# 座標等式の恒等式でCAD展開を省く

改善前`828a04a`、共通benchmarkを加えた基準`1edc2c2`、採用ソース`6861797`。
対象は独立レビューから保存していた`x=0 ∧ y=1 ∧ xz²+yz−z−1=0`である。
以前のnative releaseの一入力は65秒でも完了せず、prepare後のsearchに滞在していた。
これは数学的には代入で−1=0となる矛盾であり、正確性を保って構成を省けるかを調べた。

## 重かった箇所と見送った案

状態を追うと、最初の`Pending depth=0`から進む前の根被覆が重かった。
最初の軸のfamilyは41本、各次数は1–4だが、根の和集合を表すLCMは20次となる。
各個別systemとroot unionの構築は終え、最後のunionのsystemでsquarefree化・Sturm列の費用が膨らむ。
凍結ELFの限定profileにも`prepare_fibre → realtower.system → rp_squarefree/rp_sequence`から
有理数の除算・GCD・object管理への経路が現れた。標本には切れたstackがあり、CPU weightを全wall timeの割合とは扱わない。

QQの剰余を正の係数で再スケールし、先頭係数の絶対値を1にする試作も行った。
Sturmの符号を保つ候補だが、この入力は15秒で未完了だった。一般的な有効性を否定せず、今回は採用しない。
`realtower`の本体は基準とbyte一致へ戻し、単一の仕組みとして次の恒等式による短絡だけを採用した。
診断の標本・途中までの状態ログ・試作差分は作業記録に保持する。

## 共通の数学的規則

式全体が真なら、ANDだけから取り出した正の`EqualZero`原子は必ず成立する。
そのうち`a*x_i+b=0`という座標等式を除数とし、他の必須等式pを既存の多項式除算で簡約する。
非零定数cが残った場合だけ、商q_iから

`p = Σ q_i*d_i + c`

を再構築し、元のpと厳密に一致することを確認する。pと全d_iが零ならcも零となるので、元の式全体が偽である。
今回の入力では、恒等式は`xz²+yz−z−1 = z²*x + z*(y−1) − 1`となる。
新しい数値演算やGroebner solverは作らず、既存`polynomial.divide/multiply/add`を組み合わせる。

除数を座標等式に限るのは計算量の条件である。一般の連立一次式の代入は単項式を多数へ展開し得るので使用しない。
除数は非零、非定数項が一つ、その指数和が1であることをADT上で検査する。
対象のpは線形でも非線形でもよい。OR・否定の内側や他の関係から仮定を取り出さない。
非零定数の恒等式を得られなければ、SATや`Known(true)`を推定せず従来の係数判定とCADへ戻る。

`prefixlogic.prepare`はこの場合だけ各stageを`Constant(false)`とし、探索は既存の`Leaf(false)`で閉じる。
CAD checkerも元の式からこの恒等式と条件を再計算する。元の原子・式・全Collins射影・証拠型・公開APIは維持する。
完全CADの経路も残し、`x=0 ∧ xy=1`の旧三セルの幾何学的参照はテストで検査し続ける。
元のsourceやprojectionを整合的にSAT例へ貼り替えても、偽のroot leafは拒否する。

prefixlogic本体は3→4ファイル、386→470物理行、空白・コメントを除くcode行は310→388となった。
新しい公開関数・型・package・importは0。privateな判定規則と局所helperを追加する実装増であり、行数削減とは主張しない。
code行は`line.split('//',1)[0].strip()`が非空の行で括弧も含み、tests・CLI・生成interfaceは集計から除く。
CAD・realnlsmt・realtowerの本体は基準とbyte一致。既存188生成interfaceも維持した。

## 固定条件の比較

同じSDK、native release、CPU4の共通lock、byte一致のCLIを使い、事前に固定した8経路を5ABBAで比較した。
一プロセスにつき一入力。起動・入力構成・準備・探索・到達した証拠検査・出力を含み、コンパイルを除く。
CLI内の時計はfixture構成を除き、SMT探索には通常の内部検査も含まれる。

| 経路 | 前 process中央値 ms | 後 process中央値 ms | 前/後 |
| --- | ---: | ---: | ---: |
| cad/pruned/quadratic-nullification3 | 全10回が3秒で未完了 | 109.424 | 算出しない |
| smt/core/quadratic-nullification3 | 全10回が3秒で未完了 | 174.160 | 算出しない |
| cad/pruned/prefix-unsat2 | 0.818 | 0.658 | 1.242 |
| cad/pruned/diagonal-sat3 | 3.629 | 3.365 | 1.078 |
| cad/pruned/diagonal-unsat4 | 34.907 | 36.084 | 0.967 |
| cad/pruned/univariate-sat | 0.976 | 0.888 | 1.099 |
| cad/pruned/univariate-unsat | 0.987 | 1.025 | 0.963 |
| smt/retained/diagonal-sat3 | 3.893 | 4.376 | 0.890 |

[全160プロセスのstdout・source/ELF/SDK hash・全slotと集計](../measurements/cad-linear-conflict-20261120-comparison.json)を保存した。
旧版の重いCAD/SMTは計20回が全て3秒で未完了、新版を含む残る140回は正しい判定と証拠検査まで成功した。
3秒を完了時間・平均・有限の速度倍率に置き換えない。以前の65秒診断は[改善前の記録](../measurements/heavy-inputs-20261120.json)で、
今回のCLIと同じ数学的入力だが別の測定系列である。未完了から「何倍速い」とは計算しない。
CADの新経路は1遷移で閉じ、process約109msに対してsearchの中央値は約2.3µs。残る時間は主に射影準備と証拠再検査である。

4変数の対照は34.907→36.084msで、全5blockが遅い。約1.18ms・3.4%の観測上の退行も採用判断に含めた。
原因はこの計測では特定しておらず、全入力での速度維持を主張しない。
SMTのSAT対照はprocessで約12%遅い中央値だがblockの方向は分かれ、CLI内totalは3.070→3.083msだった。
起動を含む短時間例の揺れと計算区間を区別する。一般の非線形制約や全ての旧stressを解消したという結果ではない。

新規部分が扱う狭い恒等式で巨大な根被覆を省け、独立checkerを通るという設計仮説はこの入力で成立した。
実メモリ・確保量・JS/Wasmの性能は未測定である。

## 正しさと形式モデルの範囲

座標値・定数項・入力順を変えた81件を閉じた整数式と照合し、零余りの場合のSAT証人も検査する。
非整数の係数によるスカラー倍、条件付き等式、OR・否定・不等号、零多項式、対象の線形/非線形、
一般の連立一次式へのfallback、arity・観測長・偽plan・元の式への証拠の束縛を回帰に含めた。
既存の独立Z3参照・完全CADとの照合・改竄検査も維持する。

Leanでは、任意の有限Boolean式の真からANDのみの必須原子の真を導くことと、
その原子集合の矛盾を前提に式全体の偽を導くことを証明した。
OR/NOTも仮定へ取り込む二つの誤ったモデルは拒否された。公理依存は標準の`propext, Quot.sound`のみ。
除算・恒等式の再構築・QQから実数への評価・MoonBitとの翻訳はこのモデルの形式証明には含まれない。
[対応・ledger・未証明部分](../../formal/REVIEW-prefixlogic.md#座標等式からの大域的な矛盾2026-11-20)を参照する。
