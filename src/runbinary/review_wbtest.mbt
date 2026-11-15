///|
fn review_binary64(value : UInt64) -> @binary.Binary {
  let bits = []
  let mut remaining = value
  while remaining != 0UL {
    bits.push((remaining & 1UL) != 0UL)
    remaining = remaining >> 1
  }
  @binary.from_bits(@oracle.chain(bits))
}

///|
fn review_expanded(value : Number, maximum : Int32) -> @binary.Binary {
  match expand(value, @oracle.binary(maximum)) {
    Some(value) => value
    None => abort("review expansion exceeds the explicit bound")
  }
}

///|
fn review_canonical(value : Number) -> Bool {
  let blocks = @oracle.array(runs(value))
  for index in 0..<blocks.length() {
    if @binary.is_zero(blocks[index].length) {
      return false
    }
    if index > 0 && blocks[index - 1].bit == blocks[index].bit {
      return false
    }
  }
  blocks.is_empty() || blocks[blocks.length() - 1].bit
}

///|
test "review: exhaustive raw four-run normalization ignores zero blocks merges adjacency and trims high zeros" {
  for code in 0..<10000 {
    let mut remaining = code
    let mut offset = 0
    let mut expected = 0
    let raw = [
      for _ in 0..<4 => {
        let digit = remaining % 10
        remaining /= 10
        let length = digit / 2
        let bit = digit % 2 == 1
        if bit {
          for i in 0..<length {
            expected = expected | (1 << (offset + i))
          }
        }
        offset += length
        Run::{ bit, length: @oracle.binary(length), }
      }
    ]
    let value = from_runs(@oracle.chain(raw))
    assert_true(review_canonical(value))
    assert_eq(review_expanded(value, 16), @oracle.binary(expected))
    assert_eq(from_binary(@oracle.binary(expected)), value)
    assert_eq(from_runs(runs(value)), value)
    let expected_width = if expected == 0 {
      0
    } else {
      for n = expected, width = 0; n > 0; {
        continue n / 2, width + 1
      } nobreak {
        width
      }
    }
    assert_eq(width(value), @oracle.binary(expected_width))
    assert_eq(
      expand(value, @oracle.binary(expected_width)),
      Some(@oracle.binary(expected)),
    )
    if expected_width > 0 {
      assert_eq(expand(value, @oracle.binary(expected_width - 1)), None)
    }
  }
}

///|
test "review: machine-wide arithmetic and exact run boundary shifts match UInt64" {
  let cases : Array[UInt64] = [
    0UL, 1UL, 2UL, 3UL, 7UL, 15UL, 255UL, 256UL, 65535UL, 65536UL, 2147483647UL,
  ]
  for a in cases {
    let left = from_binary(review_binary64(a))
    assert_eq(review_expanded(successor(left), 64), review_binary64(a + 1UL))
    for b in cases {
      let right = from_binary(review_binary64(b))
      let sum = add(left, right)
      let product = multiply(left, right)
      assert_true(review_canonical(sum))
      assert_true(review_canonical(product))
      assert_eq(review_expanded(sum, 64), review_binary64(a + b))
      assert_eq(review_expanded(product, 64), review_binary64(a * b))
      assert_eq(
        compare(left, right),
        if a < b {
          @core.Less
        } else if a > b {
          @core.Greater
        } else {
          @core.Equal
        },
      )
      match subtract(left, right) {
        None => assert_true(a < b)
        Some(difference) => {
          assert_true(a >= b)
          assert_true(review_canonical(difference))
          assert_eq(review_expanded(difference, 64), review_binary64(a - b))
        }
      }
    }
    for amount in 0..<=31 {
      assert_eq(
        review_expanded(shift_left(left, @oracle.binary(amount)), 64),
        review_binary64(a << amount),
      )
      assert_eq(
        review_expanded(shift_right(left, @oracle.binary(amount)), 64),
        review_binary64(a >> amount),
      )
    }
    assert_eq(shift_right(left, @oracle.binary(64)), zero())
    assert_eq(shift_right(left, width(left)), zero())
    for exponent in [0, 1, 2, 7, 15, 16, 24] {
      let encoded = pair(@oracle.binary(exponent), left)
      assert_eq(
        review_expanded(encoded, 64),
        review_binary64(((a << 1) | 1UL) << exponent),
      )
      assert_eq(unpair(encoded), Some((@oracle.binary(exponent), left)))
    }
  }
}

