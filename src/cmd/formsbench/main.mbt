///|
fn binary_hex(value : @binary.Binary) -> String {
  let bits = @oracle.array(@core.reverse(@binary.bits(value)))
  if bits.is_empty() {
    return "0"
  }
  let padded = Array::make((4 - bits.length() % 4) % 4, false)
  for bit in bits {
    padded.push(bit)
  }
  @oracle.hex_bits(@oracle.chain(padded))
}

///|
fn rational_json(value : @exact.Rational) -> String {
  let n = @exact.numerator(value)
  "[\{@exact.negative(n)},\"\{binary_hex(@exact.magnitude(n))}\",\"\{binary_hex(@exact.denominator(value))}\"]"
}

///|
fn nat_list_json(values : @core.Chain[@core.Nat]) -> String {
  "[" +
  @oracle.array(values)
  .map(fn(n) { @oracle.int_of_nat(n).to_string() })
  .join(",") +
  "]"
}

///|
fn form_json(value : @forms.Form) -> String {
  let terms = @oracle.array(@forms.terms(value))
    .map(fn(term) {
      let polynomial = @oracle.array(@poly.terms(term.coefficient))
        .map(fn(monomial) {
          "[" +
          rational_json(monomial.coefficient) +
          "," +
          nat_list_json(monomial.exponents) +
          "]"
        })
        .join(",")
      "{\"indices\":" +
      nat_list_json(term.indices) +
      ",\"coefficient\":[" +
      polynomial +
      "]}"
    })
    .join(",")
  "{\"variables\":\{@oracle.int_of_nat(@forms.variables(value))},\"degree\":\{@oracle.int_of_nat(@forms.degree(value))},\"terms\":[" +
  terms +
  "]}"
}

///|
fn coefficient(n : Int32, shift : Int32) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(n),
    @oracle.chain(
      Array::makei(8, fn(t) {
        @poly.Term::{
          coefficient: @oracle.rational(t + 1 + shift, 1 + t % 3),
          exponents: @oracle.chain(
            Array::makei(n, fn(i) {
              @oracle.nat(if i == (t + shift) % n { 1 + t / n } else { 0 })
            }),
          ),
        }
      }),
    ),
  ).unwrap()
}

///|
fn form(n : Int32, bases : Array[Array[Int32]], shift : Int32) -> @forms.Form {
  @forms.form(
    @oracle.nat(n),
    @oracle.nat(bases[0].length()),
    @oracle.chain(
      bases.mapi(fn(index, basis) {
        @forms.Term::{
          coefficient: coefficient(n, shift + index),
          indices: @oracle.chain(basis.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn main {
  let args = @env.args()
  let route = args[args.length() - 2]
  let name = args[args.length() - 1]
  let iterations = match name {
    "overlap" => 20
    "disjoint" => 10
    "mixed" => 3
    "closed-d" => 100
    "closed-primitive" => 10
    _ => abort("unknown case")
  }
  let (left, right) = match name {
    "overlap" => (form(4, [[0, 2]], 0), form(4, [[1, 2]], 1))
    "disjoint" => (form(4, [[1, 3]], 0), form(4, [[0, 2]], 1))
    "mixed" => {
      let bases = [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]]
      (form(4, bases, 0), form(4, bases, 1))
    }
    "closed-d" => {
      let value = @forms.exact_differential(@forms.scalar(coefficient(4, 0)))
        .unwrap()
        .value()
      (value, value)
    }
    _ => {
      let value = form(3, [[0, 1, 2]], 0)
      (value, value)
    }
  }
  // Both routes pay for the same initial witness preparation. The comparison
  // asks what repeated operations can omit once closedness is already known.
  let known = if name == "closed-d" || name == "closed-primitive" {
    Some(@forms.closed_form(left).unwrap())
  } else {
    None
  }
  let answers = []
  for _ in 0..<iterations {
    let value = match (name, route) {
      ("closed-d", "general") => @forms.exterior_derivative(left).unwrap()
      ("closed-d", "structured") => known.unwrap().exterior_derivative()
      ("closed-primitive", "general") => @forms.primitive(left).unwrap()
      ("closed-primitive", "structured") =>
        known.unwrap().primitive().unwrap().primitive()
      (_, "general") => legacy_wedge(left, right).unwrap()
      (_, "structured") => @forms.wedge(left, right).unwrap()
      _ => abort("unknown route")
    }
    answers.push(form_json(value))
  }
  println(
    "{\"case\":\"\{name}\",\"iterations\":\{iterations},\"results\":[" +
    answers.join(",") +
    "]}",
  )
}
