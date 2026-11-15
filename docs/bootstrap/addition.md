# リスト末尾の共有を加算へ広げる

二進加算で片方のリストを読み終え、carryもない場合、残りはそのまま結果の末尾になる。
旧版は全てを再コピーしていた。carryがあればincrementと同じ関数を共有し、
最初のfalseまでだけ更新する。正規化された非負整数という不変条件は維持する。

native release、同じ入力、入力構築除外、10標本の平均：

| 入力 | 旧版 | suffix共有 |
| --- | ---: | ---: |
| 2048bit + 0 | 21.98 µs | 14.41 ns |
| 2048bit + 5 | 21.92 µs | 31.52 ns |
| 下位2048bit全1 + 1 | 22.42 µs | 19.60 µs |
| 同じ幅のdense 512bit | 5.51 µs | 6.02 µs |
| 2048bit学校式乗算 | 47.22 ms | 35.12 ms |
| 2048bit Karatsuba | 14.50 ms | 10.63 ms |

同じ幅のdense加算は改善せず、この計測では約9%悪化した。
全用途で速いとは主張せず、不要な全suffix複製を省ける場合と上位乗算の改善で採用する。
他agentも動作していてCPU固定はない。マイクロ例のns級の倍率を上位全体へ外挿しない。
生ログは`docs/measurements/{addition,multiply}-bootstrap-{before,after}.txt`。
関数分岐順を調整した中間候補も`addition-bootstrap-candidate.txt`に残した。

## carry-mux式は今回は見送り

SAT miterと真理値で等価性を調べたparity/carry-mux式を、Boolの直接matchへ移して試した。
しかしdense512bit加算6.61µs、Karatsuba2048bit12.31msと、直前の採用候補より遅くなった。
そのため算術の`full_adder`は従来の全真理値matchを維持する。
`boolean`/`circuit`では比較と検証のため両方の式を残す。
gate数やBoolean式の短さは、MoonBitバックエンドでの実時間の代わりにならない。
見送りの生ログ：`{addition,multiply}-bootstrap-mux.txt`。

0〜255の全加算、32〜2048bitの独立したbit列期待値、全carryを検査した。
この基礎変更を含めてWasm GC/JS全281テストが通過した。
