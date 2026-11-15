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

## 64bitまでの成立と計測

61bitの2305843009213693951と、64bitのGoldilocks素数18446744069414584321でも
候補の二進入力だけから生成できた。後者のn−1は `2^32*3*5*17*257*65537` だが、
この分解や子の証明を入力として渡していない。既定戦略で485遷移、rho26反復、
再帰全体のLucas候補14個を通り、完成後のcheckerで確定した。
両方を燃料20000以内で三backend検査し、大きいsemiprimeには再検査済み合成数witnessを返す。
screenなしの9では、すべてのLucas witnessが不成立でも `NoWitness(9)` の未確定とし、
合成数witnessを実装していない推論から `Composite` を作らないことも確認する。

2026-11-15、Intel Core Ultra 7 255H、x86_64、moonc v0.10.20、
`tools/moon bench src/primeprove --target native --release`。
初期Machineと燃料の構築を除外し、生成側は因数探索・全再帰証明・witness探索・
最終checkerを含む。再検査側はこの生成器が作ったcertificateを使う。
共有ホストの同時負荷やCPU周波数は固定していない。

| 候補 | bankなし生成（平均±標準偏差） | 生成後の再検査 | 既存の厳密試し割り |
| --- | --- | --- | --- |
| 65537 | 626.04 µs ± 26.56 µs | 145.65 µs ± 3.05 µs | 636.14 µs ± 17.16 µs |
| 998244353 | 8.76 ms ± 176.90 µs | 2.49 ms ± 95.75 µs | 234.55 ms ± 13.89 ms |
| Goldilocks 64bit | 166.12 ms ± 6.83 ms | 43.68 ms ± 1.53 ms | 未実施 |

65537では生成全体と試し割りが近い値となり、明瞭な改善とは扱わない。
998244353ではこのsmoothな前駆数に対して生成コスト込みでも小さくなった。
64bitの試し割りはこの実験では測定しておらず、速度比を主張しない。
これらは構造のよい候補での成立例であり、任意の64bit数を速く証明できる主張ではない。

```text
generate 65537: 626.04 µs ± 26.56 µs; 595.63 µs … 665.23 µs; 10 × 143 runs
recheck 65537: 145.65 µs ± 3.05 µs; 141.33 µs … 150.41 µs; 10 × 689 runs
trial 65537: 636.14 µs ± 17.16 µs; 618.72 µs … 674.00 µs; 10 × 153 runs
generate 998244353: 8.76 ms ± 176.90 µs; 8.51 ms … 9.09 ms; 10 × 12 runs
recheck 998244353: 2.49 ms ± 95.75 µs; 2.36 ms … 2.61 ms; 10 × 42 runs
trial 998244353: 234.55 ms ± 13.89 ms; 223.28 ms … 258.79 ms; 10 × 1 runs
generate Goldilocks: 166.12 ms ± 6.83 ms; 155.20 ms … 176.61 ms; 10 × 1 runs
recheck Goldilocks: 43.68 ms ± 1.53 ms; 41.92 ms … 46.73 ms; 10 × 3 runs
```
