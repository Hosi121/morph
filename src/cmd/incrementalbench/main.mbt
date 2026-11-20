///|
/// Measurement host only: the imported algorithms retain the pure ADT kernel.
fn polynomial(
  variables : Int32,
  terms : Array[(Int32, Array[Int32])],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(variables),
    @oracle.chain(
      terms.map(fn(term) {
        let (coefficient, exponents) = term
        @poly.Term::{
          coefficient: @oracle.rational(coefficient, 1),
          exponents: @oracle.chain(exponents.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn conjunction(atoms : Array[@qf.Formula]) -> @qf.Formula {
  atoms.fold(init=@qf.Truth(true), fn(left, right) {
    @qf.Conjunction(left, right)
  })
}

///|
fn alternatives(
  count : Int32,
  variables : Int32,
  satisfiable : Bool,
) -> @qf.Formula {
  let mut source : @qf.Formula = @qf.Truth(false)
  for index in 0..<count {
    let terms = if variables == 0 {
      [(index + 1, [])]
    } else {
      [(1, [2]), (index + 1, [0])]
    }
    source = @qf.Disjunction(
      source,
      @qf.Atom(polynomial(variables, terms), @qf.LessZero),
    )
  }
  if satisfiable {
    @qf.Disjunction(
      source,
      @qf.Atom(polynomial(variables, [(1, [1])]), @qf.AtLeastZero),
    )
  } else {
    source
  }
}

///|
fn fixture(name : String) -> (Int32, @qf.Formula, Bool) {
  match name {
    "constant-unsat4" => (0, alternatives(4, 0, false), false)
    "constant-unsat6" => (0, alternatives(6, 0, false), false)
    "squares-unsat3" => (1, alternatives(3, 1, false), false)
    "squares-unsat4" => (1, alternatives(4, 1, false), false)
    "alternatives-sat3" => (1, alternatives(3, 1, true), true)
    "alternatives-sat4" => (1, alternatives(4, 1, true), true)
    "constant-sat4" => (4, @qf.Truth(true), true)
    "prefix-unsat2" =>
      (
        2,
        conjunction([
          @qf.Atom(polynomial(2, [(1, [1, 0])]), @qf.EqualZero),
          @qf.Atom(polynomial(2, [(1, [1, 1]), (-1, [0, 0])]), @qf.EqualZero),
        ]),
        false,
      )
    "circle-sat2" =>
      (
        2,
        @qf.Atom(
          polynomial(2, [(1, [2, 0]), (1, [0, 2]), (-1, [0, 0])]),
          @qf.EqualZero,
        ),
        true,
      )
    "diagonal-sat3" | "diagonal-unsat3" => {
      let sat = name == "diagonal-sat3"
      (
        3,
        conjunction([
          @qf.Atom(
            polynomial(3, [(1, [2, 0, 0]), (-2, [0, 0, 0])]),
            @qf.EqualZero,
          ),
          @qf.Atom(
            polynomial(3, [(1, [0, 1, 0]), (-1, [1, 0, 0])]),
            @qf.EqualZero,
          ),
          @qf.Atom(
            polynomial(3, [(1, [0, 0, 1]), (-1, [0, 1, 0])]),
            @qf.EqualZero,
          ),
          @qf.Atom(
            polynomial(3, [(1, [0, 0, 2]), (-2, [0, 0, 0])]),
            if sat {
              @qf.EqualZero
            } else {
              @qf.NotZero
            },
          ),
        ]),
        sat,
      )
    }
    "diagonal-unsat4" =>
      (
        4,
        conjunction([
          @qf.Atom(
            polynomial(4, [(1, [1, 0, 0, 0]), (-1, [0, 1, 0, 0])]),
            @qf.EqualZero,
          ),
          @qf.Atom(
            polynomial(4, [(1, [0, 1, 0, 0]), (-1, [0, 0, 1, 0])]),
            @qf.EqualZero,
          ),
          @qf.Atom(
            polynomial(4, [(1, [0, 0, 1, 0]), (-1, [0, 0, 0, 1])]),
            @qf.EqualZero,
          ),
          @qf.Atom(
            polynomial(4, [(1, [2, 0, 0, 0]), (-2, [0, 0, 0, 0])]),
            @qf.EqualZero,
          ),
          @qf.Atom(
            polynomial(4, [(1, [0, 0, 0, 2]), (-2, [0, 0, 0, 0])]),
            @qf.NotZero,
          ),
        ]),
        false,
      )
    "quadratic-nullification3" =>
      (
        3,
        conjunction([
          @qf.Atom(polynomial(3, [(1, [1, 0, 0])]), @qf.EqualZero),
          @qf.Atom(
            polynomial(3, [(1, [0, 1, 0]), (-1, [0, 0, 0])]),
            @qf.EqualZero,
          ),
          @qf.Atom(
            polynomial(3, [
              (1, [1, 0, 2]),
              (1, [0, 1, 1]),
              (-1, [0, 0, 1]),
              (-1, [0, 0, 0]),
            ]),
            @qf.EqualZero,
          ),
        ]),
        false,
      )
    "univariate-sat" =>
      (1, @qf.Atom(polynomial(1, [(1, [2]), (-2, [0])]), @qf.EqualZero), true)
    "univariate-unsat" =>
      (1, @qf.Atom(polynomial(1, [(1, [2]), (1, [0])]), @qf.EqualZero), false)
    _ => abort("unknown benchmark fixture")
  }
}

///|
enum CadAnswer {
  Sat(@cad.Point)
  Unsat(@cad.Decomposition)
}

///|
fn cad_search(problem : @cad.Problem, full : Bool) -> (CadAnswer, Int32) {
  if full {
    let mut state = @cad.start(problem)
    for transitions in 1..<=100000 {
      match @cad.step(state).unwrap() {
        Paused(next) => state = next
        Complete(value) => {
          let answer = match @cad.witness(value).unwrap() {
            Some(point) => Sat(point)
            None => Unsat(value)
          }
          return (answer, transitions)
        }
      }
    }
  } else {
    let mut state = @cad.start_search(problem)
    for transitions in 1..<=100000 {
      match @cad.search_step(state).unwrap() {
        Paused(next) => state = next
        Satisfiable(point) => return (Sat(point), transitions)
        Unsatisfiable(value) => return (Unsat(value), transitions)
      }
    }
  }
  abort("benchmark exhausted transition limit")
}

///|
fn checked_cad(problem : @cad.Problem, answer : CadAnswer) -> Bool {
  match answer {
    Sat(point) => {
      if !@cad.check_witness(problem, point) {
        abort("invalid exact model")
      }
      true
    }
    Unsat(value) => {
      if !@cad.check_result(problem, value, @cad.certificate(value)) {
        abort("invalid CAD coverage proof")
      }
      if @cad.sentence(
          value,
          @core.replicate_onto(
            @cad.arity(problem),
            @logic.Quantifier::Exists,
            Nil,
          ),
        ).unwrap() {
        abort("nonempty alleged refutation")
      }
      false
    }
  }
}

///|
struct SmtRun {
  answer : @smt.Outcome
  transitions : Int32
  restarts : Int32
  conflicts : Int32
  proof_additions : Int32
  core_probes : Int32
  removed_literals : Int32
  refutation_literals : Int32
}

///|
fn smt_search(problem : @smt.Problem, mode : String) -> SmtRun {
  let mut state = match mode {
    "full" => @smt.start_full(problem)
    "pruned" => @smt.start_restarting(problem)
    "retained" => @smt.start_retained(problem)
    "core" => @smt.start_core(problem)
    _ => abort("unknown SMT mode")
  }
  for transitions in 1..<=100000 {
    match @smt.step(state).unwrap() {
      Paused(next) => state = next
      answer => {
        let conflicts = match answer {
          Unsatisfiable(proof) => @core.length(proof.lemmas)
          _ => @smt.theory_conflicts(state)
        }
        let (proof_additions, refutation_literals) = match answer {
          Unsatisfiable(refutation) => {
            let additions = match refutation.propositional {
              Rup(clauses) => @oracle.int_of_nat(@core.length(clauses))
            }
            let literals = @oracle.array(refutation.lemmas).fold(init=0, fn(
              count,
              lemma,
            ) {
              count + @oracle.int_of_nat(@core.length(lemma.assignment))
            })
            (additions, literals)
          }
          _ => (0, 0)
        }
        return {
          answer,
          transitions,
          restarts: @oracle.int_of_nat(@smt.boolean_restarts(state)),
          conflicts: @oracle.int_of_nat(conflicts),
          proof_additions,
          core_probes: @oracle.int_of_nat(@smt.core_probes(state)),
          removed_literals: @oracle.int_of_nat(
            @smt.core_literals_removed(state),
          ),
          refutation_literals,
        }
      }
    }
  }
  abort("SMT benchmark exhausted transition limit")
}

///|
fn checked_smt(problem : @smt.Problem, answer : @smt.Outcome) -> Bool {
  match answer {
    Satisfiable(model) => {
      if !@smt.check_model(problem, model) {
        abort("invalid SMT model")
      }
      true
    }
    Unsatisfiable(proof) => {
      if !@smt.check_refutation(problem, proof) {
        abort("invalid SMT refutation")
      }
      false
    }
    Paused(_) => abort("unfinished SMT search")
  }
}

///|
struct Measurement {
  preparation_us : Double
  search_us : Double
  verification_us : Double
  transitions : Int32
  restarts : Int32
  conflicts : Int32
  proof_additions : Int32
  core_probes : Int32
  removed_literals : Int32
  refutation_literals : Int32
  satisfiable : Bool
}

///|
fn measure_cad(
  variables : Int32,
  source : @qf.Formula,
  full : Bool,
) -> Measurement {
  let started = @bench.monotonic_clock_start()
  let problem = @cad.prepare(@oracle.nat(variables), source).unwrap()
  let preparation_us = @bench.monotonic_clock_end(started)
  let started = @bench.monotonic_clock_start()
  let (answer, transitions) = cad_search(problem, full)
  let search_us = @bench.monotonic_clock_end(started)
  let started = @bench.monotonic_clock_start()
  let satisfiable = checked_cad(problem, answer)
  {
    preparation_us,
    search_us,
    verification_us: @bench.monotonic_clock_end(started),
    transitions,
    restarts: 0,
    conflicts: 0,
    proof_additions: 0,
    core_probes: 0,
    removed_literals: 0,
    refutation_literals: 0,
    satisfiable,
  }
}

///|
fn measure_smt(
  variables : Int32,
  source : @qf.Formula,
  mode : String,
) -> Measurement {
  let started = @bench.monotonic_clock_start()
  let problem = @smt.prepare(@oracle.nat(variables), source).unwrap()
  let preparation_us = @bench.monotonic_clock_end(started)
  let started = @bench.monotonic_clock_start()
  let run = smt_search(problem, mode)
  let search_us = @bench.monotonic_clock_end(started)
  let started = @bench.monotonic_clock_start()
  let satisfiable = checked_smt(problem, run.answer)
  {
    preparation_us,
    search_us,
    verification_us: @bench.monotonic_clock_end(started),
    transitions: run.transitions,
    restarts: run.restarts,
    conflicts: run.conflicts,
    proof_additions: run.proof_additions,
    core_probes: run.core_probes,
    removed_literals: run.removed_literals,
    refutation_literals: run.refutation_literals,
    satisfiable,
  }
}

///|
fn main {
  let args = @env.args()
  if args.length() < 3 || args.length() > 5 {
    abort("usage: incrementalbench cad|smt full|pruned|retained|core CASE")
  }
  // Runtime prefixes differ: Node includes both its executable and script.
  let offset = args.length() - 3
  let layer = args[offset]
  let mode = args[offset + 1]
  let name = args[offset + 2]
  if mode != "full" && mode != "pruned" && mode != "retained" && mode != "core" {
    abort("unknown mode")
  }
  let (variables, source, expected) = fixture(name)
  let started = @bench.monotonic_clock_start()
  let measured = match layer {
    "cad" => {
      if mode == "retained" || mode == "core" {
        abort("Boolean modes require SMT")
      }
      measure_cad(variables, source, mode == "full")
    }
    "smt" => measure_smt(variables, source, mode)
    _ => abort("unknown layer")
  }
  let total_us = @bench.monotonic_clock_end(started)
  if measured.satisfiable != expected {
    abort("wrong decision")
  }
  println(
    "{\"layer\":\"\{layer}\",\"mode\":\"\{mode}\",\"case\":\"\{name}\",\"satisfiable\":\{measured.satisfiable},\"transitions\":\{measured.transitions},\"boolean_restarts\":\{measured.restarts},\"theory_conflicts\":\{measured.conflicts},\"proof_additions\":\{measured.proof_additions},\"core_probes\":\{measured.core_probes},\"removed_literals\":\{measured.removed_literals},\"refutation_literals\":\{measured.refutation_literals},\"preparation_us\":\{measured.preparation_us},\"search_us\":\{measured.search_us},\"verification_us\":\{measured.verification_us},\"total_us\":\{total_us}}",
  )
}
