# Canonical finite-prime Horner evaluation, 2026-11-17

## Decision and supported scope

Adopt one evaluate-only canonical arithmetic boundary. Median whole-process time
on the fixed mixed 512-bit-point fixture fell from 180.078 ms to 13.271 ms
(13.569× baseline/candidate); all five paired block ratios were 11.222–13.998×.
The tiny empty/constant control improved 1.581× and the field/input-setup one-shot
fixture improved 1.217×, with all five blocks favoring the candidate for both.
These are public API/process measurements including setup and checking.

The actual `listdecode.encode` route has a 1.030× process median but paired blocks
span 0.937–1.144×; its effect is unresolved. The dense canonical-point median is
likewise near one. No established list-decoding speedup, generic evaluation speed
guarantee, whole-decoder speedup or other-backend timing claim is made.

The unified baseline is `a9604b1270270b6edf9c10a6e0ef2a6d81c852ec`. Milestones:

- `d62ea8f`: freeze six public cases, including actual listdecode encoding.
- `9f635ca`: canonical Horner point boundary and independent regression tests.
- Evidence commit: this report, exact source/API audit, all samples and snapshots.

No follow-up algorithm was needed. Only the body of `fppoly.evaluate` changes in
production. Scale, derivative, other polynomial operations, field representation,
listdecode producers/checkers and all certificate algorithms are unchanged.

## Actual removed work and invariant

The baseline's recursive Horner captures the arbitrary public point and calls
`modular.multiply` plus `modular.add` for every coefficient. A large unreduced
point therefore enters repeated coefficient multiplications even though every
accumulator is a residue. This round's source audit supports that premise. It
does not rely on the earlier disproven idea that modular multiplication
re-reduces its operands: `modular.multiply` still reduces only its product.

For nonconstant input, the new implementation obtains the modulus once and reduces
the public point once. Opaque polynomial coefficients and the recursive accumulator
are canonical in `[0,p)`. The existing private `multiply_reduced` produces another
canonical residue; adding it to a coefficient yields a value below `2p`, so the
existing `add_reduced` uses one checked subtraction. This preserves the exact
Horner recurrence modulo p. The recursive highest constant coefficient can be
returned directly without multiplying the point by zero and reducing it again.

Empty and constant polynomials return before any point preparation. An unconditional
normalization at function entry would introduce unnecessary work for a huge point
whose value cannot affect those polynomials; that design was rejected by inspection
before implementation, rather than measured as a separate algorithm. Zero/unit
points, unreduced multiples of p and characteristic two satisfy the same canonical
invariant. GF2's representation/producer implementation is unchanged; the generic
public Horner implementation now establishes its parity residue once as well.

No mutable scratch, primitive numeric kernel, array, FFI, approximation, point cache
or sparse-polynomial rewrite is introduced. Recursion remains structural in the
immutable coefficient chain. Peak allocation/RSS and behavior at much larger degrees
were not measured.

## Consumer and checker independence

`listdecode.encode` in `src/listdecode/plan.mbt` constructs a public fppoly polynomial
from a checked message and evaluates it at each checked support point. Its points
are already canonical, so the large-unreduced-point gain cannot be transferred to
that consumer. The F17 benchmark uses n=17, k=8, agreements=16, multiplicity=1 and
weighted bound 15, with a full independent host codeword oracle.

`listdecode.check_candidate` calls `encode`, which shares the modified evaluation
arithmetic. Passing that checker alone is therefore not independent evidence for
this change, and no whole-program arithmetic independence is claimed. The benchmark
checks every returned symbol against independent host Int64 Horner arithmetic;
regression tests additionally retain the original generic modular-arithmetic Horner
as a second oracle. Existing checker calls remain enabled and their source bytes
are unchanged. `callsite-audit.json` records this dependency, original evaluate
source, unchanged producer/checker hashes and the proof that all source outside
the evaluate function body is identical to the baseline.

## Validation

Final fppoly plus actual listdecode consumer tests passed 66/66 on each of native,
wasm-gc and JS using `-j 1 --deny-warn`. All-target warning checks passed (408
compiler tasks executed), purity passed for 328 kernel files, and fppoly/listdecode
public API bytes are identical to the unified baseline. Exact commands, exit codes
and outputs are retained in `night-evaluation-20261117-raw/validation.json`;
interface hashes are in `api-diff.json`.

New tests exhaust every three-coefficient polynomial over F2, F3 and F5 at all
points from zero through `3p+1`, including unreduced constructor coefficients and
points. They also cover empty/constant polynomials, zero/unit/boundary points,
512-bit odd/even points, longer coefficient chains and primes through 65537.
Expected values use host Int64 arithmetic, with an independent modular-doubling
oracle for the huge point's residue. Products fit Int64 in these bounded fixtures.
Every result is also compared to the retained old generic Horner and checked to
remain below p. Existing listdecode tests include exhaustive independent small
message/codeword enumeration and error/validation cases; their checkers are not
used as a substitute for the host oracle.

