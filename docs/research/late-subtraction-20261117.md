# Sorted QQ polynomial subtraction, 2026-11-17 extended sprint

Production baseline: `a39f3234da50eb86e19d58583d5db5c2c99b62c1`.
This independent bounded pass evaluates one mechanism: fuse the old
`add(a, negate(b))` into a sorted subtraction merge. Existing add already merges
sorted terms. No multiply, division, remainder, mapped formal function, exact
rational function or checker body is changed.

## Mechanism and invariant

Opaque Polynomial constructors guarantee lex-descending unique monomials with
nonzero canonical Rational coefficients and matching exponent dimensions. The
candidate keeps a leading left-only term, emits a negated leading right-only
term, and uses existing `exact.rational_subtract` on equal monomials, dropping
zero differences. When the right input is exhausted it shares the remaining
left tail; when left is exhausted it negates the remaining right tail because
all those terms belong to the output. It avoids a separately materialized
negated polynomial and term chain, including negated coefficient wrappers for
matching terms. Dimension comparison still decides mismatches before the merge,
including zero operands; returned errors, variable counts, canonical zero and
term order are unchanged. No machine primitives, mutation or approximate
arithmetic are introduced into the kernel.

The independent old-composition oracle remains `add(a, negate(b))`. Those
functions and all shared mapped helpers are frozen byte-for-byte. Thirty-one
Python Fraction/dictionary subtraction fixtures check complete coefficients and
both operand orders across variable counts 0,1,2,3, empty/single/larger inputs,
cancellation, disjoint/interleaved support, rational signs/denominators, and
noncanonical constructor inputs with unsorted/duplicate/zero terms. Explicit
mismatch tests use empty operands in both orders. The generator has a `--check`
guard and commits full expectations for the four direct public benchmark cases.
Both old-composition and Fraction tests share the opaque polynomial constructor;
the Python arithmetic does not share the merge or exact Rational implementation.

## Frozen measurement

Harness/oracle milestone: `36db45b`; public-only package
`src/cmd/latepolybench`. At most six frozen cases cover full cancellation,
interleaved support, a block-disjoint tail-sharing control, mixed rational
coefficients, combined tiny/zero/0-variable/error controls, and an actual
Buchberger producer with its full public verifier and existing independent
SymPy reduced-lex expected basis. Every timed result is compared completely. Direct and upper cases serialize
their complete primary result; the combined small case checks all values and
serializes its constant difference. Its other exact expected values are retained
in the frozen source. Direct benchmark expectations are independently computed
with Fraction, and checked against the old composition in setup.

Producer/checker source algorithms remain unchanged, but their shared polynomial
subtraction dependency changes. A successful public checker is not independent
arithmetic evidence for this helper. The exact independently expected basis,
old composition, and Fraction fixtures supplement that check. No formal
translation proof of the new merge is claimed; mapped-function fingerprints and
formal drift are checked separately.

Whole-process time includes input/expected construction, old-composition setup
checks, one checked warmup, operations, all checks and serialization. The inner
interval contains repeated operations/full checks/serialization, including the
public verifier in the upper consumer. These intervals are not interchangeable,
and the combined small/error case cannot isolate the speed of one suboperation.
No verifier or needed preparation cost is removed. No memory peak is measured;
omitting a term-chain construction is a source-level fact, not a measured
process-RAM saving. Large coprime denominators and application totals are outside
these fixed small-coefficient fixtures.

The baseline CLI is copied and built inside the common CPU4 flock before
candidate production edits. Existing root 84-package validation and final CLI
measurements have priority; new jobs do not bypass their lock. Initial native
correctness and the initial frozen five-ABBA comparison precede broader final
checks. Final scoped suites cover polynomial and groebner only; root owns the
broader integration regression. All heavy jobs use CPU4 and `-j 1`, except
`moon info` which has no jobs option. Baseline tracked library bytes, protected
regions, public interfaces, source/ELF/harness hashes and all checked stdout are
retained. Raw JSON may be losslessly gzip compressed with both hashes recorded.

## Results and decision

