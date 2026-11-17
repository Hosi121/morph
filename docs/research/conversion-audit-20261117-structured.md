# 固定ソースの表現変換・再構築調査

固定commit: `09f615b8374817d04817eb5b45e776dbee2bfa8a`。読み取り専用、静的調査のみ。

明白な本体Nat→Binary→Nat恒等往復は担当範囲では未確認。既修正/必要な境界と、現在も反復されるcontext準備を区別した。実測性能は不明。

| ID | 優先 | 分類 | 対象 | 所見 |
| --- | --- | --- | --- | --- |
| S01 | high | production_repeated_context | src/simplicialmap/induced.mbt:64 | 列ごとに同一Smith cokernelを再構築 |
| S02 | high | production_repeated_validation | src/realnlsmt/check.mbt:185 | 同一refutation内でProblem→atoms→circuit/CNF bindingをlemma数だけ再構築 |
| S03 | high | production_rebuilt_index | src/cdcl/incremental.mbt:76 | CDCL add_clauseが既存variablesからseen trieを毎回作り直す |
| S04 | medium | production_rebuilt_domain | src/realnlsmt/check.mbt:25 | SAT model完了ごとにgrowing CNFの変数domainを再抽出・線形重複排除 |
| S05 | medium | production_repeated_preparation | src/realnlsmt/search.mbt:288 | 同じ算術atom集合のCAD projectionをBoolean候補ごとに準備 |
| S06 | medium | production_repeated_basis_layout | src/cohomology/cup.mbt:28 | cohomology ringの基底対ごとに同じsimplex集合/face対応を作り直す |
| S07 | medium | production_redundant_normalization_boundary | src/galois/carryless.mbt:115 | 内部canonicalなGF(2) field積をpublic Fp polynomial constructorで再正規化 |
| S08 | medium | production_unused_intermediate_result | src/galois/galois.mbt:96 | Galois.elementは剰余しか使わないのにpublic Fp divideでquotientも作る |
| S09 | medium | production_ephemeral_control_list | src/fppoly/factorization.mbt:206 | multiplicity展開のためだけにUnit列を作って即fold |
| S10 | high | production_vector_matrix_roundtrip | src/simplicialmap/integer.mbt:81 | integer vectorをn×1 matrixに包み、積からcolumnを再抽出 |
| S11 | medium | production_required_generic_boundary_with_specialization_option | src/chainhomology/chainhomology.mbt:159 | integer inverseのInteger→Rational→Integer往復 |
| S12 | medium | production_restarted_pipeline | src/smt/smt.mbt:375 | 整数SMTはtheory conflictごとに全CNFをCDCLへ再準備 |
| S13 | low | production_representation_boundary_not_identity_roundtrip | src/polynomial/polynomial.mbt:576 | term評価でNat exponentをBinary exponentへ毎回materialize |
| S14 | low | public_api_only_candidate | src/cohomology/cohomology.mbt:351 | H-coordinateをzero-paddingしてfull basisで戻す |
| S15 | low | public_api_benchmark_only_reuse_candidate | src/gf2/solve.mbt:114 | solve_factorはRHSごとにoperation log反転とnullspaceを準備 |
| S16 | medium | production_domain_conversion_with_boolean_specialization_option | src/cohomology/cohomology.mbt:87 | cohomology producerの整数boundary→parity→transpose |
| S17 | info | necessary_boundary_and_test_only_reference | src/cdcl/cdcl.mbt:119 | CDCL/BDD等のNat ID→Binary keyはcache/索引境界で、bitsはO(1)view |
| S18 | info | already_fixed | src/fppoly/irreducibility.mbt:94 | 旧Nat半分化往復/Fp discarded quotient/旧span再solveは既に修正済み |

## S01 列ごとに同一Smith cokernelを再構築

固定出典: `09f615b8374817d04817eb5b45e776dbee2bfa8a:src/simplicialmap/induced.mbt:64`

```moonbit
            @smith.class_coordinates(
              @smith.cokernel(target_homology.image_form),
              column,
            ),
```

