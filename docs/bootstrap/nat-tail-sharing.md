# Natの商を既存の末尾として返す

[ドキュメント](../README.md) / [探索・改善記録](README.md)

直接の半分化に続き、quotientのNatを作り直す費用を除いた。
`core.halve_nat`はfastとslowを同じ入力から開始し、二つ/一つずつSuccを消費する。
fastが0ならslow自身、1ならslowのtailを返すと、長さはfloor(n/2)になる。
返すNatのSuccはsource上では新規構築しない。公開APIと商・余りの意味は同じ。

private walkのfallbackは、初期fast=slowとstepのfast≤slow保存から到達不能である。
Leanモデルは`2*商+余り=2*slow-fast`をその条件の下で示し、初期状態から
元の商余りとfloorの定理を導く。この段階ではBinaryの変換も同じCore helperを使った。
現在のBinary変換は[8進単位の共有](nat-radix-grouping.md)へ進み、この二進変換モデルは
`fromNatByHalves`として検査を継続している。
Coreのoleanは検査ごとに生成し、ソースとの対応lockも更新した。
モデル定理から、物理的なheap割当数・速度・全入力の実行資源保証は主張しない。

別のcyclotomic agentがsource/model/diffを読み、fallback、不変式、Bool余り、
fresh Core artifactのimport順序に正しさの問題がないと確認した。
この独立レビューはcheckerの独立再実行ではない。
旧accumulatorの説明が残る文書を指摘され、この変更と合わせて修正した。

native release、CPU4、同一ELF、入力構築を除外、各10標本。
再計測用WBには旧accumulator版を明示的に保存し、現行public APIと比較する。

| 入力 | 旧half | 新halve | 旧from_nat | 新from_nat |
| --- | ---: | ---: | ---: | ---: |
| 4096 | 21.70±0.43 µs | 9.87±0.27 µs | 42.64±3.30 µs | 19.77±0.39 µs |
| 100000 | 570.10±45.36 µs | 276.47±15.05 µs | 1.21±0.06 ms | 569.94±46.23 µs |

別の初回同ELF比較でも4096 from_natは46.11→20.57 µsで同方向だった。
異なるprocess間の絶対時間を倍率の根拠にはしない。
商だけを返す専用の別helperも試したが、4096では9.82 µsとtuple版との差が小さく、
100000でも範囲が重なった。productionは共通tuple helperとwrapperに統一する。

Core/Binary/円分体/厳密FFT/Fp多項式の70テストを全3backend、Leanと警告禁止で検査した。
小さいNatは0〜4096、大きなNatは200001の商・余りも確認する。
同じ作業木の除算試作二テストも上記に含む。除算試作の通常経路への採用とは別である。
ログ：[初回比較](../measurements/nat-sharing-first.txt)、[production検証と再比較](../measurements/nat-sharing-production.txt)。
