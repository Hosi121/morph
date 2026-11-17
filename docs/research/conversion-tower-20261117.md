# Recursive constants in real towers: rejected sharing experiment

Baseline `a63dcbca9a07a5c875400c4305bf2b15585b3aa3`. The user requested continued work after a read-only conversion audit. This bounded pass examined only N03: duplicate construction in `realtower.raw_rational` and its `raw_one` callers. **Both variants are rejected; production api.mbt is restored byte-for-byte to the baseline in `b2a687550fb2a56de520e9443fb66be4f4cf0a76`.** No public API, proof, field context, selected root, fuel rule, arithmetic order or error behavior is changed in the final tree.

## Mechanism and invariants

The old recursive embedding produces Base(q) over Rationals. At Extension(parent), it separately embeds q and one in the parent, then wraps singleton numerator/denominator chains. Tower depth is required by the field representation; rebuilding identical parent units is the candidate redundancy. Representation and Chain are immutable, and their physical sharing is not observable through structural Eq or Debug. The same selected field and root interval remain attached to every Scalar.

The initial variant (`81f7667`, measured snapshot `47e0aad`) returns `(q_rep, one_rep)` together from one parent recursion and shares the denominator chain. Rationals => Base(q) stays exactly as before. Generated native C contains tuple malloc/free/reference-count work at each helper level. The one permitted follow-up (`677d4c2`) removes the tuple: recursively obtain the parent constant once, then build its unit as Base(1) at depth zero, or Fraction(d,d) using the existing denominator d at an extension. By induction, the parent result has exactly the old constant structure and d is the singleton parent-unit chain. Both constructed values are structurally equal to their old forms. No Field cache or preparation API is introduced.

For depth h, source Representation constructor calls change from 2^(h+1)-1 to 2h+1 (heights 0..4: old 1/3/7/15/31, candidate 1/3/5/7/9). Source Cons calls change from 2^(h+1)-2 to 2h. The first variant also creates transient tuples, confirmed in generated C; the follow-up eliminates that helper/type. These are construction facts, not measured heap savings or whole-operation complexity: structural Eq, Debug and exact sign/checker computations can still revisit both logical branches. Peak RAM, allocations and retained heap were not measured.

raw.mbt, including raw_one and raw_multiply equality order, all other arithmetic, checkers, Field/context data and public interfaces remain byte-identical throughout. Both patches touch only api.mbt. The final production difference is empty.

## Correctness and frozen public cases

The retained white-box oracle is the exact old two-branch recursive raw_rational, separate from the candidates. A Python Fraction generator supplies 12 normalization rows across depths 0..4 (60 instances), including 0/9, +/-1, ordinary positive/negative fractions, 6/9, -14/21 and integer reductions. Tests recursively check every numerator/denominator Base leaf and exact singleton Fraction shape, old full Representation Eq, scalar/poly one and zero, opposite selected-root context rejection, certificate rejection and actual nonunit products/deep-one multiplication. Four new tests supplement the existing package suite. Experimental native checks pass 101/101 for both variants.

Frozen public CLI is `src/cmd/towerconstantbench`, initial commit `8264944`, JSON protocol fix `47e0aad`. Each repeated operation checks full Representation and field equality and runs scalar_sign plus check_scalar. All representations are printed in full. Warm cases prepare checked linear extensions, exercising depths 0,1,2,3 and4; the combined depth3+4 case is an aggregate, not separate per-depth timing. The upper scalar case constructs two selected positive quadratic sqrt(2) extensions, multiplies nonunit rational constants and multiplies a real generator by one in both orders. It is a real public arithmetic path, not a large application benchmark. The cold case rebuilds depth-two checked linear extensions inside each iteration. Setup explicitly checks systems/roots and adjoin performs its own unchanged validation.

The inner timer includes every construction, full Eq, sign calculation and checker, and excludes setup for warm cases and one final serialization. Cold setup remains inside that case's inner timer. Whole-process measurement includes process startup, reference preparation, checked field setup, warmup operation, computation, checks and full serialization. No verifier cost was removed to improve a ratio. CLI reference constants use the old public ancestor embed route; arithmetic/checkers share dependencies, so checker success alone is not an independent proof. The old recursive oracle and Python leaf expectations provide additional evidence; no formal source-translation proof is claimed.

A protocol-only first attempt stopped before recording any comparison sample because Debug Repr contained unescaped newlines. The common harness was fixed using Json::string and Json::array.stringify, re-frozen and rebuilt on both sides. No arithmetic/checking result failed in that attempt. Its zero-sample error report, old source hashes, old CLI files and old ELFs remain available. Initial and follow-up below are the two valid series; no performance runs or negative controls were discarded.

## Results and rejection

Native release, shared CPU4 flock, five ABBA blocks per six-case series; all 240 valid process runs pass full output comparison. Ratios are baseline/candidate, so above one favors the candidate. The baseline was copied/built under the shared lock before production edits; only the worker's frozen CLI was added, and all tracked baseline source/tools/module/formal bytes remain unchanged. Candidate and baseline have separate build trees, saved immutable ELFs and matching harness hashes. No timing ran alongside a build.

### Initial variant

