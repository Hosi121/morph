// Independent Fraction arithmetic and exact SymPy count_roots; no Float oracle.

///|
test "independent reducible rational component 0 expression 0" {
  review_rational_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(3, 1),
      @oracle.rational(-7, 2),
      @oracle.rational(-1, 2),
      @oracle.rational(1, 1),
    ],
    @sturm.Interval::{
      lower: @oracle.rational(-3, 1),
      upper: @oracle.rational(-2, 1),
    },
    [@oracle.rational(2, 1), @oracle.rational(-3, 1), @oracle.rational(1, 1)],
    [@oracle.rational(0, 1), @oracle.rational(1, 1)],
    @oracle.rational(-6, 1),
    @core.Less,
  )
}

///|
test "independent reducible rational component 0 expression 1" {
  review_rational_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(3, 1),
      @oracle.rational(-7, 2),
      @oracle.rational(-1, 2),
      @oracle.rational(1, 1),
    ],
    @sturm.Interval::{
      lower: @oracle.rational(-3, 1),
      upper: @oracle.rational(-2, 1),
    },
    [
      @oracle.rational(5, 3),
      @oracle.rational(-7, 2),
      @oracle.rational(2, 1),
      @oracle.rational(1, 5),
    ],
    [@oracle.rational(-1, 1), @oracle.rational(1, 1)],
    @oracle.rational(-226, 45),
    @core.Less,
  )
}

///|
test "independent reducible rational component 1 expression 0" {
  review_rational_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(3, 1),
      @oracle.rational(-7, 2),
      @oracle.rational(-1, 2),
      @oracle.rational(1, 1),
    ],
    @sturm.Interval::{
      lower: @oracle.rational(-1, 1),
      upper: @oracle.rational(0, 1),
    },
    [@oracle.rational(2, 1), @oracle.rational(-3, 1), @oracle.rational(1, 1)],
    [@oracle.rational(-1, 1), @oracle.rational(1, 1)],
    @oracle.rational(-2, 1),
    @core.Less,
  )
}

///|
test "independent reducible rational component 1 expression 1" {
  review_rational_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(3, 1),
      @oracle.rational(-7, 2),
      @oracle.rational(-1, 2),
      @oracle.rational(1, 1),
    ],
    @sturm.Interval::{
      lower: @oracle.rational(-1, 1),
      upper: @oracle.rational(0, 1),
    },
    [
      @oracle.rational(5, 3),
      @oracle.rational(-7, 2),
      @oracle.rational(2, 1),
      @oracle.rational(1, 5),
    ],
    [@oracle.rational(-3, 2), @oracle.rational(1, 1)],
    @oracle.rational(-10, 9),
    @core.Less,
  )
}

///|
test "independent reducible rational component 2 expression 0" {
  review_rational_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(3, 1),
      @oracle.rational(-7, 2),
      @oracle.rational(-1, 2),
      @oracle.rational(1, 1),
    ],
    @sturm.Interval::{
      lower: @oracle.rational(1, 2),
      upper: @oracle.rational(1, 1),
    },
    [@oracle.rational(2, 1), @oracle.rational(-3, 1), @oracle.rational(1, 1)],
    [@oracle.rational(-3, 2), @oracle.rational(1, 1)],
    @oracle.rational(0, 1),
    @core.Equal,
  )
}

///|
test "independent reducible rational component 2 expression 1" {
  review_rational_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(3, 1),
      @oracle.rational(-7, 2),
      @oracle.rational(-1, 2),
      @oracle.rational(1, 1),
    ],
    @sturm.Interval::{
      lower: @oracle.rational(1, 2),
      upper: @oracle.rational(1, 1),
    },
    [
      @oracle.rational(5, 3),
      @oracle.rational(-7, 2),
      @oracle.rational(2, 1),
      @oracle.rational(1, 5),
    ],
    [@oracle.rational(2, 1), @oracle.rational(1, 1)],
    @oracle.rational(11, 90),
    @core.Greater,
  )
}

///|
test "independent reducible rational component 3 expression 0" {
  review_rational_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(3, 1),
      @oracle.rational(-7, 2),
      @oracle.rational(-1, 2),
      @oracle.rational(1, 1),
    ],
    @sturm.Interval::{
      lower: @oracle.rational(5, 4),
      upper: @oracle.rational(3, 2),
    },
    [@oracle.rational(2, 1), @oracle.rational(-3, 1), @oracle.rational(1, 1)],
    [@oracle.rational(2, 1), @oracle.rational(1, 1)],
    @oracle.rational(-1, 14),
    @core.Less,
  )
}