///|
test "review: unequal block boundaries match per-bit Binary arithmetic through 256-bit inputs" {
  let mut state = 15131
  for family in 0..<160 {
    let make = fn(seed : Int32) {
      let raw = [
        for index in 0..<8 => {
          let count = 1 + (seed + index * 17 + family * 29) % 32
          Run::{
            bit: (seed + index * 13) % 3 != 0,
            length: @oracle.binary(count),
          }
        }
      ]
      from_runs(@oracle.chain(raw))
    }
    state = (state * 109 + 89) % 65521
    let a = make(state)
    state = (state * 109 + 89) % 65521
    let b = make(state)
    let binary_a = review_expanded(a, 256)
    let binary_b = review_expanded(b, 256)
    assert_eq(review_expanded(add(a, b), 512), @binary.add(binary_a, binary_b))
    assert_eq(
      review_expanded(multiply(a, b), 512),
      @binary.multiply(binary_a, binary_b),
    )
    assert_eq(
      subtract(a, b).map(fn(value) { review_expanded(value, 256) }),
      @binary.subtract(binary_a, binary_b),
    )
    assert_eq(compare(a, b), @binary.compare(binary_a, binary_b))
    let boundaries = @oracle.array(runs(a))
    let mut offset = 0
    for block in boundaries {
      offset += @oracle.int_of_binary(block.length)
      for amount in [offset - 1, offset, offset + 1] {
        let shifted = shift_right(a, @oracle.binary(amount))
        let expected = @binary.from_bits(
          @core.drop(@oracle.nat(amount), @binary.bits(binary_a)),
        )
        assert_true(review_canonical(shifted))
        assert_eq(review_expanded(shifted, 256), expected)
      }
    }
  }
}

///|
test "review: astronomical widths preserve algebraic block identities without expansion" {
  let e = @binary.power(@oracle.binary(2), @oracle.binary(2048))
  let e_minus_one = @binary.subtract(e, @binary.one()).unwrap()
  let e_minus_two = @binary.subtract(e, @oracle.binary(2)).unwrap()
  let two_e = @binary.double(e)
  let p = power_of_two(e)
  let p2 = power_of_two(two_e)
  let m = from_runs(@core.Cons({ bit: true, length: e, }, Nil))
  let m2 = from_runs(@core.Cons({ bit: true, length: two_e, }, Nil))
  assert_eq(
    add(m, p),
    from_runs(@core.Cons({ bit: true, length: @binary.successor(e), }, Nil)),
  )
  assert_eq(add(m, m), shift_left(m, @binary.one()))
  assert_eq(multiply(m, successor(p)), m2)
  assert_eq(subtract(p2, p), Some(shift_left(m, e)))
  assert_eq(
    subtract(p2, successor(p)),
    Some(
      from_runs(
        @oracle.chain([
          Run::{ bit: true, length: e, },
          { bit: false, length: @binary.one(), },
          { bit: true, length: e_minus_one, },
        ]),
      ),
    ),
  )
  let squared_plus = multiply(successor(p), successor(p))
  assert_eq(
    squared_plus,
    from_runs(
      @oracle.chain([
        Run::{ bit: true, length: @binary.one(), },
        { bit: false, length: e, },
        { bit: true, length: @binary.one(), },
        { bit: false, length: e_minus_two, },
        { bit: true, length: @binary.one(), },
      ]),
    ),
  )
  assert_eq(width(squared_plus), @binary.successor(two_e))
  let high = add(p2, p)
  let low = successor(p2)
  assert_eq(width(high), width(low))
  assert_eq(compare(high, low), @core.Greater)
  assert_eq(compare(low, high), @core.Less)
  assert_eq(subtract(high, low), Some(m))
  assert_eq(shift_right(p, e_minus_one), small(2))
  assert_eq(shift_right(p, e), one())
  assert_eq(shift_right(p, @binary.successor(e)), zero())
  assert_eq(shift_left(zero(), e), zero())
  assert_eq(expand(squared_plus, @oracle.binary(4096)), None)
  assert_eq(unpair(pair(e, successor(p))), Some((e, successor(p))))
  assert_eq(pair(e, zero()), p)
  assert_eq(unpair(p), Some((e, zero())))
  for value in [p, p2, m, m2, squared_plus, high, low] {
    assert_true(review_canonical(value))
  }
}
