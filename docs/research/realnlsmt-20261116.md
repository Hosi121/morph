# 検査可能な非線形実数SMT（2026-11-16）

[任意変数の実閉体ソルバ](realclosed-20261116.md)の量化なし入口として、
`src/realnlsmt`を追加した。有理係数多項式の六関係とBoolean結合を、既存の
Tseitin変換・CDCLと任意変数CADへ接続する。公開APIは生成済み`.mbti`を正本とする。

## 入力と理論atom

`prepare(arity,@realcad.Formula)`は全atomの変数数を検査する。
各Boolean source変数は`(Polynomial,Relation)`の組であり、左からの初出順に
IDを割り当てる。同じ多項式でも`EqualZero`と`NotZero`は別IDである。
定数で隠れる分枝もarity検査とsource ID収集から省かない。
Tseitinの補助変数はsource IDの後へ割り当て、理論atomには含めない。
独立のBoolean自由変数を渡すAPIは現段階では設けていない。

`Context{arity,source}`が入力の正本であり、opaqueな`Problem`には、これに対応する
atom表と既存`@circuit.Encoding`を保存する。`Model`、`Lemma`、`Refutation`は
未信頼の公開データとしてそれぞれ同じcontextを持つ。
公開checkerの境界では、原式から`prepare`を再実行し、context、atom表、
Tseitin encodingの一致も確認する。opaqueな型の生成規則だけには依存しない。

## 再開可能な探索とSAT検査

`start`、`step`、`run`がBoolean段階とCAD段階を進める。
Boolean段階ではCDCLを一遷移だけ進める。SAT候補の部分割当を全CNF変数へ
falseで補完する前に、重複ID、未知ID、不整合、未充足CNFを拒否する。
補完後もCNFを再検査し、`@circuit.source_model`と`check_source_model`で
元のBoolean assertionへ結び付ける。全source atomの真偽を固定した連言をCADへ渡す。

CADの`Paused`はSMTの探索状態へ保存し、次の呼び出しで継続する。
得られた実点は、その点でのsigned atom連言と原式の両方を
`@cad.evaluate_formula`で厳密に再評価する。`check_model(problem,model)`も
context、実点の次元、元CNF、Tseitin assertion、全source atom、原式を検査する。
別contextの結果や、Boolean値だけが整合した偽の実点は採用しない。

`Outcome`は`Satisfiable`、`Unsatisfiable`、`Paused`。
CADの失敗は`SmtError::CadFailure`として返す。内部不変条件の失敗もエラーであり、
fuel切れやエラーをUNSATへ読み替えない。fuelは外側の遷移数であって、射影、
一回のCAD遷移、証明書検査の実時間上限ではない。

## 理論補題とUNSAT検査

CADに実点がなければ、`Lemma{context,assignment,decomposition}`を作る。
assignmentはsigned source IDであり、拒否した真偽の連言を表す。
公開checkerの`lemma_clause`は次を実行する。

1. 外部から渡された元`Problem`とcontextを比較する。
2. source IDの範囲と重複を検査し、そのatom表からsigned連言を再構築する。
   補題には有効な部分集合も許すが、補助変数は拒否する。
3. その連言で`@cad.prepare`を再実行し、対応する`@cad.Certificate`を検査する。
4. 全実変数を存在量化した`@cad.sentence`がfalseであることを確認する。
5. assignmentの各literalを否定したblocking clauseを返す。

これにより、別の連言について正しいCAD証明書だけを持ち込んでも補題にならない。
生成したblocking clauseが現在のBoolean候補を実際に排除することを確認してから
CNFへ追加し、CDCLを再開する。最終`Refutation`はcontext、学習順の補題列、
`@cdcl.Proof`を持つ。`check_refutation`は各理論補題を独立に再検査し、
元CNFへその順で節を追加した後、既存RUP checkerで最終反証を検査する。

## 独立照合と結果

[Fraction fixture記録](../measurements/realnlsmt-fixtures-20261116.json)は、
`p=(x+1)(x-1)`と`q=x(x-2)`の既知の全実根から完全な符号セルを作る。
各開区間と各根でPython `Fraction`により式を評価し、SAT/UNSAT期待値を得る。
productionのCAD、Sturm、実行ファイル、SymPyは使わない。
これは任意の有限領域を実数領域の代用にする検査ではなく、因数から全実根が
既知である多項式族について全実符号セルを列挙した独立oracleである。

同一多項式の全6×6関係のAND/OR、異なる多項式の全6×6関係のAND、否定6例の
計114式（SAT101、UNSAT13）を照合した。focused testは12件で、`x²<0`、
`x²=2 && x>0`、`x²=2 && (x<0 || x>0)`、同一多項式の異関係矛盾、
3変数単位球面の正octantのSAT、3変数平方和が負というUNSATを含む。
原式・context・Boolean値・実点・source/補助ID・CAD payload・coherentな別補題・
RUP差替えと、fuelなし/一遷移継続も検査した。
さらにpackage内部のwhite-box攻撃として、`Truth(true)`のcontextへ
`Truth(false)`のencodingを挿入し、反証のcontextだけを合わせる例を再現した。
修正前は誤って受理されて回帰テストが失敗し、原式からのpayload再構築を
checker境界へ加えた後は拒否した。外部からopaque `Problem`を組み立てるAPIはないが、
sourceとcached payloadの強い束縛をchecker自身でも維持する。

126テストがnative、wasm-gc、jsの各backendで成功した。
実行条件と結果は[検証記録](../measurements/realnlsmt-validation-20261116.json)、
生ログは`.tools/realnlsmt-20261116/`に保存した。手書きkernelのpurity、
deny-warn、fmt、fixture再生成検査も成功した。

## 残る制約

この実装は全CADを使い、拒否したBoolean算術割当をblockingする完全探索の入口である。
原典のincremental NLSAT、model-based projection、最小conflict core抽出とは呼ばない。
CDCLは理論補題追加時に再構築する。有限個のsource truth割当を排除できる一方、
全CADと証明書の再検査には大きな費用があり、scalingや性能向上は主張しない。
任意変数CAD・実根塔・RUP・Tseitinの既存実装を信頼境界に含み、形式的な意味保存証明や
実装言語全体の検証を達成したとは扱わない。
