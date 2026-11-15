# 2冪次数の円分体

`src/cyclotomic` は既存の `exact.Rational` と `polynomial.Polynomial`
から、2冪次数 `N` の `QQ(ζ_N)` を構成する。浮動小数点、近似根、組み込みの複素数を使わない。

## 正規形とAPI

`field(N)` は正の2冪だけを受理する。法多項式は次の通り。

| N | Φ_N(x) | 正規形 | generator |
| --- | --- | --- | --- |
| 1 | x − 1 | 有理定数 | 1 |
| 2 | x + 1 | 有理定数 | −1 |
| 4以上の2冪 | x^(N/2) + 1 | 次数N/2未満の有理係数多項式 | xの剰余類 |

`Field` と `Element` のコンストラクターは非公開。`element(field, polynomial)`
は既存の多項式除算で剰余化する。疎多項式の係数は既約有理数、項の順序と同類項も既存APIが正規化するため、
同じ体に属する元の構造的 `Eq` がそのまま厳密な等値判定になる。

- `rational`・`zero`・`one`・`generator`：元を構成する。
- `add`・`subtract`・`multiply`・`divide`：体の四則演算。
- `inverse`：法多項式との拡張Euclidにより逆元を得る。
- `power`：独自 `Binary` による非負整数冪。`0^0 = 1` とする。
- `conjugate`：`ζ_N` を `ζ_N^(N−1)` に置換し、有理係数を固定する。
- `representative`・`field_of`・`order`・`degree`・`defining_polynomial`：読み取り。

演算結果は `Result[..., CyclotomicError]`。異なる `Field` の混合を `FieldMismatch`、
ゼロ逆元を `ZeroDivisor` とする。多変数・0変数の多項式入力は既存の `DimensionMismatch` を包んで返す。
`InternalInvariant` は既存の単一除数による多項式除算が単一の商を返すという内部不変条件の防御的検査。
有効な公開コンストラクターから到達することは想定しない。

`N=1` と `N=2` はどちらも有理数体と同型だが、異なる根と法を持つ**別の提示**として扱う。
同じ有理数を埋め込んでもこの二つの `Field` の元は混合できない。
他の次数間の包含・自動昇格・埋め込みはまだ実装していない。

## 検証

2026-11-15、MoonBit v0.10.20で次を確認した。

```sh
python3 tools/audit_purity.py
tools/moon fmt --check src/cyclotomic
tools/moon check --deny-warn src/cyclotomic
tools/moon test src/cyclotomic --target wasm-gc
tools/moon test src/cyclotomic --target js
tools/moon test src/cyclotomic --target native
tools/moon info src/cyclotomic
```

各バックエンドで10テストが通る。確認範囲は以下。

- 0から33の次数に対する受理・拒否、`N=1/2` の特例、混合・ゼロ除算・次元不一致。
- `N=1,2,4,8,16,32` の生成元の厳密な位数、法多項式がゼロになること、高次数単項式の正規形。
- `N=4` の2係数を `−1,0,1` とした全81組の積を独立したGaussian有理数の組演算と比較。
- Python標準の `fractions.Fraction` と密な係数配列で生成した20組の積・逆元・共役。
  逆元のオラクルは有理数の乗算行列をGauss–Jordanで解くため、核の拡張Euclidとは算法が異なる。
- 分配則・除算の往復・共役の加法性と乗法性・共役の二重適用。

fixtureの再生成は次で行う。

```sh
python3 tools/generate_cyclotomic.py
tools/moon fmt src/cyclotomic src/exactfft
```

生成器は固定seed `20261115`、追加依存なし。fixtureを検証済みの有限例として扱い、
すべての入力に対する形式証明や性能向上を主張しない。
疎多項式の汎用除算とPeano指数を使うので、大きな次数への高速な数値FFTの代替は目的としていない。

## 厳密FFTと逆変換

