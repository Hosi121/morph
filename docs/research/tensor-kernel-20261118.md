# Tensor permutation: flat lookup を一時的な軸 index に置き換える

今回の問いは、既に cursor 化された contraction / mode product を保ち、
`permute` に残る「出力 entry ごとの unary offset 計算と flat Chain の先頭からの
nth」を減らせるか、である。基準 production source は
`193162547171f36b694e6b6e70c128ddc0b1ef14`。変更は permutation の内部だけに限定した。

`permute` は検証済み input を一度だけ row-major に読み、immutable な
`PermutationIndex[A]` を作る。葉は元の A を保持し、各分岐は一軸分の
`Chain[PermutationIndex[A]]` を保持する。その後は元座標に沿って軸ごとの nth を
行う。public `Tensor[A]` の格納形式、`at`、`tabulate`、contraction / mode cursor、
semiring 辞書には変更がない。機械数値、array、mutation、FFI、算術演算子は kernel に
追加していない。`Eq[A]` も要求しない。

順列の rank、bounds、重複の検査順序は従来通り。scalar は一つの葉、zero 軸を
含む tensor は軸の検証後に空 entry を返す。axis size が d_1,…,d_r、entry 数が N
なら、従来の flat nth の走査は全出力で N(N−1)/2 の Chain tail を辿る。
新しい検索は一出力あたり各軸の index の和に従う。参照木の準備と出力座標の生成は
別途必要であり、これを wall-clock の一般的な保証には読み替えない。

## 固定比較の結果

native release、MoonBit moonc `v0.10.20+65efd5b93`、Intel Core Ultra 7 255H、
CPU 4 に固定。`tools/measure` の Git 共通 lock で他の本 repo の重い処理と直列化し、
各ビルドは `-j 1` とした。全6 case を事前に固定し、各 case について
baseline / candidate / candidate / baseline を5 block 実行した。
120 fresh process すべてで完全な shape / entry が独立 oracle と一致した。

| Case | Input shape / order | 反復 | Before median ms | After median ms | Before / after | 改善 block |
|---|---|---:|---:|---:|---:|---:|
| scalar | `[] / []` | 10,000 | 1.806 | 1.814 | 0.995× | 2/5 |
| zero | `[3,0,5] / [2,0,1]` | 10,000 | 4.043 | 4.463 | 0.906× | 3/5 |
| tiny | `[2,3] / [1,0]` | 10,000 | 15.327 | 13.630 | 1.124× | 5/5 |
| rectangular rank 3 | `[3,4,5] / [2,0,1]` | 3,000 | 99.964 | 30.713 | 3.255× | 5/5 |
| rank 5 | `[3,3,3,3,3] / [4,2,0,3,1]` | 500 | 246.472 | 27.772 | 8.875× | 5/5 |
| identity rank 3 | `[3,4,5] / [0,1,2]` | 3,000 | 98.769 | 31.026 | 3.183× | 5/5 |

この固定条件では tiny を含む非空・非scalarの4件が全 block で改善した。
scalar / zero は数 ms の process duration のばらつきが大きく、改善を主張しない。
zero の median は遅くなったが block の方向が一致せず、一般的な退行率ともみなさない。
採用根拠は大きい permutation の反復 flat lookup を除いた4条件の比較である。

測定範囲は fresh process の起動、入力構築、独立期待値の構築、全反復、全結果比較、
JSON 出力を含む。コンパイルは含まない。`Int32` entry の relocation を対象とし、
正確有理数の算術速度や geometry 全体の速度を測ったものではない。各反復の内部比較は
全 tensor equality。driver はさらに Python の `itertools.product` と独立した
mixed-radix offset で求めた完全な shape / entries と、各 process の出力を照合する。
checksum だけの比較は使っていない。

## 厳密検査

- native、wasm-gc、JS の各 release で `--deny-warn -j 1`：それぞれ12 test block 成功。
- 既存の独立 array-index oracle：rank 0–3 の全40 shape、184 shape/permutation、
  contraction / mode product / product、error precedence、非整数有理数を維持。
- 追加した rank 3–5 の非等方・size-one・zero shape の全390 permutation で、
  shape と全 entry を独立 array oracle と照合。
- 非Eq の関数 entry を `[2,3,1]` の全6 permutation で照合。
- 既存の contraction / mode product の recording semiring による callback 順序検査も成功。
- scoped native `moon check --deny-warn`、`moon info`、`moon fmt --check` 成功。
  `src/tensor/pkg.generated.mbti` と CLI の生成 interface は基準 commit と byte 一致。
- 全 repo の purity gate：382 production kernel files 成功。

新しい test は permutation に対する独立した添字ループと非Eq entry の境界を検査する。
参照木の helper を呼んでその結果を期待値にする検査はない。これは有限の厳密な回帰検査で
あり、任意 rank に対する形式証明や compiler の検証ではない。

validation の最初の `moon info --deny-warn` は現 SDK がその option を受け付けず終了した。
`moon check` と各 backend test で warning を禁止済みの状態で、対応する `moon info`
command に修正して成功した。失敗した invocation も raw record に残した。

## 保存物と再現

[測定ディレクトリ](../measurements/tensor-kernel-20261118/) に以下を保存した。

- `abba.json`：全120 process の生 ns、stdout/stderr、完全結果、block ratio、range。
- `baseline.exe` / `candidate.exe`：比較した native ELF。
- `baseline-source.tar.gz` / `candidate-source.tar.gz`：`moon.mod`、`tools/moon`、全 `.mbt` と
  `moon.pkg` の凍結 source。compiled source の差分は `tensor.mbt` と新規 `permutation.mbt` のみ。
- `*-provenance.json`：全 source SHA-256、compiler version、ELF SHA、ビルド command。
  同一 harness の SHA と compiler version は driver が検査する。
- `*-build.txt`、`validation.json`、`environment.json`：build、全検査、API byte 比較、
  source hash、CPU/OS、C compiler、SDK binary hash。

```sh
python3 tools/tensor-kernel-freeze.py baseline
python3 tools/tensor-kernel-freeze.py candidate
tools/measure --cpu 4 python3 tools/tensor-kernel-compare.py \
  --baseline docs/measurements/tensor-kernel-20261118/baseline.exe \
  --candidate docs/measurements/tensor-kernel-20261118/candidate.exe \
  --output docs/measurements/tensor-kernel-20261118/abba.json
python3 tools/tensor-kernel-validate.py
```

freeze helper は baseline の production 2ファイルだけを一時的に復元して同じ canonical
harness を build し、`finally` で candidate source を戻す。baseline の全source archiveを
そのまま展開しても再buildできる。検査 helper は記録した source hash が一致する場合、
成功済みの invocation を再利用して途中から続ける。

全座標の materialization と逆順列による座標組み替えは残る。public `at` は従来通り
unary offset / flat Chain lookup。identity の専用 fast path や storage 変更も加えていない。
参照木による追加 allocation があり、memory 改善や大きい形状の stack 安全性は未測定。
本結果は固定 input、compiler、CPU に対する permutation の比較であり、他操作や利用側
package の改善率に広げない。

commit までをこの branch の到達点とし、統合・push・worktree / `_build` の片付けは
root が担当する。API 変更はなく、利用側 package の変更も不要。
