///|
fn review_order(value : Int32) -> @core.Ordering {
  if value < 0 {
    Less
  } else if value > 0 {
    Greater
  } else {
    Equal
  }
}

///|
fn review_evaluate(
  cs : Array[(Int32, Int32)],
  value : @nf.Element,
) -> @nf.Element {
  let f = @nf.parent(value)
  let mut result = @nf.zero(f)
  for i = cs.length() - 1; i >= 0; i = i - 1 {
    result = @nf.add(
      @nf.rational(f, @oracle.rational(cs[i].0, cs[i].1)),
      @nf.multiply(result, value).unwrap(),
    ).unwrap()
  }
  result
}

///|
fn review_fixture(
  a : Array[(Int32, Int32)],
  alower : (Int32, Int32),
  aupper : (Int32, Int32),
  b : Array[(Int32, Int32)],
  blower : (Int32, Int32),
  bupper : (Int32, Int32),
  expected_seed : Int32,
  expected_selected : Int32,
  expected_orders : Array[(Int32, Int32)],
  expected_minimal : Array[(Int32, Int32)],
  expected_left : Array[(Int32, Int32)],
  expected_right : Array[(Int32, Int32)],
) -> Unit raise {
  let left = test_root(a, alower, aupper)
  let right = test_root(b, blower, bupper)
  let (value, proof) = test_compose(left, right)
  let field = common_field(value)
  let x = left_element(value)
  let y = right_element(value)
  assert_eq(
    @oracle.int_of_binary(proof.separation.augmentation.seed),
    expected_seed,
  )
  assert_eq(proof.selected, @oracle.nat(expected_selected))
  assert_eq(@nf.degree(field), @oracle.nat(expected_minimal.length() - 1))
  assert_eq(@nf.modulus(field), test_poly(expected_minimal))
  assert_eq(@nf.representative(x), test_poly(expected_left))
  assert_eq(@nf.representative(y), test_poly(expected_right))
  assert_true(@nf.is_zero(review_evaluate(a, x)))
  assert_true(@nf.is_zero(review_evaluate(b, y)))
  let parameter = @nf.add(
    x,
    @nf.multiply(@nf.rational(field, @oracle.rational(expected_seed, 1)), y).unwrap(),
  ).unwrap()
  assert_true(@nf.equal(parameter, @nf.generator(field).unwrap()))
  let rows = @oracle.array(proof.selection)
  assert_eq(rows.length(), expected_orders.length())
  for i in 0..<rows.length() {
    assert_eq(rows[i].left_comparison.order, review_order(expected_orders[i].0))
    assert_eq(
      rows[i].right_comparison.order,
      review_order(expected_orders[i].1),
    )
    assert_eq(rows[i].left.index, @oracle.nat(0))
    assert_eq(rows[i].right.index, @oracle.nat(1))
  }
  assert_eq(
    check_result(left, right, value, proof, @oracle.nat(512)),
    @zass.Proven,
  )
  assert_true(@nf.check_realization(x, proof.left_embedding))
  assert_true(@nf.check_realization(y, proof.right_embedding))
  let lx = @real.number(proof.left_embedding.result).unwrap()
  let ry = @real.number(proof.right_embedding.result).unwrap()
  assert_equivalent(lx, left)
  assert_equivalent(ry, right)
}

