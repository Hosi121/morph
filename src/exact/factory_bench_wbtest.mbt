///|
fn previous_rational_zero_factory() -> Rational {
  whole(positive(@binary.zero()))
}

///|
fn previous_rational_one_factory() -> Rational {
  whole(positive(@binary.one()))
}

///|
test "current canonical rational zero and one factories" (b : @bench.T) {
  b.bench(fn() {
    b.keep(rational_zero())
    b.keep(rational_one())
  })
}

///|
test "previous canonical rational zero and one factories same ELF" (
  b : @bench.T,
) {
  b.bench(fn() {
    b.keep(previous_rational_zero_factory())
    b.keep(previous_rational_one_factory())
  })
}
