///|
/// Display adapters are outside the symbolic kernel, just like test oracles.
fn[A] required(value : A?) -> A {
  match value {
    Some(value) => value
    None => abort("demo invariant failed")
  }
}

///|
fn type_text(typ : @infer.Type) -> String {
  match typ {
    Variable(name) => "t\{@oracle.int_of_nat(name)}"
    Node(BoolType, _) => "Bool"
    Node(FunctionType, Cons(a, Cons(b, Nil))) =>
      "(\{type_text(a)} -> \{type_text(b)})"
    Node(ProductType, Cons(a, Cons(b, Nil))) =>
      "(\{type_text(a)} * \{type_text(b)})"
    _ => "malformed type"
  }
}

///|
fn main {
  println(
    "morph: ADT・パターンマッチ・再帰によるアルゴリズムの小さな実演",
  )
  let sum = @binary.add(@oracle.binary(12345), @oracle.binary(6789))
  println("Bool二進算術: 12345 + 6789 = \{@oracle.int_of_binary(sum)}")
  let pair = @binary.pair(@oracle.nat(3), @oracle.binary(5))
  println("連結によるpair(3,5) = \{@oracle.int_of_binary(pair)}")
  let input : @fft.Signal = @oracle.chain([
    @core.Cons(@core.Nil, @core.Nil),
    @core.Nil,
    @core.Nil,
    @core.Nil,
  ])
  let spectrum = required(@fft.fft(@core.Cons((), @core.Nil), input))
  println(
    "記号FFTのimpulse応答（各binの矢印数）: \{@debug.Repr(@oracle.array(spectrum).map(fn(bin) { @oracle.int_of_nat(@core.length(bin)) }))}",
  )
  let modulus = required(@modular.modulus(@oracle.binary(17)))
  let plan = required(@ntt.plan(modulus, @oracle.binary(13), @oracle.nat(4)))
  let product = required(
    @ntt.convolve(
      plan,
      @oracle.chain([1, 2, 3].map(@oracle.binary)),
      @oracle.chain([4, 5].map(@oracle.binary)),
    ),
  )
  println(
    "NTT畳み込み mod 17: [1,2,3] * [4,5] = \{@debug.Repr(@oracle.array(product).map(@oracle.int_of_binary))}",
  )
  let a = required(
    @matrix.matrix(
      @oracle.nat(2),
      @oracle.chain([
        @oracle.chain([2, 1].map(fn(n) { @oracle.rational(n, 1) })),
        @oracle.chain([1, -1].map(fn(n) { @oracle.rational(n, 1) })),
      ]),
    ),
  )
  let solution = required(
    @linear.solve(
      a,
      @oracle.chain([5, 1].map(fn(n) { @oracle.rational(n, 1) })),
    ),
  )
  match solution {
    Unique(values) =>
      println(
        "厳密な連立方程式: \{@debug.Repr(@oracle.array(values).map(fn(r) { @oracle.int_of_integer(@exact.numerator(r)) }))}",
      )
    _ => abort("demo expected a unique integral solution")
  }
  let equal = fn(a : Bool, b : Bool) { a == b }
  let x = @oracle.chain([true, false, true, false])
  let y = @oracle.chain([false, true, false])
  println(
    "編集距離: \{@oracle.int_of_nat(@dp.levenshtein(x,y,equal))}; LCS: \{@debug.Repr(@oracle.array(@dp.lcs(x,y,equal)))}",
  )
  let literal : @sat.Literal = { variable: @oracle.nat(0), positive: true, }
  let contradiction = @oracle.chain([
    @core.Cons(literal, Nil),
    @core.Cons(@sat.negate(literal), Nil),
  ])
  match @sat.solve(contradiction) {
    Unsatisfiable(proof) =>
      println(
        "SAT: p AND NOT p は充足不能。反証検査 = \{@sat.check_refutation(contradiction,proof)}",
      )
    _ => abort("demo contradiction was accepted")
  }
  let id = @infer.Lambda(@oracle.nat(0), @infer.Reference(@oracle.nat(0)))
  let expression = @infer.Let(
    @oracle.nat(1),
    id,
    @infer.Tuple(
      @infer.Apply(@infer.Reference(@oracle.nat(1)), @infer.Boolean(true)),
      @infer.Apply(@infer.Reference(@oracle.nat(1)), id),
    ),
  )
  match @infer.infer(expression) {
    Ok(scheme) =>
      println(
        "let多相: let id = fun x -> x in (id true, id id) : \{type_text(@infer.canonical(@infer.body(scheme)))}",
      )
    Err(_) => abort("demo type inference failed")
  }
  let word = @oracle.chain([false, false, false, true, true, false])
  let code = required(@huffman.build(word, equal))
  let encoded = required(@huffman.encode(code, word, equal))
  println(
    "Huffman: \{@oracle.int_of_nat(@core.length(word))} symbols -> \{@oracle.int_of_nat(@core.length(encoded))} bits; 復号一致 = \{required(@huffman.decode(code,encoded)) == word}",
  )
}
