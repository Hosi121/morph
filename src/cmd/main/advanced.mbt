///|
fn point_text(point : @elliptic.Point) -> String {
  match @elliptic.coordinates(point) {
    Infinity => "infinity"
    Affine(x, y) => "(\{binary_text(x)}, \{binary_text(y)})"
  }
}

///|
fn codes_and_optimization() -> Unit {
  let repeated = @core.replicate(@oracle.nat(8192), false)
  let compressed = @lz78.encode(repeated)
  println(
    "LZ78: 8192個の同一ビット -> \{@oracle.int_of_nat(@core.length(compressed))} bits; 復号一致 = \{@lz78.decode(compressed) == Some(repeated)}",
  )
  let patterns = @oracle.chain([
    @aho.Pattern::{ label: @oracle.nat(0), word: @oracle.chain([false, true]), },
    @aho.Pattern::{ label: @oracle.nat(1), word: @oracle.chain([true]), },
    @aho.Pattern::{ label: @oracle.nat(2), word: Nil, },
  ])
  let automaton = required(@aho.plan(patterns))
  let text = @oracle.chain([false, false, true, false, true])
  let matches = @aho.find_all(automaton, text)
  let (left, state) = @aho.feed(
    @aho.start(automaton),
    @core.take(@oracle.nat(2), text),
  )
  let (right, _) = @aho.feed(state, @core.drop(@oracle.nat(2), text))
  println(
    "Aho–Corasick: 01・1・空語を00101から検索 = \{@oracle.int_of_nat(@core.length(matches))} 一致; 分割検索と一致 = \{@core.append(left,right) == matches}",
  )
  let vertices = @oracle.chain([0, 1, 2, 3].map(@oracle.nat))
  let edges = @oracle.chain(
    [(0, 0), (0, 1), (1, 0), (2, 1), (3, 2)].map(fn(pair) {
      let (a, b) = pair
      (@oracle.nat(a), @oracle.nat(b))
    }),
  )
  let p = required(
    @bipartite.problem(
      vertices,
      @oracle.chain([0, 1, 2].map(@oracle.nat)),
      edges,
    ),
  )
  let matching = required(@bipartite.maximum(p))
  println(
    "Hopcroft–Karp: 最大対応 \{@oracle.int_of_nat(@core.length(matching.pairs))} 辺; 同数の頂点被覆の検査 = \{@bipartite.check(p,matching)}",
  )
  let a = required(
    @matrix.matrix(
      @oracle.nat(3),
      @core.Cons(
        @oracle.chain([2, 3, 4].map(fn(n) { @oracle.rational(n, 1) })),
        Nil,
      ),
    ),
  )
  let p = required(
    @zeroone.problem(
      a,
      @core.Cons(@oracle.rational(5, 1), Nil),
      @oracle.chain([3, 4, 6].map(fn(n) { @oracle.rational(n, 1) })),
    ),
  )
  match @zeroone.run(@zeroone.start(p), @oracle.nat(512)) {
    Complete(candidate, proof) =>
      println(
        "0/1分枝限定: 重さ[2,3,4]・価値[3,4,6]・容量5 -> \{@debug.Repr(@oracle.array(candidate.assignment))}, max = \{rational_text(candidate.value)}; 証拠木の検査 = \{@zeroone.check_optimal(p,candidate,proof)}",
      )
    _ => abort("demo binary LP should finish")
  }
  let field = required(@finitefield.field(@oracle.binary(17)))
  let curve = required(
    @elliptic.curve(field, @oracle.binary(2), @oracle.binary(2)),
  )
  let generator = required(
    @elliptic.point(curve, @oracle.binary(5), @oracle.binary(1)),
  )
  let a = required(@elliptic.scale(generator, @oracle.binary(5)))
  let b = required(@elliptic.scale(generator, @oracle.binary(7)))
  let shared = required(@elliptic.scale(b, @oracle.binary(5)))
  println(
    "楕円曲線: 5*(7*G) = \{point_text(shared)}; 7*(5*G)と一致 = \{@elliptic.scale(a,@oracle.binary(7)) == Some(shared)}; 点の圧縮往復 = \{@elliptic.decompress(curve,@elliptic.compress(shared)) == Some(shared)}",
  )
  let plan = required(
    @reedsolomon.plan(
      field,
      @oracle.nat(3),
      @oracle.nat(2),
      @oracle.chain([0, 1, 2, 3, 4, 5, 6].map(@oracle.binary)),
    ),
  )
  let source = @oracle.chain([3, 1, 4].map(@oracle.binary))
  let encoded = @oracle.array(required(@reedsolomon.encode(plan, source)))
  let received = encoded.copy()
  received[2] = @modular.add(
    @finitefield.modulus(field),
    received[2],
    @oracle.binary(3),
  )
  received[5] = @modular.add(
    @finitefield.modulus(field),
    received[5],
    @oracle.binary(7),
  )
  let restored = required(@reedsolomon.decode(plan, @oracle.chain(received)))
  println(
    "Reed–Solomon mod17: \{@debug.Repr(encoded.map(@oracle.int_of_binary))} -> 2箇所破損 \{@debug.Repr(received.map(@oracle.int_of_binary))}",
  )
  println(
    "復元メッセージ = \{@debug.Repr(@oracle.array(restored.message).map(@oracle.int_of_binary))}; 誤り位置 = \{@debug.Repr(@oracle.array(restored.error_positions).map(@oracle.int_of_nat))}; 再評価検査 = \{@reedsolomon.check(plan,@oracle.chain(received.map(fn(x) { Some(x) })),restored)}",
  )
}
