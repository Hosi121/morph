// Frozen same-artifact reference and Bareiss cohorts.

///|
fn bareiss_cohort(kind : Int32) -> Array[@matrix.Matrix[@exact.Rational]] {
  match kind {
    0 =>
      [
        bareiss_matrix([
          [bareiss_rat(false, "2", "1"), bareiss_rat(false, "3", "1")],
          [bareiss_rat(false, "5", "1"), bareiss_rat(false, "7", "1")],
        ]),
        bareiss_matrix([
          [
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "0", "1"),
          ],
          [
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "1", "1"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "1", "1"),
          ],
        ]),
      ]
    1 =>
      [
        bareiss_matrix([
          [
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "1", "1"),
          ],
          [
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "4", "1"),
          ],
          [
            bareiss_rat(true, "6", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "2", "1"),
          ],
          [
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(true, "2", "1"),
          ],
          [
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "1", "1"),
          ],
          [
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "1", "1"),
          ],
        ]),
        bareiss_matrix([
          [
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "6", "1"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(true, "6", "1"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "1", "1"),
          ],
          [
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "1", "1"),
          ],
          [
            bareiss_rat(false, "7", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "5", "1"),
          ],
          [
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "2", "1"),
          ],
        ]),
        bareiss_matrix([
          [
            bareiss_rat(true, "5", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(true, "2", "1"),
          ],
          [
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "1", "1"),
          ],
          [
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "5", "1"),
          ],
          [
            bareiss_rat(true, "5", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(false, "2", "1"),
          ],
          [
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "5", "1"),
          ],
          [
            bareiss_rat(true, "5", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(false, "6", "1"),
          ],
        ]),
      ]
    2 =>
      [
        bareiss_matrix([
          [
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "5", "1"),
          ],
          [
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "1", "1"),
          ],
          [
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "5", "1"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "2", "1"),
          ],
          [
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "5", "1"),
          ],
          [
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "7", "1"),
          ],
          [
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "3", "1"),
          ],
          [
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "4", "1"),
          ],
        ]),
        bareiss_matrix([
          [
            bareiss_rat(true, "6", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "3", "1"),
          ],
          [
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "2", "1"),
          ],
          [
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "2", "1"),
          ],
          [
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "3", "1"),
          ],
          [
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "1", "1"),
          ],
          [
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "2", "1"),
          ],
          [
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "1", "1"),
          ],
          [
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "3", "1"),
          ],
        ]),
        bareiss_matrix([
          [
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "1", "1"),
          ],
          [
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "6", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "1", "1"),
          ],
          [
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "4", "1"),
          ],
          [
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "4", "1"),
          ],
          [
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "3", "1"),
          ],
          [
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "6", "1"),
          ],
          [
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "2", "1"),
          ],
          [
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(false, "3", "1"),
          ],
        ]),
      ]
    3 =>
      [
        bareiss_matrix([
          [
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "5", "2"),
            bareiss_rat(true, "4", "7"),
            bareiss_rat(true, "7", "2"),
            bareiss_rat(true, "6", "5"),
          ],
          [
            bareiss_rat(true, "4", "5"),
            bareiss_rat(false, "7", "3"),
            bareiss_rat(true, "1", "7"),
            bareiss_rat(true, "1", "5"),
            bareiss_rat(true, "5", "2"),
            bareiss_rat(true, "6", "5"),
          ],
          [
            bareiss_rat(false, "1", "2"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "1", "5"),
            bareiss_rat(false, "2", "7"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "0", "1"),
          ],
          [
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "6", "7"),
            bareiss_rat(true, "2", "3"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "1", "2"),
            bareiss_rat(true, "1", "3"),
          ],
          [
            bareiss_rat(true, "1", "2"),
            bareiss_rat(true, "6", "7"),
            bareiss_rat(true, "5", "3"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "5", "2"),
          ],
          [
            bareiss_rat(false, "3", "7"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "1", "5"),
            bareiss_rat(true, "3", "5"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "4", "5"),
          ],
        ]),
        bareiss_matrix([
          [
            bareiss_rat(false, "7", "3"),
            bareiss_rat(true, "7", "3"),
            bareiss_rat(true, "4", "5"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "4", "7"),
            bareiss_rat(false, "5", "7"),
          ],
          [
            bareiss_rat(false, "4", "5"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "7", "2"),
            bareiss_rat(false, "7", "5"),
            bareiss_rat(true, "1", "2"),
          ],
          [
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "5", "3"),
            bareiss_rat(false, "4", "3"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "1", "1"),
          ],
          [
            bareiss_rat(false, "5", "7"),
            bareiss_rat(false, "6", "7"),
            bareiss_rat(true, "3", "2"),
            bareiss_rat(false, "6", "5"),
            bareiss_rat(true, "1", "3"),
            bareiss_rat(false, "2", "3"),
          ],
          [
            bareiss_rat(true, "3", "2"),
            bareiss_rat(true, "1", "7"),
            bareiss_rat(true, "7", "2"),
            bareiss_rat(false, "4", "5"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "7", "3"),
          ],
          [
            bareiss_rat(false, "3", "5"),
            bareiss_rat(true, "6", "5"),
            bareiss_rat(false, "1", "2"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "4", "5"),
            bareiss_rat(false, "1", "3"),
          ],
        ]),
        bareiss_matrix([
          [
            bareiss_rat(false, "4", "3"),
            bareiss_rat(true, "3", "7"),
            bareiss_rat(true, "4", "7"),
            bareiss_rat(true, "3", "7"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "1", "3"),
          ],
          [
            bareiss_rat(true, "5", "2"),
            bareiss_rat(true, "4", "3"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "2", "5"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "5", "2"),
          ],
          [
            bareiss_rat(false, "3", "2"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "3", "2"),
            bareiss_rat(false, "4", "7"),
            bareiss_rat(false, "3", "7"),
            bareiss_rat(false, "0", "1"),
          ],
          [
            bareiss_rat(true, "5", "3"),
            bareiss_rat(true, "4", "7"),
            bareiss_rat(true, "5", "7"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "1", "2"),
            bareiss_rat(true, "6", "7"),
          ],
          [
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "2", "3"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "2", "5"),
            bareiss_rat(true, "2", "5"),
            bareiss_rat(false, "3", "2"),
          ],
          [
            bareiss_rat(true, "3", "7"),
            bareiss_rat(false, "6", "5"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "4", "5"),
            bareiss_rat(true, "4", "7"),
            bareiss_rat(true, "2", "7"),
          ],
        ]),
      ]
    4 =>
      [
        bareiss_matrix([
          [
            bareiss_rat(false, "6", "5"),
            bareiss_rat(true, "6", "5"),
            bareiss_rat(false, "1", "3"),
            bareiss_rat(true, "1", "7"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "6", "5"),
            bareiss_rat(false, "2", "5"),
            bareiss_rat(true, "3", "5"),
          ],
          [
            bareiss_rat(false, "4", "3"),
            bareiss_rat(false, "1", "7"),
            bareiss_rat(true, "1", "3"),
            bareiss_rat(true, "7", "3"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "1", "3"),
            bareiss_rat(false, "6", "5"),
            bareiss_rat(true, "4", "7"),
          ],
          [
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "3", "5"),
            bareiss_rat(true, "4", "5"),
            bareiss_rat(false, "1", "5"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "3", "5"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "7", "2"),
          ],
          [
            bareiss_rat(false, "5", "7"),
            bareiss_rat(true, "1", "3"),
            bareiss_rat(false, "7", "3"),
            bareiss_rat(true, "7", "5"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "1", "5"),
            bareiss_rat(false, "1", "3"),
          ],
          [
            bareiss_rat(false, "1", "2"),
            bareiss_rat(false, "2", "5"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "5", "7"),
            bareiss_rat(true, "5", "3"),
            bareiss_rat(true, "4", "3"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "7", "5"),
          ],
          [
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "2", "7"),
            bareiss_rat(true, "4", "3"),
            bareiss_rat(false, "4", "5"),
            bareiss_rat(true, "4", "3"),
            bareiss_rat(true, "5", "7"),
            bareiss_rat(false, "6", "5"),
            bareiss_rat(false, "0", "1"),
          ],
          [
            bareiss_rat(false, "7", "3"),
            bareiss_rat(false, "4", "5"),
            bareiss_rat(true, "2", "5"),
            bareiss_rat(true, "7", "3"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "1", "7"),
            bareiss_rat(false, "3", "2"),
          ],
          [
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "2", "7"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "5", "7"),
            bareiss_rat(false, "4", "7"),
            bareiss_rat(false, "1", "7"),
            bareiss_rat(true, "6", "5"),
            bareiss_rat(false, "1", "2"),
          ],
        ]),
        bareiss_matrix([
          [
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "1", "2"),
            bareiss_rat(false, "5", "2"),
            bareiss_rat(false, "3", "2"),
            bareiss_rat(true, "1", "7"),
            bareiss_rat(false, "3", "5"),
            bareiss_rat(false, "7", "3"),
            bareiss_rat(true, "6", "5"),
          ],
          [
            bareiss_rat(false, "4", "7"),
            bareiss_rat(false, "1", "2"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "1", "5"),
            bareiss_rat(true, "4", "3"),
            bareiss_rat(false, "3", "7"),
            bareiss_rat(false, "4", "5"),
          ],
          [
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "5", "2"),
            bareiss_rat(true, "6", "5"),
            bareiss_rat(true, "4", "5"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "3", "2"),
            bareiss_rat(false, "4", "5"),
          ],
          [
            bareiss_rat(true, "3", "2"),
            bareiss_rat(true, "5", "7"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "4", "5"),
            bareiss_rat(false, "7", "3"),
            bareiss_rat(false, "6", "7"),
            bareiss_rat(false, "5", "2"),
            bareiss_rat(true, "1", "2"),
          ],
          [
            bareiss_rat(true, "3", "5"),
            bareiss_rat(false, "1", "5"),
            bareiss_rat(false, "3", "2"),
            bareiss_rat(false, "3", "7"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "2", "5"),
            bareiss_rat(false, "2", "3"),
            bareiss_rat(false, "1", "1"),
          ],
          [
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "5", "3"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "4", "3"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "3", "7"),
            bareiss_rat(false, "1", "1"),
          ],
          [
            bareiss_rat(true, "5", "3"),
            bareiss_rat(true, "2", "5"),
            bareiss_rat(false, "6", "5"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "6", "7"),
            bareiss_rat(true, "1", "1"),
          ],
          [
            bareiss_rat(true, "2", "5"),
            bareiss_rat(true, "6", "5"),
            bareiss_rat(true, "3", "2"),
            bareiss_rat(false, "2", "7"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "0", "1"),
          ],
        ]),
        bareiss_matrix([
          [
            bareiss_rat(true, "6", "7"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "4", "5"),
            bareiss_rat(true, "4", "7"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "6", "7"),
            bareiss_rat(false, "4", "3"),
          ],
          [
            bareiss_rat(false, "2", "7"),
            bareiss_rat(true, "2", "3"),
            bareiss_rat(true, "3", "2"),
            bareiss_rat(true, "2", "3"),
            bareiss_rat(true, "5", "2"),
            bareiss_rat(false, "3", "7"),
            bareiss_rat(true, "2", "7"),
            bareiss_rat(false, "7", "2"),
          ],
          [
            bareiss_rat(false, "1", "3"),
            bareiss_rat(false, "3", "5"),
            bareiss_rat(true, "1", "7"),
            bareiss_rat(true, "3", "7"),
            bareiss_rat(true, "1", "5"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "4", "3"),
            bareiss_rat(true, "1", "1"),
          ],
          [
            bareiss_rat(false, "7", "5"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "1", "7"),
            bareiss_rat(false, "5", "7"),
            bareiss_rat(true, "2", "3"),
            bareiss_rat(false, "2", "7"),
            bareiss_rat(false, "4", "3"),
            bareiss_rat(false, "1", "1"),
          ],
          [
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "5", "2"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "4", "3"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "2", "5"),
            bareiss_rat(false, "1", "2"),
          ],
          [
            bareiss_rat(true, "3", "5"),
            bareiss_rat(false, "4", "3"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "1", "5"),
            bareiss_rat(false, "5", "2"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "1", "1"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "7", "3"),
            bareiss_rat(false, "4", "7"),
            bareiss_rat(true, "1", "3"),
            bareiss_rat(false, "7", "5"),
            bareiss_rat(true, "5", "3"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "4", "3"),
          ],
          [
            bareiss_rat(true, "1", "5"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "5", "3"),
            bareiss_rat(true, "5", "3"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "3", "5"),
            bareiss_rat(true, "7", "3"),
            bareiss_rat(true, "1", "1"),
          ],
        ]),
      ]
    5 =>
      [
        bareiss_matrix([
          [
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "5", "1"),
          ],
          [
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "1", "1"),
          ],
          [
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "5", "1"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "2", "1"),
          ],
          [
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "5", "1"),
          ],
          [
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "7", "1"),
          ],
          [
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "3", "1"),
          ],
          [
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "5", "1"),
          ],
        ]),
        bareiss_matrix([
          [
            bareiss_rat(true, "6", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "3", "1"),
          ],
          [
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "2", "1"),
          ],
          [
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "2", "1"),
          ],
          [
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "3", "1"),
          ],
          [
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "1", "1"),
          ],
          [
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "2", "1"),
          ],
          [
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "1", "1"),
          ],
          [
            bareiss_rat(true, "6", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "3", "1"),
          ],
        ]),
        bareiss_matrix([
          [
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "1", "1"),
          ],
          [
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "6", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "1", "1"),
          ],
          [
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "4", "1"),
          ],
          [
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "4", "1"),
          ],
          [
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "3", "1"),
          ],
          [
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "6", "1"),
          ],
          [
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "2", "1"),
          ],
          [
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "1", "1"),
          ],
        ]),
      ]
    6 =>
      [
        bareiss_matrix([
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "5", "1"),
          ],
          [
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "1", "1"),
          ],
          [
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "5", "1"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "2", "1"),
          ],
          [
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "5", "1"),
          ],
          [
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "7", "1"),
          ],
          [
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "3", "1"),
          ],
          [
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "4", "1"),
          ],
        ]),
        bareiss_matrix([
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "3", "1"),
          ],
          [
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "2", "1"),
          ],
          [
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "2", "1"),
          ],
          [
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "3", "1"),
          ],
          [
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "1", "1"),
          ],
          [
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "2", "1"),
          ],
          [
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "1", "1"),
          ],
          [
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "3", "1"),
          ],
        ]),
        bareiss_matrix([
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "1", "1"),
          ],
          [
            bareiss_rat(true, "5", "1"),
            bareiss_rat(false, "6", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "1", "1"),
          ],
          [
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "4", "1"),
          ],
          [
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "4", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "4", "1"),
          ],
          [
            bareiss_rat(true, "2", "1"),
            bareiss_rat(true, "7", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "3", "1"),
          ],
          [
            bareiss_rat(true, "4", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "6", "1"),
          ],
          [
            bareiss_rat(false, "3", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "4", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "2", "1"),
          ],
          [
            bareiss_rat(false, "6", "1"),
            bareiss_rat(false, "5", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "7", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "6", "1"),
            bareiss_rat(false, "3", "1"),
          ],
        ]),
      ]
    7 =>
      [
        bareiss_matrix([
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "6", "5"),
            bareiss_rat(false, "1", "3"),
            bareiss_rat(true, "1", "7"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "6", "5"),
            bareiss_rat(false, "2", "5"),
            bareiss_rat(true, "3", "5"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "1", "7"),
            bareiss_rat(true, "1", "3"),
            bareiss_rat(true, "7", "3"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "1", "3"),
            bareiss_rat(false, "6", "5"),
            bareiss_rat(true, "4", "7"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "3", "5"),
            bareiss_rat(true, "4", "5"),
            bareiss_rat(false, "1", "5"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "3", "5"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "7", "2"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "1", "3"),
            bareiss_rat(false, "7", "3"),
            bareiss_rat(true, "7", "5"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "1", "5"),
            bareiss_rat(false, "1", "3"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "2", "5"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "5", "7"),
            bareiss_rat(true, "5", "3"),
            bareiss_rat(true, "4", "3"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "7", "5"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "2", "7"),
            bareiss_rat(true, "4", "3"),
            bareiss_rat(false, "4", "5"),
            bareiss_rat(true, "4", "3"),
            bareiss_rat(true, "5", "7"),
            bareiss_rat(false, "6", "5"),
            bareiss_rat(false, "0", "1"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "4", "5"),
            bareiss_rat(true, "2", "5"),
            bareiss_rat(true, "7", "3"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "1", "7"),
            bareiss_rat(false, "3", "2"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "2", "7"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "5", "7"),
            bareiss_rat(false, "4", "7"),
            bareiss_rat(false, "1", "7"),
            bareiss_rat(true, "6", "5"),
            bareiss_rat(false, "1", "2"),
          ],
        ]),
        bareiss_matrix([
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "1", "2"),
            bareiss_rat(false, "5", "2"),
            bareiss_rat(false, "3", "2"),
            bareiss_rat(true, "1", "7"),
            bareiss_rat(false, "3", "5"),
            bareiss_rat(false, "7", "3"),
            bareiss_rat(true, "6", "5"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "1", "2"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "1", "5"),
            bareiss_rat(true, "4", "3"),
            bareiss_rat(false, "3", "7"),
            bareiss_rat(false, "4", "5"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "5", "2"),
            bareiss_rat(true, "6", "5"),
            bareiss_rat(true, "4", "5"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "3", "2"),
            bareiss_rat(false, "4", "5"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "5", "7"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "4", "5"),
            bareiss_rat(false, "7", "3"),
            bareiss_rat(false, "6", "7"),
            bareiss_rat(false, "5", "2"),
            bareiss_rat(true, "1", "2"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "1", "5"),
            bareiss_rat(false, "3", "2"),
            bareiss_rat(false, "3", "7"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "2", "5"),
            bareiss_rat(false, "2", "3"),
            bareiss_rat(false, "1", "1"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "5", "3"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "4", "3"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "3", "7"),
            bareiss_rat(false, "1", "1"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "2", "5"),
            bareiss_rat(false, "6", "5"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "6", "7"),
            bareiss_rat(true, "1", "1"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "6", "5"),
            bareiss_rat(true, "3", "2"),
            bareiss_rat(false, "2", "7"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "0", "1"),
          ],
        ]),
        bareiss_matrix([
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(true, "4", "5"),
            bareiss_rat(true, "4", "7"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(true, "6", "7"),
            bareiss_rat(false, "4", "3"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "2", "3"),
            bareiss_rat(true, "3", "2"),
            bareiss_rat(true, "2", "3"),
            bareiss_rat(true, "5", "2"),
            bareiss_rat(false, "3", "7"),
            bareiss_rat(true, "2", "7"),
            bareiss_rat(false, "7", "2"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "3", "5"),
            bareiss_rat(true, "1", "7"),
            bareiss_rat(true, "3", "7"),
            bareiss_rat(true, "1", "5"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "4", "3"),
            bareiss_rat(true, "1", "1"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "3", "1"),
            bareiss_rat(true, "1", "7"),
            bareiss_rat(false, "5", "7"),
            bareiss_rat(true, "2", "3"),
            bareiss_rat(false, "2", "7"),
            bareiss_rat(false, "4", "3"),
            bareiss_rat(false, "1", "1"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "5", "2"),
            bareiss_rat(false, "1", "1"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(false, "4", "3"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "2", "5"),
            bareiss_rat(false, "1", "2"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "4", "3"),
            bareiss_rat(false, "2", "1"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "1", "5"),
            bareiss_rat(false, "5", "2"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "1", "1"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(false, "7", "3"),
            bareiss_rat(false, "4", "7"),
            bareiss_rat(true, "1", "3"),
            bareiss_rat(false, "7", "5"),
            bareiss_rat(true, "5", "3"),
            bareiss_rat(true, "2", "1"),
            bareiss_rat(false, "4", "3"),
          ],
          [
            bareiss_rat(false, "0", "1"),
            bareiss_rat(true, "3", "1"),
            bareiss_rat(false, "5", "3"),
            bareiss_rat(true, "5", "3"),
            bareiss_rat(true, "1", "1"),
            bareiss_rat(false, "3", "5"),
            bareiss_rat(true, "7", "3"),
            bareiss_rat(true, "1", "1"),
          ],
        ]),
      ]
    _ => []
  }
}

