# 検証ガイド

[ドキュメント](README.md) / [開発・検証環境](ENVIRONMENT.md)

実行テスト、証拠検査、Leanモデルは、それぞれ異なる性質を確かめます。
このページでは検証済みのコード、変更時のコマンド、各検査の保証範囲を案内します。

`tools/check`の`check_evidence.py`は、`docs/measurements`の共通形式の比較JSONと完全なgzipの圧縮前後のhash、
ABBAの全slot、stdoutと全出力の一致、標本から再集計した中央値・範囲・block比を検査します。
検証ログは公開ファイルのhashと各コマンドのbyte位置・hashを照合します。
`moon_test_results`付きのnative SDKログでは、start/resultの対と空の成功messageも確認し、終了コード0のassertion failureを拒否します。
過去のジョブを再実行する処理ではなく、記録の整合性を検査するものです。
実行結果の数学的な正しさや、ベンチマークの代表性を証明するものではありません。

## 商構成・Hodge・基礎部品の追加検証

これらはそれぞれの固定ソース・変更影響範囲に対する検査です。異なる行の件数を合算した全体テスト数ではありません。

| 固定対象 | 実行範囲と結果 | 記録 |
| --- | --- | --- |
| 不採用の恒等式の再構築削減 `85d8eb7` | 影響6package・runtime5package、wasm-gc/JS/native releaseで各303成功。global型検査・85 Pythonテスト・純粋性397ファイル・188生成API・既存形式モデルも成功。一時計測overlayを復元した最終srcを検査 | [checkpoint・全ログ・構造の照合](measurements/cad-demand-20261121-validation.json) |
| CAD二項等式 `8c8b7b8` | 影響6package・runtime5package、wasm-gc/JS/native releaseで各303成功。global型検査・85 Pythonテスト・純粋性397ファイル・188生成API・既存形式モデルも成功。算術全体の形式証明ではない | [checkpoint・全ログ・構造の照合](measurements/cad-binomial-conflict-20261121-validation.json) |
| Hodge・matrix/tensor/runbinary統合 `234ede3` | 影響121packageのうちruntime98package、wasm-gc/JS/native releaseで各4,724成功。残る23CLIはソースとmetadataでtest不在を確認 | [checkpoint・コマンド・ログ](measurements/hodge-kernels-integrated-20261118-validation.json) |
| せん断の最終merge（`8e4c234`に取込み） | 2変更ソースのSHAを記録。forms/hodge/simplexformsを3targetで各933成功。120項→106項と逆操作、既存888基底対照を含む | [局所検証](measurements/hodge-shear-final-20261118/summary.json) |
| 商構成試作 `60f8d9e` | 新規3packageの影響範囲、3targetで各9テスト成功。global型検査・84 Pythonテスト・純粋性395ファイル・既存形式検証も成功 | [固定checkpointと全ログ](measurements/quotient-prototype-20261118-validation.json) |
| 簡単化 `660d039` | 未採用3packageの撤去とsimplicialmapの共通処理への委譲。3target各30成功、global型検査・84 Pythonテスト・純粋性387ファイル・既存形式検証も成功 | [固定checkpoint・ログ・削減量](measurements/simplification-20261118-validation.json) |
| 商構成の復元 `1167c46` | 本体・テスト14ファイルを整理前の版とbyte一致で復元。比較CLIを除く188生成APIも一致。復元2packageを3targetで各9成功、global型検査・84 Pythonテスト・純粋性394ファイル・既存形式検証も成功 | [復元・API照合と全ログ](measurements/quotient-restoration-20261118-validation.json) |

商環の9テストは、F₂の全30法・4,680積と340単元判定、QQ・checked adapter、GF(4)係数の全256積を内部で検査します。
[評価](research/quotient-prototype-20261118.md)には有限検査の範囲と未確認事項を記載しています。
新しい商環・Hodgeの法則をLeanで証明したものではありません。既存モデルの通過と区別します。

商の140プロセス比較は、当時のharnessが全3,276,800出力を独立整数多項式oracleと照合します。
`tools/check`では[証拠検査器](../tools/construction-bench.py)で保存済みの出力・集計・source/ELFのhashを再検査し、過去のベンチマークを再実行しません。

## 数体・複素数体の重複処理の共有（2026-11-19）

固定ソース `79676d8`、基準 `9984703`。Horner評価、係数・次数、冪の線形従属、最小性検査を既存polynomial/linearへ共有した。
numberfield/complexfieldの公開APIはbyte一致、linear/polynomialには計5関数のみ追加し、既存の関数・型は変更していない。
新しい型・パッケージは0、本体は共通核を含めて60物理行減（空白・コメントを除くcode行は69減）。テスト追加は別計上する。

変更の逆依存106packageを選び、テストがある87packageをwasm-gc・JS・native releaseで実行し、**それぞれ4,966件成功**。
残る19個はソースとコンパイラmetadataでtest不在を確認したCLIだけ。global型検査・84 Pythonテスト・純粋性396ファイル・既存形式モデルも成功した。
[固定checkpoint・全ログ・API照合](measurements/field-minpoly-sharing-20261119-validation.json)と[8入力・160プロセスの比較](measurements/field-minpoly-sharing-20261119.json)を保存する。
既存の形式モデルの通過を、新しいgeneric関数や任意のcallbackの法則に対する形式証明とは扱わない。

