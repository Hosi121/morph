# SATでNAND回路を合成する

`synthesis`は真理値表から、指定個数以下の二入力NANDだけで作る回路を探す。
これまで実装したSATを検証だけでなくプログラムの構成にも使う最初の単位である。
設計の背景は[Haaswijkら, Classifying Functions with Exact Synthesis](https://msoeken.github.io/papers/2017_ismvl.pdf)。
ここでは論文の実験規模を再現せず、小さなNANDライブラリを独自に符号化した。

各slotは入力または以前のslotから二本を選ぶ。NANDの交換対称性で順序を一方に限定し、
同じwireを二度使うNOTも認める。各選択をone-hot変数で表し、全入力行に対して
`selector ⇒ output = NAND(left,right)`をCNFへ直接展開する。
最後に出力wireをone-hotで選び、真理値表の各行と一致させる。
未使用slotを許すため、入力がある問題では「高々指定個数」の探索になる。
定数wireは無料ではなく、ゼロ入力では作れる回路がない。

公開APIは`table`→`problem`→`start`/`run`。
燃料切れは`Paused`から再開でき、`Found`の回路は元の全真理値表を直接評価してから返す。
`Impossible`のRUP証拠も探索から独立したcheckerを通してから返す。
低水準の`cnf`/`decode`/`check_impossibility`も公開し、外側でsolverを選べる。
Networkのconstructorは前方参照・循環・入力範囲外・不正な出力を拒否する。
真理値表の入力順は辞書順で、最初の入力が最もゆっくり変わる。

初期成果はXORの4-NAND回路と、3個以下では不可能という検査済み証拠。
2入力の全16関数を0〜5個の各上限で調べ、CNFを使わずnativeで全NANDプログラムを
列挙する別oracleと一致させる。偽の空RUP、別の上限の証拠、不完全modelも拒否する。
これは符号化器の全入力の形式証明ではない。個別問題のUNSAT証拠を受理するcheckerと、
問題→CNFの符号化の正しさは別の信頼境界である。

gate数が減っても、MoonBitの実時間が減るとは限らない。
合成した式を基礎演算へ戻す際は、同じ値を計算する実装を別途計測して採否を決める。
全真理値表には入力数に対し指数的なコストがあり、大きな関数には分解や反例誘導が必要。
