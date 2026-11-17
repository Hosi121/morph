///|
fn input(
  points : Array[Array[Int32]],
  denominator : Int32,
) -> @core.Chain[@core.Chain[@exact.Rational]] {
  @oracle.chain(
    points.map(fn(row) {
      @oracle.chain(row.map(fn(value) { @oracle.rational(value, denominator) }))
    }),
  )
}

///|
fn complete(source : @persistence.Filtration) -> @persistence.Certificate {
  match
    @persistence.run(
      @persistence.start(source),
      @oracle.nat(1000),
      @oracle.nat(100),
    ) {
    Done(witness) => witness
    _ => abort("small exact filtration should finish")
  }
}

///|
fn grade_bars(
  witness : @persistence.Certificate,
) -> Array[(Int32, @exact.Rational, @exact.Rational?)] {
  @oracle.array(@persistence.barcode(witness)).map(fn(bar) {
    (@oracle.int_of_nat(bar.dimension), bar.birth, bar.death)
  })
}

///|
test "point dimensions exact rational distances and empty clouds" {
  assert_eq(cloud(@oracle.nat(2), input([[0], [1, 2]], 1)), None)
  assert_eq(
    squared_distance(
      @core.nth(input([[0, 0]], 1), @core.Zero).unwrap(),
      @core.nth(input([[1]], 1), @core.Zero).unwrap(),
    ),
    None,
  )
  let a = @oracle.chain([@oracle.rational(-1, 2), @oracle.rational(2, 3)])
  let b = @oracle.chain([@oracle.rational(1, 2), @oracle.rational(-1, 3)])
  assert_eq(squared_distance(a, b), Some(@oracle.rational(2, 1)))
  let empty = cloud(@oracle.nat(7), @core.Nil).unwrap()
  let filtration = build(empty, @oracle.nat(10)).unwrap()
  assert_true(check_filtration(empty, @oracle.nat(10), filtration))
  assert_eq(@persistence.entries(filtration), @core.Nil)
  assert_eq(@persistence.barcode(complete(filtration)), @core.Nil)
  let coincident = cloud(@core.Zero, @oracle.chain([@core.Nil, @core.Nil])).unwrap()
  assert_true(
    check_filtration(
      coincident,
      @oracle.nat(1),
      build(coincident, @oracle.nat(1)).unwrap(),
    ),
  )
}

///|
test "unit square has an H1 interval from squared distance one to two" {
  let source = cloud(@oracle.nat(2), input([[0, 0], [1, 0], [1, 1], [0, 1]], 1)).unwrap()
  let filtration = build(source, @oracle.nat(3)).unwrap()
  assert_true(check_filtration(source, @oracle.nat(3), filtration))
  assert_eq(
    @oracle.int_of_nat(@core.length(@persistence.entries(filtration))),
    15,
  )
  let witness = complete(filtration)
  assert_true(
    @persistence.check_result(
      filtration,
      @persistence.barcode(witness),
      witness,
    ),
  )
  let bars = grade_bars(witness)
  assert_eq(bars.filter(fn(bar) { bar.0 == 1 }), [
    (1, @oracle.rational(1, 1), Some(@oracle.rational(2, 1))),
  ])
  assert_eq(bars.filter(fn(bar) { bar.0 == 0 && bar.2 is None }).length(), 1)
  assert_eq(
    bars
    .filter(fn(bar) { bar.0 == 0 && bar.2 == Some(@oracle.rational(1, 1)) })
    .length(),
    3,
  )
  assert_eq(bars.filter(fn(bar) { bar.0 > 1 }).length(), 0)
}

///|
test "truncation really preserves top dimensional classes until cofaces arrive" {
  let source = cloud(@oracle.nat(2), input([[0, 0], [1, 0], [1, 1], [0, 1]], 1)).unwrap()
  let skeleton = build(source, @oracle.nat(2)).unwrap()
  let bars = grade_bars(complete(skeleton))
  assert_eq(bars.filter(fn(bar) { bar.0 == 2 }), [
    (2, @oracle.rational(2, 1), None),
  ])
  assert_true(check_filtration(source, @oracle.nat(2), skeleton))
  assert_false(check_filtration(source, @oracle.nat(3), skeleton))
  assert_false(check_filtration(source, @oracle.nat(1), skeleton))
}

///|
test "same-position vertices have zero-length merges omitted from grade barcode" {
  let source = cloud(@oracle.nat(1), input([[0], [0], [1]], 1)).unwrap()
  let filtration = build(source, @oracle.nat(2)).unwrap()
  let witness = complete(filtration)
  let bars = grade_bars(witness)
  assert_eq(bars.length(), 2)
  assert_eq(
    bars.filter(fn(bar) { bar.2 == Some(@oracle.rational(1, 1)) }).length(),
    1,
  )
  assert_eq(@oracle.int_of_nat(@core.length(@persistence.pairs(witness))), 3)
}

///|
test "checker binds grades completeness and actual coordinates" {
  let source = cloud(@oracle.nat(1), input([[0], [1], [2]], 1)).unwrap()
  let filtration = build(source, @oracle.nat(2)).unwrap()
  let entries = @persistence.entries(filtration)
  let shifted = @persistence.validate(
    @core.map(entries, fn(entry) {
      @persistence.Entry::{
        simplex: entry.simplex,
        grade: @exact.rational_add(entry.grade, @exact.rational_one()),
      }
    }),
  ).unwrap()
  assert_false(check_filtration(source, @oracle.nat(2), shifted))
  assert_false(
    check_filtration(
      source,
      @oracle.nat(2),
      @persistence.validate(@core.Nil).unwrap(),
    ),
  )
  let different = cloud(@oracle.nat(1), input([[0], [1], [3]], 1)).unwrap()
  assert_false(check_filtration(different, @oracle.nat(2), filtration))
  assert_eq(grade(source, @core.Nil), None)
  assert_eq(grade(source, @oracle.chain([@oracle.nat(3)])), None)
}

///|
// Independent machine-array subset enumeration, deliberately no shared grade,
// sorting, subset enumeration or distance helper from the production code.
test "all 121 small rational line clouds match independent subset metrics" {
  for size in 0..<=4 {
    let mut choices = 1
    for _ in 0..<size {
      choices *= 3
    }
    for assignment in 0..<choices {
      let mut value = assignment
      let coords : Array[Int32] = []
      for _ in 0..<size {
        coords.push(value % 3 - 1)
        value /= 3
      }
      let source = cloud(@oracle.nat(1), input(coords.map(fn(x) { [x] }), 2)).unwrap()
      for cap in [0, 1, 3] {
        let actual = build(source, @oracle.nat(cap)).unwrap()
        assert_true(check_filtration(source, @oracle.nat(cap), actual))
        let entries = @oracle.array(@persistence.entries(actual))
        let mut count = 0
        for mask in 1..<(1 << size) {
          let vertices = [ for v in 0..<size if (mask & (1 << v)) != 0 => v ]
          if vertices.length() <= cap + 1 {
            count += 1
            let mut squared = 0
            for a in vertices {
              for b in vertices {
                let d = coords[a] - coords[b]
                squared = squared.max(d * d)
              }
            }
            let found = entries.filter(fn(entry) {
              @oracle.array(entry.simplex).map(@oracle.int_of_nat) == vertices
            })
            assert_eq(found.length(), 1)
            assert_eq(found[0].grade, @oracle.rational(squared, 4))
          }
        }
        assert_eq(entries.length(), count)
      }
    }
  }
}