///|
test "independent reducible rational component 3 expression 1" {
  review_rational_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(3, 1),
      @oracle.rational(-7, 2),
      @oracle.rational(-1, 2),
      @oracle.rational(1, 1),
    ],
    @sturm.Interval::{
      lower: @oracle.rational(5, 4),
      upper: @oracle.rational(3, 2),
    },
    [
      @oracle.rational(5, 3),
      @oracle.rational(-7, 2),
      @oracle.rational(2, 1),
      @oracle.rational(1, 5),
    ],
    [@oracle.rational(0, 1), @oracle.rational(1, 1)],
    @oracle.rational(191, 180),
    @core.Greater,
  )
}

///|
test "independent quadratic field embedding 1 expression 0" {
  review_quadratic_fixture(
    true,
    [@oracle.rational(-1, 1), @oracle.rational(0, 1), @oracle.rational(1, 1)],
    [@oracle.rational(1, 1), @oracle.rational(1, 1)],
    @oracle.rational(-1, 1),
    @oracle.rational(1, 1),
    @core.Greater,
  )
}

///|
test "independent quadratic field embedding 1 expression 1" {
  review_quadratic_fixture(
    true,
    [@oracle.rational(-2, 1), @oracle.rational(0, 1), @oracle.rational(1, 1)],
    [@oracle.rational(3, 1), @oracle.rational(-2, 1)],
    @oracle.rational(0, 1),
    @oracle.rational(0, 1),
    @core.Equal,
  )
}

///|
test "independent quadratic field embedding 1 expression 2" {
  review_quadratic_fixture(
    true,
    [
      @oracle.rational(0, 1),
      @oracle.rational(3, 1),
      @oracle.rational(1, 1),
      @oracle.rational(-1, 1),
    ],
    [@oracle.rational(2, 1), @oracle.rational(1, 1)],
    @oracle.rational(1, 1),
    @oracle.rational(0, 1),
    @core.Greater,
  )
}

///|
test "independent quadratic field embedding 1 expression 3" {
  review_quadratic_fixture(
    true,
    [
      @oracle.rational(5, 7),
      @oracle.rational(-2, 3),
      @oracle.rational(0, 1),
      @oracle.rational(1, 5),
      @oracle.rational(1, 11),
    ],
    [@oracle.rational(-3, 2), @oracle.rational(1, 4), @oracle.rational(2, 7)],
    @oracle.rational(-56116, 47685),
    @oracle.rational(-1414, 47685),
    @core.Less,
  )
}

///|
test "independent quadratic field embedding 1 expression 4" {
  review_quadratic_fixture(
    true,
    [
      @oracle.rational(-1, 1),
      @oracle.rational(4, 3),
      @oracle.rational(1, 1),
      @oracle.rational(2, 3),
    ],
    [@oracle.rational(2, 3), @oracle.rational(4, 1), @oracle.rational(-4, 3)],
    @oracle.rational(5, 6),
    @oracle.rational(1, 3),
    @core.Greater,
  )
}

///|
test "independent quadratic field embedding 1 expression 5" {
  review_quadratic_fixture(
    true,
    [
      @oracle.rational(-1, 1),
      @oracle.rational(3, 1),
      @oracle.rational(1, 1),
      @oracle.rational(-1, 1),
    ],
    [@oracle.rational(-1, 3), @oracle.rational(-4, 1), @oracle.rational(-2, 1)],
    @oracle.rational(-33, 119),
    @oracle.rational(3, 119),
    @core.Less,
  )
}

///|
test "independent quadratic field embedding 1 expression 6" {
  review_quadratic_fixture(
    true,
    [
      @oracle.rational(-1, 1),
      @oracle.rational(2, 5),
      @oracle.rational(2, 1),
      @oracle.rational(-3, 5),
    ],
    [@oracle.rational(0, 1), @oracle.rational(0, 1), @oracle.rational(-1, 1)],
    @oracle.rational(-3, 2),
    @oracle.rational(2, 5),
    @core.Less,
  )
}

