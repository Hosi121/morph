# Exact interval-set reification of bivariate QE truth cells, 2026-11-16

`semialgebraic` converts a completed `cad2.eliminate_y` truth column into a finite union of intervals and isolated points with exact real algebraic endpoints. The free variable is x; y is quantified by Exists or Forall over the reals. This is an **exact interval-set representation of a QE result**, not a conversion to a quantifier-free rational-polynomial Formula, a new projection algorithm, or a general higher-dimensional CAD implementation.

[Construction](../../src/semialgebraic/assemble.mbt), [membership](../../src/semialgebraic/contains.mbt), [generated API](../../src/semialgebraic/pkg.generated.mbti), [independent oracle generator](../../tools/generate_semialgebraic_fixtures.py), [oracle data](semialgebraic-20261116-fixtures.json), [verification transcript](semialgebraic-20261116-validation.json).

The verified package passes **174 tests on native, JS and WasmGC with `--deny-warn`**, together with generated-interface/format checks, oracle freshness and the 189-file symbolic-purity gate. All existing package implementations remain frozen.

## Representation and normalization

`Bound` is NegativeInfinity, Finite(realalgebraic.RootCertificate), or PositiveInfinity. `Interval` records both bounds and the two inclusion flags. A singleton has the same finite endpoint twice and both flags true. Infinite endpoints are always open. An opaque `RealSet` exposes its ordered component list and its complete Certificate.

The base CAD cells alternate as `open,point,open,...,point,open`, in the order of the checked distinct real roots. Each finite endpoint is defined by the base Problem's exact square-free root polynomial and the corresponding isolating interval. No endpoint is inferred from a rational open-cell sample; those samples stand for whole open cells, not interval boundaries.

The constructor first turns each true open cell into an open interval and each true point cell into a closed singleton. Adjacent true pieces are joined if their endpoint representations agree and at least one side includes that common endpoint. Therefore true `open,point,open` becomes one connected component, while true `open`, false `point`, true `open` retains a puncture and two components. Empty components are never introduced. Consecutive true runs yield exactly the sorted maximal connected components of the represented real set. Redundant projection roots disappear from component boundaries whenever truth remains true across them.

The component normal form is canonical as a real interval/point decomposition. The finite algebraic endpoint *certificates* remain the exact representations supplied by the checked CAD; this package does not minimize endpoint polynomials or choose globally unique isolating intervals across different CAD proofs. Two equivalent endpoint representations cannot be silently interchanged in the representation-binding checker. `contains` can nevertheless compare an arbitrary equivalent Number exactly.

## Source and payload checker

`from_cad2(value,quantifier)` uses the completed opaque CAD, its base roots, and its quantified truth column. A malformed cell-count pattern or invalid endpoint certificate is an error. The Certificate records the original Formula, chosen quantifier, full original CAD certificate, truth column and normalized interval list.

`check(problem,quantifier,certificate,verification_fuel)` first binds the external Problem's Formula and external quantifier. It runs the frozen `cad2.check` against the externally supplied Problem, reconstructs the quantified truth column from that checked decomposition, and recomputes the normalized component list from the checked base root definition. It accepts only exact equality with the supplied certificate. Thus external source, quantifier, original projection/base/fibre evidence, truth table, algebraic endpoints, endpoint inclusion and interval coverage are one checked chain.

The return is `Some(RealSet)` on successful verification. `None` means **not verified**, including an invalid certificate or insufficient fuel in the existing CAD checker. It is not a refutation of the claimed set and never denotes an empty set. `check_result` additionally binds a separately returned opaque RealSet to the complete certificate; its false result similarly means not verified. A valid empty set has a verified certificate whose interval list is empty.

The topology constructor and checker are structural finite computations after a complete CAD. They do not add another search loop. CAD/minimality verification and exact polynomial/root checks still have their existing coefficient-growth, recursion, memory and runtime costs; verification fuel is not a global bit-operation or wall-clock budget.

## Exact membership

`contains(set,x,fuel)` compares an arbitrary existing `realalgebraic.Number` against finite endpoints with the frozen exact comparator. Infinity comparisons require no root work. `Some(true)` proves membership; `Some(false)` proves nonmembership; `None` means at least one needed endpoint comparison exhausted its refinement fuel. It is never converted to false. Algebra errors remain explicit errors.

Fuel is supplied separately to each endpoint comparison and is not a shared global budget. A definite containing component suffices even if an earlier component was unresolved. If no component proves membership, any unresolved component keeps the answer unresolved. Empty and full-real sets decide immediately with zero fuel. Exact equality with an endpoint respects its inclusion flag and may be decided by the existing gcd/common-root test without refinement.

## Independent validation

The stdlib-only generator enumerates **170 complete truth patterns** for zero through three known rational roots: 2, 8, 32 and 128 patterns. It derives expected components by finding maximal consecutive runs of true cell indices, rather than reproducing the production pairwise endpoint merge. Every output bound and inclusion flag is compared, and every original open/point sample is checked for membership. These cover all local contact configurations, disconnected singletons, punctures, unbounded components, the empty set and the whole line.

A separate Fraction oracle derives membership from `q^2 <= 2` or `q^2 < 2`, giving **38 exact rational queries** for the two actual bivariate circle CADs. The expected existential sets are `[-sqrt(2),sqrt(2)]` for `x^2+y^2-2=0`, and `(-sqrt(2),sqrt(2))` for `x^2+y^2-2<0`. Exact positive/negative sqrt(2) endpoint Numbers test both inclusion conventions. A rational value 3/2 near the positive endpoint is unresolved at zero comparison fuel and correctly outside with sufficient fuel. The universally quantified circle formulas give the empty set.

Other actual CAD families include `xy=0 and y>0`, whose existential set is the singleton `{0}`, an x-only `x^2-1 != 0` formula with two punctures and three components, and true/false formulas giving R/empty. These expected sets follow directly from the displayed equations and inequalities; they are not copied from the producer's truth column.

Adversarial checks alter closure flags, drop intervals, replace a bound with another root, substitute an equivalent endpoint with a different polynomial or isolating interval, change quantifier or source Problem, negate the truth column, omit base roots, reuse another valid RealSet payload, and close an infinite endpoint. Malformed truth lengths and invalid root intervals are rejected. Verification and membership fuel exhaustion remain distinct from empty/nonmembership.

## Frozen dependencies and preservation

Production dependencies are frozen `cad2` 316a15d, `relativecad` b6de99b, `projection` a8e7207, principal subresultants 4d1170e, `elimination` 5fa06fb, `berkowitz` 1f067d2, and the existing real-number/numberfield/orderedsturm packages. Realcad's unchanged package and dedicated note/fixtures were imported from 17692e3 without its shared catalog edits. No existing package implementation or root documentation was edited for this adapter.

Earlier Zassenhaus, realalgebraic, realvariety, Tarski, orderedsturm and compositum-review artifacts remain preserved; the [preservation manifest](semialgebraic-20261116-preservation.json) records their byte identity and the current adapter artifact paths. The tracked validation JSONs contain combined stdout/stderr, commands, CPU8 serialization metadata and exit codes. Command wall times include compilation and runners; no new performance or formal-verification claim is made.