**Rejected as a generic replacement. Production retains `add(a, negate(b))`.**
The initial candidate is `88e7453`; the one permitted follow-up is `c013ca5`.
The selected production source was restored byte-for-byte to the baseline in
`6f3ccf6`. No rejected optimization remains active at branch tip, no third variant
or additional performance search was attempted, and no public API change ships.
The two prototypes remain reproducible through independent public patches and
saved ELF/source provenance.

Initial native correctness preceded all performance runs. Both phases completed
five independent-process ABBA blocks for all six cases: 120 full checks each,
240 total, all successful. The table reports separate baseline/candidate ratios;
these columns are not savings to add or ratios to multiply. Full startup/setup/
validation/serialization cost is retained in process timing. Complete raw samples,
stdout, ranges, block ratios, compiler and source/harness/ELF hashes are retained
in the losslessly compressed reports.

Native release on Intel Core Ultra 7 255H under Microsoft/WSL virtualized Linux,
CPU4 affinity, moonc v0.10.20+65efd5b93 and moon 0.1.20261104. Ratios above one
favor the candidate. The suffix-phase inner interval retains the same full output
checks/serialization and public upper-consumer verifier.

| Case | Initial process ratio | Suffix process ratio | Suffix ABBA range | Suffix inner ratio | Suffix baseline/candidate ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| full-cancellation | 1.487x | 1.537x | 1.453–1.616 | 1.579x | 60.821/39.574 |
| interleaved | 1.011x | 0.993x | 0.947–1.035 | 0.992x | 176.733/177.962 |
| block-disjoint | 0.953x | 0.988x | 0.905–1.094 | 0.988x | 195.503/197.803 |
| mixed-rational | 0.976x | 1.021x | 0.953–1.043 | 1.021x | 185.014/181.285 |
| small-zero-errors | 1.115x | 1.111x | 0.918–1.195 | 1.114x | 90.659/81.635 |
| buchberger | 0.982x | 1.017x | 0.960–1.114 | 1.017x | 142.305/139.883 |

The clear result is complete subtraction of equal polynomial values (`a-a`):
1.487x initially and 1.537x
in the suffix variant, positive in every block in each phase. This is an
experimental targeted result, not an adopted generic or application speed claim.
The initial block-disjoint case was about 4.9% slower, with all five ratios below
one (0.924–0.995). The suffix variant's median is still about 1.2% slower there,
with mixed ratios 0.905–1.094. Interleaved support is near parity; mixed rational
and actual Buchberger outcomes also change signs among blocks. The upper case
moves from 0.982x to 1.017x by medians without establishing a robust upper gain.
The suffix variant does not establish absence of smaller penalties across normal
support shapes. The combined small control's positive median cannot isolate
which of its successful/zero/error operations benefits.

Generated C inspection motivated the single suffix variant: initial left-only
recursion/incref/allocation matched old merge_terms, while the exhausted-left
suffix used a generic map/callback. The follow-up emits that suffix through direct
immutable recursion and allocates each negative output term after its recursive
tail is ready. It adds no endpoint/degree heuristic or extra monomial scan.
The initial generated C observation was recorded before regeneration; its whole
C file was overwritten by the follow-up build. An actual follow-up C excerpt,
initial source blob hash and inspection limits are retained. Native assembly
callback costs, causation of the initial regression, peak RAM and per-phase
intermediate allocation counts were not independently established; GCC may
optimize generated C further. Separate-phase absolute times are not used to
attribute the apparent control change to the source variant.

Given the stable initial negative control and the absence of a robust generic
or upper-consumer improvement after the one bounded variant, the default remains
the original composition. The matched cancellation result alone does not justify
maintaining a replacement on all input shapes. No precision, checker or input
contract was weakened to improve the numbers.

## Validation, source restoration and reproduction

Initial and suffix native suites passed 142/142 each (polynomial + groebner).
The final suffix prototype also passed 142/142 on wasm and JS. Its global
all-target deny-warn check passed (1,918 tasks); API info passed (38 tasks);
purity passed 331 kernel files; formal drift passed 32 mapped regions; the
independent generator checked 31 fixtures. All protected functions/files and
public polynomial interface bytes matched the baseline. Checker sources are
unchanged, but public checkers can share the modified subtraction dependency;
their success alone was never treated as independent arithmetic evidence.

