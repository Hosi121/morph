///|
fn bit_count(bits : Int32, rows : Int32) -> Int32 {
  [ for row in 0..<rows if (bits & (1 << row)) != 0 => row ].length()
}

///|
test "model counts of every three-variable function agree in all six orders" {
  for bits in 0..<256 {
    for
      ordering in [
        [0, 1, 2],
        [0, 2, 1],
        [1, 0, 2],
        [1, 2, 0],
        [2, 0, 1],
        [2, 1, 0],
      ] {
      let diagram = compile(shannon(3, bits), labels(ordering)).unwrap()
      assert_eq(model_count(diagram), Some(@oracle.binary(bit_count(bits, 8))))
    }
  }
}

///|
test "quantification agrees with every small truth table and preserves the declared domain" {
  for bits in 0..<256 {
    for ordering in [[0, 1, 2], [2, 0, 1]] {
      let diagram = compile(shannon(3, bits), labels(ordering)).unwrap()
      for variable in 0..<3 {
        let existential = exists_variable(diagram, @oracle.nat(variable)).unwrap()
        let universal = forall_variable(diagram, @oracle.nat(variable)).unwrap()
        assert_true(valid(existential))
        assert_true(valid(universal))
        assert_eq(order(existential), labels(ordering))
        assert_eq(order(universal), labels(ordering))
        let mut exists_count = 0
        let mut forall_count = 0
        for row in 0..<8 {
          let low = row & (7 ^ (1 << variable))
          let high = row | (1 << variable)
          let a = (bits & (1 << low)) != 0
          let b = (bits & (1 << high)) != 0
          assert_eq(evaluate(existential, model(3, row)), Some(a || b))
          assert_eq(evaluate(universal, model(3, row)), Some(a && b))
          if a || b {
            exists_count += 1
          }
          if a && b {
            forall_count += 1
          }
        }
        assert_eq(model_count(existential), Some(@oracle.binary(exists_count)))
        assert_eq(model_count(universal), Some(@oracle.binary(forall_count)))
      }
    }
  }
  let conjunction = compile(
    @circuit.Conjunction(source(0), source(1)),
    labels([0, 1]),
  ).unwrap()
  let exists = exists_variable(conjunction, @oracle.nat(0)).unwrap()
  assert_eq(model_count(exists), Some(@oracle.binary(2)))
  assert_eq(
    equivalent(exists, compile(source(1), labels([0, 1])).unwrap()),
    Some(true),
  )
  assert_true(exists_variable(conjunction, @oracle.nat(2)) is None)
  assert_true(forall_variable(conjunction, @oracle.nat(2)) is None)
}

///|
test "skipped levels extra variables empty domains and arbitrary-size counts are exact" {
  let empty_true = compile(@circuit.Constant(true), @core.Nil).unwrap()
  let empty_false = compile(@circuit.Constant(false), @core.Nil).unwrap()
  assert_eq(model_count(empty_true), Some(@binary.one()))
  assert_eq(model_count(empty_false), Some(@binary.zero()))
  let sparse = compile(source(65535), labels([65535])).unwrap()
  assert_eq(model_count(sparse), Some(@binary.one()))
  let many = labels([ for value in 0..<64 => value ])
  let all = compile(@circuit.Constant(true), many).unwrap()
  let count = model_count(all).unwrap()
  let bits = @oracle.array(@binary.bits(count))
  assert_eq(bits.length(), 65)
  for index, bit in bits {
    assert_eq(bit, index == 64)
  }
  let mut parity = @circuit.Constant(false)
  for variable in 0..<64 {
    parity = @circuit.Exclusive(parity, source(variable))
  }
  let odd = compile(parity, many).unwrap()
  assert_true(valid(odd))
  assert_eq(@oracle.int_of_nat(node_count(odd).unwrap()), 127)
  let bits = @oracle.array(@binary.bits(model_count(odd).unwrap()))
  assert_eq(bits.length(), 64)
  for index, bit in bits {
    assert_eq(bit, index == 63)
  }
  let skipped = compile(
    @circuit.Select(
      source(0),
      source(3),
      @circuit.Conjunction(source(1), source(3)),
    ),
    labels([0, 1, 2, 3, 4]),
  ).unwrap()
  let expected = [
    for row in 0..<32 if direct(
      @circuit.Select(
        source(0),
        source(3),
        @circuit.Conjunction(source(1), source(3)),
      ),
      row,
    ) => row
  ].length()
  assert_eq(model_count(skipped), Some(@oracle.binary(expected)))
}

///|
test "carry model count agrees with independent integer addition" {
  for width in 0..<=6 {
    let expression = carry_expression(width)
    let mask = (1 << width) - 1
    let mut expected = 0
    for row in 0..<(1 << (width + width + 1)) {
      let a = row & mask
      let b = (row >> width) & mask
      let carry = (row >> (width + width)) & 1
      if (a + b + carry) >> width != 0 {
        expected += 1
      }
    }
    for interleaved in [false, true] {
      let diagram = compile(expression, adder_order(width, interleaved)).unwrap()
      assert_eq(model_count(diagram), Some(@oracle.binary(expected)))
    }
  }
}

///|
test "model count width eight carry with blocked variables" (b : @bench.T) {
  let diagram = compile(carry_expression(8), adder_order(8, false)).unwrap()
  assert_eq(model_count(diagram), Some(@oracle.binary(65536)))
  b.bench(fn() { b.keep(model_count(diagram)) })
}

///|
test "same model count width eight carry with interleaved variables" (
  b : @bench.T,
) {
  let diagram = compile(carry_expression(8), adder_order(8, true)).unwrap()
  assert_eq(model_count(diagram), Some(@oracle.binary(65536)))
  b.bench(fn() { b.keep(model_count(diagram)) })
}
