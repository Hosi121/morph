///|
fn test_field(p : Int32) -> @rowreduce.Field[@binary.Binary] {
  match @primefield.field(@oracle.binary(p)) {
    Some(field) => @primefield.arithmetic(field)
    None => abort("BM test prime field")
  }
}

///|
fn rational_field() -> @rowreduce.Field[@exact.Rational] {
  {
    zero: @exact.rational_zero(),
    one: @exact.rational_one(),
    add: @exact.rational_add,
    subtract: @exact.rational_subtract,
    negate: @exact.rational_negate,
    multiply: @exact.rational_multiply,
    inverse: fn(value) {
      match @exact.nonzero(value) {
        None => None
        Some(nonzero) => Some(@exact.reciprocal(nonzero))
      }
    },
  }
}

///|
fn native_mod(value : Int32, p : Int32) -> Int32 {
  (value % p + p) % p
}

///|
fn native_consistent(
  sequence : Array[Int32],
  length : Int32,
  p : Int32,
) -> Bool {
  let rows = [
    for n in length..<sequence.length() => {
      let row = [ for lag in 1..<=length => sequence[n - lag] ]
      row.push(native_mod(-sequence[n], p))
      row
    }
  ]
  let mut pivot = 0
  for column in 0..<length {
    let found = for row in pivot..<rows.length() {
      if rows[row][column] != 0 {
        break Some(row)
      }
    } nobreak {
      None
    }
    match found {
      None => ()
      Some(found) => {
        let temporary = rows[pivot]
        rows[pivot] = rows[found]
        rows[found] = temporary
        let inverse = for candidate in 1..<p {
          if candidate * rows[pivot][column] % p == 1 {
            break candidate
          }
        } nobreak {
          abort("native BM inverse")
        }
        for c in column..<=length {
          rows[pivot][c] = rows[pivot][c] * inverse % p
        }
        for row in 0..<rows.length() {
          if row != pivot {
            let scalar = rows[row][column]
            for c in column..<=length {
              rows[row][c] = native_mod(
                rows[row][c] - scalar * rows[pivot][c],
                p,
              )
            }
          }
        }
        pivot += 1
      }
    }
  }
  rows.all(fn(row) {
    row[:length].to_owned().any(fn(value) { value != 0 }) || row[length] == 0
  })
}

///|
fn native_minimum(sequence : Array[Int32], p : Int32) -> Int32 {
  for length in 0..<=sequence.length() {
    if native_consistent(sequence, length, p) {
      return length
    }
  }
  abort("finite sequence always admits its full length")
}

///|
fn assert_rational_fixture(
  input : Array[(Int32, Int32)],
  expected_length : Int32,
) -> Unit raise {
  let field = rational_field()
  let input = @oracle.chain(
    input.map(fn(pair) { @oracle.rational(pair.0, pair.1) }),
  )
  let result = match berlekamp_massey(field, input) {
    Some(result) => result
    None => abort("rational BM")
  }
  assert_eq(result.length, @oracle.nat(expected_length))
  assert_true(check(field, input, result))
}

///|
test "minimal recurrence lengths exhaust small prime-field sequences against native linear systems" {
  for (p, maximum) in [(2, 8), (3, 6), (5, 4)] {
    let field = test_field(p)
    let mut count = 1
    for width in 0..<=maximum {
      for code in 0..<count {
        let mut remaining = code
        let sequence = [
          for _ in 0..<width => {
            let digit = remaining % p
            remaining /= p
            digit
          }
        ]
        let symbolic = @oracle.chain(sequence.map(@oracle.binary))
        let result = match berlekamp_massey(field, symbolic) {
          Some(value) => value
          None => abort("finite BM result")
        }
        let length = @oracle.int_of_nat(result.length)
        assert_eq(length, native_minimum(sequence, p))
        assert_true(check(field, symbolic, result))
        let coefficients = @oracle.array(result.connection).map(
          @oracle.int_of_binary,
        )
        assert_eq(coefficients.length(), length + 1)
        assert_eq(coefficients[0], 1)
        for n in length..<width {
          let total = for lag = 0, total = 0; lag <= length; {
            continue lag + 1, total + coefficients[lag] * sequence[n - lag]
          } nobreak {
            total
          }
          assert_eq(total % p, 0)
          assert_eq(
            predict(
              field,
              result,
              @oracle.chain(
                sequence[n - length:n].to_owned().map(@oracle.binary),
              ),
            ),
            Some(@oracle.binary(sequence[n])),
          )
        }
      }
      count *= p
    }
  }
}

