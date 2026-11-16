///|
fn replay_step(
  state : State,
  input : @real.Number,
  step : StepCertificate,
  fuel : @core.Nat,
) -> Result[State, @zass.Verdict] {
  match step {
    Rational(value) => {
      if !rational_coordinate(input).equal(Some(value)) {
        return Err(@zass.Refuted)
      }
      Ok(with_coordinate(state, input, @nf.rational(state.field, value)))
    }
    Reuse(index) =>
      match
        (@core.nth(state.seen, index), @core.nth(state.coordinates, index)) {
        (Some(source), Some(value)) => {
          if !source.equal(@real.root_certificate(input)) {
            return Err(@zass.Refuted)
          }
          Ok(with_coordinate(state, input, value))
        }
        _ => Err(@zass.Refuted)
      }
    Normalize(proof) => {
      if !@nf.degree(state.field).equal(Succ(Zero)) {
        return Err(@zass.Refuted)
      }
      let normalized = match @real.number(proof.result) {
        Ok(value) => value
        Err(_) => return Err(@zass.Refuted)
      }
      match @minimal.check_normalization(input, normalized, proof, fuel) {
        @zass.Proven => ()
        verdict => return Err(verdict)
      }
      let field = match @nf.field(proof, fuel) {
        Ok(field) => field
        Err(@nf.VerificationBudget) => return Err(@zass.Undecided)
        Err(_) => return Err(@zass.Refuted)
      }
      let coordinates = match transport(state.coordinates, @nf.zero(field)) {
        Some(values) => values
        None => return Err(@zass.Refuted)
      }
      match @nf.generator(field) {
        Ok(generator) =>
          Ok(
            with_coordinate({ ..state, field, coordinates, }, input, generator),
          )
        Err(_) => Err(@zass.Refuted)
      }
    }
    Merge(common, proof) => {
      let alpha = match @real.number(@nf.embedding(state.field)) {
        Ok(value) => value
        Err(_) => return Err(@zass.Refuted)
      }
      match @comp.check_result(alpha, input, common, proof, fuel) {
        @zass.Proven => ()
        verdict => return Err(verdict)
      }
      let image = @comp.left_element(common)
      match @nf.evaluate_polynomial(image, @nf.modulus(state.field)) {
        Some(value) => if !@nf.is_zero(value) { return Err(@zass.Refuted) }
        None => return Err(@zass.Refuted)
      }
      let coordinates = match transport(state.coordinates, image) {
        Some(values) => values
        None => return Err(@zass.Refuted)
      }
      Ok(
        with_coordinate(
          { ..state, field: @comp.common_field(common), coordinates, },
          input,
          @comp.right_element(common),
        ),
      )
    }
  }
}

///|
fn replay(
  state : State,
  inputs : @core.Chain[@real.Number],
  steps : @core.Chain[StepCertificate],
  fuel : @core.Nat,
) -> Result[State, @zass.Verdict] {
  match (inputs, steps) {
    (Nil, Nil) => Ok(state)
    (Cons(input, rest), Cons(step, tail)) =>
      match replay_step(state, input, step, fuel) {
        Ok(next) => replay(next, rest, tail, fuel)
        Err(verdict) => Err(verdict)
      }
    _ => Err(@zass.Refuted)
  }
}

///|
fn authenticated_state(
  inputs : @core.Chain[@cx.Number],
  proof : Certificate,
  fuel : @core.Nat,
) -> Result[State, @zass.Verdict] {
  if !proof.sources.equal(@core.map(inputs, @cx.certificate)) {
    return Err(@zass.Refuted)
  }
  let zero = match @real.rational(@exact.rational_zero()) {
    Ok(zero) => zero
    Err(_) => return Err(@zass.Refuted)
  }
  match @minimal.check_result(zero, proof.initial, fuel) {
    @zass.Proven => ()
    verdict => return Err(verdict)
  }
  let field = match @nf.field(proof.initial, fuel) {
    Ok(field) => field
    Err(@nf.VerificationBudget) => return Err(@zass.Undecided)
    Err(_) => return Err(@zass.Refuted)
  }
  let state = match
    replay(
      { field, coordinates: Nil, seen: Nil, },
      flatten(inputs),
      proof.steps,
      fuel,
    ) {
    Ok(state) => state
    Err(verdict) => return Err(verdict)
  }
  if !@nf.certificate(state.field).equal(@nf.certificate(proof.field)) ||
    !proof.coordinates.equal(@core.map(state.coordinates, @nf.representative)) {
    return Err(@zass.Refuted)
  }
  Ok(state)
}

///|
/// Independently replay authenticated coordinate inclusions and all exact
/// transports. No compositum search or realization of old coordinates reruns.
pub fn check(
  inputs : @core.Chain[@cx.Number],
  proof : Certificate,
  verification_fuel : @core.Nat,
) -> @zass.Verdict {
  match authenticated_state(inputs, proof, verification_fuel) {
    Ok(_) => @zass.Proven
    Err(verdict) => verdict
  }
}

///|
fn same_elements(
  left : @core.Chain[@cf.Element],
  right : @core.Chain[@cf.Element],
) -> Bool {
  match (left, right) {
    (Nil, Nil) => true
    (Cons(a, rest), Cons(b, tail)) =>
      @cf.equal(a, b) && same_elements(rest, tail)
    _ => false
  }
}

///|
/// Bind the actual returned field, element count, order, real and imaginary
/// residues to the externally supplied selected complex Numbers.
pub fn check_result(
  inputs : @core.Chain[@cx.Number],
  value : Common,
  proof : Certificate,
  verification_fuel : @core.Nat,
) -> @zass.Verdict {
  if !@nf.certificate(@cf.real_field(value.field)).equal(
      @nf.certificate(proof.field),
    ) {
    return @zass.Refuted
  }
  let state = match authenticated_state(inputs, proof, verification_fuel) {
    Ok(state) => state
    Err(verdict) => return verdict
  }
  match complex_elements(@cf.field(state.field), state.coordinates) {
    Ok(expected) =>
      if same_elements(value.values, expected) {
        @zass.Proven
      } else {
        @zass.Refuted
      }
    Err(_) => @zass.Refuted
  }
}
