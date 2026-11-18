# 表現変換と準備の重複の監査

[研究記録](README.md) / [Natの直接処理](../bootstrap/nat-conversions.md) / [体の共通部品](../handbook/field-kernels.md)

削減候補は残っています。以前の半分化の三箇所は修正済みですが、変数や関数を挟む数値の往復、
正規化済みの値の作り直し、同じcontextの再構築は直接の字句ゲートでは検出できません。
今回の調査は固定ソース`09f615b`に対する読み取り専用の静的監査です。速度・割当量は測定していません。

二担当が数値表現と、多項式・行列・位相・SAT/SMTを分担しました。
所見には実使用箇所、公開APIのみ、テストのみ、必要な変換、既修正も含めています。
件数をそのまま「削除できる無駄」の数とは扱いません。

## 優先して確かめる箇所

| 対象 | 現在の仕事 | 次の候補と守る条件 |
| --- | --- | --- |
| [Sturmの根数](../../src/orderedsturm/count.mbt#L105)・[多段実数体の根数](../../src/realtower/system.mbt#L81) | Natの符号変化数をBinary→Integerにし、差のmagnitudeをNatへ戻す | 非負の根数を返す経路に限ってNatの比較と差を直接使う。負の差のエラーを維持し、符号付きTarski queryは分ける |
| [多段実数体への有理数埋込み](../../src/realtower/api.mbt#L12) | 同じ親体への埋込みを分子側・単位分母側で別々に再帰構築する。q=1でも重複 | 一段で値と単位の表現を作り、immutableな部分を共有する候補。構造Eqの走査費用は別に残る |
| [符号付き剰余](../../src/modular/modular.mbt#L120) | reduce済みの剰余を汎用subtractへ渡し、0と剰余をもう一度reduce | 既に0≤r<mの内部経路で符号反転する。r=0と法1を含む既存結果を維持する |
| [検証後の数体構築](../../src/numberfield/field.mbt#L72)・[resultant準備](../../src/realalgebraic/resultant.mbt#L211) | monicと確認された値を再monic、または同じ入力をdense化と保存用で二度monic | 検証を残したまま、正規な値や一度の正規化結果を再利用する |
| [Smith座標の列ごとの正規化](../../src/simplicialmap/induced.mbt#L64)・[共有版](../../src/chainhomology/chainhomology.mbt#L306) | 同じSmith formからcokernelのrank/torsion情報を列ごとに作る | 列を処理するときに一度だけ準備して共有。空列の経路・Noneの伝播・列の順序を維持する |
| [増分CDCLの節追加](../../src/cdcl/incremental.mbt#L76) | 保存済みvariablesからseen trieを毎回作る | Searchに永続索引を保持して新規分だけ更新。tautologyでも変数domainを保つ規則を維持する |
| [非線形SMTの反証検査](../../src/realnlsmt/check.mbt#L185) | 冒頭で検証した同じProblemを、lemma_clause経由で補題ごとに再prepareする | 同一呼出内で検証済みcontextを共有。各補題のcontext・CAD被覆・反証の検査は維持する |
| [整数の行列×ベクトル](https://github.com/Hosi121/morph/blob/86cee8e3a202fc1fa64e93c0a36e1678bc718946/src/simplicialmap/integer.mbt#L81) | vectorを単列matrixへ包み、積を計算してcolumnを取り出す | 行列とベクトルを直接走査する候補。次元違いと零次元の挙動を保つ |

多段実数体への埋込みは、ソース上では深さhについて`T(h)=2T(h−1)+O(1)`の再帰呼出木です。
これは構築手順の静的な指摘です。生成コードの最適化、構造等値、算術と証拠検査を含む全体時間の評価ではありません。

## 境界を維持して検討するもの

GF(2^m)の内部積は、正規な係数列を作った後に公開Fp多項式constructorで再正規化します。
再走査の候補ですが、別packageのopaqueな型の不変条件を保証する境界でもあります。
単に検査を取り除かず、検証済みの結果を渡す小さいAPIや専用操作の設計が必要です。
同様にGalois.elementには余りだけを使うdivideが残っていますが、現在の余り専用helperはpackage-privateです。

整数行列をQQへ上げて逆行列を求め、整数性を確認して戻す経路には役割があります。
既知のunimodularなSmith変換の逆を再利用する案は、一般公開の整数逆行列の置換とは分けて評価します。
IDからBinaryの索引キーを作ること、p乗根のstrideや出力の反復数をNatへ展開することも、名前だけでは冗長と判断しません。

コホモロジーの積表では、degree対ごとのsimplex列・faceの対応を基底対ごとに準備する候補があります。
整数SMTの再始動から状態保持への変更は、燃料・探索順・証拠順を含む別の設計変更です。
実数SMTの既定経路は既に保持型なので、二つを混同しません。

## 保守チェックと次の比較

`tools/audit_paths.py`はaliasを考慮し、直接の`to_nat(from_nat(...))`、逆向きの恒等往復、
`to_nat(half(from_nat(...)))`を拒否します。変数・関数をまたぐ一般的なdataflowの解析ではありません。
今回の監査でそのチェックが通っていても残る候補を確認しました。

まず根数の直接Nat演算、既約剰余の符号反転、重複monic、Smith contextのループ外共有を小さい変更として比較できます。
多段体の定数共有、CDCLの永続索引、degree対の積planは、保持量と準備費用も含めて別に比較する候補です。
各変更は通常APIの入力・エラー・検査条件を揃え、旧実装と独立oracleの全結果比較を行ってから採用します。
今回の監査で新しい削減実装を採用したとは扱いません。

## 詳細と根拠

数値担当17所見と、行列・多項式・SAT担当18所見を保存しました。合計35には必要な境界・既修正・テスト参照も含みます。

- [数値系の全所見](conversion-audit-20261117-numeric.md)・[根拠と抜粋のJSON](conversion-audit-20261117-numeric.json)
- [多項式・行列・位相・SATの全所見](conversion-audit-20261117-structured.md)・[根拠と抜粋のJSON](conversion-audit-20261117-structured.json)
- [親による照合・分担・期限・制約](conversion-audit-20261117-review.json)

親は数値担当45件・構造担当100件のファイルhashと、合計189箇所の位置・抜粋を固定Git sourceへ照合しました。
重複を除くsrc140ファイルが統合版`a63dcbc`でも同一であることを確認しています。
N01〜N06、S01/S02/S03/S07/S12の呼出経路と前提は親でも追跡しました。
これは根拠の確認であり、提案した変更の全入力に対する正しさや高速化の証明ではありません。
本体の実行頻度、全dataflow・外部caller・未発見経路の網羅性も保証しません。
