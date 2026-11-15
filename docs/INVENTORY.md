# ソースから生成した一覧

`python3 tools/inventory.py`で再生成する。手書きの集計値を正本にしない。
テスト欄はソース上の宣言数で、成功数・独立性・網羅率を表さない。
bench欄もgroup数で、group内部の個別計測数とは異なる。

算法の核：65パッケージ、113ソース。
核のテスト宣言：463、bench group：123。
testsupport・cmd・benchmarksは核の集計から除外する。

| パッケージ | 核ソース | テスト宣言 | bench group | 直接の核依存 |
| --- | ---: | ---: | ---: | --- |
| [aes](../src/aes) | 4 | 14 | 0 | `binary`, `core`, `fppoly`, `galois`, `primefield`, `trie` |
| [aho](../src/aho) | 1 | 2 | 0 | `core`, `trie` |
| [algebra](../src/algebra) | 1 | 0 | 0 | `binary`, `exact` |
| [autodiff](../src/autodiff) | 2 | 2 | 0 | `algebra`, `binary`, `core`, `exact` |
| [avl](../src/avl) | 1 | 2 | 0 | `binary`, `core` |
| [bdd](../src/bdd) | 4 | 13 | 4 | `binary`, `circuit`, `core`, `sat` |
| [binary](../src/binary) | 3 | 19 | 6 | `core` |
| [bipartite](../src/bipartite) | 1 | 3 | 0 | `core` |
| [bitcodec](../src/bitcodec) | 1 | 2 | 0 | `binary`, `core` |
| [boolean](../src/boolean) | 1 | 2 | 0 | `core` |
| [cdcl](../src/cdcl) | 4 | 29 | 43 | `binary`, `core`, `sat` |
| [cek](../src/cek) | 1 | 3 | 0 | `core`, `infer` |
| [circuit](../src/circuit) | 2 | 3 | 0 | `boolean`, `core`, `sat` |
| [core](../src/core) | 3 | 4 | 0 | — |
| [cyclicrs](../src/cyclicrs) | 1 | 21 | 0 | `binary`, `core`, `galois`, `recurrence` |
| [cyclotomic](../src/cyclotomic) | 1 | 10 | 0 | `binary`, `core`, `exact`, `polynomial` |
| [cyk](../src/cyk) | 1 | 3 | 0 | `core` |
| [difference](../src/difference) | 1 | 4 | 0 | `avl`, `binary`, `core`, `exact` |
| [discretelog](../src/discretelog) | 2 | 7 | 4 | `binary`, `core`, `factor`, `modular`, `primality`, `primefield`, `trie` |
| [dp](../src/dp) | 2 | 2 | 0 | `binary`, `core` |
| [elliptic](../src/elliptic) | 1 | 2 | 0 | `binary`, `core`, `finitefield`, `modular` |
| [exact](../src/exact) | 1 | 11 | 21 | `binary`, `core` |
| [exactcover](../src/exactcover) | 2 | 4 | 0 | `binary`, `core` |
| [exactfft](../src/exactfft) | 1 | 15 | 0 | `binary`, `core`, `cyclotomic`, `exact`, `fft` |
| [factor](../src/factor) | 3 | 17 | 4 | `binary`, `core`, `modular`, `primality` |
| [fft](../src/fft) | 1 | 3 | 0 | `core` |
| [finitefield](../src/finitefield) | 2 | 4 | 0 | `binary`, `core`, `modular`, `rowreduce` |
| [fppoly](../src/fppoly) | 4 | 19 | 0 | `binary`, `core`, `matrix`, `modular`, `primefield`, `rowreduce` |
| [galois](../src/galois) | 2 | 19 | 3 | `binary`, `core`, `fppoly`, `primefield` |
| [geometry](../src/geometry) | 1 | 3 | 0 | `core`, `exact`, `sorting` |
| [graph](../src/graph) | 2 | 3 | 0 | `binary`, `core`, `heap` |
| [groebner](../src/groebner) | 1 | 46 | 0 | `core`, `exact`, `polynomial`, `sorting` |
| [heap](../src/heap) | 1 | 2 | 0 | `core` |
| [huffman](../src/huffman) | 1 | 2 | 0 | `binary`, `core`, `heap` |
| [infer](../src/infer) | 1 | 4 | 0 | `core`, `unify` |
| [linear](../src/linear) | 1 | 3 | 0 | `core`, `exact`, `matrix`, `rowreduce` |
| [lll](../src/lll) | 5 | 9 | 4 | `algebra`, `binary`, `core`, `exact`, `linear`, `matrix`, `smith` |
| [lz78](../src/lz78) | 1 | 3 | 0 | `binary`, `bitcodec`, `core`, `trie` |
| [matrix](../src/matrix) | 1 | 3 | 0 | `algebra`, `binary`, `core` |
| [maxflow](../src/maxflow) | 1 | 2 | 0 | `binary`, `core`, `graph` |
| [modular](../src/modular) | 3 | 4 | 0 | `algebra`, `binary`, `core`, `exact` |
| [ntt](../src/ntt) | 1 | 3 | 0 | `binary`, `core`, `fft`, `modular` |
| [polynomial](../src/polynomial) | 1 | 3 | 0 | `binary`, `core`, `exact` |
| [primality](../src/primality) | 3 | 13 | 9 | `binary`, `core`, `modular` |
| [primefield](../src/primefield) | 1 | 5 | 6 | `binary`, `modular`, `primality`, `rowreduce` |
| [primeprove](../src/primeprove) | 1 | 8 | 8 | `binary`, `core`, `factor`, `primality` |
| [puzzles](../src/puzzles) | 2 | 4 | 0 | `core`, `exactcover`, `sorting` |
| [recurrence](../src/recurrence) | 2 | 17 | 0 | `core`, `rowreduce` |
| [reedsolomon](../src/reedsolomon) | 1 | 4 | 0 | `binary`, `core`, `finitefield`, `matrix`, `modular`, `rowreduce` |
| [regex](../src/regex) | 2 | 2 | 0 | `core` |
| [rowreduce](../src/rowreduce) | 1 | 0 | 0 | `core`, `matrix` |
| [runbinary](../src/runbinary) | 2 | 13 | 3 | `binary`, `core` |
| [ruplog](../src/ruplog) | 4 | 12 | 5 | `binary`, `cdcl`, `core`, `sat` |
| [sat](../src/sat) | 1 | 2 | 0 | `core` |
| [sha256](../src/sha256) | 3 | 3 | 0 | `binary`, `core` |
| [simplex](../src/simplex) | 1 | 6 | 0 | `core`, `exact`, `matrix` |
| [smith](../src/smith) | 5 | 13 | 3 | `algebra`, `binary`, `core`, `exact`, `linear`, `matrix` |
| [smt](../src/smt) | 1 | 5 | 0 | `cdcl`, `core`, `difference`, `sat` |
| [sorting](../src/sorting) | 1 | 2 | 0 | `core` |
| [spanning](../src/spanning) | 1 | 2 | 0 | `binary`, `core`, `graph`, `heap`, `sorting` |
| [sturm](../src/sturm) | 1 | 3 | 0 | `core`, `exact`, `polynomial` |
| [synthesis](../src/synthesis) | 2 | 11 | 0 | `cdcl`, `core`, `sat` |
| [trie](../src/trie) | 1 | 2 | 0 | `core` |
| [unify](../src/unify) | 1 | 2 | 0 | `core` |
| [zeroone](../src/zeroone) | 1 | 5 | 0 | `core`, `exact`, `matrix`, `simplex` |
