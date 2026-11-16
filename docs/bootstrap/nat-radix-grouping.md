# Natから三bitずつBinaryを作る

[ドキュメント](../README.md) / [探索・改善記録](README.md)

Natの値とcanonicalなBinaryを保ち、変換で作り直す中間Natと走査を減らす。
前段の[二進分割の末尾共有](nat-tail-sharing.md)から、商を既存tailとして返す設計を引き継いだ。
通常の`binary.from_nat`は0/1を既存factoryへ返し、それ以外をprivateの
`from_nat_grouped`へ委譲する。Coreの半分化は引き続きFp既約性・円分体・2冪判定から使う。

## 採用した構造

二つのcursorを同じNatから始め、fastを八つ、slowを七つずつ進める。
fastが0〜7へ達したら、その余りだけslowを進めたtailを商として返す。
商のSuccを新たに作らず、商へ再帰して一度に三bitを付ける。
最上位の余分なfalseは既存`low_bit`で省く。計算核はNat/Chain/Boolと不変ADTの分岐・再帰だけである。
数値literal、機械整数、配列、可変状態、FFIはtests/tools以外へ導入していない。

4/8/16進×商の共有/再構築の六候補を、Pythonから純ADTのMoonBitへ生成した。
4096で8進共有が安定して速く、16進は分岐が大きく同条件では改善しなかった。
100000の初回だけは16進再構築が8進共有より少し速い標本もあったが、
別の同ELF比較で逆転したため、この小差を採用理由にしない。
初回探索は[nat-radix-first.txt](../measurements/nat-radix-first.txt)に残す。

nativeだけを見ると小値0/1の保護分岐は不要に見えたが、Wasm GCの短い標本では数nsの回帰が出た。
公開wrapperに0/1の分岐を置き、両候補のfactoryをmain `66f48ae`の共有定数へ揃えた。
短すぎる標本を128回のbatchでも測り、cacheとwrapperを含む採用形を比較した。
初期案の採否を後から言い換えず、unguarded→inner-guard→wrapper→cachedのログを別々に保存する。

## 同条件の比較

CPU6、release、入力構築を除外、各10標本。同じbackendの一つの実行artifact内で、
保存した旧`shared_nat_binary`と公開wrapperと同形の`protected_nat_binary`を比較した。
両候補でfactory/cacheのsourceは共通。基準環境は`d76b5a0`で、
このcommitはfactory二つとconstantsだけをmain `66f48ae`へ揃えたもの。
除算など並行作業の変更は混ぜていない。

| backend | 入力 | 旧二進共有 | 新8進共有とwrapper |
| --- | ---: | ---: | ---: |
| native | 4096 | 9.60±0.26 µs | 6.23±0.21 µs |
| native | 100000 | 252.32±5.86 µs | 159.98±5.71 µs |
| JS | 4096 | 9.39±0.17 µs | 5.90±0.31 µs |
| JS | 100000 | 331.64±18.45 µs | 225.83±7.04 µs |
| Wasm GC | 4096 | 8.11±0.28 µs | 5.07±0.20 µs |
| Wasm GC | 100000 | 233.36±7.10 µs | 132.77±3.25 µs |

| 128回batch | 旧0→新0 | 旧1→新1 |
| --- | ---: | ---: |
| native | 1.19→0.878 µs | 2.52→0.944 µs |
| JS | 1.39→1.06 µs | 2.13→1.04 µs |
| Wasm GC | 0.990→0.737 µs | 1.69→0.755 µs |

Wasmの単発0は6.90±0.34→7.16±0.40 nsで差を判定せず、長いbatchと合わせて回帰なしと判断した。
batch値は128回の総時間であり、一回の値と直接比較しない。
外部load/周波数で絶対時間が大きく動いたため、異なる実行間の値を速度比の根拠にしない。
この結果を円分体・既約性など上位処理全体の速度比へ広げない。

最終ログ：[native](../measurements/nat-radix-cached-native.txt)、
[JS](../measurements/nat-radix-cached-js.txt)、[Wasm GC](../measurements/nat-radix-cached-wasm-gc.txt)。
artifactのSHA256とSDKは[nat-radix-artifacts.json](../measurements/nat-radix-artifacts.json)。
凍結artifactはrootの`.tools/artifacts/nat-radix-20261116`へ移し、作業用worktreeと分離した。

## 値・停止性・正規性の確認

三backendでBinaryの25 testsを実行した。候補全体を0〜1024と大きい境界値で独立整数oracleへ照合し、
採用helperの商・三つの低bitは0〜4096で商余りを直接照合した。
8進境界の前後とNat200001はcanonicalなBinaryそのものを比較する。
[実行ログ](../measurements/nat-radix-production-tests.txt)は有限実行証拠である。

Leanは任意のfast≤slowについて`8*q+r=8*slow−7*fast`、任意のnについて`8*q+r=n`、
正のnについて`q<n`を示す。`lowBit`の値と正規性を別々に示し、
`fromNat`の全自然数に対する値とcanonical性を導いた。旧二進モデルとCoreの半分化の定理も維持した。
factoryのglobal→helper→public aliasも写し、zero_sound/one_soundを公理なしで示した。
公理出力・source対応・翻訳境界は[formalレビュー](../../formal/REVIEW-nat-grouped.md)。

source lockを19領域へ広げ、low_bit、split/helper、zero/one、canonical helpers、不変globalのinitializerも含めた。
不正な余り・低bitの破棄・cached oneの変更はgateが拒否する。
Leanの不正余りは値の証明を壊し、値が同じでも高位0を残す変更はcanonical性の証明を壊す。
[negative controls](../measurements/nat-radix-negative-controls.txt)は一時コピーだけで実施した。
MoonBitへの翻訳、物理的なtail共有や割当、全入力のstack/heap上限、コンパイラの正しさは証明していない。

## 統合と追試

共有branchへ触れないため、専有treeではpublic wrapperをWBへ固定し、helper・モデル・lockを渡す。
統合担当は通常経路を次に置き換える。

```moonbit
pub fn from_nat(n : @core.Nat) -> Binary {
  match n {
    Zero => zero()
    Succ(Zero) => one()
    _ => from_nat_grouped(n)
  }
}
```

wrapperを適用した後、このcommitで検査済みのLeanモデルとの分岐対応とMoonBitの検査を確認する。
`check_model_drift.py --record`を行い、その後は通常の`tools/check_formal`で全モデルとlockを再検査する。
model自体を変えた場合は、先にLeanを直接実行して証明を検査する。CALL_PATHSも再生成する。新helperの未使用warningはwrapperの接続で消える。
公開の`.mbti`は変わらない。次の各コマンドはCPU/lockを共通にして実行する。

```sh
/home/hosi/morph/tools/measure --cpu 6 tools/check_formal
/home/hosi/morph/tools/measure --cpu 6 .tools/moon/bin/moon test --target native --release -p Hosi121/morph/binary
/home/hosi/morph/tools/measure --cpu 6 .tools/moon/bin/moon bench --target native --release -p Hosi121/morph/binary -f from_nat_grouped_wbtest.mbt
python3 tools/generate_nat_radix.py --check
```

JS/Wasm GCはtargetだけを変える。通常wrapperの接続後は、WB候補との値の一致と上位経路を統合担当が再確認する。
