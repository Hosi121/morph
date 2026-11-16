# Prime-field Reed–Solomon の Guruswami–Sudan リスト復号（2026-11-16）

[研究記録](README.md) / [生成 API](../../src/listdecode/pkg.generated.mbti)

今回の問いは、Hasse 多重度の二変数補間と Roth–Ruckenstein（RR）の根探索を純記号表現で合成し、一意訂正半径を超えた**候補集合全体**を求められるか。実装は [src/listdecode](../../src/listdecode/types.mbt)。既存の `primefield`、`rowreduce.solve`、`fppoly` を利用し、本体には機械数値、配列、mutation、FFI、全メッセージ列挙を使わない。先行する BCH の実装・記録は凍結したまま追加した。

## 入口と次数の規約

`plan(field, alphabet, points, k, A, s, D)` は以下を要求する。

- `field` は既存の検査済み `primefield.Field`。係数は `[0,p)` の正規形 `Binary`。体の拡大や任意の field dictionary は入口にしない。
- `alphabet` は全 p 個の正規形剰余を重複なく含む明示列。順序は任意だが、省略や部分集合は拒否する。RR の根探索はこの列を毎回走査する。
- `points` は同じ体の正規形で相異なる評価点。零を含めてよい。n はこの列の長さ、メッセージは長さ k の低次からの係数列で、`2≤k≤n`。
- 必要合意数 `1≤A≤n`、多重度 `s>0`、重み `(1,k−1)` の次数上限 `D`。**D は inclusive** で、`i+(k−1)j≤D` の単項式をすべて使う。
- 単項式数 N が `n*s*(s+1)/2` より厳密に大きく、かつ **D<s*A**。

符号化は `f(x)=Σ f_i x^i`, `deg f<k` を各評価点で評価する通常の RS 評価符号。返す候補は受信語との合意数が A 以上、すなわち半径 `n−A` 以内の全多項式である。k=1 は重みが零になるため今回は対応範囲から外した。次数条件は安全な十分条件であり、個々の語に補間が存在するための必要条件としては扱わない。

