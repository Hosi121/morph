// Independent scoped first-order closed-form oracle; exact rational output evaluation.

///|
test "independent FO closed form 0 inverse_universal" {
  review_fo_fixture(
    1,
    @logic.Formula::Exists(
      @logic.Formula::Forall(
        @logic.Atom(
          review_poly(3, [(1, 1, [1, 1, 1]), (-1, 1, [0, 0, 1])]),
          @qf.EqualZero,
        ),
      ),
    ),
    [
      ([(-3, 1)], true),
      ([(-2, 1)], true),
      ([(-1, 1)], true),
      ([(0, 1)], false),
      ([(1, 1)], true),
      ([(2, 1)], true),
      ([(3, 1)], true),
      ([(1, 4)], true),
      ([(-1, 4)], true),
      ([(1, 2)], true),
      ([(3, 2)], true),
      ([(-3, 2)], true),
    ],
  )
}

///|
test "independent FO closed form 1 negated_square" {
  review_fo_fixture(
    1,
    @logic.Negation(
      @logic.Formula::Exists(
        @logic.Atom(
          review_poly(2, [(-1, 1, [1, 0]), (1, 1, [0, 2])]),
          @qf.EqualZero,
        ),
      ),
    ),
    [
      ([(-3, 1)], true),
      ([(-2, 1)], true),
      ([(-1, 1)], true),
      ([(0, 1)], false),
      ([(1, 1)], false),
      ([(2, 1)], false),
      ([(3, 1)], false),
      ([(1, 4)], false),
      ([(-1, 4)], true),
      ([(1, 2)], false),
      ([(3, 2)], false),
      ([(-3, 2)], true),
    ],
  )
}

///|
test "independent FO closed form 2 nonlinear_sibling_scopes" {
  review_fo_fixture(
    1,
    @logic.Conjunction(
      @logic.Formula::Exists(
        @logic.Atom(
          review_poly(2, [(-1, 1, [1, 0]), (1, 1, [0, 2])]),
          @qf.EqualZero,
        ),
      ),
      @logic.Negation(
        @logic.Formula::Exists(
          @logic.Atom(
            review_poly(2, [(1, 1, [1, 0]), (1, 1, [0, 2])]),
            @qf.EqualZero,
          ),
        ),
      ),
    ),
    [
      ([(-3, 1)], false),
      ([(-2, 1)], false),
      ([(-1, 1)], false),
      ([(0, 1)], false),
      ([(1, 1)], true),
      ([(2, 1)], true),
      ([(3, 1)], true),
      ([(1, 4)], true),
      ([(-1, 4)], false),
      ([(1, 2)], true),
      ([(3, 2)], true),
      ([(-3, 2)], false),
    ],
  )
}

///|
test "independent FO closed form 3 inverse_implication" {
  review_fo_fixture(
    0,
    @logic.Formula::Forall(
      @logic.Disjunction(
        @logic.Atom(review_poly(1, [(1, 1, [1])]), @qf.EqualZero),
        @logic.Formula::Exists(
          @logic.Atom(
            review_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 0])]),
            @qf.EqualZero,
          ),
        ),
      ),
    ),
    [([], true)],
  )
}

///|
test "independent FO closed form 4 constant_forall_impossible" {
  review_fo_fixture(
    0,
    @logic.Formula::Exists(
      @logic.Formula::Forall(
        @logic.Atom(
          review_poly(2, [(1, 1, [1, 2]), (1, 1, [1, 0]), (-1, 1, [0, 0])]),
          @qf.EqualZero,
        ),
      ),
    ),
    [([], false)],
  )
}

///|
test "independent FO closed form 5 negated_universal_inverse" {
  review_fo_fixture(
    0,
    @logic.Negation(
      @logic.Formula::Forall(
        @logic.Formula::Exists(
          @logic.Atom(
            review_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 0])]),
            @qf.EqualZero,
          ),
        ),
      ),
    ),
    [([], true)],
  )
}