- 分類: production_repeated_context / 優先high
- 呼出元: `src/simplicialmap/induced.mbt:188`; `src/relativehomology/connecting.mbt:283`
- 実使用根拠: inducedの列normalizationとchainhomology.canonical_columnsの各列から実際に呼ぶ。公開apply専用の未使用案ではない。
- 意味上の削減可否: 可。同じimmutable formのcokernelを列ループ外に一度作り、class_coordinates自体は同じ順で呼べる。cokernelのfree/torsion構築はclass_coordinatesでは使われず、group.formだけを参照する。 空列では準備を増やさず、非空列に入る時だけ共有contextを作る。現在のclass_coordinates/再帰の評価順とNone伝播順も維持する。
- 推奨: 最小の将来候補: private normalizeへ一度準備したCokernelを渡す。公開checkerとclass_coordinatesの次元/剰余検査は残す。
- 静的仕事量: c>0列、C(form)=cokernel構築の構造的仕事とするとc*C(form)からC(form)へ。Cにはrank用とtorsion用のinvariant_factors再走査が含まれる。各列の基底変換・剰余は残る。 c=0では現状どおりcokernel準備は0回とする。
- 未測定。速度向上/回帰なしの主張ではない。

## S02 同一refutation内でProblem→atoms→circuit/CNF bindingをlemma数だけ再構築

固定出典: `09f615b8374817d04817eb5b45e776dbee2bfa8a:src/realnlsmt/check.mbt:185`

```moonbit
pub fn check_refutation(problem : Problem, proof : Refutation) -> Bool {
  if !valid_problem(problem) || !proof.context.equal(problem.context) {
    false
  } else {
    fn augment(rest : @core.Chain[Lemma], formula : @sat.Cnf) -> @sat.Cnf? {
      match rest {
        Nil => Some(formula)
        Cons(lemma, tail) =>
          match lemma_clause(problem, lemma) {
            None => None
            Some(clause) =>
              augment(tail, @core.append(formula, Cons(clause, Nil)))
```

- 分類: production_repeated_validation / 優先high
- 呼出元: `src/realnlsmt/search.mbt:272`
- 実使用根拠: check_refutationは入口でvalid_problemを通した後、augmentの各lemmaから公開lemma_clauseを呼び、そこで再びvalid_problem→prepareを実行する。
- 意味上の削減可否: 可(同一呼出内に限定)。入口で同じimmutable Problemを検証済みなら、private validated-lemma helperで重複のvalid_problemだけを省ける。各lemma.contextとCAD coverの検証は必須。
- 推奨: 公開lemma_clauseは現在の検証を維持。check_refutation内部だけでvalidated contextを共有する独立変更として検討。
- 静的仕事量: L個のlemma、P=同一Problem再prepare/比較の費用なら現状(L+1)P。重複分だけならPへできる。各cover/proof検証コストは変わらない。
- 未測定。速度向上/回帰なしの主張ではない。

## S03 CDCL add_clauseが既存variablesからseen trieを毎回作り直す

固定出典: `09f615b8374817d04817eb5b45e776dbee2bfa8a:src/cdcl/incremental.mbt:76`

```moonbit
pub fn add_clause(search : Search, clause : @sat.Clause) -> Search {
  let seen = @core.fold_left(search.variables, Empty, fn(seen, literal) {
    index_put(seen, @binary.bits(literal.key), true)
  })
  let (normalized, variables, _) = prepared_clause(
    clause,
    Some(Nil),
    search.variables,
    seen,
  )
```

