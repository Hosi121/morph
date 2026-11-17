# Active-row cursor trial, 2026-11-17 night sprint, round 3

Recommendation: reject `40328a1`. Baseline is unified
`4795f875270eb026cda25b7e509a0e60e8e6abb2`; frozen public-only CLI is
`ff324e1` (`src/cmd/nightcursorbench`). No follow-up was attempted. The hard
worker stop passed before evidence handoff, so no further source changes or
experiments were performed. The trial production code remains on its separate
branch for root disposition; this worker has not integrated or pushed it.

The producer represents a row as a known-zero prefix length and an active
suffix. Forward selection probes the active head, eliminates at that head,
and advances one source column; backward elimination aligns each stored basis
suffix to the target suffix. Full zero prefixes are restored once at the
reduction boundary. Appended transform columns remain in the suffix and take
part in every XOR. A boundary guard checks uniform shape and coverage of the
source columns without allocating Nat lengths. The exact original reduction
is retained as a fallback for nonzero column/base entry and malformed private
row shapes, preventing silent padding of short rows.

The existing independent legacy-reduction tests still compare complete rows,
pivots, transform columns and operation logs. Two added tests cover malformed
private entry/fallback cases and suffix-offset alignment. Native GF2 tests
pass 10/10. The generic checker region, public API metadata and the round-one
solve implementation are byte-identical to baseline; their source hashes are
recorded with the artifacts. Three-target consumer validation, purity and
global deny-warn were **not run for this candidate** before the hard stop.
Those are outstanding if root elects to use its production code.

Five native-release independent-process ABBA blocks use the identical six
public cases from round 2, including host Boolean full RREF/U/inverse oracles,
exact complete results and the original certificate checks on every factor
and CSS repetition. Every one of the 120 processes passed full-result checks.
The timer includes startup, fixtures/oracles, setup, operations, original
certificate costs and output. All builds and timings use the shared CPU4 lock
and `-j 1` compiler jobs; info has no `-j`.

| Case | Baseline ms | Cursor ms | Before / after | Favorable blocks |
| --- | ---: | ---: | ---: | ---: |
| Tiny 2×3 RREF | 136.098 | 173.615 | 0.784 | 0/5 |
| Sparse 24×24 RREF | 114.799 | 122.273 | 0.939 | 0/5 |
| Dense 24×24 RREF | 196.684 | 163.399 | 1.204 | 5/5 |
| Wide 12×48 RREF | 110.692 | 77.936 | 1.420 | 5/5 |
| Checked dense factor | 258.457 | 249.506 | 1.036 | 4/5 |
| CSS validation + checker | 125.127 | 123.245 | 1.015 | 3/5 |

Dense/wide direct RREF improves consistently, but tiny input takes about 28%
more time and sparse input about 6.5% more time. The ordinary CSS consumer has
only a small, uncertain difference. These costs and the larger representation/
guard/fallback implementation do not justify adoption in this bounded trial.
No whole-cohomology timing or memory claim is made. No additional variant or
threshold search was attempted after the deadline.

Every individual value and full payload is retained losslessly in
[cursor-abba.json.gz](night-cursors-20261117-raw/cursor-abba.json.gz), with
uncompressed/compressed SHA-256 and byte counts in
[artifacts.json](night-cursors-20261117-raw/artifacts.json). The readable
[summary.json](night-cursors-20261117-raw/summary.json) retains medians, ranges
and all block ratios. Baseline/candidate ELFs, exact source snapshots and
full generated native C are handed to the root archive; their hashes match
the measured artifacts. Root owns production disposition, integration,
remaining verification, push and worktree/archive cleanup.

再現用に、基準`4795f87`から凍結CLI・試作・テストをまとめた[差分](night-cursors-20261117-raw/candidate-from-4795f87.patch.gz)も公開しています。gzipを展開して適用できます。通常のライブラリには適用していません。
