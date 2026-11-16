///|
// Frozen pre-change implementation, including its length-first behavior.
fn compare_bits_reference(
  xs : @core.Chain[Bool],
  ys : @core.Chain[Bool],
) -> @core.Ordering {
  match (xs, ys) {
    (Nil, Nil) => Equal
    (Nil, Cons(_, _)) => Less
    (Cons(_, _), Nil) => Greater
    (Cons(x, xt), Cons(y, yt)) =>
      match compare_bits_reference(xt, yt) {
        Equal =>
          match (x, y) {
            (false, true) => Less
            (true, false) => Greater
            _ => Equal
          }
        order => order
      }
  }
}

///|
fn comparison_small_word(width : Int32, value : Int32) -> @core.Chain[Bool] {
  for bit = width - 1, result = @core.Nil; bit >= 0; {
    continue bit - 1, @core.Cons((value & (1 << bit)) != 0, result)
  } nobreak {
    result
  }
}

///|
fn comparison_array_word(xs : Array[Bool]) -> @core.Chain[Bool] {
  for bit = xs.length() - 1, result = @core.Nil; bit >= 0; {
    continue bit - 1, @core.Cons(xs[bit], result)
  } nobreak {
    result
  }
}

///|
// Independent high-to-low array oracle, with length checked before any bit.
fn comparison_array_order(xs : Array[Bool], ys : Array[Bool]) -> @core.Ordering {
  if xs.length() < ys.length() {
    Less
  } else if xs.length() > ys.length() {
    Greater
  } else {
    for bit = xs.length() - 1; bit >= 0; bit = bit - 1 {
      if xs[bit] != ys[bit] {
        return if xs[bit] { Greater } else { Less }
      }
    }
    Equal
  }
}

///|
test "tail comparison matches canonical integer order for every byte pair" {
  let values = [ for value in 0..<=255 => @oracle.binary(value) ]
  for x in 0..<=255 {
    for y in 0..<=255 {
      let expected = if x < y {
        @core.Less
      } else if x > y {
        @core.Greater
      } else {
        @core.Equal
      }
      assert_eq(compare_bits_tail(bits(values[x]), bits(values[y])), expected)
    }
  }
}

///|
test "tail comparison preserves old order for every short raw bit list pair" {
  let words = [@core.Nil]
  for width in 1..<=7 {
    for value in 0..<(1 << width) {
      words.push(comparison_small_word(width, value))
    }
  }
  for x in words {
    for y in words {
      assert_eq(compare_bits_tail(x, y), compare_bits_reference(x, y))
    }
  }
}

///|
test "tail comparison handles twenty-thousand-bit words without an unwind stack" {
  let equal = Array::make(20000, true)
  let low_difference = Array::make(20000, true)
  low_difference[0] = false
  let high_difference = Array::make(20000, true)
  high_difference[19998] = false
  let shorter = Array::make(19999, true)
  let raw_longer_zero = Array::make(20001, false)
  let equal_word = comparison_array_word(equal)
  for data in [equal, low_difference, high_difference, shorter, raw_longer_zero] {
    let other = comparison_array_word(data)
    assert_eq(
      compare_bits_tail(equal_word, other),
      comparison_array_order(equal, data),
    )
    assert_eq(
      compare_bits_tail(other, equal_word),
      comparison_array_order(data, equal),
    )
  }
}

///|
test "old and tail comparators on short and wide cohorts" (b : @bench.T) {
  let short_pairs = []
  for x in 0..<=15 {
    for y in 0..<=15 {
      short_pairs.push((bits(@oracle.binary(x)), bits(@oracle.binary(y))))
    }
  }
  b.bench(name="old short 256 pairs", fn() {
    for pair in short_pairs {
      b.keep(compare_bits_reference(pair.0, pair.1))
    }
  })
  b.bench(name="tail short 256 pairs", fn() {
    for pair in short_pairs {
      b.keep(compare_bits_tail(pair.0, pair.1))
    }
  })
  for width in [64, 2048] {
    let equal = Array::make(width, true)
    let dense = [ for bit in 0..<width => bit % 3 != 0 ]
    dense[width - 1] = true
    let low = Array::make(width, true)
    low[0] = false
    let high = Array::make(width, true)
    high[width - 2] = false
    let short = Array::make(width - 1, true)
    let left = comparison_array_word(equal)
    let cases = [
      comparison_array_word(equal),
      comparison_array_word(dense),
      comparison_array_word(low),
      comparison_array_word(high),
      comparison_array_word(short),
    ]
    let labels = ["equal", "dense", "low", "high", "width"]
    for index in 0..<cases.length() {
      let right = cases[index]
      let label = labels[index]
      b.bench(name="old \{label} \{width}", fn() {
        b.keep(compare_bits_reference(left, right))
      })
      b.bench(name="tail \{label} \{width}", fn() {
        b.keep(compare_bits_tail(left, right))
      })
    }
  }
}