## Frozen public comparison

The two native release executables were built with `-j 1 --deny-warn`. Builds,
tests and measurements use the shared `tools/measure --cpu 4` lock. Each of six
fixed cases has five independent ABBA blocks, producing ten baseline and ten
candidate processes (120 total). All full outputs and oracle checks passed.
After the pre-edit calibration smoke, counts were fixed before the first source
comparison; no input, expected result or count changed during comparison.

Whole-process time includes startup, setup, oracle preparation, one checked warm-up,
the operation batch and all checking/serialization. `elapsed_us` covers only the
batch, also including every evaluation/symbol check and full-result serialization.
`setup-one-shot17` repeats field construction and the public polynomial constructor
inside each iteration. Values below are median milliseconds per complete process,
not per single evaluation. Ratios are baseline/candidate; paired block ranges
show variation rather than statistical confidence intervals.

| Case | Iterations | Before ms | After ms | Process ratio | Five block ratios | Inner ratio |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| odd65537-reduced | 200 | 74.234 | 72.711 | 1.021× | 0.991–1.066× | 1.019× |
| odd257-unreduced | 25 | 180.078 | 13.271 | 13.569× | 11.222–13.998× | 16.094× |
| gf2-mixed | 9000 | 44.657 | 42.236 | 1.057× | 1.029–1.264× | 1.052× |
| tiny-constant | 150000 | 33.555 | 21.222 | 1.581× | 1.405–1.712× | 1.669× |
| setup-one-shot17 | 30000 | 53.359 | 43.832 | 1.217× | 1.153–1.373× | 1.235× |
| listdecode-encode17 | 1500 | 59.463 | 57.740 | 1.030× | 0.937–1.144× | 1.032× |

`odd65537-reduced` evaluates a dense degree-32 input at three ordinary canonical
points. `odd257-unreduced` evaluates at 0, 1, p-1, p, p+1 and two 512-bit points
(`2^511+19`, `2^511+18`); its large improvement is bounded to this mixture of inputs.
`gf2-mixed` uses unreduced input coefficients and the same point categories.
`tiny-constant` combines zero and constant polynomials with huge/zero/unit points.
`setup-one-shot17` constructs the field and a degree-one polynomial and evaluates
an unreduced small point. `listdecode-encode17` calls the actual public encoder
and checks its full 17-symbol codeword every iteration.

The dense and actual-consumer cases have overlapping ranges and paired ratios on
both sides of one, so their small median differences remain unresolved. GF2's
median process ratio is 1.057× with all paired blocks above one, but the observed
ranges still overlap and no same-binary A/A noise control was run. The robust
large-point, tiny and one-shot evidence supports adoption without claiming every
canonical-point workload is faster. No decoder search, interpolation throughput,
other machine/backend or memory result is inferred from these measurements.

## Reproduction and retained artifacts

`before-snapshot.json` and `after-initial-snapshot.json` record compiler, commit,
per-file source hashes and frozen executable hashes. The ELFs are preserved in
ignored `.tools/night-evaluation-20261117/{before,after-initial}.exe`. Baseline
tracked libraries were checked byte-identical to a9604b1 before and after
measurement; only frozen command sources were copied into its worktree. No build
directory is shared. Both archived ELF hashes were checked again after timing. The frozen CLI ELF size
grew from 597008 to 614744 bytes; this is executable size, not a peak
allocation/RSS measurement (`artifact-sizes.json`).

`initial-abba.json` retains all durations, full stdout/stderr, complete outputs,
source-manifest hashes and executable/harness/compiler hashes. `calibration.json`
retains the pre-edit smoke at its original counts. `freeze_snapshot.py` reproduces
the archive metadata. The parent must archive the ignored ELFs before worktree
cleanup.

```sh
tools/measure --cpu 4 python3 /home/hosi/morph/tools/compare_field_kernels.py \
  --before .tools/night-evaluation-20261117/before.exe \
  --after .tools/night-evaluation-20261117/after-initial.exe \
  --before-root /home/hosi/morph-night-r2-before \
  --after-root /home/hosi/morph-night-fp \
  --harness src/cmd/nightevalbench \
  --case odd65537-reduced --case odd257-unreduced --case gf2-mixed \
  --case tiny-constant --case setup-one-shot17 --case listdecode-encode17 \
  --groups 5 --output docs/research/night-evaluation-20261117-raw/initial-abba.json
```

Only local milestone commits are supplied by this worker. No push, merge,
deployment, shared-index update or worktree removal was performed.
