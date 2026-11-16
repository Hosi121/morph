# GF(256) からのAES bootstrap

[ドキュメント](../README.md) / [探索・改善記録](README.md)

仕様は [FIPS 197-upd1 (2023)](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.197-upd1.pdf)。
公式中間値はNISTの [例示値一覧](https://csrc.nist.gov/projects/cryptographic-standards-and-guidelines/example-values) から取得した
[AES-128](https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Standards-and-Guidelines/documents/examples/AES_Core128.pdf)、
[AES-192](https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Standards-and-Guidelines/documents/examples/AES_Core192.pdf)、
[AES-256](https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Standards-and-Guidelines/documents/examples/AES_Core256.pdf) を用いる。

## 固定ADTとGF(256)

`Octet` は8個のBoolを持つ固定recordで、LSBから多項式の係数に対応する。
`octet` は8bitの列だけを受理し、`from_binary` は256未満に限る。
`Block` は `Four[Four[Octet]]`。入力・出力の16 octetはFIPSの**列優先**順で扱う。
`block` は16個以外を拒否し、`octets` で元の順に読み出せる。

法は `x^8+x^4+x^3+x+1`。`xtime` は最高位の係数をこの法で還元する固定Boolean回路、
`multiply` は8bitの構造的再帰によるcarryless積。
`to_galois`・`from_galois` を通して、この特化演算とチェック済み `galois` 体の意味を照合できる。
別の提示の体の元は `from_galois` が拒否する。

## S-boxと基本変換

`tables()` はまず `primefield`・`fppoly` の既約性証拠・`galois` からAESの体を構築する。
全256入力について体の逆元（ゼロはゼロ）とFIPSのアフィン写像を計算し、
`trie` の不変辞書へforwardとinverseを登録する。重複出力は構築時に拒否する。
**核に手貼りのS-box表は存在しない**。

`calculate_sbox` が代数的計算、`sbox`・`inverse_sbox` が生成済みの不変cacheを使う入口。
`Tables` を保持して複数の状態や鍵へ共有できる。可変の大域cacheは置かない。

`sub_bytes` と逆変換、`shift_rows` と逆変換、`mix_columns` と逆変換、`add_round_key` を公開する。
MixColumnsはxtime/XORで構成し、逆変換はpreconditioning後の同じ前向き行列を使う。
独立テストではFIPSの逆行列を直接計算するため、正逆を同じ誤りで相殺しただけでは合格しない。

## 公式データと独立検証

最初の完成単位は7テスト。2026-11-15、MoonBit v0.10.20のWasm GC・JS・nativeすべてで成功。

- FIPS Table 4 / Table 6の正逆S-box全256値。
  期待値は公式PDFから抽出した検証データであり、実装の入力表ではない。
- 各鍵長の4ブロック、合計12ブロックに対する**420個の公式中間変換**。
  SubBytes・ShiftRows・MixColumnsの正逆を、各段の公開された入力・出力で個別検査。
- 全65,536個の積・XORを機械整数のcarryless oracleと照合。
- 全256 octet×8基底、計2,048積を `galois.multiply` と照合し、表現の往復も確認。
- 128個の状態基底bitと48個の混合状態で、正逆行列・列優先順・逆変換を独立検算。
- 不正なoctet/block長、範囲外のBinary、他の体の混合を拒否。

```sh
python3 tools/generate_aes.py
tools/moon fmt --check src/aes
tools/moon check --deny-warn src/aes
tools/moon test src/aes --target wasm-gc
tools/moon test src/aes --target js
tools/moon test src/aes --target native
python3 tools/audit_purity.py
tools/moon info src/aes
```

再生成時に整形が必要なら `tools/moon fmt src/aes` を実行する。
公式入力のURLとPDFのSHA-256は `src/aes/nist.json` と生成器に記録した。
FIPS PDFのdigestは `62c86eb567f13edb8f71826e985da870b04ef6381634f303cdb16e84d47becd1`。
生成器の通常実行は標準Pythonだけで動く。

公式PDFから再抽出する場合は、4個のPDFを同名で一つのdirectoryへ置き、
`python3 tools/generate_aes.py --import-nist <directory>` を使う。この再抽出だけは `pypdf` が必要。
digestを検査してから表・中間状態を抽出する。Core PDFは文字の配置順が内容stream順と異なる箇所があるため、
layout抽出を使い、全round・全block・鍵との整合も検査する。

## 主張の範囲

純ADTの代数的構成と公式値への一致を確かめる実験である。
constant-time、鍵の安全な消去、サイドチャネル耐性、FIPS認証、製品用暗号実装の性質は主張しない。
ランタイムやcache探索の時間・allocationにも依存する。
外部プロトコル、モード、padding、認証はこの基本変換の範囲に含めない。

## AES-128/192/256の鍵展開とblock暗号

`cipher(tables, key_octets)` は16・24・32 octetの鍵だけを受理する。
`KeySize` はそれぞれ `Aes128`・`Aes192`・`Aes256`、round数は10・12・14。
`round_keys` は順序付きの不変Block列、`rounds`・`key_size` がその種別を返す。

鍵展開はNk個のwordを保持する不変の小さいqueueを使い、前のwordとNk個前のwordから次のwordを作る。
周期の先頭ではRotWord・生成S-box・Rconを使い、AES-256の周期位置4では追加のSubWordを行う。
Rcon自身も `one` と `xtime` から構成し、表を貼り付けない。
AES-192のround境界とNk-word境界がずれる場合も、52wordすべてを構成してからBlockへまとめる。

`encrypt(cipher, block)` と `decrypt(cipher, block)` は単一の128bit Blockを扱う。
暗号化は最初のAddRoundKey、通常round、MixColumnsを省いた最終roundを構成する。
復号は同じround key列を逆順に使う通常のInvCipher。
cache・鍵展開結果とも不変で、再利用時に内部状態は更新しない。

## 完成単位の追加検証

追加後は14テストがWasm GC・JS・nativeすべてで成功した。上の検証コマンドはそのまま使える。

- 公式12ブロックの**全576中間状態**を実際の展開鍵を使って検査し、最終暗号化・復号も照合。
- NISTが示すAddRoundKey前後の状態のXORから、公式round keyを独立に復元。
  4ブロックで同じ鍵列になることを抽出時に検査し、3鍵長の**全156word（624 octet）**を比較。
- 別実装のOpenSSLから、各鍵長36例、計108個のblock暗号化・復号fixtureを作成。
  ゼロ、全FF、連番、固定seedの32個の任意鍵・平文を含む。
  同じ核での往復だけを正しさのoracleには使わない。
- 0〜40 octetの不正鍵長すべて、さらに64・65・256 octetを拒否。
  同じCipherの再利用で展開鍵が変わらないことも検査。

OpenSSL oracleは `OpenSSL 3.0.13 30 Jan 2024`、seed `202611153`。
`src/aes/openssl.json` にコマンド・version・入力・出力を保持する。
通常の生成器は保存済みfixtureを使い、OpenSSLへ依存しない。
外部oracleを再計算する場合だけ、次を使う。

```sh
python3 tools/generate_aes.py --refresh-openssl
tools/moon fmt src/aes
```

生成器はローカルのOpenSSLへ、公開fixture用の鍵と1ブロックを渡す。
ECBの単一ブロック・saltなし・paddingなしで暗号化し、外部復号でも平文へ戻ることを確認する。
これはblock primitiveの検証方法であり、本パッケージがECBなどのモードAPIを提供するという意味ではない。
公式PDFの再抽出、保存データからの再生成、外部oracleの更新を別々に行える。
