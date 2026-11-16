# Characteristic-two polynomial arithmetic

[ドキュメント](../../README.md) / [探索・改善記録](../README.md)

このページはFp多項式・GF(2^m)・巡回RSの性能比較と原ログを保存します。
採用した経路は[基礎部品の最適化](../../KERNELS.md)、算法の説明は[符号の章](../../handbook/coding-cryptography.md)を参照してください。
CPU時間・wall時間・ホスト負荷の条件を分け、固定幅案などの棄却理由も残しています。

The measured change replaces generic modular coefficient arithmetic in `Fp[x]`
when the checked prime is two. Public construction still reduces arbitrary Binary
coefficients, now by their low bit. Internal canonical coefficients contain only
zero and one: addition cancels equal nonzero coefficients, multiplication uses
shifts and XOR, and monic normalization/inverting the leading one are identities.
The general-prime algorithms and public interfaces are unchanged.

This is an exact symbolic implementation, not a native-integer kernel. No
constant-time, cryptographic security, or formal proof claim follows from these
measurements or tests.

## Frozen comparison

- Library baseline: `88c967b3913ba2bc5d59b995b865402e6b687e23`.
- Identical benchmark harness: `d3894844d1133d9fbd47fe27f0d2e2bbc85f178c`.
- Candidate: `62676b3626389f773802c59535ec1890830368e1`.
- Baseline ELF SHA256: `525e2e9e8765ff4fc26058e6d59ed8122e9c9d38a39b9f383822917e1b076599`.
- Candidate ELF SHA256: `97620938caaa47e1ecd27dc462a96c4f6c70f69da0596b6fad1c0a4dfc95e237`.

Both binaries use MoonBit v0.10.20 native release, GCC 13.3, `-O2 -fwrapv
-fno-strict-aliasing -ffp-contract=off`, and the default mimalloc runtime. See
`environment.json` for complete versions. Each independent process is pinned to
logical CPU6 of an Intel Core Ultra 7 255H under WSL2. Order is A/B/A/B/A/B,
with three processes per binary. No compilation by this agent overlaps timed
runs. Another agent benchmarks Binary on CPU4; other system activity is not
stopped. Per-process load averages, ELF hashes, and timestamps are retained.

Each MoonBit benchmark uses five measured batches after calibration/warm-up;
the standard `core/bench` runner targets approximately 100ms per sample and
summarizes/winsorizes inner samples. Reported values below are the median of the
three independent process means, in microseconds per operation. The raw runner
stdout and JSON summaries retain dispersion within and between processes.

| Workload | Baseline µs | Candidate µs | Baseline / candidate |
| --- | ---: | ---: | ---: |
| Fp2 polynomial multiply, 64×32 coefficients | 243.671 | 10.746 | 22.68× |
| Fp2 polynomial divide, 95 by 32 coefficients | 3835.145 | 143.651 | 26.70× |
| Fp2 extended Euclid, 16/14 coefficients | 94.734 | 8.188 | 11.57× |
| Fp5 polynomial multiply, 64×32, control | 611.238 | 601.787 | 1.02× |
| GF256 multiply, 83×202 | 41.044 | 4.544 | 9.03× |
| GF256 inverse, 83 | 43.876 | 5.212 | 8.42× |
| GF9 multiply, control | 3.003 | 3.091 | 0.97× |
| RS15 t=2 decode, two fixed errors | 1095.790 | 183.073 | 5.99× |
| RS255 t=2 decode, two fixed errors | 37789.761 | 5253.659 | 7.19× |

The small GF9 control is approximately 3% slower in this run. The Fp5 control is
noisy (candidate process means 572.804–685.250µs); these data do not establish an
improvement for general primes. Shared Binary changes are deliberately absent
from both binaries. Later combined measurements must identify their own SHA
and must not add these speedup ratios together.

The exact fixed input formulas, setup outside timed closures, modulus choices,
and error positions are in `src/galois/perf_wbtest.mbt`. GF256 multiplication uses
the AES modulus 0x11b; RS255 uses 0x11d. RS15 uses 0x13. The same messages and
errors are used by both binaries; decoded codewords are checked before timing.

## Correctness and diagnosis

