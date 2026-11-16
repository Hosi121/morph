# Rational 減算の中間 wrapper を除く

[ドキュメント](../README.md) / [探索・改善記録](README.md)

以前の段階では、零の積だけを採用し、直接減算と reciprocal の候補は採用に含めなかった。
この記録は `exact-optimization.md` の第五段に残っている。
今回は adaptive division/GCD と Binary/Rational 共有定数を含む基盤へ進んだため、
同じ問いを現在の source と実測で再評価する。過去の候補の数字を今回の根拠へ流用しない。

固定 upper fixture の生成 C を gprof 用に別 build すると、sample の約 32% が
`moonbit_drop_object`、約 18% が `mi_free`、約 11% が malloc 関連だった。
`rational_negate` は約 14.6M 回呼ばれていた。この profile は費用の順位を探るためだけで、
通常 build との性能倍率には使わない。割当全体を符号反転のせいと断定もしない。

既存の `rational_subtract(a,b)` は `rational_add(a,rational_negate(b))` としていた。
package-private な `subtract_rationals` は、既存の既約分数の加算式を維持し、
符号付き分子だけを `Integer.subtract` へ直接渡す。零の入力と共通分母の経路を維持する。
共有ファイル担当が公開 wrapper を切り替え、main `412d9e9` へ採用した。

`a=x/d, b=y/e, g=gcd(d,e), p=d/g, q=e/g` とすると、新旧の分子はともに
`t=x*q-y*p`。`h=gcd(abs(t),g)` によって `(t/h)/(p*(e/h))` を返す。
正の分母と既知整除の前提を変えず、negative zero を防ぐ Integer の処理も維持する。
この説明は式の対応確認であり、新しい機械検証済み定理を追加したという意味ではない。

## 同一 ELF の結果

Native release、CPU 8 固定、入力構築除外、十 batch。二つの候補は同じ ELF に含めた。

| 固定入力 | 旧 composition | 直接減算 |
| --- | ---: | ---: |
| 小分数 784 演算 | 96.25 ± 2.42 µs | 79.64 ± 2.63 µs |
| 同じ入力、逆順 | 89.92 ± 2.75 µs | 77.74 ± 1.88 µs |
| 共通 127 bit 分母 | 2.53 ± 0.09 µs | 2.62 ± 0.07 µs |
| coprime 大分母 | 195.53 ± 6.46 µs | 194.94 ± 4.92 µs |

小分数では順序を変えても短縮が残った。大分母の二群では改善を主張しない。
生成 C の allocator を計測用に instrument して、同一 small corpus の実割当数も調べた。
旧版 8,218 回に対し直接減算は 7,066 回で、1,152 回減った。
両入力が非零である 576 組から Integer/Rational を一つずつ省いた個数と一致する。
計測 counter が入る版の時間は採否に使わない。

分子 −8..8・分母 1..9 の全 23,409 対で独立整数 fraction oracle と旧 composition に一致した。
さらに Python Fraction で生成した、17〜512 bit・四つの符号組合せ・共通/異なる分母の
30 fixture について、出力の符号・分子 magnitude・正の分母を期待値と直接比較した。
この二群は Native / JS / Wasm GC のすべてで通過した。
handwritten kernel の purity gate も通過した。

ログ：`docs/measurements/rational-subtraction-initial.txt`。
上位での採否は、公開 wrapper を切り替えた保存 ELF と同じ入力の旧 ELF を ABBA 比較して判断する。


## 上位の保存 ELF 比較

Binary の共有定数を含む基盤を固定し、公開減算 wrapper 一行だけを切り替えた。
Nat converter 等の並行した変更はこの比較へ混ぜていない。CPU8、共通 flock、Native release、
入力構築除外、ABBA 二巡（各欄四実行、各実行十 batch）。表は実行平均の範囲を示す。

| 固定 fixture | composition の平均範囲 µs | 直接減算の平均範囲 µs |
| --- | ---: | ---: |
| LLL 3x3 | 139.43–145.04 | 133.63–145.84 |
| LLL checker | 9.26–9.45 | 8.97–9.29 |
| LLL 3x4 | 157.51–160.69 | 151.19–162.78 |
| Smith+LLL 依存 3x4 | 159.20–164.53 | 160.58–173.63 |
| Smith 3x3 | 22.91–23.53 | 22.72–23.44 |
| Smith checker | 8.72–9.11 | 8.48–8.78 |
| simplex | 12.70–13.09 | 11.85–12.24 |

simplex では短縮を観測した。その他の群は差が小さいか範囲が重なっており、改善を主張しない。
依存 LLL には悪化側の観測もあり、任意の上位に対する高速化とは呼ばない。
生 batch 統計・ELF hash・wall/CPU 秒は `rational-subtraction-{upper,lll}.json` に保存した。
必要な ELF/C/probe と基盤の manifest は worktree の外の `.tools/rational-subtraction-artifacts/` に保全した。
