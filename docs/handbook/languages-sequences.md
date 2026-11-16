# 言語と列アルゴリズム

[ハンドブック](../../HANDBOOK.md) / [ドキュメント](../README.md)

構文木・置換・継続をデータとして扱う。後半では、Bool列の検索と動的計画法を読む。

各節の検証例は実装時の記録。横断検証と証明の範囲は[検証ガイド](../VALIDATION.md)を参照。

## この章の内容

- [単一化とoccurs check](#unification)
- [Hindley–Milner型推論](#inference)
- [CEK評価機械](#cek)
- [正規表現の微分とNFA](#regex)
- [CYK構文解析](#cyk)
- [Aho–Corasick](#aho)
- [編集距離とLCS](#sequences)
- [0/1ナップサック](#knapsack)

<a id="unification"></a>

## 単一化とoccurs check

**入口:** [unify](../../src/unify)

`Term[S] = Variable(Nat) | Node(S, Chain[Term[S]])`。
変数と構成子の記号を別の型で表し、構成子のアルファベット自体もパラメータにした。
単一化では構成子を分解し、変数を束縛し、既存の置換の値域にも新しい束縛を反映する。
置換は外から構築できないので、非循環・冪等という不変条件を守れる。
既存置換に新しい等式を追加する `unify_into` も用意した。

変数が自分を含む項と結ばれると有限項では解を持たないため occurs check で拒否。
構成子名の不一致と引数数の不一致は別のエラーにする。
直接・間接の循環、置換の合成、44項からなる全1936組で、成功した置換が
等式を満たし、二度適用しても変わらないことを確認した。
このテストは最汎性の形式証明ではない。算法は分解・束縛による通常の一階単一化で、
高階単一化や rational tree の循環項は対象にしていない。

<a id="inference"></a>

## Hindley–Milner型推論

**入口:** [infer](../../src/infer)

一階単一化の構成子を Bool / 関数 / 積へ具体化し、置換と fresh 変数を明示的に渡す
Algorithm W の変形を実装した。入力は Reference/Lambda/Apply/Let/Boolean/Tuple/
First/Second/Conditional という AST。変数名も型変数も Nat なので、文字列や hash table は不要。

let の定義を推論したら、**現在の置換を反映した環境**に自由でない型変数だけを一般化する。
参照時には全称変数へ毎回新しい変数を割り当てる。
lambda の引数には全称変数を持たない scheme を入れ、勝手な多相利用を許さない。
最終結果は量化変数と本体を持つ Scheme。`canonical` が初出順に変数名を整えて比較を助ける。

恒等・定数・合成関数の主型、積と射影、let の異なる型での使用、shadowing を確認した。
一方、lambda 引数の多相使用、外側の変数に依存する let の不正な一般化、自己適用、
未定義名、条件分岐の型不一致は拒否する専用テストを置いた。
パーサ、再帰 let、高階多相、型クラス、効果・可変参照は対象外。
主型算法の実装であり、このコード全体の健全性・完全性を形式証明したという主張ではない。

原典：[Damas–Milner, Principal Type-Schemes for Functional Programs (1982)](https://www.cs.tufts.edu/comp/150FP/archive/robin-milner/damas-milner-original.pdf)。

<a id="cek"></a>

## CEK評価機械

**入口:** [cek](../../src/cek)

型推論と同じ AST を、call-by-value の CEK 抽象機械で評価する。
Control、字句的 Environment、Continuation の各要素が ADT。
関数は環境を捕捉する Closure、継続は Argument/Function/Binding/Pair/Project/Branch のリストで表す。
ホスト言語の評価の再帰へ丸投げせず、一回の遷移を `step` で取り出した。

`run(machine,fuel)` は全体で fuel 回までの遷移を行う。燃料は Nat。
終了の認識自体も一遷移として数える。ゼロ燃料なら現在状態をそのまま Suspended で返し、
次の run で正確に続けられる。Fault と無限計算の途中の Suspended を混同しない。
これは停止判定器ではなく、利用者が計算予算を渡せる実行器である。

字句スコープと shadowing、積・分岐、一遷移ずつの再開、各型エラーを検査した。
omega の自己適用は1000遷移で Suspended に戻る。
小さい式108個と、それを組み合わせた計972式について、型推論が受理した式は
十分な燃料で Fault なく終わり、結果の外形が推論型と一致することを確認した。
この有限試験を型安全性の一般証明と呼ぶことはしない。

<a id="regex"></a>

## 正規表現の微分とNFA

**入口:** [regex](../../src/regex)

Regex は空言語・空語・一記号・和・連接・Kleene star の ADT。
Brzozowski 微分は一記号を読んだ後の残りの言語を Regex として作り、
最後に nullable を調べる。空言語・空語の単位則と吸収則を smart constructor で簡約する。
文字列検索ではなく**語全体**とのマッチを実装する。アルファベットも型パラメータ。

別実装として Thompson NFA を構成した。状態番号は Nat、遷移は無音または一記号消費の ADT。
無音閉包は訪問集合で循環を止めるため、nullable な式の star でも停止する。
NFA 実行は微分のコードを使わない。

深さ2以下の構文を構成する全3244式、長さ0..4の全31二進語について両実装を照合。
既知の「末尾が true,false」言語、空言語、空語、nullable loop も確認した。
微分版には ACI 正規化やメモ化を入れていないため、長い入力では式が膨らみ得る。
NFA 版もリスト集合なので、通常のbitset実装と同じ実時間モデルではない。

原典：[Brzozowski (1964)](https://www.oilshell.org/archive/1964_JACM_Brzozowski.pdf)、
[Thompson (1968)](https://www.jmeiners.com/efficient-programming-with-components/papers/regular-expressions.pdf)。

<a id="cyk"></a>

## CYK構文解析

**入口:** [cyk](../../src/cyk)

文法規則を Terminal(A,token) と Binary(A,B,C)、構文木を Empty/Leaf/Branch で表す。
入力はChomsky標準形とし、空語を許す場合は開始記号が右辺に現れないことも入口で検査する。
任意文法から標準形への変換器や単位規則・任意位置のepsilon除去は実装していない。
区間長を増やしながら全分割位置を試し、各区間・非終端記号について一つの構文木を保持する。
左再帰や曖昧な文法でも、参照する区間長が真に小さいので再帰的文法の展開で発散しない。

構文木の検査器は使った規則と開始記号とyieldを確認し、chartは作らない。
yieldの再構成は末尾引数で走査し、部分木の文字列を何度も連結しない。
非終端2種類・終端Boolの全4096文法について、長さ0..3の全15語を、
メモ化を使わない別の再帰的導出判定と比較した（61440組）。
括弧列は長さ0..8の全511語でstack深さの整数検査と比較し、
曖昧な左再帰、重複規則、epsilon、偽の構文木、不正文法も確認した。

通常のCYKの区間・分割の数は立方オーダーだが、ここではchartや記号のlookupもリストで行う。
したがって、この実装全体が配列chart版のO(n³)実時間で動くという主張にはしない。
原論文：[Younger, Recognition and parsing of context-free languages in time n³](https://doi.org/10.1016/S0019-9958(67)80007-X)。

<a id="aho"></a>

## Aho–Corasick

**入口:** [aho](../../src/aho)

パターンの全prefixをtrieへ登録し、coreのFIFOで幅優先にfailureリンクと継承出力を作る。
遷移先がなければ、現在のprefixより真に短いfailure先へ進み、同じビットで再試行する。
一致した語の末尾に別の語も一致する場合は、failure先の出力もまとめて報告する。
同じ語に異なるラベルを付けられるが、ラベルの重複は拒否する。

Scannerはオートマトンの状態とNatの入力位置を保持する不変値。
feedしたチャンクの境界をまたぐ一致も保持し、空チャンクを挟んでも結果を重複させない。
空パターンは入力先頭を含む全境界に一致し、最初のfeedだけが先頭の空一致を報告する。
位置は[start,end)。同じendでは長い語から、同語なら入力ラベル順に返す。

長さ0..2の全7語から選ぶ全128辞書と、長さ3までの語を含む256辞書を用意し、
それぞれ長さ0..6の全127入力で全開始位置の素朴な照合と比較した（48768組）。
failureが短いsuffixであること、継承出力、重複語、空辞書、全チャンク分割位置も検査した。

ここでは状態IDをprefix自体で表し、trieのlookupと子prefixの連結も遷移に含まれる。
原論文の定数時間遷移表の線形時間保証を、この表現の実時間へそのまま当てはめない。
原論文：[Aho–Corasick 1975](https://doi.org/10.1145/360825.360855)。

<a id="sequences"></a>

## 編集距離とLCS

**入口:** [dp](../../src/dp)

格子を行ごとに走査する共通 `grid` を作った。
上・左・左上の値はリストのカーソルと引数で受け渡すため、添字を数える必要がない。
Levenshtein 距離は Nat、LCS は長さと逆順の証拠部分列、編集手順は cost と Edit の列をセルに置く。
Keep/Insert/Delete/Replace の各 Edit も ADT。`apply_script` は元の記号を照合し、壊れた手順を拒否する。

長さ0..5の全63二進語、全3969組について、距離を整数の配列 DP と比較。
編集手順を実行すると目的列になることと費用の最適性を検証した。
LCS は片側の全部分列を列挙する独立オラクルで長さを確かめ、双方の部分列であることも検査。
表のセル更新は O(mn) 回だが、単項 cost の比較や witness の保持のコストは別。
距離だけを求める版は二行ぶんの参照で進められる。証拠を返す版は共有する履歴も保持する。

<a id="knapsack"></a>

## 0/1ナップサック

**入口:** [dp](../../src/dp)

重みと容量を Nat、価値を Binary とする。各容量のセルに最適価値と選んだ添字列を保存する。
前の行の `capacity-weight` を毎回 nth で探すと、リスト表現では余分な線形走査になる。
そこで重みの個数だけずらした二本のカーソルを並走させ、一行を線形に構成した。
更新では必ず**前の行**だけを読むので、重みゼロの品物も一回だけ採用する。
同価値なら既存解を維持し、結果の添字は入力順に戻す。

6品物の40系列、容量0..12について全64部分集合を列挙したオラクルと比較。
最適値に加えて、添字の重複がないこと、容量制約、選んだ価値の合計を検証した。
表のセル数は O(品物数×容量) で、二進価値の演算と証拠の保持には別のコストがある。