The existing polynomial/extension-field/RS tests plus new characteristic-two
tests cover exhaustive GF256 products for both AES and RS moduli (65,536 pairs
per modulus), every nonzero inverse, huge unreduced Binary coefficients/scalars,
polynomial normalization, zero values, field mismatch, and error precedence.
The GF256 oracle is native shift/XOR multiplication plus Fermat inversion,
independent of the polynomial Euclidean implementation. Existing general-prime
small exhaustive arithmetic and factorization fixtures remain in the suite.
All 56 tests pass on native, Wasm GC, and JavaScript; the kernel purity audit
and generated public API snapshots are unchanged.

```sh
tools/moon test src/fppoly src/galois src/cyclicrs --target native
tools/moon test src/fppoly src/galois src/cyclicrs --target wasm-gc
tools/moon test src/fppoly src/galois src/cyclicrs --target js
python3 tools/audit_purity.py
tools/moon info src/fppoly src/galois
git diff --exit-code -- src/fppoly/pkg.generated.mbti src/galois/pkg.generated.mbti
```

The `baseline-gprof.txt` instrumented RS diagnostic attributes about 35% of
sampled self time to `moonbit_drop_object`, 16% to `mi_free`, and 14% to
`Binary.divide_bits` (about 19 million calls). `fppoly.trim` is called about
1.4 million times. This supports targeting modular reduction and allocation;
gprof sampling/instrumentation does not prove causality. Instrumented execution
is excluded from the timing comparison.

## Reproduction

Build the identical harness at each source revision, save each ELF separately,
and finish both builds before measuring:

```sh
tools/moon bench src/galois/perf_wbtest.mbt --target native --release --build-only
cp _build/native/release/bench/galois/galois.whitebox_test.exe .tools/variant.exe
python3 docs/bootstrap/gf2-performance/measure.py .tools/variant.exe label SOURCE_SHA
```

`measure.py` invokes the native driver's file-range protocol
`perf_wbtest.mbt:0-2` rather than a JSON argument. Its default CPU is 6. Retain the
same harness/input, compiler, flags, affinity, benchmark counts, and timing
order when comparing another implementation.

For the separate gprof diagnostic, copy the generated C alongside the ELF and
compile/link it with `-pg`:

```sh
gcc -pg -O2 -fwrapv -fno-strict-aliasing -ffp-contract=off \
  -DMOONBIT_ALLOCATOR=MOONBIT_ALLOCATOR_MIMALLOC -I .tools/moon/include \
  -c .tools/gfperf/baseline.c -o .tools/gfperf/baseline.profile.o
gcc -pg -O2 .tools/moon/lib/libmoonbitrun.o .tools/gfperf/baseline.profile.o \
  _build/native/release/bench/libruntime.a -lm .tools/moon/lib/libbacktrace.a \
  -o .tools/gfperf/baseline.profile.exe
GMON_OUT_PREFIX=.tools/gfperf/gmon-baseline-rs taskset -c 6 \
  .tools/gfperf/baseline.profile.exe perf_wbtest.mbt:1-2
gprof .tools/gfperf/baseline.profile.exe .tools/gfperf/gmon-baseline-rs.* > report.txt
```

## Reusing reduced coefficients

Candidate `1b3fee3` keeps the same frozen Binary base and removes repeated public
normalization after private modular arithmetic. Such coefficients are already
reduced; only high zeros need trimming. Negation preserves nonzero leading
coefficients, and shifting a nonzero polynomial preserves normalization. Public
construction still reduces arbitrary input. The new huge-scalar regression
checks residues of 2^1000 in Fp3/Fp5/Fp7 with an independent repeated native
modular-power oracle, cancellation, zero products, and shifted division.
All 57 tests pass on native, Wasm GC, and JavaScript; purity and public API
snapshots remain unchanged.

`reduced-control-*` reruns `62676b3`; `reduced-*` runs `1b3fee3`, in alternating
order with three independent processes each. Compiler, affinity, harness, and
inputs match the earlier comparison. Medians of process means are:

| Workload | Characteristic-two candidate µs | Reduced-result candidate µs | Ratio |
| --- | ---: | ---: | ---: |
| Fp2 multiply 64×32 | 10.783 | 10.416 | 1.04× |
| Fp2 divide 95/32 | 143.574 | 130.230 | 1.10× |
| Fp2 extended Euclid 16/14 | 8.352 | 7.818 | 1.07× |
| Fp5 multiply, control | 594.338 | 618.080 | 0.96× |
| GF256 multiply 83×202 | 4.510 | 4.267 | 1.06× |
| GF256 inverse 83 | 5.216 | 4.888 | 1.07× |
| GF9 multiply, control | 3.057 | 2.509 | 1.22× |
| RS15 two-error decode | 191.870 | 177.640 | 1.08× |
| RS255 two-error decode | 5559.954 | 5235.609 | 1.06× |

