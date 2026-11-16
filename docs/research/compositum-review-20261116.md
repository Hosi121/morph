# Independent compositum review, 2026-11-16

[ドキュメント](../README.md) / [研究・探索記録](README.md)

Reviewed frozen worker commit `706cb8b` (root integration `5d1d9f2`) with frozen numberfield realization/minimality dependency `24d04ed`. The review modifies **no production source, package configuration, or API**. Local dependency cherry-picks are `24d04ed -> 8d949fc` and `706cb8b -> 9c9f9b7`; these are separate from the review-only commit.

[Review tests](../../src/compositum/adversarial_review_wbtest.mbt), [generated direct arithmetic tests](../../src/compositum/direct_review_wbtest.mbt), [independent generator](../../tools/generate_compositum_review_fixtures.py), [oracle data](compositum-review-20261116-fixtures.json), [raw validation transcript](compositum-review-20261116-validation.json).

**18 focused review tests passed on native, JS and WasmGC with `--deny-warn`**. The original 29 worker tests were compiled but were outside this review's test-name filter; this report does not relabel their prior validation as a new run. Warning/format checks, independent fixture freshness, the 159-file purity gate, and an empty production/API diff all passed. CLI wall times were 201.93s / 151.03s / 118.49s; these include test/checker work and are not isolated algorithm benchmarks.

## Findings and checked chain

No incorrect producer result or false certificate acceptance was found in this bounded review. This is an independent executable/code review, not a formal correctness proof or an assertion about all inputs and budgets. Existing F4, RUR, real-number comparison, minimality, factorization and numberfield checkers remain dependencies.

The code review followed the full chain rather than treating a final product or substitution identity as sufficient:

1. `source_problem` reconstructs the ordered Cartesian equations from the **external** left/right Numbers. Their definitions are the square-free canonical polynomials returned by `realalgebraic.Number`; their selected intervals remain part of the external certificates.
2. `separation_from_certificate` checks the exact augmentation, original source, auxiliary seed, F4 ideal witnesses against the augmented inputs, shape substitution, projection dimension, and Sturm coverage of every real parameter root. Missing roots cannot be replaced by a smaller comparison table.
3. `selection_valid` requires exactly one row per covered point, binds both coordinate certificates to that point's shape and exact parameter interval, fixes indices zero and one, and checks both exact comparisons against the external selected Numbers. All nonmatching conjugates are checked too.
4. `unique_index` requires one and only one row with two Equal comparisons; the recorded index must be that row. The minimality proof's input must be the exact selected parameter certificate.
5. `numberfield.field` demands a Proven factorization/minimality certificate, then both coordinate expressions are reduced in that field. The primitive relation `x+s*y=theta` is checked. Both realizations bind canonical residues and the selected field context, and both checked comparison proofs must give equality with the external Numbers.
6. `check_result` also binds the separately returned Common: its exact field certificate, both Element parent contexts, and both canonical residues. The inner checker reconstructs the expected coordinate Elements, so changing a returned residue together with the corresponding realization input header still fails.

The checker binds **representations**. A mathematically equal Number with a refined selected interval requires a new certificate; it cannot silently reuse a certificate for the old interval. Likewise, the same minimal polynomial and the same residue coefficients in another real embedding do not describe the same returned Element. Budget exhaustion yields Unresolved during production or Undecided during irreducibility verification, never a common-field claim. These are stage counters, not global runtime limits, and the one-shot Unresolved value is not resumable state.

## Independent arithmetic oracle

The oracle reuses neither the worker's fixture expected values nor its `primitive_element`, `to_number_field`, or `minimal_polynomial` calls. It generates **15 pairs**, **62 complete Cartesian comparison rows**, exact first separating seeds and selected indices, selected minimal-polynomial coefficients, and both canonical residue coefficient lists.

