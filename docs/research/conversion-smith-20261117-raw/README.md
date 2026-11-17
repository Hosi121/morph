# S01 Smith context evidence

- `abba.json.gz`: all 120 ABBA runs, complete outputs, checks and timings. Lossless gzip; uncompressed and compressed SHA-256 are in `summary.json`.
- `summary.json`: readable medians, all five block ratios, full sample ranges, affinity and raw hashes.
- `native-smoke.json.gz`: all six complete candidate outputs before timing.
- `provenance.json`: exact source manifests plus ELF/C hashes; `handoff/` contains the corresponding six archival objects (two source tarballs, two native ELFs, two full generated C files in gzip).
- `candidate.patch.gz`: exact baseline-relative production patch, losslessly compressed.
- `baseline-bytes-before.json` and `baseline-bytes-after.json`: all 2,211 tracked Git blob bytes verified before and after timing.
- `invariants.json`: unchanged public API and all bytes outside the two permitted helper bodies, plus old-helper oracle equivalence.
- `test-{native,wasm-gc,js}.log`, `check-native.log`, `fmt.log`, `info.log`, `purity.log`: final validation.

Reproduce after extracting the source snapshots into independent worktrees with the pinned compiler recorded in the raw JSON. Build each CLI under its own `tools/measure --cpu 4 tools/moon build src/cmd/smithcontextbench --target native --release -j 1`, then run the unchanged `tools/compare_field_kernels.py` with `--harness src/cmd/smithcontextbench`, `--groups 5` and cases `empty`, `one`, `many`, `bases`, `induced`, `connecting`. Do not edit baseline tracked libraries. Compilation must finish before starting the comparison. Timed runs use the saved ELFs and original checker costs.

`handoff/` files are intentionally untracked pending root's hash-verified archival and cleanup. All small evidence files and compressed complete raw output are committed.
