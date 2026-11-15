# Berlekamp–Massey と巡回符号

## 汎用体上の最小漸化式

`src/recurrence` は `rowreduce.Field[A]` を使うBerlekamp–Massey。
有理数・標数2を含む素数体など、同じ操作辞書を渡して利用できる。
操作辞書は、可換体の法則、正規化したゼロ、`inverse(value)=None` とゼロの同値を前提とする。
既存rowreduceと同じく、このrecord自身は体の法則の形式的な証明ではない。

`berlekamp_massey(field, input)` は次の公開recordを返す。

```text
Recurrence { length: L, connection: [1,c1,...,cL] }
s[n] + c1*s[n−1] + ... + cL*s[n−L] = 0,  L <= n < input.length
```

`L` は**与えられた有限prefixに対する最小長**。
例えば `[1,0]` には `L=1, connection=[1,0]` が対応する。
接続多項式の末尾ゼロを除去して次数を0と見なすと、最初の非ゼロを説明できないため誤る。
そのため接続列は常に長さ `L+1` とし、末尾ゼロを保持する。
空列・全ゼロ列の最小長は0、接続列は `[1]`。

`check(field, input, recurrence)` は公開recordを信用せず、長さ・定数項1・`L<=input.length` を検査し、
固定長の前向きwindowへ直接再代入する。
生産者の逆順history・discrepancy更新・バックアップ多項式を使わない。
これは**漸化式の成立を検査するchecker**であり、一般の入力に対する最小性の証明器ではない。
例えば全ゼロ列に対する非最小な有効漸化式も受理する。

`predict` は古い順から新しい順のちょうどL個の履歴を受け、次項を返す。
観測済みの有限prefixだけから、実世界の未知の次項まで保証するものではない。
形が不正、履歴長が不一致の場合は `None`。
Berlekamp–Masseyも、単位元の逆元がない辞書や内部の形の不一致では `None` を返す。

## 最初の完成単位の検証

2026-11-15、MoonBit v0.10.20で16テストがWasm GC・JS・nativeすべて成功。

```sh
python3 tools/audit_purity.py
tools/moon fmt --check src/recurrence
tools/moon check --deny-warn src/recurrence
tools/moon test src/recurrence --target wasm-gc
tools/moon test src/recurrence --target js
tools/moon test src/recurrence --target native
tools/moon info src/recurrence
```

- `GF(2)` の長さ0〜8、`GF(3)` の長さ0〜6、`GF(5)` の長さ0〜4の全列、合計2,385列。
  各候補長について機械整数の線形方程式をGauss消去し、最初に整合する長さを独立オラクルとした。
- 出力係数を機械整数で再代入し、既存windowの予測も比較した。
- Python `Fraction` の線形方程式オラクル12組。有理数の混合、幾何列の和、多項式列、
  任意の短列、先頭/末尾ゼロを含む。
- Fibonacciの `[1,−1,−1]` と二次多項式列の `[1,−3,3,−1]` を明示的に比較。
- 不正な定数項・列長・漸化式・長すぎるLをcheckerが拒否すること、最小性を検査したと誤解しない例。

fixture再生成：

```sh
python3 tools/generate_cyclicrs.py
tools/moon fmt src/recurrence
```

追加のPython依存はない。有限の全小例と独立算法による比較であり、形式証明ではない。
再帰・不変リスト・汎用体演算を使う記号算法で、機械数値BMへの速度優位は主張しない。
