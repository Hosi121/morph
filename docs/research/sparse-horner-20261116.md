# 一変数多項式の疎 Horner 評価

[ドキュメント](../README.md) / [研究・探索記録](README.md)

## 採用した変更

[polynomial.evaluate](../../src/polynomial/evaluation.mbt) の一変数経路を疎 Horner 法にした。
指数の降順で並ぶ項の間隔だけを累乗し、前の評価値を使い回す。
指数 0 と 1 の累乗は、それぞれ単位元と引数を直接返す。
その他の次元は従来の項別評価をそのまま使う。

前提は Polynomial の smart constructor が保つ降順である。
Nat の引き算は切り捨てなので、この前提なしに任意の私的な項列へ適用できる函数ではない。
公開の Polynomial を作る入口は次元を検査し、項を整列・統合する。
計算結果、次元不一致時の None、厳密な有理数演算を維持する。

## 比較条件

基準ソースは `6934453`、SDK は moonc v0.10.20。
全実行は CPU 4 へ固定し、全 worktree 共通の `tools/measure` ロックを通した。
局所評価では凍結した旧評価器と実際の公開 `evaluate` を同じ実行ファイルへ入れ、
各 cohort の測定前に両経路を同じ 128 回だけ warmup する。
入力と燃料の構築は測定に含めない。
WasmGC の短い cohort には依然として大きな揺れがある。

各値は mean ± σ。異なる backend や過去の最適化との倍率は合成しない。

| 固定 cohort | native 旧→公開 Horner | JS 旧→公開 Horner | WasmGC 旧→公開 Horner |
| --- | --- | --- | --- |
| 次数0〜2、12評価 | 5.07±0.69→2.16±0.15 µs | 4.35±0.69→2.55±0.32 µs | 4.78±3.92→1.67±0.82 µs |
| 密な次数16/32、6評価 | 2.51±0.09→0.336±0.054 ms | 2.40±0.57→0.201±0.013 ms | 1.53±0.09→0.152±0.021 ms |
| 疎な次数64/128、4評価 | 2.93±0.21→2.16±0.04 ms | 2.19±0.07→1.76±0.20 ms | 1.80±0.15→1.34±0.07 ms |
| 多変数の未変更対照、4評価 | 53.80±3.45→53.16±1.63 µs | 42.07±2.11→42.13±1.96 µs | 41.18±19.39→123.31±166.61 µs |

多変数対照は native と JS で範囲が重なり、改善を主張しない。
WasmGC 対照は最小値が29.89/29.11 µsと近い一方、GC・tiering等を分離できていない大きな分散があり、
平均値から安定した差を結論できない。WasmGC の全用途で回帰しないという保証には使わない。
密な一変数の改善と native/JS の未変更対照を採用根拠とする。

生ログ: [native](../measurements/evaluation-20261116-warm-public-native-bench.txt) · [JS](../measurements/evaluation-20261116-warm-public-js-bench.txt) · [WasmGC](../measurements/evaluation-20261116-warm-public-wasm-bench.txt)。

## 上位の実数制約への波及

一変数 CAD の Problem を事前に作り、解く処理と返す証拠の再検査を測る。
同じ harness を使う変更前後の native ELF を保存し、同じ CPU とロックで比較した。

| Problem | 旧評価 | Horner |
| --- | --- | --- |
| x²=2 ∧ x>0 | 89.02±4.77 µs | 91.36±2.23 µs |
| ∏(x−i)>0, i=1..8 | 1.59±0.216 s | 489.65±10.98 ms |
| x(x−1/1024)<0 | 1.56±0.063 ms | 817.91±28.68 µs |

小さい √2 の例は横ばい。密な次数8と近接根の例では処理全体が短くなった。
これは固定した三つの入力の結果で、全実代数計算への一般的な倍率ではない。
[変更前](../measurements/evaluation-20261116-upper-before.txt) · [変更後](../measurements/evaluation-20261116-upper-after.txt) · [source/ELFのSHAと環境](../measurements/evaluation-20261116-manifest.json)。

## 正しさの検査

3125 個の次数4以下の係数列を7個の有理点で評価し、21,875 件について
Int32 で安全な範囲に収めた独立の分数展開と、旧評価器・公開評価器を比較した。
零・定数・疎な高次数・負の有理数・多変数・次元不一致も含める。
polynomial の4テストは native/JS/WasmGC で通過。
既存の realcad と realalgebraic も新経路で native の検査を通した。

モデル証明の範囲は[独立レビュー](sparse-horner-independent-review-20261116.md)に記録する。
有理数実装やコンパイラまで含む end-to-end の形式証明とは区別する。
