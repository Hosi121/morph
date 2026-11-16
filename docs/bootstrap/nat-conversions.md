# Natを直接処理する共有基礎

[ドキュメント](../README.md) / [探索・改善記録](README.md)

ユーザー監査の`fppoly/irreducibility.mbt`二箇所と`cyclotomic/cyclotomic.mbt`では、
floor(n/2)のためにNat→Binary→Natを作っていた。
この経路を`core.half_nat`へ置き換えた。

最初は`halve_nat(n)`でSuccを二つずつ消費して商へ一つずつ積む方式を共有化した。
その後、[末尾共有](nat-tail-sharing.md)へ進め、商のSuccの新規構築も省いた。
同じNat上をfastは二つずつ、slowは一つずつ進み、slowの既存tailを返す。
Binary.from_natはこの二進分割を経て、現在は[8進単位の末尾共有](nat-radix-grouping.md)で
一度に三bitを作る。半分化だけが必要な経路は引き続きCore helperを使う。
いずれもBigIntも組み込み整数も必要ない。
商の値だけなら`half_nat`を呼び、Boolが必要なら`halve_nat`を呼ぶ。
どちらも末尾再帰なので、ユーザー例の自然な再帰式と同じ値を継続stackを増やさず返す。

2冪判定もNat自身の半分化で実施する。円分体の構成と厳密FFTのplanで利用し、
FFT長の検査だけのためのUnit列や、判定用の二進表現を作らない。
FFTの根の指数・有理数の分母に必要なBinaryは計算境界で一度だけ作り、共有する。

Core・Binary・円分体・厳密FFT・Fp多項式、計67テストをnative/JS/Wasm GCで検査した。
0〜4096の半分化と余りを整数oracleに照合し、Nat200001の末尾再帰も実行した。
Leanモデルでは任意のnに対する商余りの保存とfloor(n/2)の一致を検査する。
モデルからMoonBitへの構造対応は人手のレビューであり、コンパイラの正しさは証明しない。

同一native releaseの実行ファイル・CPU4・入力構築除外で、64の半分化はBinary往復
1.41±0.06 µsから直接処理0.499±0.041 µs、4096は67.70±2.59 µsから
22.72±1.62 µsだった。各10標本。これはこの操作単体の比較で、既約性検査全体の速度比ではない。
生ログは[direct-nat-half-native.txt](../measurements/direct-nat-half-native.txt)。

呼び出し状況は[静的一覧](../CALL_PATHS.md)へ記録する。
`core.gcd`と`interleave`は内部利用がない公開APIで、削除も不自然な強制利用もしない。
`runbinary`は別の表現を持つ独立実装で、通常Binaryの既定backendにしたとは扱わない。
`binary.karatsuba`は平方根・Fibonacciから実際に利用される。
`binary.stein_gcd`は小さい有理数の約分に接続した。

直接の数値変換往復は保守ゲートで検出する。ID cacheや圧縮表現の明示的展開は
異なる役割を持つため、`to_nat`という名前だけで一括削除しない。