///|
test "reference_small" (b : @bench.T) {
  let matrices = bareiss_cohort(0)
  b.bench(name="reference_small", count=5, fn() {
    for matrix in matrices {
      b.keep(bareiss_frozen_reference(matrix))
    }
  })
}

///|
test "Bareiss_small" (b : @bench.T) {
  let matrices = bareiss_cohort(0)
  b.bench(name="Bareiss_small", count=5, fn() {
    for matrix in matrices {
      b.keep(determinant(matrix))
    }
  })
}

///|
test "reference_integer6" (b : @bench.T) {
  let matrices = bareiss_cohort(1)
  b.bench(name="reference_integer6", count=5, fn() {
    for matrix in matrices {
      b.keep(bareiss_frozen_reference(matrix))
    }
  })
}

///|
test "Bareiss_integer6" (b : @bench.T) {
  let matrices = bareiss_cohort(1)
  b.bench(name="Bareiss_integer6", count=5, fn() {
    for matrix in matrices {
      b.keep(determinant(matrix))
    }
  })
}

///|
test "reference_integer8" (b : @bench.T) {
  let matrices = bareiss_cohort(2)
  b.bench(name="reference_integer8", count=5, fn() {
    for matrix in matrices {
      b.keep(bareiss_frozen_reference(matrix))
    }
  })
}

