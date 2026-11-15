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
