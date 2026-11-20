# 二項等式を保ったCADの矛盾判定

基準`7d80b62`、採用ソース`a1a0d23`。前回の座標代入を、連鎖する等式と非線形な二項等式へ広げた。
別のsolverや新しい公開型を増やさず、既存の多項式除算・恒等式再構築・関係評価を一つの規則で使う。

## 数学的な共通部分

たとえば`x=y ∧ y=z ∧ x²=2 ∧ z²≠2`では、必須等式から`z²−2=0`が従い、非等号と矛盾する。
平方根を生成して各枝を探索する必要はない。`xy=1`から`x²y²=1`が従う場合も同じ除算で扱える。

ANDだけから必須の原子を集め、そのうち等号だけを除数にする。まず既存の座標等式を試し、
決まらなければ一項・二項の除数を使う。lex先頭項の総次数が残項以上という条件を付け、
一単項式が複数へ展開する書き換えと総次数の増加を防ぐ。
`x−y²=0`のようにlex順で次数を増やす除数はこの追加経路から除外する。

各元等式を、自身と完全一致する式を除いた元等式群で一度ずつ簡約する。
厳密に再構築した`p = Σ q_i*d_i + r`だけから新しい二項以下の余りを追加する。
変更のない場合は恒等式`p=p`を使う。元の除数がm本なら追加は高々m本で、閉包計算はしない。
追加余りは元等式が成り立つ点で零なので、同じ規則で再利用できる。
対象原子を簡約して定数が残ったら、既存の六関係の評価で偽かを判定する。
零余りに対する`<0`・`>0`・`≠0`の矛盾も共有処理に含まれる。

これは一般のGroebner基底でも完全な連立等式判定でもない。順序によって未決定になる例は残る。
係数のbit長、除算の反復数、全体の実行時間の上限は保証しない。
恒等式を確認できなければ従来の係数判定と完全CADへ戻り、零余りからSATを推論しない。
`xy=0`から一方の因子を選ばず、`x²=y²`から平方根の枝を選ばない。

prefixlogic本体は4ファイルのまま470→549物理行、空白・コメントを除くcode行は388→465。
privateな規則の拡張であり、行数削減とは主張しない。新しい公開関数・型・package・importは0。
CAD・SMT・realtowerの本体、全188公開interfaceはbyte一致を維持した。
コード行は`line.split("//",1)[0].strip()`が非空の行で、tests・CLI・生成interfaceを除く。

## 同条件の固定比較

同一SDK、native release、CPU4の共通lock、byte一致のCLI、8経路を各5ABBAで固定した。
全160プロセスが3秒上限内に完了し、元の入力に対する判定と証拠・モデル検査が成功した。
一入力の起動・fixture構成・準備・探索・検査・出力を含み、コンパイルを除く。
内部時計のtotalはfixture構成を除く。SMT探索には通常の内部検査も含む。

| 経路 | 前 process中央値 ms | 後 process中央値 ms | 前/後 |
| --- | ---: | ---: | ---: |
| cad/pruned/diagonal-unsat3 | 18.348 | 1.380 | 13.292 |
| cad/pruned/diagonal-unsat4 | 37.721 | 2.052 | 18.382 |
| smt/core/diagonal-unsat4 | 78.367 | 4.395 | 17.831 |
| cad/pruned/diagonal-sat3 | 4.570 | 4.170 | 1.096 |
| cad/pruned/quadratic-nullification3 | 92.024 | 93.664 | 0.982 |
| cad/pruned/prefix-unsat2 | 0.864 | 0.805 | 1.074 |
| cad/pruned/univariate-sat | 1.227 | 1.040 | 1.179 |
| cad/pruned/univariate-unsat | 1.328 | 1.248 | 1.064 |

上の三つの新規矛盾経路は各5/5 blockで改善した。SAT対照はprocess中央値が約8.8%速いが、
blockの方向は分かれ、内部totalの中央値は3.344→3.188 msだった。安定した改善・退行とは断定しない。
既存の座標矛盾と短時間の一変数対照もblockの方向を保存し、主たる速度向上の根拠にしない。
以前の65秒未完了との比較とは別系列であり、今回の倍率と合成しない。
実メモリ・確保量・JS/Wasmの性能は未測定。全CAD入力の速度保証ではない。

[全slot・raw stdout・source/ELF/SDK hash・集計](../measurements/cad-binomial-conflict-20261121-comparison.json)と
[同一の実行runner](../measurements/cad-binomial-conflict-20261121-runner.py)を保存した。

## 検証と形式モデルの範囲

連鎖を六通りの原子順序で検査し、全六関係を独立した整数の格子評価と照合する。
零因子と異なる実根のSAT証人、比例する等式、相反する二項式、三項式・次数増加のfallback、
既存の座標短絡の優先も確認する。新規の積・平方の三例は完全CAD参照とも照合する。
既存の独立Z3 corpus、偽plan・改変source・projectionの拒否と完全CADを維持する。

Leanモデルは変更せず、任意selectorに対する必須原子の抽出と、矛盾を前提としたBoolean伝播を再利用する。
算術の除算・恒等式・余りの帰結・QQ評価・MoonBitへの翻訳は形式証明していない。
以前保存したOR/NOT変異の拒否は同一Leanソースの証拠であり、今回の新しい証明とは数えない。
[対応・適用条件・未証明部分](../../formal/REVIEW-prefixlogic.md#二項等式と六関係への一般化2026-11-21)を参照する。

固定checkpoint`8c8b7b8`を基準`7d80b62`と比較し、影響6package・runtime5packageについて
wasm-gc・JS・native releaseで各303テストが成功した。残る1CLIはソースとnative metadataでtest不在を確認。
global型検査、85 Pythonテスト、純粋性397ファイル、188生成API、全既存形式モデルも成功した。
計測ソース`a1a0d23`からcheckpointまでmodule・wrapper・全srcのbyte一致を確認した。
[固定checkpoint・全コマンド・全ログ・構造の照合](../measurements/cad-binomial-conflict-20261121-validation.json)を保存した。
既存の独立oracleや重要な公開処理は削除せず、比較用のclean worktreeだけを削除した。
必要な凍結ELF・生ログと、純粋性監査による構文修正前の比較はprivateな作業記録に保持する。
