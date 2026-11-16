///|
fn binder_count(formula : Formula) -> @core.Nat {
  match formula {
    Truth(_) | Atom(_, _) => Zero
    Negation(body) => binder_count(body)
    Conjunction(left, right) | Disjunction(left, right) =>
      @core.add(binder_count(left), binder_count(right))
    Exists(body) | Forall(body) => Succ(binder_count(body))
  }
}

///|
pub fn complement(relation : @realcad.Relation) -> @realcad.Relation {
  match relation {
    LessZero => AtLeastZero
    AtMostZero => GreaterZero
    EqualZero => NotZero
    NotZero => EqualZero
    AtLeastZero => LessZero
    GreaterZero => AtMostZero
  }
}

///|
fn exponent_at(
  slot : @core.Nat,
  mapping : @core.Chain[@core.Nat],
  exponents : @core.Chain[@core.Nat],
) -> @core.Nat {
  match (mapping, exponents) {
    (Cons(target, rest), Cons(exponent, tail)) =>
      match @core.compare(slot, target) {
        Equal => exponent
        _ => exponent_at(slot, rest, tail)
      }
    _ => Zero
  }
}

///|
fn valid_mapping(
  target_arity : @core.Nat,
  mapping : @core.Chain[@core.Nat],
) -> Bool {
  match mapping {
    Nil => true
    Cons(slot, rest) =>
      @core.compare(slot, target_arity) == Less &&
      !@core.any(rest, fn(other) { slot.equal(other) }) &&
      valid_mapping(target_arity, rest)
  }
}

///|
/// Injectively rename each old variable to its corresponding target slot,
/// padding unused target slots with zero exponents. Rejects wrong arity,
/// duplicate slots, and out-of-range slots, including for the zero polynomial.
pub fn rename_polynomial(
  polynomial : @polynomial.Polynomial,
  target_arity : @core.Nat,
  mapping : @core.Chain[@core.Nat],
) -> Result[@polynomial.Polynomial, BuildError] {
  match @core.length(mapping).equal(@polynomial.variables(polynomial)) {
    false => Err(ArityMismatch)
    true =>
      match valid_mapping(target_arity, mapping) {
        false => Err(InvalidRenaming)
        true => {
          let slots = @core.indices(target_arity)
          let terms : @core.Chain[@polynomial.Term] = @core.map(@polynomial.terms(polynomial), fn(term) {
            {
              coefficient: term.coefficient,
              exponents: @core.map(slots, fn(slot) {
                exponent_at(slot, mapping, term.exponents)
              }),
            }
          })
          match @polynomial.polynomial(target_arity, terms) {
            Ok(result) => Ok(result)
            Err(_) => Err(InvalidRenaming)
          }
        }
      }
  }
}

///|
fn normalize_tree(
  formula : Formula,
  negative : Bool,
  mapping : @core.Chain[@core.Nat],
  next : @core.Nat,
  total : @core.Nat,
) -> Result[(@core.Chain[Quantifier], @realcad.Formula, @core.Nat), BuildError] {
  match formula {
    Truth(value) => Ok((Nil, Truth(if negative { !value } else { value }), next))
    Atom(polynomial, relation) =>
      match rename_polynomial(polynomial, total, mapping) {
        Err(error) => Err(error)
        Ok(polynomial) =>
          Ok((
            Nil,
            Atom(polynomial, if negative { complement(relation) } else { relation }),
            next,
          ))
      }
    Negation(body) => normalize_tree(body, !negative, mapping, next, total)
    Exists(body) | Forall(body) => {
      let quantifier = match (formula, negative) {
        (Exists(_), false) | (Forall(_), true) => Quantifier::Exists
        _ => Quantifier::Forall
      }
      match
        normalize_tree(
          body,
          negative,
          @core.append(mapping, Cons(next, Nil)),
          Succ(next),
          total,
        ) {
        Err(error) => Err(error)
        Ok((prefix, matrix, next)) => Ok((Cons(quantifier, prefix), matrix, next))
      }
    }
    Conjunction(left, right) | Disjunction(left, right) =>
      match normalize_tree(left, negative, mapping, next, total) {
        Err(error) => Err(error)
        Ok((left_prefix, left_matrix, next)) =>
          match normalize_tree(right, negative, mapping, next, total) {
            Err(error) => Err(error)
            Ok((right_prefix, right_matrix, next)) => {
              let matrix = match (formula, negative) {
                (Conjunction(_, _), false) | (Disjunction(_, _), true) =>
                  @realcad.Conjunction(left_matrix, right_matrix)
                _ => @realcad.Disjunction(left_matrix, right_matrix)
              }
              Ok((@core.append(left_prefix, right_prefix), matrix, next))
            }
          }
      }
  }
}

///|
/// Push negations to polynomial relations and hoist freshly renamed binders.
/// This is a finite syntactic transformation, not a quantifier-elimination or
/// semantic-proof procedure. Hoisting uses the nonemptiness of the real domain.
pub fn normalize(
  free_variables : @core.Nat,
  source : Formula,
) -> Result[Prenex, BuildError] {
  let total = @core.add(free_variables, binder_count(source))
  match
    normalize_tree(source, false, @core.indices(free_variables), free_variables, total) {
    Err(error) => Err(error)
    Ok((quantifiers, matrix, _)) =>
      Ok({ certificate: { free_variables, source, quantifiers, matrix } })
  }
}

///|
pub fn certificate(prenex : Prenex) -> Certificate {
  prenex.certificate
}

///|
pub fn source(prenex : Prenex) -> Formula {
  prenex.certificate.source
}

///|
pub fn free_variables(prenex : Prenex) -> @core.Nat {
  prenex.certificate.free_variables
}

///|
pub fn quantifiers(prenex : Prenex) -> @core.Chain[Quantifier] {
  prenex.certificate.quantifiers
}

///|
pub fn matrix(prenex : Prenex) -> @realcad.Formula {
  prenex.certificate.matrix
}

///|
pub fn variables(prenex : Prenex) -> @core.Nat {
  @core.add(free_variables(prenex), @core.length(quantifiers(prenex)))
}

///|
/// Recompute normalization and compare every field, including exact source and
/// free-variable arity. No unchecked claim can construct an opaque Prenex.
pub fn check(
  free_variables : @core.Nat,
  source : Formula,
  claimed : Certificate,
) -> Prenex? {
  match normalize(free_variables, source) {
    Err(_) => None
    Ok(prenex) => if certificate(prenex).equal(claimed) { Some(prenex) } else { None }
  }
}