Ten pairs use direct `fractions.Fraction` arithmetic in `Q(sqrt(d))`, with `d=2` or `3`, rational shifts/scales, positive/opposite conjugates, rational/zero inputs, and redundant nonminimal defining factors. Every value is the pair `(a,b)` representing `a+b*sqrt(d)`. Equality is pair equality. Signs follow rational sign and comparison of `a^2` with `d*b^2`, so no floating point or Sturm formula determines the expected comparisons. Cartesian roots are enumerated directly from the defining linear/quadratic factors and sorted by this sign oracle. The first integer seed whose Cartesian images are all distinct is obtained by exact pair equality.

For selected `theta=A+B*sqrt(d)`, `B!=0`, its minimal polynomial is `(t-A)^2-d*B^2`. A value `u+v*sqrt(d)` has residue `u-v*A/B+(v/B)*t`. If `B=0`, the selected field is rational and residues are constants. Nonsquareness of `d` proves the nonconstant degree-two polynomial irreducible. Rational input roots occur exactly at the upper endpoint of their supplied half-open intervals.

Three independent biquadratic pairs use the closed-form identity for `u=sqrt(d)`, `v=sqrt(e)`, `z=u+v`, with independent square classes `(d,e)=(3,7)` or `(2,5)`:

```text
m_z(t) = t^4 - 2(d+e)t^2 + (d-e)^2
u = ((3d+e)t - t^3)/(2(d-e))
v = (t^3 - (d+3e)t)/(2(d-e)).
```

Rational shifts translate `t`, and selecting other signs changes the real embedding. SymPy only simplifies and signs these explicitly derived radical identities; no primitive-element or minpoly routine supplies their expected coefficients. Independent square classes make the extension degree four.

Two further dependent pairs are `(sqrt(2)+sqrt(3), +/-sqrt(6))`. Their Cartesian source has **eight** real points, while the selected common field has degree **four**. A separate four-dimensional Fraction implementation multiplies in the basis `1,sqrt(2),sqrt(3),sqrt(6)`. Gaussian elimination on `1,theta,theta^2,theta^3` establishes independence, expresses `theta^4`, and derives both original generators' residues. The two selected pairs belong to different minimal factors of the Cartesian eliminant. This directly tests the selected factor rather than merely the full resultant.

Each generated MoonBit test compares the selected seed/index, every comparison order, common-field degree and every minimal/residue coefficient, verifies both source equations in the quotient field, verifies `x+s*y=theta`, checks the full Common payload, and separately checks both realized images equal the selected external Numbers.

## Coordinated negative tests

Three additional test groups cover coordinated changes that simple one-field mutations could miss:

- Delete a nonselected parameter interval **and** its comparison row, then repair the selected index; duplicate a covered point and row; reverse intervals and rows together; fabricate another matching row; change coordinate order or projection dimension.
- Take a complete valid opposite-conjugate proof and repair only its source headers; retain the original full point selection but replace minimality and both realization/equality bundles together; mix Common Elements whose modulus and canonical residues are identical but selected real embeddings differ; swap both returned coordinates and their complete certificate bundles; change a residue and the realization input header together; substitute an equivalent refined source Number; substitute another ordered source/augmentation bundle.
- Exhaust separating attempts, F4/isolation work, coordinate work, Hensel work, recombination work and realization work. Supply only primes 2 and 3 for the dependent sqrt(3) example, where the relevant reductions are not square-free. Verify zero checking fuel stays Undecided, while the completed proof is Proven with sufficient fuel.

The review runs focused tests with the name filter `*review*`, which is a test-name filter, not a filename selector. Nonzero totals are retained in the transcript. Timings include compilation, checkers and test runners and are not algorithm benchmarks.

## Preservation

All previous Zassenhaus, realalgebraic, realvariety, Tarski and orderedsturm artifacts remain untouched. Their logs are the tracked `docs/research/*-20261116-validation.json` files in `/home/hosi/morph-zassenhaus-20261116`; the first four families' SHA256 manifest is `docs/research/tarski-20261116-artifacts.json`. Review-specific fixtures and unedited combined stdout/stderr command records are the two linked review JSON files. The [preservation manifest](compositum-review-20261116-preservation.json) verifies all 19 files from the earlier manifest and all 14 orderedsturm files against frozen commit `9850b56`, byte for byte. No worktree was removed or pushed, and no separate shared Git-directory artifact copy was created by this review.