///|
test "independent quadratic field embedding 1 expression 7" {
  review_quadratic_fixture(
    true,
    [
      @oracle.rational(-1, 5),
      @oracle.rational(3, 5),
      @oracle.rational(-1, 1),
      @oracle.rational(1, 1),
    ],
    [@oracle.rational(1, 3), @oracle.rational(0, 1), @oracle.rational(1, 1)],
    @oracle.rational(-33, 35),
    @oracle.rational(39, 35),
    @core.Greater,
  )
}

///|
test "independent quadratic field embedding -1 expression 0" {
  review_quadratic_fixture(
    false,
    [@oracle.rational(-1, 1), @oracle.rational(0, 1), @oracle.rational(1, 1)],
    [@oracle.rational(1, 1), @oracle.rational(1, 1)],
    @oracle.rational(-1, 1),
    @oracle.rational(1, 1),
    @core.Less,
  )
}

///|
test "independent quadratic field embedding -1 expression 1" {
  review_quadratic_fixture(
    false,
    [@oracle.rational(-2, 1), @oracle.rational(0, 1), @oracle.rational(1, 1)],
    [@oracle.rational(3, 1), @oracle.rational(-2, 1)],
    @oracle.rational(0, 1),
    @oracle.rational(0, 1),
    @core.Equal,
  )
}

///|
test "independent quadratic field embedding -1 expression 2" {
  review_quadratic_fixture(
    false,
    [
      @oracle.rational(0, 1),
      @oracle.rational(3, 1),
      @oracle.rational(1, 1),
      @oracle.rational(-1, 1),
    ],
    [@oracle.rational(2, 1), @oracle.rational(1, 1)],
    @oracle.rational(1, 1),
    @oracle.rational(0, 1),
    @core.Greater,
  )
}

///|
test "independent quadratic field embedding -1 expression 3" {
  review_quadratic_fixture(
    false,
    [
      @oracle.rational(5, 7),
      @oracle.rational(-2, 3),
      @oracle.rational(0, 1),
      @oracle.rational(1, 5),
      @oracle.rational(1, 11),
    ],
    [@oracle.rational(-3, 2), @oracle.rational(1, 4), @oracle.rational(2, 7)],
    @oracle.rational(-56116, 47685),
    @oracle.rational(-1414, 47685),
    @core.Less,
  )
}

///|
test "independent quadratic field embedding -1 expression 4" {
  review_quadratic_fixture(
    false,
    [
      @oracle.rational(-1, 1),
      @oracle.rational(4, 3),
      @oracle.rational(1, 1),
      @oracle.rational(2, 3),
    ],
    [@oracle.rational(2, 3), @oracle.rational(4, 1), @oracle.rational(-4, 3)],
    @oracle.rational(5, 6),
    @oracle.rational(1, 3),
    @core.Greater,
  )
}

///|
test "independent quadratic field embedding -1 expression 5" {
  review_quadratic_fixture(
    false,
    [
      @oracle.rational(-1, 1),
      @oracle.rational(3, 1),
      @oracle.rational(1, 1),
      @oracle.rational(-1, 1),
    ],
    [@oracle.rational(-1, 3), @oracle.rational(-4, 1), @oracle.rational(-2, 1)],
    @oracle.rational(-33, 119),
    @oracle.rational(3, 119),
    @core.Less,
  )
}

///|
test "independent quadratic field embedding -1 expression 6" {
  review_quadratic_fixture(
    false,
    [
      @oracle.rational(-1, 1),
      @oracle.rational(2, 5),
      @oracle.rational(2, 1),
      @oracle.rational(-3, 5),
    ],
    [@oracle.rational(0, 1), @oracle.rational(0, 1), @oracle.rational(-1, 1)],
    @oracle.rational(-3, 2),
    @oracle.rational(2, 5),
    @core.Less,
  )
}

///|
test "independent quadratic field embedding -1 expression 7" {
  review_quadratic_fixture(
    false,
    [
      @oracle.rational(-1, 5),
      @oracle.rational(3, 5),
      @oracle.rational(-1, 1),
      @oracle.rational(1, 1),
    ],
    [@oracle.rational(1, 3), @oracle.rational(0, 1), @oracle.rational(1, 1)],
    @oracle.rational(-33, 35),
    @oracle.rational(39, 35),
    @core.Less,
  )
}