After rejection, the entire production polynomial file was restored exactly to
`a39f323` and the candidate helper was removed. The restored production source
passed another scoped native 142/142 and purity gate (330 files). Protected and
API byte checks continue to match. The baseline tracked-library diff remains
clean; all initial/follow-up ELF hashes and frozen harness hashes were verified.
No broad 84-package test graph was rerun by this worker; root owns integration
regression. The global worker check above was static type/warning checking.

Both patches below are independent diffs from `a39f323`; apply **one**, not both.
They were verified with `git apply --check --unidiff-zero` against the untouched baseline, without
actually changing that baseline. To reproduce, prepare two copies of the baseline
library source plus the frozen public `src/cmd/latepolybench` package and oracle
fixtures supplied here. Build and save the baseline ELF first; apply the selected
zero-context patch with `git apply --unidiff-zero` to the candidate copy; run scoped native correctness; build/save candidate
native release with the same compiler/flags; run `tools/compare_field_kernels.py`
under `tools/measure --cpu 4` using the six case names above and five ABBA groups.
The readable summaries retain the exact original driver arguments and paths.
Use `shutil.copy2`/a mode-preserving copy for saved executables. The public patches
and frozen files suffice; private branch references are provenance, not an input
required to reconstruct the rejected kernels. No kernel change is retained in
production by this report.

| Variant | Source commit | Source manifest SHA-256 | Saved ELF SHA-256 |
| --- | --- | --- | --- |
| Baseline | `a39f3234da50eb86e19d58583d5db5c2c99b62c1` | `f55baa2f97a186ba4c812479875b1fac40ed3a090dcaefabef18d45a3b6faaed` | `82a81155d4be869d82a43de848f2cc0b12a6b4e7f2102c8a4a28bda4082f4e96` |
| Initial rejected | `88e74539872152334b954bd239a18f609527580d` | `84fed3ffcce300ffe0c0e61e57f3b78334ad06e284f3ddf2de706cc9da8b471b` | `ba7e2f2ea881860ae25cc71ed09957f50a6357c0f1d497c629c74918d9c3cce7` |
| Suffix rejected | `c013ca50b3da53714055a9d2f280431858e1c2f0` | `c9abe4d1fd13da7b423771ab81a6ec1d79a4d6b947d34ab210cf46980d5b2630` | `d26f38e4b5e794a7098b1e89d5c932e698114b2056247585636e9c57a350ab96` |

Evidence and public reproduction:

- [Initial full raw report, gzip](late-subtraction-20261117-initial.json.gz) and [readable summary](late-subtraction-20261117-summary.json)
- [Only follow-up full raw report, gzip](late-subtraction-20261117-suffix.json.gz) and [readable summary](late-subtraction-20261117-suffix-summary.json)
- [Initial baseline-relative patch](late-subtraction-20261117-initial.patch) and [suffix baseline-relative patch](late-subtraction-20261117-suffix.patch)
- [Generated C observation/limits](late-subtraction-20261117-codegen-notes.json) and [readable suffix excerpt](late-subtraction-20261117-codegen-suffix.txt) and [exact excerpt bytes](late-subtraction-20261117-codegen-suffix.txt.gz)
- [Validation receipts/hashes](late-subtraction-20261117-validation.json), [initial native log](late-subtraction-20261117-initial-native.txt), [suffix native log](late-subtraction-20261117-suffix-native.txt), [final prototype log](late-subtraction-20261117-final-validation.txt), [restored source log](late-subtraction-20261117-restored-native.txt)
- [Fraction generator](late-subtraction-20261117-oracle.py) and [full direct expectations](late-subtraction-20261117-oracle-cases.json)

Saved ELF files for root archival are under
`.tools/late-subtraction-20261117/`: `baseline-a39f323.exe`,
`candidate-initial.exe`, and `candidate-suffix.exe`. Raw gzip roundtrips were
checked against the uncompressed SHA-256 and readable-summary hashes. The worker
retains the worktree for root archival and did not push, deploy, remove worktrees,
or modify main/shared indexes. No more experiments belong to this mechanism.
