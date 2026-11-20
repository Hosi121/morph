# Tensorの一時ペア列と恒等置換を省く

基準`3bc3ffc`、内積の変更`82587b8`、併用版`0b9cab0`。既存のcursorと一時軸indexを基準に、二つの不要な構築を除いた。
公開API・型・import・格納表現は維持する。機械数値・配列・mutation・FFI・Eq[A]の条件は追加していない。

## 変更と成立条件

`mode_product`の内積は、以前は`zip`で全ペアを作り、その列を左から畳み込んでいた。
Matrixの行幅とTensorのshapeは構築時に検証され、公開入口でもaxis幅を照合する。cursorの列と係数行は同じ長さになるため、
ペア列を作らず、二列を同時に進めて同じ`times(coefficient,value)`、`plus(accumulated,term)`を呼べる。
この内積は末尾再帰にした。零係数も省略せず、合法な公開入力に対するcallbackの回数・引数・順序を保つ。内部不整合のguardは残す。

`permute`はrank・bounds・全単射の検査を従来の順序で行った後、恒等順列なら検査済みの不変Tensorを返す。
この場合、軸index・座標列・成分列を作り直さない。一般の順列では既存の軸列を再利用し、従来のindex経路へ進む。
成分の比較や評価は必要なく、非Eqの関数成分にも適用する。

本体4ファイルは786→792物理行、空白・コメントを除くcode行は685→688。新しい共通型・公開関数・helper関数は0。
物理行はsplitlines、code行は`line.split('//',1)[0].strip()`が非空の行で括弧も含む。tests・CLI・生成interfaceは除く。
既存の有限oracleとcallback記録を再利用し、新しいtest宣言は追加していない。

## 固定した最終比較

native release・CPU4・共通Git lock・同一SDK・5ABBA。コンパイルを除き、起動・入力と期待値の構築・全反復・完全照合・出力を含む。
geometryは既存CLIの`--profile`による32倍反復を比較開始前に固定した。2026-11-18のデフォルト反復の報告とは別系列であり、
同じCLIのpermutationは従来の反復数のまま。harnessはbyte一致し、`argument_prefix`と`iterations`を各記録に保存する。

| ケース | 反復 | 前 median ms | 後 median ms | 前/後 | 改善block |
| --- | ---: | ---: | ---: | ---: | ---: |
| raise3 | 64,000 | 3,805.285 | 3,530.152 | 1.078 | 5/5 |
| raise5 | 16,000 | 6,581.627 | 6,264.271 | 1.051 | 5/5 |
| scalar5 | 16,000 | 8,548.880 | 8,466.957 | 1.010 | 3/5 |
| permute-identity | 3,000 | 73.585 | 5.461 | 13.475 | 5/5 |
| permute-rank5 | 500 | 66.493 | 63.296 | 1.051 | 3/5 |

[最終併用版の全100プロセス](../measurements/tensor-temporaries-final-20261120.json)は全て照合に成功した。
`raise*`はraised cube、`scalar*`はproduct・first trace・scalar、順列はshapeと全entryを毎反復照合する。
保存payload全体も、独立のPython Fraction再構築または既存mixed-radix参照で照合した。
Fraction参照のsourceは最終JSONの`independent_fraction_reference_source`に保持する。参照はMoonBitのtensor/exact演算を使わない。
全比較の実行ファイル・ソースmanifest・compiler・harnessのhashも保存し、manifestは測定sourceのGit treeと照合した。

[内積単独の120プロセス](../measurements/tensor-temporaries-dot-20261120.json)ではraise3/5が1.100/1.085倍で、両方5/5 block改善。
[恒等変換単独の120プロセス](../measurements/tensor-temporaries-identity-20261120.json)では恒等置換が18.119倍だった。
単独と併用の値は別系列であり、倍率を合成しない。最終版の採用根拠は上表の添字上げと恒等置換である。

非恒等rank5は単独比較で中央値が約4%遅く、最終比較では約5%速い。
[同一ELFの20プロセス対照](../measurements/tensor-temporaries-identity-aa-20261120.json)でもblock比が0.926–1.164に分かれた。
方向が揃わないため、非恒等順列の速度改善や退行率は確定しない。内積単独のtiny/zeroの中央値は約0.6%/1.1%遅く、
変更していないscalar経路にも小差がある。全入力・全型の速度維持は主張しない。12種の入力、3比較系列340プロセスと同一ELF対照20プロセスを保存した。

[診断profile](../measurements/tensor-temporaries-profile-20261120.txt)にはobject管理と厳密有理数演算が現れるが、zip単独の費用割合を切り出したものではない。
sampled CPU weightとwall time、inclusiveな各関数の値は区別する。実メモリ・確保総量・JS/Wasmの性能は未測定で、peak RSS削減を主張しない。

## 残る無駄

| 経路 | 残る構築・探索 |
| --- | --- |
| [tabulate / 非恒等permute](../../src/tensor/tensor.mbt) | 全座標の列挙。置換では出力ごとに座標を組み直す。public atのflat Chain検索も線形のまま |
| [Tensor.zip](../../src/tensor/tensor.mbt) | ペア列を作ってからmapする。今回の内積融合とは別に残る |
| [mode積のblock](../../src/tensor/cursor.mbt) | 同じ入力の列を出力行ごとに準備する。共有すると保持量も変わるため、単一出力行を含めた比較が必要 |
| [縮約の中間block](../../src/tensor/cursor.mbt) | 対角部分を取る前に、捨てるoff-diagonalを含むblockもコピーする |
| [scalar_by_contraction](../../src/statgeometry/tensors.mbt) | rank 2同士からrank 4の積を展開する。n⁴個の積に対し、最終結果に必要な対応成分の積はn²個。QQ専用経路の融合が次の大きい候補 |

最後の候補は、任意のSemiring callbackの順序を変えてよいという意味ではない。
固定QQの結合則・可換性を利用する経路と、汎用Tensor APIの観測契約を区別し、既存の独立照合も保つ必要がある。
Tensorはshapeと全成分を持つdense表現であり、対称性・共変/反変・遅延した積や縮約を型で保持する実装は今回追加していない。
