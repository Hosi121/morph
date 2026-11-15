# Nat変換をSATへ戻す

独立レビューの単一unit節（変数番号65535）は、旧`Binary.from_nat`の
`successor(from_nat(rest))`でJS/Wasm GCのstackを使い切った。
同時にSAT準備時間のprofileでも、この変換が支配していた。

`from_nat`はBinary accumulatorを持つ末尾再帰へ変更した。
`successor`も一般加算ではなくcarryを直接伝播し、最初のfalseより上のsuffixを共有する。
これにより連続するincrementの全bit複製を避ける。最悪の全1bit列では全carryが必要である。
表現、公開API、計算する自然数は変更しない。

| 同一入力・native release | 変更前 | 変更後 |
| --- | ---: | ---: |
| Nat 4096 → Binary | 811.69 µs | 80.91 µs |
| 偶数2048bitのincrement | 21.70 µs | 13.21 ns |
| 下位2048bitが全1のincrement | 21.94 µs | 20.27 µs |

入力構築を除外した`tools/moon bench src/benchmarks/natural_test.mbt --target native`の
10標本平均。CPU固定はしておらず、他agentの負荷もあるため精密な倍率比較ではない。
偶数例の大幅な差はsuffix共有が直接効くmicrobenchmarkで、SAT全体の倍率ではない。
生ログは`docs/measurements/natural-bootstrap-{before,after}.txt`。

0〜4096の整数oracle、100000までの大きなNatの往復、1024bitまでのcarry境界を検査した。
65535のSAT回帰を含めてJS/Wasm GCの全248テスト、独立レビュー7テストnativeが通過した。
これは有限例の結果で、全入力の帰納的形式証明ではない。
Peanoの値に比例する読取りは残るため、二進IDを直接受け取る上位APIや構造的半分化は
別の比較候補として扱う。

## 構造的半分化を共通APIへ戻す

CDCL担当のprivateな二進ID変換では、Succを二個ずつ読み、商のNatと余りのBoolへ
分ける案が、改善済みincrement版より同一入力で速かった。
同じ構成を`Binary.from_nat`へ戻した。各levelの走査量はおよそn, n/2, n/4,...で、
値に対して線形、非末尾再帰の深さはbit数に比例する。
increment版の81µsから20.58±0.71µsへ改善した（同じ4096、native release、10標本）。
初期811.69µsと比べるだけでなく、直前の採用版も比較対象として残す。
生ログ：`docs/measurements/natural-bootstrap-halving.txt`。

新APIや数値primitiveは追加していない。0〜4096と100000までの境界回帰を維持し、
CDCL側の重複private converterは次の共通化対象とする。
