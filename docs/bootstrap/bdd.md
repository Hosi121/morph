# 永続ROBDD

`src/bdd` は `@circuit.Expr` を明示した変数順序のROBDDへ変換する。
Bool、Chain、Nat、Binary、ADT、再帰だけで構成し、組み込み数値・配列・可変状態・FFIを
核に使わない。節点表、unique table、applyのmemoは不変Bool trieである。

## 基本API

```text
compile(Expr, Chain[Nat]) -> Diagram?
apply(Operation, Diagram, Diagram) -> Diagram?
negate(Diagram) -> Diagram?
restrict(Diagram, Literal) -> Diagram?
evaluate(Diagram, Model) -> Bool?
pick_model(Diagram) -> Model?
equivalent(Diagram, Diagram) -> Bool?
order(Diagram) -> Chain[Nat]
node_count(Diagram) -> Nat?
allocated_count(Diagram) -> Binary
valid(Diagram) -> Bool
model_count(Diagram) -> Binary?
exists_variable(Diagram, Nat) -> Diagram?
forall_variable(Diagram, Nat) -> Diagram?
Operation = Conjunction | Disjunction | Exclusive
```

順序には式の全変数を一度ずつ含める。余分な変数は許す。重複したラベル、式に現れるのに
順序にない変数は `compile` が拒否する。ラベルの大小とは独立に、渡した順序を使う。
大きなNatラベルは入口でBinary keyへ変換する。

各 `Diagram` が自分のmanagerとrootを保持する。節点IDはmanager内だけで意味を持つ。
Diagramにも内部Edgeにも公開Eqを与えず、関数の比較は `equivalent` を通す。
二項演算は同じ順序を要求し、両operandを新しいmanagerへ取り込んでからapplyする。
取り込みmemoは入力managerごとに分離するため、異managerで同じ番号になった節点を
同一視しない。異なる順序の混合は `None`。自動的な並べ替えは行わない。

低枝と高枝が同じなら節点を除去し、変数rank・低枝ID・高枝IDが同じ節点を共有する。
applyは最も早いrankで両関数をcofactorし、低・高の結果をunique tableへ戻す。
元のDiagramは変わらず、操作後も再使用できる。

`restrict` は一つの宣言済み変数を代入する。宣言した順序・変数領域は保持する。
`evaluate` は通過する全決定変数が割り当てられた一貫したmodelを要求する。
矛盾したmodelや必要な値の不足は `None`。余分な変数の一貫した割当ては許す。
`pick_model` は宣言した全変数へ値を返し、省略された変数にはfalseを選ぶ。
恒偽のDiagramにはmodelがない。

`node_count` はrootから到達する非terminal節点だけを数える。
`allocated_count` は中間演算で確保した、到達しなくなった節点も含む。
managerはそれらとmemoを保持し、garbage collectionやsource Exprのmemoはまだない。
`valid` は順序、枝のrank増加、後方ID参照、reduction、unique tableへの登録を検査する。
式の意味の正しさを証明するcheckerではない。

## 有限検証

最初の基本単位には9テストを置き、native、JavaScript、Wasm GCで確認する。

- 3変数の全256関数をDNFとShannonの二つのExprで作り、全6順序で同じ関数・同じ到達節点数に
  なることを検査する。全真理値、否定、SAT modelも整数・Bool oracleと直接Expr評価に照合する。
- 2変数の全16関数の全pair、両順序、3種類の二項演算を全真理値で照合する。
- 3変数の全関数、各変数、両代入値を、正順・逆順で制限し、真理値の置換と一致させる。
- 異managerで同じroot IDになる変数0/変数1、およびAND/ORを実際に作り、混合しても意味を
  取り違えないことを検査する。元Diagramの再使用、異順序、空順序、重複、未知変数、
  ラベル65535、partial/矛盾modelも検査する。
