///|
/// Internal phase of a finite, explicitly configured factoring search.
#derive(Eq, Debug)
pub enum SearchPhase {
  Select
  Walk(Machine, @core.Chain[(@binary.Binary, @binary.Binary)])
  Blocked
}

///|
pub extend SearchPhase with Eq::{equal, not_equal}

///|
pub extend SearchPhase with Debug::{to_repr}

///|
/// Pending factors, accepted prime certificates, and one active rho trajectory.
/// The certificate bank and seed schedule are explicit immutable inputs.
#derive(Eq, Debug)
pub struct Search {
  number : @binary.Binary
  pending : @core.Chain[@binary.Binary]
  proven : @core.Chain[@primality.Certificate]
  bank : @core.Chain[@primality.Certificate]
  seeds : @core.Chain[(@binary.Binary, @binary.Binary)]
  phase : SearchPhase
}

///|
pub extend Search with Eq::{equal, not_equal}

///|
pub extend Search with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum SearchStatus {
  Complete(Factorization)
  Searching(Search)
  Exhausted(Search)
}

///|
pub extend SearchStatus with Eq::{equal, not_equal}

///|
pub extend SearchStatus with Debug::{to_repr}

///|
/// Zero has no prime factorization. One can finish without certificates or seeds.
pub fn factor_search(
  number : @binary.Binary,
  certificates : @core.Chain[@primality.Certificate],
  seeds : @core.Chain[(@binary.Binary, @binary.Binary)],
) -> Search? {
  match @binary.is_zero(number) {
    true => None
    false =>
      Some({
        number,
        pending: Cons(number, Nil),
        proven: Nil,
        bank: certificates,
        seeds,
        phase: Select,
      })
  }
}

///|
pub fn search_value(search : Search) -> @binary.Binary {
  search.number
}

///|
/// Includes the target of an active rho trajectory, if any.
pub fn unresolved(search : Search) -> @core.Chain[@binary.Binary] {
  match search.phase {
    Walk(machine, _) => Cons(target(machine), search.pending)
    _ => search.pending
  }
}

///|
/// Every returned certificate has passed the prime checker, but the list is only
/// partial until Complete. The original number is still required for checking.
pub fn proven_certificates(
  search : Search,
) -> @core.Chain[@primality.Certificate] {
  @core.reverse(search.proven)
}

///|
/// Preserve completed prime leaves, replace the finite seed schedule, and add
/// evidence. An active rho orbit is explicitly restarted from its target.
pub fn retry_search(
  search : Search,
  additional_certificates : @core.Chain[@primality.Certificate],
  seeds : @core.Chain[(@binary.Binary, @binary.Binary)],
) -> Search {
  {
    number: search.number,
    pending: unresolved(search),
    proven: search.proven,
    bank: @core.append(search.bank, additional_certificates),
    seeds,
    phase: Select,
  }
}

///|
fn find_certificate(
  number : @binary.Binary,
  certificates : @core.Chain[@primality.Certificate],
) -> @primality.Certificate? {
  match certificates {
    Nil => None
    Cons(certificate, rest) =>
      match @binary.compare(number, @primality.candidate(certificate)) {
        Equal =>
          match @primality.check(certificate) {
            Some(_) => Some(certificate)
            None => find_certificate(number, rest)
          }
        _ => find_certificate(number, rest)
      }
  }
}

///|
/// One scheduler action: select a leaf, look up and check prime evidence,
/// initialize a seed, perform one rho iteration, or verify completion.
pub fn search_step(search : Search) -> SearchStatus {
  fn blocked(pending : @core.Chain[@binary.Binary]) -> SearchStatus {
    Exhausted({ ..search, pending, phase: Blocked, })
  }
  match search.phase {
    Blocked => Exhausted(search)
    Select =>
      match search.pending {
        Nil =>
          match
            check_factorization(search.number, proven_certificates(search)) {
            Some(complete) => Complete(complete)
            None => blocked(Nil)
          }
        Cons(number, rest) =>
          match @binary.compare(number, @binary.one()) {
            Equal => Searching({ ..search, pending: rest, })
            _ =>
              match find_certificate(number, search.bank) {
                Some(certificate) =>
                  Searching({
                    ..search,
                    pending: rest,
                    proven: Cons(certificate, search.proven),
                  })
                None =>
                  match search.seeds {
                    Nil => blocked(search.pending)
                    Cons((seed, constant), remaining_seeds) =>
                      match start(number, seed, constant) {
                        None => blocked(search.pending)
                        Some(machine) =>
                          Searching({
                            ..search,
                            pending: rest,
                            phase: Walk(machine, remaining_seeds),
                          })
                      }
                  }
              }
          }
      }
    Walk(machine, remaining_seeds) =>
      match step(machine) {
        Found(split) =>
          Searching({
            ..search,
            pending: Cons(divisor(split), Cons(cofactor(split), search.pending)),
            phase: Select,
          })
        Suspended(next) =>
          Searching({ ..search, phase: Walk(next, remaining_seeds), })
        Failed(failed) =>
          match remaining_seeds {
            Nil => blocked(Cons(target(failed), search.pending))
            Cons((seed, constant), rest) =>
              match start(target(failed), seed, constant) {
                None => blocked(Cons(target(failed), search.pending))
                Some(next) => Searching({ ..search, phase: Walk(next, rest), })
              }
          }
      }
  }
}

///|
/// Fuel bounds scheduler actions. Certificate checks and exact arithmetic inside
/// an action are not bounded in bit operations, memory, or wall-clock time.
pub fn search_run(search : Search, fuel : @core.Nat) -> SearchStatus {
  match fuel {
    Zero => Searching(search)
    Succ(rest) =>
      match search_step(search) {
        Searching(next) => search_run(next, rest)
        result => result
      }
  }
}
