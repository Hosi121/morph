# Polynomialの正規形を再利用するFp演算

[研究記録](README.md) / [基礎部品の最適化](../KERNELS.md)

基準は `03d6584`、採用コードの計測時点は `100c34a` です。
不変条件を持つ既存のADTから不要な処理を省けるか、一案だけを実装・比較しました。
機械数値型・配列・可変状態・FFIを計算核へ入れていません。

## 不変条件と実装

`fppoly.Polynomial` は、検査済み素体と、昇順の正規化済み係数を持つopaqueな型です。
公開constructorは任意長の未還元Binaryを剰余へ変換し、後端の零を除きます。
零多項式はNil、非零なら最後の係数は非零です。外部から係数の不変条件を破る構築はできません。

privateな係数加算は、それまで `modular.add` を通して和の剰余を計算していました。
両入力が `0 <= a,b < p` なら `a+b < 2p` です。
`binary.subtract(a+b,p)` の結果がSomeなら差、Noneなら元の和が正規形になります。
判定と差を返すADTを使い、明示的な比較のあとに減算をやり直す処理を避けます。

符号反転は、零なら既存値を返し、非零なら `p-a` を計算します。
この結果も非零かつp未満で、係数列の長さを保ちます。
checked subtractionのNone分岐には汎用のfallbackを残していますが、不変条件下では到達しません。

[実装](../../src/fppoly/polynomial.mbt)の変更はprivateな `add_reduced` / `negate_reduced` と、その呼び出しだけです。
加算helperは通常の加算と学校算法の積の和で使われ、符号反転は減算・多項式除算にも届きます。
既存のGF(2)専用経路と、未還元入力を受け取る汎用modular/primefieldの契約を保っています。
新しいResidueラッパー、追加の法照合、乗算算法の変更は導入していません。
この界限の式自体は任意の法p>1で成り立ちますが、今回の接続先は既存の素体多項式です。

## 独立検査

実装とは別の担当が、全Polynomial生成箇所と入力の由来を監査しました。
公開constructorはreduce+trim、内部の積はreduced scalar products、shiftは低位零の追加で不変条件を保ちます。
factorizationからの生成も公開constructor経由です。追加diffのread-only reviewでも問題は見つかりませんでした。

[オラクル](../../src/fppoly/canonical_wbtest.mbt)は公開APIだけを呼ぶbaseline-compatibleな3テストです。
p=2,3,5,17の全係数対と、257/65537の7値の境界集合で合計425対を照合します。
別に54の積・除算ケースを学校算法と比較し、未還元のconstructor/scalar/評価点、微分、相殺、幅違い、
零、field mismatchを検査します。積はホストのInt64へ広げてから剰余を取り、32bitのoverflowを避けます。
係数全体、範囲、後端非零、零の表現を検査します。大きい素数については境界集合の有限な検査です。
基準側で23/23、統合直後の採用側でも23/23がWasmGCで通過しました。

## 公開APIの変更前後の比較

[同じharness](../../src/cmd/canonicalfpbench/main.mbt)を基準と採用コードで別々にビルドしました。
native release、CPU4、共有ロック、1 build job、各例5組のABBA順です。
8例・160プロセスの全出力が一致し、各反復で全係数（除算は商と余り）を独立の機械演算結果と照合します。
checksumだけで正しさを判断しません。除算には独立再構成・次数検査とwarm-up時の公開API再構成もあります。

時間はプロセス全体の中央値です。入力・独立oracleの準備、fixtureごとのwarm-up、通常API、
全係数照合、出力を含み、コンパイルを除きます。`MORPH_CANONICAL_ITERATIONS` は未設定で固定回数です。
原始演算だけの時間や、全体中の当該演算の時間比率は測っていません。

