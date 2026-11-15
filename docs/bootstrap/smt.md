# 厳密整数の差分制約からSMTへ

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
