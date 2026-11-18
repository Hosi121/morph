# 数学的構成を共有単位にするための監査

基準は `234ede3502d62d7d3b97603209ea3ae530db4458`（2026-11-18）。目的は、同じ数学的構成を実装ごとに組み直している箇所を特定し、公開 API・厳密性・既存の特殊化を保って共有できる最小単位を決めることである。

これは Phase 1 の静的監査資料である。以下の Phase 2–4 は試作・評価の計画であり、その実装、性能、メモリ削減を確認した報告ではない。純粋な immutable ADT を維持し、機械数値・配列・mutation・FFI による kernel への置換、巨大な推論器・証明器・型クラス階層の追加は前提にしない。

実装した最小試作と採否は[Phase 2–4の評価](quotient-prototype-20261118.md)を参照。試作は既存の置換・削減に至らず、後に通常ソースから撤去した。

更新：実際の簡単化には、新しい商構成の層を増やす代わりに、下記6の既存 `chainhomology` を使った。
`simplicialmap` の整数半環・逆行列検査・整数逆行列・行列適用・下側行抽出・先頭零検査・商座標の列正規化という7処理の重複を削除した。
公開型・APIと検査境界を維持し、本体は644→515物理行（空白・コメントを除くcode行は552→437）。新しい共通核・adapter・型は追加していない。
呼出し先を1か所へ集めた変更であり、速度改善は主張しない。[3target各30テスト・公開API維持の検証](../measurements/simplification-20261118-validation.json)を保存した。以下の未実装候補・見積りは監査時点の記録である。

## 1. galois と numberfield：多項式環の商による体拡大

共通原理は、体 K 上の monic な正次数多項式 f に対し、K[X]/(f) の元を次数が deg(f) 未満の剰余で表すこと。和・差は次数制限を保ち、積は多項式積の還元、unit の逆は Bézout 恒等式から得られる。ただし商が体になるのは f が既約な場合である。