///|
test "independent Tarski repeated endpoint query 0 span 0" {
  review_query_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(-1, 1),
      @oracle.rational(-1, 1),
      @oracle.rational(1, 1),
      @oracle.rational(1, 1),
    ],
    [@oracle.rational(0, 1), @oracle.rational(1, 1)],
    @sturm.Interval::{
      lower: @oracle.rational(-2, 1),
      upper: @oracle.rational(-1, 1),
    },
    -1,
  )
}

///|
test "independent Tarski repeated endpoint query 0 span 1" {
  review_query_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(-1, 1),
      @oracle.rational(-1, 1),
      @oracle.rational(1, 1),
      @oracle.rational(1, 1),
    ],
    [@oracle.rational(0, 1), @oracle.rational(1, 1)],
    @sturm.Interval::{
      lower: @oracle.rational(-1, 1),
      upper: @oracle.rational(0, 1),
    },
    0,
  )
}

///|
test "independent Tarski repeated endpoint query 0 span 2" {
  review_query_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(-1, 1),
      @oracle.rational(-1, 1),
      @oracle.rational(1, 1),
      @oracle.rational(1, 1),
    ],
    [@oracle.rational(0, 1), @oracle.rational(1, 1)],
    @sturm.Interval::{
      lower: @oracle.rational(0, 1),
      upper: @oracle.rational(1, 1),
    },
    1,
  )
}

///|
test "independent Tarski repeated endpoint query 0 span 3" {
  review_query_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(-1, 1),
      @oracle.rational(-1, 1),
      @oracle.rational(1, 1),
      @oracle.rational(1, 1),
    ],
    [@oracle.rational(0, 1), @oracle.rational(1, 1)],
    @sturm.Interval::{
      lower: @oracle.rational(1, 1),
      upper: @oracle.rational(2, 1),
    },
    0,
  )
}

///|
test "independent Tarski repeated endpoint query 0 span 4" {
  review_query_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(-1, 1),
      @oracle.rational(-1, 1),
      @oracle.rational(1, 1),
      @oracle.rational(1, 1),
    ],
    [@oracle.rational(0, 1), @oracle.rational(1, 1)],
    @sturm.Interval::{
      lower: @oracle.rational(-3, 1),
      upper: @oracle.rational(3, 1),
    },
    0,
  )
}

///|
test "independent Tarski repeated endpoint query 1 span 0" {
  review_query_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(4, 1),
      @oracle.rational(-12, 1),
      @oracle.rational(13, 1),
      @oracle.rational(-6, 1),
      @oracle.rational(1, 1),
    ],
    [@oracle.rational(1, 1), @oracle.rational(-2, 1), @oracle.rational(1, 1)],
    @sturm.Interval::{
      lower: @oracle.rational(-2, 1),
      upper: @oracle.rational(-1, 1),
    },
    0,
  )
}

///|
test "independent Tarski repeated endpoint query 1 span 1" {
  review_query_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(4, 1),
      @oracle.rational(-12, 1),
      @oracle.rational(13, 1),
      @oracle.rational(-6, 1),
      @oracle.rational(1, 1),
    ],
    [@oracle.rational(1, 1), @oracle.rational(-2, 1), @oracle.rational(1, 1)],
    @sturm.Interval::{
      lower: @oracle.rational(-1, 1),
      upper: @oracle.rational(0, 1),
    },
    1,
  )
}

///|
test "independent Tarski repeated endpoint query 1 span 2" {
  review_query_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(4, 1),
      @oracle.rational(-12, 1),
      @oracle.rational(13, 1),
      @oracle.rational(-6, 1),
      @oracle.rational(1, 1),
    ],
    [@oracle.rational(1, 1), @oracle.rational(-2, 1), @oracle.rational(1, 1)],
    @sturm.Interval::{
      lower: @oracle.rational(0, 1),
      upper: @oracle.rational(1, 1),
    },
    0,
  )
}

///|
test "independent Tarski repeated endpoint query 1 span 3" {
  review_query_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(4, 1),
      @oracle.rational(-12, 1),
      @oracle.rational(13, 1),
      @oracle.rational(-6, 1),
      @oracle.rational(1, 1),
    ],
    [@oracle.rational(1, 1), @oracle.rational(-2, 1), @oracle.rational(1, 1)],
    @sturm.Interval::{
      lower: @oracle.rational(1, 1),
      upper: @oracle.rational(2, 1),
    },
    1,
  )
}

