# 桁幅に応じた除算と剰余だけのkernel

通常の`binary.divmod`を、幅の差が近い場合の整列減算へ接続した。
canonical Bool列を同時に走査し、aの方が短ければ商0・余りaを返す。
差が8以下ならbへ0のprefixを足し、高位から一桁ずつ比較・減算する。
幅差が大きければ従来の除算へ戻す。整列後のloopは最大9段である。
prefixはCore.replicate_ontoを使い、商はBool列で保持して最後にBinaryへ包む。

`binary.remainder`も追加し、GCDと`modular.reduce`が捨てる商を構築しない経路へ進めた。
除数0はdivmodと同じNone、0/1/2の値の意味は維持する。
GCDは初回だけ二数を並べ替え、以降はEuclidの`r<b`で順序が維持される。
2とのGCDは相手の最下位Boolで決まり、初期とloopの両方で扱う。

速度の主な要因は桁幅を使った不要なprefix処理の削減である。
近い幅では商も短いため、商だけを省く追加効果は小さかった。
幅が大きく違う除算には有意な短縮を確認していない。

## 固定cohortの同一実行ファイル比較

旧productionのdivmod/GCD本体をWBに凍結し、新productionと同じELFへ入れた。
native release、CPU4固定、入力構築除外、各10標本。数値はcohort一周の時間。

| 入力 | 旧divmod | 新divmod | 旧GCD | 新GCD |
| --- | ---: | ---: | ---: | ---: |
| 8bit以下128対 | 90.49±7.31 µs | 46.09±2.47 µs | 407.94±20.14 µs | 262.91±7.01 µs |
| 126〜128bitの近い32対 | 1.48±0.10 ms | 261.53±13.27 µs | 26.82±0.37 ms | 9.95±0.53 ms |
| 128bit対16〜47bitの32対 | 3.76±0.19 ms | 3.74±0.22 ms | 5.65±0.16 ms | 5.04±0.18 ms |

prototypeの一回目とも同方向だった。host外部負荷・周波数は固定できておらず、
旧processとの絶対時間の比較や、このcohort外の算法への倍率の外挿はしない。
上位への波及は個別に計測する。

## 検証と独立レビュー

0〜255の全65536対を組み込み整数の商・余り・Euclidと照合した。
Python int/math.gcdの独立生成fixtureは0、同値、逆順、幅差0/1/3/8/9/16、
16〜2048bitの数、共通因子を持つ数と固定乱数を含む。
BinaryとModular計28テストがnative/JS/Wasm GCで通過した。
生成fixtureは`python3 tools/generate_division_cases.py --check`で照合できる。

別担当のconstant_kernel agentがsourceと検査内容を読み、値の不整合は見つけなかった。
幅差8の境界、quotientのBoolを前置するLE順、各段の`r<2*aligned`から減算後の
`r<aligned`、最後の`r<b`、0/1/2と初回sort後の順序を確認した。
このレビューはcheckerの独立再実行ではなく、全入力のMoonBit形式証明でもない。
既存のLean source lockは加算・Nat・prefixが対象で、新しい除算全体の証明とは別である。

review対象SHA256: division.mbt `d82d1e7dea9a772d4d3b52e0f9d65e8af7bebc5de4098beaa6f818f9fb6f0448`、
binary.mbt `7db9d28c9330d6d386909042eda1028dbfc8b852db6b578bc5a48bb838c1eb97`、
modular.mbt `c02f8650ff641dc0e1ea5a615f139320b4bcaec45a47c3a5743b6cfde02d05db`。

ログ：[prototype cohort](../measurements/division-cohort-first.txt)、
[production検証・比較](../measurements/aligned-production-validation.txt)。