GF9 improves beyond the small regression in the first change. Fp5 is 4% slower
by this median; candidate process means span 575.688–624.327µs, so this experiment
does not establish a general-prime polynomial throughput improvement. The
control slowdown is retained as a limitation. See `reduced-summary.json` and all
raw reports instead of treating the small ratios as universal speedups.

## Monomial cancellation and one-pass shifts

Long division originally forms a monomial and multiplies the divisor by it.
`17bf360` instead scales the divisor and shifts it directly, and omits multiplying
the leading one in characteristic two. This candidate alone is **not selected**:
in a quiet three-pair comparison, Fp2 division becomes 125.482→139.683µs (11%
slower), although GF256 inversion becomes 4.828→4.434µs. The existing shift uses
`append(replicate(n, zero), tail)`, allocating the low-zero prefix twice. The
characteristic-two monomial multiplier had allocated that prefix once.

`f898e42`, applied after `17bf360`, constructs the prefix in one recursive pass,
sharing the immutable coefficient tail. Both changes together remove the
division regression. Comparison below uses the same `1b3fee3` control, same
Binary base, same nine workloads, and three independent processes per ELF.
Order is A/B/B/A/A/B. Root and other project agents withheld heavy CPU jobs for
the recorded quiet window ending 15:17 UTC; all these measurements completed
before 15:16:25 UTC. Other host activity remains uncontrolled.

| Workload | Reduced-result control µs | One-pass cancellation candidate µs | Ratio |
| --- | ---: | ---: | ---: |
| Fp2 multiply 64×32 | 11.042 | 10.277 | 1.07× |
| Fp2 divide 95/32 | 131.475 | 119.966 | 1.10× |
| Fp2 extended Euclid 16/14 | 7.964 | 7.163 | 1.11× |
| Fp5 multiply, control | 606.322 | 604.968 | 1.00× |
| GF256 multiply 83×202 | 4.120 | 3.806 | 1.08× |
| GF256 inverse 83 | 4.831 | 4.234 | 1.14× |
| GF9 multiply, control | 2.545 | 2.404 | 1.06× |
| RS15 two-error decode | 176.262 | 163.880 | 1.08× |
| RS255 two-error decode | 5136.306 | 4853.231 | 1.06× |

Select the pair of changes together. The Fp5 median is effectively unchanged;
its candidate process means span 599.521–661.348µs. Fp2 multiplication does not
call the changed division/shift path, so its 7% difference is a useful warning
against attributing every small ratio to the mechanism. The division and inverse
improvements are modest, CPU-specific evidence; the large first-step
characteristic-two gain is the stronger result.
The selected pair passes all 57 polynomial/extension-field/RS tests on native,
Wasm GC, and JavaScript; purity and public API snapshots remain unchanged.

`shift-quiet-*` records the rejected candidate alone; `prefix-*` records the
selected pair. `shift-*` and `shift-recheck-*` retain the earlier noisy attempts:
the same Fp5 control ELF varied from about 0.6ms to 2.8ms. Those two attempts are
diagnostic only and are excluded from the adoption table. Complete means and
ranges are in each `*-summary.json`. Source revision `HEAD` in the first noisy
attempt was expanded afterward to the unchanged `17bf360` revision, with that
metadata correction recorded in the JSON. The runner now resolves revisions
before timing and accepts explicit test selections/counts for later AES controls.

## Shared Binary composition and AES controls

The next experiment freezes shared Binary at
`b21222bef6073a07c1f4d5e9bcaf053d53b8a334` for both variants. The generic control
is `6dfb1d2014c74dd2fb480ff9772e23cc0e5290cc`: this shared commit plus benchmark
commits only. The characteristic-two/reduced-result/one-pass-shift candidate is
`72fd4579f9e8bc5c43944162abb9aacf3e531216`. Its harness adds ten AES workloads:
table generation, and key expansion/encrypt/decrypt for each key length. Fixed
FIPS inputs and expected ciphertexts are checked outside timed closures. The
original nine primitive/RS inputs remain identical. Polynomial/extension-field/
RS/AES correctness passes 71 tests on all three backends at this composition.