- 分類: production_rebuilt_index / 優先high
- 呼出元: `src/realnlsmt/search.mbt:137`; `src/realnlsmt/search.mbt:29`
- 実使用根拠: realnlsmt既定start_coreはRetainedで、理論conflictごとにadd_clauseへ戻る。variables/Atom.keyは既にSearchに保存されている。
- 意味上の削減可否: 条件付きで可。Searchの既存variable集合Indexを永続cacheとして維持すれば再構築を避けられる。新規変数、tautologyでもmodel-domainを保つ現在の規則は維持する必要がある。
- 推奨: opaque Searchに一貫性を持つseen cacheを保持する案を別途検証。単純に全variables走査を削除して重複検出を弱めない。
- 静的仕事量: V既存変数・key幅bとして追加ごとにV回のindex_put(構造上概ねO(Vb))とtrie再構築。K追加で反復。新規clause処理は依然必要。
- 未測定。速度向上/回帰なしの主張ではない。

## S04 SAT model完了ごとにgrowing CNFの変数domainを再抽出・線形重複排除

固定出典: `09f615b8374817d04817eb5b45e776dbee2bfa8a:src/realnlsmt/check.mbt:25`

```moonbit
fn boolean_variables(formula : @sat.Cnf) -> @core.Chain[@core.Nat] {
  @core.reverse(
    @core.fold_left(formula, Nil, fn(seen, clause) {
      @core.fold_left(clause, seen, fn(seen, literal) {
        if @core.any(seen, fn(variable) { variable.equal(literal.variable) }) {
          seen
        } else {
          Cons(literal.variable, seen)
        }
      })
    }),
```

- 分類: production_rebuilt_domain / 優先medium
- 呼出元: `src/realnlsmt/check.mbt:43`; `src/realnlsmt/search.mbt:284`
- 実使用根拠: Satisfiable Boolean候補ごとにcomplete_booleanがboolean_variables(formula)を呼ぶ。理論lemma追加後も全CNFから取り直す。
- 意味上の削減可否: 条件付きで可。変数domainをキャッシュし追加clause分で単調更新できる。ただしmasked source変数等が後で現れる可能性とfirst-use順を考慮し、初期domainが永久固定だと決めつけない。
- 推奨: producerのSearchにdomain/順序を保存する案。公開check_modelの完全性・矛盾・CNF検査は残す。
- 静的仕事量: L literals、V distinct variablesで重複検出だけでもO(LV)回のNat比較(各Nat比較コスト除外)。候補ごとに反復。
- 未測定。速度向上/回帰なしの主張ではない。

## S05 同じ算術atom集合のCAD projectionをBoolean候補ごとに準備

固定出典: `09f615b8374817d04817eb5b45e776dbee2bfa8a:src/realnlsmt/search.mbt:288`

```moonbit
              match source_assignment(search.problem, full) {
                None => Err(InternalInvariant)
                Some(assignment) =>
                  match signed_formula(search.problem, assignment) {
                    None => Err(InternalInvariant)
                    Some(signed) =>
                      match @cad.prepare(arity(search.problem), signed) {
                        Err(error) => Err(CadFailure(error))
```

- 分類: production_repeated_preparation / 優先medium
- 呼出元: `src/realnlsmt/search.mbt:265`
- 実使用根拠: source_assignmentは全source atom IDを列挙し、signed_formulaは同じpolynomialにrelation/complementを付ける。CAD prepareは各回projection.prepareを呼ぶ。
- 意味上の削減可否: 条件付き。完全assignmentではpolynomial集合は同じでrelationのみ変わるためprojection部分の共有候補。formula依存prefix/真偽ラベルやcontext bindingは再構築/検証が必要。
- 推奨: 同じpolynomial familyに結び付いたimmutable projection planのproducer共有を検討。単に別formulaのProblemを流用しない。
- 静的仕事量: K候補でprojection準備をK回。P=projection構築ならK*P。共有可能性はあるがprefix/cover/search自体の仕事は残る。
- 未測定。速度向上/回帰なしの主張ではない。

## S06 cohomology ringの基底対ごとに同じsimplex集合/face対応を作り直す

固定出典: `09f615b8374817d04817eb5b45e776dbee2bfa8a:src/cohomology/cup.mbt:28`

```moonbit
  let left_simplices = @homology.simplices(source, left_degree)
  let right_simplices = @homology.simplices(source, right_degree)
  match
    @core.length(left).equal(@core.length(left_simplices)) &&
    @core.length(right).equal(@core.length(right_simplices)) {
```

