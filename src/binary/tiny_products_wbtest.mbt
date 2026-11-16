///|
fn school_product_control(a : Binary, b : Binary) -> Binary {
  match (a.bits, b.bits) {
    (Nil, _) | (_, Nil) => zero()
    (Cons(true, Nil), _) => b
    (_, Cons(true, Nil)) => a
    (Cons(false, Cons(true, Nil)), _) => double(b)
    (_, Cons(false, Cons(true, Nil))) => double(a)
    _ => multiply_bits(a.bits, b)
  }
}

///|
fn cached_product_control(a : Binary, b : Binary) -> Binary {
  match (a.bits, b.bits) {
    (Nil, _) | (_, Nil) => zero()
    (Cons(true, Nil), _) => b
    (_, Cons(true, Nil)) => a
    (Cons(false, Cons(true, Nil)), _) => double(b)
    (_, Cons(false, Cons(true, Nil))) => double(a)
    _ =>
      match tiny_product(a, b) {
        Some(product) => product
        None => multiply_bits(a.bits, b)
      }
  }
}

///|
test "finite product table and generic fallback match every byte product" {
  for a in 0..<256 {
    for b in 0..<256 {
      let x = @oracle.binary(a)
      let y = @oracle.binary(b)
      let expected = @oracle.binary(a * b)
      assert_eq(cached_product_control(x, y), expected)
      let lookup = if a < 16 && b < 16 { Some(expected) } else { None }
      assert_eq(tiny_product(x, y), lookup)
    }
  }
}

///|
test "same ELF cached four bit generic products" (b : @bench.T) {
  let pairs = []
  for a in 3..<16 {
    for c in 3..<16 {
      pairs.push((@oracle.binary(a), @oracle.binary(c)))
    }
  }
  b.bench(name="school tiny169", fn() {
    for pair in pairs {
      b.keep(school_product_control(pair.0, pair.1))
    }
  })
  b.bench(name="cached tiny169", fn() {
    for pair in pairs {
      b.keep(cached_product_control(pair.0, pair.1))
    }
  })
}

///|
test "same ELF cached products mixed byte controls" (b : @bench.T) {
  let pairs = []
  for index in 0..<128 {
    let a = (index * 73 + 19) % 256
    let c = (index * 137 + 43) % 256
    pairs.push((@oracle.binary(a), @oracle.binary(c)))
  }
  b.bench(name="school byte128", fn() {
    for pair in pairs {
      b.keep(school_product_control(pair.0, pair.1))
    }
  })
  b.bench(name="cached byte128", fn() {
    for pair in pairs {
      b.keep(cached_product_control(pair.0, pair.1))
    }
  })
}

///|
test "same ELF cached product wide controls" (b : @bench.T) {
  let a = @oracle.binary_from_hex("d59b8c50c9174c3a71293ab167cd89ef")
  let c = @oracle.binary_from_hex("21234567a789cf1323456789abcdef01")
  let small = @oracle.binary(11)
  let pairs = [(a, c), (a, small), (small, a)]
  b.bench(name="school wide3", fn() {
    for pair in pairs {
      b.keep(school_product_control(pair.0, pair.1))
    }
  })
  b.bench(name="cached wide3", fn() {
    for pair in pairs {
      b.keep(cached_product_control(pair.0, pair.1))
    }
  })
}
