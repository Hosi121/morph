# 実代数塔の初期受入検査（2026-11-16）

対象は `research/realtower-20261116` の `src/realtower`。
全て `tools/measure --cpu 6` により Git 共通ロック・CPU 6 に固定した。
下表は package test 一回の wall/user/sys 秒であり、性能改善の比較ではない。

| target | tests | wall | user | sys |
| --- | ---: | ---: | ---: | ---: |
| native | 6/6 | 3.32 | 2.49 | 0.61 |
| wasm-gc | 6/6 | 1.18 | 0.95 | 0.33 |
| js | 6/6 | 0.64 | 0.52 | 0.14 |

`tools/moon check --deny-warn --target js src/realtower` 成功。
`python3 tools/audit_purity.py` は 223 kernel files で成功。
ログは作業木の `.tools/realtower-20261116/`（未追跡）。

検査内容：有理数、可約 `(y-1)(y-2)` の選択根1における `y-2` の逆元、
非零剰余の意味論的零、正負共役の context 拒否、ancestor embedding、
深さ2/3の入れ子平方根、逆元との積、重複因子、端点根 `(a,b]`、
無根・定数多項式、resumable isolation、根と全被覆の source/payload 改竄拒否。
独立 Fraction/SymPy fixture の増補は次の検査段階。

## 平坦な厳密 oracle と二次式の符号判定

追加後の default コーパスは27件（元の6件、opaque payload検査1件、flat oracle20件）。
独立 oracle は Fraction の平坦な `Q(gamma), gamma^(2^depth)=2` 表現を用い、
44 scalar quotient、96相対区間根数、16全根被覆を深さ0〜3で照合する。
SymPy は QQ 多項式の逆元だけに使用し、符号は Fraction 区間の厳密な二分で決める。
Float / evalf は使用しない。生成の `--check` 成功。

| target | tests | wall | user | sys |
| --- | ---: | ---: | ---: | ---: |
| native | 27/27 | 1.71 | 1.49 | 0.13 |
| wasm-gc | 27/27 | 2.87 | 2.20 | 0.67 |
| js | 27/27 | 3.07 | 2.48 | 0.46 |

これらの package test 時間には必要なコンパイルを含む。以下の比較には含まない。

二次拡大での線形式の符号を親の体における平方の大小に帰着する shortcut を、
同一の `flat exact relative roots depth 3 case 0` で比較した。
入力は正の `gamma^8=2` の塔上の `y²-gamma`、6区間の根数、全根分離と
result 証明書検査。`tools/measure --cpu 6` の共通ロック下で、凍結した二つの
native debug ELF を ABBA 順に実行した。

| order | kernel | wall seconds | user seconds |
| --- | --- | ---: | ---: |
| A | 汎用 PRS | 1.5643 | 1.6150 |
| B | 二次 shortcut | 0.0227 | 0.0224 |
| B | 二次 shortcut | 0.0201 | 0.0199 |
| A | 汎用 PRS | 1.6327 | 1.6386 |

CPU は Intel Core Ultra 7 255H、Moon は `0.1.20261104 (940aa18)`。
[凍結 ELF・source・fixture の SHA256 と生計測値](realtower-quadratic-20261116.json)を保存した。
この差は上記入力・debug cohort の結果であり、高次数・一般の塔への性能主張ではない。

分母の商環 Bézout 正規化も試したが、深さ3の密な四次式では45秒の計測上限内に
完了せず改善を確定できなかった。相対二次式でも追加コストが見えたため採用しなかった。
逆元は選択根での非零確認後に分子分母を交換する元の方式を維持する。

密な四次式を深さ2/3にも加える stress コーパスは generator の `--stress` で再生成できる。
深さ3の該当ケースは汎用 PRS と今回の shortcut とも45秒以内には完了しなかった。
旧全stress実行も382.48秒で実行を区切ったため、その実行を成功や無根と扱わない。
default の27件は全件完了している。測定上限は一つの実験の区切りであり、
APIの計算を偽・UNSAT・無根へ読み替える制限ではない。
