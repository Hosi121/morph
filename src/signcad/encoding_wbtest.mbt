///|
fn axis(dimension : Int32) -> @poly.Polynomial raise {
  let exponents = @oracle.chain(
    [
      for i in 0..<dimension => {
        @oracle.nat(if i == dimension - 1 { 1 } else { 0 })
      }
    ],
  )
  match
    @poly.polynomial(
      @oracle.nat(dimension),
      @core.Cons(
        @poly.Term::{ coefficient: @exact.rational_one(), exponents, },
        @core.Nil,
      ),
    ) {
    Ok(p) => p
    Err(_) => fail("axis")
  }
}

///|
fn family_levels(
  dimensions : Int32,
) -> @core.Chain[@core.Chain[@poly.Polynomial]] raise {
  @oracle.chain([ for i in 1..<=dimensions => @core.Cons(axis(i), @core.Nil) ])
}

///|
fn finite_tree(
  depth : Int32,
  dimensions : Int32,
  index : Int32,
  mask : Int32,
) -> Tree {
  if depth == dimensions {
    Leaf((mask & (1 << index)) != 0)
  } else {
    Branch(
      @oracle.chain(
        [
          for digit in 0..<3 => {
            Child::{
              signs: @core.Cons(
                match digit {
                  0 => @core.Less
                  1 => @core.Equal
                  _ => @core.Greater
                },
                @core.Nil,
              ),
              subtree: finite_tree(
                depth + 1,
                dimensions,
                index * 3 + digit,
                mask,
              ),
            }
          }
        ],
      ),
    )
  }
}

///|
fn host_relation(relation : @qf.Relation, sign : Int32) -> Bool {
  match relation {
    LessZero => sign < 0
    AtMostZero => sign <= 0
    EqualZero => sign == 0
    NotZero => sign != 0
    AtLeastZero => sign >= 0
    GreaterZero => sign > 0
  }
}

///|
fn host_evaluate(formula : @qf.Formula, values : Array[Int32]) -> Bool raise {
  match formula {
    Truth(value) => value
    Atom(p, relation) => {
      assert_eq(@oracle.int_of_nat(@poly.variables(p)), values.length())
      match
        @poly.evaluate(
          p,
          @oracle.chain(values.map(fn(v) { @oracle.rational(v, 1) })),
        ) {
        None => fail("formula arity")
        Some(q) =>
          host_relation(
            relation,
            match @exact.rational_compare(q, @exact.rational_zero()) {
              Less => -1
              Equal => 0
              Greater => 1
            },
          )
      }
    }
    Negation(body) => !host_evaluate(body, values)
    Conjunction(a, b) => host_evaluate(a, values) && host_evaluate(b, values)
    Disjunction(a, b) => host_evaluate(a, values) || host_evaluate(b, values)
  }
}

///|
fn host_quantify(
  mask : Int32,
  dimensions : Int32,
  free : Int32,
  quantifiers : Int32,
  depth : Int32,
  index : Int32,
) -> Bool {
  if depth == dimensions {
    (mask & (1 << index)) != 0
  } else {
    let forall = (quantifiers & (1 << (depth - free))) != 0
    let answers = [
      for digit in 0..<3 => {
        host_quantify(
          mask,
          dimensions,
          free,
          quantifiers,
          depth + 1,
          index * 3 + digit,
        )
      }
    ]
    if forall {
      answers.all(fn(v) { v })
    } else {
      answers.any(fn(v) { v })
    }
  }
}

///|
fn digits(index : Int32, length : Int32) -> Array[Int32] {
  let answer = Array::make(length, 0)
  let mut rest = index
  for i = length - 1; i >= 0; i = i - 1 {
    answer[i] = rest % 3
    rest = rest / 3
  }
  answer
}

///|
fn power_three(n : Int32) -> Int32 {
  let mut answer = 1
  for _ in 0..<n {
    answer = answer * 3
  }
  answer
}