///|
test "finite-prefix length is retained when the connection polynomial loses its last coefficient" {
  let field = test_field(5)
  let input = @oracle.chain([@oracle.binary(1), @oracle.binary(0)])
  let result = match berlekamp_massey(field, input) {
    Some(value) => value
    None => abort("finite-prefix BM")
  }
  assert_eq(result.length, @oracle.nat(1))
  assert_eq(
    result.connection,
    @oracle.chain([@oracle.binary(1), @oracle.binary(0)]),
  )
  assert_true(check(field, input, result))
  assert_eq(
    predict(field, result, @core.Cons(@oracle.binary(0), Nil)),
    Some(@oracle.binary(0)),
  )
  let zero = @core.replicate(@oracle.nat(5), @oracle.binary(0))
  let zero_result = match berlekamp_massey(field, zero) {
    Some(value) => value
    None => abort("zero BM")
  }
  assert_eq(zero_result.length, @oracle.nat(0))
  assert_eq(zero_result.connection, @core.Cons(@oracle.binary(1), Nil))
  assert_eq(predict(field, zero_result, @core.Nil), Some(@oracle.binary(0)))
}

///|
test "rational Fibonacci and polynomial sequences have exact expected connections" {
  let field = rational_field()
  let fibonacci = @oracle.chain(
    [0, 1, 1, 2, 3, 5, 8, 13, 21, 34].map(fn(value) {
      @oracle.rational(value, 1)
    }),
  )
  let result = match berlekamp_massey(field, fibonacci) {
    Some(value) => value
    None => abort("Fibonacci BM")
  }
  assert_eq(result.length, @oracle.nat(2))
  assert_eq(
    result.connection,
    @oracle.chain([1, -1, -1].map(fn(value) { @oracle.rational(value, 1) })),
  )
  assert_eq(
    predict(
      field,
      result,
      @oracle.chain([@oracle.rational(21, 1), @oracle.rational(34, 1)]),
    ),
    Some(@oracle.rational(55, 1)),
  )
  let square = @oracle.chain(
    [
      for n in 0..<12 => @oracle.rational(n * n + 3 * n + 1, 1)
    ],
  )
  let result = match berlekamp_massey(field, square) {
    Some(value) => value
    None => abort("polynomial BM")
  }
  assert_eq(result.length, @oracle.nat(3))
  assert_eq(
    result.connection,
    @oracle.chain([1, -3, 3, -1].map(fn(value) { @oracle.rational(value, 1) })),
  )
}

///|
test "independent checker rejects forged shapes and equations without claiming minimality" {
  let field = test_field(5)
  let input = @oracle.chain([1, 2, 4, 3, 1, 2].map(@oracle.binary))
  let result = match berlekamp_massey(field, input) {
    Some(value) => value
    None => abort("geometric BM")
  }
  assert_eq(result.length, @oracle.nat(1))
  assert_false(check(field, input, { ..result, connection: @core.Nil, }))
  assert_false(
    check(field, input, {
      ..result,
      connection: @oracle.chain([@oracle.binary(0), @oracle.binary(3)]),
    }),
  )
  assert_false(
    check(field, input, {
      ..result,
      connection: @oracle.chain([@oracle.binary(1), @oracle.binary(2)]),
    }),
  )
  assert_false(check(field, input, { ..result, length: @oracle.nat(0), }))
  assert_false(
    check(field, input, {
      length: @oracle.nat(7),
      connection: @oracle.chain([1, 0, 0, 0, 0, 0, 0, 0].map(@oracle.binary)),
    }),
  )
  assert_eq(predict(field, result, @core.Nil), None)
  let nonminimal = {
    length: @oracle.nat(3),
    connection: @oracle.chain([1, 0, 0, 0].map(@oracle.binary)),
  }
  assert_true(
    check(field, @core.replicate(@oracle.nat(3), @oracle.binary(0)), nonminimal),
  )
  let invalid = { ..field, inverse: fn(_) { None }, }
  assert_eq(berlekamp_massey(invalid, input), None)
}