AES table generation calls the extension-field inverse and can benefit from
these changes. Cached AES key expansion and block operations use the immutable
Sbox tries and Boolean octet operations; they do not call Galois arithmetic and
are controls. No AES implementation code is changed by this optimization.

Baseline ELF SHA256 is
`5f1a32bbac279bfc105b0d29b6c2eb6906a1dd523a1a3314772d040beb9e29a4`;
candidate ELF SHA256 is
`91b3340fa5af75061cab7e13e165eebe3ada28ed7c6c869982f815af1e38a4e8`.
`combined-*` preserves a first noisy A/B/B/A/A/B attempt. `combined-near-*` is
the second attempt with a third width-cache candidate (`a1a4f40`), in
A/B/C, B/C/A, C/A/B order. Both experiments use CPU6 and identical native flags.

Project agents stopped heavy jobs for 15:22:30–15:25:10 UTC during the second
attempt, and all nine processes completed by 15:25:05 UTC. Nevertheless unrelated
`chrome-headless`, `dnf`, and other host processes were active. They were observed
read-only and were not stopped. The cgroup reports no throttling and CPUs 0–15;
WSL host scheduling/frequency and these unrelated workloads are uncontrolled.
The same unchanged AES control ELF varied substantially. These are **diagnostic
measurements**, not evidence for small speed differences or a clean composed
speedup claim. All adaptive batch sizes and run counts are retained in each raw
summary. `combined-noisy-summary.json` and `combined-near-summary.json` preserve
the process means and ranges; the large characteristic-two advantage remains
visible, including table generation, but this host interval does not isolate
the width-cache benefit. Its adoption remains pending.

The separate `combined-gprof.txt` diagnostic identifies `core.length` and Nat
comparison after the first optimization, while Binary division no longer has a
major sampled self-time share. This motivates caching the divisor width across
long division and computing the remainder width once per iteration. The
candidate changes only private arguments; its native 71 tests, purity audit,
and public API snapshots pass. Profile call counts must not be compared directly
with the earlier profile: adaptive batch counts differ, and both Binary and
polynomial implementations changed between these profiles.

Subsequent heavy builds/tests/timing batches use the shared repository mutex,
introduced by `fbe64ee`, for example:

```sh
/home/hosi/morph/tools/measure --cpu 6 bash measurement-batch.sh
```

This serializes project agents across worktrees but does not reserve the host.
The runner now records child user/system CPU time and CPU/elapsed ratio as an
additional descheduling diagnostic. `build_cpu_timer.py` and `thread_clock.c`
provide a separate, explicitly labeled thread-CPU-time benchmark adapter through
GNU ld wrapping of `clock_gettime`. Generated kernel C is unchanged. Thread CPU
time excludes descheduled wall time; it still includes frequency/cache/hypervisor
effects, so this metric is not interchangeable with the stock wall-clock data.

## Thread CPU time diagnostic

`cpu-*` records three processes each for the original generic polynomial
implementation, the first combined candidate (`72fd457`), and the private-width
cache (`a1a4f40`). Order is A/B/C, B/C/A, C/A/B under one shared mutex hold.
The timer adapter is applied identically to all three generated native C files;
no generated kernel code is edited. Means are microseconds of thread CPU time
per operation, and medians below aggregate the three process means.

| Workload | Generic µs | Fp2 candidate µs | Width cache µs |
| --- | ---: | ---: | ---: |
| Fp2 multiply 64×32 | 284.353 | 20.284 | 21.104 |
| Fp2 divide 95/32 | 7548.070 | 241.668 | 174.048 |
| Fp2 extended Euclid 16/14 | 168.666 | 14.321 | 10.804 |
| Fp5 multiply, control | 804.412 | 817.882 | 835.351 |
| GF256 multiply 83×202 | 69.865 | 7.589 | 5.289 |
| GF256 inverse 83 | 68.368 | 8.533 | 7.478 |
| GF9 multiply, control | 3.297 | 2.819 | 2.717 |
| RS15 two-error decode | 1696.257 | 331.115 | 283.337 |
| RS255 two-error decode | 62649.545 | 9671.952 | 7840.497 |
| AES generated tables | 23877.662 | 4888.078 | 4170.976 |