///|
test "independent compositum review coherent coverage and uniqueness forgeries" {
  let a = test_sqrt(3, false)
  let (value, p) = test_compose(a, a)
  assert_eq(check_result(a, a, value, p, @oracle.nat(512)), @zass.Proven)
  let intervals = @oracle.array(p.separation.solutions.intervals)
  let rows = @oracle.array(p.selection)
  assert_eq(intervals.length(), 4)
  // Remove the same point and comparison row together, and repair the index.
  let missing = {
    ..p,
    separation: {
      ..p.separation,
      solutions: {
        ..p.separation.solutions,
        intervals: @core.drop(@oracle.nat(1), p.separation.solutions.intervals),
      },
    },
    selection: @core.drop(@oracle.nat(1), p.selection),
    selected: @oracle.nat(2),
  }
  assert_eq(check(a, a, missing, @oracle.nat(512)), @zass.Refuted)
  let duplicated = {
    ..p,
    separation: {
      ..p.separation,
      solutions: {
        ..p.separation.solutions,
        intervals: @core.append(
          p.separation.solutions.intervals,
          Cons(intervals[3], Nil),
        ),
      },
    },
    selection: @core.append(p.selection, Cons(rows[3], Nil)),
  }
  assert_eq(check(a, a, duplicated, @oracle.nat(512)), @zass.Refuted)
  let reordered = {
    ..p,
    separation: {
      ..p.separation,
      solutions: {
        ..p.separation.solutions,
        intervals: @core.reverse(p.separation.solutions.intervals),
      },
    },
    selection: @core.reverse(p.selection),
    selected: @oracle.nat(0),
  }
  assert_eq(check(a, a, reordered, @oracle.nat(512)), @zass.Refuted)
  let fake_row = {
    ..rows[0],
    left_comparison: { ..rows[0].left_comparison, order: Equal, },
    right_comparison: { ..rows[0].right_comparison, order: Equal, },
  }
  assert_eq(
    check(
      a,
      a,
      { ..p, selection: Cons(fake_row, p.selection), selected: @oracle.nat(0), },
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  let swapped_rows = @oracle.chain(
    rows.map(fn(row) {
      SelectionRow::{
        left: row.right,
        right: row.left,
        left_comparison: row.right_comparison,
        right_comparison: row.left_comparison,
      }
    }),
  )
  assert_eq(
    check(a, a, { ..p, selection: swapped_rows, }, @oracle.nat(512)),
    @zass.Refuted,
  )
  assert_eq(
    check(a, a, { ..p, selected: @oracle.nat(0), }, @oracle.nat(512)),
    @zass.Refuted,
  )
  let wrong_coordinates = {
    ..p.separation.solutions.shape,
    coordinates: @core.reverse(p.separation.solutions.shape.coordinates),
    coordinate_sources: @core.reverse(
      p.separation.solutions.shape.coordinate_sources,
    ),
  }
  assert_eq(
    check(
      a,
      a,
      {
        ..p,
        separation: {
          ..p.separation,
          solutions: { ..p.separation.solutions, shape: wrong_coordinates, },
        },
      },
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  assert_eq(
    check(
      a,
      a,
      { ..p, separation: { ..p.separation, projection: @oracle.nat(1), }, },
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
}

///|
test "independent compositum review complete conjugate bundles and output contexts" {
  let a = test_root([(-1, 1), (-2, 1), (1, 1)], (2, 1), (3, 1)) // 1+sqrt2
  let b = test_sqrt(2, false)
  let c = test_root([(-1, 1), (-2, 1), (1, 1)], (-1, 1), (0, 1)) // 1-sqrt2
  let d = test_sqrt(2, true)
  let (value, p) = test_compose(a, b)
  let (opposite, q) = test_compose(c, d)
  assert_eq(@nf.modulus(value.field), @nf.modulus(opposite.field))
  assert_eq(@nf.representative(value.left), @nf.representative(opposite.left))
  assert_eq(@nf.representative(value.right), @nf.representative(opposite.right))
  assert_false(@nf.same_field(value.field, opposite.field))
  // Valid complete other-conjugate proof, with only its public source headers repaired.
  assert_eq(
    check(a, b, { ..q, left: p.left, right: p.right, }, @oracle.nat(512)),
    @zass.Refuted,
  )
  // Keep all correct Cartesian selections but move minimality and both complete
  // realization/equality bundles together to the other selected parameter.
  let bundle = {
    ..p,
    minimal: q.minimal,
    left_embedding: q.left_embedding,
    right_embedding: q.right_embedding,
    left_equality: q.left_equality,
    right_equality: q.right_equality,
  }
  assert_eq(check(a, b, bundle, @oracle.nat(512)), @zass.Refuted)
  assert_eq(check_result(a, b, opposite, p, @oracle.nat(512)), @zass.Refuted)
  assert_eq(
    check_result(
      a,
      b,
      { ..value, left: opposite.left, right: opposite.right, },
      p,
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  assert_eq(
    check_result(
      a,
      b,
      { ..value, left: value.right, right: value.left, },
      p,
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  let swapped = {
    ..p,
    left_embedding: p.right_embedding,
    right_embedding: p.left_embedding,
    left_equality: p.right_equality,
    right_equality: p.left_equality,
  }
  assert_eq(
    check_result(
      a,
      b,
      { ..value, left: value.right, right: value.left, },
      swapped,
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  let scalar = @nf.rational(value.field, @oracle.rational(1, 1))
  let forged_value : Common = { ..value, left: scalar, }
  let forged_proof = {
    ..p,
    left_embedding: { ..p.left_embedding, input: @nf.representative(scalar), },
  }
  assert_eq(
    check_result(a, b, forged_value, forged_proof, @oracle.nat(512)),
    @zass.Refuted,
  )
  let refined_a = @real.refine(a, @oracle.nat(1)).unwrap()
  assert_eq(
    check_result(refined_a, b, value, p, @oracle.nat(512)),
    @zass.Refuted,
  )
  let other_source = {
    ..p.separation.augmentation.source,
    inputs: @core.reverse(p.separation.augmentation.source.inputs),
  }
  let aug = { ..q.separation.augmentation, source: other_source, }
  assert_eq(
    check(
      a,
      b,
      { ..p, separation: { ..q.separation, augmentation: aug, }, },
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  assert_eq(
    check(
      a,
      b,
      { ..p, left_equality: q.left_equality, right_equality: q.right_equality, },
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
}

///|
test "independent compositum review bad prime and verification budgets remain unclaimed" {
  let a = test_sqrt(3, false)
  let budget = test_budget()
  for
    b in [
      Budget::{ ..budget, attempts: @oracle.nat(0), },
      Budget::{ ..budget, work: @oracle.nat(0), },
      Budget::{ ..budget, coordinate: @oracle.nat(0), },
      Budget::{ ..budget, primes: @oracle.chain([2, 3].map(@oracle.binary)), },
      Budget::{ ..budget, lift: @oracle.nat(0), },
      Budget::{ ..budget, subset: @oracle.nat(0), },
      Budget::{ ..budget, realization: @oracle.nat(0), },
    ] {
    assert_true(compose(a, a, b).unwrap() is Unresolved(_))
  }
  let (value, proof) = test_compose(a, a)
  assert_eq(check_result(a, a, value, proof, @oracle.nat(0)), @zass.Undecided)
  assert_eq(check_result(a, a, value, proof, @oracle.nat(512)), @zass.Proven)
}
