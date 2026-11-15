#!/usr/bin/env python3
"""Independent exact SymPy LLL transforms and Gram-Schmidt property fixtures."""
from pathlib import Path
import random
import sympy
from sympy import Matrix, QQ, Rational

ROOT = Path(__file__).resolve().parent.parent


def chain(items: list[str]) -> str:
    result = 'Nil'
    for item in reversed(items):
        result = f'Cons({item}, {result})'
    return result


def rational(value) -> str:
    n, d = map(int, value.as_numer_denom())
    assert -(1 << 31) < n < (1 << 31) and 0 < d < (1 << 31)
    return f'@oracle.rational({n}, {d})'


def evidence(matrix: Matrix) -> tuple[str, list, list]:
    vectors = [Matrix(list(matrix.row(i))) for i in range(matrix.rows)]
    stars = Matrix.orthogonalize(*vectors, normalize=False, rankcheck=True)
    norms = [v.dot(v) for v in stars]
    coefficients = [[vectors[i].dot(stars[j]) / norms[j] for j in range(i)]
                    for i in range(matrix.rows)]
    expression = '{ orthogonal: ' + chain([chain([rational(x) for x in v]) for v in stars])
    expression += ', coefficients: ' + chain([chain([rational(x) for x in row]) for row in coefficients])
    expression += ', norms: ' + chain([rational(x) for x in norms]) + ' }'
    return expression, coefficients, norms


def main() -> None:
    rng = random.Random(20261115)
    cases = [Matrix([[1, 1, 1], [-1, 0, 2], [3, 5, 6]]),
             Matrix([[2, 0], [3, 2]]), Matrix([[2, 0], [-3, 2]]),
             Matrix([[2, 0, 0], [1, 1, 1]])]
    for m, n in [(1, 2), (2, 2), (2, 3), (3, 3), (3, 4), (4, 4)]:
        for _ in range(4):
            while True:
                candidate = Matrix([[rng.randrange(-8, 9) for _ in range(n)] for _ in range(m)])
                if candidate.rank() == m:
                    break
            cases.append(candidate)
    out = f'// Generated independently using SymPy {sympy.__version__}, exact QQ delta=3/4.\n'
    out += '///|\ntest "exact LLL checker and Gram Schmidt agree with independent SymPy properties" {\n'
    for source in cases:
        reduced, transform = source.lll_transform(delta=QQ(3, 4))
        assert transform * source == reduced and abs(transform.det()) == 1
        gram, mu, norms = evidence(reduced)
        assert all(abs(value) <= Rational(1, 2) for row in mu for value in row)
        assert all(norms[k] >= (Rational(3, 4) - mu[k][k - 1]**2) * norms[k - 1]
                   for k in range(1, len(norms)))
        out += f'  check_sympy({source.cols}, {source.tolist()!r}, {transform.tolist()!r}, {reduced.tolist()!r}, {gram})\n'
    out += '}\n'
    (ROOT / 'src/lll/vectors_wbtest.mbt').write_text(out)


if __name__ == '__main__':
    main()
