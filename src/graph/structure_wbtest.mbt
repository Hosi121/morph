///|
test "SCC and topological ordering exhaust all directed three-vertex graphs" {
  for mask in 0..<512 {
    let es = []
    let reach = Array::make(3, 0).map(fn(_) { Array::make(3, false) })
    for i in 0..<3 {
      reach[i][i] = true
      for j in 0..<3 {
        if (mask & (1 << (i * 3 + j))) != 0 {
          es.push((i, j, 1))
          reach[i][j] = true
        }
      }
    }
    for k in 0..<3 {
      for i in 0..<3 {
        for j in 0..<3 {
          reach[i][j] = reach[i][j] || (reach[i][k] && reach[k][j])
        }
      }
    }
    let g = make_graph(3, es)
    let components = @oracle.array(strongly_connected(g)).map(fn(xs) {
      @oracle.array(xs).map(@oracle.int_of_nat)
    })
    let group = Array::make(3, -1)
    for k, members in components {
      assert_false(members.is_empty())
      for v in members {
        assert_eq(group[v], -1)
        group[v] = k
      }
    }
    for i in 0..<3 {
      assert_true(group[i] >= 0)
      for j in 0..<3 {
        assert_eq(group[i] == group[j], reach[i][j] && reach[j][i])
      }
    }
    let permutations = [
      [0, 1, 2],
      [0, 2, 1],
      [1, 0, 2],
      [1, 2, 0],
      [2, 0, 1],
      [2, 1, 0],
    ]
    fn legal(order : Array[Int32]) -> Bool {
      let positions = Array::make(3, 0)
      for index, v in order {
        positions[v] = index
      }
      es.all(fn(edge) { positions[edge.0] < positions[edge.1] })
    }
    match topological(g) {
      None => assert_false(permutations.any(legal))
      Some(order) => {
        let values = @oracle.array(order).map(@oracle.int_of_nat)
        assert_eq(values.length(), 3)
        let sorted = values.copy()
        sorted.sort()
        assert_eq(sorted, [0, 1, 2])
        assert_true(legal(values))
      }
    }
    assert_eq(transpose(transpose(g)), g)
  }
  assert_eq(topological(make_graph(0, [])), Some(Nil))
  assert_eq(strongly_connected(make_graph(0, [])), Nil)
}
