///|
#derive(Eq, Debug)
pub(all) enum Relation {
  Nonnegative
  Positive
}

///|
pub extend Relation with Eq::{equal, not_equal}

///|
pub extend Relation with Debug::{to_repr}

///|
/// Split nodes retain their parent box and split axis. The checker derives the
/// two exact closed half-boxes; shared boundaries are intentional.
#derive(Eq, Debug)
pub(all) enum CertificateTree {
  Open(@core.Chain[Axis])
  Leaf(BoundCertificate)
  Split(@core.Chain[Axis], @core.Nat, CertificateTree, CertificateTree)
}

///|
pub extend CertificateTree with Eq::{equal, not_equal}

///|
pub extend CertificateTree with Debug::{to_repr}

///|
/// Public resumable state. resume_search validates all fields and the entire existing
/// tree, including every certified leaf, before trusting a supplied state.
#derive(Eq, Debug)
pub(all) struct SearchState {
  source : @poly.Polynomial
  box : @core.Chain[Axis]
  degrees : @core.Chain[@core.Nat]
  relation : Relation
  tree : CertificateTree
}

///|
pub extend SearchState with Eq::{equal, not_equal}

///|
pub extend SearchState with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Witness {
  point : @core.Chain[@exact.Rational]
  value : @exact.Rational
}

///|
pub extend Witness with Eq::{equal, not_equal}

///|
pub extend Witness with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Outcome {
  Certified(SearchState)
  Counterexample(SearchState, Witness)
  Paused(SearchState)
}

///|
pub extend Outcome with Eq::{equal, not_equal}

///|
pub extend Outcome with Debug::{to_repr}

///|
fn satisfies(value : @exact.Rational, relation : Relation) -> Bool {
  match (@exact.rational_compare(value, @exact.rational_zero()), relation) {
    (Greater, _) | (Equal, Nonnegative) => true
    _ => false
  }
}

///|
fn midpoint(axis : Axis) -> @exact.Rational {
  @exact.rational_half(@exact.rational_add(axis.lower, axis.upper))
}

///|
fn split_box(
  box : @core.Chain[Axis],
  index : @core.Nat,
) -> (@core.Chain[Axis], @core.Chain[Axis])? {
  match (box, index) {
    (Nil, _) => None
    (Cons(axis, rest), Zero) => {
      let middle = midpoint(axis)
      Some(
        (
          Cons({ lower: axis.lower, upper: middle, }, rest),
          Cons({ lower: middle, upper: axis.upper, }, rest),
        ),
      )
    }
    (Cons(axis, rest), Succ(index)) =>
      match split_box(rest, index) {
        None => None
        Some((left, right)) => Some((Cons(axis, left), Cons(axis, right)))
      }
  }
}

///|
/// Longest-side bisection, breaking ties at the first axis. All nonzero widths
/// eventually shrink on every infinite path, unlike always splitting axis zero.
fn longest_axis(box : @core.Chain[Axis]) -> @core.Nat? {
  match box {
    Nil => None
    Cons(head, rest) => {
      fn go(
        axes : @core.Chain[Axis],
        index : @core.Nat,
        best : @core.Nat,
        width : @exact.Rational,
      ) -> @core.Nat {
        match axes {
          Nil => best
          Cons(axis, rest) => {
            let candidate = @exact.rational_subtract(axis.upper, axis.lower)
            if @exact.rational_compare(candidate, width).equal(Greater) {
              go(rest, Succ(index), index, candidate)
            } else {
              go(rest, Succ(index), best, width)
            }
          }
        }
      }
      Some(
        go(
          rest,
          Succ(Zero),
          Zero,
          @exact.rational_subtract(head.upper, head.lower),
        ),
      )
    }
  }
}

///|
fn complete(tree : CertificateTree) -> Bool {
  match tree {
    Open(_) => false
    Leaf(_) => true
    Split(_, _, left, right) => complete(left) && complete(right)
  }
}

///|
fn check_tree(
  state : SearchState,
  box : @core.Chain[Axis],
  tree : CertificateTree,
) -> Bool {
  match tree {
    Open(actual) => actual.equal(box)
    Leaf(certificate) =>
      certificate.degrees.equal(state.degrees) &&
      satisfies(certificate.lower, state.relation) &&
      check_bound(state.source, box, certificate)
    Split(actual, axis, left, right) =>
      actual.equal(box) &&
      (match split_box(box, axis) {
        None => false
        Some((left_box, right_box)) =>
          check_tree(state, left_box, left) &&
          check_tree(state, right_box, right)
      })
  }
}

///|
fn valid_state(state : SearchState) -> Bool {
  match validate(state.source, state.box, state.degrees) {
    Err(_) => false
    Ok(_) => check_tree(state, state.box, state.tree)
  }
}

///|
fn inside(
  point : @core.Chain[@exact.Rational],
  box : @core.Chain[Axis],
) -> Bool {
  match (point, box) {
    (Nil, Nil) => true
    (Cons(x, xs), Cons(axis, axes)) =>
      !@exact.rational_compare(x, axis.lower).equal(Less) &&
      !@exact.rational_compare(x, axis.upper).equal(Greater) &&
      inside(xs, axes)
    _ => false
  }
}

///|
/// A witness is checked against the actual polynomial and closed domain.
pub fn check_witness(
  p : @poly.Polynomial,
  box : @core.Chain[Axis],
  relation : Relation,
  witness : Witness,
) -> Bool {
  valid_box(box) &&
  @core.length(box).equal(@poly.variables(p)) &&
  inside(witness.point, box) &&
  @poly.evaluate(p, witness.point).equal(Some(witness.value)) &&
  !satisfies(witness.value, relation)
}