- 分類: production_repeated_basis_layout / 優先medium
- 呼出元: `src/cohomology/ring.mbt:255`; `src/cohomology/ring.mbt:493`
- 実使用根拠: table_forの(p,i,q,j)ループはcupを基底対ごとに呼ぶ。cupはleft/right/target degreeのsimplicesを毎回取得し、各target faceから線形検索で座標を引く。simplicesはstored-list viewでなく全faces.filter。
- 意味上の削減可否: 条件付きで可。source/degree対に結び付くsimplicesリストやAlexander-Whitney face indexを準備してproducerで共有できる。cochainの値とdegree別basisは混同しない。
- 推奨: 最初はproducer table_forだけにdegree-pair planを持たせる案。公開cup/check_ringの独立検証は残す。
- 静的仕事量: T基底対で同じ3回のfaces.filterをT回。face検索もtargetごとにleft/right simplex列を走査する。plan化してもChain上の値アクセス費用は別に評価が必要。
- 未測定。速度向上/回帰なしの主張ではない。

## S07 内部canonicalなGF(2) field積をpublic Fp polynomial constructorで再正規化

固定出典: `09f615b8374817d04817eb5b45e776dbee2bfa8a:src/galois/carryless.mbt:115`

```moonbit
  let field = a.field
  {
    field,
    representative: @fppoly.polynomial(
      prime_field(field),
      binary_product_loop(
        left,
        right,
        @fppoly.coefficients(field.modulus),
        @binary.zero(),
        Nil,
      ),
```

- 分類: production_redundant_normalization_boundary / 優先medium
- 呼出元: `src/galois/galois.mbt:155`; `src/galois/galois.mbt:209`
- 実使用根拠: 非zero/nonunitのbinary_field_productは既約次数内のcanonical coefficient chainを作った後、fppoly.polynomialを呼ぶ。power/trace/norm等のmultiply経路に載る。
- 意味上の削減可否: 条件付きで可。内部のcanonical・degree-bound invariantがあればparity/high-zero再走査は数学上不要。ただし別packageの公開constructor境界なので、その検証を単純削除する権限/仕組みは現状ない。
- 推奨: sealed/checked canonical-result API等の小さい境界設計を検討。一般のraw Binary constructorは現在の正規化を維持。
- 静的仕事量: degree d以下の積ごとに追加O(d)係数走査/リストspine構築。積・剰余の仕事は残り、未測定。
- 未測定。速度向上/回帰なしの主張ではない。

## S08 Galois.elementは剰余しか使わないのにpublic Fp divideでquotientも作る

固定出典: `09f615b8374817d04817eb5b45e776dbee2bfa8a:src/galois/galois.mbt:96`

```moonbit
pub fn element(
  field : Field,
  polynomial : @fppoly.Polynomial,
) -> Result[Element, FieldError] {
  match @fppoly.divide(polynomial, field.modulus) {
    Err(error) => Err(PolynomialError(error))
    Ok({ remainder, .. }) => Ok({ field, representative: remainder, })
  }
```

- 分類: production_unused_intermediate_result / 優先medium
- 呼出元: `src/galois/galois.mbt:163`; `src/galois/galois.mbt:177`
- 実使用根拠: odd-prime multiplicationのelement reductionとinverseのelement正規化から到達する。F2 multiplyは専用pathなので区別する。
- 意味上の削減可否: 剰余計算自体は必須。discarded quotient構築のみ条件付きで削減可。既存fppoly remainder_onlyはpackage-privateでこのpackageからは呼べない。
- 推奨: 公開checked remainder API等の境界を検討し、FieldMismatch/ZeroDivisor/leading inverseとpublic divide oracleを維持。basis reductionそのものを消さない。
- 静的仕事量: q cancellation stepsに対するquotient term/shift/addの構造的仕事が余分。remainder subtractionと必要なmodulus reductionは同じ。
- 未測定。速度向上/回帰なしの主張ではない。

