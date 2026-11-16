# 厳密整数の差分制約からSMTへ

[ドキュメント](../README.md) / [探索・改善記録](README.md)

SATが返すBool割当てに、整数の意味を戻すための最初の単位が`difference`。
`Constraint{left,right,bound}`は`x_left−x_right<=bound`を表し、変数Zeroは定数0とする。
整数は既存`exact.Integer`、IDはNatを入口にBinaryへcacheし、不変AVLを使う。
固定幅へのbit-blastや浮動小数点は導入しない。

この制約は[SMT-LIBのQF_IDL](https://smt-lib.org/logics-all.shtml#QF_IDL)の差分原子の一種。
ここで扱うのは独自ADTで、SMT-LIB全構文のparserではない。
手法の資料：[Aaltoの差分理論solver講義](https://users.aalto.fi/~tjunttil/2020-DP-AUT/notes-smt/diff_solver.html)。

## Bellman–Fordと二種類の証拠

`x−y<=c`を辺`y→x`（重みc）へ変換する。
全変数へ重み0の仮想rootを置く代わりに、距離を全て0から始める。
Bellman–Fordで緩和し、固定点なら距離を整数モデルとして返す。
原点の距離を全成分から引くと、差を保ったままZeroを0に固定できる。

`Feasible`を返す前に、探索と別のcheckerで全変数の一意性・原点・元の不等式を検査する。
負閉路があれば元の制約index列を返す。
`check_cycle`は距離やpredecessorを受け取らず、辺が閉じて重み和が負になることだけを検査する。
不等式を足すと左辺が0になり、負の右辺との矛盾が直接得られる。
実装上の証拠抽出に失敗したら、UNSATへ昇格せず`InvariantViolation`を返す。

整数の否定は`not(x−y<=c)`を`y−x<=−c−1`へ変換する。
有理数や実数へこの規則をそのまま使うことはできない。
この正確な補集合が次のBool abstractionの足場になる。

3変数の全27原子から0〜3個を選ぶ20,440例、生成した600グラフを、
native符号付き整数による別のFloyd–Warshallと照合した。
返されたモデルと負閉路もnative値で再評価する。
偽のindex/非閉路/非負閉路、重複・欠落・余分な変数・原点のずれを拒否する回帰を置く。
65535/8191の疎ID、256bitの厳密な境界も検査した。
4テストがWasm GC/JS/nativeで通過。これは有限検査で、Bellman–Ford実装の形式証明ではない。

```sh
tools/moon test src/difference --target native
```

## Boolと整数を往復するlazy SMT

`smt`は`Atom = Difference(Constraint) | Free`のリストと、そのindexを使うCNFを受け取る。
CDCLがBoolモデルを返したら、正の差分原子は元の不等式、負の原子は厳密な整数の補集合へ戻す。
Freeは整数条件を課さず、Boolの補助変数として使える。
Boolモデルが部分的な場合は残りをfalseで補完し、その全割当てに対して理論を検査する。

負閉路があれば、その辺の符号付き原子だけから`not p1 or ... or not pk`を作る。
各辺を足すと矛盾するため、このclauseは理論的に妥当である。
clauseを足したCNFでCDCLを再起動し、次のBool割当てを探す。
整数モデルが見つかったら、元のCNFと全原子の真偽を別のcheckerで検査して返す。

UNSATの証拠は負閉路lemma列と最後のRUP証拠からなる。
`check_refutation`は探索を呼ばず、各lemmaの辺・向き・負の和を検査した後で
拡張CNFに対するRUPを検査する。
例えば`x<=0`と`x>=1`を同時に真にするBool単位節はSATだが、
整数の二辺の重み和は−1になり、SMTでは検査可能なUNSATとなる。
ちょうど補集合の二原子に同じ真偽を要求した例では、両方true/両方falseの二モデルを排除できる。

`start`/`step`/`run`は再開可能。燃料一単位はCDCL一遷移、または理論全体の一回の検査であり、
処理時間やBool操作の一定量を意味しない。
現版は理論lemmaを残してCDCLを再起動する素朴なlazy方式で、
部分割当て中の理論伝播やBoolean学習の再利用は実装していない。
一般の線形整数算術や乗算を扱うsolverでもない。

2原子の全小CNF6,517例、3整数変数の生成500例を、
グラフやSATを使わないnative整数値・Free Boolの全列挙と照合した。
小例の整数値域は−4〜4で、3変数・重み±1の差分制約に必要なpotential範囲を覆う。
Freeを挟んだindex、未出現原子の補完、理論lemmaの欠落・別問題への流用、
非負のwalk・不正ID・不完全な整数モデル、燃料分割を検査した。
5テストがnative/JS/Wasm GCで通過。符号化・理論checker全体の形式証明は行っていない。

```sh
tools/moon test src/smt --target native
```
