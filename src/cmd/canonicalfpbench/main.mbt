///|
/// This host-only harness imports the public polynomial API. Expected residues
/// come from machine arithmetic; no production polynomial operation computes
/// an expected coefficient. The same source builds on both revisions.
enum Operation {
  Add
  Negate
  Subtract
  Multiply
  Divide
}

///|
struct Prepared {
  left : @poly.Polynomial
  right : @poly.Polynomial
  expected : @core.Chain[@binary.Binary]
  remainder : @core.Chain[@binary.Binary]
  stamp : Int32
}

///|
fn residue(value : Int32, p : Int32) -> Int32 {
  (value % p + p) % p
}

///|
fn canonical(values : Array[Int32], p : Int32) -> Array[Int32] {
  let result = values.map(fn(value) { residue(value, p) })
  while !result.is_empty() && result[result.length() - 1] == 0 {
    ignore(result.pop())
  }
  result
}

///|
fn oracle_add(a : Array[Int32], b : Array[Int32], p : Int32) -> Array[Int32] {
  let width = if a.length() > b.length() { a.length() } else { b.length() }
  canonical(
    Array::makei(width, fn(i) {
      (if i < a.length() { a[i] } else { 0 }) +
      (if i < b.length() { b[i] } else { 0 })
    }),
    p,
  )
}

///|
fn oracle_negate(a : Array[Int32], p : Int32) -> Array[Int32] {
  canonical(a.map(fn(x) { -x }), p)
}

///|
/// Schoolbook arithmetic, with an Int64 product before taking the residue.
fn oracle_multiply(
  a : Array[Int32],
  b : Array[Int32],
  p : Int32,
) -> Array[Int32] {
  if a.is_empty() || b.is_empty() {
    return []
  }
  let product = Array::make(a.length() + b.length() - 1, 0)
  for i in 0..<a.length() {
    for j in 0..<b.length() {
      let term = (a[i].to_int64() * b[j].to_int64() % p.to_int64()).to_int()
      product[i + j] = residue(product[i + j] + term, p)
    }
  }
  canonical(product, p)
}

///|
/// Independent monic long division. The division fixture has a monic divisor.
fn oracle_divide(
  a : Array[Int32],
  b : Array[Int32],
  p : Int32,
) -> (Array[Int32], Array[Int32]) {
  if b.is_empty() || b[b.length() - 1] != 1 {
    abort("oracle divisor must be monic")
  }
  let remainder = a.copy()
  let width = a.length() - b.length() + 1
  let quotient = Array::make(if width > 0 { width } else { 0 }, 0)
  for i = a.length() - 1; i >= b.length() - 1; i = i - 1 {
    let shift = i - b.length() + 1
    let factor = remainder[i]
    quotient[shift] = factor
    for j in 0..<b.length() {
      let term = (factor.to_int64() * b[j].to_int64() % p.to_int64()).to_int()
      remainder[shift + j] = residue(remainder[shift + j] - term, p)
    }
  }
  (canonical(quotient, p), canonical(remainder, p))
}

///|
fn encoded(values : Array[Int32]) -> @core.Chain[@binary.Binary] {
  @oracle.chain(values.map(@oracle.binary))
}

///|
fn prepare(
  operation : Operation,
  field : @primefield.Field,
  p : Int32,
  a : Array[Int32],
  b : Array[Int32],
) -> Prepared {
  let a = canonical(a, p)
  let b = canonical(b, p)
  let (wanted, remainder) = match operation {
    Add => (oracle_add(a, b, p), [])
    Negate => (oracle_negate(a, p), [])
    Subtract => (oracle_add(a, oracle_negate(b, p), p), [])
    Multiply => (oracle_multiply(a, b, p), [])
    Divide => oracle_divide(a, b, p)
  }
  // The division witness uses only independent machine arithmetic. Every
  // repeated quotient/remainder is subsequently compared with this exact pair.
  if operation is Divide {
    if oracle_add(oracle_multiply(b, wanted, p), remainder, p) != a ||
      remainder.length() >= b.length() {
      abort("independent division witness failed")
    }
  }
  let stamp = wanted.fold(init=1, fn(h, x) { (h * 31 + x) % 1000003 })
  let stamp = remainder.fold(init=stamp, fn(h, x) { (h * 31 + x) % 1000003 })
  {
    left: @poly.polynomial(field, encoded(a)),
    right: @poly.polynomial(field, encoded(b)),
    expected: encoded(wanted),
    remainder: encoded(remainder),
    stamp,
  }
}

