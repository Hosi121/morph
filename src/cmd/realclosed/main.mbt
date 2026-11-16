///|
/// Machine numbers adapt these fixed inputs and output only. Every solver
/// called below computes with the library's symbolic datatypes.
fn p(
  variables : Int32,
  terms : Array[(Int32, Array[Int32])],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(variables),
    @oracle.chain(
      terms.map(fn(term) {
        let (coefficient, powers) = term
        @poly.Term::{
          coefficient: @oracle.rational(coefficient, 1),
          exponents: @oracle.chain(powers.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn closed(free : Int32, source : @logic.Formula) -> @rcf.Solution {
  let problem = @rcf.prepare(@oracle.nat(free), source).unwrap()
  match @rcf.run(@rcf.start(problem), @oracle.nat(50000)).unwrap() {
    Complete(value) => {
      if !@rcf.check_result(
          @oracle.nat(free),
          source,
          value,
          @rcf.certificate(value),
        ) {
        abort("invalid solver certificate")
      }
      value
    }
    Paused(_) => abort("demo needs more transitions")
  }
}

///|
fn main {
  let inequality = p(3, [(1, [0, 2, 0]), (1, [0, 0, 2]), (-1, [1, 0, 0])])
  let yes_source = @logic.Formula::Forall(
    @logic.Formula::Exists(
      @logic.Formula::Forall(@logic.Atom(inequality, @qf.AtLeastZero)),
    ),
  )
  let no_source = @logic.Formula::Exists(
    @logic.Formula::Forall(
      @logic.Formula::Exists(@logic.Atom(inequality, @qf.AtMostZero)),
    ),
  )
  let yes = @rcf.truth(closed(0, yes_source)).unwrap()
  let no = @rcf.truth(closed(0, no_source)).unwrap()
  println("forall x exists y forall z. y^2+z^2 >= x: \{yes} [checked]")
  println("exists x forall y exists z. y^2+z^2 <= x: \{no} [checked]")

  let sphere = p(3, [
    (1, [2, 0, 0]),
    (1, [0, 2, 0]),
    (1, [0, 0, 2]),
    (-1, [0, 0, 0]),
  ])
  let projection = closed(
    2,
    @logic.Formula::Exists(@logic.Atom(sphere, @qf.EqualZero)),
  )
  let query = @rcf.quantifier_free(projection)
  let origin = @cad.evaluate_formula(
    @cad.rational_point(
      @oracle.chain([@oracle.rational(0, 1), @oracle.rational(0, 1)]),
    ),
    query,
  ).unwrap()
  let boundary = @cad.evaluate_formula(
    @cad.rational_point(
      @oracle.chain([@oracle.rational(1, 1), @oracle.rational(0, 1)]),
    ),
    query,
  ).unwrap()
  let outside = @cad.evaluate_formula(
    @cad.rational_point(
      @oracle.chain([@oracle.rational(1, 1), @oracle.rational(1, 1)]),
    ),
    query,
  ).unwrap()
  println(
    "exists z. x^2+y^2+z^2=1: rational-polynomial formula in x,y [checked]",
  )
  println(
    "  origin=\{origin}; boundary (1,0)=\{boundary}; outside (1,1)=\{outside}",
  )

  let equations = [
    p(3, [(1, [2, 0, 0]), (-2, [0, 0, 0])]),
    p(3, [(1, [0, 2, 0]), (-1, [1, 0, 0])]),
    p(3, [(1, [0, 0, 2]), (-1, [0, 1, 0])]),
  ]
  let mut matrix = @qf.Truth(true)
  for equation in equations {
    matrix = @qf.Conjunction(matrix, @qf.Atom(equation, @qf.EqualZero))
  }
  for i in 0..<3 {
    let coordinate = p(3, [
      (1, [ for j in 0..<3 => if i == j { 1 } else { 0 } ]),
    ])
    matrix = @qf.Conjunction(matrix, @qf.Atom(coordinate, @qf.GreaterZero))
  }
  let problem = @smt.prepare(@oracle.nat(3), matrix).unwrap()
  match @smt.run(@smt.start(problem), @oracle.nat(50000)).unwrap() {
    Satisfiable(model) => {
      let checked = @smt.check_model(problem, model)
      let eighth = @cad.evaluate_formula(
        @smt.point(model),
        @qf.Atom(p(3, [(1, [0, 0, 8]), (-2, [0, 0, 0])]), @qf.EqualZero),
      ).unwrap()
      println(
        "positive nested roots x^2=2, y^2=x, z^2=y: SAT; z^8=2: \{eighth}; model checked: \{checked}",
      )
    }
    _ => abort("nested-root demo did not return a model")
  }
  let impossible = @smt.prepare(
    @oracle.nat(1),
    @qf.Atom(p(1, [(1, [2])]), @qf.LessZero),
  ).unwrap()
  match @smt.run(@smt.start(impossible), @oracle.nat(50000)).unwrap() {
    Unsatisfiable(proof) => {
      let checked = @smt.check_refutation(impossible, proof)
      let lemmas = @oracle.int_of_nat(@core.length(proof.lemmas))
      println(
        "x^2 < 0: UNSAT; theory lemmas: \{lemmas}; CAD + RUP checked: \{checked}",
      )
    }
    _ => abort("impossible demo did not return a refutation")
  }
}
