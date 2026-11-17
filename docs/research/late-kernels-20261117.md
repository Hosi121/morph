# 26時枠の共通部品改善

[研究記録](README.md) / [基礎部品の最適化](../KERNELS.md)

利用者の延長指示を受け、検証済みの`a39f323`を基準に六候補を比較し、四件を採用しました。
前の[夜間の8件](night-kernels-20261117.md)は3バックエンド各3,603テスト、1,080回の公開API比較まで完了してpush済みです。
この記録では、その後の採否と検証を分けて扱います。

## 一巡目の採否

いずれもnative release・CPU4・共通ロック・5組のABBAで、入力・構築・結果と証拠の検査を含む比較です。

| 候補 | 判断 | 担当別の測定と限界 |
| --- | --- | --- |
| QQ多項式の減算融合 | 不採用 | [完全相殺では約1.54倍](late-subtraction-20261117.md)だったが、一般入力・Gröbner全体は未確定。初期のblock-disjointは約5%遅く、単一の再試作でも汎用の利点は確立せず、元の経路を維持 |
| 標数2の既知の平方 | 採用 | [密なmodular power1.169倍・疎1.426倍・既約性と体構築1.069倍](late-frobenius-20261117.md)。奇標数対照は初回0.960・再比較1.023倍で効果未確定 |
| Bool行列積 | 採用 | [小・疎・密・零で1.066/1.162/1.244/1.208倍](late-bool-product-20261117.md)。コホモロジー生成側へ接続したが、円・トーラスの全体効果は未確定 |

標数2の平方は係数の間に零を挟む経路を、`power_mod`の既知の同一引数の平方に使います。
一般の積、奇標数の積、指数の手順と最後の余分な平方は変更していません。
Bool積は既存公開APIを専用化し、コホモロジーのincoming coordinatesの生成で利用します。
GF(2)のcheckerにも新しい積が共有される箇所があるため、旧generic積と独立Bool参照で照合しています。
CSS・コホモロジーの直接のgeneric行列積の検査は残しています。

担当別の3バックエンド検査は、Fppoly・Galoisが51テストずつ、GF(2)・コホモロジーが192テストずつです。
これらは統合後の逆依存検証に置き換えません。未採用の減算は、二案とも全出力照合・各142テストを通過しましたが、性能を理由に見送っています。

## 一巡目の統合後比較

統合コード`085b736`を同じ公開CLIで基準`a39f323`と比較し、18入力・360試行の全結果と検査が一致しました。
減算は元の実装のまま対照として測っています。

| 統合後の入力 | 基準÷採用 |
| --- | ---: |
| 未変更のQQ減算・完全相殺 | 1.028 |
| 未変更のQQ減算・交差support | 0.979 |
| 未変更のQQ減算・block分離 | 0.989 |
| 未変更のQQ減算・有理係数 | 1.005 |
| 未変更のQQ減算・小入力とエラー | 0.982 |
| 未変更のGröbner処理の対照 | 0.943 |
| F2平方・密なmodular power | 1.184 |
| F2平方・疎なmodular power | 1.383 |
| 既約性とGalois構築 | 1.089 |
| 奇標数の対照 | 1.012 |
| F2低次数 | 0.990 |
| F2一回利用 | 1.010 |
| Bool積・小入力とshape | 1.068 |
| Bool積・疎 | 1.139 |
| Bool積・密 | 1.266 |
| Bool積・零 | 1.177 |
| 円のコホモロジー全体 | 1.019 |
| トーラスのコホモロジー全体 | 1.002 |

[latepolybenchの要約](../measurements/late-round1-latepolybench-20261117.json)・[完全な生値](../measurements/late-round1-latepolybench-20261117.json.gz)、
[latefrobeniusbenchの要約](../measurements/late-round1-latefrobeniusbench-20261117.json)・[完全な生値](../measurements/late-round1-latefrobeniusbench-20261117.json.gz)、
[lateboolproductbenchの要約](../measurements/late-round1-lateboolproductbench-20261117.json)・[完全な生値](../measurements/late-round1-lateboolproductbench-20261117.json.gz)を保存しました。全生値は損失のないgzipで、要約に圧縮前後のSHA256があります。
未変更の減算・Gröbner対照にも変動があり、この系列の小差を特定の算法の改善・回帰と断定しません。
とくにGröbner対照の比0.943も省かずに記録しています。Bool積とF2平方の有限な直接入力を、上位全体の性能保証へ一般化しません。

## 検証の再開も通常の手順にする

