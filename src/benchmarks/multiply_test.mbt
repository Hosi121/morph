///|
test "School versus Karatsuba exact binary multiplication" (b : @bench.T) {
  for width in [128, 512, 2048] {
    let x = @binary.from_bits(
      @oracle.chain(
        [
          for i in 0..<width => i == width - 1 || (i * 17 + 3) % 11 < 6
        ],
      ),
    )
    let y = @binary.from_bits(
      @oracle.chain(
        [
          for i in 0..<width => i == width - 1 || (i * 13 + 7) % 7 < 4
        ],
      ),
    )
    b.bench(name="school \{width} bits", fn() { b.keep(@binary.multiply(x, y)) })
    b.bench(name="karatsuba \{width} bits", fn() {
      b.keep(@binary.karatsuba(x, y))
    })
  }
}
