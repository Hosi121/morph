///|
fn word(bits : Int32, length : Int32) -> @core.Chain[Bool] {
  @oracle.chain([ for i in 0..<length => (bits & (1 << i)) != 0 ])
}

///|
test "all two-symbol CNF grammars versus independent recursive derivation" {
  let symbols = @oracle.chain([@oracle.nat(0), @oracle.nat(1)])
  let candidates : Array[Rule[Bool]] = [
    Terminal(@oracle.nat(0), false),
    Terminal(@oracle.nat(0), true),
    Terminal(@oracle.nat(1), false),
    Terminal(@oracle.nat(1), true),
    ..[
      for i in 0..<8 => {
        Binary(@oracle.nat(i / 4), @oracle.nat(i / 2 % 2), @oracle.nat(i % 2))
      }
    ],
  ]
  for mask in 0..<4096 {
    fn expected(symbol : Int32, tokens : Array[Bool]) -> Bool {
      if tokens.length() == 0 {
        return false
      }
      if tokens.length() == 1 {
        return (mask & (1 << (symbol * 2 + (if tokens[0] { 1 } else { 0 })))) !=
          0
      }
      for a in 0..<2 {
        for b in 0..<2 {
          let bit = 4 + symbol * 4 + a * 2 + b
          if (mask & (1 << bit)) == 0 {
            continue
          }
          for split in 1..<tokens.length() {
            if expected(a, tokens[:split].to_owned()) &&
              expected(b, tokens[split:].to_owned()) {
              return true
            }
          }
        }
      }
      false
    }
    let rules = @oracle.chain(
      [
        for i in 0..<12 if (mask & (1 << i)) != 0 => candidates[i]
      ],
    )
    let g = grammar(symbols, @oracle.nat(0), rules, false).unwrap()
    for length in 0..<=3 {
      for bits in 0..<(1 << length) {
        let input = word(bits, length)
        let accepts = expected(0, @oracle.array(input))
        match parse(g, input, fn(a, b) { a == b }) {
          None => assert_false(accepts)
          Some(tree) => {
            assert_true(accepts)
            assert_eq(yield_word(tree), input)
            assert_true(check(g, input, tree, fn(a, b) { a == b }))
          }
        }
      }
    }
  }
}

///|
test "balanced brackets grammar, nullable start and forged witnesses" {
  // S -> L R | L C | B B; B -> L R | L C | B B; C -> B R.
  // L -> '(' and R -> ')'. S is absent from every right hand side.
  let s = @oracle.nat(0)
  let b = @oracle.nat(1)
  let c = @oracle.nat(2)
  let l = @oracle.nat(3)
  let r = @oracle.nat(4)
  let rules = @oracle.chain([
    Binary(s, l, r),
    Binary(s, l, c),
    Binary(s, b, b),
    Binary(b, l, r),
    Binary(b, l, c),
    Binary(b, b, b),
    Binary(c, b, r),
    Terminal(l, false),
    Terminal(r, true),
  ])
  let symbols = @oracle.chain([s, b, c, l, r])
  let g = grammar(symbols, s, rules, true).unwrap()
  for length in 0..<=8 {
    for bits in 0..<(1 << length) {
      let tokens = [ for i in 0..<length => (bits & (1 << i)) != 0 ]
      let mut depth = 0
      let mut valid = true
      for token in tokens {
        depth += if token { -1 } else { 1 }
        if depth < 0 {
          valid = false
        }
      }
      valid = valid && depth == 0
      let input = @oracle.chain(tokens)
      match parse(g, input, fn(a, b) { a == b }) {
        None => assert_false(valid)
        Some(tree) => {
          assert_true(valid)
          assert_true(check(g, input, tree, fn(a, b) { a == b }))
        }
      }
    }
  }
  assert_false(check(g, word(0, 1), Leaf(s, false), fn(a, b) { a == b }))
  assert_false(
    check(g, word(2, 2), Branch(s, Empty(b), Leaf(r, true)), fn(a, b) { a == b }),
  )
  assert_false(check(g, word(0, 1), Empty(s), fn(a, b) { a == b }))
  assert_eq(grammar(symbols, s, @core.Cons(Binary(s, s, b), rules), true), None)
  let no_rules : @core.Chain[Rule[Bool]] = Nil
  assert_eq(grammar(@oracle.chain([s, s]), s, no_rules, false), None)
  assert_eq(
    grammar(
      symbols,
      s,
      @core.Cons(Terminal(@oracle.nat(9), false), rules),
      false,
    ),
    None,
  )
}

///|
test "left recursive ambiguous grammar produces a finite witness" {
  let s = @oracle.nat(0)
  let g = grammar(
    @oracle.chain([s]),
    s,
    @oracle.chain([Terminal(s, true), Binary(s, s, s), Terminal(s, true)]),
    false,
  ).unwrap()
  for length in 1..<=12 {
    let input = @core.replicate(@oracle.nat(length), true)
    let tree = parse(g, input, fn(a, b) { a == b }).unwrap()
    assert_true(check(g, input, tree, fn(a, b) { a == b }))
  }
}
