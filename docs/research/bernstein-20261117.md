# Exact Bernstein box certificates — 2026-11-17

This milestone connects sparse rational polynomials, inequalities and closed-box
geometry. It answers whether tensor Bernstein coefficients can supply exact,
independently checkable range bounds and a resumable sufficient test for
nonnegativity or strict positivity, using only algebraic data types in the
production kernel. It does not implement a decision procedure for arbitrary
polynomial inequalities.

The implementation is [src/bernstein](../../src/bernstein/bernstein.mbt), with
[subdivision](../../src/bernstein/subdivision.mbt), a generated
[public interface](../../src/bernstein/pkg.generated.mbti),
[adversarial tests](../../src/bernstein/bernstein_wbtest.mbt) and
[independent fixtures](../../src/bernstein/fixtures_wbtest.mbt).

## Mathematical contract

For a polynomial `p` in `m` variables, a box is an ordered chain of `m` rational
intervals `[a_j,b_j]` with `a_j < b_j`. Intervals are closed; reversal and zero
width are errors. The degree vector `n` has `m` natural entries and covers every
source monomial componentwise. Degree elevation and degree-zero axes are valid.
The empty box in zero dimensions contains the unique empty tuple.

Write `w_j=b_j-a_j` and `t_j=(x_j-a_j)/w_j`. The tensor basis is

\[
B_i^n(t)=\prod_j {n_j\choose i_j}t_j^{i_j}(1-t_j)^{n_j-i_j},
\qquad 0\le i_j\le n_j.
\]

All basis values are nonnegative on the closed box. The binomial theorem gives
`sum_i B_i^n = 1`, including zero-degree axes. If the exact identity
`p(x) = sum_i c_i B_i^n(t(x))` holds, every value of `p` lies between the
smallest and largest `c_i`. The bounds are extrema of the coefficients, which
need not equal extrema of the polynomial.