前の長いnative検証が途中終了したため、[check_affected.py](../../tools/check_affected.py)を追加しました。
ソース・runner・完了済みログを固定し、旧・現のimport graphの逆依存を選びます。
一段ずつ別プロセスで実行し、未完了のログを保存してから、その段だけを再開します。
PIDの再利用・ソースやログのずれ・同じrecordの二重実行も検査します。
操作は[検証ガイド](../VALIDATION.md#変更範囲を段階ごとに検査する)にまとめています。

## 二巡目の採否

基準`905d23d`に対し、各候補一案の初回比較で探索を終了しました。

| 候補 | 判断 | 担当別の測定と限界 |
| --- | --- | --- |
| Fpの余り専用modular power | 採用 | [密なF2で1.172倍、疎1.223倍、既約性と体構築1.148倍](late-fp-remainder-20261117.md)。公開divideを保ち、捨てていた商を内部で作らない。奇標数対照は未確定 |
| QQ多項式の定数単位積 | 採用 | [+1で1.619倍、-1で1.543倍、numberfield経由1.204倍](late-poly-unit-20261117.md)。正規な単位を判定して結果を共有。非単位・密入力の小差は未確定 |
| GF(2)零空間の係数列の準備 | 不採用 | [小0.633倍、疎0.907倍、密0.796倍、コホモロジー0.955倍](late-basis-20261117.md)。準備コストを回収できず元の走査を維持 |

一巡目と合わせて採用4件、見送り2件です。担当別の照合と統合版の検証を区別し、
最終版の固定ソースで逆依存の3バックエンド検査と公開API比較を行います。
26時までに最終検証・push・片付けを行います。

## 最終統合版の公開API比較

固定ソース`a63dcbc`で全6系列・36入力・720プロセスが全結果と検査に成功しました。
起動・構築・結果と証拠の検査を含むnative release、CPU4、5組のABBAです。
基準は一巡目の3CLIが`a39f323`、二巡目が`905d23d`です。

| 公開CLI / 入力 | 基準÷統合版 | 有利なblock数 |
| --- | ---: | ---: |
| `latepolybench` / `full-cancellation` | 1.007 | 3/5 |
| `latepolybench` / `interleaved` | 0.986 | 3/5 |
| `latepolybench` / `block-disjoint` | 0.999 | 2/5 |
| `latepolybench` / `mixed-rational` | 0.985 | 2/5 |
| `latepolybench` / `small-zero-errors` | 1.077 | 5/5 |
| `latepolybench` / `buchberger` | 1.019 | 4/5 |
| `latefrobeniusbench` / `dense-f2-power16` | 1.379 | 5/5 |
| `latefrobeniusbench` / `sparse-f2-power32` | 1.774 | 5/5 |
| `latefrobeniusbench` / `irreducibility-setup8` | 1.190 | 5/5 |
| `latefrobeniusbench` / `odd17-control` | 1.060 | 5/5 |
| `latefrobeniusbench` / `lowdegree-f2` | 1.142 | 5/5 |
| `latefrobeniusbench` / `setup-one-shot-f2` | 1.233 | 5/5 |
| `lateboolproductbench` / `tiny-and-shapes` | 1.062 | 5/5 |
| `lateboolproductbench` / `sparse` | 1.175 | 5/5 |
| `lateboolproductbench` / `dense` | 1.241 | 5/5 |
| `lateboolproductbench` / `zero` | 1.191 | 5/5 |
| `lateboolproductbench` / `cohomology-circle` | 0.980 | 2/5 |
| `lateboolproductbench` / `cohomology-torus` | 1.018 | 5/5 |
| `lateunitbench` / `unit-plus` | 1.547 | 5/5 |
| `lateunitbench` / `unit-minus` | 1.483 | 5/5 |
| `lateunitbench` / `nonunit-controls` | 1.017 | 4/5 |
| `lateunitbench` / `dense-control` | 0.993 | 3/5 |
| `lateunitbench` / `tiny-zero-errors` | 1.075 | 5/5 |
| `lateunitbench` / `nf-upper` | 1.169 | 5/5 |
| `lateremainderbench` / `dense-f2-power16` | 1.196 | 5/5 |
| `lateremainderbench` / `sparse-f2-power32` | 1.190 | 5/5 |
| `lateremainderbench` / `irreducibility-setup8` | 1.126 | 5/5 |
| `lateremainderbench` / `odd17-control` | 1.028 | 4/5 |
| `lateremainderbench` / `lowdegree-f2` | 1.110 | 5/5 |
| `lateremainderbench` / `setup-one-shot-f2` | 1.184 | 5/5 |
| `latebasisbench` / `tiny` | 1.015 | 2/5 |
| `latebasisbench` / `sparse` | 0.959 | 1/5 |
| `latebasisbench` / `dense` | 1.008 | 3/5 |
| `latebasisbench` / `fullrank` | 0.997 | 2/5 |
| `latebasisbench` / `zerorank` | 1.018 | 2/5 |
| `latebasisbench` / `cohomology-torus` | 0.976 | 1/5 |

QQ減算とGF(2)基底生成は元の実装の対照です。統合による共有演算・コード配置と実行時の変動も含み、
それらの小差を見送った試作の効果へ帰属しません。奇標数、非単位積、小入力、コホモロジー全体の差も省かず掲載しています。
F2の一巡目比較には二巡目の余り専用経路も作用するため、既知平方だけの効果として読みません。
各結果はこの有限入力・環境での値で、他の大きさ・係数長・バックエンドの速度保証ではありません。メモリ量は未測定です。

[最終計測の入口](../MEASUREMENTS.md#延長枠の最終実装を比較する)に全6系列の要約と完全なgzipを、
[検証ガイド](../VALIDATION.md#26時枠に採用した4件の統合検証)に固定ソースの89 package・3 target検査をまとめました。
[契約・経緯](../measurements/late-kernels-20261117-orchestration.json)と
[片付けの記録](../measurements/late-kernels-20261117-cleanup.json)も保存しています。
採用・見送りのソース、全ELF、生成C、ログとGit bundleをhash照合して保存し、五つのworktree・六branchを片付けました。

奇標数のpowerも二巡目の余り専用還元の対象です。最終版の`odd17-control`は、一巡目の平方だけに対する未変更対照とは区別します。
