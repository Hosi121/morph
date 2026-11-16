///|
fn monomial_same(
  a : @core.Chain[@core.Nat],
  b : @core.Chain[@core.Nat],
) -> Bool {
  @poly.compare_monomial(a, b).equal(Equal)
}

///|
fn monomial_contains(
  values : @core.Chain[@core.Chain[@core.Nat]],
  value : @core.Chain[@core.Nat],
) -> Bool {
  @core.any(values, fn(x) { monomial_same(x, value) })
}

///|
fn insert_monomial(
  value : @core.Chain[@core.Nat],
  values : @core.Chain[@core.Chain[@core.Nat]],
) -> @core.Chain[@core.Chain[@core.Nat]] {
  match values {
    Nil => Cons(value, Nil)
    Cons(head, rest) =>
      match @poly.compare_monomial(value, head) {
        Greater => Cons(value, values)
        Equal => values
        Less => Cons(head, insert_monomial(value, rest))
      }
  }
}

///|
fn monomials(
  rows : @core.Chain[Annotated],
) -> @core.Chain[@core.Chain[@core.Nat]] {
  @core.fold_left(rows, Nil, fn(found, row) {
    @core.fold_left(@poly.terms(row.value), found, fn(found, term) {
      insert_monomial(term.exponents, found)
    })
  })
}

///|
fn leading_monomials(
  rows : @core.Chain[Annotated],
) -> @core.Chain[@core.Chain[@core.Nat]] {
  @core.fold_left(rows, Nil, fn(found, row) {
    match @poly.terms(row.value) {
      Nil => found
      Cons(head, _) => insert_monomial(head.exponents, found)
    }
  })
}

///|
fn leading_divides(a : @poly.Polynomial, b : @poly.Polynomial) -> Bool {
  match (@poly.terms(a), @poly.terms(b)) {
    (Cons(x, _), Cons(y, _)) => @poly.divides(x.exponents, y.exponents)
    _ => false
  }
}

///|
fn reducer(
  basis : @core.Chain[Annotated],
  monomial : @core.Chain[@core.Nat],
) -> Result[Annotated?, F4Error] {
  match basis {
    Nil => Ok(None)
    Cons(row, rest) =>
      match @poly.terms(row.value) {
        Nil => Err(InternalInvariant)
        Cons(head, _) =>
          match @poly.monomial_quotient(monomial, head.exponents) {
            None => reducer(rest, monomial)
            Some(exponents) =>
              match @exact.nonzero(head.coefficient) {
                None => Err(InternalInvariant)
                Some(coefficient) =>
                  match
                    annotated_scale(row, {
                      coefficient: @exact.reciprocal(coefficient),
                      exponents,
                    }) {
                    Err(error) => Err(error)
                    Ok(row) => Ok(Some(row))
                  }
              }
          }
      }
  }
}

///|
/// Faugere's basic symbolic preprocessing. A monomial is processed once; if
/// reducible, add a basis multiple with exactly that leading monomial. New tails
/// are strictly smaller in the admissible lex order and are processed in turn.
fn symbolic_preprocessing(
  rows : @core.Chain[Annotated],
  basis : @core.Chain[Annotated],
) -> Result[@core.Chain[Annotated], F4Error] {
  fn close(
    rows : @core.Chain[Annotated],
    done : @core.Chain[@core.Chain[@core.Nat]],
  ) -> Result[@core.Chain[Annotated], F4Error] {
    let todo = @core.filter(monomials(rows), fn(m) {
      !monomial_contains(done, m)
    })
    match todo {
      Nil => Ok(rows)
      Cons(m, _) =>
        match reducer(basis, m) {
          Err(error) => Err(error)
          Ok(None) => close(rows, Cons(m, done))
          Ok(Some(row)) => close(Cons(row, rows), Cons(m, done))
        }
    }
  }
  close(rows, leading_monomials(rows))
}

///|
fn coefficient(
  value : @poly.Polynomial,
  monomial : @core.Chain[@core.Nat],
) -> @exact.Rational {
  fn find(terms : @core.Chain[@poly.Term]) -> @exact.Rational {
    match terms {
      Nil => @exact.rational_zero()
      Cons(head, rest) =>
        if monomial_same(head.exponents, monomial) {
          head.coefficient
        } else {
          find(rest)
        }
    }
  }
  find(@poly.terms(value))
}

///|
fn row_polynomial(
  variables : @core.Nat,
  columns : @core.Chain[@core.Chain[@core.Nat]],
  row : @core.Chain[@exact.Rational],
) -> Result[@poly.Polynomial, F4Error] {
  match @core.zip(columns, row) {
    None => Err(InternalInvariant)
    Some(pairs) =>
      polynomial_result(
        @poly.polynomial(
          variables,
          @core.map(pairs, fn(pair) {
            let (exponents, coefficient) = pair
            { coefficient, exponents, }
          }),
        ),
      )
  }
}

///|
/// Actual Macaulay coefficient matrix, augmented by an identity block. RREF of
/// A|I retains the rational row transformations needed for ideal witnesses.
fn macaulay_reduce(
  variables : @core.Nat,
  input_count : @core.Nat,
  rows : @core.Chain[Annotated],
) -> Result[(@core.Chain[Annotated], @core.Nat), F4Error] {
  let columns = monomials(rows)
  let column_count = @core.length(columns)
  let row_count = @core.length(rows)
  fn augmented(
    todo : @core.Chain[Annotated],
    index : @core.Nat,
  ) -> @core.Chain[@core.Chain[@exact.Rational]] {
    match todo {
      Nil => Nil
      Cons(row, rest) =>
        Cons(
          @core.append(
            @core.map(columns, fn(m) { coefficient(row.value, m) }),
            @core.map(@core.indices(row_count), fn(j) {
              if @core.compare(index, j).equal(Equal) {
                @exact.rational_one()
              } else {
                @exact.rational_zero()
              }
            }),
          ),
          augmented(rest, Succ(index)),
        )
    }
  }
  match
    @matrix.matrix(@core.add(column_count, row_count), augmented(rows, Zero)) {
    None => Err(InternalInvariant)
    Some(matrix) =>
      match @linear.rref(matrix) {
        None => Err(InternalInvariant)
        Some(reduction) => {
          fn extract(
            todo : @core.Chain[@core.Chain[@exact.Rational]],
          ) -> Result[@core.Chain[Annotated], F4Error] {
            match todo {
              Nil => Ok(Nil)
              Cons(row, rest) =>
                match
                  row_polynomial(
                    variables,
                    columns,
                    @core.take(column_count, row),
                  ) {
                  Err(error) => Err(error)
                  Ok(value) =>
                    if @poly.is_zero(value) {
                      extract(rest)
                    } else {
                      match
                        (
                          combine_rows(
                            variables,
                            input_count,
                            rows,
                            @core.drop(column_count, row),
                          ),
                          extract(rest),
                        ) {
                        (Ok(annotated), Ok(tail)) =>
                          if annotated.value.equal(value) {
                            Ok(Cons(annotated, tail))
                          } else {
                            Err(InternalInvariant)
                          }
                        (Err(error), _) | (_, Err(error)) => Err(error)
                      }
                    }
                }
            }
          }
          match extract(@matrix.rows(reduction.matrix)) {
            Err(error) => Err(error)
            Ok(result) => Ok((result, column_count))
          }
        }
      }
  }
}