| Case | Before ms | Candidate ms | Process ratio | ABBA block range | Inner ratio |
|---|---:|---:|---:|---:|---:|
| embed-base | 10.552 | 10.921 | 0.966x | 0.901–1.076 | 0.981x |
| embed-depth1 | 11.581 | 12.286 | 0.943x | 0.847–1.072 | 0.934x |
| embed-depth2 | 10.692 | 10.567 | 1.012x | 0.851–1.090 | 1.017x |
| embed-depth3-4 | 14.225 | 13.281 | 1.071x | 0.979–1.244 | 1.098x |
| multiply-depth2 | 3.219 | 3.343 | 0.963x | 0.664–1.223 | 0.964x |
| cold-setup-depth2 | 5.085 | 5.888 | 0.864x | 0.850–0.987 | 0.948x |

### Followup variant

| Case | Before ms | Candidate ms | Process ratio | ABBA block range | Inner ratio |
|---|---:|---:|---:|---:|---:|
| embed-base | 11.481 | 12.041 | 0.953x | 0.893–1.103 | 0.945x |
| embed-depth1 | 13.894 | 12.596 | 1.103x | 0.938–1.161 | 1.118x |
| embed-depth2 | 11.834 | 11.401 | 1.038x | 0.969–1.138 | 1.018x |
| embed-depth3-4 | 15.046 | 14.217 | 1.058x | 0.961–1.126 | 1.085x |
| multiply-depth2 | 3.541 | 3.477 | 1.018x | 0.791–1.200 | 1.003x |
| cold-setup-depth2 | 6.137 | 6.699 | 0.916x | 0.743–1.215 | 1.008x |

The initial tuple variant has weak deep-only improvement and negative shallow/setup controls; cold setup is below parity in all five process blocks. The follow-up removes the tuple cost and improves depth1/2/3+4 medians, but base and cold process medians remain below parity, real multiplication is near parity with wide block ranges, and the small checked processes are noisy. These results do not establish a robust ordinary-path benefit sufficient to adopt either variant. No third variant, longer retuned case or verifier-free timing was attempted. The two series are retained separately rather than pooling ratios or subtracting checker costs. Rejection is the completed outcome, not a claim that immutable sharing can never help at greater depths or in another workload.

## Final checks and reproduction

After restoring the baseline production code, realtower passes native, wasm-gc and JS: **101/101 each**, with deny-warn. Scoped all-target static check passes (45 tasks); API info passes (27 tasks) and realtower's generated public interface is byte-identical. Formatting and the independent generator --check pass; global purity passes 333 production kernel files; formal drift passes 32 reviewed regions and explicitly is not a translation proof. Root owns broader integration checks; this worker does not rerun unrelated package graphs.

Reproduce by building baseline a63dcbc and either applying the corresponding api-only patch or checking out the measured snapshot, copying the same frozen towerconstantbench files to both dedicated trees, and saving each native release ELF before another build. Use tools/measure --cpu 4 with moon build/test -j1 (moon info has no jobs option). Then run tools/compare_field_kernels.py with the six frozen case names and --groups 5. Exact original driver arguments, source/executable/harness hashes, compiler/platform strings, all block medians/ranges and raw/gzip checksums are in the summary and raw reports.

| Variant | Measured source | Source manifest SHA-256 | ELF SHA-256 |
|---|---|---|---|
| Baseline + frozen CLI | a63dcbca9a07a5c875400c4305bf2b15585b3aa3 | 745ceea5245350f1b17dabca3b4d099e994f9e8f3fdcf6a87e9f8ebadf90d817 | f7fdf24d81bb88420db28206817af09ef716f9c2fd3b6b7f7dc00db857b2727d |
| initial | 47e0aadb11a2a27c65902d23db5df59051b29fb8 | 74dee6b1a9411671dfea2e9abe427a8eb84968d050cc9eecdc173ab4b649c4ee | 8b69c29e8f3d00b34e06dc2905ee445eba1218bee7bc83a5c8699d98bf10f666 |
| followup | 677d4c2f337f90ace5725aa79491d93f30f3d3e6 | 4bbb7cf64af690942dbed71b99d5ac80fe8344905574f1aa19954a462ce86525 | f5772fa42feeb4c9f4a866ac93fdb97b8750ad54cba83fb7217000702aed8e23 |

Evidence:

- [Initial full checked raw, gzip](conversion-tower-20261117-initial.json.gz) and [follow-up full checked raw, gzip](conversion-tower-20261117-followup.json.gz).
- [Summary, all block ratios, source/ELF/harness and raw/gzip hashes](conversion-tower-20261117-summary.json).
- [Validation receipt](conversion-tower-20261117-validation.json) and [full validation logs](conversion-tower-20261117-validation.txt).
- [Initial production-only patch](conversion-tower-20261117-initial.patch) and [follow-up production-only patch](conversion-tower-20261117-followup.patch).
- [Zero-sample protocol report](conversion-tower-20261117-protocol-v0.json.gz) and [protocol error log](conversion-tower-20261117-protocol-v0.txt).
- [Independent Fraction generator](../../tools/generate_tower_constant_fixtures.py); root may register its --check in the shared gate.

All three benchmark ELFs, both protocol ELFs, old CLI files, raw reports and baseline/initial/follow-up full generated C are retained under `.tools/conversion-tower-20261117/` for root archival, with exact paths/hashes in the summary. This worker does not push or remove worktrees/ELFs.
