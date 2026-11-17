# Independent comparison records

`native-initial.txt`, `test-js.txt`, and `test-wasm-gc.txt` retain completed 20/20
related regression results on each backend. `comparison-results.json` records
the original 5,306 QQ positions, independent auxiliary 40, and additional API
crosscheck 260 separately. `fmt.txt` is the scoped formatter result.

`generator-validation.txt` and `.json` distinguish Sympy mathematical
rederivation (`--check`) from standard-library stored-data consistency
(`python3 -S ... --check-stored`), including return codes and time after the
shared CPU-4 lock was acquired. Neither mode uses MoonBit observed results to
construct expectations. Only the fresh mode redoes the symbolic mathematics.

`oracles.json.gz` is the deterministic normalized independent dataset;
`oracle-summary.json` gives all counts and its uncompressed SHA-256.
`archived-oracles.json.gz` preserves the exact prior scratch dataset, including
its old elapsed-time metadata. Removing that metadata gives the same
mathematical object as the normalized dataset. No expected mathematical value
was changed. `archived-source.json` retains the prior incomplete review's source
record; `tested-source.json` identifies the currently compiled source, complete
compiler/Python versions and fixture/source hashes.

The two WB fixture files and their generator are committed at their package and
tools paths. `sha256.json` records their hashes and the small evidence files.
Generated fixtures contain full arbitrary-length rational numerator/denominator
literals. Complete component equality is tested, rather than checksums.
