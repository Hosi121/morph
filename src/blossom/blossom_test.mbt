///|
test "public symbolic graph matching path and certificate API" {
  let a = @core.Zero
  let b = @core.Succ(a)
  let c = @core.Succ(b)
  let d = @core.Succ(c)
  let vertices = @core.Cons(
    a,
    @core.Cons(b, @core.Cons(c, @core.Cons(d, @core.Nil))),
  )
  let edges = @core.Cons(
    (a, b),
    @core.Cons((b, c), @core.Cons((c, a), @core.Cons((b, d), @core.Nil))),
  )
  let p = @blossom.problem(vertices, edges).unwrap()
  let seed = @core.Cons((b, c), @core.Nil)
  assert_true(@blossom.check_matching(p, seed))
  let searched = @blossom.augmenting_search(p, seed).unwrap()
  let path = searched.path.unwrap()
  assert_true(@blossom.check_augmenting(p, seed, path))
  let matching = @blossom.augment(p, seed, path).unwrap()
  let certificate = @blossom.certify(p, matching).unwrap()
  assert_true(@blossom.check(p, certificate))
  assert_true(@blossom.check(p, @blossom.maximum(p).unwrap()))
  assert_true(@blossom.check_matching(p, @blossom.maximum_matching(p).unwrap()))
  assert_eq(@blossom.augmenting_search(p, matching).unwrap().path, None)
  assert_false(@blossom.check(p, { ..certificate, pairs: @core.Nil, }))
}