## S09 multiplicity展開のためだけにUnit列を作って即fold

固定出典: `09f615b8374817d04817eb5b45e776dbee2bfa8a:src/fppoly/factorization.mbt:206`

```moonbit
                      // A nonconstant p-th power has degree at least p, so
                      // this Nat conversion is bounded by the input degree.
                      let count = @binary.to_nat(characteristic(value))
                      Ok(
                        @core.fold_left(@core.replicate(count, ()), Nil, fn(
                          result,
                          _,
                        ) {
                          @core.append(factors, result)
                        }),
```

- 分類: production_ephemeral_control_list / 優先medium
- 呼出元: `src/fppoly/factorization.mbt:199`; `src/fppoly/factorization.mbt:300`
- 実使用根拠: 非constant p-th powerのfactor_monicで、factor列をp回複製する際のcounterとしてreplicate(count,())を作る。
- 意味上の削減可否: Unit列は不要。Nat countを直接構造再帰で消費すれば同じappend順・multiplicityを保てる。Binary→Natはここでは反復数を得る境界であり恒等往復ではない。pはinput degree以下という既存guard根拠もある。
- 推奨: 最小候補はUnit列だけを除く。Binary counterへ無条件変更するとbit decrementの仕事が増え得るため別評価。
- 静的仕事量: 余分なp個のUnit-list spine構築とfold走査O(p)。p回のfactor出力(長さfならO(pf))は意味上必要。
- 未測定。速度向上/回帰なしの主張ではない。

## S10 integer vectorをn×1 matrixに包み、積からcolumnを再抽出

固定出典: `09f615b8374817d04817eb5b45e776dbee2bfa8a:src/simplicialmap/integer.mbt:81`

```moonbit
fn apply_matrix(
  matrix : @matrix.Matrix[@exact.Integer],
  vector : @core.Chain[@exact.Integer],
) -> @core.Chain[@exact.Integer]? {
  match @matrix.matrix(Succ(Zero), @core.map(vector, fn(x) { Cons(x, Nil) })) {
    None => None
    Some(column) =>
      match @matrix.multiply(matrix, column, integers()) {
        None => None
        Some(product) => @matrix.column(product, Zero)
      }
```

- 分類: production_vector_matrix_roundtrip / 優先high
- 呼出元: `src/simplicialmap/induced.mbt:219`
- 実使用根拠: public simplicialmap.applyは同一呼出でこのprivate apply_matrixを2回使う。chainhomology.apply_matrixにも同型の公開実装があるが、そちらの内部本体callerは今回確認できなかった。
- 意味上の削減可否: 可。直接matrix-vector dot走査で同じ列ベクトルを返せる。次元不一致、m×0/0×nの形状とzero出力は従来通り扱う必要がある。
- 推奨: private simplicialmap helperから、元のgeneric matrix multiplyとの差分検証付きで検討。公開checkerの再検証は残す。
- 静的仕事量: 長さnのsingleton-row wrapper、generic multiplyのcolumn準備、m個のsingleton result rows、column再抽出が追加。算術dotのO(mn)自体は残る。
- 未測定。速度向上/回帰なしの主張ではない。

## S11 integer inverseのInteger→Rational→Integer往復

固定出典: `09f615b8374817d04817eb5b45e776dbee2bfa8a:src/chainhomology/chainhomology.mbt:159`

```moonbit
  let rationals = @matrix.matrix(
    @matrix.width(input),
    @core.map(@matrix.rows(input), fn(row) { @core.map(row, @exact.whole) }),
  )
  match rationals {
    None => None
    Some(rationals) =>
      match @linear.inverse(rationals) {
        None => None
        Some(inverse) =>
          match integral_rows(@matrix.rows(inverse)) {
            None => None
            Some(rows) =>
              match @matrix.matrix(@matrix.width(inverse), rows) {
                Some(candidate) =>
                  match inverse_pair(input, candidate) {
```