///|
test "independent Tarski repeated endpoint query 1 span 4" {
  review_query_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(4, 1),
      @oracle.rational(-12, 1),
      @oracle.rational(13, 1),
      @oracle.rational(-6, 1),
      @oracle.rational(1, 1),
    ],
    [@oracle.rational(1, 1), @oracle.rational(-2, 1), @oracle.rational(1, 1)],
    @sturm.Interval::{
      lower: @oracle.rational(-3, 1),
      upper: @oracle.rational(3, 1),
    },
    2,
  )
}

///|
test "independent Tarski repeated endpoint query 2 span 0" {
  review_query_fixture(
    [
      @oracle.rational(4, 1),
      @oracle.rational(0, 1),
      @oracle.rational(-5, 1),
      @oracle.rational(0, 1),
      @oracle.rational(1, 1),
    ],
    [
      @oracle.rational(-2, 1),
      @oracle.rational(-1, 1),
      @oracle.rational(2, 1),
      @oracle.rational(1, 1),
    ],
    @sturm.Interval::{
      lower: @oracle.rational(-2, 1),
      upper: @oracle.rational(-1, 1),
    },
    0,
  )
}

///|
test "independent Tarski repeated endpoint query 2 span 1" {
  review_query_fixture(
    [
      @oracle.rational(4, 1),
      @oracle.rational(0, 1),
      @oracle.rational(-5, 1),
      @oracle.rational(0, 1),
      @oracle.rational(1, 1),
    ],
    [
      @oracle.rational(-2, 1),
      @oracle.rational(-1, 1),
      @oracle.rational(2, 1),
      @oracle.rational(1, 1),
    ],
    @sturm.Interval::{
      lower: @oracle.rational(-1, 1),
      upper: @oracle.rational(0, 1),
    },
    0,
  )
}

///|
test "independent Tarski repeated endpoint query 2 span 2" {
  review_query_fixture(
    [
      @oracle.rational(4, 1),
      @oracle.rational(0, 1),
      @oracle.rational(-5, 1),
      @oracle.rational(0, 1),
      @oracle.rational(1, 1),
    ],
    [
      @oracle.rational(-2, 1),
      @oracle.rational(-1, 1),
      @oracle.rational(2, 1),
      @oracle.rational(1, 1),
    ],
    @sturm.Interval::{
      lower: @oracle.rational(0, 1),
      upper: @oracle.rational(1, 1),
    },
    0,
  )
}

///|
test "independent Tarski repeated endpoint query 2 span 3" {
  review_query_fixture(
    [
      @oracle.rational(4, 1),
      @oracle.rational(0, 1),
      @oracle.rational(-5, 1),
      @oracle.rational(0, 1),
      @oracle.rational(1, 1),
    ],
    [
      @oracle.rational(-2, 1),
      @oracle.rational(-1, 1),
      @oracle.rational(2, 1),
      @oracle.rational(1, 1),
    ],
    @sturm.Interval::{
      lower: @oracle.rational(1, 1),
      upper: @oracle.rational(2, 1),
    },
    1,
  )
}

///|
test "independent Tarski repeated endpoint query 2 span 4" {
  review_query_fixture(
    [
      @oracle.rational(4, 1),
      @oracle.rational(0, 1),
      @oracle.rational(-5, 1),
      @oracle.rational(0, 1),
      @oracle.rational(1, 1),
    ],
    [
      @oracle.rational(-2, 1),
      @oracle.rational(-1, 1),
      @oracle.rational(2, 1),
      @oracle.rational(1, 1),
    ],
    @sturm.Interval::{
      lower: @oracle.rational(-3, 1),
      upper: @oracle.rational(3, 1),
    },
    1,
  )
}

///|
test "independent Tarski repeated endpoint query 3 span 0" {
  review_query_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(1, 1),
      @oracle.rational(-2, 1),
      @oracle.rational(1, 1),
    ],
    [
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(1, 1),
      @oracle.rational(-1, 1),
    ],
    @sturm.Interval::{
      lower: @oracle.rational(-2, 1),
      upper: @oracle.rational(-1, 1),
    },
    0,
  )
}

///|
test "independent Tarski repeated endpoint query 3 span 1" {
  review_query_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(1, 1),
      @oracle.rational(-2, 1),
      @oracle.rational(1, 1),
    ],
    [
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(1, 1),
      @oracle.rational(-1, 1),
    ],
    @sturm.Interval::{
      lower: @oracle.rational(-1, 1),
      upper: @oracle.rational(0, 1),
    },
    0,
  )
}

