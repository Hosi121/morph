# 基礎部品の最適化

[ドキュメント](README.md) / [探索・改善記録](bootstrap/README.md)

通常経路に採用した改善と、その利用先・検証・比較条件をまとめます。
実装の存在だけでは、上位アルゴリズムへの統合や速度改善を意味しません。
本体からの静的参照は[呼び出し経路](CALL_PATHS.md)、全パッケージは[一覧](INVENTORY.md)を参照してください。

各数値はリンク先の同条件比較です。異なる行・測定系列の絶対時間や倍率は合成しません。

## CADへ入る前の代数的な矛盾

必須の座標等式を使う多項式除算と恒等式の再構築を、共通のprefixlogicへ追加した。
`x=0 ∧ y=1 ∧ xz²+yz−z−1=0`は、以前65秒で未完だったが、新版の固定比較ではCAD約0.109秒、SMT約0.174秒で検査まで成功。
一般CADと公開APIは維持する。[8経路の比較・適用条件・4変数対照の3.4%退行・未証明部分](research/cad-linear-conflict-20261120.md)を記録した。
旧版の打切りから有限の改善倍率や全入力の性能保証は導かない。

## 使わない恒等式の再構築

`prefixlogic`は、矛盾判定や新しい帰結に使う余りだけを厳密に再構築する。
本体は2code行減り、公開APIは維持。native・CPU4・固定5ABBAのSAT準備128回は2.556→2.294 ms（各5/5 block改善）。
全体の時間差は同一ELFにも大きな揺れがあるため未確定で、solver全体の高速化とは主張しない。
[規則・局所80回・全体160回・同一ELF40回の比較と限界](research/cad-demand-20261121.md)を保存した。

## 二項等式の共通簡約

前回の恒等式検査を再利用し、`x=y`の連鎖や`xy=1`も扱う。
`7d80b62`→`a1a0d23`のnative release・CPU4・固定5ABBAでは、3変数矛盾が18.348→1.380 ms、
4変数が37.721→2.052 ms、SMT経由が78.367→4.395 ms。各5/5 blockで改善し、全160回が検査まで成功した。
SAT対照や既存の座標例の差は安定せず、一般化しない。
[規則・全対照・限界](research/cad-binomial-conflict-20261121.md)と
[全ログとsource/ELF](measurements/cad-binomial-conflict-20261121-comparison.json)を保存した。

## 高階テンソルの走査

