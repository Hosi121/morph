///|
test "all four-row three-column exact covers agree with the binary linear model" {
  for mask in 0..<4096 {
    let rows = [
      for row in 0..<4 => {
        @exactcover.Row::{
          label: @oracle.nat(row),
          columns: @oracle.chain(
            [
              for col in 0..<3 if (mask & (1 << (row * 3 + col))) != 0 => {
                @oracle.nat(col)
              }
            ],
          ),
        }
      }
    ]
    let cover = @exactcover.problem(
      @oracle.chain([0, 1, 2].map(@oracle.nat)),
      Nil,
      @oracle.chain(rows),
    ).unwrap()
    // Each primary column becomes sum(incident row variables)=one.
    let incidence = [
      for col in 0..<3 => {
        [
          for row in 0..<4 => {
            if (mask & (1 << (row * 3 + col))) != 0 {
              1
            } else {
              0
            }
          }
        ]
      }
    ]
    let constraints = incidence +
      incidence.map(fn(row) { row.map(fn(x) { -x }) })
    let p = make_problem(constraints, [1, 1, 1, -1, -1, -1], [0, 0, 0, 0])
    match (@exactcover.solve(cover), finish(p)) {
      (Some(labels), Complete(candidate, proof)) => {
        assert_true(@exactcover.check(cover, labels))
        assert_true(check_optimal(p, candidate, proof))
        let assignment = @oracle.array(candidate.assignment)
        let selected = @oracle.chain(
          [
            for i in 0..<4 if assignment[i] => @oracle.nat(i)
          ],
        )
        assert_true(@exactcover.check(cover, selected))
      }
      (None, Infeasible(proof)) => assert_true(check_infeasible(p, proof))
      _ => fail("exact cover and its 0/1 equality model disagree")
    }
  }
}

///|
test "all pairs of three-variable clauses agree with their 0/1 inequality model" {
  for a in 0..<27 {
    for b in 0..<27 {
      let clauses = [a, b].map(fn(code) {
        [
          for variable in 0..<3 => code / [1, 3, 9][variable] % 3
        ]
      })
      let cnf = @oracle.chain(
        clauses.map(fn(clause) {
          @oracle.chain(
            [
              for i in 0..<3 if clause[i] != 0 => {
                @sat.Literal::{
                  variable: @oracle.nat(i),
                  positive: clause[i] == 1,
                }
              }
            ],
          )
        }),
      )
      // For each clause, negatives + sum(positive*x-negative*x) >= one.
      let matrix = clauses.map(fn(clause) {
        clause.map(fn(sign) {
          if sign == 1 {
            -1
          } else if sign == 2 {
            1
          } else {
            0
          }
        })
      })
      let bounds = clauses.map(fn(clause) {
        clause.filter(fn(sign) { sign == 2 }).length() - 1
      })
      let p = make_problem(matrix, bounds, [0, 0, 0])
      match (@sat.solve(cnf), finish(p)) {
        (Satisfiable(_), Complete(candidate, proof)) => {
          assert_true(check_optimal(p, candidate, proof))
          let model = @oracle.chain(
            [
              for i in 0..<3 => {
                @sat.Literal::{
                  variable: @oracle.nat(i),
                  positive: @oracle.array(candidate.assignment)[i],
                }
              }
            ],
          )
          assert_true(@sat.check_model(cnf, model))
        }
        (Unsatisfiable(refutation), Infeasible(proof)) => {
          assert_true(@sat.check_refutation(cnf, refutation))
          assert_true(check_infeasible(p, proof))
        }
        _ => fail("SAT and its 0/1 inequality model disagree")
      }
    }
  }
}
