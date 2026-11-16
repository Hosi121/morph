///|
fn constant_sign(polynomial : @poly.Polynomial) -> @core.Ordering? {
  match @poly.terms(polynomial) {
    Nil => Some(Equal)
    Cons(term, Nil) =>
      if @core.all(term.exponents, fn(power) { power is Zero }) {
        Some(@exact.rational_compare(term.coefficient, @exact.rational_zero()))
      } else {
        None
      }
    _ => None
  }
}

///|
fn find_member(
  polynomial : @poly.Polynomial,
  family : @core.Chain[@poly.Polynomial],
  index : @core.Nat,
) -> Binding {
  match family {
    Nil => Unavailable
    Cons(head, rest) =>
      if polynomial.equal(head) {
        Observed(index)
      } else {
        find_member(polynomial, rest, Succ(index))
      }
  }
}

///|
fn bind(
  polynomial : @poly.Polynomial,
  family : @core.Chain[@poly.Polynomial],
) -> Binding {
  match constant_sign(polynomial) {
    Some(sign) => Fixed(sign)
    None => find_member(polynomial, family, Zero)
  }
}

///|
fn add_group(
  future : @core.Chain[@core.Nat],
  term : @poly.Term,
  groups : @core.Chain[Group],
) -> @core.Chain[Group] {
  match groups {
    Nil => Cons({ future, terms: Cons(term, Nil), }, Nil)
    Cons(head, rest) =>
      match @poly.compare_monomial(future, head.future) {
        Equal => Cons({ ..head, terms: Cons(term, head.terms), }, rest)
        Greater => Cons({ future, terms: Cons(term, Nil), }, groups)
        Less => Cons(head, add_group(future, term, rest))
      }
  }
}

///|
/// p(prefix,suffix) = sum_mu coefficient_mu(prefix) suffix^mu.
/// No numerical substitution is performed while constructing this identity.
fn group_terms(
  depth : @core.Nat,
  terms : @core.Chain[@poly.Term],
  groups : @core.Chain[Group],
) -> Result[@core.Chain[Group], PrefixError] {
  match terms {
    Nil => Ok(groups)
    Cons(term, rest) =>
      match @core.split_exact(depth, term.exponents) {
        None => Err(DimensionMismatch)
        Some((prefix, future)) =>
          group_terms(
            depth,
            rest,
            add_group(future, { ..term, exponents: prefix, }, groups),
          )
      }
  }
}

///|
fn compile_atom(
  depth : @core.Nat,
  polynomial : @poly.Polynomial,
  relation : @qf.Relation,
  family : @core.Chain[@poly.Polynomial],
) -> Result[Conditional, PrefixError] {
  fn finish(
    groups : @core.Chain[Group],
    constant : Binding,
    future : @core.Chain[Binding],
  ) -> Result[Conditional, PrefixError] {
    match groups {
      Nil => Ok(Atom(constant, @core.reverse(future), relation))
      Cons(group, rest) =>
        match @poly.polynomial(depth, group.terms) {
          Err(_) => Err(DimensionMismatch)
          Ok(coefficient) => {
            let binding = bind(coefficient, family)
            if @core.all(group.future, fn(power) { power is Zero }) {
              finish(rest, binding, future)
            } else {
              finish(rest, constant, Cons(binding, future))
            }
          }
        }
    }
  }
  match group_terms(depth, @poly.terms(polynomial), Nil) {
    Err(error) => Err(error)
    Ok(groups) => finish(groups, Fixed(Equal), Nil)
  }
}

///|
fn compile_formula(
  depth : @core.Nat,
  formula : @qf.Formula,
  family : @core.Chain[@poly.Polynomial],
) -> Result[Conditional, PrefixError] {
  match formula {
    Truth(value) => Ok(Constant(value))
    Atom(polynomial, relation) =>
      compile_atom(depth, polynomial, relation, family)
    Negation(body) =>
      match compile_formula(depth, body, family) {
        Ok(compiled) => Ok(Not(compiled))
        Err(error) => Err(error)
      }
    Conjunction(left, right) =>
      match
        (
          compile_formula(depth, left, family),
          compile_formula(depth, right, family),
        ) {
        (Ok(a), Ok(b)) => Ok(And(a, b))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
    Disjunction(left, right) =>
      match
        (
          compile_formula(depth, left, family),
          compile_formula(depth, right, family),
        ) {
        (Ok(a), Ok(b)) => Ok(Or(a, b))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn valid_polynomial(polynomial : @poly.Polynomial, arity : @core.Nat) -> Bool {
  if !@poly.variables(polynomial).equal(arity) {
    false
  } else {
    match @poly.polynomial(arity, @poly.terms(polynomial)) {
      Ok(canonical) => canonical.equal(polynomial)
      Err(_) => false
    }
  }
}

///|
/// Families are ordered by dimensions 0 through arity, inclusive. A coefficient
/// absent from a family is allowed and produces Undetermined when needed.
pub fn prepare(
  arity : @core.Nat,
  formula : @qf.Formula,
  families : @core.Chain[@core.Chain[@poly.Polynomial]],
) -> Result[Plan, PrefixError] {
  fn stages(
    depth : @core.Nat,
    families : @core.Chain[@core.Chain[@poly.Polynomial]],
  ) -> Result[@core.Chain[Stage], PrefixError] {
    match families {
      Nil => Ok(Nil)
      Cons(family, rest) =>
        if !@core.all(family, fn(p) { valid_polynomial(p, depth) }) {
          Err(DimensionMismatch)
        } else {
          match
            (compile_formula(depth, formula, family), stages(Succ(depth), rest)) {
            (Ok(conditional), Ok(tail)) =>
              Ok(
                Cons(
                  { observation_count: @core.length(family), conditional, },
                  tail,
                ),
              )
            (Err(error), _) | (_, Err(error)) => Err(error)
          }
        }
    }
  }
  if !@core.length(families).equal(Succ(arity)) ||
    !@core.all(@logic.qf_atoms(formula), fn(p) { valid_polynomial(p, arity) }) {
    Err(DimensionMismatch)
  } else {
    match stages(Zero, families) {
      Ok(stages) => Ok({ stages, })
      Err(error) => Err(error)
    }
  }
}

///|
/// Rebuilds every coefficient group, binding and Boolean node. A coherent but
/// unrelated opaque Plan is rejected unless it has exactly the same semantics
/// and compilation for this source and these ordered families.
pub fn check_plan(
  arity : @core.Nat,
  formula : @qf.Formula,
  families : @core.Chain[@core.Chain[@poly.Polynomial]],
  plan : Plan,
) -> Bool {
  match prepare(arity, formula, families) {
    Ok(expected) => expected.equal(plan)
    Err(_) => false
  }
}