///|
fn fixtures(mode : String, operation : Operation, p : Int32) -> Array[Prepared] {
  let field = @primefield.field(@oracle.binary(p)).unwrap()
  let a17 = [0, 16, 8, 1, 0, 16, 9, 4, 16, 2, 0, 15, 7, 1, 16, 0, 8]
  let b17 = [0, 1, 9, 16, 0, 2, 8, 13, 1]
  let a65537 = [
    65536, 0, 32768, 1, 0, 2, 65535, 65536, 0, 11, 4, 0, 65530, 1, 65536, 32768,
    65536,
  ]
  let b65537 = [0, 1, 32769, 65536, 0, 65535, 2, 1, 65536]
  let inputs = match mode {
    "add17-unequal" => [(a17, b17), (b17, a17)]
    "add65537-cancel" => {
      let opposite = oracle_negate(a65537, p)
      let partial = opposite.copy()
      partial[0] = 2
      [(a65537, partial), (a65537, opposite), (a65537, a65537)]
    }
    "negate17-zeros" =>
      [([0, 0, 16, 0, 1, 0, 0, 8, 0, 0, 0, 0, 2, 0, 16, 0, 1], []), (a17, [])]
    "negate65537-sparse" =>
      [
        ([0, 0, 65536, 0, 1, 0, 0, 32768, 0, 0, 0, 0, 2, 0, 65536, 0, 1], []),
        (a65537, []),
      ]
    "subtract65537-unequal" => [(a65537, b65537), (b65537, a65537)]
    "multiply17-d8" => [(b17, [16, 0, 1, 8, 0, 2, 15, 3, 1]), (b17, b17)]
    "divide17-d16" => {
      let divisor = [1, 0, 16, 2, 0, 8, 1, 0, 1]
      let quotient = [16, 1, 0, 8, 0, 15, 2, 0, 1]
      let remainder = [0, 16, 1, 0, 8, 0, 0, 4]
      let dividend = oracle_add(
        oracle_multiply(divisor, quotient, p),
        remainder,
        p,
      )
      [(dividend, divisor), (oracle_multiply(divisor, b17, p), divisor)]
    }
    "char2-control" => [(a17, b17), (b17, a17)]
    _ => abort("unknown benchmark case")
  }
  inputs.map(fn(pair) {
    let (a, b) = pair
    prepare(operation, field, p, a, b)
  })
}

///|
/// Exact structural equality also checks canonical zero/trailing-zero shape;
/// a checksum never substitutes for this comparison.
fn check(
  actual : @poly.Polynomial,
  expected : @core.Chain[@binary.Binary],
) -> Unit {
  if @poly.coefficients(actual) != expected {
    abort("canonical coefficients differ from independent machine oracle")
  }
}

///|
fn perform(operation : Operation, input : Prepared) -> Unit {
  match operation {
    Add => check(@poly.add(input.left, input.right).unwrap(), input.expected)
    Negate => check(@poly.negate(input.left), input.expected)
    Subtract =>
      check(@poly.subtract(input.left, input.right).unwrap(), input.expected)
    Multiply =>
      check(@poly.multiply(input.left, input.right).unwrap(), input.expected)
    Divide => {
      let result = @poly.divide(input.left, input.right).unwrap()
      check(result.quotient, input.expected)
      check(result.remainder, input.remainder)
    }
  }
}

///|
fn main {
  let args = @env.args()
  let mode = args[args.length() - 1]
  let (operation, p, default_iterations) = match mode {
    "add17-unequal" => (Add, 17, 150000)
    "add65537-cancel" => (Add, 65537, 40000)
    "negate17-zeros" => (Negate, 17, 75000)
    "negate65537-sparse" => (Negate, 65537, 30000)
    "subtract65537-unequal" => (Subtract, 65537, 20000)
    "multiply17-d8" => (Multiply, 17, 10000)
    "divide17-d16" => (Divide, 17, 5000)
    "char2-control" => (Add, 2, 600000)
    _ => abort("unknown benchmark case")
  }
  let iterations = match @env.get_env_var("MORPH_CANONICAL_ITERATIONS") {
    Some(value) =>
      @string.parse_int(value[:]) catch {
        _ => abort("invalid iteration override")
      }
    None => default_iterations
  }
  if iterations <= 0 {
    abort("iteration count must be positive")
  }
  let inputs = fixtures(mode, operation, p)
  // Fixed setup and one checked warmup per fixture are included in external
  // process timing. The loop times the operation plus exact coefficient checks.
  for input in inputs {
    if operation is Divide {
      let result = @poly.divide(input.left, input.right).unwrap()
      check(result.quotient, input.expected)
      check(result.remainder, input.remainder)
      let rebuilt = @poly.add(
        @poly.multiply(input.right, result.quotient).unwrap(),
        result.remainder,
      ).unwrap()
      if rebuilt != input.left {
        abort("public division reconstruction witness failed")
      }
    } else {
      perform(operation, input)
    }
  }
  let mut checksum = 0
  for i in 0..<iterations {
    let input = inputs[i % inputs.length()]
    perform(operation, input)
    checksum = (checksum + input.stamp) % 1000000007
  }
  println(
    "{\"case\":\"\{mode}\",\"iterations\":\{iterations},\"checksum\":\{checksum},\"checked\":true}",
  )
}
