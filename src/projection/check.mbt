///|
/// Recompute the full projection and bind mode, original atom list, variable,
/// every coefficient/PSC, and product metadata. This is not a delineability proof.
pub fn check(
  mode : Method,
  atoms : @core.Chain[@poly.Polynomial],
  selected : @core.Nat,
  proof : Certificate,
) -> Bool {
  let produced = match mode {
    CollinsProjection => full_collins(atoms, selected)
    ProductProjection => product_projection(atoms, selected)
  }
  match produced {
    Err(_) => false
    Ok(plan) => certificate(plan).equal(proof)
  }
}

///|
pub fn checked(
  mode : Method,
  atoms : @core.Chain[@poly.Polynomial],
  selected : @core.Nat,
  proof : Certificate,
) -> Plan? {
  if check(mode, atoms, selected, proof) {
    Some({ proof, })
  } else {
    None
  }
}

///|
pub fn check_result(
  mode : Method,
  atoms : @core.Chain[@poly.Polynomial],
  selected : @core.Nat,
  plan : Plan,
  proof : Certificate,
) -> Bool {
  certificate(plan).equal(proof) && check(mode, atoms, selected, proof)
}
