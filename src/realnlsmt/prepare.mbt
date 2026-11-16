///|
fn collect(
  arity : @core.Nat,
  formula : @qf.Formula,
  reversed : @core.Chain[Atom],
) -> Result[@core.Chain[Atom], SmtError] {
  match formula {
    Truth(_) => Ok(reversed)
    Atom(polynomial, relation) =>
      if !@polynomial.variables(polynomial).equal(arity) {
        Err(WrongArity)
      } else {
        let atom = Atom::{ polynomial, relation, }
        Ok(
          if @core.any(reversed, fn(other) { atom.equal(other) }) {
            reversed
          } else {
            Cons(atom, reversed)
          },
        )
      }
    Negation(body) => collect(arity, body, reversed)
    Conjunction(left, right) | Disjunction(left, right) =>
      match collect(arity, left, reversed) {
        Err(error) => Err(error)
        Ok(reversed) => collect(arity, right, reversed)
      }
  }
}

///|
fn atom_index(
  atom : Atom,
  atoms : @core.Chain[Atom],
  index : @core.Nat,
) -> @core.Nat? {
  match atoms {
    Nil => None
    Cons(other, rest) =>
      if atom.equal(other) {
        Some(index)
      } else {
        atom_index(atom, rest, Succ(index))
      }
  }
}

///|
fn translate(
  formula : @qf.Formula,
  atoms : @core.Chain[Atom],
) -> @circuit.Expr? {
  match formula {
    Truth(value) => Some(Constant(value))
    Atom(polynomial, relation) =>
      match atom_index(Atom::{ polynomial, relation, }, atoms, Zero) {
        Some(index) => Some(Variable(index))
        None => None
      }
    Negation(body) =>
      match translate(body, atoms) {
        Some(body) => Some(Negation(body))
        None => None
      }
    Conjunction(left, right) =>
      match (translate(left, atoms), translate(right, atoms)) {
        (Some(left), Some(right)) => Some(Conjunction(left, right))
        _ => None
      }
    Disjunction(left, right) =>
      match (translate(left, atoms), translate(right, atoms)) {
        (Some(left), Some(right)) => Some(Disjunction(left, right))
        _ => None
      }
  }
}

///|
/// Arithmetic atoms are distinct (polynomial,relation) pairs in first-use
/// order. All source atoms are preserved in the Boolean expression, including
/// those in branches masked by constants. Tseitin auxiliaries have separate IDs.
pub fn prepare(
  arity : @core.Nat,
  source : @qf.Formula,
) -> Result[Problem, SmtError] {
  match collect(arity, source, Nil) {
    Err(error) => Err(error)
    Ok(reversed) => {
      let atoms = @core.reverse(reversed)
      match translate(source, atoms) {
        None => Err(InternalInvariant)
        Some(expression) =>
          Ok({
            context: { arity, source, },
            atoms,
            encoding: @circuit.compile(Cons(expression, Nil)),
          })
      }
    }
  }
}

///|
pub fn context(problem : Problem) -> Context {
  problem.context
}

///|
pub fn arity(problem : Problem) -> @core.Nat {
  problem.context.arity
}

///|
pub fn formula(problem : Problem) -> @qf.Formula {
  problem.context.source
}

///|
pub fn atoms(problem : Problem) -> @core.Chain[Atom] {
  problem.atoms
}

///|
pub fn cnf(problem : Problem) -> @sat.Cnf {
  @circuit.cnf(problem.encoding)
}

///|
/// Rebuild the finite source-to-CNF binding at public checker boundaries.
/// Opaque construction prevents callers from manufacturing mixed payloads,
/// but the checker also enforces the invariant instead of relying on opacity.
fn valid_problem(problem : Problem) -> Bool {
  match prepare(arity(problem), formula(problem)) {
    Ok(expected) => expected.equal(problem)
    Err(_) => false
  }
}