- 分類: production_required_generic_boundary_with_specialization_option / 優先medium
- 呼出元: `src/chainhomology/chainhomology.mbt:233`; `src/simplicialmap/induced.mbt:178`; `src/relativehomology/connecting.mbt:265`
- 実使用根拠: chainhomology.computeはSmith right matrix、induced/connectingはSmith left matrixをinteger_inverseへ渡す。同型コードはsimplicialmap/integer.mbtにもある。
- 意味上の削減可否: 一般公開integer_inverseではQQ inverseを計算して整数性を拒否/確認する意味があり、無意味な恒等変換ではない。既知unimodular Smith変換に限ればinverseをproducerで保持/再利用する別案は可能。
- 推奨: generic APIとinverse_pairの独立検査を維持。内部unimodular witness/logからinverseを得る案を別の費用比較対象にする。
- 静的仕事量: n×nで入出力の少なくとも2つのO(n²)表現走査とQQ inversion。整数algorithm/operation-log案が速いとは未測定で言えない。
- 未測定。速度向上/回帰なしの主張ではない。

## S12 整数SMTはtheory conflictごとに全CNFをCDCLへ再準備

固定出典: `09f615b8374817d04817eb5b45e776dbee2bfa8a:src/smt/smt.mbt:375`

```moonbit
                          let formula = @core.append(
                            search.formula,
                            Cons(clause, Nil),
                          )
                          Paused({
                            ..search,
                            formula,
                            lemmas_rev: Cons(lemma, search.lemmas_rev),
                            phase: Boolean(@cdcl.start(formula)),
                          })
```

- 分類: production_restarted_pipeline / 優先medium
- 呼出元: `src/smt/smt.mbt:325`
- 実使用根拠: 単なるreference関数ではなくinteger smt.stepの本体。新lemmaをappendしてcdcl.start(formula)へ戻り、literal変換/normalize/watch準備を繰り返す。
- 意味上の削減可否: 条件付き。monotone add_clause/run_incrementalへ進める余地はrealnlsmtの既存実装が示す。ただしmodel/proof順序・fuel/statisticsが変わり得るため単純な恒等変換削除とは扱えない。
- 推奨: 別の明示的algorithm契約の下で検討。realnlsmt既定は既にRetainedなので同じ未修正問題と混同しない。
- 静的仕事量: K conflictsで増大CNFの全literal準備を繰り返す。加えてappendが現在のclause spineを複製する。具体的速度は未測定。
- 未測定。速度向上/回帰なしの主張ではない。

## S13 term評価でNat exponentをBinary exponentへ毎回materialize

固定出典: `09f615b8374817d04817eb5b45e776dbee2bfa8a:src/polynomial/polynomial.mbt:576`

```moonbit
        @core.fold_left(pairs, term.coefficient, fn(product, pair) {
          let (exponent, value) = pair
          @exact.rational_multiply(
            product,
            power(value, @binary.bits(@binary.from_nat(exponent))),
          )
        })
```

- 分類: production_representation_boundary_not_identity_roundtrip / 優先low
- 呼出元: `src/polynomial/evaluation.mbt:86`; `src/bernstein/subdivision.mbt:268`
- 実使用根拠: 多変数のgeneric evaluatorではterm/variableごとにfrom_natを呼ぶ。univariate用Sparse Hornerは既に別pathでgapを使う。cyclotomic.conjugateもtermごとに同型変換を行う。
- 意味上の削減可否: 現在のbinary exponentiation helperへの入力境界として意味がある。Nat→Binary→Natではない。反復する同一exponentのbit列共有やNat半分化を直接使う別helperならmaterializationを省ける可能性。
- 推奨: 変換を削除するだけでなく、重複exponent分布とentrypointを確認してから小さいcache/Nat-powered helperを比較。univariate既修正pathを新規問題として数えない。
- 静的仕事量: 変換回数はgenericでterm数×変数数。各unary exponentの構造走査とbit表現準備があり、有理数べき乗の仕事は別。
- 未測定。速度向上/回帰なしの主張ではない。

## S14 H-coordinateをzero-paddingしてfull basisで戻す