- 全3変数関数の充足性を旧DPLLと照合する。propagate/mux加算器の0〜4bit miterは、
  BDDの恒偽、全真理値、旧DPLL反証、新CDCL RUPの各方法で一致する。
- 欠損した決定節点、reduction違反、循環した内部表を構造checkerが拒否する。

全入力の形式証明ではない。Expr→BDD、Expr→CNF、SAT proof checkerはそれぞれ信頼境界を持つ。

## 変数順序の同条件比較

同じpropagate加算器のcarry-out Exprを変換した。blockedは全a、全b、入力carryの順、
interleavedはa0、b0、a1、b1、…、入力carryの順で、語はlittle endianである。
1、2、4、6bitは両順序の全入力を独立整数加算と照合した。

| bit幅 | blocked到達節点 | interleaved到達節点 | blocked確保節点 | interleaved確保節点 |
| --- | ---: | ---: | ---: | ---: |
| 1 | 4 | 4 | 11 | 11 |
| 2 | 11 | 10 | 31 | 28 |
| 4 | 53 | 22 | 163 | 98 |
| 6 | 221 | 34 | 709 | 216 |
| 8 | 893 | 46 | 2,911 | 382 |

8bitの同一Expr・同一変数集合、native release、MoonBit v0.10.20、同じWSL2環境でのcompile：

| 順序 | 平均 ± 標準偏差 |
| --- | ---: |
| blocked | 6.64 ms ± 271.57 µs |
| interleaved | 594.58 µs ± 11.87 µs |

Expr生成と順序列の構築は計測外、managerの準備・unique/memo構築は計測内である。
各10サンプル。変数順序により、同じ関数でも節点数と時間が大きく変わることを示す。
SATエンジンとの一般的な速度の優劣はこの比較から推定しない。

```sh
tools/moon test src/bdd --target native
tools/moon test src/bdd --target js
tools/moon test src/bdd --target wasm-gc
tools/moon bench src/bdd/circuits_wbtest.mbt --target native --release
```

## モデル数と量化の後続単位

`model_count` は宣言した順序の全変数について、充足割当て数を任意精度のBinaryで返す。
終端trueには残りの変数数に応じた自由度を与える。各決定節点のmemoには、その節点自身の
rankから末尾までの個数を保存し、親からその節点まで飛ばしたrank数だけ2倍する。
同じ節点を異なる深さの親が共有しても、親依存の値を誤って再利用しない。

`exists_variable` は両制限結果のOR、`forall_variable` はANDを、新managerへの安全な
import/applyで作る。未知の変数は拒否する。どちらも元の宣言領域を保持する。
例えば順序 `[x,y]`、関数 `x AND y` でxを存在量化するとyになるが、モデル数は2である。
xが結果に影響しなくなり、xの両値を自由な割当てとして数えるためである。
`restrict` 後の個数についても同じ契約を使う。

追加4テストを含む全13テストをnative、JavaScript、Wasm GCで確認する。
全3変数関数×全6順序のモデル数は真理値表のpopcountと一致する。
正順・別順の全小関数、全変数の両量化についても全真理値と個数を照合した。
空領域、飛ばしたrank、余分な宣言変数、ラベル65535を検査する。
64変数の恒真で2^64、64変数parityで2^63を、組み込み整数へ変換せずBinaryのbit列として
確認した。parityの到達節点は127である。
carry-outの0〜6bitのモデル数も全入力の整数加算と一致する。

8bit carryのprebuilt Diagramを毎回数え、memo構築も計測に含めたnative release結果：

| 順序 | モデル数 | 平均 ± 標準偏差 |
| --- | ---: | ---: |
| blocked | 65,536 | 794.72 µs ± 34.78 µs |
| interleaved | 65,536 | 17.87 µs ± 588.78 ns |

各10サンプル。節点構築は計測外であり、上のcompile比較とは別の処理を測っている。

```sh
tools/moon bench src/bdd/count_wbtest.mbt --target native --release
```
