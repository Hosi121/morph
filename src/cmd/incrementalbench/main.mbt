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
fn smt_search(
  problem : @smt.Problem,
  mode : String,
) -> (@smt.Outcome, Int32, Int32, Int32) {
  let mut state = match mode {
    "full" => @smt.start_full(problem)
    "pruned" => @smt.start_restarting(problem)
    "retained" => @smt.start(problem)
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
        return (
          answer,
          transitions,
          @oracle.int_of_nat(@smt.boolean_restarts(state)),
          @oracle.int_of_nat(conflicts),
        )
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
fn main {
  let args = @env.args()
  if args.length() < 3 || args.length() > 5 {
    abort("usage: incrementalbench cad|smt full|pruned|retained CASE")
  }
  // Runtime prefixes differ: Node includes both its executable and script.
  let offset = args.length() - 3
  let layer = args[offset]
  let mode = args[offset + 1]
  let name = args[offset + 2]
  if mode != "full" && mode != "pruned" && mode != "retained" {
    abort("unknown mode")
  }
  let full = mode == "full"
  let (variables, source, expected) = fixture(name)
  let total_start = @bench.monotonic_clock_start()
  let prep_start = @bench.monotonic_clock_start()
  let (prep_us, search_us, check_us, transitions, restarts, conflicts, actual) = if layer ==
    "cad" {
    if mode == "retained" {
      abort("retained mode is only defined for SMT")
    }
    let problem = @cad.prepare(@oracle.nat(variables), source).unwrap()
    let prep = @bench.monotonic_clock_end(prep_start)
    let search_start = @bench.monotonic_clock_start()
    let (answer, steps) = cad_search(problem, full)
    let search = @bench.monotonic_clock_end(search_start)
    let check_start = @bench.monotonic_clock_start()
    let actual = checked_cad(problem, answer)
    (prep, search, @bench.monotonic_clock_end(check_start), steps, 0, 0, actual)
  } else if layer == "smt" {
    let problem = @smt.prepare(@oracle.nat(variables), source).unwrap()
    let prep = @bench.monotonic_clock_end(prep_start)
    let search_start = @bench.monotonic_clock_start()
    let (answer, steps, restarts, conflicts) = smt_search(problem, mode)
    let search = @bench.monotonic_clock_end(search_start)
    let check_start = @bench.monotonic_clock_start()
    let actual = checked_smt(problem, answer)
    (
      prep,
      search,
      @bench.monotonic_clock_end(check_start),
      steps,
      restarts,
      conflicts,
      actual,
    )
  } else {
    abort("unknown layer")
  }
  let total_us = @bench.monotonic_clock_end(total_start)
  if actual != expected {
    abort("wrong decision")
  }
  println(
    "{\"layer\":\"\{layer}\",\"mode\":\"\{mode}\",\"case\":\"\{name}\",\"satisfiable\":\{actual},\"transitions\":\{transitions},\"boolean_restarts\":\{restarts},\"theory_conflicts\":\{conflicts},\"preparation_us\":\{prep_us},\"search_us\":\{search_us},\"verification_us\":\{check_us},\"total_us\":\{total_us}}",
  )
}
