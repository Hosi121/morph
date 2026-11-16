///|
/// Monotone-input continuation. SAT carries the quiescent search state so a
/// caller can add further input clauses without discarding learned clauses,
/// assignments, watches, proof history or cumulative statistics.
#derive(Eq, Debug)
pub(all) enum IncrementalStatus {
  Satisfiable(@sat.Model, Search)
  Unsatisfiable(Proof)
  Paused(Search)
  InvariantViolation
}

///|
pub extend IncrementalStatus with Eq::{equal, not_equal}

///|
pub extend IncrementalStatus with Debug::{to_repr}

///|
/// Same transitions as run, retaining the state at a successful completion.
/// Exhausted fuel returns Paused; it never establishes unsatisfiability.
pub fn run_incremental(search : Search, fuel : @core.Nat) -> IncrementalStatus {
  match fuel {
    Zero => Paused(search)
    Succ(rest) => {
      let (inspection, current) = inspect_search(search)
      let (status, statistics) = transition(current, inspection)
      match status {
        Satisfiable(model) => Satisfiable(model, { ..current, statistics, })
        Unsatisfiable(proof) => Unsatisfiable(proof)
        Paused(next) => run_incremental(next, rest)
        InvariantViolation => InvariantViolation
      }
    }
  }
}

///|
fn watch_add_input(
  watch : WatchState?,
  clause : Lits,
  trail : Trail,
) -> WatchState? {
  match watch {
    None => None
    Some(state) => {
      let state = {
        ..state,
        added: Cons(clause, state.added),
        recheck_added: true,
        active: None,
        pending: @core.fold_left(@core.reverse(trail), @core.queue(), fn(
          queue,
          entry,
        ) {
          @core.enqueue(queue, entry.literal)
        }),
      }
      Some(
        match clause {
          Nil => { ..state, empty: true, }
          Cons(first, Nil) => watch_insert(state, clause, first, None)
          Cons(first, Cons(second, _)) =>
            watch_insert(state, clause, first, Some(second))
        },
      )
    }
  }
}

///|
/// Add an input axiom to a monotone formula. The caller must retain this clause
/// when checking any final proof: it is not claimed to follow from the old CNF.
/// No removal or temporary assumptions are provided. Insertion itself does not
/// consume an outer transition; propagation/conflict analysis resumes in run.
pub fn add_clause(search : Search, clause : @sat.Clause) -> Search {
  let seen = @core.fold_left(search.variables, Empty, fn(seen, literal) {
    index_put(seen, @binary.bits(literal.key), true)
  })
  let (normalized, variables, _) = prepared_clause(
    clause,
    Some(Nil),
    search.variables,
    seen,
  )
  match normalized {
    None => { ..search, variables, }
    Some(clause) =>
      {
        ..search,
        variables,
        database: Cons(clause, search.database),
        watch: watch_add_input(search.watch, clause, search.trail),
      }
  }
}