`tensor.mode_product` と `contract` は、各成分のoffset再構築から不変blockのcursorへ進めました。
添字上げ相当の固定操作でdim3/5が1.872/4.055倍、積と二回の縮約が1.920/3.111倍でした。
通常の `statgeometry` でも利用し、モデル生成を含むcubic引き戻しは1.323倍（5/5 block改善）。
曲率全体やGaussianの小差は未確定です。
[機構・直接比較](research/tensor-20261118.md)、[実際の利用経路と全100出力](research/probability-geometry-20261118.md#テンソルの基礎改善)を参照してください。

その後、内積の一時ペア列を直接の左foldへ融合し、恒等置換では検査済みTensorを再利用した。
基準`3bc3ffc`との最終比較では、添字上げdim3/5が1.078/1.051倍、恒等置換が13.475倍で各5/5 block改善。
非恒等順列と零・微小入力の差は未確定。[単独・併用比較と残る無駄](research/tensor-temporaries-20261120.md)に範囲を記録する。
これらの倍率は上の2026-11-18の系列と合成しない。

さらに`statgeometry.scalar_by_contraction`は、既存のzipとfoldでrank 4の直積と二回の縮約を省く。
固定native比較のdim3/5は5.591/11.591倍、各5/5 block改善。5次元のプロセスpeak RSSは2,560→2,304 KiB。
[条件・旧経路との照合・限界](research/scalar-contraction-20261120.md)を記録した。上記Tensor比較とは別系列である。

## 置換・行列更新・圧縮展開

| 対象 | 変更と比較範囲 |
| --- | --- |
| [tensor.permute](research/tensor-kernel-20261118.md) | 1回の入力走査で不変の軸索引を作り、各成分で平坦リストの先頭から走査しない。nativeの長方形・rank5・恒等置換で3.255・8.875・3.183倍。各5/5 block改善。全座標生成とpublic atの線形検索は残る |
| [matrix.warshall](research/matrix-kernel-20261118.md) | zipの中間pairを同時再帰へ融合。nativeのBool24/64で2.249・2.080倍、min-plus12で1.217倍、非可換係数12で1.429倍。乗算対照は1.011倍で、一般乗算の改善は主張しない |
| [runbinary.expand](research/unused-kernel-20261118.md) | 同じbitのprefix生成と連結をreplicate_ontoへ融合。JSの3入力でpaired倍率中央値1.153・1.188・1.145倍、各5/5 block改善。展開上限と公開APIを維持 |

nativeの2系列は起動・入力構築・検査・出力を含む全プロセスを、JS系列は入力構築を除くexpand直接呼出しを比べる。
異なる系列の倍率は合成しない。実メモリ・Hodgeや他の上位経路への効果は未測定。
matrix.multiplyは既に転置後の逐次dotであり、今回の調査では行列表現全体を変更する根拠は得られなかった。
`core.gcd`・`core.interleave`は公開の参照実装、`runbinary`は圧縮専用の独立実装という位置付けを維持する。
保存済みの全出力・ABBA順序・集計・ソースは静的checkerで再検査し、通常の検査で過去の計測を再実行しない。

## 変換監査から採用した共有

固定ソース`1a51057`を基準`a63dcbc`と比較しました。詳細は[四候補の採否](research/conversion-kernels-20261117.md)、
値とAPIの検査は[108パッケージの統合検証](VALIDATION.md#変換監査後の2件の統合検証)を参照してください。

| 処理 | 利用と最終公開比較 |
| --- | --- |
| 先頭係数1のmonic | polynomial.monicで既存の不変多項式を返す。疎入力process 1.053倍、inner 1.079倍。小・密・上位callerの差は別に掲載 |
| Smithの商群情報の共有 | chainhomology・simplicialmapの非空列で一度だけ準備。多列1.106倍、基底変更1.131倍。空列・単列・上位consumerも比較 |

4公開CLI・24入力・480プロセスで全結果と証拠を照合しました。native release・CPU4・5組のABBA、起動と準備を含みます。
定数の再帰共有と既約剰余の再還元削減は見送り、元の生成器を維持しました。
最終版のそれらのCLIは元の経路の対照で、比を棄却した試作の効果へ帰属しません。
複合した小入力の時間から個々の操作の無回帰を証明せず、保持量や実メモリの改善も主張しません。

## 延長枠で採用した通常経路の改善

固定ソース`a63dcbc`の4件を統合し、6公開CLI・36入力・720プロセスで全結果を照合しました。
[個別の採否・統合後の全記録](research/late-kernels-20261117.md)に、負の結果と対照も残しています。

| 採用した処理 | 実際の利用と最終比較 |
| --- | --- |
| 標数2の既知の平方 | fppoly.power_modへ接続。次の余り専用経路も含む統合版は、基準a39f323の密なF2入力で1.379倍、疎で1.774倍。平方だけの倍率ではない |
| 商を作らないFp還元 | public divideの検査順を保つ内部power用の余り。基準905d23dの密なF2入力で1.196倍、既約性と体構築で1.126倍 |
| 専用Bool行列積 | gf2.multiplyとコホモロジー生成のincoming coordinates。基準a39f323の密な積で1.241倍。コホモロジー全体の効果は別に検査 |
| 正規な±1の積の共有 | polynomial.multiply→numberfield。基準905d23dの+1で1.547倍、-1で1.483倍、numberfield経由で1.169倍 |

native release・CPU4・5組のABBAで、起動・構築・結果と証拠の検査を含みます。
行ごとに基準と作用範囲が異なり、倍率は合成しません。上位callerには他の採用変更も作用し、個別機構への因果分解は行っていません。
一般の密入力・奇標数・上位全体の改善保証にはしません。
QQ減算の融合とGF(2)係数列の準備は見送り、元の経路を維持しています。
既存APIは一致し、[89逆依存パッケージの3バックエンド検証](VALIDATION.md#26時枠に採用した4件の統合検証)も完了しました。

## 夜間に追加した通常経路の改善

最終実装`a39f323`を、各巡の凍結した公開APIの基準と比較しました。
表の行で基準が異なり、倍率は合成しません。全体は[夜間の記録](research/night-kernels-20261117.md)にあります。

| 基礎部品 | 実際の利用 | 最終公開API比較と制約 |
| --- | --- | --- |
| 固定した法の準備 | numberfield.multiply→complexfield | 密な反復積1.228倍、複素平方1.195倍。初期化・一回利用の小差は未確定 |
| 正規スカラーの共有 | fppoly.scale・係数積 | 未還元scalarを含むscale 4.327倍。一般の密な積・除算の一律な改善は主張しない |
| pivot列の単調な走査 | gf2.nullspace_factor→cohomology | 密な零空間3.457倍、分解再利用solve 2.580倍。コホモロジー全体の倍率とは区別 |
| 余りだけのQQ簡約 | polynomial.normal_form→Gröbner・FGLM等 | 多変数1.116倍、Buchberger生成・検証1.060倍。旧divideは独立照合用にも維持 |
| 一度だけ還元した評価点 | fppoly.evaluate→listdecode.encode等 | 512bit点を含む入力12.941倍。通常の点やencode全体の小差は未確定 |
| GF(2)の走査融合 | rref/factor→cohomology・CSS | 疎RREF 1.269倍。幅広・factor・上位CSSの小差や回帰も記録 |
| sorted product rowの平衡merge | polynomial.multiplyの通常経路 | 疎多変数積1.448倍。不均衡な積1.505倍。中間値・実メモリは未測定 |
| 零・単位係数の行共有 | 奇標数fppoly.multiply/power_mod | 疎積1.099倍。標数2の未変更対照に回帰もあり、全入力の速度保証ではない |

これらは各入力の起動・構築・結果と証拠の検査を含むnative releaseの測定です。
現在の8件を組み合わせた54入力・1,080試行と、3バックエンドの逆依存検証を完了しました。
[active row cursor](research/night-cursors-20261117.md)は、小・疎行列が遅くなるため製品経路へ採用していません。

## リストと自然数

| 基礎部品 | 通常経路の利用 | 採用と検証・計測の範囲 |
| --- | --- | --- |
| Natの半分化 | Fp既約性、円分体の次数、2冪判定 | [共有化](bootstrap/nat-conversions.md)から[末尾共有](bootstrap/nat-tail-sharing.md)へ進めた。4096の後段比較は21.70→9.87 µs。Leanのfloorモデルと三backendの有限oracle |
| NatからBinaryへの変換 | 公開binary.from_natとその利用先 | [8進単位の共有](bootstrap/nat-radix-grouping.md)。4096はnative9.60→6.23 µs、JS9.39→5.90、Wasm8.11→5.07。0/1保護、値・停止性・canonical性のLeanモデル |
| 定数prefix | core.replicate、binary.pair | [末尾共有](bootstrap/constant-prefix.md)。8192要素192.60→84.33 µs。任意型のLean等式。Karatsubaへの融合は差が不明瞭なので未採用 |

## 二進算術

| 基礎部品 | 通常経路の利用 | 採用と検証・計測の範囲 |
| --- | --- | --- |
| Binaryの恒等元 | multiply/divmod/gcdを使う全package | [恒等元経路](bootstrap/primitive-identities.md)。2048bitの同値GCD6.34 ms→5.29 µs。全体の一般入力にこの比は適用しない。短い除算groupには回帰あり |
| 0/1の共有 | 公開zero/one factoryを使う全kernel | [不変leaf](bootstrap/binary-constants.md)。同ELFのfactory22.04→12.37 ns、LLL3x3の別比較149〜162→138〜141 µs。差が重なる上位には改善を主張しない |
| 桁幅を使う除算・剰余・GCD | divmod、GCD、modular.reduce | [適応kernel](bootstrap/adaptive-division.md)。近い幅32対の除算1.48→0.262 ms、GCD26.82→9.95 ms。広い差の除算は同程度。8bit全対とPython2048bit fixture |
| 有界積と小さい差 | 公開multiply/subtract→exact・LLL・Smith等 | [4bit積](bootstrap/tiny-products.md)は169積26.58→2.18 µs、[差](bootstrap/tiny-differences.md)は225差9.23→2.70 µs。外域は従来算法へ戻す。積はsuffix DAGで追加Cons544→100、差のWasm byte外域には小回帰の可能性 |
| Binary比較 | binary.compareと除算/GCD等の内部比較 | [有限prefixとtail loop](bootstrap/binary-comparison.md)。全有限raw列のLean等価性、canonical値の順序、三backendの20k bitを検査。native短語2.53→2.28 µs、2048bit等値6.47→3.59 µs。64bitの全caseでの改善は主張しない |

## 整数と有理数

| 基礎部品 | 通常経路の利用 | 採用と検証・計測の範囲 |
| --- | --- | --- |
| exactの小商・約分・符号 | Rational、行列、Smith、LLL、単体法など | [段階最適化](bootstrap/exact-optimization.md)。小さい既知の正確な商、Steinへの限定dispatch、零・±1の共有を採用。さらに[4bit有限表](bootstrap/exact-tiny-gcd.md)を実際の約分へ接続し、156対で旧selector約55→6 µs、二つの固定LLL入力も短縮 |
| 有理数の直接減算 | 公開rational_subtract→行列・LLL・単体法など | [中間の否定を省く](bootstrap/rational-subtraction.md)。同ELFの784演算96.25→79.64 µs。23,409対とPython Fraction fixture、上位への波及は別計測 |

## 有限体と多項式

| 基礎部品 | 通常経路の利用 | 採用と検証・計測の範囲 |
| --- | --- | --- |
| Fp多項式の正規形 | 公開add/negate/subtract→乗算・多項式除算 | [係数の界限を再利用](research/canonical-fp-20261117.md)。nativeの符号反転1.39/1.11倍、減算1.12倍、除算1.10倍。全係数照合込み。加算の小差とGF(2)の対照は限定して解釈 |
| Fp多項式の係数と除算 | Galois、巡回RS、AESの表生成 | [Fp(2)と除算](bootstrap/gf2-performance/README.md)。同じ検査済みfieldの係数、幅、scale/shiftを再利用。CPU時間とwall時間を別に記録 |
| GF(2^m)の積 | Galois.multiply→RSの符号化/復号、AESの有限体演算 | [可変長Bool列](bootstrap/gf2-performance/README.md)。同一CPU timer系列でGF256積5.225→0.942 µs、RS255は7.510→5.000 ms。固定幅案はRSを悪化させたため棄却 |
| 多段実代数の二次式の符号 | realtowerのscalar sign→相対Sturm・任意変数CAD | [厳密な親体比較](research/realtower-20261116.md)。凍結native debug・深さ3の相対二次式1例で1.564/1.633 s→0.0227/0.0201 s。可約・従属・shifted queryの独立70テスト×3 backend。高次数一般PRSは維持 |
| CADのfibre根被覆 | cad→realtower相対Sturm・SMT | [検査付きmonic LCM](research/cad-root-union-20261116.md)。同じ凍結native debugの従属三座標は旧版2回とも12秒で未完、新版0.981/0.990秒で検査まで成功。短い一変数・円の対照は範囲重複。打ち切りを平均時間や一般倍率へ換算しない |
| CADの根を加える表現 | cadのlifting・証人再構成 | [同一根を持つ低次数atom](research/cad-20261116.md)。unionの被覆は維持し、定義次数を抑える。同条件の三段平方根1例で6.517/6.487 s→1.300/1.301 s。別の改善倍率とは合成しない |
| 一変数多項式の評価 | 公開polynomial.evaluate→Sturm・実数制約・実代数計算 | [疎Horner](research/sparse-horner-20261116.md)。同じnative ELFの密な6評価2.51→0.336 ms、実数制約の次数8例1.59→0.490 s。√2の小例は横ばい。JSにも局所改善、WasmGCの短い対照は揺れが大きい。独立QQと降順を前提にしたLeanモデル |

## 数体と増分線形従属

| 基礎部品 | 通常経路の利用 | 採用と検証・計測の範囲 |
| --- | --- | --- |
| 数体の正規代表元 | numberfield.add/subtract | [次数の界限](research/nf-kernels-20261117.md)で再簡約を省く。統合後の公開APIは次数1/4で1.455/1.262倍。体の一致検査と乗算の簡約は維持 |
| 一回の座標抽出 | numberfield・complexfield・乗算行列 | [整列項の走査](research/algorithm-kernels-20261117.md)。座標3例は2.535〜4.368倍、乗算行列は1.234倍 |
| 不変なQQ span | 数体・複素数体の最小多項式、FGLM | [新しい列だけを還元](research/incremental-span-20261117.md)。統合後の最小多項式は1.258〜1.607倍、FGLMは1.166/1.379倍。検査器を維持しFractionと旧系で照合 |
| Smithの直接列操作 | Smith→整数ホモロジー・商群など | [転置を省く](research/structural-kernels-20261117.md)。統合後の小・長方形・密行列は1.060/1.560/1.069倍。旧U/D/V・燃料遷移とも一致 |

[統合後440試行](research/algorithm-kernels-20261117.md)は起動・入力・結果検査を含むnative releaseの比較です。
数体乗算の対照には約3.5%の時間増加もあります。すべての経路で速くなるとは主張しません。

## 体上の消去と再利用

| 基礎部品 | 通常経路の利用 | 採用と検証・計測の範囲 |
| --- | --- | --- |
| GF(2)専用消去と保持した分解 | CSS rank、コホモロジーのrank・零空間・基底 | [公開APIの変更前後](research/field-kernels-20261117.md)。nativeのCSS4例は2.57〜3.10倍、円周1.83倍、トーラス3.11倍。既存の汎用証拠検査込み、Bool列のまま |
| 有理数の零係数で行を共有 | 公開linear→整数chain逆・数体の線形系 | [正規形を条件にした零判定](research/rational-elimination-20261117.md)。単位行列3.00倍、疎逆1.90倍、chain逆1.59倍。密な行列・最小多項式等の改善は未確定 |
| 素体のp=2辞書 | 公開primefield.fieldの加減乗・逆元 | [任意長入力のparity](research/prime-arithmetic-20261117.md)。直接混合演算1.46/1.77倍、逆元7.87倍。Fppoly上位例に改善なし、奇標数の小差は未解決 |

使い分けは[共通算法と専用カーネル](handbook/field-kernels.md)を参照してください。

## 行列式

[Bareissの採用](research/bareiss-adoption-20261116.md)で、`linear.determinant`を整数保存消去へ接続しました。
分母払いを含め、nativeの密な6/8次cohortは旧RREF経路の1.86〜2.36倍。
上位の固定例では、和のresultantと証拠検査が135.88→89.26 µs、四次数体のnorm4回が174.87→105.97 µsでした。
次数4×2の積resultantは範囲が重なるため改善を主張しません。Hornerとの倍率は合成しません。

## SATと反証

| 基礎部品 | 通常経路の利用 | 採用と検証・計測の範囲 |
| --- | --- | --- |
| CDCLのdecision/conflict | watched solver→NAND合成・SMT・RUP生成 | [SAT kernel](bootstrap/sat-engine.md)。first-openとassignment trieを採用。同一ELFのcomplete-query4.39 s→0.826 s、生成CNFと燃料構築を除きbuilder/checkerを含む。探索traceと証拠の一致も検査 |
| 既存CADからの理論衝突節削減 | realnlsmt.start / start_core | [被覆の再束縛と検査込み比較](research/theory-core-20261117.md)。二次式4原子のUNSATで衝突15→4、native345.526→97.005 ms、JS1.84倍、WasmGC1.35倍。削減できない対照の追加probe費用も記録し、全割当て経路を残す |
| CDCLへの単調な入力節追加 | realnlsmtの理論節を同じcursorへ追加 | [状態保持と同条件比較](research/retained-cdcl-20261117.md)。人工的な63衝突の対照で再始動63→0、SMT遷移3853→243。検査込みnative25.856→8.318 ms、JS1.97倍、WasmGC2.69倍。算術が支配的な対照は範囲重複や小さな遅れがあり、再始動経路を維持 |
| RUPの索引とhint生成 | 生成proof→独立checker | [RUP](bootstrap/ruplog.md)。非unitの早期終了と節参照の共有を合成し、20対全query314.14→284.44 ms。単独案は差が不明確で保留した。LRAT/DRATへ16証拠と7偽造例を出力して追試 |

## 採用しなかった候補と独立実装

- [持続性のpivot索引二案](research/structural-kernels-20261117.md)は、常時・必要時構築とも安定した改善がなく、不採用です。本体とAPIを基準へ復元しました。
- [全加算器の12候補](bootstrap/adder-search.md)は、全8条件の等価性をLeanでも確認しましたが、実測で遅いため通常の式を変更していません。
- [一般剰余への追加比較と複素三積](research/field-kernels-20261117.md)は、対照の回帰があり不採用です。複素積は本体を変更していません。
- [長語除算の追加実験](research/wide-kernels/README.md)は、JSのスタック制約を避けてもnative剰余が悪化するため未採用です。
- `runbinary`は圧縮に特化した独立実装で、通常のBinary全体のバックエンドにはしていません。
- `core.gcd`と`core.interleave`は内部利用のない公開APIです。局所的な速さだけで、変換費用を無視して接続することはしません。

小差や未変更対照の揺れが大きい結果では、上位の成功例だけを採用理由にしません。

## 計測の共通条件

重いbuild・test・計測は`tools/measure --cpu N COMMAND...`で、全worktree共通のロックを通します。
担当間の競合は避けられますが、外部負荷や周波数の変動までは除去できません。
詳細な条件と生ログは[計測記録](MEASUREMENTS.md)と各行の探索記録にあります。