///|
test "independent Tarski repeated endpoint query 3 span 2" {
  review_query_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(1, 1),
      @oracle.rational(-2, 1),
      @oracle.rational(1, 1),
    ],
    [
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(1, 1),
      @oracle.rational(-1, 1),
    ],
    @sturm.Interval::{
      lower: @oracle.rational(0, 1),
      upper: @oracle.rational(1, 1),
    },
    0,
  )
}

///|
test "independent Tarski repeated endpoint query 3 span 3" {
  review_query_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(1, 1),
      @oracle.rational(-2, 1),
      @oracle.rational(1, 1),
    ],
    [
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(1, 1),
      @oracle.rational(-1, 1),
    ],
    @sturm.Interval::{
      lower: @oracle.rational(1, 1),
      upper: @oracle.rational(2, 1),
    },
    0,
  )
}

///|
test "independent Tarski repeated endpoint query 3 span 4" {
  review_query_fixture(
    [
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(1, 1),
      @oracle.rational(-2, 1),
      @oracle.rational(1, 1),
    ],
    [
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(1, 1),
      @oracle.rational(-1, 1),
    ],
    @sturm.Interval::{
      lower: @oracle.rational(-3, 1),
      upper: @oracle.rational(3, 1),
    },
    0,
  )
}

///|
test "independent exact irrational relative degree 3 source 0" {
  review_relative_count_fixture(
    1,
    true,
    [
      [@oracle.rational(0, 1), @oracle.rational(2, 1)],
      [@oracle.rational(-2, 1), @oracle.rational(1, 1)],
      [@oracle.rational(-1, 1), @oracle.rational(-1, 1)],
      [@oracle.rational(1, 1)],
    ],
    [
      (
        @sturm.Interval::{
          lower: @oracle.rational(-3, 1),
          upper: @oracle.rational(-1, 1),
        },
        1,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(-1, 1),
          upper: @oracle.rational(0, 1),
        },
        0,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(0, 1),
          upper: @oracle.rational(1, 1),
        },
        0,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(1, 1),
          upper: @oracle.rational(2, 1),
        },
        2,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(-3, 1),
          upper: @oracle.rational(3, 1),
        },
        3,
      ),
    ],
  )
}

///|
test "independent exact irrational relative degree 3 source 1" {
  review_relative_count_fixture(
    1,
    false,
    [
      [@oracle.rational(0, 1), @oracle.rational(2, 1)],
      [@oracle.rational(-2, 1), @oracle.rational(1, 1)],
      [@oracle.rational(-1, 1), @oracle.rational(-1, 1)],
      [@oracle.rational(1, 1)],
    ],
    [
      (
        @sturm.Interval::{
          lower: @oracle.rational(-3, 1),
          upper: @oracle.rational(-1, 1),
        },
        2,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(-1, 1),
          upper: @oracle.rational(0, 1),
        },
        0,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(0, 1),
          upper: @oracle.rational(1, 1),
        },
        0,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(1, 1),
          upper: @oracle.rational(2, 1),
        },
        1,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(-3, 1),
          upper: @oracle.rational(3, 1),
        },
        3,
      ),
    ],
  )
}

///|
test "independent exact irrational relative degree 3 source 2" {
  review_relative_count_fixture(
    1,
    true,
    [
      [@oracle.rational(-2, 1)],
      [@oracle.rational(0, 1), @oracle.rational(1, 1)],
      [@oracle.rational(0, 1), @oracle.rational(-1, 1)],
      [@oracle.rational(1, 1)],
    ],
    [
      (
        @sturm.Interval::{
          lower: @oracle.rational(-3, 1),
          upper: @oracle.rational(-1, 1),
        },
        0,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(-1, 1),
          upper: @oracle.rational(0, 1),
        },
        0,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(0, 1),
          upper: @oracle.rational(1, 1),
        },
        0,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(1, 1),
          upper: @oracle.rational(2, 1),
        },
        1,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(-3, 1),
          upper: @oracle.rational(3, 1),
        },
        1,
      ),
    ],
  )
}