///|
/// Verifies that the actual outcome proves/refutes exactly the supplied claim,
/// or is a structurally valid unfinished search. Paused proves neither claim.
pub fn check_outcome(
  p : @poly.Polynomial,
  box : @core.Chain[Axis],
  relation : Relation,
  outcome : Outcome,
) -> Bool {
  let state = match outcome {
    Certified(state) | Counterexample(state, _) | Paused(state) => state
  }
  state.source.equal(p) &&
  state.box.equal(box) &&
  state.relation.equal(relation) &&
  valid_state(state) &&
  (match outcome {
    Certified(_) => complete(state.tree)
    Paused(_) => !complete(state.tree)
    Counterexample(_, witness) => check_witness(p, box, relation, witness)
  })
}

///|
fn corners(
  box : @core.Chain[Axis],
) -> @core.Chain[@core.Chain[@exact.Rational]] {
  match box {
    Nil => Cons(Nil, Nil)
    Cons(axis, rest) => {
      let tails = corners(rest)
      @core.append(
        @core.map(tails, fn(point) { Cons(axis.lower, point) }),
        @core.map(tails, fn(point) { Cons(axis.upper, point) }),
      )
    }
  }
}

///|
fn sample(
  p : @poly.Polynomial,
  box : @core.Chain[Axis],
  relation : Relation,
) -> Witness? {
  fn find(points : @core.Chain[@core.Chain[@exact.Rational]]) -> Witness? {
    match points {
      Nil => None
      Cons(point, rest) =>
        match @poly.evaluate(p, point) {
          Some(value) =>
            if satisfies(value, relation) {
              find(rest)
            } else {
              Some({ point, value, })
            }
          None => None
        }
    }
  }
  find(Cons(@core.map(box, midpoint), corners(box)))
}

///|
priv struct Progress {
  tree : CertificateTree
  remaining : @core.Nat
  witness : Witness?
}

///|
fn advance(
  state : SearchState,
  tree : CertificateTree,
  fuel : @core.Nat,
) -> Result[Progress, BernsteinError] {
  match tree {
    Leaf(_) => Ok({ tree, remaining: fuel, witness: None, })
    Split(box, axis, left, right) =>
      match advance(state, left, fuel) {
        Err(error) => Err(error)
        Ok(left_result) =>
          match left_result.witness {
            Some(witness) =>
              Ok({
                tree: Split(box, axis, left_result.tree, right),
                remaining: left_result.remaining,
                witness: Some(witness),
              })
            None =>
              match advance(state, right, left_result.remaining) {
                Err(error) => Err(error)
                Ok(right_result) =>
                  Ok({
                    tree: Split(box, axis, left_result.tree, right_result.tree),
                    remaining: right_result.remaining,
                    witness: right_result.witness,
                  })
              }
          }
      }
    Open(box) =>
      match bound(state.source, box, state.degrees) {
        Err(error) => Err(error)
        Ok(certificate) =>
          if satisfies(certificate.lower, state.relation) {
            Ok({ tree: Leaf(certificate), remaining: fuel, witness: None, })
          } else {
            match sample(state.source, box, state.relation) {
              Some(witness) =>
                Ok({ tree, remaining: fuel, witness: Some(witness), })
              None =>
                match fuel {
                  Zero => Ok({ tree, remaining: fuel, witness: None, })
                  Succ(rest) =>
                    match longest_axis(box) {
                      None => Err(InvalidCertificate)
                      Some(axis) =>
                        match split_box(box, axis) {
                          None => Err(InvalidCertificate)
                          Some((left_box, right_box)) =>
                            advance(
                              state,
                              Split(box, axis, Open(left_box), Open(right_box)),
                              rest,
                            )
                        }
                    }
                }
            }
          }
      }
  }
}

///|
/// Fuel counts newly created midpoint split nodes, not arithmetic operations,
/// tensor entries or wall time. Bound checks and rational sampling are free in
/// that metric. Resuming checks the existing tree and revisits open leaves.
pub fn resume_search(
  state : SearchState,
  split_fuel : @core.Nat,
) -> Result[Outcome, BernsteinError] {
  if !valid_state(state) {
    return Err(InvalidCertificate)
  }
  match advance(state, state.tree, split_fuel) {
    Err(error) => Err(error)
    Ok(progress) => {
      let next : SearchState = {
        source: state.source,
        box: state.box,
        degrees: state.degrees,
        relation: state.relation,
        tree: progress.tree,
      }
      match progress.witness {
        Some(witness) => Ok(Counterexample(next, witness))
        None =>
          Ok(if complete(next.tree) { Certified(next) } else { Paused(next) })
      }
    }
  }
}

///|
pub fn certify(
  p : @poly.Polynomial,
  box : @core.Chain[Axis],
  degrees : @core.Chain[@core.Nat],
  relation : Relation,
  split_fuel : @core.Nat,
) -> Result[Outcome, BernsteinError] {
  match validate(p, box, degrees) {
    Err(error) => Err(error)
    Ok(_) =>
      resume_search(
        { source: p, box, degrees, relation, tree: Open(box), },
        split_fuel,
      )
  }
}

///|
/// (certified leaves, split nodes, open leaves), all arbitrary-size ADT counts.
pub fn tree_counts(tree : CertificateTree) -> (@core.Nat, @core.Nat, @core.Nat) {
  match tree {
    Open(_) => (Zero, Zero, Succ(Zero))
    Leaf(_) => (Succ(Zero), Zero, Zero)
    Split(_, _, left, right) => {
      let (ll, ls, lo) = tree_counts(left)
      let (rl, rs, ro) = tree_counts(right)
      (@core.add(ll, rl), Succ(@core.add(ls, rs)), @core.add(lo, ro))
    }
  }
}
