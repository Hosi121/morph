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
tools/moon fmt src/recurrence src/cyclicrs
```

追加のPython依存はない。有限の全小例と独立算法による比較であり、形式証明ではない。
再帰・不変リスト・汎用体演算を使う記号算法で、機械数値BMへの速度優位は主張しない。

## エラーを保つ体操作

`CheckedField[A,E]` と `checked_berlekamp_massey`・`checked_check` を追加した。
各操作は `Result`、逆元は `Result[Option[A],E]` を返す。
`Ok(None)` だけをゼロと解釈し、算術エラー `Err` をゼロとして握りつぶさない。
例えば異なるGalois体の混合は、BMのdiscrepancyゼロにならず `CheckedError::Arithmetic` として返る。
通常の `rowreduce.Field[A]` を受ける最初のAPIは維持する。

## 狭義巡回Reed–Solomon

`src/cyclicrs` は `galois` 上の係数を使う、狭義巡回RSとそのzero-shortening。
`plan(field, alpha, order, length, errors)` は、次を検査する。

- αが指定した体の非ゼロ元であること。
- 主張された位数rについて、`α^r=1`、`α^j!=1` for `1<=j<r`。
  小さい冪をすべて訪問するので、位数の素因数分解や未検査の原始元を信用しない。
- `2t<n<=r<=q−1`。ここで `q=cardinality(field)`、`t=errors`、`n=length`。
  `t=0` も恒等的な境界として受理する。メッセージ長は常に正。

`n=r` が巡回符号。`n<r` は次数n以上の母符号係数をゼロに固定したshorteningであり、
長さnのまま巡回性があるという主張はしない。
位数rはq−1の真の約数でもよく、GF(16)内の位数5の元の例も確認した。

係数列は**昇冪順**。生成多項式とsystematic encodeは次の規約。

```text
g(z) = ∏_{j=1}^{2t} (z − α^j)
c(z) = z^(2t) m(z) − (z^(2t) m(z) mod g(z))
word = [低位のparity 2t個, メッセージ n−2t個]
```

先頭・末尾のゼロも固定長で保持する。`syndrome` は `S_j=r(α^j)`、`j=1,...,2t` を返す。
符号語ならすべてゼロになる。
`generator_polynomial`、`length`、`message_size`、`radius`、`root`、`root_order`、`field_of` で計画を読める。

## BM → Chien → Forney の規約と導出

受信多項式を `r(z)=c(z)+Σ_i e_i z^i` とし、位置iのlocatorを `X_i=α^i` とする。
ここでは誤り値を **受信値 − 正しい値** と定義する。

```text
S_j = Σ_i e_i X_i^j,                   j=1,...,2t
S(z) = S_1 + S_2 z + ... + S_(2t) z^(2t−1)
Λ(z) = ∏_i (1 − X_i z)
Ω(z) = (S(z) Λ(z)) mod z^(2t)
```

BMには `[S_1,...,S_(2t)]` を渡す。半径内なら出力接続多項式がΛになる。
Chien検索は実際に受信した位置 `i=0,...,n−1` だけを走査し、`Λ(X_i^−1)=0` を探す。

syndromeの無限形式級数は `Σ_i e_i X_i/(1−X_i z)`。
したがって半径内でΛを掛けると、次数が誤り数未満の多項式になり、2t項の切断からΩを復元できる。
`z_i=X_i^−1` において、

```text
Ω(z_i)  =  e_i X_i ∏_{h!=i} (1 − X_h/X_i)
Λ'(z_i) =     −X_i ∏_{h!=i} (1 − X_h/X_i)
e_i     = −Ω(z_i) / Λ'(z_i)
```

これがb=1のForney式。**追加のX_i係数は掛けない**。
標数2ではマイナスが見えなくなるため、GF(9)とGF(7)でも誤り値を網羅して符号を確認した。
訂正は `received[i] − e_i`。

復号器は、BM長がt以下、接続多項式の実次数がBM長と一致、位置根の個数がBM長と一致、
Forney分母が非ゼロ、誤り値が非ゼロであることを検査する。
最後に訂正した全語のsyndromeを再計算し、すべてゼロのときだけ成功する。
不整合は `Uncorrectable`。長さ・体の混合・算術エラーは別のエラーを保つ。

`Decoded` はmessage、corrected、error_positions、error_valuesを持つ公開record。
`check(plan, received, decoded)` はBM・Chien・Forneyを呼ばず、systematic messageの再encode、
実際に異なる位置と誤り値、距離がt以下であることを検査する。
改変したメタデータや別の体の値は拒否する。

## 訂正半径の外側

t個以下の非ゼロ誤りなら送信語へ戻す。半径を超えた場合、失敗するか別の近い符号語へ成功する場合がある。
成功やsyndromeゼロを、任意個の誤りから元のmessageを復元した保証と解釈しない。

例としてGF(4)の長さ3・半径1の反復符号で `[0,0,0]` を送り、2箇所が壊れて `[1,1,0]` になった場合、
受信語の半径1近傍は `[1,1,1]`。復号器と結果checkerはこの別の符号語を正当に受理する。
この例も明示テストに置いた。

## 巡回符号の独立検証

追加後はrecurrence 17テスト、cyclicrs 21テスト、合計38テストを3バックエンドで確認した。

```sh
python3 tools/generate_cyclicrs.py
tools/moon fmt src/recurrence src/cyclicrs
python3 tools/audit_purity.py
tools/moon check --deny-warn src/recurrence src/cyclicrs
tools/moon test src/recurrence src/cyclicrs --target wasm-gc
tools/moon test src/recurrence src/cyclicrs --target js
tools/moon test src/recurrence src/cyclicrs --target native
tools/moon info src/recurrence src/cyclicrs
```

- GF(4)の全64受信語を独立な最近傍探索と比較。半径内40語・どの半径1近傍にもない24語を含む。
- GF(16)、長さ15、半径2：全225の1誤り、全105の2誤り位置に4種類の誤り値組を適用。
- GF(9)、長さ8、半径2：全64の1誤り、全28の2誤り位置×全64の非ゼロ誤り値組を検査。
- GF(256)、長さ255、半径2：全255位置の1誤りで全255非ゼロ誤り値も一度ずつ使い、
  32系列の2誤りも検査。先頭・末尾・分散した位置を含む。
- 独立なnativeオラクルは、標数2では機械整数のcarryless shift/XOR、
  奇標数では係数配列の畳み込みを使って体演算し、多項式長除算とsyndromeを直接計算する。
- GF(7)の全長・半径1の36例で、既存のBerlekamp–Welch復号と照合。
  全非ゼロ部分群点 `X_i=α^i` の場合、cyclic係数語のn倍が次数k未満の評価語になることを使う。
  従来のBWと新しいBM→Chien→Forneyは異なる算法で、双方の結果checkerも通す。
- Pythonのnativeオラクル13組で、codeword・syndrome・Λ・Ω・Forney値を比較。
  GF(16)/GF(256)のshortening、GF(9)の奇標数、最初のsyndromeがゼロになる誤り組を含む。
- t=0、位数がq−1未満、位数の偽装、空・長さ違い・foreign field、改変decodedを検査。

消失訂正・soft decision・list decodingは含めない。
位数検査はO(r)の訪問、GF(p^m)演算は有理式のない汎用多項式核を使う。
GF(256)の機械語テーブル実装への速度優位や、標準化された通信方式とのバイト互換性は主張しない。
ここで検証した符号規約と有限テストが成果物であり、形式検証済み通信実装ではない。
