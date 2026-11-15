///|
fn equal(a : Int32, b : Int32) -> Bool {
  a == b
}

///|
/// Exhaust all possible merge schedules, rather than implementing Huffman again.
fn optimal_merge_cost(weights : Array[Int32]) -> Int32 {
  if weights.length() <= 1 {
    return 0
  }
  let mut best = 999999
  for i in 0..<weights.length() {
    for j in (i + 1)..<weights.length() {
      let merged = weights[i] + weights[j]
      let rest = [
        for k in 0..<weights.length() if k != i && k != j => weights[k]
      ]
      rest.push(merged)
      best = Int32::min(best, merged + optimal_merge_cost(rest))
    }
  }
  best
}

///|
test "Huffman weighted path length matches every merge schedule for four-symbol alphabets" {
  for code in 0..<256 {
    let mut digits = code
    let weights = [
      for _ in 0..<4 => {
        let weight = digits % 4 + 1
        digits /= 4
        weight
      }
    ]
    let word = []
    for symbol in 0..<4 {
      for _ in 0..<weights[symbol] {
        word.push(symbol)
      }
    }
    let xs = @oracle.chain(word)
    match build(xs, equal) {
      None => fail("nonempty alphabet rejected")
      Some(tree) =>
        match encode(tree, xs, equal) {
          None => fail("known alphabet rejected")
          Some(bits) => {
            assert_eq(
              @oracle.int_of_nat(@core.length(bits)),
              optimal_merge_cost(weights),
            )
            assert_eq(decode(tree, bits), Some(xs))
            let words = [
              for symbol in 0..<4 => {
                @oracle.array(codeword(tree, symbol, equal).unwrap())
              }
            ]
            for i in 0..<4 {
              for j in 0..<4 {
                if i != j {
                  assert_false(
                    words[j].length() >= words[i].length() &&
                    words[j][:words[i].length()].to_owned() == words[i],
                  )
                }
              }
            }
            assert_eq(encode(tree, @oracle.chain([99]), equal), None)
          }
        }
    }
  }
}

///|
test "singleton, empty messages, unknown symbols and truncated codewords" {
  assert_eq(build(@core.Nil, equal), None)
  match build(@oracle.chain([7, 7, 7]), equal) {
    None => fail("singleton rejected")
    Some(tree) => {
      assert_eq(
        encode(tree, @oracle.chain([7, 7, 7]), equal),
        Some(@oracle.chain([false, false, false])),
      )
      assert_eq(
        decode(tree, @oracle.chain([false, false, false])),
        Some(@oracle.chain([7, 7, 7])),
      )
      assert_eq(decode(tree, @oracle.chain([true])), None)
      assert_eq(encode(tree, Nil, equal), Some(Nil))
      assert_eq(decode(tree, Nil), Some(Nil))
    }
  }
  match build(@oracle.chain([0, 1, 2, 2, 2]), equal) {
    None => fail("alphabet rejected")
    Some(tree) =>
      for symbol in 0..<3 {
        match codeword(tree, symbol, equal) {
          Some(Cons(first, Cons(_, _))) =>
            assert_eq(decode(tree, @oracle.chain([first])), None)
          _ => ()
        }
      }
  }
}
