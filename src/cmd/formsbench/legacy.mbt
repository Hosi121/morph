///|
fn legacy_wedge(
  a : @forms.Form,
  b : @forms.Form,
) -> Result[@forms.Form, @forms.FormError] {
  fn product_row(
    term : @forms.Term,
    other : @core.Chain[@forms.Term],
  ) -> Result[@core.Chain[@forms.Term], @forms.FormError] {
    match other {
      Nil => Ok(Nil)
      Cons(head, rest) =>
        match
          (
            @poly.multiply(term.coefficient, head.coefficient),
            product_row(term, rest),
          ) {
          (Ok(coefficient), Ok(tail)) =>
            Ok(
              Cons(
                {
                  coefficient,
                  indices: @core.append(term.indices, head.indices),
                },
                tail,
              ),
            )
          _ => Err(InternalInvariant)
        }
    }
  }
  fn product(
    left : @core.Chain[@forms.Term],
  ) -> Result[@core.Chain[@forms.Term], @forms.FormError] {
    match left {
      Nil => Ok(Nil)
      Cons(head, rest) =>
        match (product_row(head, @forms.terms(b)), product(rest)) {
          (Ok(row), Ok(tail)) => Ok(@core.append(row, tail))
          _ => Err(InternalInvariant)
        }
    }
  }
  if !@forms.variables(a).equal(@forms.variables(b)) {
    Err(DimensionMismatch)
  } else {
    match product(@forms.terms(a)) {
      Err(error) => Err(error)
      Ok(terms) =>
        @forms.form(
          @forms.variables(a),
          @core.add(@forms.degree(a), @forms.degree(b)),
          terms,
        )
    }
  }
}
