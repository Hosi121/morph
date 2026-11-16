# 通常の有理数行列式へ Bareiss を採用

[ドキュメント](../README.md) / [研究・探索記録](README.md)

`linear.determinant` を、行ごとの分母を払う Bareiss 法へ接続した。
公開の `Matrix[Rational] -> Rational?` は維持し、非正方行列は None を返す。
RREF・連立方程式・逆行列は引き続き既存の体辞書による行簡約を使う。

採用の局所的根拠は、[独立した算法実装と比較](bareiss-20261116.md)である。
138個の行列式 oracle、符号付きの厳密除算、128/256bit係数と大きな非二進分母を含む
140テストが3 backendで通過した。8 cohort × 3 backendの全比較で二回とも改善し、
native の密な6/8次では1.86〜2.36倍になった。
[全比較の値](../measurements/bareiss-20261116-benchmark-runs.json)・[要約](../measurements/bareiss-20261116-benchmark-summary.json)・[凍結artifact](../measurements/bareiss-20261116-benchmark-artifacts.json)。
WasmGCや早期零の大きな倍率は変動が大きいため、一般的な予測には使わない。

## 上位の固定した処理

CPU 4、同じSDK・release、同じ入力・harnessで変更前後のnative ELFを保存して比較した。
次は mean ± σ。入力・Fieldの準備は外に置く。

| 処理 | 変更前 | Bareiss経路 |
| --- | --- | --- |
| 次数2どうしの和のresultant＋証拠検査 | 135.88±14.29 µs | 89.26±4.22 µs |
| 次数4×2の積のresultant＋証拠検査 | 953.15±57.29 µs | 911.62±62.46 µs |
| 四次数体のnormを4回、乗法行列構築込み | 174.87±12.35 µs | 105.97±12.42 µs |

和のresultantとnormの固定例は短縮した。次数4×2の積は範囲が重なり、改善を主張しない。
一部の行列演算が速くなっても、補間・多項式演算などが残る処理全体への倍率は別に測る必要がある。
過去のHornerの倍率との掛け合わせもしない。

[resultant変更前](../measurements/bareiss-upper-20261116-before-resultants.txt) ·
[変更後](../measurements/bareiss-upper-20261116-after-resultants.txt) ·
[norm変更前](../measurements/bareiss-upper-20261116-before-norms.txt) ·
[変更後](../measurements/bareiss-upper-20261116-after-norms.txt) ·
[source/ELF/CのSHA](../measurements/bareiss-upper-20261116-manifest.json)。

接続後のnativeでは linear 3、realalgebraic 158、numberfield 139テストが通過し、
公開APIの生成内容も変わらなかった（[ログ](../measurements/bareiss-upper-20261116-callers.txt)）。
最終の横断検証は、この接続と後続の算法を同時に検査する。
凍結した旧RREFのWB参照を残し、通常経路の置換後も同じ算法同士を比較できるようにする。
