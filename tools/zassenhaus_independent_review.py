#!/usr/bin/env python3
"""Independent stdlib-only arithmetic witnesses for the Zassenhaus review.

No symbolic factorization library and no production MoonBit helper is used.
The MoonBit review tests perform the actual cross-implementation comparisons.
"""
from __future__ import annotations

import argparse
from functools import reduce
from itertools import product
import json
from math import gcd, isqrt
from pathlib import Path


def content(cs):
    return reduce(gcd, map(abs, cs), 0)


def mul(a, b):
    out = [0] * (len(a) + len(b) - 1)
    for i, x in enumerate(a):
        for j, y in enumerate(b):
            out[i+j] += x*y
    return out


def evaluate(cs, numerator, denominator=1):
    n = len(cs)-1
    return sum(c*numerator**i*denominator**(n-i) for i, c in enumerate(cs))


def rational_root(cs):
    if cs[0] == 0:
        return (0, 1)
    for p in range(-abs(cs[0]), abs(cs[0])+1):
        if p == 0 or cs[0] % p:
            continue
        for q in range(1, abs(cs[-1])+1):
            if cs[-1] % q == 0 and evaluate(cs, p, q) == 0:
                return (p, q)
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, default=Path('.tools/zassenhaus-independent-review-20261116/arithmetic-witnesses.json'))
    args = parser.parse_args()
    small = []
    for lead in range(1, 4):
        for degree, radius in ((2, 3), (3, 2)):
            for lower in product(range(-radius, radius+1), repeat=degree):
                cs = [*lower, lead]
                if content(cs) == 1:
                    root = rational_root(cs)
                    small.append({'coefficients': cs, 'irreducible': root is None, 'rational_root': root})
    assert len(small) == 476
    linears = [[b, a] for a in range(1, 5) for b in range(-4, 5) if gcd(a, b) == 1]
    for g, h in product(linears, repeat=2):
        f = mul(g, h)
        bound = 2**(len(f)-1) * sum(map(abs, f))
        assert max(map(abs, g+h)) <= bound
    # A monic reducible quartic has an integer linear factor or two monic
    # quadratic factors. For x^4+x+2, the latter require b*d=2,
    # a+c=0, and a*a=b+d. None of the four possible pairs has square sum.
    quartic = [2, 1, 0, 0, 1]
    assert rational_root(quartic) is None
    pairs = [(b, d) for b in (-2, -1, 1, 2) for d in (-2, -1, 1, 2) if b*d == 2]
    assert len(pairs) == 4
    for b, d in pairs:
        total = b+d
        assert total < 0 or isqrt(total)**2 != total
    sophie = mul([2, -2, 1], [2, 2, 1])
    assert sophie == [4, 0, 0, 0, 1]
    forged = [-130302, 1, 0, 0, 1]
    assert evaluate(forged, -19) == 0
    assert all((a-b) % 256 == 0 for a, b in zip(quartic, forged))
    threshold = lambda f: 2*abs(f[-1])*2**(len(f)-1)*sum(map(abs, f))
    assert threshold(quartic) == 128
    assert 256 <= threshold(forged)
    record = {
        'oracle': 'Python standard library exact integers; rational root theorem in degrees 2 and 3',
        'small_polynomial_count': len(small),
        'quadratic_count': sum(len(r['coefficients']) == 3 for r in small),
        'cubic_count': sum(len(r['coefficients']) == 4 for r in small),
        'irreducible_count': sum(r['irreducible'] for r in small),
        'linear_product_bound_cases': len(linears)**2,
        'strict_threshold_irreducible_quartic': quartic,
        'quartic_quadratic_constant_pairs_ruled_out': pairs,
        'grouping_required_reducible_quartic': sophie,
        'congruent_reducible_target': forged,
        'congruent_reducible_root': -19,
        'modulus': 256,
        'original_threshold': threshold(quartic),
        'forged_threshold': threshold(forged),
        'small_polynomials': small,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(record, indent=2)+'\n')
    print(json.dumps({k: v for k, v in record.items() if k != 'small_polynomials'}, indent=2))


if __name__ == '__main__':
    main()
