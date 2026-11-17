# 確率・情報幾何と拡大体の接続

[研究索引](README.md) / [確率と情報幾何](../handbook/probability-geometry.md) / [実行例](../INFORMATION_TOUR.txt)

## 到達した計算経路

既存の有理算術・疎多項式・線形代数を再利用し、有限分布から微分幾何へつなぐ。
暗号側は別の作業場所で拡大体の曲線とペアリングを組み立て、rootで統合する。
計算核は不変ADT・再帰・厳密演算を維持し、数値近似を導入していない。

| 部品 | 使える経路 |
| --- | --- |
| probability | 検査済み有限分布、期待値、Bayes、条件付け、独立積、粗視化、長方形確率核とBayes逆核 |
| markov | 厳密な時間発展、定常分布の完全なアフィン解、到達確率、有限/無限の無条件平均到達時間と証拠 |
| infogeom | 正規化した確率2/3-jet、Fisher行列、cubic、α接続と微分、自然勾配 |
| 多項式・指数型モデル | 多項式の恒等的正規化と3階微分、有限指数型分布族の自然座標の局所微分 |
| riemann | 計量2-jet、Levi-Civita接続、Riemann/Ricci/scalar、共変微分、測地線の点での加速度 |
| statgeometry | 確率モデルから計量jetへ接続、一般α曲率、cubicの引き戻し、共通テンソルによる添字上げと縮約 |
| tensor | 検査済みshape、置換、積、縮約、軸に沿った線形変換、cursorによる走査 |
| gaussian | 永続memoを持つStein再帰、多項式期待値、2〜4次cumulantから自然座標のFisher計量jet |
| forms | 有理多項式係数の外積・外微分・縮約・Lie微分、pullback、radial homotopyと閉形式のprimitive |
| simplexforms | 向き付き有理単体への微分形式の厳密積分、全境界を束縛するStokes証拠 |
| extensioncurve・pairing | 拡大体上のJacobian群演算、Miller関数とshift divisorによるreduced Tate評価 |

例として、確率単体の断面曲率 `1/4`、一般αでは `(1−α²)/4`、
独立Bernoulliの積の平坦性、1変量Gaussianの族の曲率 `−1/2` を厳密に確認した。
これらは点での局所計算であり、大域的な多様体や任意の測地線・距離を解くソフトウェアではない。
局所の指数型jetも、密度の指数・対数の値を評価するAPIとは分けている。

## テンソルの基礎改善

旧実装は、各寄与のたびにrow-majorのoffsetをPeano数で組み立て、成分列を先頭から参照していた。
変更後はprefix・軸・suffixの不変blockを進め、縮約の対角blockとmode productの列をcursorで処理する。
API、shapeの境界、零次元、半環の加算・乗算の呼出順を保つ。
[担当の直接比較](tensor-20261118.md)は、六つの固定操作・5 ABBA・120実行で全結果を検査した。
dim3/5の添字上げ相当で1.872/4.055倍、積と二回の縮約で1.920/3.111倍。
tinyとzeroの小さい差は未確定とする。

rootは公開 `cmd/information` を両側で固定し、実際のモデル生成を含めて別に比較した。
19個の依存packageとCLIを照合し、差は `tensor/contraction.mbt` と追加 `tensor/cursor.mbt` のみ。
同じSDK、native release、CPU4、共有lock、5 ABBAで100プロセスの完全な出力を検査した。

| 実際の利用経路 | 基準→候補の中央値 | 比 | 改善したblock |
| --- | ---: | ---: | ---: |
| 2次元単体のLevi-Civita曲率 | 17.559→17.193 ms | 1.021 | 3/5 |
| 2次元単体のα曲率 | 44.588→42.138 ms | 1.058 | 4/5 |
| 3次cubicテンソルの引き戻し | 47.013→35.543 ms | 1.323 | 5/5 |
| 2変量GaussianのFisher計量jet（対照） | 49.668→49.906 ms | 0.995 | 3/5 |
| 0次元scalar（対照） | 2.900→2.686 ms | 1.080 | 4/5 |

各プロセスは固定した回数の演算・結果照合・JSON表示を含む。表は1回の数学演算の時間ではない。
明瞭な上位の改善はこの3次cubicの引き戻しに限定する。
GaussianやLevi-Civita曲率全体の改善、一般の無回帰、保持量や実メモリの削減は主張しない。
独立Python参照は、単体の曲率・cubicの閉形式と、独立な標準Gaussianのdouble factorialを使い、
計量・曲率・接続係数・3/4階の微分データまで全成分を比較する。

証拠は[全100出力](../measurements/information-tensor-consumers-20261118.json.gz)、
[要約とhash](../measurements/information-tensor-consumers-20261118-summary.json)、
[凍結harness](../measurements/information-tensor-consumers-20261118-harness.py)、
[基準の全依存ソース](../measurements/information-tensor-consumers-20261118-baseline-source.tar.gz)、
[候補の全依存ソース](../measurements/information-tensor-consumers-20261118-candidate-source.tar.gz)。
ELFと生成Cはローカルの作業archiveにも保存する。
`tools/check_information_evidence.py` は全slot・全数値・再集計・source archiveを通常検査する。
欠損・重複slot・誤った結果・timing改変のnegative controlも含む。

## 期限で止めた検証と未完成の作業

各成果の3バックエンド検証、独立Fraction・有限体参照と適用範囲は個別記録にある。
統合後のTensor・statgeometry・Gaussianはnative 28/28も確認した。
一方、最終版全体の3バックエンド検証は完了していない。
180 packageのgraphと161 runtime packageを確定したが、次段を初期化完了前に起動した手順ミスで
recordが見つからず停止した。maintenanceを含め、完了した全体stageは0。
期限は2026-11-18 06:02:46 JSTで、超過の確認後は新しい実装・実験を止め、保存と引継ぎを行った。
保存recordの `running` は初期化時の値であり、現在ジョブが実行中である意味ではない。
到達段階は[検証ガイド](../VALIDATION.md)と[停止時の記録](../measurements/information-geometry-20261118-status.json)を参照。

未完成の作業はmainへ混ぜず、復元用のpatch・期待値・sourceをローカルarchiveへ保存する。

| 未完成の作業 | 保存したものと未確認の点 |
| --- | --- |
| 追加の独立Sympy照合 | Gaussianと一般α曲率の5,306有理成分の期待値を生成。実装との最終照合は0完了 |
| curveidentity | ホストで加算・倍算などの零剰余と誤式の反例を確認。MoonBitのproducer/checkerとWB helpersは未完成・未ビルド |
| Whitney形式 | 未コミットのsourceとpatch。最新版のnative型検査のみで、専用oracle・テスト・API生成は未実施 |

単体の積分・Stokesの最初の区切りは統合済みで、未完成のWhitney形式とは分ける。

表現境界の修正と過去のstdoutの限界は[数値表示の記録](numeric-serialization-20261118.md)を参照。
既存のLeanモデルとdrift gateは維持し、新しい数学パッケージ全体の形式証明とは区別する。

採用済みpackageのworker版との一致、Git bundle、未完成source、性能のELF・生成C・profileを検査保存した後、
六つの作業用worktreeと五つのbranchを片付けた。[片付けの記録](../measurements/information-geometry-20261118-cleanup.json)を参照。
ローカルの `.tools/information-geometry-20261118/` は再開用のarchiveとして保持する。
