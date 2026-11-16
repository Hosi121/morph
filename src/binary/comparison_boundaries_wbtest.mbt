///|
test "tail comparison preserves raw order across prefix and group boundaries" {
  let widths = [
    0, 1, 3, 4, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 20, 24, 31, 32, 33, 64,
  ]
  for left_width in widths {
    for right_width in widths {
      for seed in 0..<4 {
        let left = [ for bit in 0..<left_width => (bit + seed) % 3 == 0 ]
        let right = [ for bit in 0..<right_width => (bit + seed) % 5 != 0 ]
        let xs = comparison_array_word(left)
        let ys = comparison_array_word(right)
        assert_eq(
          compare_bits_tail(xs, ys),
          comparison_array_order(left, right),
        )
        assert_eq(
          compare_bits_tail(ys, xs),
          comparison_array_order(right, left),
        )
      }
    }
  }
}
