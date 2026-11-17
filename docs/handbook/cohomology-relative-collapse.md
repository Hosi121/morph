# コホモロジー環・相対群・単体崩壊

[ハンドブック](../../HANDBOOK.md) / [位相と符号の基礎](topology.md)

穴の数だけでなく、類同士の積、部分空間との関係、計算を保つ簡約を扱う。
整数の相対群と二進の積を区別し、それぞれの返却値を元の複体と結び付けて検査する。

| 求めたいもの | 入口 | 計算と証拠 |
| --- | --- | --- |
| GF(2)コホモロジーと積 | [cohomology](../../src/cohomology/pkg.generated.mbti) | 具体的なcochain代表、商座標、全次数のcup積表、完全な基底変換 |
| 整数の核と像の商 | [chainhomology](../../src/chainhomology/pkg.generated.mbti) | `A B=0` の行列対からSmith基底と整数商。既存homologyも同じ核を使う |
| 相対ホモロジーと連結準同型 | [relativehomology](../../src/relativehomology/pkg.generated.mbti) | 部分複体を除いた鎖、相対群、境界への連結準同型と下降の証拠 |
| 通常の単体崩壊 | [collapse](../../src/collapse/pkg.generated.mbti) | 自由面の除去、整数の包含・射影・chain homotopy、再開可能な探索 |
| 持続性を保つ崩壊 | [filteredcollapse](../../src/filteredcollapse/pkg.generated.mbti) | 同gradeの組だけを除去し、全非零行列成分のgradeを検査 |

```sh
tools/moon run src/cmd/topologyrings
```

`rings`、`relative`、`collapse` で各部分を実行できる。
[掲載出力](../TOPOLOGY_RINGS_TOUR.txt)と[探索記録](../research/topology-rings-20261117.md)から具体例と検査へ進める。

## 穴の数が同じでも積が違う

コホモロジーは、境界行列を転置したcoboundary `delta_k = transpose(d_(k+1))` から作る。
GF(2)のcocycleの空間をcoboundaryの空間で割り、具体的な商基底と代表を保持する。
既存CSSの二進体辞書とrank証拠、共通の行基本変形を使い、別の消去法は追加しない。

頂点を昇順に並べた単体ではAlexander–Whitneyの式

\[
(a\smile b)[v_0,\ldots,v_{p+q}]
=a[v_0,\ldots,v_p]b[v_p,\ldots,v_{p+q}]
\]

でcochainの積を作れる。cocycleの積を商座標へ戻し、全ての同次基底対の積を表にする。
cochain上の積は一般には可換でない。コホモロジーの類に移すとgraded commutativityが成立し、
GF(2)ではその符号が消える。cochainの生値と商の値を混同しない。
定義と法則は[Hatcher §3.2](https://pi.math.cornell.edu/~hatcher/AT/ATch3.pdf#page=22)に対応する。

| 空間 | 整数H0/H1/H2 | GF(2)での一次の類の積 |
| --- | --- | --- |
| トーラス | Z / Z² / Z | `a²=b²=0`、独立な二類の `ab` は二次の生成元 |
| `S1 ∨ S1 ∨ S2` | Z / Z² / Z | 一次の類同士の積は全て0 |
| 実射影平面 | Z / Z/2 / 0 | 非零な一次の類 `a` に対し `a²` が非零、`a³=0` |

トーラスと上のwedgeは、加法的な整数ホモロジーでは区別できない。
cup積まで保持すると区別できる。これで任意の空間を分類する機能になるわけではない。

完全な基底証拠はcoboundary、コホモロジー代表、残りのambient基底を合わせた可逆行列を持つ。
rankだけを確認して代表の完全性を仮定せず、両側逆と元のcoboundary行列との関係を検査する。
積表では元の複体、実際の代表、全基底対の被覆、単位・結合則・商での可換性も検査する。

## 部分空間を除いた鎖と、その境界

部分複体AがKに含まれる組 `(K,A)` を入力とする。
相対鎖 `C_k(K,A)` の基底は、Kに存在しAに存在しないk単体。
元の境界へ包含と射影を掛け、Aの単体に着地する成分を商で0とする。
行列の形と境界の合成が0であることを検査して、整数の二回のSmith標準形へ渡す。

共有する[行列対の核](../../src/chainhomology/chainhomology.mbt)へ既存の絶対ホモロジーも移し、
整数cycle格子と境界像の計算を重複させない。`homology` の公開型・証拠のフィールドは維持する。

相対cycleをKの鎖へ持ち上げると、その境界はAの中にある。
これが連結準同型

\[
\partial:H_k(K,A;\mathbb Z)\longrightarrow H_{k-1}(A;\mathbb Z)
\]

の具体的な計算になる。Smithの元の左変換の逆で代表を戻し、境界をAのcycle基底へ移して、
先のSmith座標へ正規化する。相対boundaryの像が先で0になる整数の下降式も検査する。
座標は既存の誘導写像と同じく、対角1の自明なslotも含む全Smith ambient座標である。

円盤と境界円周では `H2(D2,S1)=Z` から `H1(S1)=Z` への同型になる。
区間とその両端点では、相対1次の生成元が端点の差 `(-1,1)` へ移る。
非簡約の規約を用い、次数0から次数−1への入口は持たない。
今回実装したのは相対群とこの連結準同型であり、長完全列の全写像・完全性検査ではない。

## 図形を削って計算を保つ

単体tauの余次元1の面sigmaが、tau以外の単体の面になっていないとき、両者を除ける。
実装は単体名を一組ずつ検査し、実際の除去先が閉じた複体であることを確かめる。
行列Iを残った複体の包含、Pを元からの射影、Hを次数を一つ上げるhomotopyとし、

\[
PI=1,\qquad 1-IP=dH+Hd
\]

と、I・Pがchain mapであることを全次数で検査する。
三角形の自由辺を消す際も、向きの係数 `+1` または `-1` を整数のまま扱う。
中を埋めた三角形は7単体から1頂点へ簡約でき、証拠から同じ整数ホモロジーを持つと分かる。

探索は候補の組の試行数を燃料にし、中断状態を保存できる。
`Stalled` は現在の複体でこの種の自由な組が見つからないという意味で、
最小の複体や、一般のホモトピー型・可縮性を判定したという意味ではない。
複合証拠の検査と、探索が止まったという主張の検査も区別する。

## 穴の寿命も保つ条件

通常の崩壊は最終的なホモロジーを保っても、filtrationの途中の穴を消してしまうことがある。
`filteredcollapse` は、sigmaとtauの有理gradeが同じ場合だけを許す。
残った単体のgradeと順序を変えず、I・P・Hの全非零成分が出現gradeを増やさないことも直接検査する。
これにより各gradeで使える鎖とhomotopyが保たれる。
参考は[Mischaikow–Nanda](https://people.maths.ox.ac.uk/nanda/source/DMPers-Final.pdf)のfiltered chain equivalenceであり、
この実装は自由面を順に除く限定的な方式で、一般のMorseReduceを実装したものではない。

正方形のRips filtrationは15単体から11単体になり、H1の区間 `[1,2)` を含むgradeバーコードを保つ。
単体数が減ったことと、全処理が速くなったことは別である。前処理と行列証拠の検査にも費用がかかる。
探索の燃料は試行数であり、候補構築・リスト走査・行列検査の実時間を制限しない。

独立な有限参照、証拠の改変検査、確認済みの範囲は[検証ガイド](../VALIDATION.md)と研究記録にまとめる。
これらは計算証拠と有限照合であり、新しい位相実装全体の形式証明ではない。