重み付き多重度補間の根拠は [Guruswami–Sudan, Improved Decoding of Reed-Solomon and Algebraic-Geometric Codes（著者の MIT 掲載版、1998会議版）](https://people.csail.mit.edu/madhu/papers/1998/gs.pdf)。同論文の次数 k と、この package の次元 k は一つ異なるため、重みを `k−1` にそろえた。1999年の論文情報は [IEEE IT45(6),1757–1767, DOI10.1109/18.782097](https://doi.org/10.1109/18.782097)。

## 補間と完全性の条件

単項式 `x^i y^j` の、点 `(a,b)` における `(u,v)` Hasse 係数は `binom(i,u) binom(j,v) a^(i−u) b^(j−v)`。`u+v<s` の全係数を零にする同次行列を作る。二項係数は Pascal 行を体上で足して求め、階乗の逆元に依存しない。正標数で階乗が零になる場合も同じ規約を保つ。

N 個の未知数に対し制約は `n*s*(s+1)/2` 本なので、入口の不等式により非零の線形核が存在する。既存 `rowreduce.solve` の `Affine` 核基底の先頭を選び、零係数を除いた canonical sparse Q を構成する。`check_interpolation` は非零・正規形・次数上限・全 Hasse 制約を再検査する。

次数 `<k` の f が A 点以上で合意すると、`Q(x,f(x))` は各合意点で `(x−a_i)^s` を因子に持つ。一方、その次数は D 以下。異なる評価点での零の多重度の和は sA 以上なので、D<sA なら `Q(x,f(x))` は恒等的に零になる。このため任意の非零補間 Q から全ての該当 f を根として回収できる。Q の重み付き次数の最小化は、この十分条件を満たす実装の正しさには必要ない。

Hasse の規約と、この零の個数による因数化条件は [McEliece, JPL IPN42-153,153F（2003）, Theorems5–7](https://ipnpr.jpl.nasa.gov/progress_report/42-153/153F.pdf) で確認した。

## RR 探索と予算・再開

まず Q の全項に共通する最小 x 次数を除き、`Q(0,y)` が非零多項式になるよう正規化する。全 alphabet のうち `Q(0,γ)=0` になる γ のみを次の係数候補とし、`Q(x,γ+x*y)` への代入と共通 x 冪の除去を繰り返す。k 個の係数を選んだ葉では、元の Q に対する `Q(x,f(x))=0` を `fppoly` で直接検査し、さらに A 点以上の合意で絞り込む。有限 prefix だけが根として残り、次数 `<k` の厳密な多項式根にならない場合も除く。

この変換では真の根 f の係数列が各段階の `Q_j(0,y)` の根になるので、全 alphabet を走査し切れば取り落とさない。根の重複度によって同じ係数を複数回列挙することはせず、同じ定数項から異なる高次係数へ分かれる枝は保持する。主たる手順は [Roth–Ruckenstein, Efficient Decoding of Reed–Solomon Codes Beyond Half the Minimum Distance, IEEE IT46(1),246–257（2000）](https://www.site.uottawa.ca/~zhcheng/efficient.pdf) の係数回収法であり、[McEliece §IX, Eq63–64 / Corollary11](https://ipnpr.jpl.nasa.gov/progress_report/42-153/153F.pdf) とも照合した。早期出力の最適化を使わず、k 係数を選んだ後で厳密合成を検査する。

- `start(plan, received)` は補間を完了し、処理待ち RR 木を保持する `Search` を返す。
- `advance(search, fuel)` の一単位は、処理待ちの一ノードの訪問。内部ノードでは alphabet 全体の根走査と子生成、葉では厳密合成と合意検査を含む。
- fuel が尽き、未処理ノードが残っていれば必ず `Suspended(Search)`。既に候補が見つかっていても完了にはしない。`partial_candidates` と `nodes_visited` で途中結果と訪問数を読める。
- 未処理ノードがなくなった場合だけ `Complete(Decoded)`。同じ Search を再び渡せば同じ探索を再現できる。継続状態は対応する plan・受信語・元の Q を内包する。

**fuel は補間時間、体演算数、メモリ量、壁時計時間の上限ではない。** `start` の行列構成・消去は fuel を消費する前に完了する。明示 alphabet と行列の大きさを確認した小さい入力向けであり、大きな素数や多重度への資源保証はない。試験では一回1000ノードを上限にし、未完了なら試験失敗とする。1ノードずつ再開した試験も実施した。

## 結果検査と限界

`check_candidate` は独立した再符号化、語長、合意数とメタデータを検査し、補間も RR も実行しない。`check_witnesses` は補間条件、各候補、重複、および厳密な Q 合成を検査するが、**リストの完全性を検査する証明書ではない**。候補を取り除いた改竄はこの関数では検出できない。完全性は正しい plan から始めた RR 木が尽きたことと上の次数議論に依存し、外部から作られた `Decoded` や候補集合だけでは保証できない。

`validate(plan)` は alphabet の完全性、support、次元、Hasse 添字、単項式基底、核の存在を保証する個数、不等式 D<sA の七項目を返す。無効な長さ・非正規形剰余・重複評価点・不完全 alphabet・次数条件の境界は明示的なエラーとして拒否する。

受信語が元の符号語から `n−A` より離れた場合、元のメッセージが候補に入る保証はない。半径内の候補が複数なら識別はできず、空リストも有効な完了結果である。source checker / exhaustive tests は形式証明ではなく、有限の検証範囲に対する根拠である。

## 独立オラクルと確認できたこと

[数値テスト](../../src/listdecode/listdecode_wbtest.mbt) と [Python fixture generator](../../tools/generate_listdecode.py) にだけ、全メッセージ列挙による候補集合の対照を置いた。生成側は体上の Horner 評価と一致数だけで全候補を求め、MoonBit の補間・RR は呼ばない。返された Q は、通常整数の二項係数による平行移動の展開でも全 Hasse 係数を検査した。[27件の fixture](../../src/listdecode/oracle_wbtest.mbt) は固定 seed で再生成できる。

| 対象 | 確認内容 |
| --- | --- |
| F5,n4,k2,A3,s1,D2 | 全625受信語で完全な候補集合一致。うち200語は空の完了リスト |
| F3,n3,k2,A2,s2,D3 | 全27受信語で候補集合一致。複数候補を含む。一意訂正半径零を超える半径一 |
| F11,n9,k3,A5,s2,D9 | 単項式30>制約27、半径4>一意半径3。全1331メッセージの対照で四誤りからの回収と真の複数候補を検査 |
| 多重度と次数 | F11,n10,k3,s3,D14（単項式64>制約60、半径5>一意半径3）。F17,n13,k4,s3,D20（84>78、半径6>一意半径4）まで fixture で一致 |
| 小標数 | F2/F3、多重度3/4。通常微分が消える x² の二次 Hasse 係数も検査 |
| RR の分岐 | F3 の `(y−x)(y−2x)(y−1)` により、繰り返し定数根から異なる傾きへ分岐。次数制限外の `y−x²` では偽の有限 prefix を棄却 |
| 中断と検査器 | fuel零、1ノードずつの再開、途中候補ありの Suspended、再実行一致。候補・合意数・語長・Q・plan の改竄を検査 |

具体的な F11 の曖昧語は support0,…,8、受信語 `[0,0,3,0,0,0,8,9,1]`。出力集合はちょうど `[0,0,0]` と `[0,10,1]`、すなわち零多項式と `x²−x` で、いずれも五箇所合意・距離四だった。この例でも RR 訪問数が100未満であり、本体で1331全メッセージを列挙していないことを試験で確認した。訪問数の試験は実行時間の優位を示すベンチマークではない。

最終 focused suite は **native / JS / WasmGC でそれぞれ39 tests / 39 passed / 0 failed**。fixture 再生成照合、`moon fmt --check src/listdecode`、`moon check src/listdecode --deny-warn`、`moon info src/listdecode`、全 kernel purity gate も成功。UTC、コマンド、終了コード、非零試験数、経過時間、ログは `.tools/listdecode-20261116/validation.json` と `validation-*.log`、数値候補集合は同ディレクトリの `oracle-summary.json` に保存した。

```sh
tools/measure --cpu 10 python3 tools/generate_listdecode.py --check
tools/measure --cpu 10 tools/moon fmt --check src/listdecode
tools/measure --cpu 10 tools/moon check src/listdecode --deny-warn
tools/measure --cpu 10 tools/moon info src/listdecode
tools/measure --cpu 10 tools/moon test src/listdecode --target native
tools/measure --cpu 10 tools/moon test src/listdecode --target js
tools/measure --cpu 10 tools/moon test src/listdecode --target wasm-gc
python3 tools/audit_purity.py
```

達成したのは、線形核による Hasse 多重度補間と RR による係数回収が純記号 kernel 上でも組み合わさり、一意訂正半径を超えるリストが独立オラクルと一致すること。新しい符号理論上の結果や実装の速度優位は主張しない。対応は prime-field の通常 RS 評価符号、k≥2、均一多重度、hard decision に限り、一般拡大体、消失、軟判定、parameter 自動探索、永続チェックポイントの形式、巨大入力の資源保証は未対応である。

共有 package・ルート文書・既存 generator と BCH は変更していない。統合担当が研究記録への入口、catalog / inventory と通常 check の generator 登録を追加する。ローカル commit が到達点で、push / merge / deploy はしない。worktree と名前付き `.tools` 成果物は保存確認まで維持する。