///|
test "all 512 two-dimensional truth tables preserve every free split and quantifier order" {
  let levels = family_levels(2)
  for mask in 0..<512 {
    let tree = finite_tree(0, 2, 0, mask)
    for free in 0..<=2 {
      let count = 2 - free
      for qs in 0..<(1 << count) {
        let prefix : @core.Chain[@logic.Quantifier] = @oracle.chain(
          [
            for i in 0..<count => {
              if (qs & (1 << i)) != 0 {
                @logic.Quantifier::Forall
              } else {
                @logic.Quantifier::Exists
              }
            }
          ],
        )
        let encoded = match encode(@oracle.nat(free), prefix, levels, tree) {
          Ok(value) => value
          Err(_) => fail("encode failed")
        }
        for index in 0..<power_three(free) {
          let sign_digits = digits(index, free)
          let expected = host_quantify(mask, 2, free, qs, free, index)
          assert_eq(
            host_evaluate(formula(encoded), sign_digits.map(fn(d) { d - 1 })),
            expected,
          )
          assert_eq(
            host_evaluate(
              formula(encoded),
              sign_digits.map(fn(d) { (d - 1) * 7 }),
            ),
            expected,
          )
        }
      }
    }
  }
}

///|
test "three-dimensional alternating quantifiers collapse each fibre first" {
  let levels = family_levels(3)
  for mask in [1, 15, 285, 1048577, 67108865, 134217727] {
    let tree = finite_tree(0, 3, 0, mask)
    for qs in 0..<8 {
      let prefix : @core.Chain[@logic.Quantifier] = @oracle.chain(
        [
          for i in 0..<3 => {
            if (qs & (1 << i)) != 0 {
              @logic.Quantifier::Forall
            } else {
              @logic.Quantifier::Exists
            }
          }
        ],
      )
      match encode(@core.Zero, prefix, levels, tree) {
        Ok(value) =>
          assert_eq(
            formula(value),
            @qf.Truth(host_quantify(mask, 3, 0, qs, 0, 0)),
          )
        Err(_) => fail("encode failed")
      }
    }
  }
}

///|
test "zero variables and empty families represent nonempty real fibres" {
  let no_dimensions : @core.Chain[@core.Chain[@poly.Polynomial]] = @core.Nil
  match encode(@core.Zero, @core.Nil, no_dimensions, Leaf(true)) {
    Ok(value) => assert_eq(formula(value), @qf.Truth(true))
    Err(_) => fail("encode failed")
  }
  let empty_family : @core.Chain[@core.Chain[@poly.Polynomial]] = @core.Cons(
    @core.Nil,
    @core.Nil,
  )
  let tree = Branch(
    @core.Cons(Child::{ signs: @core.Nil, subtree: Leaf(false), }, @core.Nil),
  )
  match
    encode(
      @core.Zero,
      @core.Cons(@logic.Quantifier::Forall, @core.Nil),
      empty_family,
      tree,
    ) {
    Ok(value) => assert_eq(formula(value), @qf.Truth(false))
    Err(_) => fail("encode failed")
  }
  assert_true(
    encode(@oracle.nat(1), @core.Nil, empty_family, Branch(@core.Nil))
    is Err(InvalidTree),
  )
}

///|
test "malformed dimensions, branches, sign lengths and ambiguous siblings are rejected" {
  let levels = family_levels(1)
  assert_true(
    encode(@oracle.nat(2), @core.Nil, levels, finite_tree(0, 1, 0, 1))
    is Err(DimensionMismatch),
  )
  assert_true(
    encode(@oracle.nat(1), @core.Nil, levels, finite_tree(0, 2, 0, 1))
    is Err(InvalidTree),
  )
  let child = Child::{
    signs: @core.Cons(@core.Less, @core.Nil),
    subtree: Leaf(true),
  }
  assert_true(
    encode(
      @oracle.nat(1),
      @core.Nil,
      levels,
      Branch(@oracle.chain([child, child])),
    )
    is Err(AmbiguousSigns),
  )
  assert_true(
    encode(
      @oracle.nat(1),
      @core.Nil,
      levels,
      Branch(
        @core.Cons(Child::{ signs: @core.Nil, subtree: Leaf(true), }, @core.Nil),
      ),
    )
    is Err(DimensionMismatch),
  )
  assert_true(
    encode(@oracle.nat(1), @core.Nil, family_levels(2), finite_tree(0, 2, 0, 1))
    is Err(DimensionMismatch),
  )
}

