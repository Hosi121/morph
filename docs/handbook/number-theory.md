# 数論と有限体

[ハンドブック](../../HANDBOOK.md) / [ドキュメント](../README.md)

合同式を扱う基礎から、検査済みの素数・多項式・拡大体へ進む。

各節の検証例は実装時の記録。横断検証と証明の範囲は[検証ガイド](../VALIDATION.md)を参照。

## この章の内容

- [剰余算術と拡張Euclid](#modular)
- [一般化された中国剰余定理](#crt)
- [有限体の平方根](#square-roots)
- [楕円曲線](#elliptic)
- [RSAの小さな構成例](#rsa)
- [素数証明と因数分解](#certificates)
- [検査済みの素数から拡大体へ](#extension-fields)

<a id="modular"></a>

## 剰余算術と拡張Euclid

**入口:** [modular](../../src/modular)

Modulus は1より大きい Binary を保持する。合成数も許可し、素数と型名だけで決めつけない。
剰余加減乗算、乗算ごとに還元する平方反復累乗、Bezout 係数を返す拡張 GCD、
互いに素な場合だけ返る逆元、厳密な試し割り素数判定を実装した。
符号付き Bezout 係数には exact.Integer を使う。

法2..31、入力0..39の全組合せを整数演算と比較し、逆元の有無を全候補探索で確認。
小さい指数の剰余累乗、0..39の全組の Bezout 等式、0..255の素数判定を検証した。
試し割りは平方根までの候補を数値ライブラリなしで走査するため、小規模向け。

参考：[Handbook of Applied Cryptography, Chapter 14](https://cacr.uwaterloo.ca/hac/about/chap14.pdf)
は多倍長剰余算術、GCD、累乗の標準的な構成をまとめている。

<a id="crt"></a>

## 一般化された中国剰余定理

**入口:** [modular](../../src/modular)

既存の拡張 Euclid と符号付き整数を組み合わせ、法が互いに素でない場合も扱う CRT を実装。
差が GCD で割り切れる場合だけ解があり、結果は LCM を法とする一意の合同類になる。
負の差も符号付き係数で処理し、最後に正の剰余へ戻す。
法1を Modulus の型から除いているので、空の制約列は None とする。

法2..12、全剰余の組を、0..m*nの全探索と比較した。
解の有無、最小非負解、結果の法、左右を入れ替えた同値性を確認。
2 mod 3、3 mod 5、2 mod 7 から23を得る多段合成も検証した。

<a id="square-roots"></a>

## 有限体の平方根

**入口:** [finitefield](../../src/finitefield)

Fieldは奇素数pを検査して作り、`p-1=q*2^s` の奇数部分qとNatのs、二次非剰余を保存する。
Euler判定で0・二次剰余・非剰余を区別し、Tonelli–Shanksで平方根を求める。
補正ループは残る2冪位数の指数を真に小さくし、二進の平方反復と剰余積だけで進む。
最後に二乗して入力と一致することを確認し、二つの根のうち小さい方を返す。

128未満の全奇素数について、0..2p-1の全入力を全候補の整数二乗と比較した。
`65537-1=2^16` の体でも、非自明な補正が必要な平方と非剰余を確認した。
標数2と合成数は入口で拒否する。素数検査は試し割り、非剰余探索は決定的な逐次探索であり、
巨大な暗号用素数を入力するための構築コストや定数時間性は備えていない。

アルゴリズムと不変条件の参考：[FLINTのmod p平方根](https://flintlib.org/doc/algorithms/number-theory/sqrt-mod-p.html)。

<a id="elliptic"></a>

## 楕円曲線

**入口:** [elliptic](../../src/elliptic)

奇素数体の上で `y²=x³+ax+b` を扱い、標数>3と `4a³+27b² != 0` を入口で確認する。
座標の観察用ADTは Infinity/Affine(x,y)、実際のPointは曲線と検査済み座標を隠して持つ。
異なる曲線の点は加算できない。範囲外の座標は暗黙に丸めず拒否する。
逆元はyの符号反転。加算と倍算は傾きの有理式を体の逆元で計算し、
垂直線とy=0の倍算は無限遠点になる。結果も曲線上にあることを検査する。

スカラーはBinaryの桁を再帰で読み、double-and-addを行う。
圧縮はxとyの偶奇だけを保存し、復元にはTonelli–Shanksを使う。
y=0に奇数側を要求した場合や、xに対応する平方根がない場合も拒否する。
これはADTの符号であり、SEC規格のoctet列の直列化ではない。

p=5,7,11,13の全328非特異曲線について、全点を列挙し、全点対の加算を整数演算と比較した。
全点の圧縮往復、逆元、全xと偶奇の復元判定も確認。
p=17,a=b=2の19点の群では全19³=6859組の結合則、
逐次加算とスカラー倍の一致、2^200+17のスカラーの位数による還元を確認した。
小さな鍵交換の代数例では、5*(7*G)と7*(5*G)が同じ点(10,11)になった。

試し割りによる体の構築、affine逆元、可変な実行経路を持つ教材用の群演算である。
標準暗号曲線のパラメータ・部分群検査・鍵生成・定数時間性を備えた暗号実装ではない。
演算式と圧縮の参考：[SEC 1 v2](https://www.secg.org/sec1-v2.pdf)。

<a id="rsa"></a>

## RSAの小さな構成例

**入口:** [modular](../../src/modular)

異なる二素数 p,q を試し割りで確認し、phi=(p−1)(q−1)、e の逆元 d を作る。
平文・暗号文の代表元を法未満に限定し、暗号化と復号は剰余累乗だけで構成する。
p=11,q=13,e=7 では d=103。全143代表元を往復し、pやqと互いに素でないメッセージも含めて検証した。
合成数、同じ素数、逆元がない指数、指数1、範囲外の代表元は拒否する。

これは [RSA 原論文](https://people.csail.mit.edu/rivest/Rsapaper.pdf) の算術部分を試す実装。
padding、乱数による鍵生成、秘密情報の保護、定時間性は備えていない。
通信の安全性を提供する製品実装として扱わない。

<a id="certificates"></a>

## 素数証明と因数分解

[primality](../../src/primality)はLucas/Pratt・部分Pocklingtonの証明と合成数の証拠を検査する。
[factor](../../src/factor)の燃料付きPollard rhoと、[primeprove](../../src/primeprove)の再帰証明生成を組み合わせる。
探索が燃料内に終わらない状態、因子が見つかった状態、素数性を証明できた状態は別の結果として扱う。
Miller–Rabinを通過したことだけで素数の証明に置き換えない。

詳細: [証拠の設計](../bootstrap/number-theory.md) · [証明生成と再開](../bootstrap/primeprove.md)

<a id="extension-fields"></a>

## 検査済みの素数から拡大体へ

[primefield](../../src/primefield)で検査済みの素数からGF(p)を構成し、
[fppoly](../../src/fppoly)で多項式算術・Berlekamp分解・既約性検査を行う。
[galois](../../src/galois)は既約多項式による商としてGF(p^m)を構成し、traceとnormも計算する。
[discretelog](../../src/discretelog)はbaby-step giant-step、位数の証拠、部分群の境界を扱う。

詳細: [素数体](../bootstrap/primefield.md) · [多項式と拡大体](../bootstrap/finitefields.md) · [離散対数](../bootstrap/discretelog.md)
