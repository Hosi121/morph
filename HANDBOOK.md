# 純記号アルゴリズム・ハンドブック

## 目的と実験の境界

2026-11-15、画像に示された12本の等式による FFT を出発点に、MoonBit の
ADT とパターンマッチだけでどこまで算法を構成できるか試す。
利用者はコードを読んで改造したい人。性能上の実益を後付けせず、表現と計算の関係を調べる。
今回の作業場所は `/home/hosi/morph`、区切りは同日22:00 JST。

「純記号」は**手書きのアルゴリズム本体**に組み込み数値型・数値リテラル・
数値演算・配列・可変状態を使わない、という操作可能な条件とする。
MoonBit のコンパイラ、GC、暗黙の prelude、テストランナーの内部まで排除する主張ではない。
`derive(Eq, Debug)` はテストと観察の補助であり数値計算への抜け道には使わない。
テスト側だけは Int、配列、ループを使い、別表現のオラクルと比較する。

## 開発環境

既存のグローバル環境は MoonBit v0.8.2。変更せず、公式配布を `.tools/moon` に隔離する。
`tools/moon` がこのツールチェーンを優先する。外部 Mooncakes 依存は追加しない。
設定は公式の現行 `moon.mod` / `moon.pkg` 形式を使う。

- [公式インストール](https://www.moonbitlang.com/download/)
- [モジュール設定](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html)
- [パッケージ設定](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html)

## 基盤：リストと Peano 自然数

`Chain[A] = Nil | Cons(A, Chain[A])`、`Nat = Zero | Succ(Nat)`。
長さや位置も Nat で表す。加算は Succ の移動、乗算は加算の再帰。
減算はゼロで飽和し、除算のゼロ除数は None で返す。Euclid の GCD も実装。

リストの逆順は蓄積引数を使う。連結の左側だけがコピーされ、右側は共有される。
この性質は、後の二進ワード連結や出力構築のコストを考えるうえで重要。
Peano 数は値に比例する空間を使うため、大きな演算の核には二進 Bool リストを導入する。

検証：小さい自然数の全組合せをテスト側の Int 演算と照合し、リストの分割・再結合、
逆順の involution、長さ不一致 zip、範囲外アクセスを確認する。
