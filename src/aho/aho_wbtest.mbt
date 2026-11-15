///|
fn words(maximum : Int32) -> Array[Array[Bool]] {
  let result = []
  for length in 0..<=maximum {
    for value in 0..<(1 << length) {
      result.push([ for i in 0..<length => (value & (1 << i)) != 0 ])
    }
  }
  result
}

///|
fn keys(matches : @core.Chain[Match]) -> Array[Int32] {
  let result = @oracle.array(matches).map(fn(m) {
    @oracle.int_of_nat(m.end) * 256 +
    @oracle.int_of_nat(m.label) * 16 +
    @oracle.int_of_nat(m.start)
  })
  result.sort()
  result
}

///|
fn naive(patterns : Array[Pattern], word : Array[Bool]) -> Array[Int32] {
  let result = []
  for end in 0..<=word.length() {
    for pattern in patterns {
      let needle = @oracle.array(pattern.word)
      let start = end - needle.length()
      if start >= 0 && word[start:end].to_owned() == needle {
        result.push(end * 256 + @oracle.int_of_nat(pattern.label) * 16 + start)
      }
    }
  }
  result.sort()
  result
}

///|
test "all 128 short dictionaries and 256 longer dictionaries versus naive matching" {
  let candidates = words(3).map(fn(word) { @oracle.chain(word) })
  let texts = words(6)
  for case_index in 0..<384 {
    let mask = if case_index < 128 {
      case_index
    } else {
      ((case_index - 128) * 7919 + 12345) & 32767
    }
    let patterns = [
      for i in 0..<15 if (mask & (1 << i)) != 0 => {
        Pattern::{ label: @oracle.nat(i), word: candidates[i], }
      }
    ]
    let automaton = plan(@oracle.chain(patterns)).unwrap()
    for word in texts {
      assert_eq(
        keys(find_all(automaton, @oracle.chain(word))),
        naive(patterns, word),
      )
    }
  }
}

///|
test "failure suffixes, inherited output, duplicate words and every chunk boundary" {
  let raw = [
    [],
    [false],
    [false, true],
    [false, false, true],
    [true],
    [false, true],
  ]
  let patterns = [
    for i in 0..<raw.length() => {
      Pattern::{ label: @oracle.nat(i), word: @oracle.chain(raw[i]), }
    }
  ]
  let automaton = plan(@oracle.chain(patterns)).unwrap()
  for (prefix, current) in @oracle.array(@trie.entries(automaton.nodes)) {
    let word = @oracle.array(prefix)
    let failure = @oracle.array(current.failure)
    if word.length() != 0 {
      assert_true(failure.length() < word.length())
      assert_eq(word[word.length() - failure.length():].to_owned(), failure)
    }
    let output_keys = @oracle.array(current.outputs).map(fn(out) {
      @oracle.int_of_nat(out.label)
    })
    let expected = [
      for i in 0..<raw.length() if raw[i].length() <= word.length() &&
      word[word.length() - raw[i].length():].to_owned() == raw[i] => i
    ]
    output_keys.sort()
    assert_eq(output_keys, expected)
  }
  for word in words(6) {
    let all = find_all(automaton, @oracle.chain(word))
    for split in 0..<=word.length() {
      let initial = start(automaton)
      let (left, state) = feed(initial, @oracle.chain(word[:split].to_owned()))
      let (empty, state) = feed(state, Nil)
      assert_eq(empty, Nil)
      let (right, _) = feed(state, @oracle.chain(word[split:].to_owned()))
      assert_eq(@core.append(left, right), all)
      assert_eq(
        feed(initial, @oracle.chain(word)),
        feed(initial, @oracle.chain(word)),
      )
    }
  }
  let empty = plan(Nil).unwrap()
  assert_eq(find_all(empty, @oracle.chain([true, false])), Nil)
  assert_eq(plan(@oracle.chain([patterns[0], patterns[0]])), None)
}
