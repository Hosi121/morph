///|
fn agreement_count(
  a : @core.Chain[@binary.Binary],
  b : @core.Chain[@binary.Binary],
) -> @core.Nat {
  match (a, b) {
    (Cons(x, xs), Cons(y, ys)) => {
      let rest = agreement_count(xs, ys)
      if x.equal(y) {
        Succ(rest)
      } else {
        rest
      }
    }
    _ => Zero
  }
}

///|
/// Exact evaluation, fixed message/codeword lengths and agreement metadata.
/// This witness check runs neither interpolation nor Roth–Ruckenstein search.
pub fn check_candidate(
  plan : Plan,
  received : @core.Chain[@binary.Binary],
  candidate : Candidate,
) -> Bool {
  match check_word(plan, received, @core.length(plan.points)) {
    Some(_) => return false
    None => ()
  }
  match encode(plan, candidate.message) {
    Err(_) => false
    Ok(codeword) => {
      let agreements = agreement_count(received, codeword)
      codeword.equal(candidate.codeword) &&
      agreements.equal(candidate.agreements) &&
      !(@core.compare(agreements, plan.agreements) is Less)
    }
  }
}

///|
/// Check interpolation and every listed witness. This establishes list
/// soundness, not completeness: removing a candidate cannot be detected here.
pub fn check_witnesses(
  plan : Plan,
  received : @core.Chain[@binary.Binary],
  decoded : Decoded,
) -> Bool {
  if !check_interpolation(plan, received, decoded.interpolation) {
    return false
  }
  fn visit(candidates : @core.Chain[Candidate]) -> Bool {
    match candidates {
      Nil => true
      Cons(candidate, rest) => {
        if !check_candidate(plan, received, candidate) ||
          @core.any(rest, fn(other) { other.message.equal(candidate.message) }) {
          return false
        }
        match compose(plan.field, decoded.interpolation, candidate.message) {
          Ok(value) => @fppoly.is_zero(value) && visit(rest)
          Err(_) => false
        }
      }
    }
  }
  visit(decoded.candidates)
}

///|
/// Perform the bounded interpolation phase, then expose a resumable RR tree.
/// Interpolation is not charged against the later node fuel. Alphabet size and
/// matrix dimensions are explicit plan parameters; suitable small inputs are
/// the caller's responsibility.
pub fn start(
  plan : Plan,
  received : @core.Chain[@binary.Binary],
) -> Result[Search, DecodeError] {
  match interpolate(plan, received) {
    Err(error) => Err(error)
    Ok(interpolation) =>
      Ok({
        plan,
        received,
        interpolation,
        pending: Cons(
          {
            polynomial: normalize(interpolation),
            reversed_prefix: Nil,
            remaining: plan.dimension,
          },
          Nil,
        ),
        found: Nil,
        visited: Zero,
      })
  }
}

///|
pub fn partial_candidates(search : Search) -> @core.Chain[Candidate] {
  search.found
}

///|
pub fn nodes_visited(search : Search) -> @core.Nat {
  search.visited
}

///|
fn process(
  search : Search,
  node : Node,
  rest : @core.Chain[Node],
) -> Result[Search, DecodeError] {
  let visited : @core.Nat = Succ(search.visited)
  match node.polynomial.terms {
    Nil => return Err(InternalInvariant)
    _ => ()
  }
  match node.remaining {
    Zero => {
      let message = @core.reverse(node.reversed_prefix)
      let exact = match
        compose(search.plan.field, search.interpolation, message) {
        Err(error) => return Err(error)
        Ok(value) => @fppoly.is_zero(value)
      }
      if !exact {
        return Ok({ ..search, pending: rest, visited, })
      }
      let codeword = match encode(search.plan, message) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let agreements = agreement_count(search.received, codeword)
      if @core.compare(agreements, search.plan.agreements) is Less {
        Ok({ ..search, pending: rest, visited, })
      } else {
        let candidate = { message, codeword, agreements, }
        Ok({
          ..search,
          pending: rest,
          visited,
          found: Cons(candidate, search.found),
        })
      }
    }
    Succ(remaining) => {
      let roots = @core.filter(search.plan.alphabet, fn(gamma) {
        @binary.is_zero(
          hasse(
            search.plan.field,
            node.polynomial,
            { x: Zero, y: Zero, },
            @binary.zero(),
            gamma,
          ),
        )
      })
      let children = @core.map(roots, fn(gamma) {
        {
          polynomial: substitute(search.plan.field, node.polynomial, gamma),
          reversed_prefix: Cons(gamma, node.reversed_prefix),
          remaining,
        }
      })
      Ok({ ..search, pending: @core.append(children, rest), visited, })
    }
  }
}

///|
/// Spend at most fuel pending-node visits. Suspended remains resumable even
/// when some candidates are already present; only exhausted trees are Complete.
pub fn advance(search : Search, fuel : @core.Nat) -> Result[Run, DecodeError] {
  match search.pending {
    Nil =>
      Ok(
        Complete({
          interpolation: search.interpolation,
          candidates: @core.reverse(search.found),
          nodes: search.visited,
        }),
      )
    Cons(node, rest) =>
      match fuel {
        Zero => Ok(Suspended(search))
        Succ(remaining) =>
          match process(search, node, rest) {
            Err(error) => Err(error)
            Ok(next) => advance(next, remaining)
          }
      }
  }
}

///|
pub fn decode(
  plan : Plan,
  received : @core.Chain[@binary.Binary],
  fuel : @core.Nat,
) -> Result[Run, DecodeError] {
  match start(plan, received) {
    Err(error) => Err(error)
    Ok(search) => advance(search, fuel)
  }
}