///|
test "certificates bind source dimensions, quantifiers, families, tree and returned formula" {
  let levels = family_levels(2)
  let tree = finite_tree(0, 2, 0, 285)
  let prefix = @core.Cons(@logic.Quantifier::Exists, @core.Nil)
  let one = @oracle.nat(1)
  let value = match encode(one, prefix, levels, tree) {
    Ok(v) => v
    Err(_) => fail("encode failed")
  }
  let proof = certificate(value)
  assert_true(check_result(one, prefix, levels, tree, value, proof))
  assert_true(
    check(
      one,
      @core.Cons(@logic.Quantifier::Forall, @core.Nil),
      levels,
      tree,
      proof,
    )
    is None,
  )
  assert_true(
    check(one, prefix, levels, finite_tree(0, 2, 0, 284), proof) is None,
  )
  assert_true(
    check(one, prefix, levels, tree, { ..proof, formula: @qf.Truth(true), })
    is None,
  )
  assert_true(check(@core.Zero, prefix, levels, tree, proof) is None)
  assert_true(check(one, prefix, @core.Nil, tree, proof) is None)
  let other = match encode(one, prefix, levels, finite_tree(0, 2, 0, 0)) {
    Ok(v) => v
    Err(_) => fail("encode failed")
  }
  assert_false(check_result(one, prefix, levels, tree, other, proof))
}

///|
/// This host oracle starts from a full ternary truth table. It shortens a
/// subtree only when every one of its table entries has the same Boolean.
fn compact_table(
  depth : Int32,
  dimensions : Int32,
  index : Int32,
  mask : Int32,
) -> Tree {
  let count = power_three(dimensions - depth)
  let first = (mask & (1 << (index * count))) != 0
  let mut uniform = true
  for offset in 0..<count {
    if ((mask & (1 << (index * count + offset))) != 0) != first {
      uniform = false
    }
  }
  if uniform {
    Leaf(first)
  } else {
    Branch(
      @oracle.chain(
        [
          for digit in 0..<3 => {
            Child::{
              signs: @core.Cons(
                match digit {
                  0 => @core.Less
                  1 => @core.Equal
                  _ => @core.Greater
                },
                @core.Nil,
              ),
              subtree: compact_table(
                depth + 1,
                dimensions,
                index * 3 + digit,
                mask,
              ),
            }
          }
        ],
      ),
    )
  }
}

///|
fn compact_table_case(mask : Int32, dimensions : Int32) -> Unit raise {
  let levels = family_levels(dimensions)
  let tree = compact_table(0, dimensions, 0, mask)
  for free in 0..<=dimensions {
    let count = dimensions - free
    for qs in 0..<(1 << count) {
      let prefix : @core.Chain[@logic.Quantifier] = @oracle.chain(
        [
          for i in 0..<count => {
            if (qs & (1 << i)) != 0 {
              @logic.Quantifier::Forall
            } else {
              @logic.Quantifier::Exists
            }
          }
        ],
      )
      let value = match encode(@oracle.nat(free), prefix, levels, tree) {
        Ok(value) => value
        Err(error) => fail("compact encode: \{error.to_repr()}")
      }
      assert_true(
        check_result(
          @oracle.nat(free),
          prefix,
          levels,
          tree,
          value,
          certificate(value),
        ),
      )
      for index in 0..<power_three(free) {
        let expected = host_quantify(mask, dimensions, free, qs, free, index)
        let signs = digits(index, free)
        assert_eq(
          host_evaluate(formula(value), signs.map(fn(d) { d - 1 })),
          expected,
        )
        assert_eq(
          host_evaluate(formula(value), signs.map(fn(d) { (d - 1) * 13 })),
          expected,
        )
      }
    }
  }
}