///|
test "Bareiss_integer8" (b : @bench.T) {
  let matrices = bareiss_cohort(2)
  b.bench(name="Bareiss_integer8", count=5, fn() {
    for matrix in matrices {
      b.keep(determinant(matrix))
    }
  })
}

///|
test "reference_rational6" (b : @bench.T) {
  let matrices = bareiss_cohort(3)
  b.bench(name="reference_rational6", count=5, fn() {
    for matrix in matrices {
      b.keep(bareiss_frozen_reference(matrix))
    }
  })
}

///|
test "Bareiss_rational6" (b : @bench.T) {
  let matrices = bareiss_cohort(3)
  b.bench(name="Bareiss_rational6", count=5, fn() {
    for matrix in matrices {
      b.keep(determinant(matrix))
    }
  })
}

///|
test "reference_rational8" (b : @bench.T) {
  let matrices = bareiss_cohort(4)
  b.bench(name="reference_rational8", count=5, fn() {
    for matrix in matrices {
      b.keep(bareiss_frozen_reference(matrix))
    }
  })
}

///|
test "Bareiss_rational8" (b : @bench.T) {
  let matrices = bareiss_cohort(4)
  b.bench(name="Bareiss_rational8", count=5, fn() {
    for matrix in matrices {
      b.keep(determinant(matrix))
    }
  })
}