///|
test "independent exact irrational relative degree 3 source 3" {
  review_relative_count_fixture(
    1,
    false,
    [
      [@oracle.rational(-2, 1)],
      [@oracle.rational(0, 1), @oracle.rational(1, 1)],
      [@oracle.rational(0, 1), @oracle.rational(-1, 1)],
      [@oracle.rational(1, 1)],
    ],
    [
      (
        @sturm.Interval::{
          lower: @oracle.rational(-3, 1),
          upper: @oracle.rational(-1, 1),
        },
        2,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(-1, 1),
          upper: @oracle.rational(0, 1),
        },
        0,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(0, 1),
          upper: @oracle.rational(1, 1),
        },
        0,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(1, 1),
          upper: @oracle.rational(2, 1),
        },
        1,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(-3, 1),
          upper: @oracle.rational(3, 1),
        },
        3,
      ),
    ],
  )
}

///|
test "independent exact irrational relative degree 4 source 4" {
  review_relative_count_fixture(
    1,
    true,
    [
      [@oracle.rational(-2, 1), @oracle.rational(1, 1)],
      [@oracle.rational(0, 1)],
      [@oracle.rational(-1, 1)],
      [@oracle.rational(0, 1)],
      [@oracle.rational(1, 1)],
    ],
    [
      (
        @sturm.Interval::{
          lower: @oracle.rational(-3, 1),
          upper: @oracle.rational(-1, 1),
        },
        1,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(-1, 1),
          upper: @oracle.rational(0, 1),
        },
        0,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(0, 1),
          upper: @oracle.rational(1, 1),
        },
        0,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(1, 1),
          upper: @oracle.rational(2, 1),
        },
        1,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(-3, 1),
          upper: @oracle.rational(3, 1),
        },
        2,
      ),
    ],
  )
}

///|
test "independent exact irrational relative degree 4 source 5" {
  review_relative_count_fixture(
    1,
    false,
    [
      [@oracle.rational(-2, 1), @oracle.rational(1, 1)],
      [@oracle.rational(0, 1)],
      [@oracle.rational(-1, 1)],
      [@oracle.rational(0, 1)],
      [@oracle.rational(1, 1)],
    ],
    [
      (
        @sturm.Interval::{
          lower: @oracle.rational(-3, 1),
          upper: @oracle.rational(-1, 1),
        },
        1,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(-1, 1),
          upper: @oracle.rational(0, 1),
        },
        0,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(0, 1),
          upper: @oracle.rational(1, 1),
        },
        0,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(1, 1),
          upper: @oracle.rational(2, 1),
        },
        1,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(-3, 1),
          upper: @oracle.rational(3, 1),
        },
        2,
      ),
    ],
  )
}

///|
test "independent exact irrational relative degree 3 source 6" {
  review_relative_count_fixture(
    2,
    true,
    [
      [@oracle.rational(0, 1), @oracle.rational(1, 1)],
      [@oracle.rational(0, 1), @oracle.rational(-1, 1)],
      [@oracle.rational(-1, 1)],
      [@oracle.rational(1, 1)],
    ],
    [
      (
        @sturm.Interval::{
          lower: @oracle.rational(-3, 1),
          upper: @oracle.rational(-1, 1),
        },
        1,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(-1, 1),
          upper: @oracle.rational(0, 1),
        },
        0,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(0, 1),
          upper: @oracle.rational(1, 1),
        },
        1,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(1, 1),
          upper: @oracle.rational(2, 1),
        },
        1,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(-3, 1),
          upper: @oracle.rational(3, 1),
        },
        3,
      ),
    ],
  )
}

///|
test "independent exact irrational relative degree 4 source 7" {
  review_relative_count_fixture(
    2,
    true,
    [
      [
        @oracle.rational(0, 1),
        @oracle.rational(0, 1),
        @oracle.rational(0, 1),
        @oracle.rational(-1, 1),
      ],
      [@oracle.rational(0, 1)],
      [@oracle.rational(0, 1), @oracle.rational(-1, 1), @oracle.rational(1, 1)],
      [@oracle.rational(0, 1)],
      [@oracle.rational(1, 1)],
    ],
    [
      (
        @sturm.Interval::{
          lower: @oracle.rational(-3, 1),
          upper: @oracle.rational(-1, 1),
        },
        1,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(-1, 1),
          upper: @oracle.rational(0, 1),
        },
        0,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(0, 1),
          upper: @oracle.rational(1, 1),
        },
        0,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(1, 1),
          upper: @oracle.rational(2, 1),
        },
        1,
      ),
      (
        @sturm.Interval::{
          lower: @oracle.rational(-3, 1),
          upper: @oracle.rational(3, 1),
        },
        2,
      ),
    ],
  )
}