Whole-process child CPU/elapsed ratios are 0.967–0.972, indicating little Linux
descheduling in this interval. This does not account for all WSL hypervisor or
CPU-frequency effects. Cached AES controls still differ: AES192 encryption is
74.901→83.034µs between the latter two variants although its implementation does
not use the changed arithmetic. Fp2 multiplication is also an unchanged control
for the width change and differs by about 4%. All controls and run/batch counts
are retained in `cpu-summary.json` and raw output.

The 28% time reduction in Fp2 division, 25% in extended Euclid, and 19% in RS255
are larger than most control differences in this run. This supports the width
cache as a bounded native CPU-time improvement; it does not establish the same
wall-latency change on other hosts or backends. All 71 correctness tests pass on
native, Wasm GC, and JavaScript for this candidate. A zero dividend now pays one
cached divisor-width construction; zero/unit early exits are a further candidate
and must preserve field-mismatch and zero-divisor precedence.

The adapter builder also performs a sleep-based timer probe: the wrapped
monotonic clock must advance much less than the real wall clock during a 20ms
sleep. This validates timer selection, not kernel performance. Reproduction:

```sh
python3 docs/bootstrap/gf2-performance/build_cpu_timer.py GENERATED.c .tools/cpu.exe
python3 docs/bootstrap/gf2-performance/measure.py .tools/cpu.exe label SOURCE_SHA \
  --tests perf_wbtest.mbt:0-3 --cases 19 --timer thread-cpu
```

Wrap the entire build/run batch in `tools/measure`; do not compare these thread
CPU-time values directly with stock wall-clock values from another interval.

## Fusing extension-field multiplication

The fixed-width Bool candidate `43fcc5d` passes 73 correctness tests on all
three backends, including the added small-field/degree-ten oracle coverage, but
is **rejected for performance**. In a three-pair CPU-time comparison it improves
the fixed GF256 product from 4.948 to 3.548µs while making RS255 decode slower:
7748.647→11413.153µs. Cached AES controls remain close. The fixed-width conversion
and padding lose on short products, such as the low-degree monomial points used
by RS syndromes. A faster isolated product is insufficient to select this change.

`c4b84e61efee450e759353f7c99800b0b925b1b0` replaces the fixed-width implementation
with a variable-width streaming product over existing canonical zero/one
coefficients. Multiplication by x shares a low-zero prefix when no carry occurs,
and XORs against the full monic modulus only when the value fills the field
width. Width comparison walks coefficient spans directly without constructing
Nat lengths or converting between Nat and Binary. Accumulation is canonical
XOR, and only the final representative passes through public normalization.
No heuristic threshold or new public interface is introduced. Zero/unit values
are shared after the existing field-compatibility check.

The same 19 workloads are compared in A/B/C, B/C/A, C/A/B order under one mutex
hold: A is unfused `a1a4f40`, B is rejected fixed-width `43fcc5d`, C is the
variable-width candidate. The base remains Binary `b21222b`, CPU6, identical
native flags and thread-CPU-time adapter. Medians of three process means are:

| Workload | Unfused µs | Fixed width µs | Variable width µs |
| --- | ---: | ---: | ---: |
| GF256 multiply 83×202 | 5.225 | 3.596 | 0.942 |
| GF256 inverse 83, control | 7.021 | 6.800 | 7.540 |
| GF9 multiply, control | 2.473 | 2.437 | 2.420 |
| RS15 two-error decode | 261.377 | 248.446 | 148.767 |
| RS255 two-error decode | 7510.017 | 11088.168 | 5000.204 |
| AES generated tables, control | 4051.272 | 3876.526 | 3919.947 |

Select the variable-width implementation: the measured GF256 product is 5.55×
faster than the unfused control, RS15 is 1.76×, and RS255 is 1.50×. The unchanged
inverse is about 7% slower in this interval, which remains a limitation/control
signal. AES table generation uses inverses rather than the changed multiplication
and is a control for this step. These ratios apply to the recorded native
CPU-time workload; they must not be multiplied with previous ratios or presented
as universal backend or host speedups. `carryless-summary.json` preserves the
rejected comparison and `variable-summary.json` the three-way comparison, with
all process means and raw summaries.

Both variants pass 73 tests on native, Wasm GC, and JavaScript. The new tests
exhaust all 7064 products across every binary irreducible presentation through
degree five, including both degree-one presentations. Direct private-kernel
checks and public-operation checks each use a native full-product/top-degree
division oracle. GF1024 adds 128 pairs and four Fermat inverse checks. Existing
GF256 exhaustive tests cover both 0x11b and 0x11d moduli and now cross-check two
independent native multiplication methods for all 131072 pairs. Field mismatch
before zero/unit reuse, zero inverse, general primes, and existing RS/AES oracles
remain covered. Purity passes 108 kernel files, and public API snapshots are
unchanged. These finite checks are not a formal proof.

