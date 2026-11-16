# 2026-11-15 後半のbootstrap探索

[ドキュメント](../README.md) / [探索・改善記録](README.md)

この計画は2026-11-15〜16の作業枠の記録で、完了済みです。
当時の優先順位・期限・公開条件の変更を残しています。現在の作業指示ではありません。

ユーザー承認：既存SATを検証・合成へ使い、基礎を最適化して上位算法へ戻す方針で4時間。
開始13:35:48 UTC、終了17:35:48 UTC（翌02:35:48 JST）。
後からサブエージェントへの並行実装も明示的に依頼された。
出発点mainは65ef524。正本は/home/hosi/morph、共有mainへの統合はrootが行う。

| 担当 | 独立する変更範囲 | 既存の凍結された依存 |
| --- | --- | --- |
| root | SAT回路検査/合成、共通binary/sat内部の最適化、共有文書と統合 | 既存pub APIを維持 |
| cyclotomic | src/cyclotomic、src/exactfft、専用generatorと文書 | exact、polynomial、core、binary |
| sat-engine | src/cdcl、専用generatorと文書 | sat.Literal/Cnf/Model、core、binary、avl |
| number-theory | src/primality、src/factor、専用generatorと文書 | modular、binary、core、exact |

各workerは専用worktreeで成果単位のcommitを作り、rootが検証してcherry-pickする。
新しい回路検査のCNF境界は既存sat.Cnfとし、探索エンジンの実装から分離する。
公開APIの意味は凍結し、共通算術を内部最適化しても同じ結果を保つ。
一つの成果ができたworkerは次の候補を報告し、rootが依存関係と残り時間から再配置する。
空いた枠を使って、別文脈からの順次レビューも行う。

## ユーザーの追加指示を反映した後半の優先度

14:44 UTC頃：共有プリミティブ/カーネルをできるだけ高速化し、必要なら超最適化するよう明示。
進行中のSMT・AES・LLLを成果単位で区切り、新たな上位算法は増やさず次を分担する。

| 担当 | 優先する共有部品 |
| --- | --- |
| root | binary算術・比較・変換・基礎構造、全体比較 |
| cyclotomic | fppoly/galois、特に標数2の演算 |
| sat-engine | RUP hintsの生成/検査、SAT内部の支配コスト |
| number-theory | exact.Integer/Rational、上位のLLL/Smith/simplexへの波及 |

14:48 UTC頃：ユーザーがHosi121/morphのpublic repo作成とuploadを明示。
この指示で従来の「push/外部公開しない」条件を更新する。
公開担当はcyclotomic、rootが全体検証した固定SHAを通常pushし、コミット履歴を維持する。
研究探索の期限17:35:48 UTCは変更しない。

## 2026-11-16の継続枠

前回の期限を過ぎた再開時に区切りを確認し、ユーザーが「あと4時間、同じ方針で反復」と回答。
新しい枠は2026-11-16 01:58:27〜05:58:27 UTC（10:58:27〜14:58:27 JST）。
公開先Hosi121/morphと通常pushの許可、核の純粋性・厳密性・同条件比較・成果ごとのcommitを継続する。
古いgoal recordの期限と非公開条件より、この後続の明示指示を優先する。

最初は残った除算/GCD、Nat変換、定数共有、SAT入口の作業を回収する。
rootがmainと共通Binaryの既存関数を管理し、workerは専用treeと新helperまたはCDCLを担当する。
測定は全worktree共通の`tools/measure` mutexを使用する。
05:30 UTC頃をsource確定の目安とし、残りで全体検証・文書・公開snapshot・片付けまで行う。
