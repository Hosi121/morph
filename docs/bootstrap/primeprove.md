# certificate bankなしで生成するLucas証明

`src/primeprove` は、外部で列挙した素数証明を一つも受け取らず、候補nから
既存 `@primality.Certificate` を構築する。完成時には既存checkerを再実行し、
元のnと一致する `Prime` とcertificateをopaqueな `Proof` にまとめて返す。

```moonbit
pub fn defaults() -> Config
pub fn start(@binary.Binary, Config) -> Machine?
pub fn step(Machine) -> Status
pub fn run(Machine, @core.Nat) -> Status
pub fn certificate(Proof) -> @primality.Certificate
pub fn prime(Proof) -> @primality.Prime
pub(all) enum Status {
  Proven(Proof)
  Composite(@primality.CompositeProof)
  Suspended(Machine)
  Inconclusive(Uncertainty, Machine)
}
```

入力はn>=2に限る。`Config` は小さな試し割りの上限、強い合成数screenのbase列、
有限のrho `(seed,c)` 列だけを持つ。既定値は試し割り2〜16、base 2/3/5/7、
rhoの `(2,1)/(2,2)/(2,3)`。すべての処理は純記号のBinary/Chain/ADT/再帰で行う。

## 証明の生成と検査の分離

候補が2なら `Two` を使う。それ以外で合成数witnessが見つかれば、そのwitnessだけを返す。
screenを通過しても素数とはせず、n−1を分割し、すべての因子を同じ処理で再帰的に証明する。
小さい因子は試し割りで探し、強いscreenで合成数と分かった未分割因子には
既存のPollard rhoを使う。非自明因子は既存 `check_factor` でも検査する。
screenが直接返した非自明因子2も再利用する。

全因子が証明できたら、witnessを2からn−1まで順に試してLucasの木を作る。
各候補木を既存の `@primality.check` に渡し、通った木だけを採用する。
再帰した因子を戻す境界と、rootを返す境界でも再検査する。
根拠は [HAC Fact 4.38](https://cacr.uwaterloo.ca/hac/about/chap4.pdf) の完全分解と位数条件、
因数探索は [HAC Algorithm 3.9](https://cacr.uwaterloo.ca/hac/about/chap3.pdf) のrhoである。
外部oracleやPythonはこの生成経路にもcheckerにも関与しない。

## 燃料・再開・未確定

再帰の継続、分割済みの因子証明、試し割りの候補、screenの残base、
rhoの途中状態、witnessの位置をすべて不変のMachineに持つ。
燃料1は状態遷移1回で、試し割りの候補1個、強いbase1個、rho1反復、
Lucas witness1個、または継続の出し入れを行う。
Lucas検査などの内部演算数、ビット操作、メモリ、実時間を燃料1で固定しない。

`Suspended` は単に燃料切れで、同じMachineに追加の燃料を与えると正確に続行する。
燃料0では一切進めない。`Inconclusive` は有限seedが尽きた因子 `NoFactor(n)`、
全witnessが不成立だった `NoWitness(n)`、または防御的な不変条件エラーを示す。
この状態に燃料だけを足しても変わらない。
`restart(machine,new_config)` は元の候補を新しい戦略で最初からやり直す。
これは燃料による継続とは区別し、先の部分証明は再利用しない。

`Composite` はrootの数について独立に再検査した合成数witnessがある場合だけ返す。
証明できない候補、全baseを通過した候補、rhoに失敗した候補をPrimeへ昇格しない。
例えば強い擬素数2047をbase2だけでscreenしても、Lucas証明がない限り `Proven` にならない。
因数分解やwitnessが難しい一般の候補で、指定燃料内の成功を保証しない。

## 最初の成立確認

0と1の入力拒否、2〜127を独立した整数の全試し割りと比較し、素数には生成した証明、
合成数には再検査したwitnessを返すことを確認する。
257、65537、998244353のsmoothなn−1から、手書きbankなしで完全な証明木を生成する。
燃料0・1ステップ分割・一括実行の同一性、退化したrho seedでの未確定と戦略変更、
試し割りを無効にしてrhoで31の前駆数を分割する例も検査する。
通常テストは外部のcertificate fixtureを使わず、その場で核の生成器を動かす。
