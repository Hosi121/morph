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

## 検証と継続作業

各成果の3バックエンド検証、独立Fraction・有限体参照と適用範囲は個別記録にある。
この最初の統合版を固定して全repository検査を行い、source commit・全コマンド・結果を
[検証ガイド](../VALIDATION.md)へ追記する。検証中の結果を完了扱いしない。
追加の独立したGaussian log-partition微分と一般α曲率のレビュー、
曲線式の多項式証拠、微分形式の単体上の積分とWhitney形式も別の段階で扱う。
これらの成果は、統合と検証が済む前に上表へ含めない。

表現境界の修正と過去のstdoutの限界は[数値表示の記録](numeric-serialization-20261118.md)を参照。
既存のLeanモデルとdrift gateは維持し、新しい数学パッケージ全体の形式証明とは区別する。