| 公開APIの例 | 基準 ms | 採用 ms | 基準 / 採用 | 5ブロックの比 |
| --- | ---: | ---: | ---: | ---: |
| add17-unequal | 121.346 | 111.052 | 1.093× | 0.922–1.147 |
| add65537-cancel | 134.451 | 130.992 | 1.026× | 0.982–1.101 |
| negate17-zeros | 113.486 | 81.568 | 1.391× | 1.337–1.471 |
| negate65537-sparse | 121.474 | 109.616 | 1.108× | 1.046–1.179 |
| subtract65537-unequal | 131.222 | 116.726 | 1.124× | 1.064–1.186 |
| multiply17-d8 | 135.537 | 128.668 | 1.053× | 1.016–1.130 |
| divide17-d16 | 106.508 | 96.628 | 1.102× | 1.056–1.136 |
| char2-control | 98.003 | 100.556 | 0.975× | 0.965–1.030 |

全サンプル・入力harnessと実行ファイルのhash・反復数・compilerは
[変更前後の生値](../measurements/canonical-fp-20261117.json)に保存しました。
符号反転2例、減算、除算はすべてのABBAブロックで採用版が速く、中央値はそれぞれ1.391/1.108/1.124/1.102倍です。
乗算は1.053倍ですが小差であり、大きな上位計算への一般化はしません。

## 小差と採否

二つの加算例とGF(2)対照は、最初の系列で少なくとも一ブロックが逆向きでした。
追加は、同じ採用ELFを両ラベルで使う4例・80プロセスと、
加算2例・GF(2)対照の一回限りの再測定60プロセスに限定しました。追加の実装候補は試していません。

| 同じELFの対照 | ラベル間の中央値比 | ブロックの比 |
| --- | ---: | ---: |
| add17-unequal | 1.014 | 0.990–1.031 |
| add65537-cancel | 1.014 | 0.997–1.193 |
| multiply17-d8 | 0.990 | 0.978–1.090 |
| char2-control | 0.987 | 0.939–1.045 |

[同一ELF対照](../measurements/canonical-fp-control-20261117.json)でも小差や大きい単発の揺れがあります。
[再測定](../measurements/canonical-fp-replication-20261117.json)は、加算p=17が1.101倍、p=65537が1.064倍、
GF(2)対照が0.990倍です。再測定の加算は全5ブロックで速くなりましたが、初回の逆向きの値も残します。
p=65537の小さい加算差を確実な一般改善とは扱いません。
GF(2)の初回0.975倍と再測定0.990倍も、無回帰を保証する結果ではありません。

符号反転・減算・除算の改善と、型が保証する単純な界限を根拠に、このprivateな機構を採用します。
GF(2)や任意の奇素数・形状に一様な改善を主張しません。メモリ削減、他CPUや他backendの速度は未測定です。
前回不採用にした汎用reduceへの追加比較は復活させていません。

## 追跡と検証

kernelは `329d45c`、独立テストは `25c13dc`（担当の元ID `c2861d5`）、
harnessは `100c34a`（元ID `4ee3669`）です。
既存のAPI・純記号制約・型検査と、影響範囲の3 backend検証が通過しました。
既存Leanモデルの検査と、新しいhelper全体の形式証明は区別します。


統合コード `7749ddc` の36 packageは、
wasm-gc各1,392テスト・js各1,392テスト・native各1,392テストで成功しました。
全体の保守・型・API・純記号制約・既存Leanも通過しています。
[検証範囲と記録](../VALIDATION.md#fp多項式の正規形を使う演算)に実行harnessと全コマンドをまとめました。
[担当範囲と経緯](../measurements/canonical-fp-20261117-orchestration.json)、
[片付け記録](../measurements/canonical-fp-20261117-cleanup.json)も保存しています。

同じ影響範囲の検証を再実行する場合は、クリーンなcheckoutと既存のMoonBit/Lean環境で次を実行します。

```sh
mkdir -p .tools/canonical-fp-20261117
tools/measure --cpu 4 python3 docs/measurements/canonical-fp-20261117-harness.py
```

性能を再計測する場合は、基準 `03d6584` と採用版を別のcheckoutに置き、同じ
`src/cmd/canonicalfpbench` を両方でnative release・`-j 1`でビルドします。
`MORPH_CANONICAL_ITERATIONS` を未設定にして `tools/compare_field_kernels.py` の
二つのroot/artifact、harnessとcaseを指定してください。SDKのみ共有し、`_build`は共有しません。
一回限りの再測定を含む全300プロセスで全係数検査と出力比較が通過しました。
