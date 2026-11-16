# Complete complex splitting: adversarial review

This review checks the `complexsplitting` implementation introduced by
`5bbd047`, using separately written white-box tests in
[`adversarial_wbtest.mbt`](../../src/complexsplitting/adversarial_wbtest.mbt).
No production algorithm, existing test, package configuration, or generated
interface was changed. The six new tests pass on native and JavaScript with
warnings denied. No concrete defect was found in the reviewed boundaries.

## Claims and evidence

The complete-root checker requires distinct roots, positive multiplicities,
the exact ambient CF context, and multiplicities summing to the original
polynomial degree. For a claimed multiplicity `m`, derivatives of orders below
`m` must vanish and the derivative of order `m` must be nonzero. In
characteristic zero, these conditions certify the complete weighted root set.

The review independently expands `(t-1)^2(t+1)` as
`t^3-t^2-t+1`, with multiplicities two at one and one at minus one.
Its first derivative vanishes at one and equals four at minus one; its second
derivative equals four at one. Swapping the multiplicities preserves the total
degree but fails the exact derivative check. Duplicate roots, a zero weight,
an omitted root, and compensating a missing root with an excessive weight are
also rejected.

The second independently expanded example is
`(t^2+1)^2(t-1) = t^5-t^4+2t^3-2t^2+t-1`.
Its roots are `i`, `-i`, and one with weights two, two, and one. The first
derivative vanishes at `i`, the second is nonzero there, and the first
derivative at one is four. Several exchanges that retain total degree five
are rejected, as are a substituted nonroot and omitted roots. Returned root
images retain the exact weights and evaluate back to the supplied roots.

Scaling the first polynomial by `7/3` or `-6` retains the same weighted roots
but creates a different source polynomial. Each scaled result is valid for
its exact source; every attempt to reuse it or its certificate for the monic
source is rejected. This checks binding to the original coefficients rather
than only to a monic associate.

Two valid alternative presentations test proof and actual-result binding.
For the Gaussian field, `theta = 1+2i` has minimum
`t^2-2t+5`; the images of `i` and `-i` are respectively `(t-1)/2` and
`(1-t)/2`. This independently selected candidate and its conversions form an
accepted complete certificate. Swapping only its primitive certificate,
polynomials, conversion certificates, images, or actual private representation
into the original result is rejected. Adding the original modulus to a root
image preserves its value but is rejected as a noncanonical output.

A second valid alternative reverses the generated monomial basis to `[i,1]`.
Candidate zero is then `i`, with minimum `t^2+1`. Its complete certificate and
private payload are accepted together. All seven combinations of replacing
the original private field, representation, or stored proof with these
alternative payloads are rejected against the original certificate, including
the coherent complete alternative result. The alternative is accepted when
checked against its own certificate.

Finally, the weighted Gaussian roots are placed in the degree-four ambient
`Q(sqrt(2),i)`. The returned generated field still has degree two and excludes
`sqrt(2)`. A degree-four closed ambient basis with false generator-monomial
provenance is rejected, as is a genuinely generated degree-four field with an
extra generator. Complete results built in the distinct degree-two Gaussian
ambient are valid there; cross-context roots, certificates, actual fields,
representations, and coherent whole-result substitutions are rejected.

## Validation and limits

Both commands executed exactly six new review tests, with six passed and zero
failed. The existing five tests were compiled but excluded by the test filter;
this report does not count their earlier validation as a new execution.

```text
tools/measure --cpu 4 tools/moon test src/complexsplitting --target native --release --deny-warn -j 1 --filter 'review*'
tools/measure --cpu 4 tools/moon test src/complexsplitting --target js --release --deny-warn -j 1 --filter 'review*'
```

Only the new test file was formatted. The production files, original tests,
package configuration, and generated interface are byte-identical to
`5bbd047`. The repository purity audit also passed for 286 kernel files.

The review uses exact ambient degrees two and four and the supplied-root entry
point. It does not exercise the automatic factorization, root isolation,
materialization, or common-ambient search pipeline, a later cubic fast path,
large-degree scaling, or adversarial resource consumption. It reuses the
existing CF, rational arithmetic, subfield, and primitive checkers as the
trusted executable foundation. These finite checks are not a formal proof of
those components, the compiler, or the general algorithm.
