# パッケージ一覧

[ドキュメント](README.md) / [アルゴリズム一覧](ALGORITHMS.md)

`python3 tools/inventory.py`で再生成する。手書きの集計値を正本にしない。
テスト欄はソース上の宣言数で、成功数・独立性・網羅率を表さない。
bench欄もgroup数で、group内部の個別計測数とは異なる。

算法の核：139パッケージ、394ソース。
核のテスト宣言：5711、bench group：213。
testsupport・cmd・benchmarksは核の集計から除外する。

| パッケージ | 核ソース | テスト宣言 | bench group | 直接の核依存 |
| --- | ---: | ---: | ---: | --- |
| [aes](../src/aes) | 4 | 14 | 0 | `binary`, `core`, `fppoly`, `galois`, `primefield`, `trie` |
| [aho](../src/aho) | 1 | 2 | 0 | `core`, `trie` |
| [algebra](../src/algebra) | 1 | 0 | 0 | `binary`, `exact` |
| [autodiff](../src/autodiff) | 2 | 2 | 0 | `algebra`, `binary`, `core`, `exact` |
| [avl](../src/avl) | 1 | 2 | 0 | `binary`, `core` |
| [bareiss](../src/bareiss) | 2 | 140 | 16 | `binary`, `core`, `exact`, `matrix` |
| [bch](../src/bch) | 3 | 28 | 0 | `binary`, `core`, `galois`, `recurrence` |
| [bdd](../src/bdd) | 4 | 13 | 4 | `binary`, `circuit`, `core`, `sat` |
| [berkowitz](../src/berkowitz) | 2 | 76 | 0 | `algebra`, `binary`, `core`, `exact`, `matrix` |
| [bernstein](../src/bernstein) | 2 | 17 | 0 | `binary`, `core`, `exact`, `polynomial` |
| [binary](../src/binary) | 9 | 35 | 25 | `core` |
| [bipartite](../src/bipartite) | 1 | 3 | 0 | `core` |
| [bitcodec](../src/bitcodec) | 1 | 2 | 0 | `binary`, `core` |
| [blossom](../src/blossom) | 2 | 12 | 0 | `core` |
| [boolean](../src/boolean) | 1 | 2 | 0 | `core` |
| [cad](../src/cad) | 8 | 91 | 0 | `cadprojection`, `core`, `exact`, `polynomial`, `prefixlogic`, `realcad`, `realformula`, `realtower`, `signcad`, `sturm` |
| [cad2](../src/cad2) | 5 | 47 | 0 | `binary`, `core`, `numberfield`, `orderedsturm`, `polynomial`, `projection`, `realalgebraic`, `realcad`, `realminimal`, `relativecad` |
| [cadprojection](../src/cadprojection) | 4 | 33 | 0 | `core`, `elimination`, `exact`, `polynomial` |
| [cdcl](../src/cdcl) | 6 | 57 | 65 | `binary`, `core`, `sat` |
| [cek](../src/cek) | 1 | 3 | 0 | `core`, `infer` |
| [chainhomology](../src/chainhomology) | 1 | 3 | 0 | `algebra`, `binary`, `core`, `exact`, `linear`, `matrix`, `smith` |
| [circuit](../src/circuit) | 2 | 3 | 0 | `boolean`, `core`, `sat` |
| [cohomology](../src/cohomology) | 3 | 181 | 0 | `binary`, `core`, `csscode`, `exact`, `gf2`, `homology`, `matrix` |
| [collapse](../src/collapse) | 3 | 8 | 0 | `algebra`, `binary`, `core`, `exact`, `homology`, `matrix` |
| [complexalgebraic](../src/complexalgebraic) | 5 | 10 | 0 | `core`, `exact`, `polynomial`, `realalgebraic` |
| [complexautomorphism](../src/complexautomorphism) | 2 | 10 | 0 | `complexfield`, `core`, `numberfield` |
| [complexcompositum](../src/complexcompositum) | 3 | 16 | 0 | `complexalgebraic`, `complexfield`, `compositum`, `core`, `exact`, `numberfield`, `polynomial`, `realalgebraic`, `realminimal`, `zassenhaus` |
| [complexfactor](../src/complexfactor) | 3 | 16 | 0 | `binary`, `complexroots`, `core`, `exact`, `polynomial`, `zassenhaus` |
| [complexfield](../src/complexfield) | 5 | 28 | 0 | `core`, `exact`, `linear`, `linearspan`, `matrix`, `numberfield`, `polynomial` |
| [complexprimitive](../src/complexprimitive) | 2 | 11 | 0 | `algebra`, `complexfield`, `core`, `exact`, `linear`, `matrix`, `numberfield`, `polynomial` |
| [complexroots](../src/complexroots) | 5 | 23 | 0 | `binary`, `complexalgebraic`, `core`, `exact`, `polynomial`, `realalgebraic`, `realvariety`, `sturm`, `tarski` |
| [complexsplitting](../src/complexsplitting) | 3 | 13 | 0 | `complexalgebraic`, `complexcompositum`, `complexfactor`, `complexfield`, `complexroots`, `complexsubfield`, `compositum`, `core`, `cubicradical`, `polynomial`, `zassenhaus` |
| [complexsubfield](../src/complexsubfield) | 4 | 20 | 0 | `complexfield`, `core`, `exact`, `linear`, `matrix`, `polynomial` |
| [compositum](../src/compositum) | 3 | 47 | 0 | `binary`, `core`, `exact`, `numberfield`, `polynomial`, `realalgebraic`, `realminimal`, `realvariety`, `zassenhaus` |
| [core](../src/core) | 3 | 4 | 0 | — |
| [csscode](../src/csscode) | 2 | 9 | 0 | `algebra`, `binary`, `core`, `exact`, `gf2`, `homology`, `matrix`, `rowreduce` |
| [cubicradical](../src/cubicradical) | 3 | 5 | 0 | `complexfield`, `compositum`, `core`, `exact`, `numberfield`, `polynomial`, `realalgebraic`, `sturm`, `zassenhaus` |
| [cyclicrs](../src/cyclicrs) | 1 | 21 | 0 | `binary`, `core`, `galois`, `recurrence` |
| [cyclotomic](../src/cyclotomic) | 1 | 10 | 0 | `binary`, `core`, `exact`, `polynomial` |
| [cyk](../src/cyk) | 1 | 3 | 0 | `core` |
| [difference](../src/difference) | 1 | 4 | 0 | `avl`, `binary`, `core`, `exact` |
| [discretelog](../src/discretelog) | 2 | 7 | 4 | `binary`, `core`, `factor`, `modular`, `primality`, `primefield`, `trie` |
| [dp](../src/dp) | 2 | 2 | 0 | `binary`, `core` |
| [elimination](../src/elimination) | 8 | 330 | 0 | `berkowitz`, `core`, `exact`, `matrix`, `polynomial` |
| [elliptic](../src/elliptic) | 1 | 2 | 0 | `binary`, `core`, `finitefield`, `modular` |
| [exact](../src/exact) | 3 | 13 | 30 | `binary`, `core` |
| [exactcover](../src/exactcover) | 2 | 4 | 0 | `binary`, `core` |
| [exactfft](../src/exactfft) | 1 | 15 | 0 | `binary`, `core`, `cyclotomic`, `exact`, `fft` |
| [extensioncurve](../src/extensioncurve) | 3 | 7 | 0 | `binary`, `core`, `galois` |
| [f4](../src/f4) | 3 | 71 | 0 | `core`, `exact`, `groebner`, `linear`, `matrix`, `polynomial`, `sorting` |
| [factor](../src/factor) | 3 | 17 | 4 | `binary`, `core`, `modular`, `primality` |
| [fft](../src/fft) | 1 | 3 | 0 | `core` |
| [fglm](../src/fglm) | 4 | 90 | 0 | `core`, `exact`, `f4`, `heap`, `linearspan`, `polynomial`, `sorting` |
| [filteredcollapse](../src/filteredcollapse) | 1 | 6 | 0 | `collapse`, `core`, `exact`, `homology`, `matrix`, `persistence` |
| [finitefield](../src/finitefield) | 2 | 4 | 0 | `binary`, `core`, `modular`, `rowreduce` |
| [fixedfield](../src/fixedfield) | 3 | 8 | 0 | `complexautomorphism`, `complexfield`, `core`, `exact`, `linear`, `matrix` |
| [forms](../src/forms) | 7 | 542 | 0 | `binary`, `core`, `exact`, `polynomial` |
| [fppoly](../src/fppoly) | 5 | 34 | 0 | `binary`, `core`, `matrix`, `modular`, `primefield`, `rowreduce` |
| [galois](../src/galois) | 2 | 19 | 4 | `binary`, `core`, `fppoly`, `primefield` |
| [galoissolvability](../src/galoissolvability) | 1 | 3 | 0 | `complexsplitting`, `core`, `permgroup`, `splittinggalois` |
| [gaussian](../src/gaussian) | 4 | 12 | 0 | `avl`, `binary`, `core`, `exact`, `matrix`, `polynomial`, `positiveform`, `riemann`, `tensor` |
| [geometry](../src/geometry) | 1 | 3 | 0 | `core`, `exact`, `sorting` |
| [gf2](../src/gf2) | 3 | 13 | 0 | `algebra`, `core`, `matrix`, `rowreduce` |
| [graph](../src/graph) | 2 | 3 | 0 | `binary`, `core`, `heap` |
| [groebner](../src/groebner) | 1 | 46 | 0 | `core`, `exact`, `polynomial`, `sorting` |
| [heap](../src/heap) | 1 | 2 | 0 | `core` |
| [hodge](../src/hodge) | 4 | 116 | 0 | `binary`, `core`, `exact`, `forms`, `matrix`, `polynomial`, `positiveform`, `realalgebraic` |
| [homology](../src/homology) | 2 | 10 | 0 | `algebra`, `binary`, `chainhomology`, `core`, `exact`, `matrix`, `smith` |
| [huffman](../src/huffman) | 1 | 2 | 0 | `binary`, `core`, `heap` |
| [infer](../src/infer) | 1 | 4 | 0 | `core`, `unify` |
| [infogeom](../src/infogeom) | 6 | 15 | 0 | `core`, `exact`, `linear`, `matrix`, `polynomial`, `probability` |
| [linear](../src/linear) | 1 | 6 | 0 | `bareiss`, `binary`, `core`, `exact`, `matrix`, `rowreduce` |
| [linearspan](../src/linearspan) | 1 | 17 | 0 | `core`, `exact` |
| [listdecode](../src/listdecode) | 6 | 39 | 0 | `binary`, `core`, `fppoly`, `matrix`, `modular`, `primefield`, `rowreduce` |
| [lll](../src/lll) | 5 | 9 | 4 | `algebra`, `binary`, `core`, `exact`, `linear`, `matrix`, `smith` |
| [lz78](../src/lz78) | 1 | 3 | 0 | `binary`, `bitcodec`, `core`, `trie` |
| [markov](../src/markov) | 5 | 115 | 0 | `algebra`, `binary`, `core`, `exact`, `linear`, `matrix` |
| [matrix](../src/matrix) | 1 | 7 | 0 | `algebra`, `binary`, `core` |
| [maxflow](../src/maxflow) | 1 | 2 | 0 | `binary`, `core`, `graph` |
| [modular](../src/modular) | 3 | 7 | 0 | `algebra`, `binary`, `core`, `exact` |
| [mucalc](../src/mucalc) | 5 | 153 | 0 | `core`, `parity` |
| [ntt](../src/ntt) | 1 | 3 | 0 | `binary`, `core`, `fft`, `modular` |
| [numberfield](../src/numberfield) | 7 | 145 | 1 | `core`, `exact`, `linear`, `linearspan`, `matrix`, `polynomial`, `realalgebraic`, `realminimal`, `sturm`, `zassenhaus` |
| [orderedsturm](../src/orderedsturm) | 5 | 48 | 0 | `binary`, `core`, `exact`, `numberfield`, `polynomial`, `realalgebraic`, `sturm`, `tarski` |
| [pairing](../src/pairing) | 4 | 8 | 0 | `binary`, `core`, `extensioncurve`, `galois` |
| [parity](../src/parity) | 4 | 7 | 0 | `core` |
| [permgroup](../src/permgroup) | 3 | 12 | 0 | `avl`, `core` |
| [persistence](../src/persistence) | 4 | 9 | 0 | `core`, `exact` |
| [polynomial](../src/polynomial) | 6 | 136 | 8 | `binary`, `core`, `exact` |
| [positiveform](../src/positiveform) | 2 | 5 | 0 | `core`, `exact`, `matrix` |
| [prefixlogic](../src/prefixlogic) | 3 | 9 | 0 | `core`, `exact`, `polynomial`, `realcad`, `realformula` |
| [presentation](../src/presentation) | 2 | 8 | 0 | `binary`, `core`, `exact`, `matrix`, `smith` |
| [primality](../src/primality) | 3 | 13 | 9 | `binary`, `core`, `modular` |
| [primefield](../src/primefield) | 1 | 6 | 6 | `binary`, `modular`, `primality`, `rowreduce` |
| [primeprove](../src/primeprove) | 1 | 8 | 8 | `binary`, `core`, `factor`, `primality` |
| [probability](../src/probability) | 2 | 6 | 0 | `binary`, `core`, `exact` |
| [projection](../src/projection) | 3 | 32 | 0 | `core`, `elimination`, `exact`, `polynomial` |
| [puzzles](../src/puzzles) | 2 | 4 | 0 | `core`, `exactcover`, `sorting` |
| [quotient](../src/quotient) | 5 | 4 | 0 | `core`, `gf2`, `matrix`, `rowreduce` |
| [quotientfield](../src/quotientfield) | 2 | 5 | 0 | `algebra`, `binary`, `core`, `exact`, `fppoly`, `galois`, `numberfield`, `polynomial`, `primefield`, `quotient`, `realalgebraic`, `rowreduce` |
| [realalgebraic](../src/realalgebraic) | 6 | 158 | 2 | `binary`, `core`, `exact`, `linear`, `matrix`, `polynomial`, `sturm` |
| [realcad](../src/realcad) | 5 | 42 | 3 | `core`, `exact`, `polynomial`, `sturm` |
| [realclosed](../src/realclosed) | 1 | 11 | 0 | `cad`, `core`, `realcad`, `realformula` |
| [realformula](../src/realformula) | 3 | 112 | 0 | `core`, `polynomial`, `realcad` |
| [realminimal](../src/realminimal) | 3 | 43 | 0 | `binary`, `core`, `exact`, `polynomial`, `realalgebraic`, `sturm`, `zassenhaus` |
| [realnlsmt](../src/realnlsmt) | 4 | 183 | 0 | `cad`, `cdcl`, `circuit`, `core`, `polynomial`, `realcad`, `realformula`, `sat` |
| [realtower](../src/realtower) | 8 | 101 | 0 | `binary`, `core`, `exact`, `sturm` |
| [realvariety](../src/realvariety) | 6 | 124 | 0 | `binary`, `core`, `exact`, `f4`, `linear`, `matrix`, `polynomial`, `realalgebraic`, `sturm` |
| [recurrence](../src/recurrence) | 2 | 17 | 0 | `core`, `rowreduce` |
| [reedsolomon](../src/reedsolomon) | 1 | 4 | 0 | `binary`, `core`, `finitefield`, `matrix`, `modular`, `rowreduce` |
| [regex](../src/regex) | 2 | 2 | 0 | `core` |
| [relativecad](../src/relativecad) | 4 | 148 | 0 | `core`, `exact`, `numberfield`, `orderedsturm`, `sturm` |
| [relativehomology](../src/relativehomology) | 3 | 11 | 0 | `binary`, `chainhomology`, `core`, `exact`, `homology`, `matrix`, `smith` |
| [riemann](../src/riemann) | 4 | 9 | 0 | `core`, `exact`, `linear`, `matrix`, `positiveform` |
| [rips](../src/rips) | 1 | 6 | 0 | `core`, `exact`, `persistence`, `sorting` |
| [rowreduce](../src/rowreduce) | 1 | 2 | 0 | `core`, `matrix` |
| [runbinary](../src/runbinary) | 2 | 13 | 4 | `binary`, `core` |
| [ruplog](../src/ruplog) | 4 | 15 | 13 | `binary`, `cdcl`, `core`, `sat` |
| [sat](../src/sat) | 1 | 2 | 0 | `core` |
| [semialgebraic](../src/semialgebraic) | 3 | 174 | 0 | `cad2`, `core`, `polynomial`, `realalgebraic`, `realcad`, `sturm` |
| [sha256](../src/sha256) | 3 | 3 | 0 | `binary`, `core` |
| [signcad](../src/signcad) | 3 | 9 | 0 | `core`, `polynomial`, `realcad`, `realformula` |
| [simplex](../src/simplex) | 1 | 6 | 0 | `core`, `exact`, `matrix` |
| [simplexforms](../src/simplexforms) | 3 | 275 | 0 | `binary`, `core`, `exact`, `forms`, `polynomial` |
| [simplicialmap](../src/simplicialmap) | 2 | 30 | 0 | `chainhomology`, `core`, `exact`, `homology`, `matrix`, `smith` |
| [smith](../src/smith) | 5 | 15 | 3 | `algebra`, `binary`, `core`, `exact`, `linear`, `matrix` |
| [smt](../src/smt) | 1 | 5 | 0 | `cdcl`, `core`, `difference`, `sat` |
| [sorting](../src/sorting) | 1 | 2 | 0 | `core` |
| [spanning](../src/spanning) | 1 | 2 | 0 | `binary`, `core`, `graph`, `heap`, `sorting` |
| [splittinggalois](../src/splittinggalois) | 3 | 11 | 0 | `complexfield`, `complexsplitting`, `complexsubfield`, `core`, `exact`, `polynomial` |
| [statgeometry](../src/statgeometry) | 6 | 24 | 0 | `algebra`, `core`, `exact`, `gaussian`, `infogeom`, `linear`, `matrix`, `positiveform`, `riemann`, `tensor` |
| [sturm](../src/sturm) | 1 | 3 | 0 | `core`, `exact`, `polynomial` |
| [synthesis](../src/synthesis) | 2 | 11 | 0 | `cdcl`, `core`, `sat` |
| [tarski](../src/tarski) | 3 | 402 | 0 | `binary`, `core`, `exact`, `polynomial`, `realalgebraic`, `sturm` |
| [tensor](../src/tensor) | 4 | 12 | 0 | `algebra`, `core`, `matrix` |
| [trie](../src/trie) | 1 | 2 | 0 | `core` |
| [unify](../src/unify) | 1 | 2 | 0 | `core` |
| [zassenhaus](../src/zassenhaus) | 3 | 462 | 0 | `binary`, `core`, `exact`, `fppoly`, `modular`, `polynomial`, `primefield` |
| [zeroone](../src/zeroone) | 1 | 5 | 0 | `core`, `exact`, `matrix`, `simplex` |