固定出典: `09f615b8374817d04817eb5b45e776dbee2bfa8a:src/cohomology/cohomology.mbt:351`

```moonbit
      let b = @core.length(witness.result.coboundaries)
      let tail = @core.subtract(
        @matrix.width(witness.basis),
        @core.add(b, witness.result.rank),
      )
      apply_matrix(
        witness.basis,
        @core.append(
          @core.replicate(b, false),
          @core.append(value, @core.replicate(tail, false)),
        ),
      )
```

- 分類: public_api_only_candidate / 優先low
- 呼出元: 本体caller未確認
- 実使用根拠: representative公開APIの実装。本体内/他packageの非test producer callerは固定src検索では見つからず、testsでの利用を確認。現行実使用hot pathとは断定しない。
- 意味上の削減可否: 条件付きで可。stored H representativesの選択XORならB/complementのzero paddingと全basis dotを避けられる。入力長検査とstored代表元の選択規則は維持。
- 推奨: 公開API利用頻度を先に確認。現在のproducer hot path扱いで優先しない。
- 静的仕事量: n-dimensional full coordinate chain構築とdense n×n apply。h representativesだけの組合せならO(nh)型の仕事が候補だが、実装/計測していない。
- 未測定。速度向上/回帰なしの主張ではない。

## S15 solve_factorはRHSごとにoperation log反転とnullspaceを準備

固定出典: `09f615b8374817d04817eb5b45e776dbee2bfa8a:src/gf2/solve.mbt:114`

```moonbit
  match @core.compare(@core.length(rhs), @matrix.height(value.source)) {
    Equal => {
      let transformed = @core.fold_left(
        @core.reverse(value.reverse_operations),
        rhs,
        apply_rhs,
```

- 分類: public_api_benchmark_only_reuse_candidate / 優先low
- 呼出元: `src/cmd/gf2kernelbench/main.mbt:158`; `src/cmd/nightgf2bench/main.mbt:214`
- 実使用根拠: 公開solve_factorの再利用経路は存在するが、今回固定srcで確認した呼出元はcmd benchmark/test。cohomology本体はnullspace_factorを一度使うだけ。
- 意味上の削減可否: 複数RHSならforward logやnullspaceをFactorizationにcacheできる可能性。単発利用ではcache準備/保持費用が増えるので不要と断定しない。
- 推奨: 実consumerの複数RHS需要を確認してから。factor再利用が既に導入済みな点を無視して全解法再実行と誤診しない。
- 静的仕事量: RHSごとにlog長tのreverse spine O(t)とnullspace再構築。既存reduction自体は再計算していない。
- 未測定。速度向上/回帰なしの主張ではない。

## S16 cohomology producerの整数boundary→parity→transpose

固定出典: `09f615b8374817d04817eb5b45e776dbee2bfa8a:src/cohomology/cohomology.mbt:87`

```moonbit
  match @homology.boundary(source, Succ(degree)) {
    None => None
    Some(boundary) =>
      match parity(boundary) {
        None => None
        Some(binary) => Some(@matrix.transpose(binary))
      }
```

- 分類: production_domain_conversion_with_boolean_specialization_option / 優先medium
- 呼出元: `src/cohomology/cohomology.mbt:246`
- 実使用根拠: computeのincoming/outgoing coboundary生成でinteger incidence matrixを構成後、全cellをBoolへ写し、転置する。checkerも同じpublic coboundary/incomingを再構成する。
- 意味上の削減可否: cochain方向への転置とmod2という数学的変換は必要。producer専用Bool incidence builderならInteger中間表現を避けられる可能性があるが、公開integer-based checkerを削除/信頼cache化してはいけない。
- 推奨: 必要ならproducerのみBool builderを別案にし、元の整数boundary/parityと全形状比較する。検査重複を単純削除しない。
- 静的仕事量: mn incidence cellsのInteger中間、Bool写像、row/column転置の構造走査。最終mn Bool出力とface incidence判定は不可避。
- 未測定。速度向上/回帰なしの主張ではない。

