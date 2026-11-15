///|
#derive(ToJson)
priv struct ExportStep {
  id : Int32
  clause : Array[Int32]
  hints : Array[Int32]
}

///|
#derive(ToJson)
priv struct ExportCase {
  name : String
  cnf : Array[Array[Int32]]
  steps : Array[ExportStep]
}

///|
fn dimacs(value : @sat.Literal) -> Int32 {
  let variable = @oracle.int_of_nat(value.variable) + 1
  if value.positive {
    variable
  } else {
    -variable
  }
}

///|
fn export_case(
  name : String,
  cnf : @sat.Cnf,
  logged : Certificate,
) -> Unit raise {
  assert_true(check(cnf, logged))
  let exported = ExportCase::{
    name,
    cnf: @oracle.array(cnf).map(fn(clause) { @oracle.array(clause).map(dimacs) }),
    steps: @oracle.array(logged.steps).map(fn(step) {
      ExportStep::{
        id: @oracle.int_of_binary(step.id),
        clause: @oracle.array(step.clause).map(dimacs),
        hints: @oracle.array(step.hints).map(@oracle.int_of_binary),
      }
    }),
  }
  println("MORPH_RUPLOG:\{@json.to_json(exported).stringify()}")
}

///|
fn export_both(
  name : String,
  cnf : @sat.Cnf,
  proof : @cdcl.Proof,
) -> Unit raise {
  let input = prepare(cnf)
  let scanned = build_scanning_prepared(input, proof).unwrap()
  let indexed = build_prepared(input, proof).unwrap()
  assert_eq(erase(scanned), erase(indexed))
  export_case("\{name}_scan", cnf, scanned)
  export_case("\{name}_occurrence", cnf, indexed)
}

///|
fn export_solved(name : String, cnf : @sat.Cnf) -> Unit raise {
  match @cdcl.run(@cdcl.start(cnf), @oracle.nat(200000)) {
    Unsatisfiable(proof) => export_both(name, cnf, proof)
    _ => fail("export fixture must be unsatisfiable")
  }
}

///|
// Opt-in numeric/JSON adapter only. Ordinary test runs perform no export.
test "export actual kernel certificates for independent native checkers" {
  match @env.get_env_var("MORPH_RUPLOG_EXPORT") {
    None => ()
    Some(selection) => {
      assert_true(selection == "small" || selection == "all")
      let empty = @cdcl.Rup(@core.Cons(@core.Nil, Nil))
      export_both("units", formula([[lit(0, true)], [lit(0, false)]]), empty)
      export_both(
        "chain",
        formula([[lit(0, true)], [lit(0, false), lit(1, true)], [lit(1, false)]]),
        empty,
      )
      export_both(
        "duplicates",
        formula([
          [lit(0, true), lit(0, true)],
          [lit(0, false), lit(0, false)],
          [lit(1, true), lit(1, false), lit(1, true)],
        ]),
        empty,
      )
      export_both("original_empty", formula([[]]), empty)
      export_solved(
        "cube",
        formula([
          [lit(0, true), lit(1, true)],
          [lit(0, false), lit(1, true)],
          [lit(0, true), lit(1, false)],
          [lit(0, false), lit(1, false)],
        ]),
      )
      export_solved("pigeonhole_4_3", pigeonhole(4, 3))
      let (cnf, proof) = miter(8)
      export_both("miter8", cnf, proof)
      if selection == "all" {
        let (cnf, proof) = miter(64)
        export_both("miter64", cnf, proof)
      }
    }
  }
}
