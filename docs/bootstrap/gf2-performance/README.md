# Characteristic-two polynomial arithmetic

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
