///|
fn bool_words() -> Array[Array[Bool]] {
  let result = []
  for n in 0..<=5 {
    for code in 0..<(1 << n) {
      result.push([ for i in 0..<n => (code & (1 << i)) != 0 ])
    }
  }
  result
}

///|
fn edit_oracle(xs : Array[Bool], ys : Array[Bool]) -> Int32 {
  let table = [
    for i in 0..<=xs.length() => {
      [
        for j in 0..<=ys.length() => {
          if i == 0 {
            j
          } else if j == 0 {
            i
          } else {
            0
          }
        }
      ]
    }
  ]
  for i in 1..<=xs.length() {
    for j in 1..<=ys.length() {
      table[i][j] = if xs[i - 1] == ys[j - 1] {
        table[i - 1][j - 1]
      } else {
        1 +
        Int32::min(
          table[i - 1][j - 1],
          Int32::min(table[i - 1][j], table[i][j - 1]),
        )
      }
    }
  }
  table[xs.length()][ys.length()]
}

///|
fn subsequence(needle : Array[Bool], haystack : Array[Bool]) -> Bool {
  let mut index = 0
  for value in haystack {
    if index < needle.length() && needle[index] == value {
      index += 1
    }
  }
  index == needle.length()
}

///|
fn lcs_oracle(xs : Array[Bool], ys : Array[Bool]) -> Int32 {
  let mut best = 0
  for mask in 0..<(1 << xs.length()) {
    let candidate = [
      for i in 0..<xs.length() if (mask & (1 << i)) != 0 => xs[i]
    ]
    if subsequence(candidate, ys) {
      best = Int32::max(best, candidate.length())
    }
  }
  best
}

///|
test "edit distance, optimal scripts and LCS exhaust all binary words through length five" {
  let equal = fn(a : Bool, b : Bool) { a == b }
  let words = bool_words()
  for x in words {
    for y in words {
      let xs = @oracle.chain(x)
      let ys = @oracle.chain(y)
      let distance = edit_oracle(x, y)
      assert_eq(@oracle.int_of_nat(levenshtein(xs, ys, equal)), distance)
      let edits = edit_script(xs, ys, equal)
      assert_eq(apply_script(xs, edits, equal), Some(ys))
      let cost = @oracle.array(edits)
        .filter(fn(edit) {
          match edit {
            Keep(_) => false
            _ => true
          }
        })
        .length()
      assert_eq(cost, distance)
      let result = @oracle.array(lcs(xs, ys, equal))
      assert_true(subsequence(result, x) && subsequence(result, y))
      assert_eq(result.length(), lcs_oracle(x, y))
    }
  }
  assert_eq(
    apply_script(@oracle.chain([true]), @oracle.chain([Keep(false)]), equal),
    None,
  )
  assert_eq(apply_script(@oracle.chain([true]), Nil, equal), None)
}
