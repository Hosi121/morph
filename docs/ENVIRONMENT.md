# 開発・検証環境

[ドキュメント](README.md) / [検証ガイド](VALIDATION.md)

## 準備と実行

MoonBit、Python 3、Bashを使います。通常のテストにMooncakesの追加依存はありません。
公式配布を取得する初回のbootstrapには、curl・tarとネットワーク接続が必要です。

```sh
tools/bootstrap
tools/moon version --all
tools/moon run src/cmd/main
```

`tools/bootstrap`はツールチェーンを`.tools/moon`へ配置します。
`tools/moon`はこのローカル版を優先し、存在しない場合はPATH上のmoonを使います。
bootstrapの既定値は公式のlatestです。後日の取得物が下記の検証済み版と同じになるとは限りません。

ツアーの[出力例](TOUR.txt)と[表示・入力変換の実装](../src/cmd/main)も参照してください。
`tools/moon run src/cmd/advanced` は実代数演算・数体・実解列挙・基底順序変換・μ-calculusをまとめて実行します。
[出力例](ADVANCED_TOUR.txt)はnative・JS・WasmGCで完全一致を確認しています。

## 開発時のコマンド

すべてリポジトリのルートで実行します。検査の対象と限界は[検証ガイド](VALIDATION.md)にまとめています。

| 用途 | コマンド |
| --- | --- |
| 文書のリンク・節・コードブロック | `python3 tools/check_docs.py` |
| 通常の横断検査 | `tools/check` |
| 特定パッケージ | `tools/moon test src/fft` |
| nativeの全テスト | `tools/moon test --target native` |
| native releaseのベンチ | `tools/moon bench src/benchmarks --target native --release` |
| 整形 | `tools/moon fmt` |

Leanは任意の検証用ツールです。Linux x86_64向けの準備と実行は次の通りです。

```sh
python3 tools/bootstrap_lean.py
tools/check_formal
```

モデルの定理・対応レビューは[形式検証](../formal/README.md)を参照してください。

## 生成ファイルを更新する

公開APIや集計表は、元のソースを変更した後に生成し直します。

```sh
tools/moon info
python3 tools/inventory.py
python3 tools/audit_paths.py --write
```

`pkg.generated.mbti`、[パッケージ一覧](INVENTORY.md)、[呼び出し経路](CALL_PATHS.md)は手編集しません。
`tools/check`で生成差分を検出します。

期待値のfixtureもコミット済みなので、通常のテストで再生成やネットワーク取得は行いません。
fixtureを更新するときだけ、対応するオラクルや原データを用意します。

| 生成器の例 | オラクル・入力 |
| --- | --- |
| [二進算術](../tools/generate_binary_math.py) | Python任意精度整数、math.isqrt、math.gcd |
| [SHA-256](../tools/generate_sha256.py) | hashlib、FIPS 180-4の定数 |
| [NIST SHA-256](../tools/generate_nist_sha256.py) | 引数にNISTのSHA256ShortMsg.rspを指定 |
| [Gröbner基底](../tools/generate_groebner.py) | SymPy 1.14.0、QQのlex順既約基底 |
| [単体法](../tools/generate_simplex.py) | fractions.Fractionによる二次元の頂点列挙 |

SymPyの版は[requirements-oracles.txt](../tools/requirements-oracles.txt)に固定しています。
生成後に`tools/moon fmt`を実行し、期待値の差分が出た理由を確認します。
そのほかの生成器は[tools](../tools)と各探索記録を参照してください。

## 2026-11-15の検証環境

以下は記録された比較条件です。異なる環境で同じ速度になることを保証する値ではありません。

| 項目 | 値 |
| --- | --- |
| CPU | Intel Core Ultra 7 255H、環境から見える16論理CPU |
| OS | Linux 6.6.87.2-microsoft-standard-WSL2、x86_64 |
| moon / moonrun | 0.1.20261104、940aa18 |
| moonc | v0.10.20+65efd5b93、2026-11-05 |
| backend | wasm-gc、js、native |
| Python | 3.12.3 |
| ベンチ | native、release、各10サンプル |

当時取得したアーカイブのSHA-256を保存します。

```text
moonbit-linux-x86_64.tar.gz
80d987523308fa490eba9f1baf98df996a5a7891e118357553b7c2608c0597c5

core-latest.tar.gz
8ec2a2c01335501d703867bb4eef5f92d3cd7e1ae1ee5f7f14d54d16d2c7c2b5
```


## 実閉体・非線形SMTの独立fixtureを再生成する

通常のテストはコミット済みの正確なfixtureを使い、Z3を実行しません。
独立参照を再計算する場合だけ、SymPyとZ3のPython環境を用意します。

```sh
uv venv .tools/reference-venv
uv pip install --python .tools/reference-venv/bin/python sympy==1.14.0 z3-solver==5.4.1.0
.tools/reference-venv/bin/python tools/generate_cad_review.py --check
.tools/reference-venv/bin/python tools/generate_realnlsmt_review.py --check
```

Z3はQF_NRAの41入力についてsat/unsatの正確な判定を要求し、unknownなら生成を止めます。
参照コード、SMT-LIB、バイナリのSHA-256は[独立照合](research/realnlsmt-independent-review-20261116.md)を参照してください。
MoonBitの計算核から外部solverを呼ぶ経路はありません。
