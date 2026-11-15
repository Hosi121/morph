///|
/// Decimal formatting converts only individual decimal digits to machine Int.
/// The algorithm's arbitrary-precision result never passes through Int.
fn binary_text(n : @binary.Binary) -> String {
  if @binary.is_zero(n) {
    return "0"
  }
  let (quotient, remainder) = required(@binary.divmod(n, @oracle.binary(10)))
  let digit = @oracle.int_of_binary(remainder).to_string()
  if @binary.is_zero(quotient) {
    digit
  } else {
    binary_text(quotient) + digit
  }
}

///|
fn rational_text(r : @exact.Rational) -> String {
  let n = @exact.numerator(r)
  let sign = if @exact.negative(n) { "-" } else { "" }
  let numerator = sign + binary_text(@exact.magnitude(n))
  if @exact.denominator(r) == @binary.one() {
    numerator
  } else {
    numerator + "/" + binary_text(@exact.denominator(r))
  }
}

///|
fn demo_poly(data : Array[(Int32, Array[Int32])]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(2),
    @oracle.chain(
      data.map(fn(term) {
        let (coefficient, exponents) = term
        @poly.Term::{
          coefficient: @oracle.rational(coefficient, 1),
          exponents: @oracle.chain(exponents.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn polynomial_text(p : @poly.Polynomial) -> String {
  let mut result = ""
  for term in @oracle.array(@poly.terms(p)) {
    let negative = @exact.negative(@exact.numerator(term.coefficient))
    let coefficient = if negative {
      @exact.rational_negate(term.coefficient)
    } else {
      term.coefficient
    }
    let factors = []
    for index, power in @oracle.array(term.exponents) {
      let exponent = @oracle.int_of_nat(power)
      if exponent != 0 {
        let variable = if index == 0 { "x" } else { "y" }
        factors.push(
          if exponent == 1 {
            variable
          } else {
            variable + "^" + exponent.to_string()
          },
        )
      }
    }
    let factors = if coefficient != @exact.rational_one() || factors.is_empty() {
      [rational_text(coefficient), ..factors]
    } else {
      factors
    }
    let sign = if result == "" {
      if negative {
        "-"
      } else {
        ""
      }
    } else if negative {
      " - "
    } else {
      " + "
    }
    result += sign + factors.join("*")
  }
  if result == "" {
    "0"
  } else {
    result
  }
}

///|
fn arithmetic_and_algebra() -> Unit {
  let (fib, _) = @binary.fibonacci_pair(@oracle.binary(100))
  println("高速倍化 Fibonacci(100) = \{binary_text(fib)}")
  let pair = @bitcodec.pair_word(
    @binary.power(@oracle.binary(2), @oracle.binary(600)),
    @binary.power(@oracle.binary(2), @oracle.binary(400)),
  )
  println(
    "自己区切りpair(2^600,2^400): \{@oracle.int_of_nat(@core.length(pair))} bits; 復号できる = \{@bitcodec.decode_pair(pair) is Some(_)}",
  )
  let digest = required(@sha256.hash(@oracle.bits_from_bytes(b"abc")))
  println("Boolリストの SHA-256(abc) = \{@oracle.hex_bits(digest)}")
  let generators = @oracle.chain([
    demo_poly([(1, [2, 0]), (-1, [0, 1])]),
    demo_poly([(1, [1, 1]), (-1, [0, 0])]),
  ])
  match
    @groebner.buchberger(@oracle.nat(2), generators, @oracle.nat(128)).unwrap() {
    Complete(basis) =>
      println(
        "Gröbner {x^2-y,xy-1} -> \{@debug.Repr(@oracle.array(@groebner.polynomials(basis)).map(polynomial_text))}; Sペア検査 = \{@groebner.verify(basis).unwrap()}",
      )
    Paused(_) => abort("demo Groebner budget insufficient")
  }
  let rows = @oracle.chain(
    [[2, 1], [1, 2], [-1, 0], [0, -1]].map(fn(row) {
      @oracle.chain(row.map(fn(n) { @oracle.rational(n, 1) }))
    }),
  )
  let p = required(
    @simplex.problem(
      required(@matrix.matrix(@oracle.nat(2), rows)),
      @oracle.chain([4, 4, -1, -1].map(fn(n) { @oracle.rational(n, 1) })),
      @oracle.chain([1, 1].map(fn(n) { @oracle.rational(n, 1) })),
    ),
  )
  match @simplex.run(@simplex.start(p), @oracle.nat(64)) {
    Optimal(certificate) =>
      println(
        "二段階単体法: x = \{@debug.Repr(@oracle.array(certificate.primal).map(rational_text))}, max = \{rational_text(certificate.value)}; 双対検査 = \{@simplex.check_optimum(p,certificate)}",
      )
    _ => abort("demo LP should have an optimum")
  }
  let polynomial = @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain([
      @poly.Term::{
        coefficient: @oracle.rational(1, 1),
        exponents: @core.Cons(@oracle.nat(2), Nil),
      },
      @poly.Term::{
        coefficient: @oracle.rational(-2, 1),
        exponents: @core.Cons(Zero, Nil),
      },
    ]),
  ).unwrap()
  let system = @sturm.system(polynomial).unwrap()
  let interval = required(
    @sturm.refine(
      system,
      { lower: @oracle.rational(0, 1), upper: @oracle.rational(2, 1), },
      @oracle.nat(16),
    ),
  )
  println(
    "Sturm: x^2-2の実根は \{@oracle.int_of_nat(@sturm.count_all(system))} 個; 正の根は (\{rational_text(interval.lower)}, \{rational_text(interval.upper)}]",
  )
}

///|
fn search_and_geometry() -> Unit {
  let edges = @oracle.chain(
    [(0, 1, 3), (0, 2, 2), (1, 2, 1), (1, 3, 2), (2, 3, 3)].map(fn(data) {
      let (from, to, weight) = data
      @graph.Edge::{
        from: @oracle.nat(from),
        to: @oracle.nat(to),
        weight: @oracle.binary(weight),
      }
    }),
  )
  let g = required(
    @graph.graph(@oracle.chain([0, 1, 2, 3].map(@oracle.nat)), edges),
  )
  let flow = required(@maxflow.max_flow(g, @oracle.nat(0), @oracle.nat(3)))
  println(
    "最大流 = \{binary_text(flow.value)}; 最小カット検査 = \{@maxflow.check(g,@oracle.nat(0),@oracle.nat(3),flow)}",
  )
  let forest = @spanning.kruskal(g)
  println(
    "同じ辺を無向とした最小全域木 = \{binary_text(forest.total)}; 最適性検査 = \{@spanning.check(g,forest)}",
  )
  let p = required(@puzzles.queens_problem(@oracle.nat(8)))
  let mut search = @exactcover.enumerate(p)
  let mut solutions = 0
  let mut done = false
  while !done {
    match @exactcover.advance(search, @oracle.nat(100)) {
      Found(_, rest) => {
        solutions += 1
        search = rest
      }
      Pending(rest) => search = rest
      Exhausted => done = true
    }
  }
  println(
    "8クイーン全配置 = \{solutions} 解（回転・鏡映を別に数える）",
  )
  let grid = [[1, 0, 0, 4], [0, 4, 1, 0], [2, 0, 4, 0], [0, 3, 0, 1]]
  let clues = []
  for r, row in grid {
    for c, value in row {
      if value != 0 {
        clues.push(@puzzles.Cell::{
          row: @oracle.nat(r),
          column: @oracle.nat(c),
          value: @oracle.nat(value - 1),
        })
      }
    }
  }
  let cells = required(@puzzles.sudoku(@oracle.nat(2), @oracle.chain(clues)))
  let result = Array::make(4, 0).map(fn(_) { Array::make(4, 0) })
  for cell in @oracle.array(cells) {
    result[@oracle.int_of_nat(cell.row)][@oracle.int_of_nat(cell.column)] = @oracle.int_of_nat(
        cell.value,
      ) +
      1
  }
  println("4x4数独 = \{@debug.Repr(result)}")
  let x = @ad.Variable(@oracle.nat(0))
  let y = @ad.Variable(@oracle.nat(1))
  let expression = @ad.sum(
    @ad.sum(@ad.product(x, x), @ad.product(x, y)),
    @ad.product(y, y),
  )
  let gradient = required(
    @ad.reverse(
      expression,
      @oracle.chain([
        (@oracle.nat(0), @oracle.rational(2, 1)),
        (@oracle.nat(1), @oracle.rational(3, 1)),
      ]),
    ),
  )
  println(
    "逆向きAD: x^2+xy+y^2 at (2,3) = \{rational_text(gradient.value)}, gradient = (\{rational_text(@ad.partial(gradient,@oracle.nat(0)))}, \{rational_text(@ad.partial(gradient,@oracle.nat(1)))})",
  )
  let points = @oracle.chain(
    [(0, 0), (2, 0), (2, 2), (0, 2), (1, 1), (0, 0)].map(fn(pair) {
      let (x, y) = pair
      @geometry.Point::{ x: @oracle.rational(x, 1), y: @oracle.rational(y, 1), }
    }),
  )
  let hull = @geometry.convex_hull(points)
  println(
    "厳密凸包: \{@oracle.int_of_nat(@core.length(hull))} 頂点、面積 = \{rational_text(@geometry.area(hull))}",
  )
}
