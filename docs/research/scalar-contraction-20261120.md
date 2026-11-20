# スカラー縮約のrank 4展開を省く

通常経路は`src/statgeometry/tensors.mbt`の`scalar_by_contraction`。基準`2115681`、変更`919b06f`。
基準は`fe4a754`へ照合用の旧経路と固定benchmarkを加えただけで、本体は同じである。

## 数学的な縮約をそのまま実行する

以前は逆計量gⁱʲとRicciテンソルRₖₗの全直積を作り、i=k、j=lで二回縮約していた。
最終結果はΣᵢⱼ gⁱʲRᵢⱼなので、既存`Tensor.zip`で対応成分を掛け、既存`core.fold_left`で和を取れる。
係数の積はn⁴回からn²回、縮約の加算はn³+n回からn²回へ減る。rank 4の積と二回の縮約結果を保持しない。

これは固定された厳密有理数の結合則・可換性による変更である。汎用Semiringのcallback順序を変更する規則ではない。
逆計量、Ricciの順でTensorへ変換・shape検査する部分はbyte一致で保った。零次元では空和が0になる。
`riemann.scalar_curvature`のキャッシュを読まず、逆計量とRicciから独立して再計算する。

新しい公開API・型・package・production helper・importは0。statgeometry本体6ファイルは1,387→1,384物理行、
code行は1,149→1,146。code行は`line.split('//',1)[0].strip()`が非空の行で括弧も含み、tests・CLI・生成interfaceは除く。
公開interfaceとimportはbyte一致。旧計算は本体と分離したwhitebox参照としてそのまま保存した。

## 固定条件の比較

native release、CPU4、同一SDK、事前に固定した4入力・反復数・5ABBAで計80プロセス。
両版でCLIソースはbyte一致。コンパイルを除き、起動・曲率の一度の準備・全反復・厳密照合・出力を測る。
各反復で単体の独立な公式scalar=n(n−1)/4と完全一致を検査し、PythonのFractionでも出力全体を復号する。

| 入力 | 反復 | 前 median ms | 後 median ms | 前/後 | 改善block | peak RSS中央値 KiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| scalar0 | 32,768 | 14.675 | 6.386 | 2.298 | 5/5 | 2,048 → 2,048 |
| scalar3 | 8,192 | 160.985 | 28.793 | 5.591 | 5/5 | 2,176 → 2,176 |
| scalar5 | 2,048 | 480.499 | 41.456 | 11.591 | 5/5 | 2,560 → 2,304 |
| cached5 | 2,048 | 8.136 | 8.400 | 0.969 | 3/5 | 2,304 → 2,304 |

[全試行・stdout・ELF/SDK/source hash](../measurements/scalar-contraction-20261120.json)を保存し、source manifestは両Git treeと照合した。
キャッシュ値のgetterは未変更の対照で、blockごとに増減し中央値では約3%遅い。対照の小差を退行・改善と断定しない。
5次元のpeak RSSは256 KiB減ったが、これは曲率準備とruntimeも含むプロセス全体であり、縮約単独の保持量・確保総量ではない。
3次元と零次元のRSSは同じ。JS・Wasmの速度や、全モデルで同じ倍率になることは未確認である。
2026-11-18の積と二回縮約のbenchmarkや、同日のTensor内積融合とは別系列で、倍率を合成しない。

[固定したrunner](../measurements/scalar-contraction-20261120-runner.py)は`tools/measure --cpu 4`で実行する。
再実行には両commitのnative release CLIを`.tools/scalar-contraction/{before,after}.exe`へ用意し、
基準checkoutを`/home/hosi/morph-contraction-before`へ置く。`.tools/scalar-contraction/task.json`の`cases`を
`{"scalar0":32768,"scalar3":8192,"scalar5":2048,"cached5":2048}`とする。通常の検査では過去の計測を再実行しない。

## 検証と残る範囲

旧rank 4経路は関数本体をそのままwhitebox参照へ保存し、新経路と照合する。
零・1・2・3次元の単体に加え、非対角の正定値計量と不定値計量を確認した。
後者はg(x)=exp(2φ(x))Hの有理2-jet、grad φ=0、Hess φ=diag(1/2,1/3)で、
2次元の独立な公式scalar=−2 trace(H⁻¹ Hess φ)から−5/4と−4/15を得る。
既存の非線形確率族・Gaussian・SymPy独立fixtureも維持する。

汎用Tensor.product/contract、Tensor.zipの一時ペア列、denseなCurvature自体の格納は維持している。
今回省いたのは、既にある逆計量とRicciからscalarだけを求める際の不要なrank 4展開である。

固定ソース`2d45adc`を基準`fe4a754`と比較し、逆依存4packageのうち3packageを3targetで実行して各142件成功した。
残る1CLIはソースとnative metadataからtest不在を確認した。global型検査・85 Pythonテスト・純粋性396ファイル・既存形式モデルも成功。
[固定checkpoint・全コマンド・ログ・APIと構造の照合](../measurements/scalar-contraction-20261120-validation.json)を保存した。
有限照合と既存形式モデルの成功を、任意の有理計量の新しい形式証明とは扱わない。
比較用worktreeは削除し、必要なELFと完全な生データを保存している。
