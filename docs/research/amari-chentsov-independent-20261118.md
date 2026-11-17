# Independent exact information-geometry regression

No mismatch was found in the completed native, JS and wasm-gc comparisons on
source `2b3183e`. Each backend passed 20 related Gaussian/statgeometry test
blocks, including the two new independent fixture blocks. The archived review
had stopped before completing a compiled comparison; that earlier incomplete
status is not counted as validation here. No production source or public API is
changed by this work.

## Exactly what was compared

| Expected component positions per backend | Count |
|---|---:|
| Gaussian log-partition derivatives of orders 2, 3 and 4 | 3,184 |
| Finite-model probability jets, metric jets, cubic, natural gradient and alpha geometry | 2,122 |
| Original archived corpus | **5,306** |
| Additional score components | 36 |
| Additional cubic pullback/evaluation components | 4 |
| Independent expected positions including those auxiliary checks | **5,346** |
| Additional public API crosschecks against the same expected values | 260 |
| Total QQ component comparisons, including those crosschecks | **5,606** |

These are positions in complete tensors/vectors, including zero and symmetry
related positions, not counts of distinct rational numbers. All positions are
checked by exact value equality, with no checksum or numerical tolerance. The
260 additional comparisons are 32 cubic-tensor getter positions, 160 raised
connection getter positions, 64 ordinary Riemann positions at alpha zero, and
four scalar-by-contraction values. They do not enlarge the independent oracle
corpus. Tensor shapes, model/jet lengths and metric dimensions are also checked;
those structural assertions are outside the QQ counts.

The fixtures cover seven Gaussian points: three univariate and four bivariate.
Three bivariate points have nonzero rational means and nondiagonal positive
definite rational covariance matrices; the fourth is a zero-mean nondiagonal
control. Natural parameter dimensions are two and five. The finite corpus has
two normalized polynomial families with four and five outcomes, each evaluated
at two nonzero rational parameter points. Every point is checked at alpha
0, +1, -1, +3/5 and -3/5: twenty complete connection/curvature objects.

## Gaussian method and the off-diagonal convention

The oracle directly differentiates the Gaussian log partition

```
F(eta,H) = -eta^T H^-1 eta / 4 - log det(-2H) / 2 + constant.
```

It evaluates at precision P = covariance^-1, eta = P mean, H = -P/2.
The sufficient-statistic order is all X_i followed by X_i X_j for i<=j in
row-major order. Consequently the independent quadratic coordinate theta_ij
satisfies H_ii=theta_ii and H_ij=theta_ij/2 for i<j. In two dimensions the full
coordinate order is `(eta0, eta1, theta00, theta01, theta11)`; in particular
`theta01 = -P01`, not `-P01/2`. This factor is present before differentiation.

