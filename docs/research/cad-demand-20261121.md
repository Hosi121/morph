# 使わない余りの恒等式を再構築しない

基準`2f46fca`、採用ソース`bdd99a3`。前回の二項等式による矛盾判定を簡単にする改善である。
SAT例や未決定の原子でも、捨てる余りについて恒等式を再構築していた。
呼出側が既に持つ採用条件を先に適用し、必要な結果だけを厳密に検査する順序へ変えた。

## 残す検査と省く計算

矛盾判定では元の関係に反する定数だけ、新しい帰結の追加では未登録の二項以下の式または矛盾する定数だけを使う。
それ以外の余りは判定にも除数にも使わないため、再構築せず`None`を返せる。
採用する変更には、引き続き`p = Σ q_i*d_i + r`を再構築し、元のpとの厳密な一致を要求する。
変化がない場合の恒等式`p=p`も維持する。採用する証拠の検査を弱める変更ではない。

旧版の「検査してから採用条件」と新版の「採用条件を調べてから検査」は、
副作用のない検査が終了する場合に同じ結果を返す。未終了・資源枯渇まで同じ挙動とする契約ではない。
商の生成と多項式除算、全Collins射影は残る。採用条件は一度だけ評価する。

prefixlogic本体は4ファイル・549物理行のまま、空白・コメントを除くcode行は465→463。
新しい公開関数・型・package・importは0。他の全kernel sourceと188生成interfaceはbyte一致。
code行は`line.split("//",1)[0].strip()`が非空の行で、tests・CLI・生成interfaceを除く。

## 公開prepareの反復比較

native release・同一SDK・CPU4の共通lockで4入力を各5ABBA、全80プロセスが成功した。
初期CADから得た同じ実際の射影族を使い、公開`prefixlogic.prepare`を一プロセスで128回実行する。
内部時計には各回のPlan全体の等号確認と`bench.keep`を含む。
初期のCAD・射影構築、参照Plan、最終`check_plan`、表示・起動は内部時計の外で、process時間には含まれる。
候補の生成Cでも、prepareとkeepが128回loopの内側にあることを確認した。コンパイラの一般証明ではない。

| 入力 | 前：128回の中央値 ms | 後：128回の中央値 ms | 前/後 | 改善block |
| --- | ---: | ---: | ---: | ---: |
| diagonal-sat3 | 2.556 | 2.294 | 1.114 | 5/5 |
| diagonal-unsat4 | 3.644 | 2.977 | 1.224 | 3/5 |
| prefix-unsat2 | 0.329 | 0.271 | 1.213 | 4/5 |
| circle-sat2 | 0.353 | 0.351 | 1.006 | 2/5 |

SATの準備反復は全5blockで改善した。他の小差と方向の分かれた入力は確定的な改善に数えない。
この局所結果の約11%をsolver全体の改善率へ置き換えない。
両sourceへ同一の一時CLI二ファイルだけを重ねてbuildし、元のGit treeと保存したoverlayからsource manifestを独立に再構築した。
dirtyなCLIは意図した計測用overlayであり、測定後に両方とも元のbytesへ戻した。
全Planの等号確認に加え、両版のDebug出力も一致した。表示はSDK既定の深さ16で、一般的な完全serializationの証明ではない。
[全80出力・overlay原文・source/ELF hash・生成Cのloop](../measurements/cad-demand-20261121-prefix.json)を保存した。

## 全体の時間と同一ELFの対照

同じ元CLIを使い、8経路を各5ABBAで比較した。全160回が3秒上限内に完了し、
判定・証拠検査だけでなく、時計以外の全出力と探索回数が両版で一致した。
起動・入力構築・準備・探索・検査・出力を含み、コンパイルを除く。

| 経路 | 前 process中央値 ms | 後 process中央値 ms | 前/後 |
| --- | ---: | ---: | ---: |
| cad/pruned/diagonal-sat3 | 5.543 | 4.948 | 1.120 |
| smt/retained/diagonal-sat3 | 5.513 | 6.321 | 0.872 |
| cad/pruned/diagonal-unsat3 | 1.697 | 1.431 | 1.186 |
| cad/pruned/diagonal-unsat4 | 2.708 | 2.478 | 1.093 |
| smt/core/diagonal-unsat4 | 5.989 | 5.345 | 1.120 |
| cad/pruned/quadratic-nullification3 | 111.972 | 115.340 | 0.971 |
| cad/pruned/prefix-unsat2 | 1.181 | 1.192 | 0.991 |
| cad/pruned/circle-sat2 | 1.995 | 1.769 | 1.128 |

SMTのSAT例はprocessで約15%遅い標本を得た。この観測も除外せず残す。
一方、同じ基準ELFを両側に使った別の固定5ABBA・40プロセスでも、次の差が現れた。

| 同一ELFの入力 | process中央値の前/後 | 前が遅いblock |
| --- | ---: | ---: |
| smt/retained/diagonal-sat3 | 1.247 | 4/5 |
| cad/pruned/circle-sat2 | 1.195 | 5/5 |

同一ELFにも同程度以上のprocess差が出る環境であり、全体時間の差が変更固有かは分離できていない。
これは回帰が無いことの証明ではない。全体の速度向上や全入力の速度維持は主張しない。
[元CLI全160出力](../measurements/cad-demand-20261121-comparison.json)、
[同一ELF全40出力](../measurements/cad-demand-20261121-identical.json)を保存した。
局所のSAT準備では不要な再構築を省く効果が見え、本体も2code行減るため採用する。
実メモリ・確保量・JS/Wasmの性能は未測定。新しいsolverや最適化エンジンは導入していない。

## 正しさの範囲

既存の独立整数式・有理数証人、完全CAD参照、独立Z3 corpus、偽Planと改変sourceの拒否を維持する。
LeanのBooleanモデルはbyte一致であり、同じ条件付き健全性を再確認する。
除算・恒等式・QQから実数への評価・検査順序の等価性・MoonBitへの翻訳は形式証明していない。
[対応と未証明部分](../../formal/REVIEW-prefixlogic.md#不採用の余りの再構築を省く2026-11-21)を参照する。

固定checkpoint`85d8eb7`を基準`2f46fca`と比較し、影響6package・runtime5packageで
wasm-gc・JS・native releaseが各303テスト成功した。残る1CLIはソースとnative metadataでtest不在を確認。
global型検査・85 Pythonテスト・純粋性397ファイル・188生成API・全既存形式モデルも成功した。
計測ソース`bdd99a3`とcheckpointのmodule・wrapper・全srcはbyte一致を確認した。
[固定checkpoint・全コマンド・全ログ・構造の照合](../measurements/cad-demand-20261121-validation.json)を保存した。
計測用overlayは元のbytesへ戻し、比較用のclean worktreeを削除した。凍結ELFと必要な生ログ・再現用overlayは保持している。