The timer sleep probes pass. The reprobed width-control ELF and clock object are
byte-identical to those used in the first CPU diagnostic; hashes and probe
values are in `timer-probe-verification.json`. The temporary generic-baseline
worktree was clean and removed after preserving its branch, ELF/C, and provenance.

The integration-only source commit is `af4a1de`: it contains the final four-file
Galois delta against `a1a4f40` without requiring the rejected fixed-width source
commit. Its complete `src` tree was compared byte-for-byte with `c4b84e6`.

## Stock wall-clock confirmation

The nine original primitive/RS workloads were rerun with the saved stock native
ELFs, excluding the custom timer adapter. The source remains frozen at Binary
`b21222b`, unfused `a1a4f40` versus variable-width `c4b84e6`. This experiment does
not mix subsequent Core changes into either ELF. CPU6, one shared mutex hold,
A/B/B/A/A/B, three processes per variant:

| Workload | Unfused wall µs | Variable-width wall µs | Ratio |
| --- | ---: | ---: | ---: |
| GF256 multiply 83×202 | 5.570 | 0.992 | 5.62× |
| RS15 two-error decode | 275.203 | 160.285 | 1.72× |
| RS255 two-error decode | 8038.691 | 5371.939 | 1.50× |
| GF9 multiply, control | 2.583 | 2.717 | 0.95× |
| Fp2 divide, control | 167.794 | 179.528 | 0.93× |

These confirm the large product and RS gains with the standard wall-clock
runner. The unchanged division control is 7% slower and GF9 is 5% slower in this
interval; their causes are not established. All nine cases, process means, run
counts, resource usage, and fault/context-switch diagnostics are retained in
`wall-summary.json` and `wall-*` raw records. Small cross-workload differences
remain subject to compiler-layout and shared-host effects; no improvement for
every operation or backend is claimed.

Separately, Core `17c206d` was merged and the local
polynomial prefix constructor was replaced with `core.replicate_onto` in
`5036234`. This removes duplicate implementation using the reviewed generic
prefix law. All 73 polynomial/field/RS/AES tests pass on native, Wasm GC, and
JavaScript, purity passes 113 kernel files, and their public API snapshots are
unchanged. No extra speedup is attributed to this refactoring.

## Zero and constant polynomial division

Harness `b4d626e` adds 21 fixed workloads for zero/unit/general/constant division
and scalar controls at 64 coefficients. Inputs, including 2^1000, are built
outside timed closures. Candidate `972964c` checks field compatibility and zero
divisors first, then shares a zero dividend or returns division by one directly.
A nonzero constant divisor uses one scalar inverse and a single scale rather
than repeated polynomial long division. Public errors and normalization remain
unchanged. The negative-input regression explicitly checks mixed-field units
and mixed-field zero dividends as well as zero-over-zero.

The source base is the separately composed Core `17c206d`, with shared prefix
refactoring `5036234`, rather than the earlier frozen Binary-only comparison.
Both variants use this same base. Under one mutex, CPU6, thread-CPU timer,
A/B/B/A/A/B, and three independent processes, the median microseconds are:

| Workload | Baseline µs | Direct-division µs |
| --- | ---: | ---: |
| Zero / nonzero, Fp2 | 1.133 | 0.237 |
| Unit divisor, Fp2 | 112.479 | 0.053 |
| Unit divisor, Fp3 | 471.389 | 0.056 |
| Unit divisor, Fp5 | 703.510 | 0.057 |
| Nonunit constant, Fp3 | 484.904 | 10.331 |
| Nonunit constant, Fp5 | 713.306 | 27.262 |

The Fp3 general-division control is 410.991→447.719µs (9% slower), while
the Fp5 control is 812.153→810.186µs. These countertrends remain recorded.
Complete values, including both nonunit constant divisors, general-division
controls, and unchanged scalar workloads, are in `unit-summary.json` and the
raw `unit-*` reports. Large scalar costs are recorded as controls and are not
optimized in this milestone. All 74 correctness tests pass on native, Wasm GC,
and JavaScript; purity and public API snapshots remain unchanged. This completes
the current polynomial tuning phase before the separate Nat radix work.