///|
test "reference_singular8" (b : @bench.T) {
  let matrices = bareiss_cohort(5)
  b.bench(name="reference_singular8", count=5, fn() {
    for matrix in matrices {
      b.keep(bareiss_frozen_reference(matrix))
    }
  })
}

///|
test "Bareiss_singular8" (b : @bench.T) {
  let matrices = bareiss_cohort(5)
  b.bench(name="Bareiss_singular8", count=5, fn() {
    for matrix in matrices {
      b.keep(determinant(matrix))
    }
  })
}

///|
test "reference_pivot8" (b : @bench.T) {
  let matrices = bareiss_cohort(6)
  b.bench(name="reference_pivot8", count=5, fn() {
    for matrix in matrices {
      b.keep(bareiss_frozen_reference(matrix))
    }
  })
}

///|
test "Bareiss_pivot8" (b : @bench.T) {
  let matrices = bareiss_cohort(6)
  b.bench(name="Bareiss_pivot8", count=5, fn() {
    for matrix in matrices {
      b.keep(determinant(matrix))
    }
  })
}

///|
test "reference_earlyzero8" (b : @bench.T) {
  let matrices = bareiss_cohort(7)
  b.bench(name="reference_earlyzero8", count=5, fn() {
    for matrix in matrices {
      b.keep(bareiss_frozen_reference(matrix))
    }
  })
}

///|
test "Bareiss_earlyzero8" (b : @bench.T) {
  let matrices = bareiss_cohort(7)
  b.bench(name="Bareiss_earlyzero8", count=5, fn() {
    for matrix in matrices {
      b.keep(determinant(matrix))
    }
  })
}
