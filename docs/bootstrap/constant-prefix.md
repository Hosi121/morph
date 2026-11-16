# 末尾を共有する定数prefix

[ドキュメント](../README.md) / [探索・改善記録](README.md)

`core.replicate_onto(n,value,tail)`は、既存tailへ同じ値をn回Consする。
末尾再帰一回で済み、`append(replicate(n,value),tail)`の構築と走査を融合する。
`core.replicate`もtail=Nilのwrapperへ変更し、Binaryのpairにも使う。
表現・リスト順序・公開関数の意味は維持する。

Leanのgeneric Chainモデルで、任意の要素型・n・末尾について元の式との一致を検査した。
新規の独自公理やsorryはない。
100000個のprefixとpair/unpairをnative/JS/Wasm GCで検査し、call stackに依存する旧再帰を避けた。

native release、CPU4固定、入力構築除外、同process、10標本：

| 長さ | 旧replicate→append | 一回prepend |
| --- | ---: | ---: |
| 4 | 77.86 ns | 51.15 ns |
| 256 | 5.41 µs | 2.36 µs |
| 8192 | 192.60 µs | 84.33 µs |

source上のConsと走査は減るが、Nativeの実heap allocation数はcompilerのreuseにも依存する。
この表を全algorithmの速度比へ外挿しない。

Karatsubaのshiftにも適用可能だが、初期の別関数コピーによる比較は外部loadや
コード生成差の影響が大きく、2048bitで悪化も見えたため、productionへの融合は保留する。
同じrecursive bodyへshift callbackだけを切り替える対照でも、2048bitは
25.51±1.48 msから24.57±1.48 msと範囲が重なった。
したがって上位Karatsubaの高速化を確認したとは扱わない。
公開Karatsubaのshiftはこの段階では既存の構成を維持する。

生ログ：`docs/measurements/constant-prefix-native.txt`、`constant-prefix-paired-native.txt`。
原子のsource lockは10領域へ拡大し、generic関数・Nat半分化と全Leanモデルの差分も検出する。
