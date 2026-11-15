///|
fn arrow(n : Int32) -> Arrow {
  if n == 0 {
    Nil
  } else {
    Cons((), arrow(n - 1))
  }
}

///|
fn phase(a : Arrow) -> Int32 {
  match a {
    Nil => 0
    Cons(_, rest) => 1 + phase(rest)
  }
}

///|
/// Group-algebra coefficients modulo x^N-1, stronger than floating comparison.
fn histogram(x : Number, period : Int32) -> Array[Int32] {
  let counts = Array::make(period, 0)
  fn visit(x : Number) -> Unit {
    match x {
      Nil => ()
      Cons(a, rest) => {
        counts[phase(a) % period] += 1
        visit(rest)
      }
    }
  }
  visit(x)
  counts
}

///|
fn same_spectrum(
  actual : Signal,
  expected : Signal,
  period : Int32,
) -> Unit raise {
  match (actual, expected) {
    (Nil, Nil) => ()
    (Cons(a, at), Cons(b, bt)) => {
      assert_eq(histogram(a, period), histogram(b, period))
      same_spectrum(at, bt, period)
    }
    _ => fail("different spectrum lengths")
  }
}

///|
test "FFT agrees with independent DFT on every Boolean signal up to length eight" {
  for n in [1, 2, 4, 8] {
    for mask in 0..<(1 << n) {
      fn signal(i : Int32) -> Signal {
        if i == n {
          Nil
        } else {
          let sample : Number = if (mask & (1 << i)) == 0 {
            Nil
          } else {
            Cons(Nil, Nil)
          }
          Cons(sample, signal(i + 1))
        }
      }
      let input = signal(0)
      match fft(arrow(1), input) {
        None => fail("valid length rejected")
        Some(spectrum) => same_spectrum(spectrum, dft(arrow(1), input), n)
      }
    }
  }
}

///|
test "complex arrow sums and non-unit root step" {
  fn signal(i : Int32) -> Signal {
    if i == 16 {
      Nil
    } else {
      Cons(Cons(arrow(i % 5), Cons(arrow(i * 3 + 1), Nil)), signal(i + 1))
    }
  }
  let xs = signal(0)
  for step in [1, 2, 3] {
    match fft(arrow(step), xs) {
      None => fail("valid length rejected")
      Some(actual) => same_spectrum(actual, dft(arrow(step), xs), 16 * step)
    }
  }
}

///|
test "invalid FFT lengths fail explicitly" {
  assert_eq(fft(Nil, Nil), None)
  let sample : Number = Cons(Nil, Nil)
  assert_eq(
    fft(
      arrow(1),
      @core.replicate(@core.Succ(@core.Succ(@core.Succ(@core.Zero))), sample),
    ),
    None,
  )
  assert_false(
    valid_length(
      @core.Cons((), Cons((), Cons((), Cons((), Cons((), Cons((), Nil)))))),
    ),
  )
}