Sympy differentiates F symbolically, then substitutes each exact rational point.
Its Hessian is compared with the metric, its third derivatives with
`first[k][i,j]`, and its fourth derivatives with `second[k][l][i,j]`.
Every covariance is independently checked positive definite. This route uses
no Gaussian moment recurrence, moment cache, centered-statistic product, or
MoonBit output to construct expectations. The interpretation of log-partition
Hessians and cumulants follows Nielsen and Garcia's
[exponential-family digest, sections 1.2 and 1.4](https://arxiv.org/html/0911.4863v2).

## Finite models, alpha connections and index order

Both probability families sum identically to one as polynomials. Sympy checks
this identity, positivity of every probability at the selected points, and
nonsingularity of the resulting metric. The points are `(1/3,-1/4)` and
`(-1/4,1/5)` for the four-outcome family, and `(1/5,1/4)` and `(-1/3,1/6)` for
the five-outcome family. Their nontrivial cross terms include third and fourth
polynomial degree; these are not simplex or product-Bernoulli closed forms.
Positivity is asserted at these points, not everywhere in parameter space.

Starting with l=log p, the independent expressions are

```
g_ij = sum_x p (partial_i l)(partial_j l)
C_ijk = sum_x p (partial_i l)(partial_j l)(partial_k l)
Gamma^(alpha)_ij,k = sum_x p (partial_i partial_j l
                              + (1-alpha)/2 (partial_i l)(partial_j l)) partial_k l.
```

The expected alpha connection is the convention introduced in Amari's
[Differential Geometry of Edgeworth Expansions](https://www.ism.ac.jp/editsec/aism/pdf/035_1_0001.pdf).
The generator differentiates the probability/metric/lowered-connection
expressions directly with Sympy. It differentiates a local symbolic inverse
metric to raise the connection; it does not copy the producer's hand-written
derivative-of-inverse or metric-second-derivative code.

Raised coefficients are stored as `[i,j,r]=Gamma^r_ij`, ordinary derivatives as
`[k,i,j,r]`, and mixed Riemann curvature as `[r,j,k,l]`. The oracle constructs
connection matrices and their commutator:

```
R_kl = partial_k Gamma_l - partial_l Gamma_k + Gamma_k Gamma_l - Gamma_l Gamma_k.
```

It then lowers the first index with g, contracts first/third indices for Ricci,
and contracts Ricci with the inverse metric for scalar curvature. Before
emitting data it checks the algebraic Bianchi identity and lowered-curvature
duality between alpha and minus alpha. Each compiled case compares every
lowered/raised coefficient and derivative, mixed/lowered Riemann, Ricci and
scalar component. At alpha zero it also checks the separate ordinary Riemann
route and the shared tensor product/two-trace scalar route.

The forty auxiliary values use Python standard-library Fraction arithmetic on
the independent data: thirty-six scores and four trilinear cubic evaluations
under a rectangular Jacobian. The generated MoonBit tests use hexadecimal
arbitrary-length numerator/denominator literals, so large expected rationals
(up to hundreds of bits here) are never truncated to machine integers.

## Reproduction, provenance and boundaries

`tools/generate_information_review_fixtures.py` retains the mathematical
expressions, points and complete fixture renderer. There are two intentionally
different verification modes:

- `python3 tools/generate_information_review_fixtures.py --check` loads Sympy,
  rederives the mathematics, and checks all generated fixture and oracle bytes.
- `python3 -S tools/generate_information_review_fixtures.py --check-stored` uses
  only the Python standard library and the pinned SDK formatter. It rerenders
  committed oracle data and checks fixture consistency; it does **not** rederive
  or establish the mathematical expectations.

The independently rerunnable backend is Sympy 1.14.0 on `/usr/bin/python3`.
On CPU 4 after acquiring the shared lock, fresh rederivation plus byte checking
took 10.403 seconds; the `python3 -S` stored-data check took 0.193 seconds. Both
returned zero and both fixture files matched byte for byte. These are checker
execution observations, not a kernel performance comparison. Exact commands and
times are in the raw generator-validation record. Normal
regression need not install Sympy: stored-data consistency and mathematical
rederivation are separate checks. The archived mathematical data are retained
losslessly; the normalized reproducible copy removes only old elapsed-time
metadata. The two compiled fixture files retain the archived expected values.

[Raw records](amari-chentsov-independent-20261118-raw/README.md) include all three
compiled-test logs, generator validation, exact input/fixture/tool/source hashes,
the prior incomplete source record and the normalized/archived oracle data.
Tests call the existing `fisher_jet`, `cubic`, `alpha_geometry` and related public
operations at the recorded source. New Amari–Chentsov/Gaussian Information
wrapper APIs added on main are a separate integration check owned by root.

This is exact finite regression evidence, not a proof for all Gaussian
dimensions, all finite statistical models or global analytic manifolds.
Univariate/bivariate Gaussian derivatives through fourth order and these
four finite points are covered. The exponential-point and stochastic-channel
implementations received source review in the prior pass; this fixture set does
not add an independent runtime comparison for them. Final equality also relies
on the existing rational constructors, equality implementation and compiler
backends. No performance or asymptotic improvement is claimed.
