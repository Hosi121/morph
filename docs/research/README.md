# 研究・探索記録

[ドキュメント](../README.md) / [探索・改善記録](../bootstrap/README.md)

設計上の考察、複雑な算法への挑戦、通常経路へ採用しなかった試作を保存します。
現行の設計説明は[ハンドブック](../../HANDBOOK.md)、採用状況は[基礎部品の最適化](../KERNELS.md)を参照してください。

| 記録 | 内容 | 状態 |
| --- | --- | --- |
| [複雑な算法への挑戦](advanced-algorithms-20261116.md) | 実数制約、Blossom、Hensel/Zassenhaus、BCHへの4時間の探索 | 進行中 |
| [一変数の実数制約](realcad-20261116.md) | 符号不変分割、無理数の証人、存在・全称と証拠検査 | 統合検証中 |
| [一般グラフのマッチング](blossom-20261116.md) | 奇数サイクルの縮約・展開、Tutte–Berge証拠 | 統合済み |
| [整数・有理多項式の分解](zassenhaus-20261116.md) | Berlekamp・Hensel・Zassenhaus | [独立レビュー](zassenhaus-independent-review-20261116.md)済み |
| [二進BCH符号](bch-20261116.md) | 共役根からの構成、系統符号化、代数的訂正 | 統合済み |
| [GSリスト復号](listdecode-20261116.md) | 多重度補間、Roth–Ruckenstein、複数候補 | 統合済み |
| [実代数的数](realalgebraic-20261116.md) | resultants、共役選択、厳密な演算 | [独立レビュー](realalgebraic-independent-review-20261116.md)・返却値の束縛を補強 |
| [F4 Gröbner基底](f4-20261116.md) | Macaulay行列、元入力へのideal witness | 統合済み |
| [実数制約の独立レビュー](realcad-independent-review-20261116.md) | Fraction・二次体の独立符号と境界検査 | 検査範囲で反例なし |
| [パリティゲーム](parity-20261116.md) | Zielonka法、位置戦略、独立した閉路検査 | 統合済み |
| [有限な実解集合の表現](realvariety-20261116.md) | F4からshapeを抽出し、一つの代数的パラメータで全実解を表す | 対応shapeを明示して統合 |
| [探索とリファクタリングの履歴](HISTORY.md) | 初期の実装、表現コストの見直し、検証と統合の経緯 | 当時の記録を保存 |
| [長語除算・剰余](wide-kernels/README.md) | 逆順fold、末尾再帰、有限prefix、unrollの比較 | 通常経路へ未採用 |

履歴にある期限・作業場所・テスト数は当時の条件です。
試作の成功例を、通常のライブラリ経路の成果や性能として読み替えないでください。
