///|
test "zero-one knapsack witnesses match exhaustive subset enumeration" {
  for family in 0..<40 {
    let weights = [ for i in 0..<6 => (family * 3 + i * 7) % 5 ]
    let values = [ for i in 0..<6 => (family * 7 + i * 3) % 11 ]
    let items = @oracle.chain(
      [
        for i in 0..<6 => {
          Item::{
            weight: @oracle.nat(weights[i]),
            value: @oracle.binary(values[i]),
          }
        }
      ],
    )
    for capacity in 0..<=12 {
      let mut best = 0
      for mask in 0..<64 {
        let mut weight = 0
        let mut value = 0
        for i in 0..<6 {
          if (mask & (1 << i)) != 0 {
            weight += weights[i]
            value += values[i]
          }
        }
        if weight <= capacity {
          best = Int32::max(best, value)
        }
      }
      let result = knapsack(items, @oracle.nat(capacity))
      assert_eq(@oracle.int_of_binary(result.value), best)
      let chosen = @oracle.array(result.chosen).map(@oracle.int_of_nat)
      let mut total_weight = 0
      let mut total_value = 0
      let mut previous = -1
      for index in chosen {
        assert_true(index > previous && index < 6)
        previous = index
        total_weight += weights[index]
        total_value += values[index]
      }
      assert_true(total_weight <= capacity)
      assert_eq(total_value, best)
    }
  }
  assert_eq(knapsack(Nil, @oracle.nat(0)).value, @oracle.binary(0))
}
