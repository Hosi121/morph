# GF(2)を含む一般の素数体

`src/primefield` は、標数2と奇素数の両方を同じ `Field` 境界で受け取る。
フィールドを外部から構築できず、法は必ず1より大きい素数である。
既存の奇素数用Tonelli–Shanksとは独立し、多項式などがGF(2)の算術を要求する入口に使う。

```moonbit
pub fn field(@binary.Binary) -> Field?
pub fn from_prime(@primality.Prime) -> Field?
pub fn modulus(Field) -> @modular.Modulus
pub fn arithmetic(Field) -> @rowreduce.Field[@binary.Binary]
```

`field` は既存の厳密な試し割りで検査する。`from_prime` はすでに検査を通った
opaqueな `Prime` を要求し、試し割りを繰り返さず法を構築する。
算術recordは既存の剰余加減乗算・拡張Euclidによる逆元を使い、各結果は正規剰余になる。
逆元がないのは入力の剰余が0の場合だけで、法の倍数などの未正規入力も扱う。

0〜127の候補を独立した整数試し割りと比較する。
GF(2)、GF(3)、GF(5)では入力0〜15のすべての加減乗算・符号反転・逆元を整数と照合し、
証明からの入口と試し割り入口の同値も確認する。
GF(2)上の小行列で汎用Gauss–Jordanの逆行列・行列式・方程式も確認する。
純記号ゲートの対象であり、実用暗号の安全性や定数時間性は主張しない。

## 構築コストの同条件比較

2026-11-15、Intel Core Ultra 7 255H、x86_64、moonc v0.10.20、
`tools/moon bench src/primefield --target native --release`。
二進入力と証明木の構築を除外し、既存試し割り、検査済みPrimeからの変換、
Lucas証明検査を含む入口の三つを比較する。証明の発見コストは含まない。
共有ホストの同時負荷や周波数は固定していない。

| 法 | 厳密試し割りからfield | 検査済みPrimeから変換だけ | Lucas検査とfrom_prime |
| --- | --- | --- | --- |
| 65537 | 679.05 µs ± 31.71 µs | 23.35 ns ± 2.52 ns | 142.46 µs ± 4.44 µs |
| 998244353 | 235.96 ms ± 4.82 ms | 23.20 ns ± 0.67 ns | 2.36 ms ± 60.18 µs |

`from_prime` だけの値は素数判定の時間ではなく、すでに検査した証拠を利用する変換の時間。
証明を受け取って厳密に体を作る場合の比較対象は右列である。
65537の両入口の同値と、998244353の証明経由の法も通常テストで検査する。

```text
trial 65537: 679.05 µs ± 31.71 µs; 644.36 µs … 740.04 µs; 10 × 148 runs
from checked Prime 65537: 23.35 ns ± 2.52 ns; 21.75 ns … 28.87 ns; 10 × 100000 runs
Lucas plus conversion 65537: 142.46 µs ± 4.44 µs; 136.52 µs … 149.80 µs; 10 × 678 runs
trial 998244353: 235.96 ms ± 4.82 ms; 230.06 ms … 244.04 ms; 10 × 1 runs
from checked Prime 998244353: 23.20 ns ± 0.67 ns; 22.50 ns … 24.41 ns; 10 × 100000 runs
Lucas plus conversion 998244353: 2.36 ms ± 60.18 µs; 2.28 ms … 2.43 ms; 10 × 43 runs
```
