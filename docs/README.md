# ドキュメント

[morph](../README.md) の実装を読み、試し、検証するための案内です。

## まず使う

| 知りたいこと | 読む資料 |
| --- | --- |
| 準備して実行する | [READMEの実行手順](../README.md#試す)・[開発・検証環境](ENVIRONMENT.md) |
| 実装済みの算法とソースの入口 | [アルゴリズム一覧](ALGORITHMS.md) |
| 基礎算法と代数の実行例 | [基本ツアー](TOUR.txt)・[厳密代数とモデル検査](ADVANCED_TOUR.txt) |
| 実数制約と複素根の実行例 | [実閉体と非線形SMT](REALCLOSED_TOUR.txt)・[複素代数](COMPLEX_TOUR.txt) |
| 分解体と群の実行例 | [対称性と中間体](GALOIS_TOUR.txt)・[最小分解体と根置換](SPLITTING_TOUR.txt) |
| 群・不等式・位相の部品をつなぐ | [分野をまたぐ計算](handbook/connections.md) |
| 点群・図形の写像・符号をつなぐ | [位相と符号](handbook/topology.md)・[実行例](TOPOLOGY_TOUR.txt) |
| 同じ穴の数の空間を区別し、相対群・簡約を計算する | [積・相対群・崩壊](handbook/cohomology-relative-collapse.md)・[実行例](TOPOLOGY_RINGS_TOUR.txt) |
| 確率・Gaussian・Markov連鎖から幾何へ進む | [確率と情報幾何](handbook/probability-geometry.md)・[実行例](INFORMATION_TOUR.txt) |

## 設計と限界を読む

| 知りたいこと | 読む資料 |
| --- | --- |
| データ型から算法を組み立てる考え方 | [ハンドブック](../HANDBOOK.md) |
| 多項式、基底、実解、数体をつなぐ | [厳密代数の計算経路](handbook/algebraic-solving.md) |
| 複素数を厳密に演算し、全根を取り出す | [複素代数的数と全複素根](handbook/complex-algebra.md) |
| 複素数体の基底を固定して計算する | [複素数体と一生成元の表現](handbook/complex-fields.md) |
| 体の対称性と中間体を計算する | [自己同型と固定体](handbook/galois-fixed-fields.md) |
| 多項式から最小の分解体と群を求める | [最小分解体とGalois群](handbook/complex-splitting.md) |
| 実数の厳密演算、CAD・量化消去、非線形SMTを使い分ける | [実数制約の章](handbook/real-constraints.md) |
| 表現と証拠の違いを手元で試す | [小さな実験](handbook/exercises.md) |
| テスト・証拠検査・形式証明の対象 | [検証ガイド](VALIDATION.md) |
| 実装済みの範囲と残る課題 | [到達点と次の候補](ROADMAP.md) |

## 実装の状態を調べる

| 資料 | 役割 |
| --- | --- |
| [パッケージ一覧](INVENTORY.md) | ソースから生成した依存関係・テスト宣言数 |
| [呼び出し経路](CALL_PATHS.md) | 本体からの参照と、公開API・独立実装の区別 |
| [基礎部品の最適化](KERNELS.md) | 通常経路へ採用した改善、利用先、比較条件 |
| [形式検証](../formal/README.md) | Leanモデルの定理、実装との対応、レビュー |
| [計測記録](MEASUREMENTS.md) | 性能比較の条件・生ログと、初期計測のアーカイブ |

## 研究と履歴を調べる

| 資料 | 役割 |
| --- | --- |
| [探索・改善記録](bootstrap/README.md) | 個別の実装、最適化、採用・棄却の根拠を分野別に探す |
| [研究・探索記録](research/README.md) | 厳密代数・実数制約などの実装と独立レビュー、未採用の試作 |
| [2026-11-16の検証済み到達点](bootstrap/RESULTS-20261116.md) | 当時のソースに固定した横断検証と制約の記録 |

現在の設計はハンドブック、確認済みの検査は検証ガイドから辿れます。
日付付きの探索記録や生ログは、当時の入力・ソース・環境に対する結果と判断の経緯を保存しています。
文書内のコマンドは、特記がなければリポジトリのルートで実行します。