## S17 CDCL/BDD等のNat ID→Binary keyはcache/索引境界で、bitsはO(1)view

固定出典: `09f615b8374817d04817eb5b45e776dbee2bfa8a:src/cdcl/cdcl.mbt:119`

```moonbit
fn atom(literal : @sat.Literal) -> Atom {
  {
    key: binary_key(literal.variable),
    source: literal.variable,
    positive: literal.positive,
  }
}

///|
fn external(literal : Atom) -> @sat.Literal {
  { variable: literal.source, positive: literal.positive, }
```

- 分類: necessary_boundary_and_test_only_reference / 優先info
- 呼出元: `src/cdcl/preparation.mbt:25`; `src/cdcl/cdcl.mbt:568`
- 実使用根拠: Atomはsource Natとcached Binary keyを両方保持し、solver出力externalではsourceを使う。lookup中にto_natしていない。旧prototype Nat-bit変換はkeys_wbtestだけ。BDDもstored key/source bindingをcheckerで検証する。
- 意味上の削減可否: 現行trie/AVL索引設計では意味がある。binary.bitsはn.bitsを返すだけで再変換/再構築ではない。watch_keyはpositive bitを1個prefixするが全key再作成ではない。
- 推奨: from_nat/bitsという名前だけで一括削除しない。cache domain再構築(S03)と本件を区別。
- 静的仕事量: bits accessorはO(1)参照。Nat→key変換はprepare時のliteralごとで、以後のlookupはcached key。
- 未測定。速度向上/回帰なしの主張ではない。

## S18 旧Nat半分化往復/Fp discarded quotient/旧span再solveは既に修正済み

固定出典: `09f615b8374817d04817eb5b45e776dbee2bfa8a:src/fppoly/irreducibility.mbt:94`

```moonbit
                        false => Ok(None)
                        true => {
                          let half = @core.half_nat(n)
                          match
```

- 分類: already_fixed / 優先info
- 呼出元: `src/cyclotomic/cyclotomic.mbt:56`
- 実使用根拠: 固定HEADでfloor(n/2)はcore.half_natを直接利用。Fp modular-powerはremainder_onlyを使い、linearspanはcached columnsを新vectorへ適用する。古い実装は一部WB oracleに残る。
- 意味上の削減可否: 今回の未修正findingに数えない。公開divideや旧generic referenceは独立oracle/別APIなので残す意味がある。
- 推奨: 既修正docsと本体を併記し、test/referenceの旧変換をproductionと誤認しない。
- 静的仕事量: 既修正の状態確認のみ。過去の計測値を現在の性能主張として転用しない。
- 未測定。速度向上/回帰なしの主張ではない。

## 範囲と制約

機械検索対象のproduction .mbt: 64 files。対象package: polynomial, fppoly, galois, cyclotomic, matrix, gf2, linearspan, graph, homology, chainhomology, relativehomology, simplicialmap, cohomology, collapse, filteredcollapse, persistence, rips, sat, cdcl, smt, realnlsmt, circuit, bdd, ruplog, difference。

固定source本文は全てgit showで読み、JSONに参照sourceのSHA-256と数値変換site一覧を残した。GraphはSCC転置が二段DFSに必要で、単なる往復として扱わない。Matrixのright-column準備も一回のmultiplyに必要なlayoutで、同一prepared RHSを反復利用する需要を示さずに不要と断定しない。Linearspanは既にincremental columnsを再利用しており、残るnth/immutable residual更新を数値変換と混同しない。

- 全ソースの形式的/dataflow証明ではない。変数経由・マクロ・外部callerの完全性は主張しない。
- 関数の存在だけでhot pathと断定しない。実使用根拠を本体/公開APIのみ/cmd+testに分けた。
- 重いテスト、計測、コンパイル、実装、Git変更、追加agentは行っていない。
- Big-Oはlist構造走査/表現準備の静的評価。BigInt/ADT arithmetic、Nat比較、メモリ管理や実測速度を代用しない。
