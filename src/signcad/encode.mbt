///|
fn conjoin(left : @qf.Formula, right : @qf.Formula) -> @qf.Formula {
  match (left, right) {
    (Truth(false), _) | (_, Truth(false)) => Truth(false)
    (Truth(true), other) | (other, Truth(true)) => other
    _ => if left.equal(right) { left } else { Conjunction(left, right) }
  }
}

///|
fn disjoin(left : @qf.Formula, right : @qf.Formula) -> @qf.Formula {
  match (left, right) {
    (Truth(true), _) | (_, Truth(true)) => Truth(true)
    (Truth(false), other) | (other, Truth(false)) => other
    _ => if left.equal(right) { left } else { Disjunction(left, right) }
  }
}

///|
/// Prefix variables are outermost first. Each fibre is collapsed before its
/// parent; flattening the leaves would lose quantifier alternation.
fn collapse(
  prefix : @core.Chain[@logic.Quantifier],
  tree : Tree,
) -> Result[Bool, EncodingError] {
  match (prefix, tree) {
    (Nil, Leaf(value)) => Ok(value)
    (Cons(quantifier, rest), Branch(children)) => {
      fn fold(children : @core.Chain[Child]) -> Result[Bool, EncodingError] {
        match children {
          Nil => Ok(quantifier is Forall)
          Cons(child, tail) =>
            match (collapse(rest, child.subtree), fold(tail)) {
              (Ok(head), Ok(following)) =>
                match quantifier {
                  Exists => Ok(head || following)
                  Forall => Ok(head && following)
                }
              (Err(error), _) | (_, Err(error)) => Err(error)
            }
        }
      }
      fold(children)
    }
    _ => Err(InvalidTree)
  }
}

///|
fn pad_polynomial(
  p : @poly.Polynomial,
  variables : @core.Nat,
) -> Result[@poly.Polynomial, EncodingError] {
  match @core.compare(@poly.variables(p), variables) {
    Greater => Err(DimensionMismatch)
    Equal => Ok(p)
    Less =>
      match
        @poly.polynomial(
          variables,
          @core.map(@poly.terms(p), fn(term) {
            @poly.Term::{
              coefficient: term.coefficient,
              exponents: @core.append(
                term.exponents,
                @core.replicate(
                  @core.subtract(variables, @poly.variables(p)),
                  Zero,
                ),
              ),
            }
          }),
        ) {
        Ok(padded) => Ok(padded)
        Err(_) => Err(ArithmeticFailure)
      }
  }
}

///|
fn sign_guard(
  family : @core.Chain[@poly.Polynomial],
  signs : @core.Chain[@core.Ordering],
  variables : @core.Nat,
) -> Result[@qf.Formula, EncodingError] {
  match (family, signs) {
    (Nil, Nil) => Ok(Truth(true))
    (Cons(p, rest), Cons(sign, tail)) =>
      match (pad_polynomial(p, variables), sign_guard(rest, tail, variables)) {
        (Ok(padded), Ok(following)) =>
          Ok(
            conjoin(
              Atom(
                padded,
                match sign {
                  Less => LessZero
                  Equal => EqualZero
                  Greater => GreaterZero
                },
              ),
              following,
            ),
          )
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
    _ => Err(DimensionMismatch)
  }
}

///|
fn assemble(
  remaining_free : @core.Nat,
  free_variables : @core.Nat,
  quantifiers : @core.Chain[@logic.Quantifier],
  levels : @core.Chain[@core.Chain[@poly.Polynomial]],
  tree : Tree,
) -> Result[@qf.Formula, EncodingError] {
  match remaining_free {
    Zero =>
      match collapse(quantifiers, tree) {
        Ok(value) => Ok(Truth(value))
        Err(error) => Err(error)
      }
    Succ(rest) =>
      match (levels, tree) {
        (Cons(family, following), Branch(children)) => {
          fn cases(
            children : @core.Chain[Child],
          ) -> Result[@qf.Formula, EncodingError] {
            match children {
              Nil => Ok(Truth(false))
              Cons(child, tail) =>
                match
                  (
                    sign_guard(family, child.signs, free_variables),
                    assemble(
                      rest,
                      free_variables,
                      quantifiers,
                      following,
                      child.subtree,
                    ),
                    cases(tail),
                  ) {
                  (Ok(condition), Ok(body), Ok(next)) =>
                    Ok(disjoin(conjoin(condition, body), next))
                  (Err(error), _, _)
                  | (_, Err(error), _)
                  | (_, _, Err(error)) => Err(error)
                }
            }
          }
          cases(children)
        }
        _ => Err(InvalidTree)
      }
  }
}

///|
/// Families are in dimensions one through n, not including dimension zero.
/// This checks a finite sign-tree transformation. It is NOT by itself a CAD
/// coverage proof or a test that signs are constant between sample points.
pub fn encode(
  free_variables : @core.Nat,
  quantifiers : @core.Chain[@logic.Quantifier],
  levels : @core.Chain[@core.Chain[@poly.Polynomial]],
  tree : Tree,
) -> Result[Encoding, EncodingError] {
  if !@core.add(free_variables, @core.length(quantifiers)).equal(
      @core.length(levels),
    ) ||
    !validate_levels(levels, Succ(Zero)) {
    Err(DimensionMismatch)
  } else {
    match validate_tree(levels, tree) {
      Err(error) => Err(error)
      Ok(_) =>
        match
          assemble(free_variables, free_variables, quantifiers, levels, tree) {
          Err(error) => Err(error)
          Ok(formula) =>
            Ok({
              proof: { free_variables, quantifiers, levels, tree, formula, },
            })
        }
    }
  }
}

///|
/// Deterministic finite recomputation, with all source and output bindings.
pub fn check(
  free_variables : @core.Nat,
  quantifiers : @core.Chain[@logic.Quantifier],
  levels : @core.Chain[@core.Chain[@poly.Polynomial]],
  tree : Tree,
  proof : Certificate,
) -> Encoding? {
  match encode(free_variables, quantifiers, levels, tree) {
    Ok(expected) =>
      if expected.proof.equal(proof) {
        Some(expected)
      } else {
        None
      }
    Err(_) => None
  }
}

///|
pub fn check_result(
  free_variables : @core.Nat,
  quantifiers : @core.Chain[@logic.Quantifier],
  levels : @core.Chain[@core.Chain[@poly.Polynomial]],
  tree : Tree,
  value : Encoding,
  proof : Certificate,
) -> Bool {
  match check(free_variables, quantifiers, levels, tree, proof) {
    Some(expected) => value.equal(expected)
    None => false
  }
}
