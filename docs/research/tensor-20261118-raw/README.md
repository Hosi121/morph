# Tensor cursor evidence

- `initial-abba.json.gz`: all 120 checked full-output runs, lossless. Each JSON includes input tensors and all expected complete targets; every selected library route compares its actual full tensors to those targets in every repetition. Uncompressed/compressed SHA-256, every block ratio and full timing ranges are in `summary.json`.
- `baseline-provenance.json.gz`, `candidate-provenance.json.gz`: lossless complete source manifests, commits, exact ELF and generated-C hashes; `provenance-summary.json` gives the readable metadata.
- `baseline-source-proof.json`, `invariants.json`: all 2,359 baseline tracked blobs verified; unchanged API/CLI/core source; canonical old-helper hashes.
- `candidate.patch.gz`: lossless production patch relative to the frozen CLI baseline.
- `profiles/*-functions.txt`: baseline/candidate gprofng summaries for raising and scalar contraction at dimensions three and five. Readable copies trim redundant EOF blank lines; matching `.txt.gz` files preserve the exact collector-display bytes. Raw collector stdout is text (it includes a collector header); `profile-outputs.json.gz` contains all eight parsed checked complete outputs.
- `handoff.json`: seven untracked archive objects with exact byte counts and SHA-256: two source tarballs, two native ELFs, two full generated C files in gzip, and eight full profiling experiments in one tar.gz. `profile-archive-replay.txt` confirms the archived experiment can be reopened after extraction.
- `test-{native,wasm-gc,js}.txt`, `check-native.txt`, `info.txt`, `fmt.txt`, `purity.txt`: final validation output.
- `pre-freeze-calibration.json.gz`: single candidate-tree runs of the original library before the CLI/baseline freeze, used only to check outputs and adequate repetition counts. It is not A/B evidence. `initial-candidate-smoke.json.gz` is the analogous sole cursor candidate smoke test before ABBA.

Reproduce with saved source/ELF artifacts and pinned SDK from the provenance. Build the same `src/cmd/tensorbench` CLI in independent trees under `tools/measure --cpu 4 ... --target native --release --deny-warn -j 1`. Run the unchanged comparison driver with six `--case` arguments: tiny, zero, raise3, raise5, scalar3, scalar5; `--groups 5`. The `--profile` CLI flag is a predeclared 32× diagnostic repetition multiplier, not used by ABBA. Profiling uses `gprofng collect app -p 1` and complete outputs remain checked. Do not use profiler CPU weights as process wall times.

The handoff directory and live experiment directories remain untracked pending root's hash-verified archival and cleanup. No further variants or input/count changes were made.