///|
test "all compressed two-dimensional tables preserve free and quantified cylinder semantics" {
  for mask in 0..<512 {
    compact_table_case(mask, 2)
  }
}

///|
test "mixed-depth constant cylinders preserve three-dimensional quantifier alternation" {
  // Uniform groups of 3 and 9 produce leaves before either free-variable or
  // quantified splits; nonuniform groups retain the intervening branches.
  for
    mask in [
      0, 1, 7, 15, 285, 511, 262143, 1048577, 67108865, 134217216, 134217727,
    ] {
    compact_table_case(mask, 3)
  }
}

///|
test "early leaves retain dimension, family and surrounding branch validation" {
  let levels = family_levels(2)
  assert_true(
    encode(@oracle.nat(1), @core.Nil, levels, Leaf(true))
    is Err(DimensionMismatch),
  )
  let wrong_levels = @oracle.chain([
    @core.Cons(axis(2), @core.Nil),
    @core.Cons(axis(2), @core.Nil),
  ])
  assert_true(
    encode(@oracle.nat(2), @core.Nil, wrong_levels, Leaf(true))
    is Err(DimensionMismatch),
  )
  let short = Child::{
    signs: @core.Cons(@core.Equal, @core.Nil),
    subtree: Leaf(false),
  }
  assert_true(
    encode(
      @oracle.nat(2),
      @core.Nil,
      levels,
      Branch(@oracle.chain([short, short])),
    )
    is Err(AmbiguousSigns),
  )
  assert_true(
    encode(@oracle.nat(2), @core.Nil, levels, Branch(@core.Nil))
    is Err(InvalidTree),
  )
  assert_true(
    encode(
      @oracle.nat(2),
      @core.Nil,
      levels,
      Branch(@core.Cons({ ..short, signs: @core.Nil, }, @core.Nil)),
    )
    is Err(DimensionMismatch),
  )
  assert_true(
    encode(
      @core.Zero,
      @core.Nil,
      @core.Nil,
      Branch(@core.Cons(short, @core.Nil)),
    )
    is Err(InvalidTree),
  )
}

///|
test "constant-cylinder certificates bind even semantically equivalent source changes" {
  let levels = family_levels(3)
  let one = @oracle.nat(1)
  let prefix = @oracle.chain([
    @logic.Quantifier::Forall,
    @logic.Quantifier::Exists,
  ])
  let tree = Leaf(true)
  let value = match encode(one, prefix, levels, tree) {
    Ok(value) => value
    Err(_) => fail("constant cylinder")
  }
  let proof = certificate(value)
  assert_eq(formula(value), @qf.Truth(true))
  assert_true(check_result(one, prefix, levels, tree, value, proof))
  let changed_prefix = @oracle.chain([
    @logic.Quantifier::Exists,
    @logic.Quantifier::Forall,
  ])
  assert_true(check(one, changed_prefix, levels, tree, proof) is None)
  assert_true(
    check(
      @oracle.nat(2),
      @core.Cons(@logic.Quantifier::Exists, @core.Nil),
      levels,
      tree,
      proof,
    )
    is None,
  )
  assert_true(
    check(one, prefix, levels, finite_tree(0, 3, 0, 134217727), proof) is None,
  )
  let changed_levels = @oracle.chain([
    @core.Nil,
    @core.Cons(axis(2), @core.Nil),
    @core.Cons(axis(3), @core.Nil),
  ])
  assert_true(check(one, prefix, changed_levels, tree, proof) is None)
  assert_true(check(one, prefix, levels, Leaf(false), proof) is None)
  assert_true(
    check(one, prefix, levels, tree, { ..proof, formula: @qf.Truth(false), })
    is None,
  )
  let forged : Encoding = { proof: { ..proof, tree: Leaf(false), }, }
  assert_false(check_result(one, prefix, levels, tree, forged, proof))
}
