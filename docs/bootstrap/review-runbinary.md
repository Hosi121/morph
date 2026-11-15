# runbinary 独立レビュー

対象：`3404abafbc81667dc9d67408d945728478678be2`
（`runbinary.mbt`、2026-11-15、MoonBit v0.10.20）。
レビューworktreeの基点は `cc6d243858814b361e83cd412ad092d3fb5bfe60`。
実装は編集せず、`review_wbtest.mbt` だけを追加した。
並行して追加される燃料付き除算は、このレビューの対象外。

## 結果

調べた有限例では、正規化・加減乗・比較・shift・pair/unpairの不一致は見つからなかった。
巨大値の恒等式も、ビット展開せず正規化run列として一致した。
新しい修正提案を必要とする最小反例は得られていない。

## 独立に追加した検査

- 4個のraw runの全10,000列。各runはbit二択、長さ0〜4。
  機械整数へ直接展開して意味を計算し、ゼロ長の除去・隣接merge・高位ゼロ除去・幅・
  同じrun列からの再正規化・明示展開budgetのちょうど境界を検査。
- UInt64で0、1、2冪の前後、65535、65536、2147483647など11値の全121対を検算。
  最大積は2^62未満。ネイティブoverflowをoracleに混ぜず、加減乗・比較・shiftとpairを比較。
- 8run・幅256bit以下の160組を、既存の**per-bit Binary**算術と比較。
  run境界の直前・一致・直後でshiftし、長さの違うblock同士のcarry/borrowと高位比較を検査。
  このoracleはfull-adderを一部共有するため、完全に独立した算術核だとは扱わない。
  小さい値のUInt64 oracleと組み合わせた検査である。
- `E=2^2048` をrun長として、展開不可能な幅で次の既知の形を検査。
  `(2^E−1)(2^E+1)=2^(2E)−1`、`(2^E+1)^2` の3個の非ゼロbit、
  `2^(2E)−2^E`、`2^(2E)−2^E−1`、長いborrow、同幅の高位比較、巨大pairの逆変換。
  期待値は少数の明示runで構成し、巨大幅のビット展開は呼ばない。

巨大値に対して `expand` を許す呼び出しは行っていない。
小さいbudgetで確実に拒否されることだけを確認した。
幅budgetはビット数を制限するAPIであり、呼び出し側が巨大なbudgetを渡した場合の資源上限までは意味しない。

## 検証コマンド

```sh
tools/moon fmt --check src/runbinary
tools/moon check --deny-warn src/runbinary
tools/moon test src/runbinary/review_wbtest.mbt --target wasm-gc
tools/moon test src/runbinary/review_wbtest.mbt --target js
tools/moon test src/runbinary/review_wbtest.mbt --target native
```

追加4テストが各バックエンドで成功。整形・警告禁止の型検査も成功。
全入力に対する形式証明、除算や後続実装への保証、機械整数算術への速度優位はこの結果から主張しない。