既存の格納形式と認証境界は異なる。[galois](../../src/galois/galois.mbt#L46) は checked Fp と既約性証明書を用い、係数は canonical Binary の dense Chain。[numberfield](../../src/numberfield/field.mbt#L68) は QQ 上の疎な一変数多項式と、選択実根の証明を結び付ける。`same_field` は法だけでなく根区間も含む。同じ根を別の区間で表した場合も、現在の公開 context としては別である。共有核を入れても、この境界を緩めない。

剰余演算と Euclid には共有可能な数学がある。一方、galois の Euclid は左右の Bézout 係数を運び、[numberfield の逆元生成](../../src/numberfield/inverse.mbt#L31)は片側を運んで最後に cofactor を作る。必要な証明書・state・error が違うため、似た全関数をそのまま削除可能 LOC と数えない。有限体の Frobenius 証明と、QQ の因数分解・選択実根の証明も別に残る。

**数体の固定法還元は既に準備済み**である。[Field の reduction](../../src/numberfield/field.mbt#L20) は検査後に `−monic(f)` を保持し、[prepared_remainder](../../src/numberfield/prepared_reduction.mbt#L7) は商を作らず還元する。これを新しいキャッシュの発明とは扱わない。公開 element 構築や逆元 checker が別の normal-form/division 経路を使う独立性も保つ。

条件付きの候補は、galois の一般 p 側で捨てている商の構築を避けること、数体の乗法行列の列を X 倍の ladder で作ること。[fppoly の remainder-only](../../src/fppoly/remainder_only.mbt#L58) は既存なので、それを利用する境界の検討となる。疎→密→疎の変換を毎回増やすだけの adapter を高速化とは数えない。

## 2. complexfield：K(i) の構成と演算

現在の K は checked な実数体であり、K⊂R だから X²+1 は K 上既約になる。[二成分表現](../../src/complexfield/field.mbt#L29) a+i b は、この二次商の次数制限を直接実装したもの。積 `(ac−bd, ad+bc)`、相対 norm `a²+b²`、[共役による逆元](../../src/complexfield/inverse.mbt#L25) `(a−ib)/(a²+b²)` は既に使われている。一般の polynomial Euclid へ戻すことを改善とはしない。

この構成は任意の K へ無条件には広げられない。既に i を含む体や標数2では、同じ既約性の議論は成立しない。QQ への trace・norm も塔の公式を使い、相対次数2と ambient QQ 次元2d、個々の元の最小多項式次数を区別する。

実在する重複は numberfield / complexfield の座標取得、QQ 行列の組立て、多項式評価、最小多項式の探索・検査にある。ここは Element の演算・座標・次元を渡して共有できる候補であり、共役 inverse 自体の重複ではない。公開 context の検査と、[入力・分母証明書・積を確認する checker](../../src/complexfield/inverse.mbt#L81) は残す。汎用二次商は、既存の pair 公式との厳密な照合対象として使える。

## 3. algebra・rowreduce・gf2・primefield：演算辞書と特殊化

[Semiring](../../src/algebra/algebra.mbt#L2) と [Field](../../src/rowreduce/rowreduce.mbt#L2) は法則を仮定する演算レコードであり、法則の証明ではない。Field は可換体・canonical input・`inverse=None iff zero` を仮定する。`is_zero(a)=inverse(a) is None`、`equal(a,b)=is_zero(a−b)` を導けるので、generic 処理に A:Eq は必須ではない。高速な predicate を別に渡す場合は、これらとの一致が条件になる。

`Field -> Semiring` は zero/one/add/multiply の明示的 projection にできる。Q の [algebra 辞書](../../src/algebra/algebra.mbt#L42)と [linear 辞書](../../src/linear/linear.mbt#L3)、[GF₂ の二辞書](../../src/gf2/kernel.mbt#L11)、primefield と finitefield の modular 辞書が共有候補である。ただし algebra に rowreduce を import すると、rowreduce→matrix→algebra の依存が循環する。既存 Field を使う小変更なら、adapter は rowreduce 側または上位層へ置く。

**Bool の二つの代数を混同しない。** `algebra.booleans` は OR/AND の半環、`gf2.scalars/field` は XOR/AND の F₂。`true+true` の値が異なる。同じ Bool 型から演算を自動選択できない。また modular は合成数の法も許すため、その半環を無条件に Field へ昇格できない。

現在の [GF₂ 行列](../../src/gf2/kernel.mbt#L60)は `Chain[Bool]`、[carryless 積](../../src/galois/carryless.mbt#L105)は canonical 0/1 の `Chain[Binary]` を直接走査する。[Binary 自体](../../src/binary/binary.mbt#L2)も Bool Chain であり、機械 packedword ではない。反復 pack/unpack を除くという説明は現状に当てはまらない。carryless の終端には polynomial constructor による再正規化の走査が残るが、その省略の安全性と効果は未検証である。

**標数2と基礎体 F₂を分ける。** 現在は base が primefield なので characteristic=2 から係数が0/1と分かる。[両非零を零にする XOR](../../src/fppoly/characteristic_two.mbt#L33)、係数をそのままに零を挿入する square、非零 leading coefficient を1と扱う monic 処理は F₂ 専用。GF(4) も標数2だが、任意の非零係数は1ではなく、a²=a も成立しない。一般有限 K の相対 Frobenius は q=|K| 乗であり、現在の p 乗・p^degree・係数をそのまま取る p-th root を一律に継承できない。

## 4. positiveform：直和・逆・正スカラー倍の構造保持

[Structure](../../src/positiveform/positive.mbt#L108) は Dense / Inverse / Scaled / Blocks を既に保持し、[direct_sum](../../src/positiveform/positive.mbt#L432) では次元の和、determinant の積、block ごとの作用と逆を利用する。dense 入力の正定値性検査・LDL 分解まで直和の法則が代行するわけではない。

[congruence](../../src/positiveform/congruence.mbt#L137) は逆・正スケール・直和から diagonal と shear word を導き、LDL の再実行を避ける。Hodge も [star / inner の graph](../../src/hodge/value.mbt#L146) と [covector action](../../src/hodge/prepared.mbt#L105) を保持し、二重 star、isometry、invertible shear の零保存を利用している。これらは既存の構造利用であり、新しい generic ADT の成果に加えない。

必要なのは正のスカラー、正定値 witness、shear の source/target・積の順序、metric・orientation・grade の一致である。汎用 `Sum/Product/Dual` enum だけでこれらは導けない。Hodge の Space は context equality 用に metric を materialize するため、「すべて dense 展開を避けている」とも言えない。新しい共通型による net 削減は未立証である。

## 5. forms と tensor：外積・テンソル演算の構成

外積は alternating relation による商であり、[canonical basis の merge](../../src/forms/exterior.mbt#L5) が重複による零・符号・次数を実装する。[pullback](../../src/forms/pullback.mbt#L127) は係数代入と微分の wedge、[Cartan の公式](../../src/forms/cartan.mbt#L107) は既存演算の合成である。closed / exact の witness も d²=0・Leibniz・pullback と d の可換性で [既に伝播する](../../src/forms/closed.mbt#L179)。一般 Form の入口の検査や、affine QQⁿ・正次数での homotopy の条件は残る。

[Tensor](../../src/tensor/tensor.mbt#L28) は shape と flat entries を持ち、product・mode product・contraction を実装する。ただし親空間や vector/covector の variance を型で追跡していない。V**≅V の自然性と、metric で V を V* へ同一視することは別である。既存 cursor・permutation index を再発明しない。融合を提案する場合も、zero axis、shape error の優先順、semiring callback の左右・括弧・呼出し順と回数を含む観測を維持する必要がある。

ADT の和・積と数学上の構成も別である。ADT sum は選択肢の和で、Ab の直和 V⊕W は両成分と加法を持つ biproduct。環の直積なら成分別乗法になるが、Hodge の [二成分 Parts](../../src/hodge/value.mbt#L5) は √D の関係により交差項を持ち、[積](../../src/hodge/evaluation.mbt#L97) は `(ac+Dbd, ad+bc)` 型である。record であることだけから成分別乗法にはできない。

forms と simplicialmap の符号付き basis 正規化には似た挿入処理があるが、前者は重複を零にし、後者は退化後の頂点集合を target-face 検査にも使う。共通化するなら sorted basis・sign・degenerate を残して frontend ごとに解釈する。canonical input 用の線形 merge を遅い汎用 sort へ戻さない。

## 6. chainhomology と simplicialmap：誘導写像と商群座標

共通原理は H=ker A/im B と、関係を保つ写像が商へ降りること。P=Zᵐ/im A、Q=Zⁿ/im B の行列 F は、F A=B W を満たす witness W があれば商の写像を定める。source 座標の lift、F の作用、target の商座標化という合成を共有単位にできる。

[Smith の Cokernel](../../src/smith/cokernel.mbt#L17) は既に商群を構成し、[class_coordinates](../../src/smith/cokernel.mbt#L68) が free/torsion 座標を正規化する。[chainhomology](../../src/chainhomology/chainhomology.mbt#L226)、[homology](../../src/homology/homology.mbt#L120)、[presentation](../../src/presentation/abelianization.mbt#L176) も既存 engine を共有している。QQ の incremental span は別の構成であり、2Z⊂Z の商の2-torsionを QQ span で置換すると失う。

実在する重複は [simplicialmap の整数 helper](https://github.com/Hosi121/morph/blob/234ede3502d62d7d3b97603209ea3ae530db4458/src/simplicialmap/integer.mbt) と、[列ごとの canonical_columns](../../src/simplicialmap/induced.mbt#L51) の wrapper にある。既存 chainhomology への委譲候補であり、新しい Smith 算法を作る理由ではない。両 canonical_columns は既に Cokernel を一度準備して全列へ渡しているので、「列ごとの準備を初めて除いた」とは数えない。

新しい checked map を置くなら source/target presentation、lift の逆関係、descent witness、元の complex と degree の binding が必要になる。[誘導写像 checker](../../src/simplicialmap/induced.mbt#L121) や AB=0・Smith witness の検査は削除しない。public witness の再検査と、opaque な内部 context の再利用は区別する。target の divisor chain の準備再利用は条件付き候補だが、現段階に性能結果はない。

## 重複の footprint と net 削減の未達

三つの監査は対象が重なるため合算しない。LOC の数え方も異なり、以下は削除済み行数や保守費用ではない。

| 監査 | 有限範囲・機械カウント | 意味上の候補と限界 |
| --- | --- | --- |
| 商と体拡大 | 26ファイルを確認。本体22ファイルが3,839物理行 / 3,179 code行 | 座標・最小多項式・F₂ XOR helper のコピー側 footprint は192 code行。adapter・context検査・wrapperの追加分をまだ差し引いていない |
| 係数表現・辞書 | 21 production＋9設定ファイル。sourceは5,580物理行 / 4,623 code-like行。named fn 340は nested helper を含む | 辞書11 literal / 59 slot assignment は59個の算術実装ではない。直接共有関係はQ・F₂ Bool・Fp Binaryの3群。F₂ XOR helper は2定義 / 1意味で、商監査の192行にも含まれる |
| 構成と商座標 | 28 productionファイルの関係箇所を確認 | 整数 helper と canonical_columns の候補領域は152物理行 / 140 code行。委譲後の net は静的見積りで約105–145物理行減。符号付き basis の候補約10–25行減も未実装で、別途評価が必要 |

code行は空白・コメントを除く簡易 source-line 指標で、braceや型宣言を含む。係数監査のcode-like行は全行コメントだけを除く。named fn は API 数でも数学的演算数でもない。本 Phase 1 で達成した production の net 削減は0であり、共通核を追加するだけの prototype はまず増加し得る。

数体の還元準備、複素共役 inverse、Hodge の構造保持、既存 Smith / rowreduce / span への委譲を削減余地へ重複加算しない。新型の context、certificate、変換、残る専用 kernel、tests を数えた後で初めて net を判定する。

## Phase 2–4 の最小計画と評価項目

**Phase 2 は一変数の monic 商環に限定する。** 既存 `rowreduce.Field[A]` を使う小さい `CoeffBackend[A, Base]` と、opaque な Polynomial / Quotient / Element を試す。Base は runtime presentation、A は係数値。canonicalize/validate、exact zero/equality、base一致の境界を明示し、関数レコードを Eq で比較しない。unsafe cast や generic A の型推測は使わず、QQ・Fp の factory が戻り値の型を固定する。

核は trim、加減、convolution、monic remainder、積、unit の try_inverse とする。未既約の商では非零 nonunit にも逆元がないため、これを Field の `None iff zero` と同一視しない。既存の既約性 checker を通した adapter だけが公開 Field を構成し、`Undecided` や単なる Bool を証明済みへ昇格しない。numberfield の選択実根・根区間、complexfield の実 base・QQ 座標順、公開 error/None の順序を維持する。既存 checker を新しい producer と同じ reducer へまとめず、source binding と独立照合を保つ。

**Phase 3 は条件を明示した GF₂ 特殊化の比較とする。** canonical F₂係数、monic modulus、同一 presentation を確認する typed factory から、現在の XOR・shift-and-reduce・専用 square を選ぶ。char2だけでこの kernel を使わない。既存 carryless と複素 pair の経路を残し、generic 核との一致を検査する。GF(4) 係数は誤った適用を防ぐ負の対照にできる。機械 packing はこの純粋 ADT の計画に含めない。

**Phase 4 は採否を決める評価とする。** いずれも今後の項目であり、この資料では実行済みではない。

- 厳密性：代表元の全係数、context・法の不一致、zero/constant/nonmonic modulus、次数1、零 inverse、reducible quotient の非零 nonunit、証明書の付替え、numberfield の別根区間・Undecided を確認する。複素二成分の式、相対次数とQQ次数、既存 oracle・独立 checker も維持する。
- LOCと重複：旧側を実際に委譲・削除した後、共通核＋残る旧実装＋factory/wrapper＋context検査を同じ規則で数える。tests・証拠・docsは分けて示す。最小多項式の別件共有と商 kernel の効果も分ける。
- 追加構造の費用：context構築、既約性検査、変換、cache・証明書の保持を含める。疎/密の二重cacheは保持量を測らず採用しない。
- 時間：構築込み、一回演算、同一context反復、実callerを別cohortにする。同一入力・backend・CPU、共有排他下の固定5ABBAで旧新を比較し、全結果を検査する。F₂、奇素体、疎QQ、密QQ、二次塔を混ぜて一つの速度比にしない。
- メモリ：peak RSSと、取得可能なら確保量・保持量を別に測る。経過時間やConsの静的個数だけから実メモリ削減を推定しない。
- 共存と採否：既存の準備済み・特殊化済み経路を基準にする。汎用化で速度・LOCの片方または両方が悪化した場合も示し、構成の一貫性という価値と費用を分けて判断する。Phase 1の他領域の候補を、この最小試作へ同時に広げない。