`src/exactfft` の `plan(field, N)` は、体の次数 `M` に対して `N` が正の2冪であり
`M` を割り切る場合だけ成功する。根は `ω = ζ_M^(M/N)`。したがって、変換長より大きい円分体の
任意の元も入力にできる。`size`・`field_of`・`root` で計画の意味を確認できる。

規約は次の通り。インデックスは `0` から `N−1`。

```text
transform(x)[k] = Σ_j x[j] ω^(j k)
inverse(y)[j]   = (1/N) Σ_k y[k] ω^(−j k)
```

`transform` は偶数位置・奇数位置へ再帰し、`E + ω^k O` と `E − ω^k O` を連結する。
`inverse` は根の共役を使って同じ算法を呼び、有理数 `1/N` を厳密に掛ける。
`dft` は再帰分割を使わず、各binを入力全体から順に加算する独立な二次時間の仕様。
3関数とも計画と異なる長さを `LengthMismatch`、他の体の元を `FieldMismatch` として拒否する。
内部の体演算エラーを消さずに `Arithmetic` に包む。

例えば `QQ(i)` で `[1,2,3,4]` を変換すると、近似を介さず
`[10, −2−2i, −2, −2+2i]` になる。逆変換は元の整数列に戻る。
`N=1` は1元の恒等変換、`N=2` は根 `−1` による和と差であり、同じAPIで扱う。

## 既存の12等式との意味対応

従来の `fft.Arrow` は長さ `k` の `Unit` リスト、`fft.Number` は矢印の形式和。
`interpret_arrow(field, arrow)` を `ζ_M^k`、`interpret_number` をその和、
`interpret_signal` を成分ごとの解釈と定義した。
この解釈では、形式和に残っている一周分や逆向きの矢印が正規化によって厳密に相殺される。

変換長 `N` に対し、従来の `fft.fft(w, xs)` のstep `w` を長さ `M/N` の矢印にする。
すると各段の形式的な回転が `ω = ζ_M^(M/N)` の乗算に対応する。
`M=N` の場合は長さ1の矢印でよい。次の可換性を有限例で確認した。

```text
interpret_signal(field, fft.fft(w, xs))
  = exactfft.transform(plan(field, N), interpret_signal(field, xs))
```

従来の `fft.dft` についても同じ対応を確認している。従来の形式和の並びが異なっても、
円分体の正規形として厳密に比較するため、浮動小数点の誤差閾値は存在しない。
任意の別のstepに対する自動的な根の選択は行わない。

## FFTの検証と次の候補

以下を実行し、Wasm GC・JavaScript・nativeの各バックエンドで15テストが通った。
円分体の10テストと合わせて25テスト。

```sh
tools/moon fmt --check src/cyclotomic src/exactfft
tools/moon check --deny-warn src/cyclotomic src/exactfft
tools/moon test src/exactfft --target wasm-gc
tools/moon test src/exactfft --target js
tools/moon test src/exactfft --target native
tools/moon info src/cyclotomic src/exactfft
```

- 計画の受理・拒否、空・長さ不一致・他の体の混入。
- 明示的な4点DFTと、長さ1/2/4の全binary信号。
- 長さ1/2/4/8/16の円分体入力30組で直接DFT一致と両向きの厳密往復。
- Python `Fraction` で、係数配列を直接回転・加算するDFTオラクル8組。
  `M=16,N=8` のような拡大体内の変換、`N=1` の非有理入力も含む。
- 矢印FFT/DFTとの対応を7種類の `(M,N)`、各4入力で確認。加法と回転の解釈、逆位相の相殺も確認。

次の候補は、`Φ_N = (x^N−1) / ∏_{d|N,d<N} Φ_d` の厳密多項式除算による一般次数への拡張、
異なる次数間の明示的な埋め込み、`ζ_N + ζ_N^(−1)` を生成元とする実部分体。
一般次数ではFFTも2冪の変換長だけが現状の対象になる。
ここではそれらの実装・一般性能・形式証明は主張しない。
