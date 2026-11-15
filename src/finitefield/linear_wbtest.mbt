///|
test "shared field Gaussian solver versus all assignments over the field of three" {
  let field = field(@oracle.binary(3)).unwrap()
  for matrix in 0..<81 {
    let entries = [ for i in 0..<4 => matrix / [1, 3, 9, 27][i] % 3 ]
    let a = @matrix.matrix(
      @oracle.nat(2),
      @oracle.chain([
        @oracle.chain(entries[:2].to_owned().map(@oracle.binary)),
        @oracle.chain(entries[2:].to_owned().map(@oracle.binary)),
      ]),
    ).unwrap()
    for rhs in 0..<9 {
      let b = [rhs % 3, rhs / 3]
      let solutions = []
      for x in 0..<3 {
        for y in 0..<3 {
          if (entries[0] * x + entries[1] * y) % 3 == b[0] &&
            (entries[2] * x + entries[3] * y) % 3 == b[1] {
            solutions.push([x, y])
          }
        }
      }
      match
        @rowreduce.solve(
          arithmetic(field),
          a,
          @oracle.chain(b.map(@oracle.binary)),
        ).unwrap() {
        Inconsistent => assert_true(solutions.is_empty())
        Unique(values) => {
          assert_eq(solutions.length(), 1)
          assert_eq(
            @oracle.array(values).map(@oracle.int_of_binary),
            solutions[0],
          )
        }
        Affine(particular, basis) => {
          assert_true(solutions.length() > 1)
          let p = @oracle.array(particular).map(@oracle.int_of_binary)
          assert_true(solutions.contains(p))
          for direction in @oracle.array(basis) {
            let d = @oracle.array(direction).map(@oracle.int_of_binary)
            for scale in 0..<3 {
              assert_true(
                solutions.contains([
                  (p[0] + scale * d[0]) % 3,
                  (p[1] + scale * d[1]) % 3,
                ]),
              )
            }
          }
        }
      }
    }
  }
}
