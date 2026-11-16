///|
test "F4 actual batch trace records multiple pairs preprocessing rows and matrix columns" {
  let inputs = @oracle.chain([
    test_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1])]),
    test_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 0])]),
    test_poly(2, [(1, 1, [1, 0]), (-1, 1, [0, 2])]),
  ])
  let result = test_complete(2, inputs)
  debug_inspect(
    @oracle.array(history(result)).map(fn(b) {
      (
        @oracle.int_of_nat(b.degree),
        @oracle.int_of_nat(b.selected_pairs),
        @oracle.int_of_nat(b.seed_rows),
        @oracle.int_of_nat(b.reducer_rows),
        @oracle.int_of_nat(b.columns),
        @oracle.int_of_nat(b.new_rows),
      )
    }),
    content=(
      #|[
      #|  (2, 2, 4, 1, 6, 1),
      #|  (3, 1, 2, 1, 3, 0),
      #|  (4, 2, 4, 2, 4, 0),
      #|  (5, 1, 2, 2, 4, 0),
      #|]
    ),
  )
}
