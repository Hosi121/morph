# 証明を受け取る素数判定

`src/primality` は、素数を探索する処理と、渡された証明を検査する処理を分ける。
外部の探索で作ったLucas/Pratt型の木を、純記号の二進算術と剰余累乗だけで検査する。
`check` が返す `Prime` はフィールドを外部から構築できない型であり、
確定した素数を要求する別パッケージの入口に渡せる。

```moonbit
pub(all) enum Certificate {
  Two
  Lucas(@binary.Binary, @binary.Binary, @core.Chain[Certificate])
}
pub fn check(Certificate) -> Prime?
pub fn value(Prime) -> @binary.Binary
pub fn candidate(Certificate) -> @binary.Binary
```

`Lucas(n, a, children)` の子は `n−1` の素因数を**重複込み**で並べる。
順序は任意。例えば7には2と3の証明、5には2の証明を二つ渡す。
子の証明をすべて再帰検査し、`n−1` を各素因数で割っていき、余りがすべて0で
最後の商が1になることを確認する。これにより欠けた因子、余分な因子、
素数でない子を受け付けない。2は `Two` が基底となる。

検査する合同式は `a^(n−1) ≡ 1 (mod n)` と、各素因数 `q` について
`a^((n−1)/q) ≢ 1 (mod n)`。
前者から `a` は乗法群の元で、その位数は `n−1` を割る。
後者がすべての素因数に成立すると、その位数は `n−1` そのものになる。
したがって `φ(n) ≥ n−1` となり、`n>1` は素数である。
これは [Handbook of Applied Cryptography, Fact 4.38, §4.3.2](https://cacr.uwaterloo.ca/hac/about/chap4.pdf)
の条件に対応する。部分分解を使うPocklingtonの条件とは混同しない。
`None` はその証明が不正だったことだけを意味し、合成数の証明にはならない。

## fixtureと検証

通常のテストはコミット済み `vectors_wbtest.mbt` だけを使う。
再生成は次のとおり。Python整数の試し割りで `n−1` を完全分解し、
Pythonの `pow` で最小のwitnessを探索する。MoonBitのcheckerはこの探索を呼ばない。

```sh
python3 tools/generate_primality.py
tools/moon fmt src/primality
tools/moon test src/primality --target wasm-gc
tools/moon test src/primality --target js
tools/moon test src/primality --target native
python3 tools/audit_purity.py
```

独立した整数試し割りと旧 `@modular.is_prime` に対し0〜127を照合する。
同範囲のすべての合成数は、`n−1` の正しい完全分解を渡しても
0〜`n−1` のすべてのwitnessで拒否される。
因子の欠落・追加・非約数・不正な子証明・誤witnessも拒否する。
大きいfixtureは257、65537、998244353、2147483647、2305843009213693951。
受理の根拠は外部での「素数らしい」という判定ではなく、MoonBitでの証明検査である。

この境界はMoonBit型システムと既存の二進・剰余算術の正しさに依存する。
任意入力の終了時間やスタック量は保証しない。証明木は非循環の通常値として受け取る。
実用暗号の安全性、定数時間性、機械整数ライブラリに対する性能優位は主張しない。

## 同条件の検査コスト

2026-11-15、Intel Core Ultra 7 255H、x86_64環境、moonc v0.10.20、
`tools/moon bench src/primality --target native --release`。
証明木と二進入力の構築を計測外に置き、同じ数を既存の完全試し割りと比較した。
証明を発見するコストは含まない。

| 候補 | Lucas証明検査（平均±標準偏差） | 既存試し割り（平均±標準偏差） |
| --- | --- | --- |
| 65537 | 1.27 ms ± 36.95 µs | 692.30 µs ± 20.47 µs |
| 998244353 | 17.28 ms ± 751.96 µs | 250.94 ms ± 9.55 ms |

65537では子の重複検査と合同累乗のコストで証明検査の方が遅い。
998244353では同じ厳密な素数受理に対する検査時間が小さくなる。
この二つの数での結果であり、一般の素数探索や機械整数実装との優劣を示さない。

```text
Lucas 65537:    1.27 ms ± 36.95 µs; 1.23 ms … 1.34 ms; 10 × 83 runs
trial 65537: 692.30 µs ± 20.47 µs; 665.63 µs … 723.14 µs; 10 × 149 runs
Lucas 998244353: 17.28 ms ± 751.96 µs; 16.23 ms … 18.27 ms; 10 × 6 runs
trial 998244353: 250.94 ms ± 9.55 ms; 236.47 ms … 268.24 ms; 10 × 1 runs
```
