# 大きい語の除算・剰余の追加探索（通常経路へ未採用）

基準sourceは`0ccff36`。source制約を維持したBool/Chain/ADTの試作である。
`pair(Nat20000, zero)`は2^20000を表し、通常remainder(...,3)はJSで
RangeErrorになった。これは数学的な値のモデルでは検出できない資源上の制約である。
現在の通常除算にはこの長さの制約が残る。以下の成功をproductionの成果と混同しない。

逆順の入力をtail loopで処理する案では、全小整数と2^20000の商・余りが
native/JS/Wasm GCで一致した。入力反転と末尾再帰でstackを避ける一方、
native剰余128/3は4.59→5.10 µs、4096/3は145.73→155.83 µsと悪化した。
四/八nodeの単純unroll、一定再帰prefix、raw Bool列state、有限形状によるdispatchも比較したが、
剰余の共通cohortでの回帰を除去できず、通常経路の置換は見送った。
商を返す経路には短縮例もあるが、上位と全backendの採用判定までは完了していない。

nativeのownership/RC生成とリストの追加構築が影響する。
式が同じ値を返すこと、stackが深くならないこと、同backendで速いことは別の判定である。
`formal/Fold.lean`は任意の型・state・stepに対する
reverse→left foldと従来right foldの一致、四node単位、有限prefixの全称定理を検査する。
Core.reverse/反転accumulatorは同じ構造を持つ。これは除算全体の数値的な正しさや
MoonBitへのrefinement/コンパイラ/資源上限の証明ではない。

このディレクトリは履歴を再現する実験用で、通常srcのpackageには含めない。
再現時は専用worktreeを`0ccff36`から作り、このディレクトリの`*_wbtest.mbt`を
その`src/binary/`へコピーし、rootと同じ隔離SDKを設定する。
`tools/moon test src/binary/wide_trial_wbtest.mbt --target js`などを使う。
`moon test -f`はtest名のfilterであり、benchのfile指定とは意味が違う。
0 testsは検査成功の証拠にしない。測定は共通`tools/measure --cpu 4`を通す。

生ログはdocs/measurements/wide-*.txt。計測の基準時刻・sourceと現在の最終snapshotは異なる。
