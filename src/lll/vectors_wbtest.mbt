// Generated independently using SymPy 1.14.0, exact QQ delta=3/4.

///|
test "exact LLL checker and Gram Schmidt agree with independent SymPy properties" {
  check_sympy(
    3,
    [[1, 1, 1], [-1, 0, 2], [3, 5, 6]],
    [[-4, -1, 1], [5, 1, -1], [0, 1, 0]],
    [[0, 1, 0], [1, 0, 1], [-1, 0, 2]],
    {
      orthogonal: Cons(
        Cons(
          @oracle.rational(0, 1),
          Cons(@oracle.rational(1, 1), Cons(@oracle.rational(0, 1), Nil)),
        ),
        Cons(
          Cons(
            @oracle.rational(1, 1),
            Cons(@oracle.rational(0, 1), Cons(@oracle.rational(1, 1), Nil)),
          ),
          Cons(
            Cons(
              @oracle.rational(-3, 2),
              Cons(@oracle.rational(0, 1), Cons(@oracle.rational(3, 2), Nil)),
            ),
            Nil,
          ),
        ),
      ),
      coefficients: Cons(
        Nil,
        Cons(
          Cons(@oracle.rational(0, 1), Nil),
          Cons(
            Cons(@oracle.rational(0, 1), Cons(@oracle.rational(1, 2), Nil)),
            Nil,
          ),
        ),
      ),
      norms: Cons(
        @oracle.rational(1, 1),
        Cons(@oracle.rational(2, 1), Cons(@oracle.rational(9, 2), Nil)),
      ),
    },
  )
  check_sympy(2, [[2, 0], [3, 2]], [[1, 0], [-2, 1]], [[2, 0], [-1, 2]], {
    orthogonal: Cons(
      Cons(@oracle.rational(2, 1), Cons(@oracle.rational(0, 1), Nil)),
      Cons(Cons(@oracle.rational(0, 1), Cons(@oracle.rational(2, 1), Nil)), Nil),
    ),
    coefficients: Cons(Nil, Cons(Cons(@oracle.rational(-1, 2), Nil), Nil)),
    norms: Cons(@oracle.rational(4, 1), Cons(@oracle.rational(4, 1), Nil)),
  })
  check_sympy(2, [[2, 0], [-3, 2]], [[1, 0], [1, 1]], [[2, 0], [-1, 2]], {
    orthogonal: Cons(
      Cons(@oracle.rational(2, 1), Cons(@oracle.rational(0, 1), Nil)),
      Cons(Cons(@oracle.rational(0, 1), Cons(@oracle.rational(2, 1), Nil)), Nil),
    ),
    coefficients: Cons(Nil, Cons(Cons(@oracle.rational(-1, 2), Nil), Nil)),
    norms: Cons(@oracle.rational(4, 1), Cons(@oracle.rational(4, 1), Nil)),
  })
  check_sympy(
    3,
    [[2, 0, 0], [1, 1, 1]],
    [[1, 0], [0, 1]],
    [[2, 0, 0], [1, 1, 1]],
    {
      orthogonal: Cons(
        Cons(
          @oracle.rational(2, 1),
          Cons(@oracle.rational(0, 1), Cons(@oracle.rational(0, 1), Nil)),
        ),
        Cons(
          Cons(
            @oracle.rational(0, 1),
            Cons(@oracle.rational(1, 1), Cons(@oracle.rational(1, 1), Nil)),
          ),
          Nil,
        ),
      ),
      coefficients: Cons(Nil, Cons(Cons(@oracle.rational(1, 2), Nil), Nil)),
      norms: Cons(@oracle.rational(4, 1), Cons(@oracle.rational(2, 1), Nil)),
    },
  )
  check_sympy(2, [[1, -8]], [[1]], [[1, -8]], {
    orthogonal: Cons(
      Cons(@oracle.rational(1, 1), Cons(@oracle.rational(-8, 1), Nil)),
      Nil,
    ),
    coefficients: Cons(Nil, Nil),
    norms: Cons(@oracle.rational(65, 1), Nil),
  })
  check_sympy(2, [[7, -3]], [[1]], [[7, -3]], {
    orthogonal: Cons(
      Cons(@oracle.rational(7, 1), Cons(@oracle.rational(-3, 1), Nil)),
      Nil,
    ),
    coefficients: Cons(Nil, Nil),
    norms: Cons(@oracle.rational(58, 1), Nil),
  })
  check_sympy(2, [[3, -3]], [[1]], [[3, -3]], {
    orthogonal: Cons(
      Cons(@oracle.rational(3, 1), Cons(@oracle.rational(-3, 1), Nil)),
      Nil,
    ),
    coefficients: Cons(Nil, Nil),
    norms: Cons(@oracle.rational(18, 1), Nil),
  })
  check_sympy(2, [[6, -2]], [[1]], [[6, -2]], {
    orthogonal: Cons(
      Cons(@oracle.rational(6, 1), Cons(@oracle.rational(-2, 1), Nil)),
      Nil,
    ),
    coefficients: Cons(Nil, Nil),
    norms: Cons(@oracle.rational(40, 1), Nil),
  })
  check_sympy(2, [[-5, -7], [-1, 8]], [[1, 1], [0, -1]], [[-6, 1], [1, -8]], {
    orthogonal: Cons(
      Cons(@oracle.rational(-6, 1), Cons(@oracle.rational(1, 1), Nil)),
      Cons(
        Cons(@oracle.rational(-47, 37), Cons(@oracle.rational(-282, 37), Nil)),
        Nil,
      ),
    ),
    coefficients: Cons(Nil, Cons(Cons(@oracle.rational(-14, 37), Nil), Nil)),
    norms: Cons(@oracle.rational(37, 1), Cons(@oracle.rational(2209, 37), Nil)),
  })
  check_sympy(2, [[-3, -4], [-6, 7]], [[1, 0], [0, 1]], [[-3, -4], [-6, 7]], {
    orthogonal: Cons(
      Cons(@oracle.rational(-3, 1), Cons(@oracle.rational(-4, 1), Nil)),
      Cons(
        Cons(@oracle.rational(-36, 5), Cons(@oracle.rational(27, 5), Nil)),
        Nil,
      ),
    ),
    coefficients: Cons(Nil, Cons(Cons(@oracle.rational(-2, 5), Nil), Nil)),
    norms: Cons(@oracle.rational(25, 1), Cons(@oracle.rational(81, 1), Nil)),
  })
  check_sympy(2, [[-3, 8], [2, 2]], [[0, 1], [1, -1]], [[2, 2], [-5, 6]], {
    orthogonal: Cons(
      Cons(@oracle.rational(2, 1), Cons(@oracle.rational(2, 1), Nil)),
      Cons(
        Cons(@oracle.rational(-11, 2), Cons(@oracle.rational(11, 2), Nil)),
        Nil,
      ),
    ),
    coefficients: Cons(Nil, Cons(Cons(@oracle.rational(1, 4), Nil), Nil)),
    norms: Cons(@oracle.rational(8, 1), Cons(@oracle.rational(121, 2), Nil)),
  })
  check_sympy(2, [[-4, 3], [6, 3]], [[1, 0], [1, 1]], [[-4, 3], [2, 6]], {
    orthogonal: Cons(
      Cons(@oracle.rational(-4, 1), Cons(@oracle.rational(3, 1), Nil)),
      Cons(
        Cons(@oracle.rational(18, 5), Cons(@oracle.rational(24, 5), Nil)),
        Nil,
      ),
    ),
    coefficients: Cons(Nil, Cons(Cons(@oracle.rational(2, 5), Nil), Nil)),
    norms: Cons(@oracle.rational(25, 1), Cons(@oracle.rational(36, 1), Nil)),
  })
  check_sympy(
    3,
    [[-3, -7, 5], [-8, 3, 1]],
    [[1, 0], [0, 1]],
    [[-3, -7, 5], [-8, 3, 1]],
    {
      orthogonal: Cons(
        Cons(
          @oracle.rational(-3, 1),
          Cons(@oracle.rational(-7, 1), Cons(@oracle.rational(5, 1), Nil)),
        ),
        Cons(
          Cons(
            @oracle.rational(-640, 83),
            Cons(@oracle.rational(305, 83), Cons(@oracle.rational(43, 83), Nil)),
          ),
          Nil,
        ),
      ),
      coefficients: Cons(Nil, Cons(Cons(@oracle.rational(8, 83), Nil), Nil)),
      norms: Cons(
        @oracle.rational(83, 1),
        Cons(@oracle.rational(6078, 83), Nil),
      ),
    },
  )
  check_sympy(
    3,
    [[2, 3, 4], [2, -6, -2]],
    [[1, 0], [1, 1]],
    [[2, 3, 4], [4, -3, 2]],
    {
      orthogonal: Cons(
        Cons(
          @oracle.rational(2, 1),
          Cons(@oracle.rational(3, 1), Cons(@oracle.rational(4, 1), Nil)),
        ),
        Cons(
          Cons(
            @oracle.rational(102, 29),
            Cons(
              @oracle.rational(-108, 29),
              Cons(@oracle.rational(30, 29), Nil),
            ),
          ),
          Nil,
        ),
      ),
      coefficients: Cons(Nil, Cons(Cons(@oracle.rational(7, 29), Nil), Nil)),
      norms: Cons(@oracle.rational(29, 1), Cons(@oracle.rational(792, 29), Nil)),
    },
  )
  check_sympy(
    3,
    [[-5, -7, 5], [-5, 6, 6]],
    [[1, 0], [0, 1]],
    [[-5, -7, 5], [-5, 6, 6]],
    {
      orthogonal: Cons(
        Cons(
          @oracle.rational(-5, 1),
          Cons(@oracle.rational(-7, 1), Cons(@oracle.rational(5, 1), Nil)),
        ),
        Cons(
          Cons(
            @oracle.rational(-430, 99),
            Cons(
              @oracle.rational(685, 99),
              Cons(@oracle.rational(529, 99), Nil),
            ),
          ),
          Nil,
        ),
      ),
      coefficients: Cons(Nil, Cons(Cons(@oracle.rational(13, 99), Nil), Nil)),
      norms: Cons(
        @oracle.rational(99, 1),
        Cons(@oracle.rational(9434, 99), Nil),
      ),
    },
  )
  check_sympy(
    3,
    [[3, -5, -1], [-5, -5, 1]],
    [[1, 0], [0, 1]],
    [[3, -5, -1], [-5, -5, 1]],
    {
      orthogonal: Cons(
        Cons(
          @oracle.rational(3, 1),
          Cons(@oracle.rational(-5, 1), Cons(@oracle.rational(-1, 1), Nil)),
        ),
        Cons(
          Cons(
            @oracle.rational(-202, 35),
            Cons(@oracle.rational(-26, 7), Cons(@oracle.rational(44, 35), Nil)),
          ),
          Nil,
        ),
      ),
      coefficients: Cons(Nil, Cons(Cons(@oracle.rational(9, 35), Nil), Nil)),
      norms: Cons(
        @oracle.rational(35, 1),
        Cons(@oracle.rational(1704, 35), Nil),
      ),
    },
  )
  check_sympy(
    3,
    [[0, 3, -8], [-8, 0, -4], [1, 1, -4]],
    [[1, 0, -2], [0, 0, 1], [-3, 1, 5]],
    [[-2, 1, 0], [1, 1, -4], [-3, -4, 0]],
    {
      orthogonal: Cons(
        Cons(
          @oracle.rational(-2, 1),
          Cons(@oracle.rational(1, 1), Cons(@oracle.rational(0, 1), Nil)),
        ),
        Cons(
          Cons(
            @oracle.rational(3, 5),
            Cons(@oracle.rational(6, 5), Cons(@oracle.rational(-4, 1), Nil)),
          ),
          Cons(
            Cons(
              @oracle.rational(-176, 89),
              Cons(
                @oracle.rational(-352, 89),
                Cons(@oracle.rational(-132, 89), Nil),
              ),
            ),
            Nil,
          ),
        ),
      ),
      coefficients: Cons(
        Nil,
        Cons(
          Cons(@oracle.rational(-1, 5), Nil),
          Cons(
            Cons(@oracle.rational(2, 5), Cons(@oracle.rational(-33, 89), Nil)),
            Nil,
          ),
        ),
      ),
      norms: Cons(
        @oracle.rational(5, 1),
        Cons(@oracle.rational(89, 5), Cons(@oracle.rational(1936, 89), Nil)),
      ),
    },
  )
  check_sympy(
    3,
    [[-4, 2, -4], [-3, 2, 8], [3, -5, 8]],
    [[1, 0, 1], [2, 0, 1], [-1, 1, -1]],
    [[-1, -3, 4], [-5, -1, 0], [-2, 5, 4]],
    {
      orthogonal: Cons(
        Cons(
          @oracle.rational(-1, 1),
          Cons(@oracle.rational(-3, 1), Cons(@oracle.rational(4, 1), Nil)),
        ),
        Cons(
          Cons(
            @oracle.rational(-61, 13),
            Cons(@oracle.rational(-1, 13), Cons(@oracle.rational(-16, 13), Nil)),
          ),
          Cons(
            Cons(
              @oracle.rational(-164, 153),
              Cons(
                @oracle.rational(820, 153),
                Cons(@oracle.rational(574, 153), Nil),
              ),
            ),
            Nil,
          ),
        ),
      ),
      coefficients: Cons(
        Nil,
        Cons(
          Cons(@oracle.rational(4, 13), Nil),
          Cons(
            Cons(@oracle.rational(3, 26), Cons(@oracle.rational(53, 306), Nil)),
            Nil,
          ),
        ),
      ),
      norms: Cons(
        @oracle.rational(26, 1),
        Cons(@oracle.rational(306, 13), Cons(@oracle.rational(6724, 153), Nil)),
      ),
    },
  )
  check_sympy(
    3,
    [[6, 3, 1], [-5, 4, -5], [-7, 5, 6]],
    [[1, 0, 0], [0, 1, 0], [0, 0, 1]],
    [[6, 3, 1], [-5, 4, -5], [-7, 5, 6]],
    {
      orthogonal: Cons(
        Cons(
          @oracle.rational(6, 1),
          Cons(@oracle.rational(3, 1), Cons(@oracle.rational(1, 1), Nil)),
        ),
        Cons(
          Cons(
            @oracle.rational(-2, 1),
            Cons(@oracle.rational(11, 2), Cons(@oracle.rational(-9, 2), Nil)),
          ),
          Cons(
            Cons(
              @oracle.rational(-9348, 2507),
              Cons(
                @oracle.rational(12300, 2507),
                Cons(@oracle.rational(19188, 2507), Nil),
              ),
            ),
            Nil,
          ),
        ),
      ),
      coefficients: Cons(
        Nil,
        Cons(
          Cons(@oracle.rational(-1, 2), Nil),
          Cons(
            Cons(
              @oracle.rational(-21, 46),
              Cons(@oracle.rational(29, 109), Nil),
            ),
            Nil,
          ),
        ),
      ),
      norms: Cons(
        @oracle.rational(46, 1),
        Cons(
          @oracle.rational(109, 2),
          Cons(@oracle.rational(242064, 2507), Nil),
        ),
      ),
    },
  )
  check_sympy(
    3,
    [[-3, -4, -2], [-2, 0, 5], [-8, 5, -5]],
    [[1, 0, 0], [0, 1, 0], [0, 0, 1]],
    [[-3, -4, -2], [-2, 0, 5], [-8, 5, -5]],
    {
      orthogonal: Cons(
        Cons(
          @oracle.rational(-3, 1),
          Cons(@oracle.rational(-4, 1), Cons(@oracle.rational(-2, 1), Nil)),
        ),
        Cons(
          Cons(
            @oracle.rational(-70, 29),
            Cons(
              @oracle.rational(-16, 29),
              Cons(@oracle.rational(137, 29), Nil),
            ),
          ),
          Cons(
            Cons(
              @oracle.rational(-236, 33),
              Cons(
                @oracle.rational(1121, 165),
                Cons(@oracle.rational(-472, 165), Nil),
              ),
            ),
            Nil,
          ),
        ),
      ),
      coefficients: Cons(
        Nil,
        Cons(
          Cons(@oracle.rational(-4, 29), Nil),
          Cons(
            Cons(
              @oracle.rational(14, 29),
              Cons(@oracle.rational(-41, 165), Nil),
            ),
            Nil,
          ),
        ),
      ),
      norms: Cons(
        @oracle.rational(29, 1),
        Cons(@oracle.rational(825, 29), Cons(@oracle.rational(3481, 33), Nil)),
      ),
    },
  )
  check_sympy(
    4,
    [[0, -2, 4, -8], [-5, -6, -2, -1], [-8, 0, -4, 5]],
    [[1, -1, 1], [1, 0, 0], [0, 1, 0]],
    [[-3, 4, 2, -2], [0, -2, 4, -8], [-5, -6, -2, -1]],
    {
      orthogonal: Cons(
        Cons(
          @oracle.rational(-3, 1),
          Cons(
            @oracle.rational(4, 1),
            Cons(@oracle.rational(2, 1), Cons(@oracle.rational(-2, 1), Nil)),
          ),
        ),
        Cons(
          Cons(
            @oracle.rational(16, 11),
            Cons(
              @oracle.rational(-130, 33),
              Cons(
                @oracle.rational(100, 33),
                Cons(@oracle.rational(-232, 33), Nil),
              ),
            ),
          ),
          Cons(
            Cons(
              @oracle.rational(-3982, 629),
              Cons(
                @oracle.rational(-2372, 629),
                Cons(
                  @oracle.rational(-1272, 629),
                  Cons(@oracle.rational(-43, 629), Nil),
                ),
              ),
            ),
            Nil,
          ),
        ),
      ),
      coefficients: Cons(
        Nil,
        Cons(
          Cons(@oracle.rational(16, 33), Nil),
          Cons(
            Cons(@oracle.rational(-1, 3), Cons(@oracle.rational(143, 629), Nil)),
            Nil,
          ),
        ),
      ),
      norms: Cons(
        @oracle.rational(33, 1),
        Cons(
          @oracle.rational(2516, 33),
          Cons(@oracle.rational(36729, 629), Nil),
        ),
      ),
    },
  )
  check_sympy(
    4,
    [[6, 3, 5, -5], [-3, 4, 7, -8], [2, -1, -5, -8]],
    [[1, 0, 0], [-1, 1, 0], [0, 0, 1]],
    [[6, 3, 5, -5], [-9, 1, 2, -3], [2, -1, -5, -8]],
    {
      orthogonal: Cons(
        Cons(
          @oracle.rational(6, 1),
          Cons(
            @oracle.rational(3, 1),
            Cons(@oracle.rational(5, 1), Cons(@oracle.rational(-5, 1), Nil)),
          ),
        ),
        Cons(
          Cons(
            @oracle.rational(-699, 95),
            Cons(
              @oracle.rational(173, 95),
              Cons(
                @oracle.rational(64, 19),
                Cons(@oracle.rational(-83, 19), Nil),
              ),
            ),
          ),
          Cons(
            Cons(
              @oracle.rational(1713, 2783),
              Cons(
                @oracle.rational(-14948, 8349),
                Cons(
                  @oracle.rational(-52793, 8349),
                  Cons(@oracle.rational(-55595, 8349), Nil),
                ),
              ),
            ),
            Nil,
          ),
        ),
      ),
      coefficients: Cons(
        Nil,
        Cons(
          Cons(@oracle.rational(-26, 95), Nil),
          Cons(
            Cons(
              @oracle.rational(24, 95),
              Cons(@oracle.rational(149, 8349), Nil),
            ),
            Nil,
          ),
        ),
      ),
      norms: Cons(
        @oracle.rational(95, 1),
        Cons(
          @oracle.rational(8349, 95),
          Cons(@oracle.rational(733951, 8349), Nil),
        ),
      ),
    },
  )
  check_sympy(
    4,
    [[8, -5, 7, 3], [-1, 3, 7, -8], [-1, 5, 0, -8]],
    [[0, -1, 1], [1, -1, 1], [1, -1, 2]],
    [[0, 2, -7, 0], [8, -3, 0, 3], [7, 2, 0, -5]],
    {
      orthogonal: Cons(
        Cons(
          @oracle.rational(0, 1),
          Cons(
            @oracle.rational(2, 1),
            Cons(@oracle.rational(-7, 1), Cons(@oracle.rational(0, 1), Nil)),
          ),
        ),
        Cons(
          Cons(
            @oracle.rational(8, 1),
            Cons(
              @oracle.rational(-147, 53),
              Cons(@oracle.rational(-42, 53), Cons(@oracle.rational(3, 1), Nil)),
            ),
          ),
          Cons(
            Cons(
              @oracle.rational(7569, 2155),
              Cons(
                @oracle.rational(13181, 4310),
                Cons(
                  @oracle.rational(1883, 2155),
                  Cons(@oracle.rational(-27187, 4310), Nil),
                ),
              ),
            ),
            Nil,
          ),
        ),
      ),
      coefficients: Cons(
        Nil,
        Cons(
          Cons(@oracle.rational(-6, 53), Nil),
          Cons(
            Cons(
              @oracle.rational(4, 53),
              Cons(@oracle.rational(1879, 4310), Nil),
            ),
            Nil,
          ),
        ),
      ),
      norms: Cons(
        @oracle.rational(53, 1),
        Cons(
          @oracle.rational(4310, 53),
          Cons(@oracle.rational(268263, 4310), Nil),
        ),
      ),
    },
  )
  check_sympy(
    4,
    [[7, 2, -5, 6], [0, -2, -7, -1], [-1, 0, -6, 0]],
    [[0, -1, 1], [0, -1, 2], [1, 0, -1]],
    [[-1, 2, 1, 1], [-2, 2, -5, 1], [8, 2, 1, 6]],
    {
      orthogonal: Cons(
        Cons(
          @oracle.rational(-1, 1),
          Cons(
            @oracle.rational(2, 1),
            Cons(@oracle.rational(1, 1), Cons(@oracle.rational(1, 1), Nil)),
          ),
        ),
        Cons(
          Cons(
            @oracle.rational(-12, 7),
            Cons(
              @oracle.rational(10, 7),
              Cons(@oracle.rational(-37, 7), Cons(@oracle.rational(5, 7), Nil)),
            ),
          ),
          Cons(
            Cons(
              @oracle.rational(305, 39),
              Cons(
                @oracle.rational(193, 117),
                Cons(
                  @oracle.rational(-305, 234),
                  Cons(@oracle.rational(1363, 234), Nil),
                ),
              ),
            ),
            Nil,
          ),
        ),
      ),
      coefficients: Cons(
        Nil,
        Cons(
          Cons(@oracle.rational(2, 7), Nil),
          Cons(
            Cons(@oracle.rational(3, 7), Cons(@oracle.rational(-83, 234), Nil)),
            Nil,
          ),
        ),
      ),
      norms: Cons(
        @oracle.rational(7, 1),
        Cons(@oracle.rational(234, 7), Cons(@oracle.rational(23285, 234), Nil)),
      ),
    },
  )
  check_sympy(
    4,
    [[3, 1, -3, -3], [-6, 3, -3, 1], [-6, 7, -2, 7], [-7, 6, 5, 7]],
    [[1, 0, 0, 0], [1, 0, -1, 1], [1, 1, -1, 1], [1, -1, 1, 0]],
    [[3, 1, -3, -3], [2, 0, 4, -3], [-4, 3, 1, -2], [3, 5, -2, 3]],
    {
      orthogonal: Cons(
        Cons(
          @oracle.rational(3, 1),
          Cons(
            @oracle.rational(1, 1),
            Cons(@oracle.rational(-3, 1), Cons(@oracle.rational(-3, 1), Nil)),
          ),
        ),
        Cons(
          Cons(
            @oracle.rational(47, 28),
            Cons(
              @oracle.rational(-3, 28),
              Cons(
                @oracle.rational(121, 28),
                Cons(@oracle.rational(-75, 28), Nil),
              ),
            ),
          ),
          Cons(
            Cons(
              @oracle.rational(-2820, 803),
              Cons(
                @oracle.rational(2589, 803),
                Cons(
                  @oracle.rational(-3, 73),
                  Cons(@oracle.rational(-1924, 803), Nil),
                ),
              ),
            ),
            Cons(
              Cons(
                @oracle.rational(26825, 11431),
                Cons(
                  @oracle.rational(108225, 22862),
                  Cons(
                    @oracle.rational(23125, 22862),
                    Cons(@oracle.rational(33300, 11431), Nil),
                  ),
                ),
              ),
              Nil,
            ),
          ),
        ),
      ),
      coefficients: Cons(
        Nil,
        Cons(
          Cons(@oracle.rational(3, 28), Nil),
          Cons(
            Cons(@oracle.rational(-3, 14), Cons(@oracle.rational(74, 803), Nil)),
            Cons(
              Cons(
                @oracle.rational(11, 28),
                Cons(
                  @oracle.rational(-31, 73),
                  Cons(@oracle.rational(-1221, 22862), Nil),
                ),
              ),
              Nil,
            ),
          ),
        ),
      ),
      norms: Cons(
        @oracle.rational(28, 1),
        Cons(
          @oracle.rational(803, 28),
          Cons(
            @oracle.rational(22862, 803),
            Cons(@oracle.rational(855625, 22862), Nil),
          ),
        ),
      ),
    },
  )
  check_sympy(
    4,
    [[-4, -3, 2, 6], [2, -7, -7, 2], [-1, -4, 3, 6], [1, 1, -5, -7]],
    [[-1, 0, 1, 0], [0, 0, 1, 1], [0, 1, -2, -2], [0, -1, 3, 2]],
    [[3, -1, 1, 0], [0, -3, -2, -1], [2, -1, -3, 4], [-3, -3, 6, 2]],
    {
      orthogonal: Cons(
        Cons(
          @oracle.rational(3, 1),
          Cons(
            @oracle.rational(-1, 1),
            Cons(@oracle.rational(1, 1), Cons(@oracle.rational(0, 1), Nil)),
          ),
        ),
        Cons(
          Cons(
            @oracle.rational(-3, 11),
            Cons(
              @oracle.rational(-32, 11),
              Cons(
                @oracle.rational(-23, 11),
                Cons(@oracle.rational(-1, 1), Nil),
              ),
            ),
          ),
          Cons(
            Cons(
              @oracle.rational(1, 1),
              Cons(
                @oracle.rational(1, 3),
                Cons(
                  @oracle.rational(-8, 3),
                  Cons(@oracle.rational(13, 3), Nil),
                ),
              ),
            ),
            Cons(
              Cons(
                @oracle.rational(-3688, 1377),
                Cons(
                  @oracle.rational(-16135, 4131),
                  Cons(
                    @oracle.rational(17057, 4131),
                    Cons(@oracle.rational(14291, 4131), Nil),
                  ),
                ),
              ),
              Nil,
            ),
          ),
        ),
      ),
      coefficients: Cons(
        Nil,
        Cons(
          Cons(@oracle.rational(1, 11), Nil),
          Cons(
            Cons(@oracle.rational(4, 11), Cons(@oracle.rational(1, 3), Nil)),
            Cons(
              Cons(
                @oracle.rational(0, 1),
                Cons(
                  @oracle.rational(-55, 153),
                  Cons(@oracle.rational(-34, 81), Nil),
                ),
              ),
              Nil,
            ),
          ),
        ),
      ),
      norms: Cons(
        @oracle.rational(11, 1),
        Cons(
          @oracle.rational(153, 11),
          Cons(
            @oracle.rational(27, 1),
            Cons(@oracle.rational(212521, 4131), Nil),
          ),
        ),
      ),
    },
  )
  check_sympy(
    4,
    [[-1, 8, 6, -6], [6, 2, -6, 8], [1, -1, 8, -3], [-6, 4, 3, -7]],
    [[2, -2, -2, -3], [-1, 1, 1, 1], [-1, 2, 2, 2], [2, -3, -2, -4]],
    [[2, 2, -1, -1], [2, -3, -1, 4], [3, 2, 4, 2], [2, -4, 2, -2]],
    {
      orthogonal: Cons(
        Cons(
          @oracle.rational(2, 1),
          Cons(
            @oracle.rational(2, 1),
            Cons(@oracle.rational(-1, 1), Cons(@oracle.rational(-1, 1), Nil)),
          ),
        ),
        Cons(
          Cons(
            @oracle.rational(3, 1),
            Cons(
              @oracle.rational(-2, 1),
              Cons(@oracle.rational(-3, 2), Cons(@oracle.rational(7, 2), Nil)),
            ),
          ),
          Cons(
            Cons(
              @oracle.rational(17, 11),
              Cons(
                @oracle.rational(18, 11),
                Cons(
                  @oracle.rational(52, 11),
                  Cons(@oracle.rational(18, 11), Nil),
                ),
              ),
            ),
            Cons(
              Cons(
                @oracle.rational(736, 331),
                Cons(
                  @oracle.rational(-1012, 331),
                  Cons(
                    @oracle.rational(460, 331),
                    Cons(@oracle.rational(-1012, 331), Nil),
                  ),
                ),
              ),
              Nil,
            ),
          ),
        ),
      ),
      coefficients: Cons(
        Nil,
        Cons(
          Cons(@oracle.rational(-1, 2), Nil),
          Cons(
            Cons(@oracle.rational(2, 5), Cons(@oracle.rational(12, 55), Nil)),
            Cons(
              Cons(
                @oracle.rational(-2, 5),
                Cons(
                  @oracle.rational(8, 55),
                  Cons(@oracle.rational(30, 331), Nil),
                ),
              ),
              Nil,
            ),
          ),
        ),
      ),
      norms: Cons(
        @oracle.rational(10, 1),
        Cons(
          @oracle.rational(55, 2),
          Cons(
            @oracle.rational(331, 11),
            Cons(@oracle.rational(8464, 331), Nil),
          ),
        ),
      ),
    },
  )
  check_sympy(
    4,
    [[-6, -1, -3, 3], [-7, -1, -2, 2], [-7, -4, -2, -4], [6, 6, -5, -2]],
    [[-1, 1, 0, 0], [2, -3, 1, 0], [1, 0, 0, 0], [-2, 3, 0, 1]],
    [[-1, 0, 1, -1], [2, -3, -2, -4], [-6, -1, -3, 3], [-3, 5, -5, -2]],
    {
      orthogonal: Cons(
        Cons(
          @oracle.rational(-1, 1),
          Cons(
            @oracle.rational(0, 1),
            Cons(@oracle.rational(1, 1), Cons(@oracle.rational(-1, 1), Nil)),
          ),
        ),
        Cons(
          Cons(
            @oracle.rational(2, 1),
            Cons(
              @oracle.rational(-3, 1),
              Cons(@oracle.rational(-2, 1), Cons(@oracle.rational(-4, 1), Nil)),
            ),
          ),
          Cons(
            Cons(
              @oracle.rational(-56, 11),
              Cons(
                @oracle.rational(-26, 11),
                Cons(
                  @oracle.rational(-43, 11),
                  Cons(@oracle.rational(13, 11), Nil),
                ),
              ),
            ),
            Cons(
              Cons(
                @oracle.rational(-169, 265),
                Cons(
                  @oracle.rational(1521, 265),
                  Cons(
                    @oracle.rational(-1859, 530),
                    Cons(@oracle.rational(-1521, 530), Nil),
                  ),
                ),
              ),
              Nil,
            ),
          ),
        ),
      ),
      coefficients: Cons(
        Nil,
        Cons(
          Cons(@oracle.rational(0, 1), Nil),
          Cons(
            Cons(@oracle.rational(0, 1), Cons(@oracle.rational(-5, 11), Nil)),
            Cons(
              Cons(
                @oracle.rational(0, 1),
                Cons(
                  @oracle.rational(-1, 11),
                  Cons(@oracle.rational(227, 530), Nil),
                ),
              ),
              Nil,
            ),
          ),
        ),
      ),
      norms: Cons(
        @oracle.rational(3, 1),
        Cons(
          @oracle.rational(33, 1),
          Cons(
            @oracle.rational(530, 11),
            Cons(@oracle.rational(28561, 530), Nil),
          ),
        ),
      ),
    },
  )
}
