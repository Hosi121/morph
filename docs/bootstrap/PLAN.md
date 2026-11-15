# 2026-11-15 後半のbootstrap探索

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
