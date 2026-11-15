///|
fn dot_exact(
  xs : @core.Chain[@exact.Integer],
  ys : @core.Chain[@exact.Integer],
) -> @exact.Integer? {
  match @core.zip(xs, ys) {
    None => None
    Some(pairs) =>
      Some(
        @core.fold_left(pairs, @exact.positive(@binary.zero()), fn(sum, pair) {
          let (x, y) = pair
          @exact.add(sum, @exact.multiply(x, y))
        }),
      )
  }
}

///|
fn apply(
  input : @matrix.Matrix[@exact.Integer],
  vector : @core.Chain[@exact.Integer],
) -> @core.Chain[@exact.Integer]? {
  fn walk(
    rows : @core.Chain[@core.Chain[@exact.Integer]],
  ) -> @core.Chain[@exact.Integer]? {
    match rows {
      Nil => Some(Nil)
      Cons(row, rest) =>
        match (dot_exact(row, vector), walk(rest)) {
          (Some(value), Some(rest)) => Some(Cons(value, rest))
          _ => None
        }
    }
  }
  match @core.compare(@core.length(vector), @matrix.width(input)) {
    Equal => walk(@matrix.rows(input))
    _ => None
  }
}

///|
/// y*A vanishes modulo modulus but y*b does not, or y*A is exactly zero while
/// y*b is nonzero. Both refute an integral solution without running Smith.
#derive(Eq, Debug)
pub(all) enum Obstruction {
  Congruence(@core.Chain[@exact.Integer], @binary.Binary)
  Annihilator(@core.Chain[@exact.Integer])
}

///|
pub extend Obstruction with Eq::{equal, not_equal}

///|
pub extend Obstruction with Debug::{to_repr}

///|
pub fn check_obstruction(
  input : @matrix.Matrix[@exact.Integer],
  rhs : @core.Chain[@exact.Integer],
  obstruction : Obstruction,
) -> Bool {
  let y = match obstruction {
    Congruence(y, _) | Annihilator(y) => y
  }
  match
    (
      @core.compare(@core.length(rhs), @matrix.height(input)),
      apply(@matrix.transpose(input), y),
      dot_exact(y, rhs),
    ) {
    (Equal, Some(coefficients), Some(value)) =>
      match obstruction {
        Congruence(_, modulus) =>
          @binary.compare(modulus, @binary.one()) is Greater &&
          @core.all(coefficients, fn(value) {
            divides(modulus, @exact.magnitude(value))
          }) &&
          !divides(modulus, @exact.magnitude(value))
        Annihilator(_) => @core.all(coefficients, zero) && !zero(value)
      }
    _ => false
  }
}

///|
fn canonical_kernel(
  form : Decomposition,
) -> @core.Chain[@core.Chain[@exact.Integer]] {
  @core.drop(rank(form), @matrix.rows(@matrix.transpose(right(form))))
}

///|
/// Complete affine lattice x = particular + sum(parameter_j * basis_j).
#derive(Eq, Debug)
pub struct IntegralSolution {
  form : Decomposition
  rhs : @core.Chain[@exact.Integer]
  particular : @core.Chain[@exact.Integer]
  basis : @core.Chain[@core.Chain[@exact.Integer]]
}

///|
pub extend IntegralSolution with Eq::{equal, not_equal}

///|
pub extend IntegralSolution with Debug::{to_repr}

///|
pub fn particular(solution : IntegralSolution) -> @core.Chain[@exact.Integer] {
  solution.particular
}

///|
pub fn kernel_basis(
  solution : IntegralSolution,
) -> @core.Chain[@core.Chain[@exact.Integer]] {
  solution.basis
}

///|
pub fn solution_rhs(solution : IntegralSolution) -> @core.Chain[@exact.Integer] {
  solution.rhs
}

///|
pub fn solution_form(solution : IntegralSolution) -> Decomposition {
  solution.form
}

///|
/// Check A*x=b and the full integer kernel basis. Equality with the free
/// columns of the checked unimodular V establishes completeness over Z.
pub fn check_solution(
  form : Decomposition,
  rhs : @core.Chain[@exact.Integer],
  particular : @core.Chain[@exact.Integer],
  basis : @core.Chain[@core.Chain[@exact.Integer]],
) -> IntegralSolution? {
  let input = original(form)
  let valid_basis = basis.equal(canonical_kernel(form)) &&
    @core.all(basis, fn(vector) {
      match apply(input, vector) {
        Some(values) => @core.all(values, zero)
        None => false
      }
    })
  match apply(input, particular) {
    Some(value) =>
      match value.equal(rhs) && valid_basis {
        true => Some({ form, rhs, particular, basis, })
        false => None
      }
    None => None
  }
}

///|
#derive(Eq, Debug)
pub(all) enum SolveResult {
  Solved(IntegralSolution)
  Impossible(Obstruction)
}

///|
pub extend SolveResult with Eq::{equal, not_equal}

///|
pub extend SolveResult with Debug::{to_repr}

///|
pub fn solve(
  form : Decomposition,
  rhs : @core.Chain[@exact.Integer],
) -> SolveResult? {
  let u = left(form)
  let d = diagonal(form)
  fn diagnose(
    rows : @core.Chain[@core.Chain[@exact.Integer]],
    values : @core.Chain[@exact.Integer],
    index : @core.Nat,
  ) -> Obstruction? {
    match (rows, values) {
      (Cons(y, rest), Cons(value, tail)) => {
        let divisor = match cell(d, index, index) {
          Some(value) => @exact.magnitude(value)
          None => @binary.zero()
        }
        match @binary.is_zero(divisor) {
          true =>
            match zero(value) {
              false => Some(Annihilator(y))
              true => diagnose(rest, tail, Succ(index))
            }
          false =>
            match divides(divisor, @exact.magnitude(value)) {
              false => Some(Congruence(y, divisor))
              true => diagnose(rest, tail, Succ(index))
            }
        }
      }
      _ => None
    }
  }
  match apply(u, rhs) {
    None => None
    Some(transformed) =>
      match diagnose(@matrix.rows(u), transformed, Zero) {
        Some(obstruction) =>
          match check_obstruction(original(form), rhs, obstruction) {
            true => Some(Impossible(obstruction))
            false => None
          }
        None => {
          let coordinates = @core.map(
            @core.indices(@matrix.width(original(form))),
            fn(index) {
              match (cell(d, index, index), @core.nth(transformed, index)) {
                (Some(divisor), Some(value)) =>
                  match quotient(value, divisor) {
                    Some(value) => value
                    None => @exact.positive(@binary.zero())
                  }
                _ => @exact.positive(@binary.zero())
              }
            },
          )
          match apply(right(form), coordinates) {
            None => None
            Some(particular) =>
              match
                check_solution(form, rhs, particular, canonical_kernel(form)) {
                Some(solution) => Some(Solved(solution))
                None => None
              }
          }
        }
      }
  }
}
