#!/usr/bin/env python3
"""Independent reduced lex Groebner fixtures from SymPy over QQ.

SymPy is only a development/test oracle, never a runtime dependency of morph.
"""
from pathlib import Path
import sympy as sp

root = Path(__file__).resolve().parent.parent
x,y,z = sp.symbols('x y z')
cases = [
    ((x,y), [x*y-1,y*y-x]),
    ((x,y), [x*x+y*y-1,x-y]),
    ((x,y), [x*x-y,x*y-1]),
    ((x,y), [x*y,y*y]),
    ((x,y), [2*x+3*y-1,3*x-y+2]),
    ((x,y), [x*x-1,y*y-1]),
    ((x,y), [x+y,x-y]),
    ((x,y), [x*x+y,x*y+y]),
    ((x,y,z), [x+y+z-1,x-y,y-z]),
    ((x,y,z), [x*y-z,y*z-x,z*x-y]),
    ((x,y,z), [x+y+z,x*y+y*z+z*x,x*y*z-1]),
    ((x,y), [x,x-1]),
    ((x,y), []),
]
for code in range(32):
    digits = []
    n = code * 7 + 11
    for _ in range(5):
        digits.append(n % 3 - 1)
        n //= 3
    a,b,c,d,e = digits
    cases.append(((x,y),[x*x+a*y+b,x*y+c*x+d*y+e]))


def polynomial(expression, variables):
    terms = []
    for powers, coefficient in sp.Poly(expression,*variables,domain=sp.QQ).terms():
        if not coefficient:
            continue
        numerator,denominator = coefficient.as_numer_denom()
        terms.append(f'({numerator},{denominator},[' + ','.join(map(str,powers)) + '])')
    return f'make_poly({len(variables)},[' + ','.join(terms) + '])'


out = '// Generated with SymPy ' + sp.__version__ + ', reduced lex Groebner bases over QQ.\n'
for index, (variables, generators) in enumerate(cases):
    basis = sp.groebner(generators,*variables,order='lex',domain=sp.QQ)
    out += f'///|\ntest "SymPy QQ lex Groebner fixture {index}" {{\n'
    out += '  let generators = @oracle.chain([' + ','.join(polynomial(g,variables) for g in generators) + '])\n'
    out += f'  let basis = complete({len(variables)},generators)\n'
    out += '  let expected = @oracle.chain([' + ','.join(polynomial(p.as_expr(),variables) for p in basis.polys) + '])\n'
    out += '  assert_eq(polynomials(basis),expected)\n'
    out += '  assert_eq(verify(basis),Ok(true))\n'
    out += '  for generator in @oracle.array(generators) { assert_true(@poly.is_zero(required(normal_form(basis,generator)))) }\n'
    out += '}\n\n'
(root / 'src/groebner/sympy_wbtest.mbt').write_text(out)
print('Generated',len(cases),'fixtures with SymPy',sp.__version__)
