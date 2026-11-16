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