The unit-box coefficient relation and convex-hull enclosure appear in
Dang and Salinas, [Image computation for polynomial dynamical systems using the
Bernstein expansion, §2.2](https://www-verimag.imag.fr/TR/TR-2008-21.pdf).
The [official BernsteinExpansions.jl range documentation](https://juliareach.github.io/BernsteinExpansions.jl/latest/man/range/)
also states the enclosure. The displayed proof above directly establishes the
scalar enclosure needed here; no geometric hull computation is required.

For a monomial `x^alpha`, the producer computes each axis factor

\[
\sum_{k=0}^{\min(i,\alpha)}
 {\alpha\choose k}a^{\alpha-k}w^k
 \frac{{i\choose k}}{{n\choose k}},
\]

then multiplies factors across axes and sums over source monomials. This follows
by expanding `(a+wt)^alpha` and using the standard unit-box conversion. The
denominator is nonzero because `k <= alpha <= n`. Binomial coefficients and
rational powers are computed recursively; no floating point is used.

The preprint [arXiv:1906.03472](https://arxiv.org/abs/1906.03472) was considered
as a lead but rejected as evidence: its current version is withdrawn and its
author reports mistakes. None of its claimed optimization results is used.

## Producer and independent checker

`bound(p, box, degrees)` returns a `BoundCertificate` holding the source, actual
box, degree vector, complete coefficient tensor, lower bound and upper bound.
Tensor indices use lexicographic Cartesian order, with the first variable
varying slowest. Keeping explicit indices permits rejection of missing,
duplicate, out-of-range and reordered entries.

`check_bound(p, actual_box, certificate)` validates the external source and box,
all dimensions, the degree coverage, exact index sequence and exact coefficient
extrema. It then independently expands each basis term in the original `x`
coordinates:

\[
{n\choose i}\frac{(x-a)^i(b-x)^{n-i}}{(b-a)^n}.
\]

Both powers are expanded with the binomial theorem. Products across axes and
the tensor sum produce ordinary sparse terms, which the existing polynomial
constructor canonicalizes. The checker requires equality with the original
polynomial. It never calls `bound`, the producer's monomial conversion formula
or the search. The two directions share rational arithmetic, powers and the
binomial routine; they do not share the conversion algorithm. This is an
executable certificate checker, not a machine-checked proof of its implementation
or of the underlying arithmetic library.

An altered source or box is rejected even if changed in both the external input
and certificate while keeping the old coefficients: the expanded identity must
still match. Merely altering coefficients and recomputing their extrema does not
evade this check. A different tensor/degree that genuinely represents the same
polynomial is a valid different certificate, which is intentional.

## Adaptive exact geometry

`certify(p, box, degrees, relation, split_fuel)` starts a search.
`resume_search(state, split_fuel)` validates and continues public state. `resume`
was avoided because the compiler reserves that identifier for future use.
`Relation` distinguishes `Nonnegative` (`p >= 0`) and `Positive` (`p > 0`).

Each open leaf computes a fresh bound. A lower bound at least zero certifies a
nonnegative leaf; a strictly positive lower bound certifies a positive leaf.
Otherwise the algorithm evaluates the rational midpoint and all rational
corners. An evaluated violation returns `Counterexample` with the point and its
exact value. A negative coefficient alone is never a counterexample.

If the bound and samples are inconclusive, one fuel unit permits an exact
midpoint bisection of the longest side, breaking ties at the first axis.
Depth-first traversal continues with the remaining fuel. Every split creates
two closed half-boxes whose union is the parent; their common face is included
in both. Longest-side splitting avoids permanently ignoring a nonzero-width
coordinate. All choices and all state are deterministic.

The public `CertificateTree` has `Open(box)`, `Leaf(bound_certificate)` and
`Split(parent_box, axis, left, right)` constructors. The checker derives the two
half-boxes from each actual parent and axis, then checks descendants against
those exact boxes. Duplicating one child, dropping coverage, changing an axis,
changing a parent box or substituting false leaf bounds is rejected.

`check_outcome(p, actual_box, relation, result)` binds the entire returned result
to the external claim. `Certified` requires a fully checked tree with no open
leaves. `Counterexample` additionally checks membership and evaluates the source
at the actual witness, including the stored value and relation. `Paused` requires
a structurally checked tree with at least one open leaf and asserts neither
truth nor falsity. `check_witness` can also check a rational witness separately.
`tree_counts` returns `(certified_leaves, split_nodes, open_leaves)` as ADT
naturals. Supplied state is checked before `resume_search` trusts it.

Fuel counts newly allocated split nodes. It does **not** bound arithmetic
operations, tensor size, source size, coefficient bit length, checker cost or
wall time. Even zero fuel can compute a tensor, discover a witness or certify an
already favorable box. Resumption verifies existing leaves and revisits open
leaves, rather than storing an unchecked producer cache.

## Deterministic examples and observations

| Claim and box | Initial enclosure | Budget/result |
| --- | --- | --- |
| `x^2-x+3/8 > 0`, `[0,1]` | `[-1/8,3/8]` with coefficients `[3/8,-1/8,3/8]` | Zero splits pauses; one split certifies two leaves |
| `x >= 0`, `[0,1]` | `[0,1]` | Certifies with zero splits |
| `x > 0`, `[0,1]` | `[0,1]` | Counterexample `x=0`, value `0` |
| `x^2-x+1/8 >= 0`, `[0,1]` | Negative coefficient lower bound | Checked midpoint counterexample `x=1/2`, value `-1/8` |
| `x^2 >= 0`, `[-1,1]` | `[-1,1]` | One split proves both halves; strict positivity has midpoint counterexample |
| `(x-1/3)^2 >= 0`, `[0,1]` | Inconclusive | Two splits pause; three more splits give five total and still pause |
| `(x-1/2)^2+(y-1/2)^2+1/8 > 0`, `[0,1]^2` | `[-3/8,5/8]` | Three splits certify four quarters, splitting `x` then `y` on each half |

The first example is strictly positive although its unsplit degree-two tensor
contains a negative coefficient. Thus the finite experiment establishes a real
benefit from geometric subdivision without confusing enclosure width with a
counterexample. The dyadic and non-dyadic zero examples show why a bounded search
must distinguish unresolved from false. Boundary zeros can immediately refute
strict positivity when sampled; unsampled zero sets can remain unresolved.

## Independent oracle and verification

[generate_bernstein_fixtures.py](../../tools/generate_bernstein_fixtures.py) uses
Python `Fraction` only as a test oracle. It expands every tensor basis polynomial
in original coordinates, builds a rational coefficient matrix and solves a
linear system by exact Gaussian elimination. It does not use the producer's
power-to-Bernstein formula. It checks the reconstructed polynomial and every
point of a five-point-per-axis rational grid against the coefficient enclosure.
Seven generated fixtures cover zero, negative constants with elevated degrees,
`xy`, a subdivision-positive quadratic, rational cross terms over negative and
nonunit boxes, a bivariate degree `(4,3)` case and zero dimensions. Grid tests are
sanity checks, never proofs of the range claim.

The handwritten tests additionally cover dimension/order/degree rejection,
source/box/bounds/coefficient/index/tensor/tree tampering, exact witnesses,
strict versus nonnegative semantics, one- and two-variable subdivision,
zero/negative constants, split counts, paused-state resumption and rejection of
forged resume state. The production package passes the repository purity gate:
no machine numeric types/literals/operators, mutable containers, mutation or
FFI; test code and the Python oracle are outside that constraint.

Observed validation: 17 of 17 package tests pass on both `wasm-gc` and `js`;
the package checks without warnings. The full repository purity gate passes
over 294 production kernel files in this worktree.

Reproduction, using the existing SDK and shared measurement lock:

```bash
tools/measure --cpu 4 python3 tools/generate_bernstein_fixtures.py
tools/measure --cpu 4 tools/moon fmt src/bernstein
tools/measure --cpu 4 tools/moon check -j 1 src/bernstein --deny-warn
tools/measure --cpu 4 tools/moon test -j 1 src/bernstein --target wasm-gc
tools/measure --cpu 4 tools/moon test -j 1 src/bernstein --target js
tools/measure --cpu 4 python3 tools/audit_purity.py
tools/measure --cpu 4 tools/moon info src/bernstein
```

The generated fixture source is formatted in the following `moon fmt` step.
This milestone makes no speedup or runtime bound claim. Exact rational tensor
size is `product_j(n_j+1)`; independent expansion can create many more temporary
terms. Bisection trees can grow exponentially, coefficient numerators and
denominators can grow, and recursive ADT evaluation is subject to runtime stack
and memory limits. Repeated resumption need not terminate on zero sets or
unsampled equality cases. A general CAD solver, positivity completeness theorem,
optimized de Casteljau coefficient reuse, serialization and benchmarking are
outside this finite milestone.
