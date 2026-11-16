# 大きいbit列を比較するときのstackを減らす

通常Binaryの比較を、長さに比例する再帰のunwindから、有限の先頭処理とtail loopへ移す。
値、公開API、非canonicalな生のbit列に対する従来の振る舞いを保つ。
特に生の列は長さを優先し、上位0を除去しない。`Cons(false,Nil)`は`Nil`より大きいと返す。
canonicalなBinaryについては数値の順序と一致する。

## 採用する形

先頭八段は以前と同じ順序で結果を戻す有限の処理にし、その先は四nodeずつ消費するtail loopへ渡す。
loopは、すでに見た低位bitのorderingを持ち、より高位の相違があれば上書きする。
片方だけ先にNilへ着いたら、過去のorderingを無視して短い方をLessとする。
最初の八段の呼出し深さは固定で、その後のloopは語長に比例するunwindを作らない。

sourceは[comparison.mbt](../../src/binary/comparison.mbt)。数値型・数値literal・配列・可変状態・FFIは計算核へ導入していない。
候補と採用sourceは`tools/generate_comparison_candidates.py`から純ADTの静的な分岐・関数呼出しへ生成する。
`--check`で両方の生成結果を照合する。

単純な一node tail loopも正しいが、nativeで短語256対が旧2.53→3.02 µsへ回帰した。
生成Cでは旧再帰の引数にRC更新がなく、tail loopは開始時retainと各nodeのretain/releaseを行っていた。
global関数への移動と通常fnへの`#borrow(xs,ys)`も試したが、RC更新も速度も解消しなかった。
annotationは現SDKでエラー/無視warningなく受理されたが、採用した計算核へは入れていない。

2/4/8node単位の走査と、有限の先頭2/4/8段を比較した。
四nodeのgroupと八段の先頭処理で短語を保護した。
group helperが先頭分岐へ丸ごとinlineされるとnativeの中程度の語で遅くなったため、
SDKにもある`#inline(never)`でprivate helperの境界を保つ。
この属性もsource lockへ含め、変更をレビュー対象にした。値のモデルはinline方針に依存しない。

探索ログ：[一node](../measurements/comparison-initial-native.txt)、
[borrow/global](../measurements/comparison-borrow-native.txt)、
[group幅](../measurements/comparison-group-native.txt)、
[先頭段数](../measurements/comparison-protected-native.txt)。

## 同条件の比較

main `9fb8bce`から分離した専有tree、CPU6、release、入力構築を除外、各10標本。
同一backendの一つの実行artifactへ固定旧referenceと新helperを入れ、同じ入力で比較した。
別のprocess/backend間の絶対時間を倍率の根拠にしない。

| backend | 256対の短語cohort | 2048bit等値 | 2048bit dense相違 | 2048bit異幅 |
| --- | ---: | ---: | ---: | ---: |
| native | 2.53→2.28 µs | 6.47→3.59 µs | 5.04→3.42 µs | 5.32→3.46 µs |
| JS | 4.04→2.98 µs | 10.95→2.92 µs | 12.20→3.11 µs | 10.94→2.83 µs |
| Wasm GC | 2.78→2.45 µs | 5.45→3.37 µs | 4.62→3.39 µs | 4.65→3.53 µs |

全入力での高速化は主張しない。nativeの64bit高位相違は89.44±3.49→97.78±12.81 nsで、
小差とばらつきが残った。64bit異幅の旧値もばらつきが大きく、そこだけの速度改善は採用理由にしない。
JS/Wasm GCと2048bitの各cohort、短語全体での改善、20k bitのstack問題の解消を採否の根拠にした。
上位の除算・GCD・有理数など全体の速度比へは広げない。

最終ログ：[native](../measurements/comparison-noinline-native.txt)、
[JS](../measurements/comparison-noinline-js.txt)、[Wasm GC](../measurements/comparison-noinline-wasm-gc.txt)。
凍結artifactとSDKは[comparison-artifacts.json](../measurements/comparison-artifacts.json)。
rootの`.tools/artifacts/comparison-20261116`へ実行file、native C、source snapshotを保存した。

## 有限実行と全称モデル

三backendで次を確認した。

- canonicalな0〜255の全65536整数対を独立整数oracleと照合。
- 長さ0〜7の全255 raw列の全65025対を固定旧referenceと照合。
- 先頭8段とgroup4の境界、余りの長さ、非canonical形状を独立した高位→低位の配列oracleへ照合。
- 20000bitの等値・低位相違・高位相違・異幅・長い全0列を両方向で照合。

候補を含む5 testsがnative/JS/Wasm GCで通過した[ログ](../measurements/comparison-final-tests.txt)を残す。
別の一時testで、旧referenceの20000bit等値比較はJSのRangeErrorを実際に起こした。
これは[negative control](../measurements/comparison-old-stack-negative-js.txt)として保存し、通常suiteには失敗testを残していない。
`from_bits`や他の大語演算すべてのstack上限を解消したとは扱わない。

Leanは、任意の有限列と任意の過去orderingについて一node loopの不変式を示し、
group4が同じloopと等しいこと、先頭を有限段だけ旧式にしても旧referenceと等しいことを示す。
したがって最終helperの等価性は、非canonicalを含む全有限列が対象である。
canonicalな列では、`Less/Equal/Greater`がそれぞれ数値の`<` / `=` / `>`を意味することも別に示した。
有限のbit条件はgroup内の局所補題にだけ使い、全列の主張を有限長へ切り詰めていない。

モデルのaxiom出力・対応・限界は[formalレビュー](../../formal/REVIEW-comparison.md)。
新しいsource lockはhelper二つと旧compare_bits入口を足して22領域。
inline属性、長さ優先、渡すsuffixの向きを変えるとgateが拒否し、
不正なgroup内orderingはLeanの等価証明を壊す[negative control](../measurements/comparison-negative-controls.txt)も確認した。

## 通常経路への統合

共有branchへのwriteを分けるため、専有treeでは既存`binary.mbt`を変更していない。
統合担当は`compare_bits`のbodyだけを次へ置き換える。

```moonbit
fn compare_bits(xs : @core.Chain[Bool], ys : @core.Chain[Bool]) -> @core.Ordering {
  compare_bits_tail(xs, ys)
}
```

公開`compare`の署名と挙動は変わらない。wrapper適用後に対応とMoonBit検査を確認し、
`check_model_drift.py --record`後、通常の`tools/check_formal`で再検査する。
checkerはCoreに続けてBinary.oleanも毎回生成し、Comparisonが古いBinary artifactをimportしないようにした。

```sh
/home/hosi/morph/tools/measure --cpu 6 tools/check_formal
/home/hosi/morph/tools/measure --cpu 6 .tools/moon/bin/moon test --target native --release src/binary/comparison_wbtest.mbt src/binary/comparison_candidates_wbtest.mbt src/binary/comparison_boundaries_wbtest.mbt
/home/hosi/morph/tools/measure --cpu 6 .tools/moon/bin/moon bench --target native --release -p Hosi121/morph/binary -f comparison_wbtest.mbt
python3 tools/generate_comparison_candidates.py --check
```

JS/Wasm GCはtargetだけ変える。`moon test`のfile指定は位置引数、`moon bench`は`-f`を使う。
public入口の接続後の全体検査と上位経路の計測は統合担当の別の検査とする。
