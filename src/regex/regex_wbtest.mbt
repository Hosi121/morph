///|
test "derivatives and Thompson automata agree on all depth-two regexes and short binary words" {
  let base : Array[Regex[Bool]] = [Empty, Epsilon, Atom(false), Atom(true)]
  let depth_one = base.copy()
  for a in base {
    depth_one.push(Repeat(a))
    for b in base {
      depth_one.push(Choice(a, b))
      depth_one.push(Sequence(a, b))
    }
  }
  let expressions = base.copy()
  for a in depth_one {
    expressions.push(Repeat(a))
    for b in depth_one {
      expressions.push(Choice(a, b))
      expressions.push(Sequence(a, b))
    }
  }
  let words = []
  for n in 0..<=4 {
    for mask in 0..<(1 << n) {
      words.push(@oracle.chain([ for i in 0..<n => (mask & (1 << i)) != 0 ]))
    }
  }
  let eq = fn(a : Bool, b : Bool) { a == b }
  for expression in expressions {
    let nfa = compile(expression)
    for word in words {
      assert_eq(matches(expression, word, eq), nfa_matches(nfa, word, eq))
    }
  }
}

///|
test "nullable loops, empty language and a known language" {
  let eq = fn(a : Bool, b : Bool) { a == b }
  let expression = Sequence(
    Repeat(Choice(Atom(false), Atom(true))),
    Sequence(Atom(true), Atom(false)),
  )
  for n in 0..<=7 {
    for mask in 0..<(1 << n) {
      let word = [ for i in 0..<n => (mask & (1 << i)) != 0 ]
      let expected = n >= 2 && word[n - 2] && !word[n - 1]
      assert_eq(matches(expression, @oracle.chain(word), eq), expected)
    }
  }
  assert_true(nfa_matches(compile(Repeat(Repeat(Epsilon))), Nil, eq))
  assert_false(matches(Empty, Nil, eq))
  assert_true(matches(Repeat(Empty), Nil, eq))
}
