///|
fn word(value : Int32, width : Int32) -> Array[Bool] {
  [
    for i in 0..<width => (value & (1 << i)) != 0
  ]
}

///|
fn naive_tokens(word : Array[Bool]) -> Array[(Int32, Bool?)] {
  let dictionary : Array[Array[Bool]] = [[]]
  let tokens = []
  let mut prefix : Array[Bool] = []
  let mut prefix_id = 0
  for bit in word {
    let phrase = prefix + [bit]
    let mut found = -1
    for i in 0..<dictionary.length() {
      if dictionary[i] == phrase {
        found = i
      }
    }
    if found >= 0 {
      prefix = phrase
      prefix_id = found
    } else {
      tokens.push((prefix_id, Some(bit)))
      dictionary.push(phrase)
      prefix = []
      prefix_id = 0
    }
  }
  if !prefix.is_empty() {
    tokens.push((prefix_id, None))
  }
  tokens
}

///|
test "all 8191 binary words through length twelve match array dictionary parsing" {
  for width in 0..<=12 {
    for value in 0..<(1 << width) {
      let input = word(value, width)
      let chain = @oracle.chain(input)
      let tokens = compress(chain)
      let actual = @oracle.array(tokens).map(fn(token) {
        (@oracle.int_of_binary(token.prefix), token.literal)
      })
      assert_eq(actual, naive_tokens(input))
      assert_eq(decompress(tokens), Some(chain))
      let packed = pack(tokens)
      assert_eq(unpack(packed), Some(tokens))
      assert_eq(decode(packed), Some(chain))
    }
  }
}

///|
fn naive_decode(bits : Array[Bool]) -> Array[Bool]? {
  let dictionary : Array[Array[Bool]] = [[]]
  let result = []
  let mut position = 0
  while position < bits.length() {
    let mut zeros = 0
    while position < bits.length() && !bits[position] {
      zeros += 1
      position += 1
    }
    if position == bits.length() {
      return None
    }
    position += 1
    let mut number = 1
    for _ in 0..<zeros {
      if position == bits.length() {
        return None
      }
      number = number * 2 + (if bits[position] { 1 } else { 0 })
      position += 1
    }
    let prefix = number - 1
    if prefix >= dictionary.length() || position == bits.length() {
      return None
    }
    let literal = bits[position]
    position += 1
    if !literal {
      if position != bits.length() || prefix == 0 {
        return None
      }
      result.append(dictionary[prefix])
    } else {
      if position == bits.length() {
        return None
      }
      let phrase = dictionary[prefix] + [bits[position]]
      position += 1
      result.append(phrase)
      dictionary.push(phrase)
    }
  }
  Some(result)
}

///|
test "all short wire streams are checked against an independent bit cursor decoder" {
  for width in 0..<=12 {
    for value in 0..<(1 << width) {
      let bits = word(value, width)
      let expected = naive_decode(bits).map(@oracle.chain)
      assert_eq(decode(@oracle.chain(bits)), expected)
    }
  }
}

///|
test "long repetition compresses but short inputs can expand; malformed references fail" {
  let input = @core.replicate(@oracle.nat(8192), false)
  let packed = encode(input)
  assert_true(@oracle.int_of_nat(@core.length(packed)) < 8192)
  assert_eq(decode(packed), Some(input))
  assert_true(
    @oracle.int_of_nat(@core.length(encode(@oracle.chain([false])))) > 1,
  )
  let future = Token::{ prefix: @oracle.binary(1), literal: Some(true), }
  assert_eq(decompress(@oracle.chain([future])), None)
  assert_eq(
    decompress(
      @oracle.chain([Token::{ prefix: @oracle.binary(0), literal: None, }]),
    ),
    None,
  )
  let first = Token::{ prefix: @oracle.binary(0), literal: Some(false), }
  let ending = Token::{ prefix: @oracle.binary(1), literal: None, }
  assert_eq(
    decompress(@oracle.chain([first, ending])),
    Some(@oracle.chain([false, false])),
  )
  assert_eq(decompress(@oracle.chain([first, ending, first])), None)
  assert_eq(unpack(pack(@oracle.chain([first, ending, first]))), None)
}
