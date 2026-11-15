# 検証環境

記録日：2026-11-15（JST）。ローカルの実測値であり、異なる環境の速度は保証しない。

| 項目 | 値 |
| --- | --- |
| CPU | Intel Core Ultra 7 255H、環境から見える16論理CPU |
| OS | Linux 6.6.87.2-microsoft-standard-WSL2、x86_64 |
| moon / moonrun | 0.1.20261104、940aa18 |
| moonc | v0.10.20+65efd5b93、2026-11-05 |
| backend | wasm-gc、js、native |
| Python | 3.12.3 |
| ベンチ | native、release、各10サンプル |

ツールチェーンはグローバルを書き換えず `.tools/moon` に置く。
`tools/bootstrap` は既定では公式のlatestを取得するため、後日の取得物がこの版と同じとは限らない。
今回取得したアーカイブのSHA-256は次の通り。

```text
moonbit-linux-x86_64.tar.gz
80d987523308fa490eba9f1baf98df996a5a7891e118357553b7c2608c0597c5

core-latest.tar.gz
8ec2a2c01335501d703867bb4eef5f92d3cd7e1ae1ee5f7f14d54d16d2c7c2b5
```

通常のテストはPython 3標準ライブラリと、このMoonBitツールチェーンで動く。
Mooncakesの追加依存はない。期待値のfixtureはコミット済み。
SymPyやNISTの原データは、fixtureを再生成するときだけ必要になる。

| 再生成スクリプト | 使用するオラクル・入力 |
| --- | --- |
| tools/generate_binary_math.py | Python任意精度整数、math.isqrt、math.gcd |
| tools/generate_sha256.py | hashlib、FIPS 180-4の定数 |
| tools/generate_nist_sha256.py | 引数にNISTのSHA256ShortMsg.rspを指定 |
| tools/generate_groebner.py | SymPy 1.14.0、QQのlex順既約基底 |
| tools/generate_simplex.py | fractions.Fractionによる二次元の頂点列挙 |

リポジトリのルートで実行し、その後 `tools/moon fmt` を実行する。
生成したfixtureの差分が出た場合は、期待値が変わった理由を確認してから採用する。
普段の `tools/check` は再生成・ネットワーク取得を行わない。
今回、この5スクリプトで再生成して整形した後、全MoonBitソースのhashが変更前と一致することも確認した。
