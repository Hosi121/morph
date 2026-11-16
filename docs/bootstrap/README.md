# 探索・改善記録

[ドキュメント](../README.md) / [ハンドブック](../../HANDBOOK.md)

基礎部品、SAT・回路合成、数論などの実装と最適化について、仮説、検査、採用・棄却の理由を保存しています。
独立レビューがあるものは、実装と同じ行に並べています。
各ページは作業時点の記録です。現在の採用状況は[基礎部品の最適化](../KERNELS.md)、
確認済みの検査は[検証ガイド](../VALIDATION.md)、比較条件と生ログは[計測記録](../MEASUREMENTS.md)を参照してください。
厳密代数・CAD・非線形SMTなどの記録は[研究・探索記録](../research/README.md)にまとめています。

## 基礎算術

| テーマ | 記録 |
| --- | --- |
| Natと二進表現の往復 | [SAT入口の改善](naturals.md) · [直接の半分化](nat-conversions.md) · [末尾共有](nat-tail-sharing.md) · [8進単位の変換](nat-radix-grouping.md) |
| 不変リストと加算 | [定数prefix](constant-prefix.md) · [加算のsuffix共有](addition.md) · [全加算器の候補探索](adder-search.md) |
| 恒等則と共有値 | [Binary恒等則](primitive-identities.md) · [0/1の共有](binary-constants.md) · [小さい積](tiny-products.md) · [小さい差](tiny-differences.md) |
| 除算と比較 | [幅差制限の試作](aligned-division.md) · [適応除算・剰余](adaptive-division.md) · [比較の計算核](binary-comparison.md) |
| 厳密有理数 | [段階最適化](exact-optimization.md) · [小さいGCD](exact-tiny-gcd.md) · [直接減算](rational-subtraction.md) |
| 圧縮二進数 | [run算術](runbinary.md) · [独立レビュー](review-runbinary.md) |

## SAT・検証・合成

| テーマ | 記録 |
| --- | --- |
| SATエンジン | [CDCLの構築と改善](sat-engine.md) · [独立レビュー](review-cdcl.md) |
| 反証と回路 | [ヒント付きRUP](ruplog.md) · [Bool式・CNF・miter](circuits.md) |
| 回路合成 | [NAND合成](synthesis.md) · [独立レビュー](review-synthesis.md) |
| 論理の別表現 | [BDD](bdd.md) · [差分制約とSMT](smt.md) |
| 主張の管理 | [検証台帳](verification-ledger.md) |

## 数論・代数・符号

| テーマ | 記録 |
| --- | --- |
| 素数と分解 | [素数証明・Pollard rho](number-theory.md) · [証明生成](primeprove.md) · [離散対数](discretelog.md) |
| 有限体 | [素数体](primefield.md) · [多項式と拡大体](finitefields.md) · [GF(2^m)の性能比較](gf2-performance/README.md) |
| 円分体と変換 | [円分体・厳密FFT](cyclotomic.md) |
| 整数線形代数 | [Smith標準形](smith.md) · [LLL](lll.md) |
| 暗号と誤り訂正 | [AES](aes.md) · [Berlekamp–Massey・巡回RS](cyclic-rs.md) |

## 履歴・横断記録

| 資料 | 内容 |
| --- | --- |
| [2026-11-16の到達点](RESULTS-20261116.md) | 当時のソースに固定した成果、横断検証、制約 |
| [時系列](TRACE.md) | 実装・検証・統合の順序 |
| [当時の計画](PLAN.md) | 作業枠、優先順位、後続指示による変更 |
| [探索タスクのひな形](TASK_TEMPLATE.md) | 独立した実装・比較を依頼するときの記録項目 |
| [初期の考察と整理](../research/HISTORY.md) | 旧ハンドブックから移した探索・リファクタリングの記録 |

生ログは[measurements](../measurements)、GF(2^m)の個別ログは
[gf2-performance](gf2-performance)に保存しています。数値の比較には各記録のソース・入力・環境を使ってください。
