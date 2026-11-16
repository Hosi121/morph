# 到達点と次の候補

[ドキュメント](README.md) / [ハンドブック](../HANDBOOK.md)

多段の実代数拡大、有限個の実数変数を扱うCAD、一階実数式の量化消去、
量化なしの非線形実数SMTまで実装しています。
複素代数的数の厳密演算と、有理係数多項式の全複素根・重複度の列挙も接続しています。
実数体 K に i を加えた基底計算と、α+i による一生成元の表現も使えます。
全根を同じ体で指定できる場合は、全自己同型と部分群の固定体も計算できます。
部品の接続は[厳密代数の計算経路](handbook/algebraic-solving.md)、
入力・出力・証拠の使い分けは[実数制約の章](handbook/real-constraints.md)、
確認済みの検査と対象ソースは[検証ガイド](VALIDATION.md)を参照してください。

## 実装済みの範囲

有理係数の多項式の等式・不等式とBoolean結合を扱い、量化消去では有限個の変数と量化を受け取ります。
近似に置き換えず、解や不可能性の根拠を検査できる形で返します。
燃料不足による未完了やエラーを、UNSATへ置き換えません。

| 層 | できること | 設計・独立検査の記録 |
| --- | --- | --- |
| 多段の実代数拡大体 | 選択根を順に加え、厳密な四則演算・零判定・順序比較を行う | [実装](research/realtower-20261116.md)・[独立レビュー](research/realtower-independent-review-20261116.md) |
| 任意変数のCAD | 変数列に沿って射影とliftingを再帰し、実数空間をセルに分割する | [実装](research/cad-20261116.md)・[独立レビュー](research/cad-independent-review-20261116.md) |
| 一階実数式の量化消去 | セルの真偽を量化順序どおり集約し、自由変数の解集合を量化なしの式で表す | [正規化](research/realformula-20261116.md)・[式の出力](research/signcad-20261116.md) |
| 量化なしの非線形実数SMT | CDCLと厳密な実数理論を接続し、SATの厳密モデル、UNSATのCAD理論補題と最終RUP反証を検査する | [実装](research/realnlsmt-20261116.md)・[独立レビュー](research/realnlsmt-independent-review-20261116.md) |
| 複素代数と全複素根 | 実代数的な二座標の演算、QQ因数分解から各全根・元の重複度への復元 | [設計・同条件比較](research/complex-algebra-20261117.md)・[独立参照](research/complex-oracle-20261117.md) |
| 基底を持つ複素数体 | K(i) の四則演算・trace/norm・最小多項式、α+i による絶対一生成元の双方向変換 | [設計](handbook/complex-fields.md)・[数体の独立参照](research/complexfield-oracle-20261117.md)・[変換の独立参照](research/complexprimitive-oracle-20261117.md) |
| 明示分解した体の対称性 | 全自己同型・合成表、部分群の固定体の完全基底と座標。z⁴−2 では D4 と全10中間体 | [設計](handbook/galois-fixed-fields.md)・[群の参照](research/complexautomorphism-oracle-20261117.md)・[固定体の参照](research/fixedfield-oracle-20261117.md) |

## 現在の探索経路と残る課題

既定のSMT経路は、必要なセルからの探索、理論衝突後のCDCL状態の保持、
既存のCAD被覆を使った理論衝突節の削減を組み合わせます。
完全CADや再始動する経路も比較用に残しています。入口ごとの違いは[実数制約の章](handbook/real-constraints.md)にまとめています。

| 実装した工夫 | 保つ条件・限界 | 根拠 |
| --- | --- | --- |
| 厳密なSAT早期終了と円柱の枝刈り | 親セル全体の真偽を検査できる範囲でliftingを省く。全Collins射影の費用は残る | [探索と検査の記録](research/incremental-cad-20261117.md) |
| 理論衝突後のCDCL状態の保持 | 検査済み理論節を単調に追加し、学習節・trail・watchを保持する | [状態保持の記録](research/retained-cdcl-20261117.md) |
| 既存被覆からの理論衝突節の削減 | 元の被覆で部分式の不可能性を検査する。短縮されたセルで判断できなければ原子を残し、最小の節は保証しない | [削減と独立検査の記録](research/theory-core-20261117.md) |

性能比較は[計測記録](MEASUREMENTS.md)から辿れます。改善は入力ごとの結果であり、すべての問題への高速化を示すものではありません。

| 残る課題・候補 | 現在の制約 |
| --- | --- |
| 局所射影 | 現在は全Collins射影を使い、必要な部分だけを射影する経路はない |
| 算術側の状態保持と学習 | CDCL状態の保持とは別に、算術処理の再利用と学習が必要 |
| 理論衝突節の追加削減 | 省略されたセルの情報が足りない場合は、保守的に原子を残す |
| 仮定のpush/pop | 単調な理論節追加を越える、仮定の取り消しは未実装 |
| 密な多項式・深い実代数拡大 | 体演算と射影の費用が大きく、規模の拡大には同条件の計測が必要 |

[Jovanović–de Moura, Solving Non-Linear Arithmetic](https://dddejan.github.io/papers/jovanovic-ijcar2012.pdf)は、
非線形実数制約にCDCL型探索とCAD由来の射影を接続する参考文献です。
本プロジェクトの証拠形式、ADTによる表現、性能上の採否は個別に設計・検査しています。
実装をつないだ経緯は[実閉体ソルバの作業記録](research/realclosed-20261116.md)に保存しています。

## 別の長期候補

以下は、既存の部品から考えられる研究候補です。実装の完了や性能を見積もったものではありません。

| 目標 | 使える部品 | 大きな不足 |
| --- | --- | --- |
| 一般の分解体・Galois群・根号可解性 | QQ既約分解、実数体の合成、LLL、[複素根](handbook/complex-algebra.md)、[自己同型と固定体](handbook/galois-fixed-fields.md) | 任意の複素拡大体の自動合成、分解体探索、一般の群分類・resolvent |
| 実代数集合の連結成分と経路 | CAD、実根、実解の一変数表現 | 特異点、セルの接続関係、roadmap |
| Schoof/SEAの楕円曲線点数計算 | 有限体、拡大体、多項式、楕円曲線、CRT | 除算多項式、torsion、Frobenius作用、traceの復元 |

Galois群の参考は[Stauduhar](https://www.ams.org/mcom/1973-27-124/S0025-5718-1973-0327712-4/S0025-5718-1973-0327712-4.pdf)です。
原典は根の高精度近似も使うため、今回の制約では厳密な根隔離・有理区間による別設計が必要です。
既存の `galois` パッケージは有限拡大体を扱います。
`complexautomorphism` は全根を指定した K(i) の自己同型群を扱い、任意のQQ多項式からの分解体探索は行いません。

幾何の参考は[Basu–Royの実代数集合のroadmap](https://arxiv.org/abs/1305.3211)、
点数計算は[Schoofの解説とAtkin–Elkiesの改善](https://www.numdam.org/item/JTNB_1995__7_1_219_0/)です。