## F₂の係数規則の共有（2026-11-19）

固定ソース`22f1727`、基準`13b85cb`。canonicalな係数列のXORと素体F₂の判定を共有し、既存のAPI・専用乗算・正規化境界を維持した。
逆依存60packageのうちruntime 47packageをwasm-gc・JS・native releaseで実行し、**それぞれ1,627件成功**。
残る13CLIはソースとcompiler metadataでtest不在を確認した。global型検査・85 Pythonテスト・純粋性396ファイル・既存形式モデルも通過した。
[固定checkpoint・全ログ・API照合・本体の削減量](measurements/f2-sharing-20261119-validation.json)と
[180プロセスの比較条件と制約](research/mathematical-constructions-20261118.md#f₂の係数規則を共有した結果2026-11-19)を保存した。
既存モデルの通過は、共有したXORの任意長入力に対する新しい形式証明ではない。

## CSS・Markovのスカラー構成の共有（2026-11-20）

固定ソース`fc701be`、基準`0abcc77`。既存gf2とalgebraの構成へ委譲し、公開API・型・importは維持した。
逆依存12packageのうちruntime 7packageをwasm-gc・JS・native releaseで実行し、**それぞれ306件成功**。
残る5CLIはソースとcompiler metadataでtest不在を確認した。global型検査・85 Pythonテスト・純粋性396ファイル・既存形式モデルも通過した。
[固定checkpoint・全ログ・APIと本体の照合](measurements/scalar-sharing-20261120-validation.json)と
[共有範囲・削減量・性能比較](research/mathematical-constructions-20261118.md#利用側のスカラー代数を共有した結果2026-11-20)を保存する。

## Tensorの一時列・恒等置換の省略（2026-11-20）

固定ソース`1d711b9`、基準`3bc3ffc`。公開APIと格納表現を保ち、内積を直接の左foldへ融合し、恒等置換で不変Tensorを再利用した。
逆依存8packageのうちruntime 5packageをwasm-gc・JS・native releaseで実行し、**それぞれ165件成功**。
残る3CLIはソースとcompiler metadataでtest不在を確認した。global型検査・85 Pythonテスト・純粋性396ファイル・既存形式モデルも通過した。
[固定checkpoint・全ログ・APIと本体の照合](measurements/tensor-temporaries-20261120-validation.json)・
[単独/併用の比較と残る無駄](research/tensor-temporaries-20261120.md)を保存した。任意形状への新しい形式証明ではない。

## スカラー曲率のrank 4展開の省略（2026-11-20）

固定ソース`2d45adc`、基準`fe4a754`。既存zipとfoldを組み合わせ、対応成分n²個だけでスカラー縮約を再計算する。
公開API・import・shape検査の順序は維持し、旧rank 4関数の本体をwhitebox参照として保存した。
逆依存4packageのうち3packageをwasm-gc・JS・native releaseで実行し、各142件成功。残る1CLIはソースとnative metadataでtest不在を確認。
非対角・不定値の有理計量、零次元、独立な単体・conformal公式と既存SymPy fixtureを含む。
global型検査・85 Pythonテスト・純粋性396ファイル・既存形式モデルも通過した。
[checkpoint・全ログ・構造とAPIの照合](measurements/scalar-contraction-20261120-validation.json)と
[4入力・80プロセスの時間/RSS比較](research/scalar-contraction-20261120.md)を保存する。任意の計量についての新しい形式証明ではない。

## 座標等式からのCAD短絡（2026-11-20）

固定ソース`f2014d8`、基準`828a04a`。必須の座標等式による除算と恒等式の再構築をprefixlogicへ追加し、非零定数の矛盾だけを全域の偽へ導く。
CAD・SMT・realtowerの本体と公開APIを維持。完全CADの幾何学的な参照と、SATへの整合的なsource/projection貼替えの拒否も確認した。
影響6packageの実行対象5packageをwasm-gc・JS・native releaseで確認し、各298件成功。残る1CLIはソースとnative metadataでtest不在を確認。
global型検査・85 Pythonテスト・397核ソースの純粋性・188生成API・全形式モデルも通過した。
Leanは任意のBoolean式からANDのみの必須原子を抽出する条件と、矛盾を前提とする全体の偽を検査し、OR/NOTからも仮定を取る二つの変異を拒否した。
多項式除算・QQから実数への評価・MoonBitへの翻訳まで形式証明したものではない。
[checkpoint・全ログ・正負の形式検査](measurements/cad-linear-conflict-20261120-validation.json)と
[8経路160試行・時間切れ・対照の3.4%退行・適用条件](research/cad-linear-conflict-20261120.md)を保存する。

## 確率・情報幾何の検証の到達段階

Amari–Chentsovテンソルの明示API、添字上げ・trace・ノルム・接ベクトルへの作用、Gaussianの2・3次cumulant経路を追加しました。
定義・符号・座標系と入力の条件は[確率と情報幾何](handbook/probability-geometry.md)、
独立した期待値の導出は[独立検証](research/amari-chentsov-independent-20261118.md)を参照してください。

ソース `cd58f60` を固定し、全graph 180 packageを型検査、runtime 161 packageを実行しました。
19個の省略はソースとコンパイラmetadataの両方でtestがないと確認できたCLIだけです。

| バックエンド | 全体 `cd58f60` | 追加統合 `bc6818d` の3package |
| --- | ---: | ---: |
| wasm-gc | 5558成功 | 31成功 |
| js | 5558成功 | 31成功 |
| native release | 5558成功 | 31成功 |

全体検証の後に、独立fixtureと新公開APIの直接照合を統合しました。
その後の本体差分は `gaussian/information.mbt` のdoc commentだけで、関数本体と180公開interfaceのbyte一致を確認しています。
変更したGaussian・statgeometryと逆依存のCLIを、別の固定ソースで3target再検証しました。
二つのソースのテスト数を合計して、最終版の一括実行数とは扱いません。

独立参照はGaussianのlog-partition微分7点と、有限モデル4点・20個のα接続/曲率です。
元の5,306成分とscore・pullbackの補助40成分を、wasm-gc・JS・nativeで完全一致まで確認しました。
ゼロと対称な位置を含む成分位置数で、異なる有理数の個数ではありません。
新公開APIは同じ参照値の636 Gaussian成分・80有限モデル成分を直接使って照合し、独立corpusの追加件数とは区別しています。
Gaussianの積が結合的でない具体例も、追加統合の検査に含みます。

Python検査、純記号制約、生成物・保存済oracle、全targetの型、公開interface、既存Leanモデルと対応領域の差分検査が通過しました。
新しい情報幾何全体やChentsovの一意性定理を形式証明したものではありません。
通常の `tools/check` はSymPyを必要とせず、独立数式の再導出は[環境ガイド](ENVIRONMENT.md#情報幾何の独立参照を再生成する)の別手順です。

[全体のソース・graph・全コマンド](measurements/amari-chentsov-20261118-full-validation.json)、
[全体ログ](measurements/amari-chentsov-20261118-full-validation.txt)、[実行runner](measurements/amari-chentsov-20261118-full-harness.py)、
[追加統合のソース・範囲・全コマンド](measurements/amari-chentsov-20261118-integrated-validation.json)、
[追加統合ログ](measurements/amari-chentsov-20261118-integrated-validation.txt)、[追加統合runner](measurements/amari-chentsov-20261118-integrated-harness.py)を保存しました。
作業用worktreeとbranchは、18採用ファイルの一致とGit bundleの検査後に片付けています。
[片付けの証跡](measurements/amari-chentsov-20261118-cleanup.json)を参照してください。

前回の `569c6c3` の全体検証は、初期化を待たず次段を起動した `FileNotFoundError` と期限で完了stageが0でした。
[当時の状態](measurements/information-geometry-20261118-status.json)と
[初期化record](measurements/information-geometry-20261118-checkpoint-initialization.json.gz)は履歴として保持します。
今回の `cd58f60` では初期化を確認してから7段階を逐次実行し、全体検証を完了しました。
Whitney形式と曲線式の証明書の未完成draftは引き続きmainから除外しています。

## 変更範囲を段階ごとに検査する

[check_affected.py](../tools/check_affected.py)は、基準からの変更と旧・現のimport graphから逆依存を選び、
固定したソースに対する検査を段階ごとに保存します。長い一個のプロセスにまとめず、一段ずつ別の呼び出しで進めます。

```bash
tools/measure --cpu 4 python3 tools/check_affected.py --record .tools/affected/run.json --init --base HEAD~1
tools/measure --cpu 4 python3 tools/check_affected.py --record .tools/affected/run.json --stage next
python3 tools/check_affected.py --record .tools/affected/run.json --status
```

`HEAD~1`は比較する実装の基準へ置き換え、初期化前に変更をcommitします。
全packageを対象に固定して検査するときは、初期化時に `--full` を追加します。
その場合も空CLIの省略は同じ厳しい条件に限定し、全graphと省略根拠をrecordへ保存します。
`--stage next`は、maintenance、全targetの型、wasm-gc、js、native release、既存formalの順で一段だけ実行します。
状態が`passed`になるまで進めます。完了済みの段を再指定すると、ログのhashを照合して再実行を省きます。

中断時はソース・runner・完了済みログのhashを再確認し、未完了の段のpartial logを保存します。
前の子プロセスが生きていれば重複実行を拒否し、同じrecordへの同時更新もロックします。
HEADやソースが変わった場合は、別のrecordで検査します。
既存APIの差分には`--allow-interface`による明示したreview対象が必要で、全体のmodule/compiler変更はこの範囲検証で代用しません。

影響graphと実行するtest packageは別に保存します。`cmd/`内で、普通の実行module設定・testファイルなし・
source内にtest/bench/fenceなし・キャッシュしたnativeの両test metadataも空、を全て満たす場合だけ、
空のtest driverの生成を省きます。全targetの型検査は維持します。
`runtime_packages`と`skipped_zero_test_commands`に集合と根拠のsource/config/metadata hashを保存し、各段の前後で照合します。
metadataがない、新しい設定・生成処理・条件付きtestの可能性がある場合は省きません。

実装`9aaf4b9`では、直前に全検査した108 packageから17個の空CLIだけを省き、nativeを91 packageで再実行しました。
元と同じ3,816テストが全て通過しています。数学のsrc・module・formalは`1a51057`と同一です。
67件のPython検査には、inline/WB/条件付きtest、doc fence、未知設定、metadata欠損・不一致を残す例と、
省略根拠が変われば停止する例を含みます。残る21個の空CLIも、保守的な判定では残しています。
コンパイル時間の短縮率は測っていません。
[集合・根拠・実行コマンド](measurements/runtime-selection-20261117-validation.json)、
[全出力](measurements/runtime-selection-20261117-validation.txt)、
[実行harness](measurements/runtime-selection-20261117-harness.py)を保存しました。



## 変換監査後の2件の統合検証

コード`1a51057`を固定し、基準`a63dcbc`からの変更と旧・現のimport graphの逆依存を検査しました。
対象は108 packageです。WBだけを変更したownerの逆依存も保守的に含めます。
全repositoryの無変更テストを実行し直した記録とは区別します。

| バックエンド | 成功数 |
| --- | ---: |
| wasm-gc | 3,816 |
| js | 3,816 |
| native release | 3,816 |

Python55テスト、167コンパイラ生成interface、全targetの型検査、整形・生成物・334核ソースの純記号制約が通過しました。
既存の公開interfaceは基準とbyte一致で、四つの測定CLIだけが追加です。
既存Lean全モデルと32対応領域の差分検査も通過しました。monicや共有helperの全実装を形式証明したものではありません。
同じ基準に対する4公開CLI・24入力・480プロセスの完全な出力と証拠の照合も成功しました。
棄却した定数・剰余の実装は統合していません。最終CLIは元の生成器を使い、採用変更の上位への影響や変動を測る対照です。

[ソース・環境・対象graph・全コマンド](measurements/conversion-kernels-20261117-validation.json)、
[全検証ログ](measurements/conversion-kernels-20261117-validation.txt)、[実行したrunnerの同一コピー](measurements/conversion-kernels-20261117-harness.py)、
[比較driver](measurements/conversion-kernels-20261117-comparison-driver.py)を保存しました。
checker本体を保っても共有するmonicは変わるため、旧monic・旧列helper・独立Fraction/小整数参照を併用しています。

[採否と全比較](research/conversion-kernels-20261117.md)、[分担・契約・経緯](measurements/conversion-kernels-20261117-orchestration.json)、
[片付けの記録](measurements/conversion-kernels-20261117-cleanup.json)を参照してください。
六つの作業用worktree・四branchを、採用と棄却のソース・生成C・ELF・ログ・Git bundleを検査保存して片付けました。

## 26時枠に採用した4件の統合検証

コード`a63dcbc`を固定し、基準`a39f323`からの変更と旧・現のimport graphの逆依存を検査しました。
対象は89 packageで、テスト用importも含みます。無変更の無関係なテストまで再実行した全体検証とは区別します。

| バックエンド | 成功数 |
| --- | ---: |
| wasm-gc | 3,667 |
| js | 3,667 |
| native release | 3,667 |

Python43テスト、163公開APIスナップショット、全targetの型検査、整形・生成物・333核ソースの純記号制約が通過しました。
既存APIのsnapshotは基準と一致し、六つの測定CLIのsnapshotだけが追加です。
既存Lean全モデルと32対応領域の差分検査も通過しました。新しい最適化全体の形式証明ではありません。
六つの公開CLI・36入力・720プロセスが、完全な結果と証拠の検査に成功しました。
不採用の減算融合とGF(2)係数列の準備は統合せず、最終CLIでは元の生成器を対照に使っています。
GF(2)自身のcheckerは専用Bool積と演算を共有するため、旧generic積・独立Bool参照も使います。

[環境・ソース・対象graph・全コマンド](measurements/late-kernels-20261117-validation.json)、
[完全な検証ログ](measurements/late-kernels-20261117-validation.txt)、[実行したrunnerの同一コピー](measurements/late-kernels-20261117-harness.py)、
[最終比較driver](measurements/late-kernels-20261117-comparison-driver.py)を保存しました。
最初のmaintenanceも成功しましたが、追加CLIの生成interfaceをcommitした後に全段を新しいrecordで実行しました。
[最初の記録](measurements/late-kernels-20261117-first-maintenance.json)を残し、完了済みの別ソースの実行を最終記録へ混ぜていません。

[採否と測定](research/late-kernels-20261117.md)、[契約・担当範囲・経緯](measurements/late-kernels-20261117-orchestration.json)、
[片付けの証跡](measurements/late-kernels-20261117-cleanup.json)を参照してください。
五つの作業用worktree・六branchは、Git bundle、採否両方のパッチ、生成C、ELF、ログを保存しhashを検査して片付けました。

## 夜間に採用した共通部品の統合検証

コード `a39f323` を固定し、基準 `ab22a4a` からの変更と旧・現のimport graphの逆依存を検査しました。
対象は84 packageで、テスト専用importも含みます。全repositoryの無変更テストを再実行した記録とは区別します。

| バックエンド | 結果 |
| --- | --- |
| wasm-gc | 3,603テスト成功 |
| js | 3,603テスト成功 |
| native release | 3,603テスト成功 |

Python 31テスト、157公開APIスナップショット、全targetの型検査、整形・生成物・330核ソースの純記号制約が通過しました。
既存Lean全モデルと32対応領域の差分検査も通過しました。新しい実装全体の形式証明ではありません。
8件の採用変更を組み合わせた9公開CLI・54入力・1,080プロセスも、全結果と証拠の検査に成功しています。
不採用のcursor実装は統合していません。同じ名前の最終CLIは元の生成器の対照です。

既存公開APIは数体のopaqueなFieldにprivate cacheの表示が増える以外、コンパイラ生成snapshotのバイト列が一致します。
checkerの算法を維持しても、生成側と共有する多項式演算などは変わるため、旧divide・独立Fraction/Bool参照との照合も併用しました。
独立生成fixtureの再生成も通常の`tools/check`へ組み込んでいます。

[環境・ソース・選択graph・全コマンド](measurements/night-kernels-20261117-validation.json)、
[全出力](measurements/night-kernels-20261117-validation.txt)、[実行harness](measurements/night-kernels-20261117-harness.py)、
[最終比較driver](measurements/night-kernels-20261117-comparison-driver.py)を保存しました。
最初の整形ゲート失敗はruntimeテスト開始前で、[修正前の記録](measurements/night-kernels-20261117-first-attempt.json)も残しています。
修正はbenchmarkの空白と末尾commaだけで、最終比較の両側を同じharnessからbuildしています。
途中のnativeジョブは終了code143で中断しました。完了済みのソース・ログのhashを再照合し、未完了のnativeとformalだけを
[再開harness](measurements/night-kernels-20261117-resume-harness.py)で完了しました。[中断ログ](measurements/night-kernels-20261117-interruption.json)も保存しています。

[採否と全計測](research/night-kernels-20261117.md)、[担当範囲と経緯](measurements/night-kernels-20261117-orchestration.json)、
[片付けの証跡](measurements/night-kernels-20261117-cleanup.json)を参照してください。
六つの作業用worktree・九branchは、全採用パッチ・却下ソース・生成C・実行ファイル・ログとGit bundleを検査して保存し、削除しました。
前回の範囲検証と、それ以前の全体検証は下に残しています。

## 数体・増分線形従属・Smithの算法改善

コード `ffc66b7` を固定し、基準 `2e33ef5` からの変更と旧・現のimport graphの逆依存を検査しました。
対象は46 packageで、テスト専用importも含みます。無変更の無関係なpackageを再実行した全体検証ではありません。

| バックエンド | 結果 |
| --- | --- |
| wasm-gc | 1,140テスト成功 |
| js | 1,140テスト成功 |
| native release | 1,140テスト成功 |

Python 27テスト、148公開APIスナップショット、全targetの型検査、整形・生成物・327核ソースの純記号制約が通過しました。
既存Lean全モデルと32対応領域の差分検査も通過しました。新しい増分spanや数体最適化の全実装を形式証明したものではありません。
最小多項式・FGLM・Smithの既存検査算法は維持し、旧方式、独立Fraction・行列式、停止と再開、次元違いなどを照合しました。
生成と検査には共通の演算もあります。有限なoracleとの照合と、独立した全実装の証明は区別します。

公開APIは`numberfield.coordinates`と新しい`linearspan`を追加し、opaqueなFGLM状態にcacheを保持します。
既存の関数の結果・エラー・証拠の条件を維持し、不採用にした持続性の本体・import・APIは基準と同じバイト列へ復元しました。

[環境・ソース・選択graph・全コマンド](measurements/algorithm-kernels-20261117-validation.json)、
[全出力](measurements/algorithm-kernels-20261117-validation.txt)、[実行harness](measurements/algorithm-kernels-20261117-harness.py)を保存しました。
全出力の各コマンド部分はバイト位置とSHA256でも検査できます。
増分spanの15個のベクトル列・120判断のFraction参照は、
[再生成ゲート](../tools/generate_linearspan_fixtures.py)でMoonBit fixtureと凍結JSONの両方を照合します。
`tools/check`にも含めているため、元の生成スクリプトを手動で実行する必要はありません。
[五候補の採否と440試行](research/algorithm-kernels-20261117.md)、
[担当範囲と統合](measurements/algorithm-kernels-20261117-orchestration.json)、
[基準ライブラリの同一性](measurements/algorithm-kernels-20261117-baseline-invariance.json)も残しています。
四つの作業用worktreeと三branchは、全パッチ反映、Git bundle検査、ソース・実行ファイルの保存を確認して削除しました。
担当が使った段階別スナップショットの削除も含め、[片付けの記録](measurements/algorithm-kernels-20261117-cleanup.json)にあります。

## Fp多項式の正規形を使う演算

コード `7749ddc` を固定し、基準 `03d6584` からの変更と旧・現のimport graphの逆依存を検査しました。
対象は36 packageで、テスト専用importも含みます。全repositoryの無変更テストを再実行した記録とは区別します。

| バックエンド | 結果 |
| --- | --- |
| wasm-gc | 1,392テスト成功 |
| js | 1,392テスト成功 |
| native | 1,392テスト成功 |

全体のPython 27テスト・144公開API・型・整形・生成物・325核ソースの純記号制約が通過しました。
既存Lean全モデルと32対応領域の差分検査も通過しました。新しいhelper全体の形式証明ではありません。
fppoly・modular・primefieldを含む既存公開APIは変更していません。
独立した425係数対・54積/除算ケースを追加し、未還元constructor・相殺・幅違い・零・field mismatchも検査しました。

[環境・ソース・選択graph・全コマンド](measurements/canonical-fp-20261117-validation.json)、
[全出力](measurements/canonical-fp-20261117-validation.txt)、[実行harness](measurements/canonical-fp-20261117-harness.py)を保存しました。
前回の84 packageの検証記録と、それ以前の全体検証は下に残しています。
設計と比較の範囲は[正規形の再利用](research/canonical-fp-20261117.md)を参照してください。
今回の3 worktree・2作業branchは、全パッチ反映・Git bundle・harnessと実行ファイルの保存を確認して削除しました
（[片付け](measurements/canonical-fp-20261117-cleanup.json)、[担当範囲と経緯](measurements/canonical-fp-20261117-orchestration.json)）。

## 体のカーネルの影響範囲検証

コード `af279b4` を固定し、基準 `4d9e6c4` からの変更と旧・現のimport graphの逆依存を検査しました。
対象は84 packageで、テスト専用importも選択に含みます。全repositoryの無変更なテストを再実行した記録とは区別します。

| 検査 | 結果 |
| --- | --- |
| WasmGC / JS / native release | 対象の各3,545テスト成功 |
| 全体の保守・型・API | Python 27テスト、143公開API、警告なし型検査、生成fixtureが通過 |
| 純記号制約 | 325核ソース。機械数値型・配列・可変状態・FFIなし |
| 既存のAPI | linear・primefield・modular・CSS・cohomology・homologyの公開スナップショットは変更なし。rowreduceには零判定付き入口を追加 |
| 既存Leanモデル | 全モデルと32対応領域の差分検査が通過。新規GF(2)核全体の形式証明ではない |
| 独立参照 | 全689の小GF(2)行列と5,054右辺、Fractionの1,539系、未還元素体入力、既存証拠の改変検査 |
| 旧比較の保守 | 元の四hashを維持したBareiss参照ゲート、11種類の意図的変更を拒否 |

[ソース・選択graph・全コマンド](measurements/field-kernels-20261117-validation.json)、
[全出力](measurements/field-kernels-20261117-validation.txt)、[実行harness](measurements/field-kernels-20261117-harness.py)、[再開harness](measurements/field-kernels-20261117-resume-harness.py)、
[参照ゲートの改変検査](measurements/field-kernels-20261117-reference-mutations.json)を保存しました。
途中の実行セッション中断は[保存時点の記録](measurements/field-kernels-20261117-interrupted.json)に残しています。
nativeの完了記録がなかったため、ソースと完了ログのhashを照合してnative・Leanだけを再開しました。
[環境の補足](measurements/field-kernels-20261117-environment.json)は再開時点のホスト情報です。
検証の範囲に関する正本はJSONのpackage一覧・実行成功数で、宣言数を成功数に数えたものではありません。
[採否・計測条件](research/field-kernels-20261117.md)と
[共通算法・専用化の設計](handbook/field-kernels.md)も参照してください。
今回の4 worktreeと3作業branchは、全パッチ反映・Git bundle・必要な実行ファイルの保存を確認して削除しました
（[片付け](measurements/field-kernels-20261117-cleanup.json)、[担当範囲と経緯](measurements/field-kernels-20261117-orchestration.json)）。

## 積・相対群・崩壊の影響範囲検証

コード `72f166a` で、変更した7 packageと旧・現のimport graph上の逆依存を検査しました。
対象は11 package、各バックエンド255テストです。無変更の数体・CAD等を全件再実行した記録ではありません。
前回の全4,142テストの記録は下に残しています。今回の追加宣言は207で、現在の全宣言数と今回の実行成功数は別です。

| 検査 | 結果 |
| --- | --- |
| WasmGC / JS / native release | 影響範囲の各255テスト成功。旧homology、simplicialmap、CSSと新規核を含む |
| 全体の保守・型・ソース制約 | Python 24テスト、323核ソース、138公開API、全体の警告なし型検査が通過 |
| 共通化の互換性 | 既存homologyの公開APIスナップショットは変更なし |
| 既存Lean・対応差分 | 既存全モデルと32対応領域が通過。新しい核全体の形式証明ではない |
| cup積の独立照合 | 167小複体、269,883 cochain対、49,923 cocycle対、トーラス・wedge・RP2の積 |
| 相対群の独立照合 | 315小対の境界・rank・連結写像、整数minorとRP2のねじれ |
| 崩壊の独立照合 | 167複体・9,781候補・340収縮、整数I/P/Hの各成分と恒等式、改変拒否 |
| filtered adapter・ツアー | 同grade・全非零成分のgradeを検査。ツアー3バックエンド・21起動ケースが一致 |

正本は[ソース・選択graph・コマンド・生値](measurements/topology-rings-20261117-validation.json)、
[全出力](measurements/topology-rings-20261117-validation.txt)、
[実行したharness](measurements/topology-rings-20261117-harness.py)です。
対象は `chainhomology`, `cmd/connections`, `cmd/topology`, `cmd/topologyrings`, `cohomology`, `collapse`, `csscode`, `filteredcollapse`, `homology`, `relativehomology`, `simplicialmap`。
全体の型検査で見つけたテスト補助型のtrait宣言を修正し、失敗した二試行も同データに保存しています。
使い方は[コホモロジー環・相対群・崩壊](handbook/cohomology-relative-collapse.md)、
判断理由は[探索記録](research/topology-rings-20261117.md)にまとめました。
3作業用worktreeは全パッチ反映とGitアーカイブを確認して削除しました
（[片付け記録](measurements/topology-rings-20261117-cleanup.json)）。

## 全体検証済みスナップショット（前回）

2026-11-17（JST）にコード `93a2913` を固定して統合検証しました。
有理点群のVietoris–Rips filtration、GF(2)持続ホモロジー、整数誘導準同型、
CSS符号の論理商・最小重みと、従来の全算法を含みます。
以後の文書編集を、新しい計算核の検証として数えるものではありません。

| 検査 | 結果 |
| --- | --- |
| native（release） / JS / WasmGC | 各4,142テスト成功。前回から51宣言を追加 |
| Pythonの保守ゲート | 24テスト成功 |
| 純記号制約 | 312核ソースが通過 |
| 公開API | 132生成スナップショットが一致 |
| Lean | 既存の全モデルと32対応領域の差分検査が通過。新しい位相・符号核全体の形式証明ではない |
| 持続性の独立照合 | 230 filtrations、43,718の全次数・prefix対rank。tie-order・入力と証拠の改竄も検査 |
| 単体写像の独立照合 | 19複体、3,439頂点関数、四面体の256写像、729ずつのchain/H1合成 |
| CSSの独立照合 | 小部分空間の82可換組・204拒否組、583ベクトル、RP2とトーラスの全bitmask最小重み |
| 有理点群 | 121入力×3次元上限を独立部分集合・直接距離と照合。二乗距離、座標の重複、打ち切りを検査 |
| 位相ツアー | 3バックエンドで掲載出力と一致。既定・モード・不正引数の全21起動ケースも通過 |

正本は[環境・ソース・実行記録](measurements/topology-20261117-validation.json)と
[全出力](measurements/topology-20261117-validation.txt)、
再実行した[検証harness](measurements/topology-20261117-harness.py)です。
現在の入口は[位相と符号](handbook/topology.md)、設計と独立参照は[探索記録](research/topology-20261117.md)から辿れます。
探索燃料は実時間の上限ではなく、CSS距離の最小性検査も指数時間の再列挙です。
今回の3作業用worktreeは全パッチの反映・Gitアーカイブを検査して削除しました
（[片付け記録](measurements/topology-20261117-cleanup.json)）。

前回の群・不等式・整数ホモロジーの統合では、計算核 `6cf0f28` で各4,091テストを確認し、
ツアー起動引数だけを `9bccd5a` で修正しました。
当時の[環境と集計](measurements/connections-20261117-validation.json)・
[全出力](measurements/connections-20261117-validation.txt)と
[片付け記録](measurements/connections-20261117-cleanup.json)も保存しています。

## 変更したときに実行する

すべてリポジトリのルートで実行します。

| 変更 | コマンド |
| --- | --- |
| 文書 | `python3 tools/check_docs.py` |
| 計算核・探索・検査器 | `tools/check` と `tools/moon test --target native` |
| 対応するLeanモデルやソース | `tools/check_formal` |
| 独立fixture | [実閉体・SMT](ENVIRONMENT.md#実閉体非線形smtの独立fixtureを再生成する)・[複素代数](ENVIRONMENT.md#複素代数の独立fixtureを再生成する) |

`tools/check` は保守テスト、ソース制約、整形、型、生成物、WasmGC・JSテスト、公開APIの差分を検査します。
文書のリンク検査にはMoonBitやLeanは不要です。Leanの初回準備は[形式検証](../formal/README.md)を参照してください。
共有のLinux環境では、重い処理を `tools/measure --cpu N COMMAND...` で直列化できます。
CPU番号は環境に合わせて指定します。

## 検査が示すもの

| 方法 | 確認する性質 | 信頼する部分・限界 |
| --- | --- | --- |
| ソース検査 | 核への数値型・配列・可変状態・FFIの混入、代表的な変換往復の再導入 | 保守的な字句検査。停止性やコンパイラの正しさは証明しない |
| 総当たり・独立オラクル | 有限の入力集合で、整数・配列・別実装の期待値と一致すること | 入力範囲とオラクルに依存する。任意長への一般化は別に必要 |
| 問題ごとの証拠検査 | SAT反証、最大流のカット、LPの双対解などが元の問題の根拠を満たすこと | 検査器と共有算術を信頼する。探索と別の検査器もプログラムである |
| 外部チェッカー | SAT核の出力をLRAT/DRAT形式でも受理できること | 選んだ問題とチェッカーに対する確認。偽造例の拒否も併せて調べる |
| Leanモデル | 加算、半分化、二進変換、比較、fold、疎Horner、条件付きBoolean評価などの全称命題 | 手で対応付けたモデルの証明。原子観測の健全性など明示的な仮定がある。複素代数・CAD・SMT・コンパイラ全体の証明ではない |
| 対応差分・公開API検査 | レビューしたソース領域や公開型の変更の検出 | 差分を検出する仕組み。変更後の意味の正しさは別途確認する |

定理とソースの対応は[形式検証](../formal/README.md)、主張ごとの根拠は
[検証台帳](bootstrap/verification-ledger.md)、個別の独立レビューは[研究記録](research/README.md)にあります。
パッケージ一覧の「テスト宣言数」、実行成功数、一つのテスト内の比較例数は異なる集計です。

## 過去の検証記録

履歴の値は、その時点のコードと条件に対する結果です。

| コード | 段階 | 記録 |
| --- | --- | --- |
| `701e789` | 最小分解体・共通体・完全Galois作用、各4,041テスト | [集計](measurements/complex-splitting-20261117-validation.json)・[出力](measurements/complex-splitting-20261117-validation.txt) |
| `0c79742` | K(i)・一生成元・明示自己同型と固定体、各3,976テスト | [集計](measurements/complex-galois-20261117-validation.json)・[出力](measurements/complex-galois-20261117-validation.txt) |
| `060a66f` | K(i) と一生成元表示の追加範囲、各38テスト | [集計](measurements/complex-fields-20261117-validation.json)・[出力](measurements/complex-fields-20261117-validation.txt) |
| `4aa8668` | 複素代数の演算・全根・因数分解の接続、各3,920テスト | [集計](measurements/complex-algebra-20261117-validation.json)・[出力](measurements/complex-algebra-20261117-validation.txt) |
| `b8e5ff3` | 理論衝突節の削減、各3,871テスト | [集計](measurements/theory-core-20261117-validation.json)・[出力](measurements/theory-core-20261117-validation.txt) |
| `de2a892` | CDCL状態保持、各3,835テスト | [集計](measurements/retained-cdcl-20261117-validation.json)・[出力](measurements/retained-cdcl-20261117-validation.txt) |
| `8fe68f0` | 円柱の枝刈り、各3,817テスト | [集計](measurements/incremental-20261117-validation.json)・[出力](measurements/incremental-20261117-validation.txt) |
| `37d82f5` | 多段実代数体・任意変数CAD・量化消去、各3,775テスト | [集計](measurements/realclosed-20261116-validation.json)・[出力](measurements/realclosed-20261116-validation.txt) |
| `9880edf` | 複雑な算法の仕上げ、各3,311テスト | [出力](measurements/advanced-20261116-final-validation.txt) |
| `12db9d8` / `6934453` | 複雑な算法の第二段階 / 最初の段階 | [第二段階](measurements/advanced-20261116-second-validation.txt)・[最初の段階](measurements/advanced-20261116-first-validation.txt) |

`b8e5ff3` の六関係・共有被覆18組の照合は[衝突節削減の記録](research/theory-core-20261117.md)、
当時の資料の保管先は[片付け記録](measurements/theory-core-20261117-cleanup.json)を参照してください。

<details>
<summary>前段階の基礎kernel検証とSAT反証の外部検査</summary>

2026-11-16のコード `c331d0c` に対する記録です。

| 検査 | 結果 |
| --- | --- |
| native / JS / WasmGC | 各499テスト成功 |
| Python / 純記号制約 / 公開API | 12テスト / 122核ソース / 69生成スナップショット |
| Leanとの対応 | 24領域の差分検査と全モデルが通過 |
| SAT反証の外部検査 | 16証拠をLRAT/DRAT両方が受理、7偽造例を拒否 |

[核・テスト・Lean](measurements/final-kernels-validation.txt)・
[外部反証検査](measurements/final-proof-validation.txt)・
[証拠マニフェスト](measurements/final-proof-manifest.json)を保存しています。

</details>

## 資源と性能の限界

値の一致、再帰の深さ、割当量、実行速度は別々に確認します。
燃料付き探索の一歩にも、リスト走査や有理数演算が含まれ、一定実時間を保証しません。

JSの通常の長語除算・剰余には、`2^20000 mod 3` で確認したスタック制約が残ります。
20,000bitは耐久試験の入力で、上位アルゴリズムに必要な桁数を示すものではありません。
[末尾再帰化の試作](research/wide-kernels/README.md)は値とスタックの検査を通過しましたが、
nativeの剰余が遅くなるため採用していません。

性能の比較条件は[計測記録](MEASUREMENTS.md)、通常経路への採否は[基礎部品の最適化](KERNELS.md)を参照してください。
異なる測定系列の倍率は掛け合わせません。
