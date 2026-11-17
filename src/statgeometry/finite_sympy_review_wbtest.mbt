// Independent Sympy log-partition/coordinate-calculus oracle; generated in scratch.

///|
type IRRat = (Bool, String, String)

///|
fn ir_q(value : IRRat) -> @exact.Rational {
  let (negative, n, d) = value
  let numerator = @exact.positive(@oracle.binary_from_hex(n))
  let numerator = if negative { @exact.negate(numerator) } else { numerator }
  @exact.ratio(numerator, @oracle.binary_from_hex(d)).unwrap()
}

///|
fn ir_values(values : Array[IRRat]) -> @core.Chain[@exact.Rational] {
  @oracle.chain(values.map(ir_q))
}

///|
fn ir_matrix(
  values : Array[IRRat],
  width : Int32,
) -> @matrix.Matrix[@exact.Rational] {
  let rows = Array::makei(width, fn(i) {
    @oracle.chain(Array::makei(width, fn(j) { ir_q(values[i * width + j]) }))
  })
  @matrix.matrix(@oracle.nat(width), @oracle.chain(rows)).unwrap()
}

///|
fn ir_flat_matrix(
  value : @matrix.Matrix[@exact.Rational],
) -> @core.Chain[@exact.Rational] {
  @core.fold_left(@matrix.rows(value), @core.Nil, @core.append)
}

///|
fn ir_flat_first(
  value : @core.Chain[@matrix.Matrix[@exact.Rational]],
) -> @core.Chain[@exact.Rational] {
  @core.fold_left(value, @core.Nil, fn(result, matrix) {
    @core.append(result, ir_flat_matrix(matrix))
  })
}

///|
fn ir_flat_second(
  value : @core.Chain[@core.Chain[@matrix.Matrix[@exact.Rational]]],
) -> @core.Chain[@exact.Rational] {
  @core.fold_left(value, @core.Nil, fn(result, row) {
    @core.append(result, ir_flat_first(row))
  })
}

///|
struct IRTerm {
  coefficient : IRRat
  exponents : Array[Int32]
}

///|
struct IRJet {
  p : IRRat
  gradient : Array[IRRat]
  hessian : Array[IRRat]
  third : Array[IRRat]
}

///|
struct IRAlpha {
  alpha : IRRat
  lower : Array[IRRat]
  lower_first : Array[IRRat]
  coefficients : Array[IRRat]
  derivatives : Array[IRRat]
  riemann : Array[IRRat]
  lowered : Array[IRRat]
  ricci : Array[IRRat]
  scalar : IRRat
}

///|
struct IRFinite {
  name : String
  point : Array[IRRat]
  polynomials : Array[Array[IRTerm]]
  jets : Array[IRJet]
  metric : Array[IRRat]
  first : Array[IRRat]
  second : Array[IRRat]
  cubic : Array[IRRat]
  scores : Array[IRRat]
  natural_gradient : Array[IRRat]
  cubic_pullback : IRRat
  alphas : Array[IRAlpha]
}

///|
fn ir_finites() -> Array[IRFinite] {
  [
    {
      name: "four_outcome_0",
      point: [(false, "1", "3"), (true, "1", "4")],
      polynomials: [
        [
          { coefficient: (false, "1", "3c"), exponents: [2, 1], },
          { coefficient: (false, "1", "28"), exponents: [2, 0], },
          { coefficient: (false, "1", "1e"), exponents: [1, 1], },
          { coefficient: (false, "1", "a"), exponents: [1, 0], },
          { coefficient: (false, "1", "14"), exponents: [0, 1], },
          { coefficient: (false, "1", "4"), exponents: [0, 0], },
        ],
        [
          { coefficient: (false, "1", "46"), exponents: [1, 2], },
          { coefficient: (true, "1", "c"), exponents: [1, 0], },
          { coefficient: (true, "1", "32"), exponents: [0, 2], },
          { coefficient: (false, "1", "f"), exponents: [0, 1], },
          { coefficient: (false, "1", "5"), exponents: [0, 0], },
        ],
        [
          { coefficient: (true, "1", "50"), exponents: [3, 0], },
          { coefficient: (false, "1", "23"), exponents: [1, 1], },
          { coefficient: (false, "1", "19"), exponents: [1, 0], },
          { coefficient: (true, "1", "9"), exponents: [0, 1], },
          { coefficient: (false, "3", "a"), exponents: [0, 0], },
        ],
        [
          { coefficient: (false, "1", "50"), exponents: [3, 0], },
          { coefficient: (true, "1", "3c"), exponents: [2, 1], },
          { coefficient: (true, "1", "28"), exponents: [2, 0], },
          { coefficient: (true, "1", "46"), exponents: [1, 2], },
          { coefficient: (true, "d", "d2"), exponents: [1, 1], },
          { coefficient: (true, "11", "12c"), exponents: [1, 0], },
          { coefficient: (false, "1", "32"), exponents: [0, 2], },
          { coefficient: (true, "1", "b4"), exponents: [0, 1], },
          { coefficient: (false, "1", "4"), exponents: [0, 0], },
        ],
      ],
      jets: [
        {
          p: (false, "49", "10e"),
          gradient: [(false, "13", "b4"), (false, "11", "10e")],
          hessian: [
            (false, "1", "18"),
            (false, "2", "2d"),
            (false, "2", "2d"),
            (false, "0", "1"),
          ],
          third: [
            (false, "0", "1"),
            (false, "1", "1e"),
            (false, "1", "1e"),
            (false, "0", "1"),
            (false, "1", "1e"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
          ],
        },
        {
          p: (false, "1e7", "c4e"),
          gradient: [(true, "115", "d20"), (false, "d", "af")],
          hessian: [
            (false, "0", "1"),
            (true, "1", "8c"),
            (true, "1", "8c"),
            (true, "10", "20d"),
          ],
          third: [
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "1", "23"),
            (false, "0", "1"),
            (false, "1", "23"),
            (false, "1", "23"),
            (false, "0", "1"),
          ],
        },
        {
          p: (false, "63e5", "12750"),
          gradient: [(false, "f1", "20d0"), (true, "20", "13b")],
          hessian: [
            (true, "1", "28"),
            (false, "1", "23"),
            (false, "1", "23"),
            (false, "0", "1"),
          ],
          third: [
            (true, "3", "28"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
          ],
        },
        {
          p: (false, "9fd", "2a30"),
          gradient: [(true, "175", "1c20"), (true, "151", "24ea")],
          hessian: [
            (true, "1", "3c"),
            (true, "53", "4ec"),
            (true, "53", "4ec"),
            (false, "10", "20d"),
          ],
          third: [
            (false, "3", "28"),
            (true, "1", "1e"),
            (true, "1", "1e"),
            (true, "1", "23"),
            (true, "1", "1e"),
            (true, "1", "23"),
            (true, "1", "23"),
            (false, "0", "1"),
          ],
        },
      ],
      metric: [
        (false, "1f60c6e234ede5", "13d24b5086fca00"),
        (true, "34c280d5016c7", "d02016cd895c90"),
        (true, "34c280d5016c7", "d02016cd895c90"),
        (false, "2f1d02021e98cf", "222543bdb8892fa"),
      ],
      first: [
        (false, "a1b1345f65eac6b46123aced", "df82cdb638758dbf9cb1f2000"),
        (false, "17075abb71882e26c29ded0f", "30e49cffdc59b701ea46ecf00"),
        (false, "17075abb71882e26c29ded0f", "30e49cffdc59b701ea46ecf00"),
        (false, "2bc3816850dbfd4c935cb4af", "60421517b9d0a04bc53ba2788"),
        (false, "6ffa3f037971ade2dd59f4b9", "92add6ff950d2505bed4c6d00"),
        (false, "929082c754a850e80d4193f", "13406a9e585cecdbf43f207e8"),
        (false, "929082c754a850e80d4193f", "13406a9e585cecdbf43f207e8"),
        (true, "843badba1d6c8d0a47d924f9", "a873a4e9852d188499285c52e"),
      ],
      second: [
        (
          true, "381c8dc5ab3e444b3c2140018ba6be9d939", "ec488cf468adf343c38783feddb1cd170000",
        ),
        (
          false, "111548cf789cceebda150c5a98900fb986d", "33afded576e60d36d2c5a4dfc07ee4dd0800",
        ),
        (
          false, "111548cf789cceebda150c5a98900fb986d", "33afded576e60d36d2c5a4dfc07ee4dd0800",
        ),
        (
          false, "3462ef846b28a1595e29d8f73e5821552a5", "21eb6a3c1606f8abfa51b432d65346310d40",
        ),
        (
          false, "1a5039c293c82e96f36a8f6f02328e417b3", "33afded576e60d36d2c5a4dfc07ee4dd0800",
        ),
        (
          false, "1d8851261072b1a65ffbdbfd618ae784537", "21eb6a3c1606f8abfa51b432d65346310d40",
        ),
        (
          false, "1d8851261072b1a65ffbdbfd618ae784537", "21eb6a3c1606f8abfa51b432d65346310d40",
        ),
        (
          true, "a4aa50b13df15f4e7662b8c4b7d96ba2d", "239d95f24a541eb493a296cefaa43ce6b45",
        ),
        (
          false, "1a5039c293c82e96f36a8f6f02328e417b3", "33afded576e60d36d2c5a4dfc07ee4dd0800",
        ),
        (
          false, "1d8851261072b1a65ffbdbfd618ae784537", "21eb6a3c1606f8abfa51b432d65346310d40",
        ),
        (
          false, "1d8851261072b1a65ffbdbfd618ae784537", "21eb6a3c1606f8abfa51b432d65346310d40",
        ),
        (
          true, "a4aa50b13df15f4e7662b8c4b7d96ba2d", "239d95f24a541eb493a296cefaa43ce6b45",
        ),
        (
          false, "2077f2ec2d3181ec4b5839291e64448e8c9", "21eb6a3c1606f8abfa51b432d65346310d40",
        ),
        (
          true, "7ab1524600173283e030086792c12cf192", "b213edbb73a49986e22cf20ae5353081859",
        ),
        (
          true, "7ab1524600173283e030086792c12cf192", "b213edbb73a49986e22cf20ae5353081859",
        ),
        (
          false, "119fb366ef40d761e784466b03bd9ccdbf93", "e9ba280607c8098108dafdae4cd5cfa9ff4d",
        ),
      ],
      cubic: [
        (true, "226d238f7f05a49cf34c00ed", "df82cdb638758dbf9cb1f2000"),
        (false, "161fca33a7251761b2c6beb5", "30e49cffdc59b701ea46ecf00"),
        (false, "161fca33a7251761b2c6beb5", "30e49cffdc59b701ea46ecf00"),
        (true, "61b80d1d687b5b1202d26bd", "20160707e89ae01941be8b7d8"),
        (false, "161fca33a7251761b2c6beb5", "30e49cffdc59b701ea46ecf00"),
        (true, "61b80d1d687b5b1202d26bd", "20160707e89ae01941be8b7d8"),
        (true, "61b80d1d687b5b1202d26bd", "20160707e89ae01941be8b7d8"),
        (false, "1c8d967526e1db431be5a679", "a873a4e9852d188499285c52e"),
      ],
      natural_gradient: [
        (false, "a27c4c9fa3afdce0", "1b25376ff4f1de11"),
        (true, "2a832a6d14de16fd", "90c67cffc509f5b"),
      ],
      scores: [
        (false, "39", "92"),
        (false, "11", "49"),
        (true, "103b", "1e70"),
        (false, "ea", "1e7"),
        (false, "879", "63e5"),
        (true, "1e00", "63e5"),
        (true, "45f", "13fa"),
        (true, "a88", "45eb"),
      ],
      cubic_pullback: (
        true, "3c116c51a8e73e5843f3e14bdfa71", "8e219325085e0cafe13a0de5ed0000",
      ),
      alphas: [
        {
          alpha: (false, "0", "1"),
          scalar: (
            true, "12d8d0d3753e62b44555bd624c7afd8", "51dfe6855658c639d3c24924122a59",
          ),
          lower: [
            (false, "a1b1345f65eac6b46123aced", "1bf059b6c70eb1b7f3963e4000"),
            (false, "3bdfba02b647c6e87315f17", "29e886922a960a93ed615d600"),
            (false, "6ffa3f037971ade2dd59f4b9", "1255badff2a1a4a0b7da98da00"),
            (false, "2bc3816850dbfd4c935cb4af", "c0842a2f73a140978a7744f10"),
            (false, "6ffa3f037971ade2dd59f4b9", "1255badff2a1a4a0b7da98da00"),
            (false, "2bc3816850dbfd4c935cb4af", "c0842a2f73a140978a7744f10"),
            (false, "ff245716c046716d1a417ed", "402c0e0fd135c032837d16fb0"),
            (true, "843badba1d6c8d0a47d924f9", "150e749d30a5a31093250b8a5c"),
          ],
          lower_first: [
            (
              true, "381c8dc5ab3e444b3c2140018ba6be9d939", "1d89119e8d15be687870f07fdbb639a2e0000",
            ),
            (
              false, "7da57dc5d716f40c0bf89462eed9131927", "675fbdaaedcc1a6da58b49bf80fdc9ba1000",
            ),
            (
              false, "1a5039c293c82e96f36a8f6f02328e417b3", "675fbdaaedcc1a6da58b49bf80fdc9ba1000",
            ),
            (
              false, "3462ef846b28a1595e29d8f73e5821552a5", "43d6d4782c0df157f4a36865aca68c621a80",
            ),
            (
              false, "1a5039c293c82e96f36a8f6f02328e417b3", "675fbdaaedcc1a6da58b49bf80fdc9ba1000",
            ),
            (
              false, "3462ef846b28a1595e29d8f73e5821552a5", "43d6d4782c0df157f4a36865aca68c621a80",
            ),
            (
              false, "155f08e578c26ca46c2c633e75922bd7f5", "d915db1a2693044ca8714e12287b5ad3880",
            ),
            (
              true, "a4aa50b13df15f4e7662b8c4b7d96ba2d", "473b2be494a83d6927452d9df54879cd68a",
            ),
            (
              false, "1a5039c293c82e96f36a8f6f02328e417b3", "675fbdaaedcc1a6da58b49bf80fdc9ba1000",
            ),
            (
              false, "8dd8fcaa6914b2026dfd4f08c3b2e28b37", "169cf17d6404a5c7fc367821e4378420b380",
            ),
            (
              false, "2077f2ec2d3181ec4b5839291e64448e8c9", "43d6d4782c0df157f4a36865aca68c621a80",
            ),
            (
              true, "a4aa50b13df15f4e7662b8c4b7d96ba2d", "473b2be494a83d6927452d9df54879cd68a",
            ),
            (
              false, "2077f2ec2d3181ec4b5839291e64448e8c9", "43d6d4782c0df157f4a36865aca68c621a80",
            ),
            (
              true, "a4aa50b13df15f4e7662b8c4b7d96ba2d", "473b2be494a83d6927452d9df54879cd68a",
            ),
            (
              true, "c1ed6b549cd2f73f3b613711ac0e684043", "16427db76e749330dc459e415ca6a61030b2",
            ),
            (
              false, "119fb366ef40d761e784466b03bd9ccdbf93", "1d374500c0f90130211b5fb5c99ab9f53fe9a",
            ),
          ],
          coefficients: [
            (
              false, "eb67317e5af71f9b346f6c0d351", "3bc8d906779607406801f84bb9a0",
            ),
            (false, "d24e7beab1b7789295937ec9cb", "7791b20cef2c0e80d003f097734"),
            (
              false, "39abfa8137e8310de92816d4407", "d13ef796a28d19616c06e50909b",
            ),
            (
              false, "19c117a1a2cef9055152e172d03", "7791b20cef2c0e80d003f097734",
            ),
            (
              false, "39abfa8137e8310de92816d4407", "d13ef796a28d19616c06e50909b",
            ),
            (
              false, "19c117a1a2cef9055152e172d03", "7791b20cef2c0e80d003f097734",
            ),
            (
              false, "1f8711b6a1b6202f988e402ee590", "112a2a4f5b559314fddc90c9bdcb7",
            ),
            (
              true, "6e38056c4ee3b67e0b5f05ffa4b", "1a27def2d451a32c2d80dca12136",
            ),
          ],
          derivatives: [
            (
              true, "adec7a1345444427936adf0894ff645fd607d3fb2f394c56199f", "2dbfeb11c82a81243f206de4d44d5a9e6f07845d4a16f44767200",
            ),
            (
              true, "1f1e12ceb20b5a6294d46a06fb2e1cfeeda617aa0388f7dcb6257", "11def7d2f2309a7228a8aaed62ee3765e35eefb470f0f76be44880",
            ),
            (
              false, "1400a871d786ed17834dc6d648bd99bc51daf5c5c1f5e94db295", "23bdefa5e46134e4515155dac5dc6ecbc6bddf68e1e1eed7c8910",
            ),
            (
              false, "b778c4eef2f27253c306a4de1405eeb65119e1cc86c4a0d1e8b", "1c97f2eb1d1a90b6a77444af04b058a30564b2ba4e4e58aca074",
            ),
            (
              false, "1400a871d786ed17834dc6d648bd99bc51daf5c5c1f5e94db295", "23bdefa5e46134e4515155dac5dc6ecbc6bddf68e1e1eed7c8910",
            ),
            (
              false, "b778c4eef2f27253c306a4de1405eeb65119e1cc86c4a0d1e8b", "1c97f2eb1d1a90b6a77444af04b058a30564b2ba4e4e58aca074",
            ),
            (
              false, "14597baeed4083a3ef776c9b0701adeb8c710a6f0c512096542e", "fa318d893ea8723e393958fb690707926f311bde2d2d87e67bf7",
            ),
            (
              true, "2a350ba1880632107c7d2b4e6a2a8a55e5058050e88f8f7d0549", "3e8c63624faa1c8f8e4e563eda41c1e49bcc46f78b4b61f99efdc",
            ),
            (
              false, "d259690c4090cde2e5345c2b9e6cac469d229b98dfb73802d65b", "fa318d893ea8723e393958fb690707926f311bde2d2d87e67bf70",
            ),
            (
              false, "26cfbcde548fce610ff20d610931c58989a7875355d35a51a5a15", "8ef7be979184d3914545576b1771bb2f1af77da38787bb5f22440",
            ),
            (
              false, "a6937d03b9af8fc11321777ca684e841c017903a58f4b4e9edca", "6d75adec0b69b1fb390916edfdf3135010a57c3133c3eb74d63c1",
            ),
            (
              true, "3bca3f1d5efe46a0100226625279e85dfd0ef91d0d0f0535c25b", "3e8c63624faa1c8f8e4e563eda41c1e49bcc46f78b4b61f99efdc",
            ),
            (
              false, "a6937d03b9af8fc11321777ca684e841c017903a58f4b4e9edca", "6d75adec0b69b1fb390916edfdf3135010a57c3133c3eb74d63c1",
            ),
            (
              true, "3bca3f1d5efe46a0100226625279e85dfd0ef91d0d0f0535c25b", "3e8c63624faa1c8f8e4e563eda41c1e49bcc46f78b4b61f99efdc",
            ),
            (
              true, "29847766130e896610a57439bc566498174d324e34e1bb02fc3650", "8faa7445cefab999badbee185d4f095915d9330093f12509592ed5",
            ),
            (
              false, "2a9dfcdc173b11f32c6bd915b4f7eb9805f466109f2292db56241", "daeb5bd816d363f672122ddbfbe626a0214af8626787d6e9ac782",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              false, "8d6b8cb30de9df6c3a83ff19f6ea17e5a5a462bd", "12eefc2eaf76718f44e4926c9ca7ced3f6b91a3004",
            ),
            (
              true, "8d6b8cb30de9df6c3a83ff19f6ea17e5a5a462bd", "12eefc2eaf76718f44e4926c9ca7ced3f6b91a3004",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "5430a50247ef0c1d417caaa7f2032118d5137dd0e", "21223951b30f46bab890003e1225a9f2efc3edd407",
            ),
            (
              false, "5430a50247ef0c1d417caaa7f2032118d5137dd0e", "21223951b30f46bab890003e1225a9f2efc3edd407",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "fc5272757775354278e1efe4818f326e551fe6b35", "568da567b466996a5f829d5e39da8ced8c72c0db80",
            ),
            (
              true, "fc5272757775354278e1efe4818f326e551fe6b35", "568da567b466996a5f829d5e39da8ced8c72c0db80",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "8d6b8cb30de9df6c3a83ff19f6ea17e5a5a462bd", "12eefc2eaf76718f44e4926c9ca7ced3f6b91a3004",
            ),
            (
              false, "8d6b8cb30de9df6c3a83ff19f6ea17e5a5a462bd", "12eefc2eaf76718f44e4926c9ca7ced3f6b91a3004",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "e4bb64aaea4e416f603985fccc9", "3a96c0346af44ec95bb002b09c500",
            ),
            (
              false, "e4bb64aaea4e416f603985fccc9", "3a96c0346af44ec95bb002b09c500",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "e4bb64aaea4e416f603985fccc9", "3a96c0346af44ec95bb002b09c500",
            ),
            (
              true, "e4bb64aaea4e416f603985fccc9", "3a96c0346af44ec95bb002b09c500",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
          ],
          ricci: [
            (
              true, "fc5272757775354278e1efe4818f326e551fe6b35", "568da567b466996a5f829d5e39da8ced8c72c0db80",
            ),
            (
              false, "8d6b8cb30de9df6c3a83ff19f6ea17e5a5a462bd", "12eefc2eaf76718f44e4926c9ca7ced3f6b91a3004",
            ),
            (
              false, "8d6b8cb30de9df6c3a83ff19f6ea17e5a5a462bd", "12eefc2eaf76718f44e4926c9ca7ced3f6b91a3004",
            ),
            (
              true, "5430a50247ef0c1d417caaa7f2032118d5137dd0e", "21223951b30f46bab890003e1225a9f2efc3edd407",
            ),
          ],
        },
        {
          alpha: (false, "1", "1"),
          scalar: (
            true, "1454696aa50b50f7d09bd30c7284c00", "51dfe6855658c639d3c24924122a59",
          ),
          lower: [
            (false, "620f2bf7727835a8aa37d6ed", "df82cdb638758dbf9cb1f2000"),
            (true, "1416be9ce2d7ef8fb2fd513f", "92add6ff950d2505bed4c6d00"),
            (false, "16cd7034420133dee282dc4d", "92add6ff950d2505bed4c6d00"),
            (false, "1f0b01eeea398f2ff9f21473", "60421517b9d0a04bc53ba2788"),
            (false, "16cd7034420133dee282dc4d", "92add6ff950d2505bed4c6d00"),
            (false, "1f0b01eeea398f2ff9f21473", "60421517b9d0a04bc53ba2788"),
            (false, "23493d386a79c7a64fb5311", "66ace34c81ef99ea6bfb57f8"),
            (true, "5064a217a2273426b1df65b9", "a873a4e9852d188499285c52e"),
          ],
          lower_first: [
            (
              false, "e987914e046cf951fa6206e69be41aa6c7", "ec488cf468adf343c38783feddb1cd170000",
            ),
            (
              true, "5fabfcf3544d414c528c4f6a60be2c9959", "33afded576e60d36d2c5a4dfc07ee4dd0800",
            ),
            (
              false, "3403123e5e68b96542cbe1dc3969bbe5ed", "33afded576e60d36d2c5a4dfc07ee4dd0800",
            ),
            (
              false, "1fa9483056536fa903b86a271164958303f", "21eb6a3c1606f8abfa51b432d65346310d40",
            ),
            (
              false, "3403123e5e68b96542cbe1dc3969bbe5ed", "33afded576e60d36d2c5a4dfc07ee4dd0800",
            ),
            (
              false, "1fa9483056536fa903b86a271164958303f", "21eb6a3c1606f8abfa51b432d65346310d40",
            ),
            (
              false, "8cea9d1fb9d7ff6058a6d2d34975bb22d1", "21eb6a3c1606f8abfa51b432d65346310d40",
            ),
            (
              true, "3993b69fdb6a6b22b90361faa8471369fd", "b213edbb73a49986e22cf20ae5353081859",
            ),
            (
              false, "4f8bab31ad4e9f887d6c9677336a99b533", "33afded576e60d36d2c5a4dfc07ee4dd0800",
            ),
            (
              false, "149ed9e6b023fabbd901c577e0b4ee9defd", "21eb6a3c1606f8abfa51b432d65346310d40",
            ),
            (
              false, "7da293999a0ee55ec1f60e13484c3e2b85", "b4e78beb20252e3fe1b3c10f21bc21059c0",
            ),
            (
              true, "f7ca5a5ae18fb5e33fa9d08464b71d364", "239d95f24a541eb493a296cefaa43ce6b45",
            ),
            (
              false, "7da293999a0ee55ec1f60e13484c3e2b85", "b4e78beb20252e3fe1b3c10f21bc21059c0",
            ),
            (
              true, "f7ca5a5ae18fb5e33fa9d08464b71d364", "239d95f24a541eb493a296cefaa43ce6b45",
            ),
            (
              true, "94ab554b0338ad925f163fd378c6746fa5", "b213edbb73a49986e22cf20ae5353081859",
            ),
            (
              false, "dd1e1a06bb7acd55313c13f46fc9d0c3753", "e9ba280607c8098108dafdae4cd5cfa9ff4d",
            ),
          ],
          coefficients: [
            (
              false, "80bc242c6f37d8acdb50fe895d1", "1de46c833bcb03a03400fc25dcd0",
            ),
            (true, "5f49f809694b960558801da69b", "7791b20cef2c0e80d003f097734"),
            (
              false, "1d3d9afb5b7f2d1e87fd229ec26", "d13ef796a28d19616c06e50909b",
            ),
            (false, "f8229ca584d9c654725133c4d3", "3bc8d906779607406801f84bb9a"),
            (
              false, "1d3d9afb5b7f2d1e87fd229ec26", "d13ef796a28d19616c06e50909b",
            ),
            (false, "f8229ca584d9c654725133c4d3", "3bc8d906779607406801f84bb9a"),
            (
              false, "2dc18e9533cd98003932acc64d20", "112a2a4f5b559314fddc90c9bdcb7",
            ),
            (true, "41f86dbc0a53390fdd24fc88d4b", "d13ef796a28d19616c06e50909b"),
          ],
          derivatives: [
            (
              true, "23b37a2647f93cee9bb56321ff9ffd5114622d425c846105a59f", "16dff588e41540921f9036f26a26ad4f3783c22ea50b7a23b3900",
            ),
            (
              true, "1956c6045cb7a54da5cd680165fe299aa92e325954a29d2d5aed7", "8ef7be979184d3914545576b1771bb2f1af77da38787bb5f22440",
            ),
            (
              true, "437028ece35a06d0a9552bf2232c6554efd3ea103cd5d7d5bab", "11def7d2f2309a7228a8aaed62ee3765e35eefb470f0f76be4488",
            ),
            (
              false, "7baa16bd0a2ef7dfb8def5af33f5a433ce84d21fe997a62a55d", "e4bf9758e8d485b53ba225782582c5182b2595d27272c56503a",
            ),
            (
              true, "437028ece35a06d0a9552bf2232c6554efd3ea103cd5d7d5bab", "11def7d2f2309a7228a8aaed62ee3765e35eefb470f0f76be4488",
            ),
            (
              false, "7baa16bd0a2ef7dfb8def5af33f5a433ce84d21fe997a62a55d", "e4bf9758e8d485b53ba225782582c5182b2595d27272c56503a",
            ),
            (
              false, "271a6fa82645f501bcac72b2ad0604e56f97562fde3d124ec87c", "fa318d893ea8723e393958fb690707926f311bde2d2d87e67bf7",
            ),
            (
              true, "4f5cdd98087df0f04db8e33f73f3f319a518bc71a1b5d8de3629", "1f4631b127d50e47c7272b1f6d20e0f24de6237bc5a5b0fccf7ee",
            ),
            (
              true, "6053bd7b4ad27ce3b9c0f2bd715be28ca6e95d9b2a5d8bb80a5", "7d18c6c49f54391f1c9cac7db48383c937988def1696c3f33dfb8",
            ),
            (
              false, "16cb863dfe05de22669572b99d708d80752e47640f62653d808b5", "477bdf4bc8c269c8a2a2abb58bb8dd978d7bbed1c3c3ddaf91220",
            ),
            (
              false, "1d2f9b06bd6ebcaf63268f24e94378ad725e48c545edc55ffdab4", "6d75adec0b69b1fb390916edfdf3135010a57c3133c3eb74d63c1",
            ),
            (
              true, "5372ef1729d1025baf15ed97377f619ca635e72d3fdc751ed86b", "1f4631b127d50e47c7272b1f6d20e0f24de6237bc5a5b0fccf7ee",
            ),
            (
              false, "1d2f9b06bd6ebcaf63268f24e94378ad725e48c545edc55ffdab4", "6d75adec0b69b1fb390916edfdf3135010a57c3133c3eb74d63c1",
            ),
            (
              true, "5372ef1729d1025baf15ed97377f619ca635e72d3fdc751ed86b", "1f4631b127d50e47c7272b1f6d20e0f24de6237bc5a5b0fccf7ee",
            ),
            (
              true, "414a31414037af2707e7ef43151b8aadb76c45b6fde49aa0dabca0", "8faa7445cefab999badbee185d4f095915d9330093f12509592ed5",
            ),
            (
              false, "27fd4c304a577cd4bb1e22415dc9bbcb55d32fb263e40fa0ff841", "6d75adec0b69b1fb390916edfdf3135010a57c3133c3eb74d63c1",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              false, "3e21be61c55e5d75b992954c3ee0e0a15b52ce898", "7655a823c8a445bf6e949326d318ccacc604e3ac19",
            ),
            (
              true, "3e21be61c55e5d75b992954c3ee0e0a15b52ce898", "7655a823c8a445bf6e949326d318ccacc604e3ac19",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "8eba2301efa550ef91adbf8ef45eb6cf52e06fb400", "33c5798fa7c7de83c0610060fc5ad98b96a2239b4af",
            ),
            (
              false, "8eba2301efa550ef91adbf8ef45eb6cf52e06fb400", "33c5798fa7c7de83c0610060fc5ad98b96a2239b4af",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "352892cd8d4fdc16b0a87282ab5657e323910c3f8", "10e7aa4e413c09f6c6a782bc674caf86656e69aadf",
            ),
            (
              true, "352892cd8d4fdc16b0a87282ab5657e323910c3f8", "10e7aa4e413c09f6c6a782bc674caf86656e69aadf",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "44e28433439d10e460db0de290bb4c4dbc67b8998", "7655a823c8a445bf6e949326d318ccacc604e3ac19",
            ),
            (
              false, "44e28433439d10e460db0de290bb4c4dbc67b8998", "7655a823c8a445bf6e949326d318ccacc604e3ac19",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (
              false, "1c7ba38f5f2a734d1914d2ae09", "344fbde5a8a346585b01b942426c0",
            ),
            (
              true, "1c7ba38f5f2a734d1914d2ae09", "344fbde5a8a346585b01b942426c0",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "304072b74461d3457190b62c8ab", "b71718a3ce3b76353e860867e87a",
            ),
            (
              false, "304072b74461d3457190b62c8ab", "b71718a3ce3b76353e860867e87a",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "6e00ba94da04ac5313459d14e1", "1a27def2d451a32c2d80dca12136",
            ),
            (true, "6e00ba94da04ac5313459d14e1", "1a27def2d451a32c2d80dca12136"),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "1ca6f7538120de3112efd38b7c", "112a2a4f5b559314fddc90c9bdcb7",
            ),
            (
              false, "1ca6f7538120de3112efd38b7c", "112a2a4f5b559314fddc90c9bdcb7",
            ),
            (false, "0", "1"),
          ],
          ricci: [
            (
              true, "352892cd8d4fdc16b0a87282ab5657e323910c3f8", "10e7aa4e413c09f6c6a782bc674caf86656e69aadf",
            ),
            (
              false, "3e21be61c55e5d75b992954c3ee0e0a15b52ce898", "7655a823c8a445bf6e949326d318ccacc604e3ac19",
            ),
            (
              false, "44e28433439d10e460db0de290bb4c4dbc67b8998", "7655a823c8a445bf6e949326d318ccacc604e3ac19",
            ),
            (
              true, "8eba2301efa550ef91adbf8ef45eb6cf52e06fb400", "33c5798fa7c7de83c0610060fc5ad98b96a2239b4af",
            ),
          ],
        },
        {
          alpha: (true, "1", "1"),
          scalar: (
            true, "1454696aa50b50f7d09bd30c7284c00", "51dfe6855658c639d3c24924122a59",
          ),
          lower: [
            (false, "195033b77", "58e9bc17d0"),
            (false, "1269671213", "3a59636fa08"),
            (false, "21bde9b0c39f1", "37800614ad29c0"),
            (false, "4d02fb4c554d", "246c03fd91a366"),
            (false, "21bde9b0c39f1", "37800614ad29c0"),
            (false, "4d02fb4c554d", "246c03fd91a366"),
            (false, "1fdd2d", "cfd3345"),
            (true, "53f1860", "110c534a9"),
          ],
          lower_first: [
            (true, "3b24851f3ee0ab2b", "c5a35e351d1717c6a"),
            (false, "1a72206912060d549", "62d1af1a8e8b8be350"),
            (false, "1173e8ef6d5a18f1bd612149", "271d4a6649e15f34bb6bf0c00"),
            (false, "53a5c5ffad3b92edcfaf013", "88e684660294cd388ff9caa0"),
            (false, "1173e8ef6d5a18f1bd612149", "271d4a6649e15f34bb6bf0c00"),
            (false, "53a5c5ffad3b92edcfaf013", "88e684660294cd388ff9caa0"),
            (true, "7bea5e5fe5b", "7b674e26829b8"),
            (false, "3b5d8aa0a7c", "6bfa6461b2481"),
            (false, "391fbb5a03443abd3", "8a58c1f1fac35d7170"),
            (false, "4ff9f59d9ea0d626cf", "1c5f33c61fed10a9c378"),
            (false, "6be8304185fa868b0d342b7", "19ab38d3207be67a9afed5fe0"),
            (false, "d1af48e55fac5ef7bc48f3", "59d746e2f1b1a6ad1e7becf9"),
            (false, "6be8304185fa868b0d342b7", "19ab38d3207be67a9afed5fe0"),
            (false, "d1af48e55fac5ef7bc48f3", "59d746e2f1b1a6ad1e7becf9"),
            (true, "1b714306c0ce", "6bfa6461b2481"),
            (false, "24e7a88fae240", "8db8a3c039fe95"),
          ],
          coefficients: [
            (false, "2049e79613814e8", "90c67cffc509f5b"),
            (false, "9c2a29a96017517", "24319f3ff1427d6c"),
            (false, "3b92e61e7a255e8", "90c67cffc509f5b"),
            (false, "18cfbb2ab0bd6a8", "90c67cffc509f5b"),
            (false, "3b92e61e7a255e8", "90c67cffc509f5b"),
            (false, "18cfbb2ab0bd6a8", "90c67cffc509f5b"),
            (false, "91e8c5400c8600", "90c67cffc509f5b"),
            (true, "1e9d74d1c4aad00", "90c67cffc509f5b"),
          ],
          derivatives: [
            (
              true, "1eebb82de833f973708c426efffef4", "51dfe6855658c639d3c24924122a59",
            ),
            (
              true, "34f29f1369d9fab6af3b125a5bebe", "51dfe6855658c639d3c24924122a59",
            ),
            (
              false, "22ac0c14eb3c156ef33bdbdb1b9228", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (
              false, "6b085297c0d3949cea32262f2ec777", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (
              false, "22ac0c14eb3c156ef33bdbdb1b9228", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (
              false, "6b085297c0d3949cea32262f2ec777", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (
              false, "29c7284825663a6256d21a2c582a0", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (
              false, "1e65bd9c15632a67cbe49261046ed0", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (
              false, "8d9ca1695d910646db1a80eab3f20", "51dfe6855658c639d3c24924122a59",
            ),
            (
              false, "1258360f2481dc6a22577ade89cca3", "51dfe6855658c639d3c24924122a59",
            ),
            (
              true, "1f47da79e0a7bc413f18cd0394e2a0", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (
              false, "135b0d80ec2d8731051a85b3dd6058", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (
              true, "1f47da79e0a7bc413f18cd0394e2a0", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (
              false, "135b0d80ec2d8731051a85b3dd6058", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (
              true, "329073b37f459be8c9f614f4e73000", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (
              false, "9d3d2ba9c2bde0c2b45256b25c200", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              false, "c5584af2af04ae8700923addf5b48", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (
              true, "c5584af2af04ae8700923addf5b48", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "45b73f27712c5eff44e4f925926e00", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (
              false, "45b73f27712c5eff44e4f925926e00", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "50750fbb149be57e0cf0c710cb23d6", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (
              true, "50750fbb149be57e0cf0c710cb23d6", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "adfbaf003bbe438da7b836ef4f648", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (
              false, "adfbaf003bbe438da7b836ef4f648", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (
              true, "1c7ba38f5f2a734d1914d2ae09", "344fbde5a8a346585b01b942426c0",
            ),
            (
              false, "1c7ba38f5f2a734d1914d2ae09", "344fbde5a8a346585b01b942426c0",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (true, "6e00ba94da04ac5313459d14e1", "1a27def2d451a32c2d80dca12136"),
            (
              false, "6e00ba94da04ac5313459d14e1", "1a27def2d451a32c2d80dca12136",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "304072b74461d3457190b62c8ab", "b71718a3ce3b76353e860867e87a",
            ),
            (
              true, "304072b74461d3457190b62c8ab", "b71718a3ce3b76353e860867e87a",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "1ca6f7538120de3112efd38b7c", "112a2a4f5b559314fddc90c9bdcb7",
            ),
            (
              true, "1ca6f7538120de3112efd38b7c", "112a2a4f5b559314fddc90c9bdcb7",
            ),
            (false, "0", "1"),
          ],
          ricci: [
            (
              true, "50750fbb149be57e0cf0c710cb23d6", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (
              false, "c5584af2af04ae8700923addf5b48", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (
              false, "adfbaf003bbe438da7b836ef4f648", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
            (
              true, "45b73f27712c5eff44e4f925926e00", "1995f809aafbbdf2122cb6db45ad3bd",
            ),
          ],
        },
        {
          alpha: (false, "3", "5"),
          scalar: (
            true, "1e484c1f7214c03faaad64194ce5a980", "7fedd83056eab5ba5adf92485c622b1",
          ),
          lower: [
            (false, "71f7ae116f54d9eb97f2cc6d", "117638123c692f12f83de6e800"),
            (true, "884969d5e3219ea59a79687", "b7594cbf7a506e472e89f8840"),
            (false, "5a3147d01fbaa4bfc27144d", "16eb2997ef4a0dc8e5d13f108"),
            (false, "271cb8ea96b9556392a0d77", "8982f98f9bbc52b562e77a63"),
            (false, "5a3147d01fbaa4bfc27144d", "16eb2997ef4a0dc8e5d13f108"),
            (false, "271cb8ea96b9556392a0d77", "8982f98f9bbc52b562e77a63"),
            (false, "c41bbb593f5a490af177d7b", "281b88c9e2c1981f922e2e5ce"),
            (true, "bab4ca0081f114bf2ebbab12", "1a5211c47ccf0bd4b7ee4e6cf3"),
          ],
          lower_first: [
            (
              true, "314c8a1c29a7562f74bb7ad939afe67939", "1275ab03182d97014b46964fe951e405cc000",
            ),
            (
              true, "28579e45097433f63aeb16770cd85cacb9", "409bd68ad49f908487770e17b09e9e144a00",
            ),
            (
              false, "1208669722bde8acf7f864e4267b30be4bd", "8137ad15a93f21090eee1c2f613d3c289400",
            ),
            (
              false, "49af640ab711782a34a98bb63942f0ef1b1", "54cc899637116dadf1cc427f17d02f7aa120",
            ),
            (
              false, "1208669722bde8acf7f864e4267b30be4bd", "8137ad15a93f21090eee1c2f613d3c289400",
            ),
            (
              false, "49af640ab711782a34a98bb63942f0ef1b1", "54cc899637116dadf1cc427f17d02f7aa120",
            ),
            (
              false, "8466c0f6a2550755c9b49a2c8a0f03280f", "2a6644cb1b88b6d6f8e6213f8be817bd5090",
            ),
            (
              true, "e0305d16f59aaf30b008ffad72492be0d8", "37a63a4a94236ffa26ae0ba367a09f2879bd",
            ),
            (
              false, "a4e9a76f911bb2022bbbae956f5a2c4dd3", "409bd68ad49f908487770e17b09e9e144a00",
            ),
            (
              false, "10d960f79f4303592480ea84d0893503cb", "204deb456a4fc84243bb870bd84f4f0a250",
            ),
            (
              false, "3391b2f949ecf178cc395089fb8793c383b", "54cc899637116dadf1cc427f17d02f7aa120",
            ),
            (
              true, "b59b798d2d534cfe71133ba9facc8d745", "239d95f24a541eb493a296cefaa43ce6b45",
            ),
            (
              false, "3391b2f949ecf178cc395089fb8793c383b", "54cc899637116dadf1cc427f17d02f7aa120",
            ),
            (
              true, "b59b798d2d534cfe71133ba9facc8d745", "239d95f24a541eb493a296cefaa43ce6b45",
            ),
            (
              true, "7ffcaf0abae5cccade87314f37ad27830a", "b213edbb73a49986e22cf20ae5353081859",
            ),
            (
              false, "25d038802042798652661afb6bf7f84936c", "2ebed4ce018e684d01c565efa8f78feecca9",
            ),
          ],
          coefficients: [
            (
              false, "9b66e780ea27aa68719899ea531", "255d87a40abdc48841013b2f5404",
            ),
            (
              false, "86bf0fb9278c2f1521a6a49fc5", "255d87a40abdc48841013b2f5404",
            ),
            (
              false, "cb10c5f4824de9776a479584c80", "4163ad5f12cc17ee71c22792d307",
            ),
            (
              false, "2423ca8055dbe71a93610d93dbe", "95761e902af712210404ecbd501",
            ),
            (
              false, "cb10c5f4824de9776a479584c80", "4163ad5f12cc17ee71c22792d307",
            ),
            (
              false, "2423ca8055dbe71a93610d93dbe", "95761e902af712210404ecbd501",
            ),
            (
              false, "c852cf2cded5085fdcb486b0b280", "55d2d38cc8abdf68f54ed3f0b4f93",
            ),
            (
              true, "134214ea06ddd61ada2cdfb9a22c", "4163ad5f12cc17ee71c22792d307",
            ),
          ],
          derivatives: [
            (
              true, "e0d2539e7dbffbf5eba26d25431916a8dc25163503d1f2b8d53", "5b7fd623905502487e40dbc9a89ab53cde0f08ba942de88ece40",
            ),
            (
              true, "1ac89936f20c9292e18f2882cb4a2673ba4c2bad805c33d931bb7", "b2b5ae3d75e608759696ad45dd4e29fae1b55d0c6969aa36ead50",
            ),
            (
              false, "1d6e8315b3982f418e373a6388951af1938ce78ada3743567e5", "1656b5c7aebcc10eb2d2d5a8bba9c53f5c36aba18d2d3546dd5aa",
            ),
            (
              false, "37724db701bfef6517c38d645e63e2bb5faa6f37a05ac1ee7dd", "725fcbac746a42da9dd112bc12c1628c1592cae9393962b281d",
            ),
            (
              false, "1d6e8315b3982f418e373a6388951af1938ce78ada3743567e5", "1656b5c7aebcc10eb2d2d5a8bba9c53f5c36aba18d2d3546dd5aa",
            ),
            (
              false, "37724db701bfef6517c38d645e63e2bb5faa6f37a05ac1ee7dd", "725fcbac746a42da9dd112bc12c1628c1592cae9393962b281d",
            ),
            (
              false, "9e0246564d52e64d14f4314e15156a8767a8176db359781901d0", "4e2f7c3ae394a3b371e1ebce90d2325dc2bf58b56e1e3a7806bd3",
            ),
            (
              true, "8c25d234d0c00270b2d3ea86630331d16a27dad2e6d88d0bd3e2", "4e2f7c3ae394a3b371e1ebce90d2325dc2bf58b56e1e3a7806bd3",
            ),
            (
              false, "30126d6148a2559e0c980baa064adc730f75b682f1f16b74151b", "9c5ef875c7294766e3c3d79d21a464bb857eb16adc3c74f00d7a6",
            ),
            (
              false, "1acc93e613a85a3210ec99637860db82ba4c975fe0fea28289d0d", "595ad71ebaf3043acb4b56a2eea714fd70daae8634b4d51b756a8",
            ),
            (
              false, "6c6140b4af8228064bd7dc5e509b07108f1dcc571ce7e6bd36bb0", "2234c659c391079e81d2d72a5f5bf6090533b6cf602d399482f2c5",
            ),
            (
              true, "9b1186316e38a6d98ea1f793fc7c0699f7d857526652324925ce", "4e2f7c3ae394a3b371e1ebce90d2325dc2bf58b56e1e3a7806bd3",
            ),
            (
              false, "6c6140b4af8228064bd7dc5e509b07108f1dcc571ce7e6bd36bb0", "2234c659c391079e81d2d72a5f5bf6090533b6cf602d399482f2c5",
            ),
            (
              true, "9b1186316e38a6d98ea1f793fc7c0699f7d857526652324925ce", "4e2f7c3ae394a3b371e1ebce90d2325dc2bf58b56e1e3a7806bd3",
            ),
            (
              true, "116e7828fe6c420413902b63cb7ff693954df35c1637145e888a280", "2ce54455d0ae5a000a64ba679d28b2ebd6d3dff02e3b5b92ebdea29",
            ),
            (
              false, "a295e16cf64188715dc63fd9ce551efa076df527cacec1be54b04", "2234c659c391079e81d2d72a5f5bf6090533b6cf602d399482f2c5",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              false, "5b2527835db0a732006dd24d813db3b017bc5e4cfc", "b8e5d6b7e980acfb1cc825eca9d6bfcdf567a3bce71",
            ),
            (
              true, "5b2527835db0a732006dd24d813db3b017bc5e4cfc", "b8e5d6b7e980acfb1cc825eca9d6bfcdf567a3bce71",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "d42473594ea66e01a4524fff3143732f38d817587e0", "50e48df076284baddc9790978a4df3ea1b5d57a2a517",
            ),
            (
              false, "d42473594ea66e01a4524fff3143732f38d817587e0", "50e48df076284baddc9790978a4df3ea1b5d57a2a517",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "2797712309f87effc32e136b8ebdc7cef1e9a1eb47d", "d34fd0d22f6e7c8cb32de2330b3e920ff3e428d7e38",
            ),
            (
              true, "2797712309f87effc32e136b8ebdc7cef1e9a1eb47d", "d34fd0d22f6e7c8cb32de2330b3e920ff3e428d7e38",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "6179e0f7c40b6f69bd41c35a6dfa78a1b2bff9bbfc", "b8e5d6b7e980acfb1cc825eca9d6bfcdf567a3bce71",
            ),
            (
              false, "6179e0f7c40b6f69bd41c35a6dfa78a1b2bff9bbfc", "b8e5d6b7e980acfb1cc825eca9d6bfcdf567a3bce71",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (
              false, "5572eaae1d7f59e74b3e780a1b", "1058eb57c4b305fb9c7089e4b4c1c0",
            ),
            (
              true, "5572eaae1d7f59e74b3e780a1b", "1058eb57c4b305fb9c7089e4b4c1c0",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "23eb70324f95228c82b1877508c19", "8f0a0b3ff91e745998d8b6912d9f50",
            ),
            (
              false, "23eb70324f95228c82b1877508c19", "8f0a0b3ff91e745998d8b6912d9f50",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "23dc60afee3d3cdafee978c6efe39", "8f0a0b3ff91e745998d8b6912d9f50",
            ),
            (
              true, "23dc60afee3d3cdafee978c6efe39", "8f0a0b3ff91e745998d8b6912d9f50",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "1ca6f7538120de3112efd38b7c", "1c9b9bd998394a7851c4f1503c531",
            ),
            (
              false, "1ca6f7538120de3112efd38b7c", "1c9b9bd998394a7851c4f1503c531",
            ),
            (false, "0", "1"),
          ],
          ricci: [
            (
              true, "2797712309f87effc32e136b8ebdc7cef1e9a1eb47d", "d34fd0d22f6e7c8cb32de2330b3e920ff3e428d7e38",
            ),
            (
              false, "5b2527835db0a732006dd24d813db3b017bc5e4cfc", "b8e5d6b7e980acfb1cc825eca9d6bfcdf567a3bce71",
            ),
            (
              false, "6179e0f7c40b6f69bd41c35a6dfa78a1b2bff9bbfc", "b8e5d6b7e980acfb1cc825eca9d6bfcdf567a3bce71",
            ),
            (
              true, "d42473594ea66e01a4524fff3143732f38d817587e0", "50e48df076284baddc9790978a4df3ea1b5d57a2a517",
            ),
          ],
        },
        {
          alpha: (true, "3", "5"),
          scalar: (
            true, "1e484c1f7214c03faaad64194ce5a980", "7fedd83056eab5ba5adf92485c622b1",
          ),
          lower: [
            (false, "160974d97404279d785e72eed", "45d8e048f1a4bc4be0f79ba000"),
            (false, "a50bc15b67856ac5e25e5a41", "2dd6532fde941b91cba27e2100"),
            (false, "17b80ab711fc31beecddf3dfd", "2dd6532fde941b91cba27e2100"),
            (false, "51ecffd484c347a25f9c9563", "1e14a6976a113217ada2a2c5a8"),
            (false, "17b80ab711fc31beecddf3dfd", "2dd6532fde941b91cba27e2100"),
            (false, "51ecffd484c347a25f9c9563", "1e14a6976a113217ada2a2c5a8"),
            (false, "1eb46c60cc3f712f5bd681b5", "a06e23278b06607e48b8b9738"),
            (true, "11fc0d0a18f3c97b509c662b9", "34a42388f99e17a96fdc9cd9e6"),
          ],
          lower_first: [
            (
              true, "10c3ba2554dcd7fec4f7761516bd5bf75939", "49d6ac0c60b65c052d1a593fa547901730000",
            ),
            (
              false, "31599edf15943941527873fcadd9ed230a7", "1026f5a2b527e42121ddc385ec27a78512800",
            ),
            (
              false, "da49e3b3b0f95a81de092c4f693331cf93", "24eb5606305b2e02968d2c9fd2a3c80b9800",
            ),
            (
              false, "728fe580a9a8366a6d7e2567c532c4cb9d7", "a999132c6e22db5be39884fe2fa05ef54240",
            ),
            (
              false, "da49e3b3b0f95a81de092c4f693331cf93", "24eb5606305b2e02968d2c9fd2a3c80b9800",
            ),
            (
              false, "728fe580a9a8366a6d7e2567c532c4cb9d7", "a999132c6e22db5be39884fe2fa05ef54240",
            ),
            (
              false, "4acda8e41a87eb769834867530a3b76b1", "a999132c6e22db5be39884fe2fa05ef54240",
            ),
            (
              true, "2119c0fdfb2e75b9e8f14105ecfa8c4d8d", "37a63a4a94236ffa26ae0ba367a09f2879bd",
            ),
            (
              false, "5a56b6f0fea1fc723625e185af263c33f33", "1026f5a2b527e42121ddc385ec27a78512800",
            ),
            (
              false, "ed76543ea2131c4c27d8e4a5037ca04ddf", "38885bb97a0b9e73f6882c54ba8aca51c0c0",
            ),
            (
              false, "3b3458aa4e1da6abe0467cb9a0e62f41b77", "a999132c6e22db5be39884fe2fa05ef54240",
            ),
            (
              false, "26b981f6b5721f49186ee20c06be0428", "51683229ce77219cbf2a7d46cf2e420f53",
            ),
            (
              false, "3b3458aa4e1da6abe0467cb9a0e62f41b77", "a999132c6e22db5be39884fe2fa05ef54240",
            ),
            (
              false, "26b981f6b5721f49186ee20c06be0428", "51683229ce77219cbf2a7d46cf2e420f53",
            ),
            (
              true, "41f0bc49e1ed2a745cda05c2746140bd39", "b213edbb73a49986e22cf20ae5353081859",
            ),
            (
              false, "5cea1bee52c1167edc45dfc72001f36de77", "e9ba280607c8098108dafdae4cd5cfa9ff4d",
            ),
          ],
          coefficients: [
            (
              false, "22b6859741e34f4663fcab498bd1", "95761e902af712210404ecbd5010",
            ),
            (
              false, "7b051c771c99e86a4b61c4f4229", "255d87a40abdc48841013b2f5404",
            ),
            (
              false, "175a70317acc40113b1494ec5bc6", "4163ad5f12cc17ee71c22792d307",
            ),
            (
              false, "387de12782530ee56fdc4c16593", "12aec3d2055ee24420809d97aa02",
            ),
            (
              false, "175a70317acc40113b1494ec5bc6", "4163ad5f12cc17ee71c22792d307",
            ),
            (
              false, "387de12782530ee56fdc4c16593", "12aec3d2055ee24420809d97aa02",
            ),
            (
              false, "72f3e1f57248397c18d9fb244520", "55d2d38cc8abdf68f54ed3f0b4f93",
            ),
            (
              true, "f2f6cc7d1c952ec8960d226414b", "4163ad5f12cc17ee71c22792d307",
            ),
          ],
          derivatives: [
            (
              true, "75b7e52ba5d4452a188243bf44391eb59efe8e6dee44cfa7e453", "16dff588e41540921f9036f26a26ad4f3783c22ea50b7a23b3900",
            ),
            (
              true, "3073f92db20679a161e97017babdf72bbb0dc79c103c07eac7cd7", "2cad6b8f5d79821d65a5ab5177538a7eb86d57431a5a6a8dbab540",
            ),
            (
              false, "5ca7a973c8bc95a52cf71396898eb9f1346392fa133fbdaedd55", "595ad71ebaf3043acb4b56a2eea714fd70daae8634b4d51b756a8",
            ),
            (
              false, "e84084cfcb083e850b31b9dde3fa1d9838dcd790e0305ca95d", "2dbfeb11c82a81243f206de4d44d5a9e6f07845d4a16f447672",
            ),
            (
              false, "5ca7a973c8bc95a52cf71396898eb9f1346392fa133fbdaedd55", "595ad71ebaf3043acb4b56a2eea714fd70daae8634b4d51b756a8",
            ),
            (
              false, "e84084cfcb083e850b31b9dde3fa1d9838dcd790e0305ca95d", "2dbfeb11c82a81243f206de4d44d5a9e6f07845d4a16f447672",
            ),
            (
              false, "2d7c8e7ef7323e1a45b60cc030fb60ac14c250e8c7d1cdc647fc", "4e2f7c3ae394a3b371e1ebce90d2325dc2bf58b56e1e3a7806bd3",
            ),
            (
              false, "45426a41f9610a8ef735fc84b331aff55b34341142e34ca68d57", "9c5ef875c7294766e3c3d79d21a464bb857eb16adc3c74f00d7a6",
            ),
            (
              false, "35b7557b8204aaef647a59e31fef3eb94d3d62ff096ce6a3ddb5b", "2717be1d71ca51d9b8f0f5e74869192ee15fac5ab70f1d3c035e98",
            ),
            (
              false, "56dc60bf582d9f1d0c07dd574c756da4c71347212926398e14e35", "1656b5c7aebcc10eb2d2d5a8bba9c53f5c36aba18d2d3546dd5aa0",
            ),
            (
              true, "44512925b746e2d9fe2f1b06887f5e7770f1232a54ef5ab021cc", "2234c659c391079e81d2d72a5f5bf6090533b6cf602d399482f2c5",
            ),
            (
              false, "b2fd0d00179ec92cd392f3c5c96835dfe65d1138b594a857fd5", "9c5ef875c7294766e3c3d79d21a464bb857eb16adc3c74f00d7a6",
            ),
            (
              true, "44512925b746e2d9fe2f1b06887f5e7770f1232a54ef5ab021cc", "2234c659c391079e81d2d72a5f5bf6090533b6cf602d399482f2c5",
            ),
            (
              false, "b2fd0d00179ec92cd392f3c5c96835dfe65d1138b594a857fd5", "9c5ef875c7294766e3c3d79d21a464bb857eb16adc3c74f00d7a6",
            ),
            (
              true, "8845276cd7cd3dbb6d73d404a36084b79424c14cad600835517ca0", "2ce54455d0ae5a000a64ba679d28b2ebd6d3dff02e3b5b92ebdea29",
            ),
            (
              false, "32800edf7de5d14e8054fd92ba827afe1658092b50de1c8a5a041", "2234c659c391079e81d2d72a5f5bf6090533b6cf602d399482f2c5",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              false, "566058333b8392727a7ec8ef2222dfb1f96c7c87ec", "b8e5d6b7e980acfb1cc825eca9d6bfcdf567a3bce71",
            ),
            (
              true, "566058333b8392727a7ec8ef2222dfb1f96c7c87ec", "b8e5d6b7e980acfb1cc825eca9d6bfcdf567a3bce71",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "d295be320962ca3fc80d60055cf507fc365f23b81e0", "50e48df076284baddc9790978a4df3ea1b5d57a2a517",
            ),
            (
              false, "d295be320962ca3fc80d60055cf507fc365f23b81e0", "50e48df076284baddc9790978a4df3ea1b5d57a2a517",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "27978bc8422a8c8250bae57c193d37fb81ee0531bad", "d34fd0d22f6e7c8cb32de2330b3e920ff3e428d7e38",
            ),
            (
              true, "27978bc8422a8c8250bae57c193d37fb81ee0531bad", "d34fd0d22f6e7c8cb32de2330b3e920ff3e428d7e38",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "500b9ebed528ca3abdaad7e235661ac05e68e118ec", "b8e5d6b7e980acfb1cc825eca9d6bfcdf567a3bce71",
            ),
            (
              false, "500b9ebed528ca3abdaad7e235661ac05e68e118ec", "b8e5d6b7e980acfb1cc825eca9d6bfcdf567a3bce71",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (
              true, "5572eaae1d7f59e74b3e780a1b", "1058eb57c4b305fb9c7089e4b4c1c0",
            ),
            (
              false, "5572eaae1d7f59e74b3e780a1b", "1058eb57c4b305fb9c7089e4b4c1c0",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "23dc60afee3d3cdafee978c6efe39", "8f0a0b3ff91e745998d8b6912d9f50",
            ),
            (
              false, "23dc60afee3d3cdafee978c6efe39", "8f0a0b3ff91e745998d8b6912d9f50",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "23eb70324f95228c82b1877508c19", "8f0a0b3ff91e745998d8b6912d9f50",
            ),
            (
              true, "23eb70324f95228c82b1877508c19", "8f0a0b3ff91e745998d8b6912d9f50",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "1ca6f7538120de3112efd38b7c", "1c9b9bd998394a7851c4f1503c531",
            ),
            (
              true, "1ca6f7538120de3112efd38b7c", "1c9b9bd998394a7851c4f1503c531",
            ),
            (false, "0", "1"),
          ],
          ricci: [
            (
              true, "27978bc8422a8c8250bae57c193d37fb81ee0531bad", "d34fd0d22f6e7c8cb32de2330b3e920ff3e428d7e38",
            ),
            (
              false, "566058333b8392727a7ec8ef2222dfb1f96c7c87ec", "b8e5d6b7e980acfb1cc825eca9d6bfcdf567a3bce71",
            ),
            (
              false, "500b9ebed528ca3abdaad7e235661ac05e68e118ec", "b8e5d6b7e980acfb1cc825eca9d6bfcdf567a3bce71",
            ),
            (
              true, "d295be320962ca3fc80d60055cf507fc365f23b81e0", "50e48df076284baddc9790978a4df3ea1b5d57a2a517",
            ),
          ],
        },
      ],
    },
    {
      name: "four_outcome_1",
      point: [(true, "1", "4"), (false, "1", "5")],
      polynomials: [
        [
          { coefficient: (false, "1", "3c"), exponents: [2, 1], },
          { coefficient: (false, "1", "28"), exponents: [2, 0], },
          { coefficient: (false, "1", "1e"), exponents: [1, 1], },
          { coefficient: (false, "1", "a"), exponents: [1, 0], },
          { coefficient: (false, "1", "14"), exponents: [0, 1], },
          { coefficient: (false, "1", "4"), exponents: [0, 0], },
        ],
        [
          { coefficient: (false, "1", "46"), exponents: [1, 2], },
          { coefficient: (true, "1", "c"), exponents: [1, 0], },
          { coefficient: (true, "1", "32"), exponents: [0, 2], },
          { coefficient: (false, "1", "f"), exponents: [0, 1], },
          { coefficient: (false, "1", "5"), exponents: [0, 0], },
        ],
        [
          { coefficient: (true, "1", "50"), exponents: [3, 0], },
          { coefficient: (false, "1", "23"), exponents: [1, 1], },
          { coefficient: (false, "1", "19"), exponents: [1, 0], },
          { coefficient: (true, "1", "9"), exponents: [0, 1], },
          { coefficient: (false, "3", "a"), exponents: [0, 0], },
        ],
        [
          { coefficient: (false, "1", "50"), exponents: [3, 0], },
          { coefficient: (true, "1", "3c"), exponents: [2, 1], },
          { coefficient: (true, "1", "28"), exponents: [2, 0], },
          { coefficient: (true, "1", "46"), exponents: [1, 2], },
          { coefficient: (true, "d", "d2"), exponents: [1, 1], },
          { coefficient: (true, "11", "12c"), exponents: [1, 0], },
          { coefficient: (false, "1", "32"), exponents: [0, 2], },
          { coefficient: (true, "1", "b4"), exponents: [0, 1], },
          { coefficient: (false, "1", "4"), exponents: [0, 0], },
        ],
      ],
      jets: [
        {
          p: (false, "8d1", "2580"),
          gradient: [(false, "25", "190"), (false, "29", "3c0")],
          hessian: [
            (false, "11", "12c"),
            (false, "1", "28"),
            (false, "1", "28"),
            (false, "0", "1"),
          ],
          third: [
            (false, "0", "1"),
            (false, "1", "1e"),
            (false, "1", "1e"),
            (false, "0", "1"),
            (false, "1", "1e"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
          ],
        },
        {
          p: (false, "bf51", "33450"),
          gradient: [(true, "365", "2904"), (false, "259", "2904")],
          hessian: [
            (false, "0", "1"),
            (false, "1", "af"),
            (false, "1", "af"),
            (true, "21", "2bc"),
          ],
          third: [
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "1", "23"),
            (false, "0", "1"),
            (false, "1", "23"),
            (false, "1", "23"),
            (false, "0", "1"),
          ],
        },
        {
          p: (false, "68f3b", "189c00"),
          gradient: [(false, "797", "af00"), (true, "95", "4ec")],
          hessian: [
            (false, "3", "a0"),
            (false, "1", "23"),
            (false, "1", "23"),
            (false, "0", "1"),
          ],
          third: [
            (true, "3", "28"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
          ],
        },
        {
          p: (false, "a31d95", "2673c00"),
          gradient: [(true, "8b69", "a4100"), (false, "240b", "7b0c0")],
          hessian: [
            (true, "b5", "960"),
            (true, "53", "578"),
            (true, "53", "578"),
            (false, "21", "2bc"),
          ],
          third: [
            (false, "3", "28"),
            (true, "1", "1e"),
            (true, "1", "1e"),
            (true, "1", "23"),
            (true, "1", "1e"),
            (true, "1", "23"),
            (true, "1", "23"),
            (false, "0", "1"),
          ],
        },
      ],
      metric: [
        (false, "b403f668ea9a3be7", "86cf7311e633dfaa8"),
        (true, "16cad41554c30c31", "35ec946d8f47f3110"),
        (true, "16cad41554c30c31", "35ec946d8f47f3110"),
        (false, "1a5f92db04126e07e5", "15d28a778995845dae0"),
      ],
      first: [
        (
          false, "4b985cbf824d74272815cf44185534", "3c9455d1f20f1493c9e08bfe8126d0b",
        ),
        (
          false, "115ab15c3ea1955d2666016ddc8d60b", "70126b9133024c77cf129c96d5549bac",
        ),
        (
          false, "115ab15c3ea1955d2666016ddc8d60b", "70126b9133024c77cf129c96d5549bac",
        ),
        (
          true, "176ec501e4165c57996b76034fa88dd", "344cdcdd5c1223af60a24913305aaf0c",
        ),
        (
          false, "1ce10f71bafef527880f28e92baca9", "3076ab0e5b3f43a96e4d3ccb9a8573c",
        ),
        (
          true, "4bac81ab44f62ac87982e40b5b802", "1de2c759eb781464373829c1d27cf65",
        ),
        (
          true, "4bac81ab44f62ac87982e40b5b802", "1de2c759eb781464373829c1d27cf65",
        ),
        (
          false, "2789b77b1329864a47908c81db4d84ad", "5ab54f0febaf75e42b9976bd47dd4798d0",
        ),
      ],
      second: [
        (
          false, "3919407ff30b39690fd703a503652ff6fba522863e5e0", "1f79d84e72e55fd2f376a0f4486793e69f464ae4f973789",
        ),
        (
          false, "1ce66d133c4b4ba1b6951112a811093376bc4aaff97a0", "14250550ed5f997cc4c6cd692419546aa3602feeb420f1",
        ),
        (
          false, "1ce66d133c4b4ba1b6951112a811093376bc4aaff97a0", "14250550ed5f997cc4c6cd692419546aa3602feeb420f1",
        ),
        (
          false, "24a70edae35da3edb03a616322408c52f2b09f3c923fd7", "2e959c4b24ed12f0870bbb03237a933699ce6ed8008c2d5",
        ),
        (
          false, "73abfbaac525b36a65db4208442076a36d10de1d5c988", "64b91a94a2ddff6fd7e2030db47ea61530e0efa984a4b5",
        ),
        (
          false, "95e57b1540f35f342e5345905e211db9a6dc2475093f0", "2e959c4b24ed12f0870bbb03237a933699ce6ed8008c2d5",
        ),
        (
          false, "95e57b1540f35f342e5345905e211db9a6dc2475093f0", "2e959c4b24ed12f0870bbb03237a933699ce6ed8008c2d5",
        ),
        (
          true, "1fc2f866c12a9e379f387bb883d582dac5acfac32facf37", "28c2e8c1c04f7092762a43a2bf0b40cfc694a0fd007aa7a6",
        ),
        (
          false, "73abfbaac525b36a65db4208442076a36d10de1d5c988", "64b91a94a2ddff6fd7e2030db47ea61530e0efa984a4b5",
        ),
        (
          false, "95e57b1540f35f342e5345905e211db9a6dc2475093f0", "2e959c4b24ed12f0870bbb03237a933699ce6ed8008c2d5",
        ),
        (
          false, "95e57b1540f35f342e5345905e211db9a6dc2475093f0", "2e959c4b24ed12f0870bbb03237a933699ce6ed8008c2d5",
        ),
        (
          true, "1fc2f866c12a9e379f387bb883d582dac5acfac32facf37", "28c2e8c1c04f7092762a43a2bf0b40cfc694a0fd007aa7a6",
        ),
        (
          false, "d9052b81e3279d290a5b5a4239c9047f00770efa32a8", "14250550ed5f997cc4c6cd692419546aa3602feeb420f1",
        ),
        (
          true, "25c6d2ee5c099087ac423c11b45ff798cf99cb04aa7194", "2e959c4b24ed12f0870bbb03237a933699ce6ed8008c2d5",
        ),
        (
          true, "25c6d2ee5c099087ac423c11b45ff798cf99cb04aa7194", "2e959c4b24ed12f0870bbb03237a933699ce6ed8008c2d5",
        ),
        (
          false, "d878e1da7350c40ebb8139f5f2ec703d76f4aa77c9f62165", "bc857480196f68a5628378d0b3940bc0f66f68922237475fc",
        ),
      ],
      cubic: [
        (
          false, "2d31747b55ea591b715187000b748", "3c9455d1f20f1493c9e08bfe8126d0b",
        ),
        (
          false, "8db76f4f3d12501ac50d2b3a14f03", "3076ab0e5b3f43a96e4d3ccb9a8573c",
        ),
        (
          false, "8db76f4f3d12501ac50d2b3a14f03", "3076ab0e5b3f43a96e4d3ccb9a8573c",
        ),
        (
          false, "550835ac852344a2c82f40cdc4c1c3", "344cdcdd5c1223af60a24913305aaf0c",
        ),
        (
          false, "8db76f4f3d12501ac50d2b3a14f03", "3076ab0e5b3f43a96e4d3ccb9a8573c",
        ),
        (
          false, "550835ac852344a2c82f40cdc4c1c3", "344cdcdd5c1223af60a24913305aaf0c",
        ),
        (
          false, "550835ac852344a2c82f40cdc4c1c3", "344cdcdd5c1223af60a24913305aaf0c",
        ),
        (
          true, "1a9b01e5652451d94aaeda228ee80390d", "5ab54f0febaf75e42b9976bd47dd4798d0",
        ),
      ],
      natural_gradient: [
        (false, "c9651def0f3262fcf901", "1e64a446e28bafeaa010"),
        (true, "41606697e53aa9eaec15", "f3252237145d7f55008"),
      ],
      scores: [
        (false, "18", "3d"),
        (false, "19a", "8d1"),
        (true, "43e4", "bf51"),
        (false, "2ef4", "bf51"),
        (false, "1113c", "68f3b"),
        (true, "2e900", "68f3b"),
        (true, "20ac9c", "a31d95"),
        (false, "b4370", "a31d95"),
      ],
      cubic_pullback: (
        false, "8435742fe50af127461ee15478111ceb15", "779607bb7d37d1ec4f7ad20a8a3e39e3f638",
      ),
      alphas: [
        {
          alpha: (false, "0", "1"),
          scalar: (
            true, "448e1885abc96028ba9e6528b433849c3cb2d", "66a35743524ab1c93b2c144faba1b1a74239",
          ),
          lower: [
            (
              false, "25cc2e5fc126ba13940ae7a20c2a9a", "3c9455d1f20f1493c9e08bfe8126d0b",
            ),
            (
              true, "201310fe832a6c311dd70bbf7be4857", "e024d722660498ef9e25392daaa93758",
            ),
            (
              false, "1ce10f71bafef527880f28e92baca9", "60ed561cb67e8752dc9a7997350ae78",
            ),
            (
              true, "176ec501e4165c57996b76034fa88dd", "6899b9bab824475ec144922660b55e18",
            ),
            (
              false, "1ce10f71bafef527880f28e92baca9", "60ed561cb67e8752dc9a7997350ae78",
            ),
            (
              true, "176ec501e4165c57996b76034fa88dd", "6899b9bab824475ec144922660b55e18",
            ),
            (
              false, "6e108a46d0082fbbed6d420d3a486d", "6899b9bab824475ec144922660b55e18",
            ),
            (
              false, "2789b77b1329864a47908c81db4d84ad", "b56a9e1fd75eebc85732ed7a8fba8f31a0",
            ),
          ],
          lower_first: [
            (
              false, "1c8ca03ff9859cb487eb81d281b297fb7dd291431f2f0", "1f79d84e72e55fd2f376a0f4486793e69f464ae4f973789",
            ),
            (
              false, "56aa238acae5a0735dfbb4592644f2af9b2506613115c", "64b91a94a2ddff6fd7e2030db47ea61530e0efa984a4b5",
            ),
            (
              false, "39d5fdd56292d9b532eda10422103b51b6886f0eae4c4", "64b91a94a2ddff6fd7e2030db47ea61530e0efa984a4b5",
            ),
            (
              false, "24a70edae35da3edb03a616322408c52f2b09f3c923fd7", "5d2b389649da25e10e17760646f5266d339cddb001185aa",
            ),
            (
              false, "39d5fdd56292d9b532eda10422103b51b6886f0eae4c4", "64b91a94a2ddff6fd7e2030db47ea61530e0efa984a4b5",
            ),
            (
              false, "24a70edae35da3edb03a616322408c52f2b09f3c923fd7", "5d2b389649da25e10e17760646f5266d339cddb001185aa",
            ),
            (
              true, "11ea5f783b3f38072a6ff8b1167c689bbdd51aadf117f7", "5d2b389649da25e10e17760646f5266d339cddb001185aa",
            ),
            (
              true, "1fc2f866c12a9e379f387bb883d582dac5acfac32facf37", "5185d183809ee124ec5487457e16819f8d2941fa00f54f4c",
            ),
            (
              false, "39d5fdd56292d9b532eda10422103b51b6886f0eae4c4", "64b91a94a2ddff6fd7e2030db47ea61530e0efa984a4b5",
            ),
            (
              true, "65087f38edb26e8345a65acc34af4f7931ad84dc41534", "2e959c4b24ed12f0870bbb03237a933699ce6ed8008c2d5",
            ),
            (
              false, "6c8295c0f193ce94852dad211ce4823f803b877d1954", "14250550ed5f997cc4c6cd692419546aa3602feeb420f1",
            ),
            (
              true, "1fc2f866c12a9e379f387bb883d582dac5acfac32facf37", "5185d183809ee124ec5487457e16819f8d2941fa00f54f4c",
            ),
            (
              false, "6c8295c0f193ce94852dad211ce4823f803b877d1954", "14250550ed5f997cc4c6cd692419546aa3602feeb420f1",
            ),
            (
              true, "1fc2f866c12a9e379f387bb883d582dac5acfac32facf37", "5185d183809ee124ec5487457e16819f8d2941fa00f54f4c",
            ),
            (
              true, "2258f8ba5fe61eb5ce3b6d6677d26e70a5a02884fa99cf9", "5185d183809ee124ec5487457e16819f8d2941fa00f54f4c",
            ),
            (
              false, "d878e1da7350c40ebb8139f5f2ec703d76f4aa77c9f62165", "1790ae90032ded14ac506f1a167281781ecded124446e8ebf8",
            ),
          ],
          coefficients: [
            (
              false, "b1dd1c1ef1cd5b4bfcaee1ac01f051def", "17009f91ba3ce91e407110dac5ce7f6140",
            ),
            (
              false, "2e91ea7c9e32fe86667367a1724b2c0f9", "39818eec519846cba11aaa22ee843e7320",
            ),
            (
              false, "a1a4465da1f49cccf2ac2ebbd40512a389", "36a17afa1a50a9a7d90c880795ca6e86f80",
            ),
            (
              true, "34bf28e8465b66a6fb6567f8e393d13abd", "1b50bd7d0d2854d3ec864403cae537437c0",
            ),
            (
              false, "a1a4465da1f49cccf2ac2ebbd40512a389", "36a17afa1a50a9a7d90c880795ca6e86f80",
            ),
            (
              true, "34bf28e8465b66a6fb6567f8e393d13abd", "1b50bd7d0d2854d3ec864403cae537437c0",
            ),
            (
              false, "690bd0dcac52bc8f3cb9ebd94ea68740a7ef", "6e8abed6113f3749a12f5b3f59179ba519d00",
            ),
            (
              false, "40c4e79a4aef4fa7e8f1a91925701e81f33", "7e556c625cda885425ecfa918a641f981d80",
            ),
          ],
          derivatives: [
            (
              true, "2fe3d05c82641e7bde87e2fded5ab5c117a4b67e3186e28051310c2d40dee21a7",
              "d170aefa2898082cd121865e0e2c466b3ef140aa15a9a1eb74a11882e7d5a2490",
            ),
            (
              false, "4d13c67a515f079422111b4a791f72a1d5d38475d5a963c256ee84db9c43785a5",
              "82e66d5c595f051c02b4f3fac8dbac030756c86a4d8a053328e4af51d0e5856da",
            ),
            (
              false, "e40518b5fd1c7d82cf4de7e450f93598c36f6a0114ab8dd676eef21671175ade2b9",
              "23f247080f5797e73124b0ffc48eb956081d88093117cd3a59546624f7aa3a8a6770",
            ),
            (
              false, "e39a980c0a423dcfce39319e1566faeea5ea277f7db671778afc468e700f1e29d99",
              "23f247080f5797e73124b0ffc48eb956081d88093117cd3a59546624f7aa3a8a6770",
            ),
            (
              false, "e40518b5fd1c7d82cf4de7e450f93598c36f6a0114ab8dd676eef21671175ade2b9",
              "23f247080f5797e73124b0ffc48eb956081d88093117cd3a59546624f7aa3a8a6770",
            ),
            (
              false, "e39a980c0a423dcfce39319e1566faeea5ea277f7db671778afc468e700f1e29d99",
              "23f247080f5797e73124b0ffc48eb956081d88093117cd3a59546624f7aa3a8a6770",
            ),
            (
              true, "72a7c6320f4029032e2272495fd4d399789126803ae69747046938b7f2f72a1540af",
              "14f7fec4b39dc346dcaabc9532a896c784bbe4b0074de26209713b959078a22611ac0",
            ),
            (
              true, "fbb2ade5dc439d18218fc1a7af0ce4898247c2bcf6d6a50b55467cf3d280940c739",
              "23f247080f5797e73124b0ffc48eb956081d88093117cd3a59546624f7aa3a8a6770",
            ),
            (
              false, "181542e286c13a15d5a36b8b04cdb1b36479946496cfae0a19fab79a243b955b3",
              "68b8577d144c04166890c32f071623359f78a0550ad4d0f5ba508c4173ead1248",
            ),
            (
              false, "65ea590109b153cff3075bdf39cc19d3208bbe50ea8b5f2e5eb7ec245f12c371",
              "d170aefa2898082cd121865e0e2c466b3ef140aa15a9a1eb74a11882e7d5a2490",
            ),
            (
              false, "354517d3174a125bfb1fa9cb4da2e6fc56819a08ca47772bfd9ffdfa0488c130c85",
              "2fedb40abf1f7534418641550613a1c80ad20ab6ec1fbc4dcc7088314a384e0ddf40",
            ),
            (
              true, "4df92d43ffa02e4c9eccb134713ab27400560ade2b39da882c83439efa343bbc8cd",
              "11f9238407abcbf39892587fe2475cab040ec404988be69d2caa33127bd51d4533b8",
            ),
            (
              false, "354517d3174a125bfb1fa9cb4da2e6fc56819a08ca47772bfd9ffdfa0488c130c85",
              "2fedb40abf1f7534418641550613a1c80ad20ab6ec1fbc4dcc7088314a384e0ddf40",
            ),
            (
              true, "4df92d43ffa02e4c9eccb134713ab27400560ade2b39da882c83439efa343bbc8cd",
              "11f9238407abcbf39892587fe2475cab040ec404988be69d2caa33127bd51d4533b8",
            ),
            (
              true, "456767ac1e9c3baee2255bf473062caf12be63855924e8d35a1646a7f642cbd0d089b",
              "14c81110a8dea3d1a8693653dda28325bcb112a55061c2a5bba4cb0d5f2e69d803ccc0",
            ),
            (
              false, "2d581b529d863e02c69e36c012905e60883bd470a959ca30db4e27aa1617d66f08337",
              "6ed5b058d9f8bf08d78677149e0d661e9905b8c702096373e8c43af1fba2348014440",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              false, "682b228c53a0cbb41fc21383e978889ab732894a872dae29993", "2e1f4aff723882fed27ba2dbaf15e252e9e02d83b11b3d6334e0",
            ),
            (
              true, "682b228c53a0cbb41fc21383e978889ab732894a872dae29993", "2e1f4aff723882fed27ba2dbaf15e252e9e02d83b11b3d6334e0",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "5618b159cb6875be494041c13b6a4bc295697fc719c122231307d", "d550badd70455dda8d7bd13809c536bf79acd281131dfbead48c0",
            ),
            (
              false, "5618b159cb6875be494041c13b6a4bc295697fc719c122231307d", "d550badd70455dda8d7bd13809c536bf79acd281131dfbead48c0",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "a48bda179b33e5acbc746a2a10028c22677619f91ed779b8af1", "170fa57fb91c417f693dd16dd78af12974f016c1d88d9eb19a70",
            ),
            (
              true, "a48bda179b33e5acbc746a2a10028c22677619f91ed779b8af1", "170fa57fb91c417f693dd16dd78af12974f016c1d88d9eb19a70",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "682b228c53a0cbb41fc21383e978889ab732894a872dae29993", "2e1f4aff723882fed27ba2dbaf15e252e9e02d83b11b3d6334e0",
            ),
            (
              false, "682b228c53a0cbb41fc21383e978889ab732894a872dae29993", "2e1f4aff723882fed27ba2dbaf15e252e9e02d83b11b3d6334e0",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "216dc2d08a6138275d6fdb818ff21c945a1", "45bf292ba34350991f9ad50059bc9c1bfaf4",
            ),
            (
              false, "216dc2d08a6138275d6fdb818ff21c945a1", "45bf292ba34350991f9ad50059bc9c1bfaf4",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "216dc2d08a6138275d6fdb818ff21c945a1", "45bf292ba34350991f9ad50059bc9c1bfaf4",
            ),
            (
              true, "216dc2d08a6138275d6fdb818ff21c945a1", "45bf292ba34350991f9ad50059bc9c1bfaf4",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
          ],
          ricci: [
            (
              true, "a48bda179b33e5acbc746a2a10028c22677619f91ed779b8af1", "170fa57fb91c417f693dd16dd78af12974f016c1d88d9eb19a70",
            ),
            (
              false, "682b228c53a0cbb41fc21383e978889ab732894a872dae29993", "2e1f4aff723882fed27ba2dbaf15e252e9e02d83b11b3d6334e0",
            ),
            (
              false, "682b228c53a0cbb41fc21383e978889ab732894a872dae29993", "2e1f4aff723882fed27ba2dbaf15e252e9e02d83b11b3d6334e0",
            ),
            (
              true, "5618b159cb6875be494041c13b6a4bc295697fc719c122231307d", "d550badd70455dda8d7bd13809c536bf79acd281131dfbead48c0",
            ),
          ],
        },
        {
          alpha: (false, "1", "1"),
          scalar: (
            true, "8fc514adc942fbe9d4929e7b61485e77d5723", "cd46ae86a49563927658289f5743634e8472",
          ),
          lower: [
            (
              false, "2462a2bbe677674ab8805b6a0bcef6", "3c9455d1f20f1493c9e08bfe8126d0b",
            ),
            (
              true, "1a474a0a7b7f08e27e28f97f70759e3", "70126b9133024c77cf129c96d5549bac",
            ),
            (
              false, "2008f3fad8494d095f96f055aa2f7", "9b1556945730d884942a5c2521ab0c",
            ),
            (
              true, "836a6f5e81de02e388d42e00c8f0c", "1de2c759eb781464373829c1d27cf65",
            ),
            (
              false, "2008f3fad8494d095f96f055aa2f7", "9b1556945730d884942a5c2521ab0c",
            ),
            (
              true, "836a6f5e81de02e388d42e00c8f0c", "1de2c759eb781464373829c1d27cf65",
            ),
            (
              false, "c842a4d2572758c929f009fbac355", "344cdcdd5c1223af60a24913305aaf0c",
            ),
            (
              false, "e89ceae8b2b751ef793f175564e6dedd", "5ab54f0febaf75e42b9976bd47dd4798d0",
            ),
          ],
          lower_first: [
            (
              false, "b14b0b0c29ad1b1ad3e57d5fa6971cfe6e1db0280268", "a7df2c4d0f71ff0fbd235a6c2cd314cdfc218f6fdd1283",
            ),
            (
              false, "4d423d0a06cbddae120c62711c79e01a06c82eaadc718", "64b91a94a2ddff6fd7e2030db47ea61530e0efa984a4b5",
            ),
            (
              false, "9af9e441fb1d1632e32dc9f380dd4f26d3beb11ab880", "14250550ed5f997cc4c6cd692419546aa3602feeb420f1",
            ),
            (
              false, "13a3d7935ea30d45cebff132f3a6773a883c650a3fdb10", "2e959c4b24ed12f0870bbb03237a933699ce6ed8008c2d5",
            ),
            (
              false, "9af9e441fb1d1632e32dc9f380dd4f26d3beb11ab880", "14250550ed5f997cc4c6cd692419546aa3602feeb420f1",
            ),
            (
              false, "13a3d7935ea30d45cebff132f3a6773a883c650a3fdb10", "2e959c4b24ed12f0870bbb03237a933699ce6ed8008c2d5",
            ),
            (
              true, "7a4df9630ab60b49e953bd728b8033cd00677eb01d0d7", "2e959c4b24ed12f0870bbb03237a933699ce6ed8008c2d5",
            ),
            (
              true, "192acf7e5ae4a857fbd671fb10e5a4a88503518a609b91f", "28c2e8c1c04f7092762a43a2bf0b40cfc694a0fd007aa7a6",
            ),
            (
              false, "31acd552fa99109f40c72a21f98a103efa5d106e53864", "64b91a94a2ddff6fd7e2030db47ea61530e0efa984a4b5",
            ),
            (
              true, "18e1f7740d00a2fd5e67d99f547aeb34ab88624e9ed28", "2e959c4b24ed12f0870bbb03237a933699ce6ed8008c2d5",
            ),
            (
              false, "8d70a6f37c418e5fb8be53b10f24ad9b6736d4b36d70", "14250550ed5f997cc4c6cd692419546aa3602feeb420f1",
            ),
            (
              true, "1a7bfbcb60de354caaf356a96b59f7771def721248c664", "2e959c4b24ed12f0870bbb03237a933699ce6ed8008c2d5",
            ),
            (
              false, "8d70a6f37c418e5fb8be53b10f24ad9b6736d4b36d70", "14250550ed5f997cc4c6cd692419546aa3602feeb420f1",
            ),
            (
              true, "1a7bfbcb60de354caaf356a96b59f7771def721248c664", "2e959c4b24ed12f0870bbb03237a933699ce6ed8008c2d5",
            ),
            (
              true, "18777c7bc4202ee22d1664ab37ed2e532a2b1ab0e524059", "28c2e8c1c04f7092762a43a2bf0b40cfc694a0fd007aa7a6",
            ),
            (
              false, "1614609624c831267770cdd1565a1a17bbe6ba224cde234f", "1aee7e5b71590ef30e12c81dd082dd1b90eb5814e0510a324",
            ),
          ],
          coefficients: [
            (
              false, "5f6f750c98960023f860a4da0b44e4183d", "da85ebe86942a69f6432201e5729ba1be0",
            ),
            (
              true, "168cc546700676b384eeb708fc4c7abb05", "2224ecdc50726a08e7a7d504bd9e85145b0",
            ),
            (
              false, "28a6366a5b204ae0fe09d023dfbc9e3609", "1b50bd7d0d2854d3ec864403cae537437c0",
            ),
            (
              true, "2a95bdd12be18c079f65359dc85af6643d", "da85ebe86942a69f6432201e5729ba1be0",
            ),
            (
              false, "28a6366a5b204ae0fe09d023dfbc9e3609", "1b50bd7d0d2854d3ec864403cae537437c0",
            ),
            (
              true, "2a95bdd12be18c079f65359dc85af6643d", "da85ebe86942a69f6432201e5729ba1be0",
            ),
            (
              false, "2c886684567748672d810356329c60e4b75", "2e8b42e0ded73fb33664c81aac3fd5bec780",
            ),
            (
              false, "82ab9c9deeb5c2cde37a11f73a926252a1", "35317100feacdb15f50576f9e96d8690e40",
            ),
          ],
          derivatives: [
            (
              true, "82ef5a5ccb1c3acc6b198983e6ff8194fddab6d1899dbf9a08eaf1f7992c7ecf7",
              "2973a2a182b36c48deb94d429d78c34539ca6a21a99ee80bef15378493379d73c8",
            ),
            (
              false, "266c86fe2667dad261f4ea8cd50dbaa851192be2ab1304c69a2d5b69db208f63bf",
              "4db8d0eed5106b08a19b70dce7426e21cc5b86ff1e09f3166047c8189408473917",
            ),
            (
              false, "7abb8dd8f4bf9d2b868536dd8ebc6d7659f8ab16c1c50f3913c0b35bfcb8edba639",
              "11f9238407abcbf39892587fe2475cab040ec404988be69d2caa33127bd51d4533b8",
            ),
            (
              false, "770a6362da97f7ab56a99e5dbdca36f13d46c0b0a13783c8fbeba369914bd9cfd19",
              "11f9238407abcbf39892587fe2475cab040ec404988be69d2caa33127bd51d4533b8",
            ),
            (
              false, "7abb8dd8f4bf9d2b868536dd8ebc6d7659f8ab16c1c50f3913c0b35bfcb8edba639",
              "11f9238407abcbf39892587fe2475cab040ec404988be69d2caa33127bd51d4533b8",
            ),
            (
              false, "770a6362da97f7ab56a99e5dbdca36f13d46c0b0a13783c8fbeba369914bd9cfd19",
              "11f9238407abcbf39892587fe2475cab040ec404988be69d2caa33127bd51d4533b8",
            ),
            (
              true, "366f9aecff26b74aef41f7a84e0bf380e413024154e7e45a98ca4d0be0ce1f4bfb5",
              "8d435604ba0be02e3a63474b7039dcd455c962f2b7f1bf3624a9fd32f5b36cca920",
            ),
            (
              true, "906d82c429d9b41b6584eb09587a54db6d6ca8749b94a797a3d2e0eaae1aa913c3",
              "f22a4a513eefc973d1cec35cc063316c00c6f2c4a90c23383eda44575c0f03a468",
            ),
            (
              false, "c879a0119aac90197b9b7c5fdd6107ccb190994d64326438f13eacc3f43ddfe75",
              "3e2d73f2440d226d4e15f3e3ec3524e7d6af9f327e6e5c11e69fd346dcd36c2dac",
            ),
            (
              false, "c8e79905ea8cf16d5ecb019406ec9d1b75c8f592882fcd9a7fdf670b78c71e773",
              "7c5ae7e4881a44da9c2be7c7d86a49cfad5f3e64fcdcb823cd3fa68db9a6d85b58",
            ),
            (
              false, "33e61d7d7bd14b638bbc3682f02ef59765df4eec4c7c29eb2d301de274fe25a54d5",
              "17f6da055f8fba9a20c320aa8309d0e40569055b760fde26e6384418a51c2706efa0",
            ),
            (
              true, "3a733f0417b05c2ecb8cba40ca28924ebc8dd69c45132054af3015afb6b287f3059",
              "8fc91c203d5e5f9cc492c3ff123ae55820762024c45f34e965519893dea8ea299dc",
            ),
            (
              false, "33e61d7d7bd14b638bbc3682f02ef59765df4eec4c7c29eb2d301de274fe25a54d5",
              "17f6da055f8fba9a20c320aa8309d0e40569055b760fde26e6384418a51c2706efa0",
            ),
            (
              true, "3a733f0417b05c2ecb8cba40ca28924ebc8dd69c45132054af3015afb6b287f3059",
              "8fc91c203d5e5f9cc492c3ff123ae55820762024c45f34e965519893dea8ea299dc",
            ),
            (
              true, "2614bc02ea0f7694708c40b048703ccd2666011abe31a8637b1a704ced0ace026a05",
              "8c0072f6f862a076f54b88f19f39589270730459b1bb045c84562f828138ae1b0c20",
            ),
            (
              false, "1b6c111fe1d0478d63f95da72daf40272d2aadcc0401258d1c60390a2558e99641f5",
              "2eaad0fcfd76357cfc6e82fb35131d86257bac1de5e901742c1cba80d5bd8f5e5960",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              false, "75f9c372df7bf15a583c35b362d170d9102f1e76878cf6d39", "232cf75ad7bf4f5032b43813146720064a2337cff8b5712b60",
            ),
            (
              true, "75f9c372df7bf15a583c35b362d170d9102f1e76878cf6d39", "232cf75ad7bf4f5032b43813146720064a2337cff8b5712b60",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "2857b5cc3e094eae41fa37d13a3838c18c3c7b74eb3cff715fd53", "54856bda27a78f7393d5493cd8664ad31ce3df7b987af98d590c0",
            ),
            (
              false, "2857b5cc3e094eae41fa37d13a3838c18c3c7b74eb3cff715fd53", "54856bda27a78f7393d5493cd8664ad31ce3df7b987af98d590c0",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "7b69d7bbdea9fd0efd07de6f6095332f45e22ea67553ffe53", "11967bad6bdfa7a8195a1c098a33900325119be7fc5ab895b0",
            ),
            (
              true, "7b69d7bbdea9fd0efd07de6f6095332f45e22ea67553ffe53", "11967bad6bdfa7a8195a1c098a33900325119be7fc5ab895b0",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "7472bc503619a7ac5cc751cfc83b9110a02cbdf5009a602dbb", "29c565bbe0332e2f3c360296a83a76077809d246f7577663820",
            ),
            (
              false, "7472bc503619a7ac5cc751cfc83b9110a02cbdf5009a602dbb", "29c565bbe0332e2f3c360296a83a76077809d246f7577663820",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (
              false, "33a5fb1ad8e169fe29eb051583530778", "2224ecdc50726a08e7a7d504bd9e85145b",
            ),
            (
              true, "33a5fb1ad8e169fe29eb051583530778", "2224ecdc50726a08e7a7d504bd9e85145b",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "3e5072c89f4e320c312e04c92456fef074", "6e8abed6113f3749a12f5b3f59179ba519d",
            ),
            (
              false, "3e5072c89f4e320c312e04c92456fef074", "6e8abed6113f3749a12f5b3f59179ba519d",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "404e95a969860b4c3a0a054581bba487", "91ae9d459b81c46a42cc15698f7126bd4",
            ),
            (
              true, "404e95a969860b4c3a0a054581bba487", "91ae9d459b81c46a42cc15698f7126bd4",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "29a088d5738ae616e6b60f5bd51612bdf", "126c7523ad8a8936f0328f353983ef462ef8",
            ),
            (
              false, "29a088d5738ae616e6b60f5bd51612bdf", "126c7523ad8a8936f0328f353983ef462ef8",
            ),
            (false, "0", "1"),
          ],
          ricci: [
            (
              true, "7b69d7bbdea9fd0efd07de6f6095332f45e22ea67553ffe53", "11967bad6bdfa7a8195a1c098a33900325119be7fc5ab895b0",
            ),
            (
              false, "75f9c372df7bf15a583c35b362d170d9102f1e76878cf6d39", "232cf75ad7bf4f5032b43813146720064a2337cff8b5712b60",
            ),
            (
              false, "7472bc503619a7ac5cc751cfc83b9110a02cbdf5009a602dbb", "29c565bbe0332e2f3c360296a83a76077809d246f7577663820",
            ),
            (
              true, "2857b5cc3e094eae41fa37d13a3838c18c3c7b74eb3cff715fd53", "54856bda27a78f7393d5493cd8664ad31ce3df7b987af98d590c0",
            ),
          ],
        },
        {
          alpha: (true, "1", "1"),
          scalar: (
            true, "8fc514adc942fbe9d4929e7b61485e77d5723", "cd46ae86a49563927658289f5743634e8472",
          ),
          lower: [
            (false, "4dd672828f6", "784274a23797"),
            (true, "2e061cf00b1", "379ebc57d34f7"),
            (false, "dff01753210327", "23f30d9e5f854cb6"),
            (true, "2851bc9a58819b13", "e8c5c4fb10e583e74"),
            (false, "dff01753210327", "23f30d9e5f854cb6"),
            (true, "2851bc9a58819b13", "e8c5c4fb10e583e74"),
            (false, "e35d768a", "79e6ae8725"),
            (true, "7184a05cd", "3554ec5b203"),
          ],
          lower_first: [
            (false, "be1c17f5d9efc05d691f58", "fad4ebaf0239070bb21f2f37"),
            (false, "3309fbe3633e7a35f37da0", "3582c1a3a0e69e8433a7145"),
            (
              false, "63c1f0338d745cd4de2df95cf2e8a8", "956de4c1995865f51418d0c91c70cf9",
            ),
            (
              false, "aea0dafc37b3b72bc87e9f164f0f7", "1de2c759eb781464373829c1d27cf65",
            ),
            (
              false, "63c1f0338d745cd4de2df95cf2e8a8", "956de4c1995865f51418d0c91c70cf9",
            ),
            (
              false, "aea0dafc37b3b72bc87e9f164f0f7", "1de2c759eb781464373829c1d27cf65",
            ),
            (true, "ccc7b492104b3b81a0", "3a0be0d9d2cc79a40b59"),
            (true, "41bc383ad7a512b8c7c", "1965325f4c397537c4f6f"),
            (false, "af4f1e180057d020fa6df4", "10b8dc832248118950243659"),
            (true, "1d6a89c41c6c87b187fe640", "7bbe5fca64154e91b7725ef9"),
            (
              false, "7020cbbb1dbb13096abd7fe010898", "1de2c759eb781464373829c1d27cf65",
            ),
            (
              true, "cbd98a7a5476af803ea9bbeb6ccab0b", "3c78df5ff274f942c7bba47e2fe8da65e",
            ),
            (
              false, "7020cbbb1dbb13096abd7fe010898", "1de2c759eb781464373829c1d27cf65",
            ),
            (
              true, "cbd98a7a5476af803ea9bbeb6ccab0b", "3c78df5ff274f942c7bba47e2fe8da65e",
            ),
            (true, "e121fec9031ff33cf0", "3a0be0d9d2cc79a40b59"),
            (false, "85726e207a5bebb2d7f", "1965325f4c397537c4f6f"),
          ],
          coefficients: [
            (false, "55e1c868fc077413d4", "a218c17a0d93aa38ab"),
            (false, "737f87e2339ac500b8", "32a7bc76243e2531b57"),
            (false, "2ce00374726cfdb3ae", "a218c17a0d93aa38ab"),
            (true, "789aff9098d899144", "a218c17a0d93aa38ab"),
            (false, "2ce00374726cfdb3ae", "a218c17a0d93aa38ab"),
            (true, "789aff9098d899144", "a218c17a0d93aa38ab"),
            (false, "131f74bb0b2f6f936f", "1443182f41b27547156"),
            (true, "e7fc84d991e1e297b", "a218c17a0d93aa38ab"),
          ],
          derivatives: [
            (
              true, "500648eae4b79a4e2feb6198b113ea96f310", "133ea05c9f6e0155bb1843cef02e514f5c6ab",
            ),
            (
              false, "41bf26fe0b46130ace9d36c355a294a9ca780", "603921cf1d2606aca779530ab0e7968cce157",
            ),
            (
              false, "259415b41e2ff0c6ca4d5debf61eb9dd5d70", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (
              false, "26bf6a423e41fef2246915eabaf6555318f0", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (
              false, "259415b41e2ff0c6ca4d5debf61eb9dd5d70", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (
              false, "26bf6a423e41fef2246915eabaf6555318f0", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (
              true, "1e99b0016f9b63ff2eeaf672a6d8a24d6de6", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (
              true, "1c9ef2c1c8c050a67fe2af61bb276574cf88", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (
              false, "1a867fdd1499a2badbd9a2268c85d5366167", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (
              true, "41ee18810fd9ca2dee598092beab0cd8016", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (
              false, "bbe7343cb1da1d57012999c62eb182715f", "cd46ae86a49563927658289f5743634e8472",
            ),
            (
              true, "defa89019fef3bbe36ed23a42195a070973", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (
              false, "bbe7343cb1da1d57012999c62eb182715f", "cd46ae86a49563927658289f5743634e8472",
            ),
            (
              true, "defa89019fef3bbe36ed23a42195a070973", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (
              true, "776fbb40ffc1645a5851166c3d1d8da704cd", "3351aba1a92558e49d960a27d5d0d8d3a11c8",
            ),
            (
              false, "5eae87afca13cbb409073b62b53d4195f469", "19a8d5d0d492ac724ecb0513eae86c69d08e4",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              false, "8de7565ac844d85e1952fcdce8c381cce3d", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (
              true, "8de7565ac844d85e1952fcdce8c381cce3d", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "4bc5a9f4d7b4b79d60eaf79b1800851fe97f", "cd46ae86a49563927658289f5743634e8472",
            ),
            (
              false, "4bc5a9f4d7b4b79d60eaf79b1800851fe97f", "cd46ae86a49563927658289f5743634e8472",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "32fa00869adb46ccfcbe78affddacd923c7e", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (
              true, "32fa00869adb46ccfcbe78affddacd923c7e", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "c8029c051af5c648f95512fde015ee39849", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (
              false, "c8029c051af5c648f95512fde015ee39849", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (
              true, "33a5fb1ad8e169fe29eb051583530778", "2224ecdc50726a08e7a7d504bd9e85145b",
            ),
            (
              false, "33a5fb1ad8e169fe29eb051583530778", "2224ecdc50726a08e7a7d504bd9e85145b",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "404e95a969860b4c3a0a054581bba487", "91ae9d459b81c46a42cc15698f7126bd4",
            ),
            (
              false, "404e95a969860b4c3a0a054581bba487", "91ae9d459b81c46a42cc15698f7126bd4",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "3e5072c89f4e320c312e04c92456fef074", "6e8abed6113f3749a12f5b3f59179ba519d",
            ),
            (
              true, "3e5072c89f4e320c312e04c92456fef074", "6e8abed6113f3749a12f5b3f59179ba519d",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "29a088d5738ae616e6b60f5bd51612bdf", "126c7523ad8a8936f0328f353983ef462ef8",
            ),
            (
              true, "29a088d5738ae616e6b60f5bd51612bdf", "126c7523ad8a8936f0328f353983ef462ef8",
            ),
            (false, "0", "1"),
          ],
          ricci: [
            (
              true, "32fa00869adb46ccfcbe78affddacd923c7e", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (
              false, "8de7565ac844d85e1952fcdce8c381cce3d", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (
              false, "c8029c051af5c648f95512fde015ee39849", "66a35743524ab1c93b2c144faba1b1a74239",
            ),
            (
              true, "4bc5a9f4d7b4b79d60eaf79b1800851fe97f", "cd46ae86a49563927658289f5743634e8472",
            ),
          ],
        },
        {
          alpha: (false, "3", "5"),
          scalar: (
            true, "8b81f3a1fb618e17ac09c4c6eaf5988cb9413", "cd46ae86a49563927658289f5743634e8472",
          ),
          lower: [
            (
              false, "b8c044f335b3aa075196e1823bc216", "12ee5ad19ba4b66e2f162bbf885c2137",
            ),
            (
              true, "1bba3bc77d69e1b626147e0f7351580", "8c1706757fc2df95c2d743bc8aa9c297",
            ),
            (
              false, "1d74ba1672e1d6b028d6551cbd9c91", "7928aba3e41e292793c117fd024da16",
            ),
            (
              true, "428db18ce6b3354a4251151b91978cd", "105805052cc5ab26ce32b6d5ff1c56b3c",
            ),
            (
              false, "1d74ba1672e1d6b028d6551cbd9c91", "7928aba3e41e292793c117fd024da16",
            ),
            (
              true, "428db18ce6b3354a4251151b91978cd", "105805052cc5ab26ce32b6d5ff1c56b3c",
            ),
            (
              false, "24e7424b9017e418695290fb1aa49b", "41601414b316ac9b38cadb57fc715acf",
            ),
            (
              false, "54458a14b47e1ccf9f769bb717162fb", "33d551bff464435dcfc5686c2910bb32c",
            ),
          ],
          lower_first: [
            (
              false, "9cd376b6ca7c98a827081a2ad11a30461995d59cbfb88", "9d6139883e7adf1ec15124c56a05e3811c5f7678df415ad",
            ),
            (
              false, "1951afe33aa2ed9f0f21c9005a1f785ad4aa298c2f7800", "1f79d84e72e55fd2f376a0f4486793e69f464ae4f973789",
            ),
            (
              false, "104f641a8a090f83a1ad62f5c8ceff0d7d393a42669908", "1f79d84e72e55fd2f376a0f4486793e69f464ae4f973789",
            ),
            (
              false, "5f929594ff46cbbf1c7a34fbfd33f2028b65ce5b51d107", "e8ec0d77b8a15eb2a33aa70fb164e01101082a3802bce29",
            ),
            (
              false, "104f641a8a090f83a1ad62f5c8ceff0d7d393a42669908", "1f79d84e72e55fd2f376a0f4486793e69f464ae4f973789",
            ),
            (
              false, "5f929594ff46cbbf1c7a34fbfd33f2028b65ce5b51d107", "e8ec0d77b8a15eb2a33aa70fb164e01101082a3802bce29",
            ),
            (
              true, "28d8fe3acd415a25062fac3690a472522de8826ef68a7c", "e8ec0d77b8a15eb2a33aa70fb164e01101082a3802bce29",
            ),
            (
              true, "18846f498f0cef5efcf7bae4f685211a97053e07d81d2e", "2e959c4b24ed12f0870bbb03237a933699ce6ed8008c2d5",
            ),
            (
              false, "34f07f20bdc9c774d4d68ce2d68c87e0126e697b44a24", "64b91a94a2ddff6fd7e2030db47ea61530e0efa984a4b5",
            ),
            (
              true, "3757c75c66e15acc87b40d4ae15cace9adfda35413060", "2e959c4b24ed12f0870bbb03237a933699ce6ed8008c2d5",
            ),
            (
              false, "8044a01277fc0e74d751444447d7cf76a46be9041898", "14250550ed5f997cc4c6cd692419546aa3602feeb420f1",
            ),
            (
              true, "1441af78ecb062069331730aa5ed227d7da6b470a2f1253", "28c2e8c1c04f7092762a43a2bf0b40cfc694a0fd007aa7a6",
            ),
            (
              false, "8044a01277fc0e74d751444447d7cf76a46be9041898", "14250550ed5f997cc4c6cd692419546aa3602feeb420f1",
            ),
            (
              true, "1441af78ecb062069331730aa5ed227d7da6b470a2f1253", "28c2e8c1c04f7092762a43a2bf0b40cfc694a0fd007aa7a6",
            ),
            (
              true, "ac657d15e071122d55975f0cff5cc2436d025a8c433c9a", "14617460e027b8493b1521d15f85a067e34a507e803d53d3",
            ),
            (
              false, "2201d71bc5fca3cf86c9b49b4d373a9bfe71b25d3468c058", "2f215d20065bda2958a0de342ce502f03d9bda24888dd1d7f",
            ),
          ],
          coefficients: [
            (
              false, "18e03f3a2071e4a44ea8e153b8349a4679", "36a17afa1a50a9a7d90c880795ca6e86f8",
            ),
            (
              true, "3164257d50db576bd48c682cf4b0af7a5", "2aae2813648f048b2191ca45ed06265971c",
            ),
            (
              false, "bf0cbdb7b6cb1bea643c6070cef9e337", "5c027e46e8f3a47901c4436b1739fd850",
            ),
            (
              true, "7999dbdcd38975b87d06161c744e9f43", "2e013f237479d23c80e221b58b9cfec28",
            ),
            (
              false, "bf0cbdb7b6cb1bea643c6070cef9e337", "5c027e46e8f3a47901c4436b1739fd850",
            ),
            (
              true, "7999dbdcd38975b87d06161c744e9f43", "2e013f237479d23c80e221b58b9cfec28",
            ),
            (
              false, "d2f4981019e2f1ff0bde06304f294d25f73", "dd157dac227e6e93425eb67eb22f374a33a0",
            ),
            (
              false, "1a839d13d8aabde1de9106dae51ae1706a7", "fcaad8c4b9b510a84bd9f52314c83f303b0",
            ),
          ],
          derivatives: [
            (
              true, "20a14a908345b151851feeb9eef2dc2e46b7a7e2ee0e3a2fc15b99a440cc6cf505",
              "9b71a1ddaa20d6114336e1b9ce84dc4398b70dfe3c13e62cc08f903128108e722e",
            ),
            (
              false, "295c3688bd91aeb16943d002fc994e6b6d0af030c963a428845a4333abc9f5d14c",
              "4db8d0eed5106b08a19b70dce7426e21cc5b86ff1e09f3166047c8189408473917",
            ),
            (
              false, "191a99b1e3827f89a88aacfd2db11d8ea51c0484447658bcb3f74945276119c547",
              "3c8a92944fbbf25cf473b0d73018cc5b0031bcb12a4308ce0fb69115d703c0e91a",
            ),
            (
              false, "7b19a226057b661139ba8969f5a2de43ddd73ea557ddae7d2828402ac43316a703",
              "12eb4dce58eabbbd0c6427433f07bfdc700f8af75d34f2c064e90d56d3312c48d82",
            ),
            (
              false, "191a99b1e3827f89a88aacfd2db11d8ea51c0484447658bcb3f74945276119c547",
              "3c8a92944fbbf25cf473b0d73018cc5b0031bcb12a4308ce0fb69115d703c0e91a",
            ),
            (
              false, "7b19a226057b661139ba8969f5a2de43ddd73ea557ddae7d2828402ac43316a703",
              "12eb4dce58eabbbd0c6427433f07bfdc700f8af75d34f2c064e90d56d3312c48d82",
            ),
            (
              true, "f6dde4e51694de64e8645d40c4b2b8dd50dd7ed3fab3c3d49d6188f503112e0ff33",
              "29effd89673b868db955792a65512d8f0977c9600e9bc4c412e2772b20f1444c2358",
            ),
            (
              true, "264fa3fcd5aaf589495c76bfa61cd5bdf60157be380e02e793d84982cb232d84f15",
              "47e48e101eaf2fce624961ff891d72ac103b1012622f9a74b2a8cc49ef547514cee",
            ),
            (
              false, "34f33df370d173322a4c2c05a5c529fc53af972b2b19a792234461efd3db7c462",
              "f8b5cfc9103489b53857cf8fb0d4939f5abe7cc9f9b970479a7f4d1b734db0b6b",
            ),
            (
              false, "b4ef4530beca59f3c33e70754a5a0d7f460034adebc53a75a406276366cee8def",
              "9b71a1ddaa20d6114336e1b9ce84dc4398b70dfe3c13e62cc08f903128108e722e",
            ),
            (
              false, "8cc708487306b4e6d1105f35f9638ea8c77e556cecf531215c6c0523f7965d0df",
              "50b8c3706a4fedd145ef9674402110795597a6418daeb66814f36c1d1eafabe178",
            ),
            (
              true, "aaa909a490a288a7c04d63ae5b6c1118650d2cef24aea40ef95084801468fa54a",
              "1e45494a27ddf92e7a39d86b980c662d8018de589521846707db488aeb81e0748d",
            ),
            (
              false, "8cc708487306b4e6d1105f35f9638ea8c77e556cecf531215c6c0523f7965d0df",
              "50b8c3706a4fedd145ef9674402110795597a6418daeb66814f36c1d1eafabe178",
            ),
            (
              true, "aaa909a490a288a7c04d63ae5b6c1118650d2cef24aea40ef95084801468fa54a",
              "1e45494a27ddf92e7a39d86b980c662d8018de589521846707db488aeb81e0748d",
            ),
            (
              true, "5206e895ccfaeda647a39a902ed59bb72b03e961d91586af19db62b0cde3b716f74b",
              "14c81110a8dea3d1a8693653dda28325bcb112a55061c2a5bba4cb0d5f2e69d803ccc",
            ),
            (
              false, "726dad1027fcfd88623876b61dda28bce0e97fac5fb17ff94050c24b6283abab75bd",
              "ddab60b1b3f17e11af0cee293c1acc3d320b718e0412c6e7d18875e3f74469002888",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              false, "9cc8cd0d65930094360060e0ef30f059d2d32aae27094f444f", "3642eed22c063fc26109ecc637650a436d80358bdf6b5747898",
            ),
            (
              true, "9cc8cd0d65930094360060e0ef30f059d2d32aae27094f444f", "3642eed22c063fc26109ecc637650a436d80358bdf6b5747898",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "9bb043a2003db6bc83f35f880499b3072046a923752110769fdb", "15f57ca5da9dba9a4345376b6a6ae3c0e31d15ab679d708559a50",
            ),
            (
              false, "9bb043a2003db6bc83f35f880499b3072046a923752110769fdb", "15f57ca5da9dba9a4345376b6a6ae3c0e31d15ab679d708559a50",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "3b3030d67c56eb3ad3f9914af24a7b6945704e1be7946ef5599", "87a7550d6e0f9f65f298cfef8a7c99a891c085ddae8c5a32d7c",
            ),
            (
              true, "3b3030d67c56eb3ad3f9914af24a7b6945704e1be7946ef5599", "87a7550d6e0f9f65f298cfef8a7c99a891c085ddae8c5a32d7c",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "8a5a5a38e33f57690d1e5b2d1625847fc2ce315d0d5765c76f", "3642eed22c063fc26109ecc637650a436d80358bdf6b5747898",
            ),
            (
              false, "8a5a5a38e33f57690d1e5b2d1625847fc2ce315d0d5765c76f", "3642eed22c063fc26109ecc637650a436d80358bdf6b5747898",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (
              false, "33a5fb1ad8e169fe29eb051583530778", "38e8356f30beb0b98217b85d3c083321ed",
            ),
            (
              true, "33a5fb1ad8e169fe29eb051583530778", "38e8356f30beb0b98217b85d3c083321ed",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "190022e8b4327af148be3127339e8aeb98e25", "2fadad24d49b0418ac9ad79b3d57eeb7208ccc",
            ),
            (
              false, "190022e8b4327af148be3127339e8aeb98e25", "2fadad24d49b0418ac9ad79b3d57eeb7208ccc",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "56020e8a7e62d1afc26997171577f50d3e23", "beb6b493526c1062b26b5e6cf55fbadc82333",
            ),
            (
              true, "56020e8a7e62d1afc26997171577f50d3e23", "beb6b493526c1062b26b5e6cf55fbadc82333",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "18f9ebb3455356da8a6d3c6a4ca6d80b9", "126c7523ad8a8936f0328f353983ef462ef8",
            ),
            (
              false, "18f9ebb3455356da8a6d3c6a4ca6d80b9", "126c7523ad8a8936f0328f353983ef462ef8",
            ),
            (false, "0", "1"),
          ],
          ricci: [
            (
              true, "3b3030d67c56eb3ad3f9914af24a7b6945704e1be7946ef5599", "87a7550d6e0f9f65f298cfef8a7c99a891c085ddae8c5a32d7c",
            ),
            (
              false, "9cc8cd0d65930094360060e0ef30f059d2d32aae27094f444f", "3642eed22c063fc26109ecc637650a436d80358bdf6b5747898",
            ),
            (
              false, "8a5a5a38e33f57690d1e5b2d1625847fc2ce315d0d5765c76f", "3642eed22c063fc26109ecc637650a436d80358bdf6b5747898",
            ),
            (
              true, "9bb043a2003db6bc83f35f880499b3072046a923752110769fdb", "15f57ca5da9dba9a4345376b6a6ae3c0e31d15ab679d708559a50",
            ),
          ],
        },
        {
          alpha: (true, "3", "5"),
          scalar: (
            true, "8b81f3a1fb618e17ac09c4c6eaf5988cb9413", "cd46ae86a49563927658289f5743634e8472",
          ),
          lower: [
            (
              false, "c1398aca55cf9abc76d62ad23de7ee", "12ee5ad19ba4b66e2f162bbf885c2137",
            ),
            (
              true, "317665da9a2c961cfce1427f9e313b3", "2305c19d5ff0b7e570b5d0ef22aa70a5c",
            ),
            (
              false, "557bd90bc1371c65569f22545f262b", "f2515747c83c524f27822ffa049b42c",
            ),
            (
              true, "ca709df236f261aef320e3d3f2cce1", "41601414b316ac9b38cadb57fc715acf",
            ),
            (
              false, "557bd90bc1371c65569f22545f262b", "f2515747c83c524f27822ffa049b42c",
            ),
            (
              true, "ca709df236f261aef320e3d3f2cce1", "41601414b316ac9b38cadb57fc715acf",
            ),
            (
              false, "192b5aa33cfc95e49fdd80655b8d7b5", "105805052cc5ab26ce32b6d5ff1c56b3c",
            ),
            (
              true, "6beffa2928b32c210f7f03fe8d194ec7", "5ab54f0febaf75e42b9976bd47dd4798d0",
            ),
          ],
          lower_first: [
            (
              false, "80aacbc8f4bb8665282af80e3fdfbf8cd0a3d702781d8", "9d6139883e7adf1ec15124c56a05e3811c5f7678df415ad",
            ),
            (
              false, "1cd8a653842c96a90b9b87b75dcb9f52ec4cfa708f3598", "1f79d84e72e55fd2f376a0f4486793e69f464ae4f973789",
            ),
            (
              false, "13d65a8ad392b88d9e2721accc7b260594dc0b26c656a0", "1f79d84e72e55fd2f376a0f4486793e69f464ae4f973789",
            ),
            (
              false, "57b0b4b1718d67e554a9b1f3ae0ecb9c320d4dd3896e2c", "e8ec0d77b8a15eb2a33aa70fb164e01101082a3802bce29",
            ),
            (
              false, "13d65a8ad392b88d9e2721accc7b260594dc0b26c656a0", "1f79d84e72e55fd2f376a0f4486793e69f464ae4f973789",
            ),
            (
              false, "57b0b4b1718d67e554a9b1f3ae0ecb9c320d4dd3896e2c", "e8ec0d77b8a15eb2a33aa70fb164e01101082a3802bce29",
            ),
            (
              true, "30badf1e5afabdfece002f3edfc998b8874102f6beed57", "e8ec0d77b8a15eb2a33aa70fb164e01101082a3802bce29",
            ),
            (
              true, "a4f170663ff4cc481dfb8302c2105e38188647c52936b3", "28c2e8c1c04f7092762a43a2bf0b40cfc694a0fd007aa7a6",
            ),
            (
              false, "3ebb7c8a075bebf59104b5256d93eec35aa274a217f64", "64b91a94a2ddff6fd7e2030db47ea61530e0efa984a4b5",
            ),
            (
              true, "92b937157483823a0398a84d8801f208b55d66646fa08", "2e959c4b24ed12f0870bbb03237a933699ce6ed8008c2d5",
            ),
            (
              false, "58c08b6f6b2b8eb4330a15fdf1f135085c0b25f61a10", "14250550ed5f997cc4c6cd692419546aa3602feeb420f1",
            ),
            (
              true, "5c0a476ea3d1e1886038456eef4302ea4032329465de72", "14617460e027b8493b1521d15f85a067e34a507e803d53d3",
            ),
            (
              false, "58c08b6f6b2b8eb4330a15fdf1f135085c0b25f61a10", "14250550ed5f997cc4c6cd692419546aa3602feeb420f1",
            ),
            (
              true, "5c0a476ea3d1e1886038456eef4302ea4032329465de72", "14617460e027b8493b1521d15f85a067e34a507e803d53d3",
            ),
            (
              true, "ccc4917a3d7fc7023888184d7e6d62837ffdd3372323c5", "28c2e8c1c04f7092762a43a2bf0b40cfc694a0fd007aa7a6",
            ),
            (
              false, "5071856b5b5e34d0a05a6788be0f85cd7d2de102f8532005", "bc857480196f68a5628378d0b3940bc0f66f68922237475fc",
            ),
          ],
          coefficients: [
            (
              false, "6fb5947c3d5c49d9016c26ad617af81ed9", "da85ebe86942a69f6432201e5729ba1be0",
            ),
            (
              false, "120db69a33f859d18f5705159d3ca817afb", "aab8a04d923c122c86472917b4189965c70",
            ),
            (
              false, "68ec7e0b17b050835cea421a5692e32f35", "1b50bd7d0d2854d3ec864403cae537437c0",
            ),
            (
              true, "10a57ba2b78e97b436479968710c79f2d9", "da85ebe86942a69f6432201e5729ba1be0",
            ),
            (
              false, "68ec7e0b17b050835cea421a5692e32f35", "1b50bd7d0d2854d3ec864403cae537437c0",
            ),
            (
              true, "10a57ba2b78e97b436479968710c79f2d9", "da85ebe86942a69f6432201e5729ba1be0",
            ),
            (
              false, "344eaad8a5da000f79c26a4d3adc33f72a23", "37455f6b089f9ba4d097ad9fac8bcdd28ce80",
            ),
            (
              true, "29498cb517bba7df915272526efb673fb69", "3f2ab6312e6d442a12f67d48c5320fcc0ec0",
            ),
          ],
          derivatives: [
            (
              true, "99d37ae3391bafb964c718dbf57f267161835c018dd7f81adca4d1bbadf9aaa8e5",
              "26dc68776a88358450cdb86e73a13710e62dc37f8f04f98b3023e40c4a04239c8b8",
            ),
            (
              false, "a08a76e809ca20fb309b3477d72685759c6729f07444d42da2cfee9d2c13b6b97",
              "f8b5cfc9103489b53857cf8fb0d4939f5abe7cc9f9b970479a7f4d1b734db0b6b",
            ),
            (
              false, "6cc6bea904709fb4eebb3231b7efe933332a548ccf7968562018560df60a20751a5",
              "11f9238407abcbf39892587fe2475cab040ec404988be69d2caa33127bd51d4533b8",
            ),
            (
              false, "2294b36079941103d34e7eb5f1c3d46e6dfd45bec13333a83382e2ffd0c58eb37f19",
              "59ddb194265afbc1fadbba7f6b64cf571449d416fabb8111df52ff5c6b29925a0298",
            ),
            (
              false, "6cc6bea904709fb4eebb3231b7efe933332a548ccf7968562018560df60a20751a5",
              "11f9238407abcbf39892587fe2475cab040ec404988be69d2caa33127bd51d4533b8",
            ),
            (
              false, "2294b36079941103d34e7eb5f1c3d46e6dfd45bec13333a83382e2ffd0c58eb37f19",
              "59ddb194265afbc1fadbba7f6b64cf571449d416fabb8111df52ff5c6b29925a0298",
            ),
            (
              true, "34f04cf8c99af169f4095af92ea825622459c6cb3c39a651dd10d67ab232de9143e3",
              "a7bff6259cee1a36e555e4a99544b63c25df25803a6f13104b89dcac83c511308d60",
            ),
            (
              true, "62741df28597c6f2fc1de6a916998d91aa4263c4169e996d05e556e8a5f3ddf8ae5",
              "11f9238407abcbf39892587fe2475cab040ec404988be69d2caa33127bd51d4533b8",
            ),
            (
              false, "f5c6ff023d1182d631f04b3ac42f885f2647a6ca85034c77608a18b160fe24ac1",
              "3e2d73f2440d226d4e15f3e3ec3524e7d6af9f327e6e5c11e69fd346dcd36c2dac",
            ),
            (
              true, "769da44cd19c862c59fe1057c23c5ca786c318b73e7964b33db49375a6bc3b0cd",
              "26dc68776a88358450cdb86e73a13710e62dc37f8f04f98b3023e40c4a04239c8b8",
            ),
            (
              false, "b7a015d952414a7750ecd87479958a23b4818ac73eeac96162fec7357081d90a51",
              "17f6da055f8fba9a20c320aa8309d0e40569055b760fde26e6384418a51c2706efa0",
            ),
            (
              true, "1b4efe6724afedbad1b5b79cae169d60c25621872c5601d3ba7f5c48f425116b6d5",
              "8fc91c203d5e5f9cc492c3ff123ae55820762024c45f34e965519893dea8ea299dc",
            ),
            (
              false, "b7a015d952414a7750ecd87479958a23b4818ac73eeac96162fec7357081d90a51",
              "17f6da055f8fba9a20c320aa8309d0e40569055b760fde26e6384418a51c2706efa0",
            ),
            (
              true, "1b4efe6724afedbad1b5b79cae169d60c25621872c5601d3ba7f5c48f425116b6d5",
              "8fc91c203d5e5f9cc492c3ff123ae55820762024c45f34e965519893dea8ea299dc",
            ),
            (
              true, "1c63f361381ec4dbbe538eac5b9b5ed37d3c6ed46c9a257bcd28954f8f50f04554e43",
              "a640888546f51e8d4349b29eed14192de588952a830e152ddd26586af9734ec01e660",
            ),
            (
              false, "10bcb00e9386fea0ae1019128b19d43150017485916d6a328b39f7173d76eb842ac43",
              "376ad82c6cfc5f846bc33b8a4f06b30f4c82dc638104b1b9f4621d78fdd11a400a220",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              false, "18990f2541293509189594f049a6a2465f71ec99498d71bceee5", "e69c76fd3b1a8efa1c6a2e4a6b6d6b9e9160e392758832f00860",
            ),
            (
              true, "18990f2541293509189594f049a6a2465f71ec99498d71bceee5", "e69c76fd3b1a8efa1c6a2e4a6b6d6b9e9160e392758832f00860",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "234c035ab7cff8a93d7be24aa534730cb8cda159718ae39798dd29", "5d5351c0e11e590f9de62b88844647f3c53b9c18785d1e36bcfd40",
            ),
            (
              false, "234c035ab7cff8a93d7be24aa534730cb8cda159718ae39798dd29", "5d5351c0e11e590f9de62b88844647f3c53b9c18785d1e36bcfd40",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "10fa6065a070e9d3eb0b04190d436c0bfed7fbc2bf467172d9813", "24087297913c26571470973ba0c918d0c6b7238ee25d47f5814f0",
            ),
            (
              true, "10fa6065a070e9d3eb0b04190d436c0bfed7fbc2bf467172d9813", "24087297913c26571470973ba0c918d0c6b7238ee25d47f5814f0",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "1d7e65a5b3c76df88f719e740f4daaec4bb33ed2d460b3c21a65", "e69c76fd3b1a8efa1c6a2e4a6b6d6b9e9160e392758832f00860",
            ),
            (
              false, "1d7e65a5b3c76df88f719e740f4daaec4bb33ed2d460b3c21a65", "e69c76fd3b1a8efa1c6a2e4a6b6d6b9e9160e392758832f00860",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (
              true, "33a5fb1ad8e169fe29eb051583530778", "38e8356f30beb0b98217b85d3c083321ed",
            ),
            (
              false, "33a5fb1ad8e169fe29eb051583530778", "38e8356f30beb0b98217b85d3c083321ed",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "56020e8a7e62d1afc26997171577f50d3e23", "beb6b493526c1062b26b5e6cf55fbadc82333",
            ),
            (
              false, "56020e8a7e62d1afc26997171577f50d3e23", "beb6b493526c1062b26b5e6cf55fbadc82333",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "190022e8b4327af148be3127339e8aeb98e25", "2fadad24d49b0418ac9ad79b3d57eeb7208ccc",
            ),
            (
              true, "190022e8b4327af148be3127339e8aeb98e25", "2fadad24d49b0418ac9ad79b3d57eeb7208ccc",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "18f9ebb3455356da8a6d3c6a4ca6d80b9", "126c7523ad8a8936f0328f353983ef462ef8",
            ),
            (
              true, "18f9ebb3455356da8a6d3c6a4ca6d80b9", "126c7523ad8a8936f0328f353983ef462ef8",
            ),
            (false, "0", "1"),
          ],
          ricci: [
            (
              true, "10fa6065a070e9d3eb0b04190d436c0bfed7fbc2bf467172d9813", "24087297913c26571470973ba0c918d0c6b7238ee25d47f5814f0",
            ),
            (
              false, "18990f2541293509189594f049a6a2465f71ec99498d71bceee5", "e69c76fd3b1a8efa1c6a2e4a6b6d6b9e9160e392758832f00860",
            ),
            (
              false, "1d7e65a5b3c76df88f719e740f4daaec4bb33ed2d460b3c21a65", "e69c76fd3b1a8efa1c6a2e4a6b6d6b9e9160e392758832f00860",
            ),
            (
              true, "234c035ab7cff8a93d7be24aa534730cb8cda159718ae39798dd29", "5d5351c0e11e590f9de62b88844647f3c53b9c18785d1e36bcfd40",
            ),
          ],
        },
      ],
    },
    {
      name: "five_outcome_0",
      point: [(false, "1", "5"), (false, "1", "4")],
      polynomials: [
        [
          { coefficient: (false, "1", "21"), exponents: [2, 2], },
          { coefficient: (false, "1", "19"), exponents: [2, 1], },
          { coefficient: (false, "1", "9"), exponents: [1, 0], },
          { coefficient: (true, "1", "11"), exponents: [0, 1], },
          { coefficient: (false, "1", "5"), exponents: [0, 0], },
        ],
        [
          { coefficient: (false, "1", "1d"), exponents: [1, 2], },
          { coefficient: (true, "1", "d"), exponents: [1, 0], },
          { coefficient: (false, "1", "2d"), exponents: [0, 3], },
          { coefficient: (false, "1", "b"), exponents: [0, 1], },
          { coefficient: (false, "1", "6"), exponents: [0, 0], },
        ],
        [
          { coefficient: (true, "1", "1f"), exponents: [2, 0], },
          { coefficient: (false, "1", "25"), exponents: [1, 1], },
          { coefficient: (false, "1", "f"), exponents: [1, 0], },
          { coefficient: (false, "1", "13"), exponents: [0, 1], },
          { coefficient: (false, "1", "7"), exponents: [0, 0], },
        ],
        [
          { coefficient: (false, "1", "29"), exponents: [3, 0], },
          { coefficient: (true, "1", "17"), exponents: [1, 0], },
          { coefficient: (true, "1", "2b"), exponents: [0, 2], },
          { coefficient: (true, "1", "15"), exponents: [0, 1], },
          { coefficient: (false, "1", "8"), exponents: [0, 0], },
        ],
        [
          { coefficient: (true, "1", "29"), exponents: [3, 0], },
          { coefficient: (true, "1", "21"), exponents: [2, 2], },
          { coefficient: (true, "1", "19"), exponents: [2, 1], },
          { coefficient: (false, "1", "1f"), exponents: [2, 0], },
          { coefficient: (true, "1", "1d"), exponents: [1, 2], },
          { coefficient: (true, "1", "25"), exponents: [1, 1], },
          { coefficient: (true, "304", "348f"), exponents: [1, 0], },
          { coefficient: (true, "1", "2d"), exponents: [0, 3], },
          { coefficient: (false, "1", "2b"), exponents: [0, 2], },
          { coefficient: (true, "ad0", "12375"), exponents: [0, 1], },
          { coefficient: (false, "133", "348"), exponents: [0, 0], },
        ],
      ],
      jets: [
        {
          p: (false, "3569db", "100ce30"),
          gradient: [(false, "2ccf", "182b8"), (true, "9b17", "ab342")],
          hessian: [
            (false, "9d", "19c8"),
            (false, "5b", "101d"),
            (false, "5b", "101d"),
            (false, "2", "339"),
          ],
          third: [
            (false, "0", "1"),
            (false, "5b", "339"),
            (false, "5b", "339"),
            (false, "4", "a5"),
            (false, "5b", "339"),
            (false, "4", "a5"),
            (false, "4", "a5"),
            (false, "0", "1"),
          ],
        },
        {
          p: (false, "1fda7f", "b63dc0"),
          gradient: [(true, "1c3", "1790"), (false, "1d77", "12b10")],
          hessian: [
            (false, "0", "1"),
            (false, "1", "3a"),
            (false, "1", "3a"),
            (false, "29", "366"),
          ],
          third: [
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "2", "1d"),
            (false, "0", "1"),
            (false, "2", "1d"),
            (false, "2", "1d"),
            (false, "2", "f"),
          ],
        },
        {
          p: (false, "1d935c", "ae94ad"),
          gradient: [(false, "341", "35c4"), (false, "cc", "dbb")],
          hessian: [
            (true, "2", "1f"),
            (false, "1", "25"),
            (false, "1", "25"),
            (false, "0", "1"),
          ],
          third: [
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
          ],
        },
        {
          p: (false, "a784a37", "65829a50"),
          gradient: [(true, "3bc", "5c17"), (true, "6b", "70e")],
          hessian: [
            (false, "6", "cd"),
            (false, "0", "1"),
            (false, "0", "1"),
            (true, "2", "2b"),
          ],
          third: [
            (false, "6", "29"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
          ],
        },
        {
          p: (false, "2eef01970cbded4f7", "882b7a96378e71040"),
          gradient: [
            (true, "47c031ea2c9", "496e706918b0"),
            (true, "146329c0ef1", "1f4f5b25a070"),
          ],
          hessian: [
            (false, "17785", "7ffff8"),
            (true, "8f599", "87131a"),
            (true, "8f599", "87131a"),
            (true, "186d", "1f654e"),
          ],
          third: [
            (true, "6", "29"),
            (true, "5b", "339"),
            (true, "5b", "339"),
            (true, "1be", "12b1"),
            (true, "5b", "339"),
            (true, "1be", "12b1"),
            (true, "1be", "12b1"),
            (true, "2", "f"),
          ],
        },
      ],
      metric: [
        (
          false, "69b906be10e48e19333234adb5466aa2c01ef4350f", "2d98c02211fa97ef361ed1090d7e5ed1ae6eead8340",
        ),
        (
          true, "919244aeffcd335d024dbf1c7f6e6428dd38db7b", "1954dc84b4a7a9bdc8bbc976ce9b8a02b63d9ee9e4",
        ),
        (
          true, "919244aeffcd335d024dbf1c7f6e6428dd38db7b", "1954dc84b4a7a9bdc8bbc976ce9b8a02b63d9ee9e4",
        ),
        (
          false, "563926f849166d42db5523e5a0c6dfde44e7941d50", "298f39c9b863127b5d541686eaf72e6c72fd18b7ba1",
        ),
      ],
      first: [
        (
          true, "13a2d6dff33994a829894f7b78b6dc4ab108f385352ed375bd68625ea4d1bbd338f1e78d20abf64b1",
          "11eba5891380972523d5f93ff8f1b878450d07d473bf5ba62bdf61845627ba2fb47f09fa11b15ea400",
        ),
        (
          true, "1997001bc17a6b6ee1c53f03cdfec8425916a7a2bce65fa344a8752bb152f2c3fdf0ee0e0a007981",
          "599a3bad6182f3b9b32dde3fdcb89a595941272642bcca3edb5ce795aec6a2ee867b31e25876d9340",
        ),
        (
          true, "1997001bc17a6b6ee1c53f03cdfec8425916a7a2bce65fa344a8752bb152f2c3fdf0ee0e0a007981",
          "599a3bad6182f3b9b32dde3fdcb89a595941272642bcca3edb5ce795aec6a2ee867b31e25876d9340",
        ),
        (
          false, "98b3c56eb689bb380200865090b84c62bc211d433274e3a138da49e989591585e7e38d41bc52e7d",
          "955663764d2f96357ff71d151a89013f94c1ebea6f3aa668c2f02ca4234b0f8d8acd5323e8c614ac",
        ),
        (
          false, "546fad1df3a8170aa67072df3eb6301d2951e3b5335bbb0fba58ade743941a6d517bb5b5dc79da5",
          "5f9372db12add0c6147531552fb3d7d6c59ad46d13fc93763f52081720d3e0fe6d503535b3b1f8c0",
        ),
        (
          false, "6708486440deff59e8b7535fccfa72c3608b14a4d5b9c090aa714e2987f06b4241f6537e4a343e9",
          "955663764d2f96357ff71d151a89013f94c1ebea6f3aa668c2f02ca4234b0f8d8acd5323e8c614ac",
        ),
        (
          false, "6708486440deff59e8b7535fccfa72c3608b14a4d5b9c090aa714e2987f06b4241f6537e4a343e9",
          "955663764d2f96357ff71d151a89013f94c1ebea6f3aa668c2f02ca4234b0f8d8acd5323e8c614ac",
        ),
        (
          false, "16944421084135e5f1b25b77a48d37299c0e977f132c23be5c0128c9c25eaadb4935782a58ba1fed4",
          "f501bb2e16a2126fc5f16bb69f88c60c500e270c9e7c3903dfd2093d49e7258437b8dc66e9e4f9ea3",
        ),
      ],
      second: [
        (
          false, "bdd457350519932f4a2b38659c0c21b6e66c232084f054a20cd5837ee16fa7d40d919ffcb82ab92114dd4efdf094a8005e1fc57d2dce014d6ceccb9",
          "e680c3ea250048713997e2ecd1785dfe6f73db08a49a1a98c102be97af1609d0e20c4c6cc6ee0fd6ac28145f8528888b7c246026497835078a066000",
        ),
        (
          true, "1ee8e2b1644bb4448df7eb017b418f9ff5deb50f3c69a353c076955594813167488d6d9f0aecab127de52572a03d351f39fef2088c60aafc7988db3",
          "34d2d790532565ef47dd795645564034f98a8cdca5b8a61856e5f658181fb79533cd7c2e42ebe3a1321e84ab392e9f4aa1c85608c62b8c270fa17600",
        ),
        (
          true, "1ee8e2b1644bb4448df7eb017b418f9ff5deb50f3c69a353c076955594813167488d6d9f0aecab127de52572a03d351f39fef2088c60aafc7988db3",
          "34d2d790532565ef47dd795645564034f98a8cdca5b8a61856e5f658181fb79533cd7c2e42ebe3a1321e84ab392e9f4aa1c85608c62b8c270fa17600",
        ),
        (
          false, "94385b6987eb56a8e3f1ad2afbad803ea4033138fae93cd38f1060fe96cab2afee2d4d216023c477c04916bf4d194120b9a686e471dab07c474dd",
          "800ea5baf81c9a06038d452e3b7bc270e895b293061cb9714ec8a2c60befcc907d950e038af608cc98880b5182dda1310c14356a9a981d75f758e0",
        ),
        (
          false, "5071ff2bb852ea8115922c8c22c229518509bff5ad40fe8f83241a4ee3f6529521e454111bc5c86122f8b8f4fac5d79365de40f8bf72cc2548eb93f",
          "34d2d790532565ef47dd795645564034f98a8cdca5b8a61856e5f658181fb79533cd7c2e42ebe3a1321e84ab392e9f4aa1c85608c62b8c270fa17600",
        ),
        (
          false, "1275837b3361ea015c34e301a4aaa60f6e5f558a3d7774ab4daee7573d742c51154d830093f8363b17aab61342f24ddd118876dea82e3a0ae8b421",
          "1802bf130e855ce120aa7cf8ab2734752b9c117b912562c53ec59e85223cf65b178bf2a0aa0e21a65c99821f48898e393243ca03fcfc85861e60aa0",
        ),
        (
          false, "1275837b3361ea015c34e301a4aaa60f6e5f558a3d7774ab4daee7573d742c51154d830093f8363b17aab61342f24ddd118876dea82e3a0ae8b421",
          "1802bf130e855ce120aa7cf8ab2734752b9c117b912562c53ec59e85223cf65b178bf2a0aa0e21a65c99821f48898e393243ca03fcfc85861e60aa0",
        ),
        (
          false, "2d5c12caccfdf6ad8d4d446c9c13c7d975f5944e24d28d5880142015b3cba12ca57512c5071de7bc27ac1d2697c2038f128a0801c03abb3281161d",
          "1b83259b2b4e25174ac359dceec796c641f8295d96502bd757ed1af88c9084f30afb0602c2dadbe3f4c53a6e831d9da189985779e736ae545824182",
        ),
        (
          false, "5071ff2bb852ea8115922c8c22c229518509bff5ad40fe8f83241a4ee3f6529521e454111bc5c86122f8b8f4fac5d79365de40f8bf72cc2548eb93f",
          "34d2d790532565ef47dd795645564034f98a8cdca5b8a61856e5f658181fb79533cd7c2e42ebe3a1321e84ab392e9f4aa1c85608c62b8c270fa17600",
        ),
        (
          false, "1275837b3361ea015c34e301a4aaa60f6e5f558a3d7774ab4daee7573d742c51154d830093f8363b17aab61342f24ddd118876dea82e3a0ae8b421",
          "1802bf130e855ce120aa7cf8ab2734752b9c117b912562c53ec59e85223cf65b178bf2a0aa0e21a65c99821f48898e393243ca03fcfc85861e60aa0",
        ),
        (
          false, "1275837b3361ea015c34e301a4aaa60f6e5f558a3d7774ab4daee7573d742c51154d830093f8363b17aab61342f24ddd118876dea82e3a0ae8b421",
          "1802bf130e855ce120aa7cf8ab2734752b9c117b912562c53ec59e85223cf65b178bf2a0aa0e21a65c99821f48898e393243ca03fcfc85861e60aa0",
        ),
        (
          false, "2d5c12caccfdf6ad8d4d446c9c13c7d975f5944e24d28d5880142015b3cba12ca57512c5071de7bc27ac1d2697c2038f128a0801c03abb3281161d",
          "1b83259b2b4e25174ac359dceec796c641f8295d96502bd757ed1af88c9084f30afb0602c2dadbe3f4c53a6e831d9da189985779e736ae545824182",
        ),
        (
          false, "1ecadc569e3d94909c323be81f5b898a69489205c459faecf2cc6bcd59f4c978dd972e110264a8adc90eb3b4b01e4e0b82a5b4ad12772c0ee890b3",
          "119b9d301bb721fa6d49d31cc1c76abc532e2ef4373d8cb2c7a1fcc8080a928711447eba164ea135bb5f818e6864dfc38b42c758420e840d0535d20",
        ),
        (
          false, "4c9bea61ddd7ccd824a6d38ca7ae0981feb9525f85ccf3d82d6daa45f5dbe9214e8633e5015a0d408f38f5c8df1034a7c8a57a7bcfffcd96e31875",
          "528970d181ea6f45e04a0d96cc56c452c5e87c18c2f0838607c750e9a5b18ed920f11208489093abde4faf4b8958d8e49cc9066db5a40afd086c486",
        ),
        (
          false, "4c9bea61ddd7ccd824a6d38ca7ae0981feb9525f85ccf3d82d6daa45f5dbe9214e8633e5015a0d408f38f5c8df1034a7c8a57a7bcfffcd96e31875",
          "528970d181ea6f45e04a0d96cc56c452c5e87c18c2f0838607c750e9a5b18ed920f11208489093abde4faf4b8958d8e49cc9066db5a40afd086c486",
        ),
        (
          false, "1c7670543bafb50d5f9cfa595f5a4b2423980d832a6037820a9270b62439d4fb08d62449f5ec6375bd002618031847e528d8d9aaccf16c4487bdf218",
          "5a465365261869b46d50fedcef7ee6ba887647bb15370fda9882007f8d3a343d7c07abb90f5e2183fb2727ba9e392d3a0b7bdf07feab6c04c1366f29",
        ),
      ],
      cubic: [
        (
          false, "215c6334c71db5538d98b7dfef70c028ae6c1228a39fca41be5d2dac23e57a102e37647ae51e973b",
          "5f9372db12add0c6147531552fb3d7d6c59ad46d13fc93763f52081720d3e0fe6d503535b3b1f8c00",
        ),
        (
          true, "3afd1cdf135af29df8b3eebf1784af2be5ba007f25f72bec2654f59167aa54dd698bf05996db493",
          "599a3bad6182f3b9b32dde3fdcb89a595941272642bcca3edb5ce795aec6a2ee867b31e25876d9340",
        ),
        (
          true, "3afd1cdf135af29df8b3eebf1784af2be5ba007f25f72bec2654f59167aa54dd698bf05996db493",
          "599a3bad6182f3b9b32dde3fdcb89a595941272642bcca3edb5ce795aec6a2ee867b31e25876d9340",
        ),
        (
          true, "354868a9f0cee2251a3e0b5613847cbb1f04ace9afa664afeb5e112ec8b84e53f7201f5b32861d5",
          "955663764d2f96357ff71d151a89013f94c1ebea6f3aa668c2f02ca4234b0f8d8acd5323e8c614ac",
        ),
        (
          true, "3afd1cdf135af29df8b3eebf1784af2be5ba007f25f72bec2654f59167aa54dd698bf05996db493",
          "599a3bad6182f3b9b32dde3fdcb89a595941272642bcca3edb5ce795aec6a2ee867b31e25876d9340",
        ),
        (
          true, "354868a9f0cee2251a3e0b5613847cbb1f04ace9afa664afeb5e112ec8b84e53f7201f5b32861d5",
          "955663764d2f96357ff71d151a89013f94c1ebea6f3aa668c2f02ca4234b0f8d8acd5323e8c614ac",
        ),
        (
          true, "354868a9f0cee2251a3e0b5613847cbb1f04ace9afa664afeb5e112ec8b84e53f7201f5b32861d5",
          "955663764d2f96357ff71d151a89013f94c1ebea6f3aa668c2f02ca4234b0f8d8acd5323e8c614ac",
        ),
        (
          false, "361ccbaf9f9f7aa08538ff000c9bdaabec99e99f8eb5c5c73440b55d44921d839739581e249662cc",
          "f501bb2e16a2126fc5f16bb69f88c60c500e270c9e7c3903dfd2093d49e7258437b8dc66e9e4f9ea3",
        ),
      ],
      natural_gradient: [
        (
          false, "1c22b4be076be003dd94eb792be5c6f3e42599c69bea", "6d70b1fdd93bfea16426b47b63e2cf8211d147bbe2b",
        ),
        (
          true, "ac08b432f37457dcd1888b7e388e336031f23d4cb983", "36b858feec9dff50b2135a3db1f167c108e8a3ddf158",
        ),
      ],
      scores: [
        (false, "1dc176", "3569db"),
        (true, "e8a28", "3569db"),
        (true, "da034", "1fda7f"),
        (false, "11f484", "1fda7f"),
        (false, "2a433d", "764d70"),
        (false, "28875", "764d7"),
        (true, "41dcb40", "a784a37"),
        (true, "603a088", "a784a37"),
        (true, "850da45f9c4248ec", "2eef01970cbded4f7"),
        (true, "58aa97d859c41c1c", "2eef01970cbded4f7"),
      ],
      cubic_pullback: (
        true, "c5b5ea35a777d7035137fadfdbfc36a5d66429b62bcfd37cfa1eab757b92ee7d42575ab9bfbb035208c7",
        "33ae5d7bb8c62fe393c0ecb885a6d9c698e2fc3ca96e3406d1364df2ed96c1e9e3c0fe7db5564cb7662000",
      ),
      alphas: [
        {
          alpha: (false, "0", "1"),
          scalar: (
            true, "1acf6de30e2be436fb8b88a6344fd1546c13ab7fb0870214c80e3f8e00a3827dfea807abf7b74e4206d3e1",
            "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
          ),
          lower: [
            (
              true, "13a2d6dff33994a829894f7b78b6dc4ab108f385352ed375bd68625ea4d1bbd338f1e78d20abf64b1",
              "23d74b1227012e4a47abf27ff1e370f08a1a0fa8e77eb74c57bec308ac4f745f68fe13f42362bd4800",
            ),
            (
              true, "8256b28397626c77bf93e9b8e6c85da008ea14bf59f2bea548040d603200be4e7845d67692b32fad",
              "b334775ac305e773665bbc7fb97134b2b2824e4c8579947db6b9cf2b5d8d45dd0cf663c4b0edb2680",
            ),
            (
              false, "546fad1df3a8170aa67072df3eb6301d2951e3b5335bbb0fba58ade743941a6d517bb5b5dc79da5",
              "bf26e5b6255ba18c28ea62aa5f67afad8b35a8da27f926ec7ea4102e41a7c1fcdaa06a6b6763f180",
            ),
            (
              false, "98b3c56eb689bb380200865090b84c62bc211d433274e3a138da49e989591585e7e38d41bc52e7d",
              "12aacc6ec9a5f2c6affee3a2a3512027f2983d7d4de754cd185e0594846961f1b159aa647d18c2958",
            ),
            (
              false, "546fad1df3a8170aa67072df3eb6301d2951e3b5335bbb0fba58ade743941a6d517bb5b5dc79da5",
              "bf26e5b6255ba18c28ea62aa5f67afad8b35a8da27f926ec7ea4102e41a7c1fcdaa06a6b6763f180",
            ),
            (
              false, "98b3c56eb689bb380200865090b84c62bc211d433274e3a138da49e989591585e7e38d41bc52e7d",
              "12aacc6ec9a5f2c6affee3a2a3512027f2983d7d4de754cd185e0594846961f1b159aa647d18c2958",
            ),
            (
              false, "355ccb59cb34437bcf6e206f093c992404f50c0678fe9d801c0852698687c0fe9c0919bad815955",
              "12aacc6ec9a5f2c6affee3a2a3512027f2983d7d4de754cd185e0594846961f1b159aa647d18c2958",
            ),
            (
              false, "b4a221084209af2f8d92dbbd2469b94ce074bbf899611df2e009464e12f556da49abc152c5d0ff6a",
              "f501bb2e16a2126fc5f16bb69f88c60c500e270c9e7c3903dfd2093d49e7258437b8dc66e9e4f9ea3",
            ),
          ],
          lower_first: [
            (
              false, "bdd457350519932f4a2b38659c0c21b6e66c232084f054a20cd5837ee16fa7d40d919ffcb82ab92114dd4efdf094a8005e1fc57d2dce014d6ceccb9",
              "1cd0187d44a0090e2732fc5d9a2f0bbfcdee7b6114934353182057d2f5e2c13a1c41898d98ddc1fad585028bf0a511116f848c04c92f06a0f140cc000",
            ),
            (
              true, "2f6bec2f804e1bae1080ab85086c6d85d042635c0cb16c67ac05c1a8aefd91cbe6550fc5108a5f820a410148be6ac09b489eb703481160b4bea9c37",
              "23373a60376e43f4da93a639838ed578a65c5de86e7b19658f43f9901015250e2288fd742c9d426b76bf031cd0c9bf8716858eb0841d081a0a6ba400",
            ),
            (
              false, "5071ff2bb852ea8115922c8c22c229518509bff5ad40fe8f83241a4ee3f6529521e454111bc5c86122f8b8f4fac5d79365de40f8bf72cc2548eb93f",
              "69a5af20a64acbde8fbaf2ac8aac8069f31519b94b714c30adcbecb0303f6f2a679af85c85d7c742643d0956725d3e954390ac118c57184e1f42ec00",
            ),
            (
              false, "94385b6987eb56a8e3f1ad2afbad803ea4033138fae93cd38f1060fe96cab2afee2d4d216023c477c04916bf4d194120b9a686e471dab07c474dd",
              "1001d4b75f039340c071a8a5c76f784e1d12b65260c3972e29d91458c17df9920fb2a1c0715ec1199311016a305bb426218286ad535303aebeeb1c0",
            ),
            (
              false, "5071ff2bb852ea8115922c8c22c229518509bff5ad40fe8f83241a4ee3f6529521e454111bc5c86122f8b8f4fac5d79365de40f8bf72cc2548eb93f",
              "69a5af20a64acbde8fbaf2ac8aac8069f31519b94b714c30adcbecb0303f6f2a679af85c85d7c742643d0956725d3e954390ac118c57184e1f42ec00",
            ),
            (
              false, "94385b6987eb56a8e3f1ad2afbad803ea4033138fae93cd38f1060fe96cab2afee2d4d216023c477c04916bf4d194120b9a686e471dab07c474dd",
              "1001d4b75f039340c071a8a5c76f784e1d12b65260c3972e29d91458c17df9920fb2a1c0715ec1199311016a305bb426218286ad535303aebeeb1c0",
            ),
            (
              false, "92075d29d47b3c30dac758b3a24c4131dfe11d9cbe32deef08abc7ebea257212df2878ae5e9b79fbb47b7e2a76fdf840041b4727b0372fe8409ab",
              "30057e261d0ab9c24154f9f1564e68ea573822f7224ac58a7d8b3d0a4479ecb62f17e541541c434cb933043e91131c7264879407f9f90b0c3cc1540",
            ),
            (
              false, "2d5c12caccfdf6ad8d4d446c9c13c7d975f5944e24d28d5880142015b3cba12ca57512c5071de7bc27ac1d2697c2038f128a0801c03abb3281161d",
              "37064b36569c4a2e9586b3b9dd8f2d8c83f052bb2ca057aeafda35f1192109e615f60c0585b5b7c7e98a74dd063b3b431330aef3ce6d5ca8b048304",
            ),
            (
              false, "5071ff2bb852ea8115922c8c22c229518509bff5ad40fe8f83241a4ee3f6529521e454111bc5c86122f8b8f4fac5d79365de40f8bf72cc2548eb93f",
              "69a5af20a64acbde8fbaf2ac8aac8069f31519b94b714c30adcbecb0303f6f2a679af85c85d7c742643d0956725d3e954390ac118c57184e1f42ec00",
            ),
            (
              true, "37c99c7cdb31985b3a660075afb2c9c8af0f34753901ad298cf26f88fd5bff1d273270f26c91391abf30e1ee90f3e1ad25fb5f01a10297efa0ffa7",
              "2103c6ba33f75fb58cea6bd5eb55e8211bf69809e79367cf364fb9f70f13d2bd40606d9ce9d36e44bf5312eb03bd238ea51d35c57bdb379869c4e9c0",
            ),
            (
              false, "1ecadc569e3d94909c323be81f5b898a69489205c459faecf2cc6bcd59f4c978dd972e110264a8adc90eb3b4b01e4e0b82a5b4ad12772c0ee890b3",
              "23373a60376e43f4da93a639838ed578a65c5de86e7b19658f43f9901015250e2288fd742c9d426b76bf031cd0c9bf8716858eb0841d081a0a6ba40",
            ),
            (
              false, "2d5c12caccfdf6ad8d4d446c9c13c7d975f5944e24d28d5880142015b3cba12ca57512c5071de7bc27ac1d2697c2038f128a0801c03abb3281161d",
              "37064b36569c4a2e9586b3b9dd8f2d8c83f052bb2ca057aeafda35f1192109e615f60c0585b5b7c7e98a74dd063b3b431330aef3ce6d5ca8b048304",
            ),
            (
              false, "1ecadc569e3d94909c323be81f5b898a69489205c459faecf2cc6bcd59f4c978dd972e110264a8adc90eb3b4b01e4e0b82a5b4ad12772c0ee890b3",
              "23373a60376e43f4da93a639838ed578a65c5de86e7b19658f43f9901015250e2288fd742c9d426b76bf031cd0c9bf8716858eb0841d081a0a6ba40",
            ),
            (
              false, "2d5c12caccfdf6ad8d4d446c9c13c7d975f5944e24d28d5880142015b3cba12ca57512c5071de7bc27ac1d2697c2038f128a0801c03abb3281161d",
              "37064b36569c4a2e9586b3b9dd8f2d8c83f052bb2ca057aeafda35f1192109e615f60c0585b5b7c7e98a74dd063b3b431330aef3ce6d5ca8b048304",
            ),
            (
              false, "11239c6354b5b5a7a165d9d37b20bb779b91e7d49d223fa6da9ef44ad054eebcacad2f7aed5a634ca76d941df6da5ea259acdcf25f4f699642ee93",
              "a512e1a303d4de8bc0941b2d98ad88a58bd0f83185e1070c0f8ea1d34b631db241e2241091212757bc9f5e9712b1b1c939920cdb6b4815fa10d890c",
            ),
            (
              false, "e3b382a1dd7da86afce7d2cafad259211cc06c195301bc10549385b121cea7d846b1224faf631bade80130c018c23f2946c6cd56678b62243def90c",
              "5a465365261869b46d50fedcef7ee6ba887647bb15370fda9882007f8d3a343d7c07abb90f5e2183fb2727ba9e392d3a0b7bdf07feab6c04c1366f29",
            ),
          ],
          coefficients: [
            (
              true, "108e53b4696fe82de4dc7f7021c6a3c92266da75c75bdd0a33eb5e2e3af7d72376007cdb64287ec92fdf",
              "377217b727fac9852ac1b8ddf89a912b57870ecf6a2a9a6c269eb929949744faacad8bb5f56027a02960",
            ),
            (
              true, "b26d7a7e0bcd4435a61805ba5367175ae0b6583420e20c44fc5462f0cb98d25450dbe58841ee3b0160a3",
              "1bb90bdb93fd64c29560dc6efc4d4895abc38767b5154d36134f5c94ca4ba27d5656c5dafab013d014b00",
            ),
            (
              false, "4124d63988f1dab45384912807e2beafe228942bb3f7820486009b5c6a8d9bd9fec2aad80fd3a6ab38d",
              "1153a7693c7e5ef99d5c89c55db04d5d8b5a34a0d12d5041cc1199dcfe6f458e55f63ba8dcae0c620cee",
            ),
            (
              false, "7f5a00bf685048aa1f032982067b7df70a4d52032fd4f35f6d22e7dcbc685f1c6969efe562cc420e611",
              "1bb90bdb93fd64c29560dc6efc4d4895abc38767b5154d36134f5c94ca4ba27d5656c5dafab013d014b0",
            ),
            (
              false, "4124d63988f1dab45384912807e2beafe228942bb3f7820486009b5c6a8d9bd9fec2aad80fd3a6ab38d",
              "1153a7693c7e5ef99d5c89c55db04d5d8b5a34a0d12d5041cc1199dcfe6f458e55f63ba8dcae0c620cee",
            ),
            (
              false, "7f5a00bf685048aa1f032982067b7df70a4d52032fd4f35f6d22e7dcbc685f1c6969efe562cc420e611",
              "1bb90bdb93fd64c29560dc6efc4d4895abc38767b5154d36134f5c94ca4ba27d5656c5dafab013d014b0",
            ),
            (
              false, "5e140cd7b0ee9a22974f17599ea31fbb39faba2b8e8db275cbc858ddf2b692fe024eeee896078976288",
              "2b512287173bed700967586d6a38c169dc6183920af148a47e2c00a87c162de3d6e7952627b31ef52053",
            ),
            (
              false, "3483d0eb1e99eb1926d0584d65fc39261b9ab33ce4ed3153977ec01d29d86a8f49bbd8fbc3ac322caf9",
              "8a9d3b49e3f2f7cceae44e2aed826aec5ad1a506896a820e608ccee7f37a2c72afb1dd46e5706310677",
            ),
          ],
          derivatives: [
            (
              true, "cd12e767991508a921f3d762f724d1cedc027c7e6f7d7d823028dbb327cd7b72a0d8837ad215d2c2fa333483faa1f6c5791ad4532a1a123d9736a80c7a8ebe0d8dc35c023052274cbb44b8840b1a02f2ee3ef",
              "8bbcc643d7435f16a29fc7374b0adef9e07d37357170f6dde4c97cc49691831d6770f502e957cbc2ae32e8d687d2ef5be6e81df5135ea5ac1314641f14f2e029699e2e50491a0c2d5a4698af3c7fac51651600",
            ),
            (
              true, "237a7647794dfde4ddc72db1e1928681e27fdd18507a4b81bfb640e9e90606060c16e9d8a2c6e75ef9f151821f4eda5be3095dd3400eb793d7a0edef0d05af8665c75fc345a130595518edf7f60c84b26f9d573",
              "45de6321eba1af8b514fe39ba5856f7cf03e9b9ab8b87b6ef264be624b48c18eb3b87a8174abe5e15719746b43e977adf3740efa89af52d6098a320f8a797014b4cf1728248d0616ad234c579e3fd628b28b000",
            ),
            (
              false, "47f437bef9ffeb7ee53d518f72acfb07211dc0daa5858ebbd6b20f394402df9a41a16fcf57750a08536ce424745739e20bccf1a94614a23ba60bd3de156182367688a40abb76bb89fce1231bb6fbbb10cc8ad",
              "8bbcc643d7435f16a29fc7374b0adef9e07d37357170f6dde4c97cc49691831d6770f502e957cbc2ae32e8d687d2ef5be6e81df5135ea5ac1314641f14f2e029699e2e50491a0c2d5a4698af3c7fac5165160",
            ),
            (
              false, "121751f03be9d421ac3020d728bce76b34d25d04e140ee5c07862f01a3a86b125b0b5938026eff39fd32386272e574318ffa024babd01726a81ce80a67a30c139ea2ccf41a552a982029e331e336b75ca6e939",
              "45de6321eba1af8b514fe39ba5856f7cf03e9b9ab8b87b6ef264be624b48c18eb3b87a8174abe5e15719746b43e977adf3740efa89af52d6098a320f8a797014b4cf1728248d0616ad234c579e3fd628b28b00",
            ),
            (
              false, "47f437bef9ffeb7ee53d518f72acfb07211dc0daa5858ebbd6b20f394402df9a41a16fcf57750a08536ce424745739e20bccf1a94614a23ba60bd3de156182367688a40abb76bb89fce1231bb6fbbb10cc8ad",
              "8bbcc643d7435f16a29fc7374b0adef9e07d37357170f6dde4c97cc49691831d6770f502e957cbc2ae32e8d687d2ef5be6e81df5135ea5ac1314641f14f2e029699e2e50491a0c2d5a4698af3c7fac5165160",
            ),
            (
              false, "121751f03be9d421ac3020d728bce76b34d25d04e140ee5c07862f01a3a86b125b0b5938026eff39fd32386272e574318ffa024babd01726a81ce80a67a30c139ea2ccf41a552a982029e331e336b75ca6e939",
              "45de6321eba1af8b514fe39ba5856f7cf03e9b9ab8b87b6ef264be624b48c18eb3b87a8174abe5e15719746b43e977adf3740efa89af52d6098a320f8a797014b4cf1728248d0616ad234c579e3fd628b28b00",
            ),
            (
              false, "a3e7dff4b606f38b1deeca06d717b13de5e2c6e424308d307c395dba3abe3c723bc6b30b802cf371cb294746efdffb0e080dfd76eb2afccfb175613f1524e986612141c93598bef47a070e9da5e0a13ec945",
              "2baafdf533450db712d1ee41477365ae16272140b3734d25577ef6fd6f0d78f930534c90e8eb6facd66fe8c30a71eaccb828895c960d93c5c5f65f49b68be60cf1016e7916d823ce2c360fb6c2e7e5d96f96e",
            ),
            (
              false, "12dbbcfb40dda45788f39c4a343a9981f298c63c971ed9747f9040819d1719493cedc8e658a0e217f8dca74199075815f6869f5f9d55eebaf3787aed546aa108cedd3a36f25716b6a5429bf49790d7dbbf0ad",
              "45de6321eba1af8b514fe39ba5856f7cf03e9b9ab8b87b6ef264be624b48c18eb3b87a8174abe5e15719746b43e977adf3740efa89af52d6098a320f8a797014b4cf1728248d0616ad234c579e3fd628b28b0",
            ),
            (
              false, "581cde3a4620bef2f8ee2650ea2447b2a49b3698f324497c759f5dd1d87a3f61c753bf252093dd82234147baaea8715a837495e9ed9008fe882be3f177971321e8b89d8cb9d23b163e127aefd6d1317f26f55",
              "8bbcc643d7435f16a29fc7374b0adef9e07d37357170f6dde4c97cc49691831d6770f502e957cbc2ae32e8d687d2ef5be6e81df5135ea5ac1314641f14f2e029699e2e50491a0c2d5a4698af3c7fac5165160",
            ),
            (
              false, "1efb9e952455c612670c7035c3c4643274fea66519f6438046a69bcac6b1741058570387745796f5988b576648cb04efbbc36fa2f48ee2dbc427ce4d18988140d4b16e2ee2c942e5827a7918eab5f26268c635",
              "45de6321eba1af8b514fe39ba5856f7cf03e9b9ab8b87b6ef264be624b48c18eb3b87a8174abe5e15719746b43e977adf3740efa89af52d6098a320f8a797014b4cf1728248d0616ad234c579e3fd628b28b00",
            ),
            (
              false, "9defae3474aa181d80ef4a98270e687038da50aa901e3828b9082714066311c8b586f0c145103a615c52a4f766a21303be1a9e13afa5fa65e16f91734f209d2e9f93dedc716d27e6a81e5169d274d5adc40d",
              "2baafdf533450db712d1ee41477365ae16272140b3734d25577ef6fd6f0d78f930534c90e8eb6facd66fe8c30a71eaccb828895c960d93c5c5f65f49b68be60cf1016e7916d823ce2c360fb6c2e7e5d96f96e",
            ),
            (
              false, "ac769bd9acd3a9d7f1b31e9787ef32c30da0b5d704f7c143019993552db69657a14a13b7411785b10f275767bdebc59bab2cd3f49983b59826872e3a34fd89315c53d75f32956f084a9f00a87a61ca491d59",
              "45de6321eba1af8b514fe39ba5856f7cf03e9b9ab8b87b6ef264be624b48c18eb3b87a8174abe5e15719746b43e977adf3740efa89af52d6098a320f8a797014b4cf1728248d0616ad234c579e3fd628b28b0",
            ),
            (
              false, "9defae3474aa181d80ef4a98270e687038da50aa901e3828b9082714066311c8b586f0c145103a615c52a4f766a21303be1a9e13afa5fa65e16f91734f209d2e9f93dedc716d27e6a81e5169d274d5adc40d",
              "2baafdf533450db712d1ee41477365ae16272140b3734d25577ef6fd6f0d78f930534c90e8eb6facd66fe8c30a71eaccb828895c960d93c5c5f65f49b68be60cf1016e7916d823ce2c360fb6c2e7e5d96f96e",
            ),
            (
              false, "ac769bd9acd3a9d7f1b31e9787ef32c30da0b5d704f7c143019993552db69657a14a13b7411785b10f275767bdebc59bab2cd3f49983b59826872e3a34fd89315c53d75f32956f084a9f00a87a61ca491d59",
              "45de6321eba1af8b514fe39ba5856f7cf03e9b9ab8b87b6ef264be624b48c18eb3b87a8174abe5e15719746b43e977adf3740efa89af52d6098a320f8a797014b4cf1728248d0616ad234c579e3fd628b28b0",
            ),
            (
              false, "23cec043032d30340e2f2d25080863c3a81f6e1b9e8f8d713e23a4657b5a489620e69707c8159fbcb6c3a43bef98768bc3b1d1a94671314f5ebe46bb1f95ecf9ffabe5991405bce161fff2705e02b488b4e8",
              "6d2b7ae5002ca249af0cd3a332a07e333761d321c0a040dd5abd697995a1ae6ef8d03f6a464c97301817c5e79a1ccaffcc6557677721f16e6ee7ee38485dbf205a83942eb91c59836e872748e743be9f96f93",
            ),
            (
              false, "13c1f176f55a7cb09f7dc4c22c131133c6322209a44b356c05a03db4b50ad47e72bedd7661ecb8201278240a9b127fad7e53fdbac368ad0ad7a06b5791e700ef9f6421ba49e3a8066fb7f5c2dbbf0680a71d1",
              "15d57efa99a286db8968f720a3b9b2d70b1390a059b9a692abbf7b7eb786bc7c9829a6487475b7d66b37f4618538f5665c1444ae4b06c9e2e2fb2fa4db45f3067880b73c8b6c11e7161b07db6173f2ecb7cb7",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              false, "9c1cbfd3fab8da64822af7e232fe6aa047af44bdcfd0ff2000ca27e84f93c266ad2bb585cb37b01fbbd16b0420f3d5bb82cf82fa26ad1d1936d367f34053",
              "5ecff240e56c32e296e33997930ffc6c3523667b533ac6fd8f53b720297b8d001f3d7a438ad479e43d17c9a865678c119e0924af2621bd28dccc67b9ef0cc8",
            ),
            (
              true, "9c1cbfd3fab8da64822af7e232fe6aa047af44bdcfd0ff2000ca27e84f93c266ad2bb585cb37b01fbbd16b0420f3d5bb82cf82fa26ad1d1936d367f34053",
              "5ecff240e56c32e296e33997930ffc6c3523667b533ac6fd8f53b720297b8d001f3d7a438ad479e43d17c9a865678c119e0924af2621bd28dccc67b9ef0cc8",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "70b8ab920d953771b599c6f81889d37e19d33c8026d97afaadf1b187fbf23224bcf61a35649b5585ba8ab573afc140799784bf57e838db0f567f6826dfa8",
              "bd9fe481cad865c52dc6732f261ff8d86a46ccf6a6758dfb1ea76e4052f71a003e7af48715a8f3c87a2f9350cacf18233c12495e4c437a51b998cf73de199",
            ),
            (
              false, "70b8ab920d953771b599c6f81889d37e19d33c8026d97afaadf1b187fbf23224bcf61a35649b5585ba8ab573afc140799784bf57e838db0f567f6826dfa8",
              "bd9fe481cad865c52dc6732f261ff8d86a46ccf6a6758dfb1ea76e4052f71a003e7af48715a8f3c87a2f9350cacf18233c12495e4c437a51b998cf73de199",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "3efce768233903c5d5626b7f03189294f4f5de6c6a86e90e7fbfb7845f8cfaf8711cd9085cb25ebe79d10f29c4323483b748995800be32f68f1c40863cfa4b",
              "5ecff240e56c32e296e33997930ffc6c3523667b533ac6fd8f53b720297b8d001f3d7a438ad479e43d17c9a865678c119e0924af2621bd28dccc67b9ef0cc80",
            ),
            (
              true, "3efce768233903c5d5626b7f03189294f4f5de6c6a86e90e7fbfb7845f8cfaf8711cd9085cb25ebe79d10f29c4323483b748995800be32f68f1c40863cfa4b",
              "5ecff240e56c32e296e33997930ffc6c3523667b533ac6fd8f53b720297b8d001f3d7a438ad479e43d17c9a865678c119e0924af2621bd28dccc67b9ef0cc80",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "9c1cbfd3fab8da64822af7e232fe6aa047af44bdcfd0ff2000ca27e84f93c266ad2bb585cb37b01fbbd16b0420f3d5bb82cf82fa26ad1d1936d367f34053",
              "5ecff240e56c32e296e33997930ffc6c3523667b533ac6fd8f53b720297b8d001f3d7a438ad479e43d17c9a865678c119e0924af2621bd28dccc67b9ef0cc8",
            ),
            (
              false, "9c1cbfd3fab8da64822af7e232fe6aa047af44bdcfd0ff2000ca27e84f93c266ad2bb585cb37b01fbbd16b0420f3d5bb82cf82fa26ad1d1936d367f34053",
              "5ecff240e56c32e296e33997930ffc6c3523667b533ac6fd8f53b720297b8d001f3d7a438ad479e43d17c9a865678c119e0924af2621bd28dccc67b9ef0cc8",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "4a5f39b0fc63f411c41d8634b01ab6d9d35fb571f22f28b820246770b6417f7c384dd794d9cbafcad9",
              "377217b727fac9852ac1b8ddf89a912b57870ecf6a2a9a6c269eb929949744faacad8bb5f56027a02960",
            ),
            (
              false, "4a5f39b0fc63f411c41d8634b01ab6d9d35fb571f22f28b820246770b6417f7c384dd794d9cbafcad9",
              "377217b727fac9852ac1b8ddf89a912b57870ecf6a2a9a6c269eb929949744faacad8bb5f56027a02960",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "4a5f39b0fc63f411c41d8634b01ab6d9d35fb571f22f28b820246770b6417f7c384dd794d9cbafcad9",
              "377217b727fac9852ac1b8ddf89a912b57870ecf6a2a9a6c269eb929949744faacad8bb5f56027a02960",
            ),
            (
              true, "4a5f39b0fc63f411c41d8634b01ab6d9d35fb571f22f28b820246770b6417f7c384dd794d9cbafcad9",
              "377217b727fac9852ac1b8ddf89a912b57870ecf6a2a9a6c269eb929949744faacad8bb5f56027a02960",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
          ],
          ricci: [
            (
              true, "3efce768233903c5d5626b7f03189294f4f5de6c6a86e90e7fbfb7845f8cfaf8711cd9085cb25ebe79d10f29c4323483b748995800be32f68f1c40863cfa4b",
              "5ecff240e56c32e296e33997930ffc6c3523667b533ac6fd8f53b720297b8d001f3d7a438ad479e43d17c9a865678c119e0924af2621bd28dccc67b9ef0cc80",
            ),
            (
              false, "9c1cbfd3fab8da64822af7e232fe6aa047af44bdcfd0ff2000ca27e84f93c266ad2bb585cb37b01fbbd16b0420f3d5bb82cf82fa26ad1d1936d367f34053",
              "5ecff240e56c32e296e33997930ffc6c3523667b533ac6fd8f53b720297b8d001f3d7a438ad479e43d17c9a865678c119e0924af2621bd28dccc67b9ef0cc8",
            ),
            (
              false, "9c1cbfd3fab8da64822af7e232fe6aa047af44bdcfd0ff2000ca27e84f93c266ad2bb585cb37b01fbbd16b0420f3d5bb82cf82fa26ad1d1936d367f34053",
              "5ecff240e56c32e296e33997930ffc6c3523667b533ac6fd8f53b720297b8d001f3d7a438ad479e43d17c9a865678c119e0924af2621bd28dccc67b9ef0cc8",
            ),
            (
              true, "70b8ab920d953771b599c6f81889d37e19d33c8026d97afaadf1b187fbf23224bcf61a35649b5585ba8ab573afc140799784bf57e838db0f567f6826dfa8",
              "bd9fe481cad865c52dc6732f261ff8d86a46ccf6a6758dfb1ea76e4052f71a003e7af48715a8f3c87a2f9350cacf18233c12495e4c437a51b998cf73de199",
            ),
          ],
        },
        {
          alpha: (false, "1", "1"),
          scalar: (
            true, "244d01c9926cd5e315a9810cf8ffec3eacfc5e332c820d284ede859ec00d9ba6d56a04f353c79f2651191e",
            "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
          ),
          lower: [
            (
              true, "cf214bcec479353ea0af8fabace002928de9b7669ee64b1088ced7775c6615b20ce253215d0d9531",
              "11eba5891380972523d5f93ff8f1b878450d07d473bf5ba62bdf61845627ba2fb47f09fa11b15ea400",
            ),
            (
              true, "caa49abc3d14621633411147eee68448774a5458a5b87970d5cac9a4f8d68e676914f24e5ba25e9",
              "11eba5891380972523d5f93ff8f1b878450d07d473bf5ba62bdf61845627ba2fb47f09fa11b15ea40",
            ),
            (
              false, "296c420d02d1a261edca554e9e218c070a8c32c0e942b90ec08c3930f2eabf0a297e5cb00c0ff89f",
              "599a3bad6182f3b9b32dde3fdcb89a595941272642bcca3edb5ce795aec6a2ee867b31e25876d9340",
            ),
            (
              false, "66fe170c53ac4eae8e1f48d3521e648eed92e516710da428921c2d8c2908b1ecef81d64e776c829",
              "955663764d2f96357ff71d151a89013f94c1ebea6f3aa668c2f02ca4234b0f8d8acd5323e8c614ac",
            ),
            (
              false, "296c420d02d1a261edca554e9e218c070a8c32c0e942b90ec08c3930f2eabf0a297e5cb00c0ff89f",
              "599a3bad6182f3b9b32dde3fdcb89a595941272642bcca3edb5ce795aec6a2ee867b31e25876d9340",
            ),
            (
              false, "66fe170c53ac4eae8e1f48d3521e648eed92e516710da428921c2d8c2908b1ecef81d64e776c829",
              "955663764d2f96357ff71d151a89013f94c1ebea6f3aa668c2f02ca4234b0f8d8acd5323e8c614ac",
            ),
            (
              false, "35529a01de0192d074d615e28e608aef91fcdc781452811803b331cc27a007a949949c8b054dd95",
              "955663764d2f96357ff71d151a89013f94c1ebea6f3aa668c2f02ca4234b0f8d8acd5323e8c614ac",
            ),
            (
              false, "9993bb307239f1df4af65c3d1e1bcbf6ea27c728d2063b0f45e8eb9f70ac48187e0f1543b385ce04",
              "f501bb2e16a2126fc5f16bb69f88c60c500e270c9e7c3903dfd2093d49e7258437b8dc66e9e4f9ea3",
            ),
          ],
          lower_first: [
            (
              false, "81a7380f8387a8c9be34eb3a657d6ada3a861c6339c846c07efbb928ae22cc1e800bfec60009e80c339e0c8e4b3b45e4e142ddd2c3ebcc9c784d2633",
              "9e7886b0f97031cdd7986c02d002c09eec9fa695f129f24904b1e308485f26bf9b68748ac8c3aae3965b8e01ab8bdddfe559021a5282a4752ee462000",
            ),
            (
              true, "1b1b96ed8ea09667961b5c960a7cd70c06650b50c4ec4c97ae7528a25ec064ab6988d375fd46832fea53226ad4fe67f04be24d1c03451974f7120f7",
              "119b9d301bb721fa6d49d31cc1c76abc532e2ef4373d8cb2c7a1fcc8080a928711447eba164ea135bb5f818e6864dfc38b42c758420e840d0535d200",
            ),
            (
              false, "1e081d1470bcdb8ee13801cb7e8d33cd67b953129ae5bc1c383b35bd5c3655fa2dd7474e2edee9e3e1e477271c07d4e1bc364bad42042ac2dd3e40d",
              "34d2d790532565ef47dd795645564034f98a8cdca5b8a61856e5f658181fb79533cd7c2e42ebe3a1321e84ab392e9f4aa1c85608c62b8c270fa17600",
            ),
            (
              false, "583da08c9af67970035df8eebb8a34e1719a4a0e49c09ff669eb2fa381070a91b4e7f8206e9656789ace51227e4af3dcffa8559e3c5734a89a9579",
              "580a11f08a93a9e422711f8fc8e515ad9fe6eac51433bf7de629efe82834dca3565679a26f89260ca8dd87c809f85ed1b84de4b94a4894411a0d1a0",
            ),
            (
              false, "1e081d1470bcdb8ee13801cb7e8d33cd67b953129ae5bc1c383b35bd5c3655fa2dd7474e2edee9e3e1e477271c07d4e1bc364bad42042ac2dd3e40d",
              "34d2d790532565ef47dd795645564034f98a8cdca5b8a61856e5f658181fb79533cd7c2e42ebe3a1321e84ab392e9f4aa1c85608c62b8c270fa17600",
            ),
            (
              false, "583da08c9af67970035df8eebb8a34e1719a4a0e49c09ff669eb2fa381070a91b4e7f8206e9656789ace51227e4af3dcffa8559e3c5734a89a9579",
              "580a11f08a93a9e422711f8fc8e515ad9fe6eac51433bf7de629efe82834dca3565679a26f89260ca8dd87c809f85ed1b84de4b94a4894411a0d1a0",
            ),
            (
              false, "a2114b675dc317a2aa3d36b59edde8cce0a0f595fbe2d5cb3d33b79d1010f6a62dcf1a52d12392bcd82a0750cc461dc340eea634c42f10717c6d59",
              "1081e35d19fbafdac67535eaf5aaf4108dfb4c04f3c9b3e79b27dcfb8789e95ea03036ce74e9b7225fa9897581de91c7528e9ae2bded9bcc34e274e0",
            ),
            (
              false, "e132637bbe546468e1c43eb7144bbeb526286460a8d0eb21c438cbe259fb2d847cba1685e4cd39ec96ba2e698df453b436ed8b55b38786ea7425d",
              "1b83259b2b4e25174ac359dceec796c641f8295d96502bd757ed1af88c9084f30afb0602c2dadbe3f4c53a6e831d9da189985779e736ae545824182",
            ),
            (
              false, "107da29db723654d8a6c420ee7a901b26f692c01c65b05ac4f317b215957fb1feef95ebf2fd96f3621058a9e9ff30568d893a1c54f259580b186eff",
              "34d2d790532565ef47dd795645564034f98a8cdca5b8a61856e5f658181fb79533cd7c2e42ebe3a1321e84ab392e9f4aa1c85608c62b8c270fa17600",
            ),
            (
              false, "119b07a05f1068651d2a7b2715a3eeab8ddb587651353a2f0ac7b8794a6a128a617ce02fb86a16dc72cd457ad83af96c752e6d36df863073f02ac5",
              "34d2d790532565ef47dd795645564034f98a8cdca5b8a61856e5f658181fb79533cd7c2e42ebe3a1321e84ab392e9f4aa1c85608c62b8c270fa1760",
            ),
            (
              false, "15add68e9ebb8b063c280294b2f3b95cc32709bb5732dd371195cfaa7156c434cf8f772e7624dfff301891028aa84194b30c09ca5389e08ab5192eb",
              "1081e35d19fbafdac67535eaf5aaf4108dfb4c04f3c9b3e79b27dcfb8789e95ea03036ce74e9b7225fa9897581de91c7528e9ae2bded9bcc34e274e0",
            ),
            (
              false, "1c02cba0992f605dba52ef40cf10316b7ab43cbcd96607c3466e83b5fb3983880e7c9ea3b8c9913760a1df700b8247bdec0015b3a9addd1efc64e7",
              "1b83259b2b4e25174ac359dceec796c641f8295d96502bd757ed1af88c9084f30afb0602c2dadbe3f4c53a6e831d9da189985779e736ae545824182",
            ),
            (
              false, "15add68e9ebb8b063c280294b2f3b95cc32709bb5732dd371195cfaa7156c434cf8f772e7624dfff301891028aa84194b30c09ca5389e08ab5192eb",
              "1081e35d19fbafdac67535eaf5aaf4108dfb4c04f3c9b3e79b27dcfb8789e95ea03036ce74e9b7225fa9897581de91c7528e9ae2bded9bcc34e274e0",
            ),
            (
              false, "1c02cba0992f605dba52ef40cf10316b7ab43cbcd96607c3466e83b5fb3983880e7c9ea3b8c9913760a1df700b8247bdec0015b3a9addd1efc64e7",
              "1b83259b2b4e25174ac359dceec796c641f8295d96502bd757ed1af88c9084f30afb0602c2dadbe3f4c53a6e831d9da189985779e736ae545824182",
            ),
            (
              false, "189014e3426c09e8abb7d40940a346380cf54baba3876318807cd526cc259033899cd781165d09b23a1a3ca53a5101345507a3918c59335c5504d3",
              "528970d181ea6f45e04a0d96cc56c452c5e87c18c2f0838607c750e9a5b18ed920f11208489093abde4faf4b8958d8e49cc9066db5a40afd086c486",
            ),
            (
              false, "113098740c08a76587b554a981e389849703f0012f380c7a296990c90e21f9676c39a1074ec80664872655ad13d75f4c4df2e49ddcdd92ec09eb7cd8",
              "5a465365261869b46d50fedcef7ee6ba887647bb15370fda9882007f8d3a343d7c07abb90f5e2183fb2727ba9e392d3a0b7bdf07feab6c04c1366f29",
            ),
          ],
          coefficients: [
            (
              true, "a60e0e43e3b86aea8faf03c2aaf9ffb57728d298fda048ff6cb79451b6ca77ce24747a6fa20a438d0ff",
              "1bb90bdb93fd64c29560dc6efc4d4895abc38767b5154d36134f5c94ca4ba27d5656c5dafab013d014b0",
            ),
            (
              true, "59ec6fe2358f8f663c2c14ab79fa45ff65ddbef232a597c367bedee140677329101ea9d4b1ef93b3af73",
              "ddc85edc9feb2614ab06e377e26a44ad5e1c3b3da8aa69b09a7ae4a6525d13eab2b62ed7d5809e80a580",
            ),
            (
              false, "23bba066d5ad0e022db83030466764e992c49e8fe006d233a4e92f195f0a869839e81630fc124a6b3f9",
              "8a9d3b49e3f2f7cceae44e2aed826aec5ad1a506896a820e608ccee7f37a2c72afb1dd46e5706310677",
            ),
            (
              false, "539f3086379101363a13eebd6e2fa623cc6a0aee76265ae2cfb73217491bc7e5f2a22bb6f061d57ec4d",
              "ddc85edc9feb2614ab06e377e26a44ad5e1c3b3da8aa69b09a7ae4a6525d13eab2b62ed7d5809e80a58",
            ),
            (
              false, "23bba066d5ad0e022db83030466764e992c49e8fe006d233a4e92f195f0a869839e81630fc124a6b3f9",
              "8a9d3b49e3f2f7cceae44e2aed826aec5ad1a506896a820e608ccee7f37a2c72afb1dd46e5706310677",
            ),
            (
              false, "539f3086379101363a13eebd6e2fa623cc6a0aee76265ae2cfb73217491bc7e5f2a22bb6f061d57ec4d",
              "ddc85edc9feb2614ab06e377e26a44ad5e1c3b3da8aa69b09a7ae4a6525d13eab2b62ed7d5809e80a58",
            ),
            (
              false, "8f0037ccb9c0d95a0ca32c4bf1026bc93b207d05f92be085a964e2272e2e6bf07fe71130a4fe7fc15d0",
              "2b512287173bed700967586d6a38c169dc6183920af148a47e2c00a87c162de3d6e7952627b31ef52053",
            ),
            (
              false, "2ed4a926ec0275284c1cf78ea0a83c319781b3ef65135274db27335ffdcc7873f1597d4183d3b90072e",
              "8a9d3b49e3f2f7cceae44e2aed826aec5ad1a506896a820e608ccee7f37a2c72afb1dd46e5706310677",
            ),
          ],
          derivatives: [
            (
              false, "27167228b7521bd661ad6b23bdde81069cb2fd2182711bbfe2f06b58676c158d413cc7c768437b14e6522de0a624cbcbe4a8621c475437eb20bd948403eb18ea1ee5a91d6a4947cb0c1e413c869d31ab75a51",
              "45de6321eba1af8b514fe39ba5856f7cf03e9b9ab8b87b6ef264be624b48c18eb3b87a8174abe5e15719746b43e977adf3740efa89af52d6098a320f8a797014b4cf1728248d0616ad234c579e3fd628b28b00",
            ),
            (
              true, "1487e0d48796ae11bf17353732b3672183958f7ff9d7dee7b367d44708f5176eb4db2b04edebee03cce18c231408032061186c6b233f9adf971d7258f7a802bdbc2d10e19f134811e9b58ea8a16ee87a3678d33",
              "22ef3190f5d0d7c5a8a7f1cdd2c2b7be781f4dcd5c5c3db779325f3125a460c759dc3d40ba55f2f0ab8cba35a1f4bbd6f9ba077d44d7a96b04c51907c53cb80a5a678b941246830b5691a62bcf1feb145945800",
            ),
            (
              false, "21627e1fa4f3409b75656ebefe8094baad5d34d6b4b51f09f2729f188df5e2dccaad4bb0856b23f76bdd1502067af4a29a09462cdacac0cd8deb4de10bcdbdda376e4ff659d8536b6685509d11000a345a47d",
              "45de6321eba1af8b514fe39ba5856f7cf03e9b9ab8b87b6ef264be624b48c18eb3b87a8174abe5e15719746b43e977adf3740efa89af52d6098a320f8a797014b4cf1728248d0616ad234c579e3fd628b28b0",
            ),
            (
              false, "e83b027e12bf6e578560e398922810445e0aa18ef558a6949e643ee977200fe440819b35e92e5886df8cae271906d82257561fdea7f4c7f0059326a89af1a092ccdff4a7c1c510e11c15bdd31390ed9fa4ac9",
              "22ef3190f5d0d7c5a8a7f1cdd2c2b7be781f4dcd5c5c3db779325f3125a460c759dc3d40ba55f2f0ab8cba35a1f4bbd6f9ba077d44d7a96b04c51907c53cb80a5a678b941246830b5691a62bcf1feb14594580",
            ),
            (
              false, "21627e1fa4f3409b75656ebefe8094baad5d34d6b4b51f09f2729f188df5e2dccaad4bb0856b23f76bdd1502067af4a29a09462cdacac0cd8deb4de10bcdbdda376e4ff659d8536b6685509d11000a345a47d",
              "45de6321eba1af8b514fe39ba5856f7cf03e9b9ab8b87b6ef264be624b48c18eb3b87a8174abe5e15719746b43e977adf3740efa89af52d6098a320f8a797014b4cf1728248d0616ad234c579e3fd628b28b0",
            ),
            (
              false, "e83b027e12bf6e578560e398922810445e0aa18ef558a6949e643ee977200fe440819b35e92e5886df8cae271906d82257561fdea7f4c7f0059326a89af1a092ccdff4a7c1c510e11c15bdd31390ed9fa4ac9",
              "22ef3190f5d0d7c5a8a7f1cdd2c2b7be781f4dcd5c5c3db779325f3125a460c759dc3d40ba55f2f0ab8cba35a1f4bbd6f9ba077d44d7a96b04c51907c53cb80a5a678b941246830b5691a62bcf1feb14594580",
            ),
            (
              false, "96f880eed21a2443bf800771a9c6714a9ff5facb3030b583c6dc64e27f885677186bad7542127722c92d3a1584886ec79aad049f14482231c1531fda044e082c6f0d88fe040c3bc9f5de20c58e6fe69d304d",
              "15d57efa99a286db8968f720a3b9b2d70b1390a059b9a692abbf7b7eb786bc7c9829a6487475b7d66b37f4618538f5665c1444ae4b06c9e2e2fb2fa4db45f3067880b73c8b6c11e7161b07db6173f2ecb7cb7",
            ),
            (
              false, "667297c5d7420f940355157efcdd57653c51cc5a58944834ffc5c6c381b9ee3b3627ad807786118ca5c24a2c5070e7b25ee7fd296de79e2c0dd51dbb06912d32f7b0789d141794828193a54de5b73292e855",
              "22ef3190f5d0d7c5a8a7f1cdd2c2b7be781f4dcd5c5c3db779325f3125a460c759dc3d40ba55f2f0ab8cba35a1f4bbd6f9ba077d44d7a96b04c51907c53cb80a5a678b941246830b5691a62bcf1feb1459458",
            ),
            (
              false, "22f1cc03db2ca197895b8b10e745dd8f042854cf4fca8037190e02c378e17ba40fb5ca4442f1ec97632b1f79593ec17f291f8ec97aefa55db41adf0a1e78cf27e6e3b524faa9bcc04f27b4a6dd38fc1b49315",
              "45de6321eba1af8b514fe39ba5856f7cf03e9b9ab8b87b6ef264be624b48c18eb3b87a8174abe5e15719746b43e977adf3740efa89af52d6098a320f8a797014b4cf1728248d0616ad234c579e3fd628b28b0",
            ),
            (
              false, "170d7fe71ad3e3f95eb0c43444bba565c9511df3a6fe35c829e1e47aa3c0e0114412a14585d78fe8d9e8956b606335bafb216ae1eba9d02526bd9b07c40940bd6f5c64b0a14ed9eedd879d250fa7dba75f1635",
              "22ef3190f5d0d7c5a8a7f1cdd2c2b7be781f4dcd5c5c3db779325f3125a460c759dc3d40ba55f2f0ab8cba35a1f4bbd6f9ba077d44d7a96b04c51907c53cb80a5a678b941246830b5691a62bcf1feb14594580",
            ),
            (
              false, "87690b1b0ac4fb00b4b9dfd93926ac745de44555ffacd3694bb421b82438b77e531b32939f8763f94fc5cc15741f3e5c654289181cd6221abbcec20d3beb7552f98035f85feb4221baa56a636df0bc421f0d",
              "15d57efa99a286db8968f720a3b9b2d70b1390a059b9a692abbf7b7eb786bc7c9829a6487475b7d66b37f4618538f5665c1444ae4b06c9e2e2fb2fa4db45f3067880b73c8b6c11e7161b07db6173f2ecb7cb7",
            ),
            (
              false, "721aa76a8ff15352edad3c72817c4406d8519fd402f575f40730891f98f6242e172071f384c8061f46aae23468ec5dc4e80bb3a7010b0d8d047b92d008d6073d554724fc950d66dca113d22c3349570e1269",
              "22ef3190f5d0d7c5a8a7f1cdd2c2b7be781f4dcd5c5c3db779325f3125a460c759dc3d40ba55f2f0ab8cba35a1f4bbd6f9ba077d44d7a96b04c51907c53cb80a5a678b941246830b5691a62bcf1feb1459458",
            ),
            (
              false, "87690b1b0ac4fb00b4b9dfd93926ac745de44555ffacd3694bb421b82438b77e531b32939f8763f94fc5cc15741f3e5c654289181cd6221abbcec20d3beb7552f98035f85feb4221baa56a636df0bc421f0d",
              "15d57efa99a286db8968f720a3b9b2d70b1390a059b9a692abbf7b7eb786bc7c9829a6487475b7d66b37f4618538f5665c1444ae4b06c9e2e2fb2fa4db45f3067880b73c8b6c11e7161b07db6173f2ecb7cb7",
            ),
            (
              false, "721aa76a8ff15352edad3c72817c4406d8519fd402f575f40730891f98f6242e172071f384c8061f46aae23468ec5dc4e80bb3a7010b0d8d047b92d008d6073d554724fc950d66dca113d22c3349570e1269",
              "22ef3190f5d0d7c5a8a7f1cdd2c2b7be781f4dcd5c5c3db779325f3125a460c759dc3d40ba55f2f0ab8cba35a1f4bbd6f9ba077d44d7a96b04c51907c53cb80a5a678b941246830b5691a62bcf1feb1459458",
            ),
            (
              false, "e746eb174a909af785a02945c5fc90534330f8e2aa53a660a0d082ea1dd8c0abe6078fc19044368a0e8c1cdcdecb8556ddc4bdade6d7b095ce0f28c1e96f7f89aa18f873eae74ff6cfcde8e6e9dccfdec150",
              "6d2b7ae5002ca249af0cd3a332a07e333761d321c0a040dd5abd697995a1ae6ef8d03f6a464c97301817c5e79a1ccaffcc6557677721f16e6ee7ee38485dbf205a83942eb91c59836e872748e743be9f96f93",
            ),
            (
              false, "19d29b13552775a16d50c9c4186f46b261199ff099333ce08e77368a8c2426d8565ce5be5342f8986298e8a7ce3544986b2072b10d3931c715fbfc7fd2c928d162d99a498abbdb5d34574320c90e10205bcc2",
              "15d57efa99a286db8968f720a3b9b2d70b1390a059b9a692abbf7b7eb786bc7c9829a6487475b7d66b37f4618538f5665c1444ae4b06c9e2e2fb2fa4db45f3067880b73c8b6c11e7161b07db6173f2ecb7cb7",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              false, "3c1f5d6d57df66c75e0305202c0e8f3c635739687a7f85597976b5c3087f333dca1fe4af85fa092f4990a6026f4398497c634545135135b047cd2426e4f1f",
              "17b3fc90395b0cb8a5b8ce65e4c3ff1b0d48d99ed4ceb1bf63d4edc80a5ee34007cf5e90e2b51e790f45f26a1959e3046782492bc9886f4a373319ee7bc332",
            ),
            (
              true, "3c1f5d6d57df66c75e0305202c0e8f3c635739687a7f85597976b5c3087f333dca1fe4af85fa092f4990a6026f4398497c634545135135b047cd2426e4f1f",
              "17b3fc90395b0cb8a5b8ce65e4c3ff1b0d48d99ed4ceb1bf63d4edc80a5ee34007cf5e90e2b51e790f45f26a1959e3046782492bc9886f4a373319ee7bc332",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "5531f4841db7b841ab8d723706af3c51b5a66f995d799b0f4c83d16cc75fa0687d19971581ec130c0dc001b219b11eea35f69bc70d29599f0497174ec39a8",
              "3b41f7688f639fcd9e4e03febbe9fdc3a136200d1404bc5e7994527419ed382013866c6a36c4cc2ea62ede093f60b78b02c5b6ed77d5163989ffc0d43567fd",
            ),
            (
              false, "5531f4841db7b841ab8d723706af3c51b5a66f995d799b0f4c83d16cc75fa0687d19971581ec130c0dc001b219b11eea35f69bc70d29599f0497174ec39a8",
              "3b41f7688f639fcd9e4e03febbe9fdc3a136200d1404bc5e7994527419ed382013866c6a36c4cc2ea62ede093f60b78b02c5b6ed77d5163989ffc0d43567fd",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "1b10b07f5af74e6e60e52292ce080d9d29c57ff14b0232c0b54e07bce0dd4ac8c50aa89bf6dbff3e5376498690852524c3444833608e10f7e8e9d60c5bf229",
              "17b3fc90395b0cb8a5b8ce65e4c3ff1b0d48d99ed4ceb1bf63d4edc80a5ee34007cf5e90e2b51e790f45f26a1959e3046782492bc9886f4a373319ee7bc3320",
            ),
            (
              true, "1b10b07f5af74e6e60e52292ce080d9d29c57ff14b0232c0b54e07bce0dd4ac8c50aa89bf6dbff3e5376498690852524c3444833608e10f7e8e9d60c5bf229",
              "17b3fc90395b0cb8a5b8ce65e4c3ff1b0d48d99ed4ceb1bf63d4edc80a5ee34007cf5e90e2b51e790f45f26a1959e3046782492bc9886f4a373319ee7bc3320",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "4c7f7e95f4d7dea06a28912cf410c1680e7282298015ae75781d6bb212dc74ea562eb7c2be082a04323dba46ef79e877ada3d958c8f1b5a3c412447ccb7e7",
              "17b3fc90395b0cb8a5b8ce65e4c3ff1b0d48d99ed4ceb1bf63d4edc80a5ee34007cf5e90e2b51e790f45f26a1959e3046782492bc9886f4a373319ee7bc332",
            ),
            (
              false, "4c7f7e95f4d7dea06a28912cf410c1680e7282298015ae75781d6bb212dc74ea562eb7c2be082a04323dba46ef79e877ada3d958c8f1b5a3c412447ccb7e7",
              "17b3fc90395b0cb8a5b8ce65e4c3ff1b0d48d99ed4ceb1bf63d4edc80a5ee34007cf5e90e2b51e790f45f26a1959e3046782492bc9886f4a373319ee7bc332",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (
              false, "25eb2fb8c41550db2df1aeed729c63139d42b95095845ba693cc29d134639ed05b4b25020d369fbe0ef",
              "6ee42f6e4ff5930a558371bbf1352256af0e1d9ed45534d84d3d7253292e89f5595b176beac04f4052c0",
            ),
            (
              true, "25eb2fb8c41550db2df1aeed729c63139d42b95095845ba693cc29d134639ed05b4b25020d369fbe0ef",
              "6ee42f6e4ff5930a558371bbf1352256af0e1d9ed45534d84d3d7253292e89f5595b176beac04f4052c0",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "4b59a32b44facb7a9b81c99d016e4e683bcbf588e044b5f29c4e6a142638b399b09adc8e2ab8bba7d5",
              "22a74ed278fcbdf33ab9138abb609abb16b46941a25aa083982333b9fcde8b1cabec7751b95c18c419dc",
            ),
            (
              false, "4b59a32b44facb7a9b81c99d016e4e683bcbf588e044b5f29c4e6a142638b399b09adc8e2ab8bba7d5",
              "22a74ed278fcbdf33ab9138abb609abb16b46941a25aa083982333b9fcde8b1cabec7751b95c18c419dc",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "3ca0c8e272f38510a3fb4dcb9f6c6c38228d06241226c169cda82bad4eb2c0b1fe5e451d38f263ccdf",
              "299591c95dfc1723e0114aa67a73ece081a54b1b8f9ff3d11cf70adf2f7173bc018228c878081db81f08",
            ),
            (
              true, "3ca0c8e272f38510a3fb4dcb9f6c6c38228d06241226c169cda82bad4eb2c0b1fe5e451d38f263ccdf",
              "299591c95dfc1723e0114aa67a73ece081a54b1b8f9ff3d11cf70adf2f7173bc018228c878081db81f08",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "41e37492bb8badb88b7509989249d9e88898de99453b1957ad7ee731144b7e20c5c4bb242da3cc306",
              "aa9a219604dc44ad6fddea0d7316aafb83782d91e434514cc5999c312baa0f521351105741c5663b93",
            ),
            (
              false, "41e37492bb8badb88b7509989249d9e88898de99453b1957ad7ee731144b7e20c5c4bb242da3cc306",
              "aa9a219604dc44ad6fddea0d7316aafb83782d91e434514cc5999c312baa0f521351105741c5663b93",
            ),
            (false, "0", "1"),
          ],
          ricci: [
            (
              true, "1b10b07f5af74e6e60e52292ce080d9d29c57ff14b0232c0b54e07bce0dd4ac8c50aa89bf6dbff3e5376498690852524c3444833608e10f7e8e9d60c5bf229",
              "17b3fc90395b0cb8a5b8ce65e4c3ff1b0d48d99ed4ceb1bf63d4edc80a5ee34007cf5e90e2b51e790f45f26a1959e3046782492bc9886f4a373319ee7bc3320",
            ),
            (
              false, "3c1f5d6d57df66c75e0305202c0e8f3c635739687a7f85597976b5c3087f333dca1fe4af85fa092f4990a6026f4398497c634545135135b047cd2426e4f1f",
              "17b3fc90395b0cb8a5b8ce65e4c3ff1b0d48d99ed4ceb1bf63d4edc80a5ee34007cf5e90e2b51e790f45f26a1959e3046782492bc9886f4a373319ee7bc332",
            ),
            (
              false, "4c7f7e95f4d7dea06a28912cf410c1680e7282298015ae75781d6bb212dc74ea562eb7c2be082a04323dba46ef79e877ada3d958c8f1b5a3c412447ccb7e7",
              "17b3fc90395b0cb8a5b8ce65e4c3ff1b0d48d99ed4ceb1bf63d4edc80a5ee34007cf5e90e2b51e790f45f26a1959e3046782492bc9886f4a373319ee7bc332",
            ),
            (
              true, "5531f4841db7b841ab8d723706af3c51b5a66f995d799b0f4c83d16cc75fa0687d19971581ec130c0dc001b219b11eea35f69bc70d29599f0497174ec39a8",
              "3b41f7688f639fcd9e4e03febbe9fdc3a136200d1404bc5e7994527419ed382013866c6a36c4cc2ea62ede093f60b78b02c5b6ed77d5163989ffc0d43567fd",
            ),
          ],
        },
        {
          alpha: (true, "1", "1"),
          scalar: (
            true, "244d01c9926cd5e315a9810cf8ffec3eacfc5e332c820d284ede859ec00d9ba6d56a04f353c79f2651191e",
            "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
          ),
          lower: [
            (
              true, "123dd3f21429f6d6aba75fc56de54ae248b", "30dc32a581ea0c6611ba6f9acd6c5cf2a2e8",
            ),
            (
              true, "f39cfacf29ae9530728544d75df8439377", "145bbfc4f621852a876303d5d597d1651936",
            ),
            (
              false, "2720c0f13eb9c8cc9f88ad128e5241ffc7", "5ce8493557ba595dc4cd1f9a6b917205490",
            ),
            (
              false, "338b0e00841a54120abcc800235af6ef1", "9ad87a03923694f19d55df56b347be08cf",
            ),
            (
              false, "2720c0f13eb9c8cc9f88ad128e5241ffc7", "5ce8493557ba595dc4cd1f9a6b917205490",
            ),
            (
              false, "338b0e00841a54120abcc800235af6ef1", "9ad87a03923694f19d55df56b347be08cf",
            ),
            (
              false, "993efd4d4c29e6ede124bdbaccc09b0", "8c542b8327cfe2a6b6f5dc0ed3180a6b487",
            ),
            (
              false, "76f486d898500986438b9f4822f7d45690", "8c542b8327cfe2a6b6f5dc0ed3180a6b487",
            ),
          ],
          lower_first: [
            (
              false, "429411fdf56deb1471f9c4578ca780f99da8c5dd9fb45a9cf0e24e22bc02343d9f5",
              "303a8356201558cd819322f8b048c76cbc3e77b6d7fa8d398367749ce625cb4bc37180",
            ),
            (
              true, "37a3e50e8d2cc835af361a3bee00c1a5e0ebcb2fc4ddce4425c98dfddcf27ee5cf8f",
              "303a8356201558cd819322f8b048c76cbc3e77b6d7fa8d398367749ce625cb4bc3718",
            ),
            (
              false, "9fc442513e1601978700f6a796791ec1413d43523e93d191ab24179a8ead31f703",
              "a76779638af236ac5d926c61d987ac104ff4f41200473d874b056e1780605505900",
            ),
            (
              false, "2b4ac754f471f67341919d3e975cdf9d82500e2fbf598a53132f2e56e38caabf1",
              "11701ca50923e5b1f469eb4a31537741b2fed96c8ab21668c27b3b77c80a08db3f0",
            ),
            (
              false, "9fc442513e1601978700f6a796791ec1413d43523e93d191ab24179a8ead31f703",
              "a76779638af236ac5d926c61d987ac104ff4f41200473d874b056e1780605505900",
            ),
            (
              false, "2b4ac754f471f67341919d3e975cdf9d82500e2fbf598a53132f2e56e38caabf1",
              "11701ca50923e5b1f469eb4a31537741b2fed96c8ab21668c27b3b77c80a08db3f0",
            ),
            (
              true, "4e60edc434def169fd775ca59c17b96fff0bb6442394474d42274040728f4096f1e8",
              "14fa976fa55ddc6cea591373b49857de566980b83c36e2e8586abf1a55b0c0fca66599",
            ),
            (
              false, "7f3aca155d0df04094395f0f4b5d562939756cad437fbaa6249fc9c0d57231f5ffa0",
              "6fe327a8c749ecef8c85bd13c32c7f4c778803d6967a0f81d78ea5e1c904054377733",
            ),
            (
              false, "af2c7918b9906bc908d2c8dd062f60807746c1bd47bd4cfe3853de598bfb0c326ba3",
              "90af8a0260400a6884b968ea10da564634bb672487efa7ac8a365dd6b27161e34a548",
            ),
            (
              true, "1069c440ecba0c5d938fea694efc39d418af3097dd2232bbff5ccdbe7c9d6132094c",
              "1e249215d40d578070fbf5db6e2d7ca3f5a70ad246fc9843f220a8e20fd79f0f5a26f",
            ),
            (
              false, "16c843fac9b5c93485c95a34c63bd55744524a0012ca754691642af6ae9fb80913",
              "345055ef1b6bb115dd3dc1de93fa65c518fc8c45a016433a4771b267581e1a91bd0",
            ),
            (
              false, "36faee701e28698568d6a26911c6a9806c860813d493b0b137ac32dd6742328f9",
              "57308f392db37c79c6119872f6a154487efa3f1eb57a700bcc682956e8322c483b",
            ),
            (
              false, "16c843fac9b5c93485c95a34c63bd55744524a0012ca754691642af6ae9fb80913",
              "345055ef1b6bb115dd3dc1de93fa65c518fc8c45a016433a4771b267581e1a91bd0",
            ),
            (
              false, "36faee701e28698568d6a26911c6a9806c860813d493b0b137ac32dd6742328f9",
              "57308f392db37c79c6119872f6a154487efa3f1eb57a700bcc682956e8322c483b",
            ),
            (
              true, "1e30db728c609dc5808bf39247447e295e9e15a23116c783c38192624a2600618f60",
              "14fa976fa55ddc6cea591373b49857de566980b83c36e2e8586abf1a55b0c0fca66599",
            ),
            (
              false, "45dbb4d0448c881eba464daa341d350f820c49e2fdce47a68c3f54e42dc9fbddb4cc0",
              "22f6fc64be471a0adbe9cb162cfde7c7e55a81330f0624d8935c93d68ed141a51553ff",
            ),
          ],
          coefficients: [
            (
              true, "1863039dabb9f49de41137f0fe9abd6a6f8cb3206ae", "6d70b1fdd93bfea16426b47b63e2cf8211d147bbe2b",
            ),
            (
              true, "15d6232d3e447f7046e78ec903280e2d599174f584f3", "36b858feec9dff50b2135a3db1f167c108e8a3ddf158",
            ),
            (
              false, "17388bc243ba1eb4e82700e87778b92d2a0bad8b404", "6d70b1fdd93bfea16426b47b63e2cf8211d147bbe2b",
            ),
            (
              false, "2b285132686cb3eb84099c41676cc69a856016caf11", "dae163fbb277fd42c84d68f6c7c59f0423a28f77c56",
            ),
            (
              false, "17388bc243ba1eb4e82700e87778b92d2a0bad8b404", "6d70b1fdd93bfea16426b47b63e2cf8211d147bbe2b",
            ),
            (
              false, "2b285132686cb3eb84099c41676cc69a856016caf11", "dae163fbb277fd42c84d68f6c7c59f0423a28f77c56",
            ),
            (
              false, "721609e4be6dafc508d045211282e1d19a3ef05940", "6d70b1fdd93bfea16426b47b63e2cf8211d147bbe2b",
            ),
            (
              false, "2df333ad401688754764b39fdf89fe7c2ed9542e374", "6d70b1fdd93bfea16426b47b63e2cf8211d147bbe2b",
            ),
          ],
          derivatives: [
            (
              true, "28dfc6c565b6306cc9f38e3ffcafa6664e0fb3bb31084f67215906a6d0d242106e51a27f4b0892486a5a73",
              "bb24a4b99370b5c12e1f4b25c2315de6d1d20226e5aa2d082688f3c6177b7ddf67f223200ef5140a576ce4",
            ),
            (
              true, "28097ebe73866f3d7a98b6b98bb90a4c08ee587e28b1a3ad41ddfeaaa7db94860dd69c471930f84d744522b",
              "5d92525cc9b85ae0970fa592e118aef368e9011372d51684134479e30bbdbeefb3f91190077a8a052bb6720",
            ),
            (
              false, "19d3afde419b5ac4a7ad1bebf52549a75e0401ad60bb71c044bb2b018c5edf7a75589b25f757d130cbfa21",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (
              false, "2652125a60b7bcc168838b446484f12e7d5fc8373313d6b2e99173ff90a4d56df1a6c49548e07cbc526d2d",
              "17649497326e16b825c3e964b8462bbcda3a4044dcb545a104d11e78c2ef6fbbecfe446401dea2814aed9c8",
            ),
            (
              false, "19d3afde419b5ac4a7ad1bebf52549a75e0401ad60bb71c044bb2b018c5edf7a75589b25f757d130cbfa21",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (
              false, "2652125a60b7bcc168838b446484f12e7d5fc8373313d6b2e99173ff90a4d56df1a6c49548e07cbc526d2d",
              "17649497326e16b825c3e964b8462bbcda3a4044dcb545a104d11e78c2ef6fbbecfe446401dea2814aed9c8",
            ),
            (
              false, "1bb7997bb0fd97bafe224dcffeabf9bec2ea7035f07c2ff2638afcb53db7dc92605fc128de2dde448ba88",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (
              false, "10ae4befb1aafeea455be3636066842aac633d7ed003ccb739bede02658ddb561928c472c41fd8c3a1fab9",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (
              false, "239a4e1472dd5dba24090177ff02236c2f04224103f19eecf09ae37e000807d4e9916084c356215dec6e6c",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (
              false, "a9ed5e0b415e519bbba2e1fd5cacc23a6135c923d8e4351c3c6f21f10419c7cc49e73b967c60442d43d20",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (
              false, "3044bd0af2d9d787cf5e4d4b19c6e3ed24d6b644b2423a31b8e9ad6997cc31a87e738790b2b3ee3342b00",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (
              false, "4e2850d86102d14b7651babcb57d2c2ecf949ff2f87f8ac0fb96c7b6987e156b7d61cf4e16453bcd9ab8a",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (
              false, "3044bd0af2d9d787cf5e4d4b19c6e3ed24d6b644b2423a31b8e9ad6997cc31a87e738790b2b3ee3342b00",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (
              false, "4e2850d86102d14b7651babcb57d2c2ecf949ff2f87f8ac0fb96c7b6987e156b7d61cf4e16453bcd9ab8a",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (
              true, "446cb1e60e283dd703bf1d810ffb23f9c8054c623aabe61c0e9fe3710fb028461355e3f491b04cc634680",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (
              false, "1d571bc190a338f12a9e83d4090d8df193034056bead05bd060d05f52436ba43de2ef965dfc19ea1ccd720",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              true, "69a22c2934c48c0bfaf83513ed70067df8a6aa7289e4f55de1f61869dc53bd48db9c0fd005f6e69c1e531",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (
              false, "69a22c2934c48c0bfaf83513ed70067df8a6aa7289e4f55de1f61869dc53bd48db9c0fd005f6e69c1e531",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "80c850d35c36319b5d4d63e00cab8f0e72fc0249a5bff6f7dad9db8d15462a05df9ec0bbde54ce5872d8",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (
              false, "80c850d35c36319b5d4d63e00cab8f0e72fc0249a5bff6f7dad9db8d15462a05df9ec0bbde54ce5872d8",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "f5f98b92fc13c2b524fc4ea1d2b03eb44d95f8e1bb6842c1cd83071030af3c906ba6b92bc5760406f57f7",
              "17649497326e16b825c3e964b8462bbcda3a4044dcb545a104d11e78c2ef6fbbecfe446401dea2814aed9c8",
            ),
            (
              true, "f5f98b92fc13c2b524fc4ea1d2b03eb44d95f8e1bb6842c1cd83071030af3c906ba6b92bc5760406f57f7",
              "17649497326e16b825c3e964b8462bbcda3a4044dcb545a104d11e78c2ef6fbbecfe446401dea2814aed9c8",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "89f4b6e8da517a0d14a657cca08d80acdf43d9325e3f6345c451a9126220d797ad3a31c171ca34369c015",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (
              true, "89f4b6e8da517a0d14a657cca08d80acdf43d9325e3f6345c451a9126220d797ad3a31c171ca34369c015",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (
              true, "25eb2fb8c41550db2df1aeed729c63139d42b95095845ba693cc29d134639ed05b4b25020d369fbe0ef",
              "6ee42f6e4ff5930a558371bbf1352256af0e1d9ed45534d84d3d7253292e89f5595b176beac04f4052c0",
            ),
            (
              false, "25eb2fb8c41550db2df1aeed729c63139d42b95095845ba693cc29d134639ed05b4b25020d369fbe0ef",
              "6ee42f6e4ff5930a558371bbf1352256af0e1d9ed45534d84d3d7253292e89f5595b176beac04f4052c0",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "3ca0c8e272f38510a3fb4dcb9f6c6c38228d06241226c169cda82bad4eb2c0b1fe5e451d38f263ccdf",
              "299591c95dfc1723e0114aa67a73ece081a54b1b8f9ff3d11cf70adf2f7173bc018228c878081db81f08",
            ),
            (
              false, "3ca0c8e272f38510a3fb4dcb9f6c6c38228d06241226c169cda82bad4eb2c0b1fe5e451d38f263ccdf",
              "299591c95dfc1723e0114aa67a73ece081a54b1b8f9ff3d11cf70adf2f7173bc018228c878081db81f08",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "4b59a32b44facb7a9b81c99d016e4e683bcbf588e044b5f29c4e6a142638b399b09adc8e2ab8bba7d5",
              "22a74ed278fcbdf33ab9138abb609abb16b46941a25aa083982333b9fcde8b1cabec7751b95c18c419dc",
            ),
            (
              true, "4b59a32b44facb7a9b81c99d016e4e683bcbf588e044b5f29c4e6a142638b399b09adc8e2ab8bba7d5",
              "22a74ed278fcbdf33ab9138abb609abb16b46941a25aa083982333b9fcde8b1cabec7751b95c18c419dc",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "41e37492bb8badb88b7509989249d9e88898de99453b1957ad7ee731144b7e20c5c4bb242da3cc306",
              "aa9a219604dc44ad6fddea0d7316aafb83782d91e434514cc5999c312baa0f521351105741c5663b93",
            ),
            (
              true, "41e37492bb8badb88b7509989249d9e88898de99453b1957ad7ee731144b7e20c5c4bb242da3cc306",
              "aa9a219604dc44ad6fddea0d7316aafb83782d91e434514cc5999c312baa0f521351105741c5663b93",
            ),
            (false, "0", "1"),
          ],
          ricci: [
            (
              true, "f5f98b92fc13c2b524fc4ea1d2b03eb44d95f8e1bb6842c1cd83071030af3c906ba6b92bc5760406f57f7",
              "17649497326e16b825c3e964b8462bbcda3a4044dcb545a104d11e78c2ef6fbbecfe446401dea2814aed9c8",
            ),
            (
              true, "69a22c2934c48c0bfaf83513ed70067df8a6aa7289e4f55de1f61869dc53bd48db9c0fd005f6e69c1e531",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (
              true, "89f4b6e8da517a0d14a657cca08d80acdf43d9325e3f6345c451a9126220d797ad3a31c171ca34369c015",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
            (
              true, "80c850d35c36319b5d4d63e00cab8f0e72fc0249a5bff6f7dad9db8d15462a05df9ec0bbde54ce5872d8",
              "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
            ),
          ],
        },
        {
          alpha: (false, "3", "5"),
          scalar: (
            true, "1e3a13c566be26bc9e8c154614b82cf06ef6cd1c76c2a9e89c6db4f031116296efcf25697f424ca8b0ecce",
            "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
          ),
          lower: [
            (
              true, "e9e4545ae0413a8f9ea8e9aea4837318ae9317a1cbe806235c3cab1418937f926d715c8d887a0911",
              "16668eeb5860bcee6ccb778ff72e2696565049c990af328fb6d739e56bb1a8bba19ecc78961db64d00",
            ),
            (
              true, "501440e50429621b23e83a7b15b01e68fe2ff0f49d53ec1fc41c8a9ab6d278f3dab25e680226da15",
              "7000ca98b9e3b0a81ff955cfd3e6c0efaf9170efd36bfcce9234217b1a784baa2819fe5aee948f810",
            ),
            (
              false, "879e504cbdec532a839af268c374f6204eeb93d3129ec707558fdf1270120e98a5ea0af1c1ec19b",
              "12aacc6ec9a5f2c6affee3a2a3512027f2983d7d4de754cd185e0594846961f1b159aa647d18c2958",
            ),
            (
              false, "736b82a4ec63a9d0eb179832a1c4de83e1367321a1677406bbcbb4a3811ccad32d9a440b48a61be",
              "baabfc53e07b7bc2dff4e45a612b418f79f266e50b095002f3ac37cd2c1dd370ed80a7ece2f799d7",
            ),
            (
              false, "879e504cbdec532a839af268c374f6204eeb93d3129ec707558fdf1270120e98a5ea0af1c1ec19b",
              "12aacc6ec9a5f2c6affee3a2a3512027f2983d7d4de754cd185e0594846961f1b159aa647d18c2958",
            ),
            (
              false, "736b82a4ec63a9d0eb179832a1c4de83e1367321a1677406bbcbb4a3811ccad32d9a440b48a61be",
              "baabfc53e07b7bc2dff4e45a612b418f79f266e50b095002f3ac37cd2c1dd370ed80a7ece2f799d7",
            ),
            (
              false, "35552657d94e3efb4b7c1885ad178e7caebae85bad7d883209c879f37f59f5fe9e31bbd6f9ffc85",
              "baabfc53e07b7bc2dff4e45a612b418f79f266e50b095002f3ac37cd2c1dd370ed80a7ece2f799d7",
            ),
            (
              false, "335ff73a1dac133fcfc08cc31a326d67e7f60cd6ba8d4ed1391cd4f7a77ef85fe0d84c270a63368e0",
              "4c908a7e6712a5c2eddb71a911dabde3d9046c33f186d1d135f1a2e327183bb95169c4e029178e192f",
            ),
          ],
          lower_first: [
            (
              false, "19f92e9b59813a60afe16c6c40966dfc9f196f10cd3cb3ec0b7d191810450ec976df9aea6322f45ef7a8ea32df8e0042583985a984900d22ee96e987",
              "279e21ac3e5c0c7375e61b00b400b027bb27e9a57c4a7c92412c78c21217c9afe6da1d22b230eab8e596e3806ae2f777f956408694a0a91d4bb918800",
            ),
            (
              true, "202fac3e0b0bf7b934b4b051c9f8bcaa78dc615396dd948badd94ee3f2cfaff388bbe289c2177a44724e9a224f597e1b0b116795d4782b44e8f7fc7",
              "1602847c22a4ea79089c47e3f239456b67f9bab1450cefdf798a7bfa0a0d3728d5959e689be249832a3761f2027e17b46e13792e5292251046834680",
            ),
            (
              false, "55452b348544be96dc9d18f74f34e25cde1adc96bef9197215eaddc37c4caa41d5b514fdd431430664530f35276eab1c4d40920042bfa636f0532b3",
              "840f1ae8cfdd7ed633a9af57ad57a0846fda60279e4d9f3cd93ee7dc3c4f4af50181b673a74db912fd4c4bac0ef48e3a9474d715ef6cde61a713a700",
            ),
            (
              false, "b74fd03f2f2a9bf2136808ecdfd2f367b2c8880104e11cda580e68ccc5603d47093b86b41eedcd3e124e99857ff11c2ebf4dbecbe1a5fba7a062f5",
              "dc192cd95a7128ba561acee7763cb6320fc14aecb2815ebabf68d7c46484279857d8301616d6df1fa629d37418eced0c4cc2bbcf39b572a2c120c10",
            ),
            (
              false, "55452b348544be96dc9d18f74f34e25cde1adc96bef9197215eaddc37c4caa41d5b514fdd431430664530f35276eab1c4d40920042bfa636f0532b3",
              "840f1ae8cfdd7ed633a9af57ad57a0846fda60279e4d9f3cd93ee7dc3c4f4af50181b673a74db912fd4c4bac0ef48e3a9474d715ef6cde61a713a700",
            ),
            (
              false, "b74fd03f2f2a9bf2136808ecdfd2f367b2c8880104e11cda580e68ccc5603d47093b86b41eedcd3e124e99857ff11c2ebf4dbecbe1a5fba7a062f5",
              "dc192cd95a7128ba561acee7763cb6320fc14aecb2815ebabf68d7c46484279857d8301616d6df1fa629d37418eced0c4cc2bbcf39b572a2c120c10",
            ),
            (
              false, "92a63c90b6d7801265482c47170b89ce3af369476d9adea983645012584b2897e0b6487c151d6704e524bf2be5a83cfd7167ace2656cc891086c99",
              "14a25c34607a9bd178128365b315b114b17a1f0630bc20e181f1d43a696c63b6483c4482122424eaf793ebd2e25636392732419b6d6902bf421b1218",
            ),
            (
              false, "2bcac2b90056e4c09bd1081777f0fdcdb68e9390223cdcb76a6f632812555cdabe6bfb7f1102314c41f782ed312fe9a06e6b4910e8f2123f3b6e9a",
              "44c7de03ec435cba3ae860a854f2f8efa4ec6769f7c86d9a5bd0c36d5f694c5f9b738f06e72325b9e3ed121447ca0a13d7fcdab0c208b3d2dc5a3c5",
            ),
            (
              false, "67ef1f3717ca7b87c3df2893e1642520a904366266a80c76c093a2f58ccb6990bf0d26a555db44cf9e6de0a7154beca4bfadb83a23e93d52b13383",
              "d34b5e414c9597bd1f75e559155900d3e62a337296e298615b97d960607ede54cf35f0b90baf8e84c87a12ace4ba7d2a8721582318ae309c3e85d80",
            ),
            (
              false, "3412f57a2db121645ec5cdb5253a0c912832be9e62472ee6053057e497b6c5bfa3c7ac7658698773feb58c1106a02eeb6def41cd5df68fb6dc6079",
              "14a25c34607a9bd178128365b315b114b17a1f0630bc20e181f1d43a696c63b6483c4482122424eaf793ebd2e25636392732419b6d6902bf421b1218",
            ),
            (
              false, "16c3ce1e519663f6dae2b266b7d1b1b46009f9b81a9688752cb2af87b853d3c1e0965582bf31b1f85c4f63c22fc712e31fe898e906c52d50fe61bf",
              "140249e536c47810f08e12cf394b5661a45763e6f8f47cf9b44f596ef1dd77f6939f4a308db6715ff7d541c4bc72a12fa9e32858a827c49a6ea5e30",
            ),
            (
              false, "5e1a84206ef185a7cebe98dc63d4a0144a3bd91aaf4931ea6b2e4df9ecb47cec3ad967c5f5707101a9de59cab60670921064924372603c0b3ebdb",
              "640b717a11d65854b2c65e0c1e78afe835b4f382dcc670e0858cbf2ab95357d0e21c72f2c49036dfd72a48d7ae3d25ee516fc9bb48c6d704293d6f",
            ),
            (
              false, "16c3ce1e519663f6dae2b266b7d1b1b46009f9b81a9688752cb2af87b853d3c1e0965582bf31b1f85c4f63c22fc712e31fe898e906c52d50fe61bf",
              "140249e536c47810f08e12cf394b5661a45763e6f8f47cf9b44f596ef1dd77f6939f4a308db6715ff7d541c4bc72a12fa9e32858a827c49a6ea5e30",
            ),
            (
              false, "5e1a84206ef185a7cebe98dc63d4a0144a3bd91aaf4931ea6b2e4df9ecb47cec3ad967c5f5707101a9de59cab60670921064924372603c0b3ebdb",
              "640b717a11d65854b2c65e0c1e78afe835b4f382dcc670e0858cbf2ab95357d0e21c72f2c49036dfd72a48d7ae3d25ee516fc9bb48c6d704293d6f",
            ),
            (
              false, "420e70c3b74153e9ec09b2dc897c0a45a4afd956ee5792232bb282b99abe4556c119f8b8dd69d1bc9b71aa3878955eb9b4eb79edd49f487c8d152",
              "12c22546e358308fe18531a245b6a0fb8a11eda88965352a190a63d802bfa0772a65558d84db0a49f857eda870ab771caf44f5d31da54850c7bb84d",
            ),
            (
              false, "500839b05fc9ab3df6bcf855e504e7b1e8a3dd86b8085cf086cf23114e9fc1314d83075fe24476a35273271f3e9e65ca12b18784638a2508a58068a0",
              "1c35fa0f9be7a10862294fa50ad7a81a4aa4f66a76a134f44fa8a027dc22305336c265a9d4cd6a793e7c3c6a5171de222396b5b27f9591c17c6102bcd",
            ),
          ],
          coefficients: [
            (
              true, "bec3d9849089f0e77f35409287560eeca2fa07c9dba7aae8613727f634f7366873594f414a29adce8b7",
              "22a74ed278fcbdf33ab9138abb609abb16b46941a25aa083982333b9fcde8b1cabec7751b95c18c419dc",
            ),
            (
              true, "1668f081d56c98eb9e2169c970111877a750c773bc70f0fa5c2da661070a5bca600f9826b7963f816bf3",
              "377217b727fac9852ac1b8ddf89a912b57870ecf6a2a9a6c269eb929949744faacad8bb5f56027a02960",
            ),
            (
              false, "ac57b76e09f904badcad21b8db18ed6c9a766fdb540bf89f74bc28a887ad2fa2ac7aed6b040a85ecf78",
              "2b512287173bed700967586d6a38c169dc6183920af148a47e2c00a87c162de3d6e7952627b31ef52053",
            ),
            (
              false, "2f46f24a41e0698999a7deb74a214e0c4df16e59d2490080fb890fc452f776d9c82a0e61467e385155f",
              "8a9d3b49e3f2f7cceae44e2aed826aec5ad1a506896a820e608ccee7f37a2c72afb1dd46e5706310677",
            ),
            (
              false, "ac57b76e09f904badcad21b8db18ed6c9a766fdb540bf89f74bc28a887ad2fa2ac7aed6b040a85ecf78",
              "2b512287173bed700967586d6a38c169dc6183920af148a47e2c00a87c162de3d6e7952627b31ef52053",
            ),
            (
              false, "2f46f24a41e0698999a7deb74a214e0c4df16e59d2490080fb890fc452f776d9c82a0e61467e385155f",
              "8a9d3b49e3f2f7cceae44e2aed826aec5ad1a506896a820e608ccee7f37a2c72afb1dd46e5706310677",
            ),
            (
              false, "26928c1158f1fc0535487b397104d82d22556eb69089f067c93bf58316ff869cd845311631b0a9230680",
              "d895aca3742ba3302f04ba23131bc7114de791da36b66b3676dc034a6c6ee5733285e9bec67f9ac9a19f",
            ),
            (
              false, "f5859d4b013b35ab31f79746adf126e0fdba8247f9145a05c0731a5a4d163e7a678429bc12d38f5ab7c",
              "2b512287173bed700967586d6a38c169dc6183920af148a47e2c00a87c162de3d6e7952627b31ef52053",
            ),
          ],
          derivatives: [
            (
              true, "463fa7245c1890eb30bc77f9646dd8959e546a7b2021bb686c461487f46dc8a24a81bcea143c4e036c3088b4d35c75e7d5b48b31dce455302a64bb99f23df5d8f40eb3bb2791d9894587f70b929b8b26d773",
              "117798c87ae86be2d453f8e6e9615bdf3c0fa6e6ae2e1edbbc992f9892d23063acee1ea05d2af97855c65d1ad0fa5deb7cdd03bea26bd4b582628c83e29e5c052d33c5ca09234185ab48d315e78ff58a2ca2c0",
            ),
            (
              true, "4da813d0d9a8067b48d70aac6156fcb85766d61364ce5360ae57caff365109db555388b923a227884d44c4bc491f1c9738421c1087d7a0287d94372e5ccaf966150ba8534f15a07274fae18e484764e7426ca7",
              "8bbcc643d7435f16a29fc7374b0adef9e07d37357170f6dde4c97cc49691831d6770f502e957cbc2ae32e8d687d2ef5be6e81df5135ea5ac1314641f14f2e029699e2e50491a0c2d5a4698af3c7fac51651600",
            ),
            (
              false, "89afc1b187148aa76abe17d6be8bc75f542ab2b2361d897af1a18a0257ea068d4e210f1a52f85e5878d01c220639aca17b209cf311f71d503fd7cacdc70896374a42dcbe3a662b09c05a7728bb2fe157e2b5",
              "117798c87ae86be2d453f8e6e9615bdf3c0fa6e6ae2e1edbbc992f9892d23063acee1ea05d2af97855c65d1ad0fa5deb7cdd03bea26bd4b582628c83e29e5c052d33c5ca09234185ab48d315e78ff58a2ca2c",
            ),
            (
              false, "314eb51fe5f160a810f50936368388600529e2a625ce0adfea93fbd787febe70ec1c850e7e8626429f4a1407d2defd6000482037890b3082edb9ff6e6a26ae8c1da3d5760bbb4b01ddf1923ac5818322116e1",
              "8bbcc643d7435f16a29fc7374b0adef9e07d37357170f6dde4c97cc49691831d6770f502e957cbc2ae32e8d687d2ef5be6e81df5135ea5ac1314641f14f2e029699e2e50491a0c2d5a4698af3c7fac5165160",
            ),
            (
              false, "89afc1b187148aa76abe17d6be8bc75f542ab2b2361d897af1a18a0257ea068d4e210f1a52f85e5878d01c220639aca17b209cf311f71d503fd7cacdc70896374a42dcbe3a662b09c05a7728bb2fe157e2b5",
              "117798c87ae86be2d453f8e6e9615bdf3c0fa6e6ae2e1edbbc992f9892d23063acee1ea05d2af97855c65d1ad0fa5deb7cdd03bea26bd4b582628c83e29e5c052d33c5ca09234185ab48d315e78ff58a2ca2c",
            ),
            (
              false, "314eb51fe5f160a810f50936368388600529e2a625ce0adfea93fbd787febe70ec1c850e7e8626429f4a1407d2defd6000482037890b3082edb9ff6e6a26ae8c1da3d5760bbb4b01ddf1923ac5818322116e1",
              "8bbcc643d7435f16a29fc7374b0adef9e07d37357170f6dde4c97cc49691831d6770f502e957cbc2ae32e8d687d2ef5be6e81df5135ea5ac1314641f14f2e029699e2e50491a0c2d5a4698af3c7fac5165160",
            ),
            (
              false, "268d162c12c5560565c6ee05bd46b051dc5c4b745b4c2adbbd0ce8c61b9573fd78509bb6b466458da26b0f5877d794764d8150b5428036364f56ec0cd220f020bae49dcc341bd72525ba170ee513055165a2c",
              "6d2b7ae5002ca249af0cd3a332a07e333761d321c0a040dd5abd697995a1ae6ef8d03f6a464c97301817c5e79a1ccaffcc6557677721f16e6ee7ee38485dbf205a83942eb91c59836e872748e743be9f96f93",
            ),
            (
              false, "1e742df37a94d29c3adc7374cfb67b1d8b2016d79fc88598593777d1d121919045aa945858d4d11b798daa87ece39c6c5374e5791b277d1c2b405a0051517aceb10b73dd1e7c68727e0b6f28f54f5aac3baf",
              "8bbcc643d7435f16a29fc7374b0adef9e07d37357170f6dde4c97cc49691831d6770f502e957cbc2ae32e8d687d2ef5be6e81df5135ea5ac1314641f14f2e029699e2e50491a0c2d5a4698af3c7fac516516",
            ),
            (
              false, "9a5b6837dfb882fadd9a39361991804c8da9c4058203081b00a11e7d027ef50b2b90e4c18787b5d3709bb81efb83c4accbdc3505184bfa7950639a730f3466e14ab630c954a5f445bc6e13e9f1fceb0d9ba1",
              "117798c87ae86be2d453f8e6e9615bdf3c0fa6e6ae2e1edbbc992f9892d23063acee1ea05d2af97855c65d1ad0fa5deb7cdd03bea26bd4b582628c83e29e5c052d33c5ca09234185ab48d315e78ff58a2ca2c",
            ),
            (
              false, "501ce5085d745b32027efd754192a9e973f4cd000bf3ea4703703a955b29a9d01d3f1f799e4b6bc01e9dac86bb2a1e808a8626a092d6a908f9e6e5e9ea29cf941bd2169a389173c1af410d39ae246aad38071",
              "8bbcc643d7435f16a29fc7374b0adef9e07d37357170f6dde4c97cc49691831d6770f502e957cbc2ae32e8d687d2ef5be6e81df5135ea5ac1314641f14f2e029699e2e50491a0c2d5a4698af3c7fac5165160",
            ),
            (
              false, "2342acf8594f9091f9f1cea23d2826dcd528720ac8f24b2649c248c3c730d3843aed8887c23a6664d4ba40937c2ffce18ede2395c062860b614dbd79b02e2fd278c1480c5912eee4bd80e90941c470a742134",
              "6d2b7ae5002ca249af0cd3a332a07e333761d321c0a040dd5abd697995a1ae6ef8d03f6a464c97301817c5e79a1ccaffcc6557677721f16e6ee7ee38485dbf205a83942eb91c59836e872748e743be9f96f93",
            ),
            (
              false, "19bd20e7ab0861ca6fbc8a98c09e998ac7877aaa8d7e01c18df55bef6607a68b4b889214172bfacd8b5b99803fa2718bb82a658bae3b718328ffb1eeea5ffb25449ba9eaa5afe1c7e8b152c24103172c2aa1",
              "8bbcc643d7435f16a29fc7374b0adef9e07d37357170f6dde4c97cc49691831d6770f502e957cbc2ae32e8d687d2ef5be6e81df5135ea5ac1314641f14f2e029699e2e50491a0c2d5a4698af3c7fac516516",
            ),
            (
              false, "2342acf8594f9091f9f1cea23d2826dcd528720ac8f24b2649c248c3c730d3843aed8887c23a6664d4ba40937c2ffce18ede2395c062860b614dbd79b02e2fd278c1480c5912eee4bd80e90941c470a742134",
              "6d2b7ae5002ca249af0cd3a332a07e333761d321c0a040dd5abd697995a1ae6ef8d03f6a464c97301817c5e79a1ccaffcc6557677721f16e6ee7ee38485dbf205a83942eb91c59836e872748e743be9f96f93",
            ),
            (
              false, "19bd20e7ab0861ca6fbc8a98c09e998ac7877aaa8d7e01c18df55bef6607a68b4b889214172bfacd8b5b99803fa2718bb82a658bae3b718328ffb1eeea5ffb25449ba9eaa5afe1c7e8b152c24103172c2aa1",
              "8bbcc643d7435f16a29fc7374b0adef9e07d37357170f6dde4c97cc49691831d6770f502e957cbc2ae32e8d687d2ef5be6e81df5135ea5ac1314641f14f2e029699e2e50491a0c2d5a4698af3c7fac516516",
            ),
            (
              false, "2fd7241cbe60c314ead3ed61b6206788119d1c6df3c1a0e045eb8d189503ed32ff3e3dd5440f7e317992b9f0e7b937d1c20b1dc5c4169746027aa07bbfb7a5890fda2b48de8c169a733699f95799bd8adadc0",
              "221d9667900df2b706b40222ffd22770014e91fa8c3214452c5b30f5fec28682adc113d135f7ef3f07876dd86028ff6fefdfab50553a9b7282a87a71969d4bba1c491e4e99d8dbf9128a3c46c8452b91df2ddf",
            ),
            (
              false, "74fbb427ea2b5a4586ede6d0a173f67eafb123e514302179b6a61f090e821d85e8946c27bda25a094cbb020ca0c4cd243e095388ae7cef6af134cc2e9c297c536755125133fae2247c75b4e812a83d62619e8",
              "6d2b7ae5002ca249af0cd3a332a07e333761d321c0a040dd5abd697995a1ae6ef8d03f6a464c97301817c5e79a1ccaffcc6557677721f16e6ee7ee38485dbf205a83942eb91c59836e872748e743be9f96f93",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              false, "29ddaacbe10fab2b227ccf4863e4ec5ad5e52789da158222959239b7030f3c5db3b4c749041d060d3cc82a7086c713369730658e0195c6a7585a3dc3a7419",
              "1aef707558731a17a50c305c83f5fefbd4ea0e9194bc559f4e893cc068e030c8c30e8e5ed313a2a0d72c9378912bf656759fb03d6503c448b317291aa3e973",
            ),
            (
              true, "29ddaacbe10fab2b227ccf4863e4ec5ad5e52789da158222959239b7030f3c5db3b4c749041d060d3cc82a7086c713369730658e0195c6a7585a3dc3a7419",
              "1aef707558731a17a50c305c83f5fefbd4ea0e9194bc559f4e893cc068e030c8c30e8e5ed313a2a0d72c9378912bf656759fb03d6503c448b317291aa3e973",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "8d65951e9298bea0a54537504dee3af7d5f22d704b2d796fbb935f0543ac2fb66600500c6e60c680546264527723744f6e40edb2da6acec35705f87c67f28",
              "86ad324aba3f8276393cf1ce93cdfaeb289248d7e7adac1c88ae2fc20c60f3ebcf48c7da1f622d2433dee15ad5dbcfb04c1e7132f912d56b7f73cd85338f3f",
            ),
            (
              false, "8d65951e9298bea0a54537504dee3af7d5f22d704b2d796fbb935f0543ac2fb66600500c6e60c680546264527723744f6e40edb2da6acec35705f87c67f28",
              "86ad324aba3f8276393cf1ce93cdfaeb289248d7e7adac1c88ae2fc20c60f3ebcf48c7da1f622d2433dee15ad5dbcfb04c1e7132f912d56b7f73cd85338f3f",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "268bad1385ccef2aba41ca646e529754aad317ae1fe80d191e416da8cf5242263d8a3367c1459099ef1276d3c42738f53e8655fdc90b1c91f38dadc5c2f87",
              "2b18b3eef3eb5cf2a1ad1a2d9feffe5fbb10174f546088fee40ec79a4166b4746b4a7d6484ec3767beadb8c0e84656f0bc32b3956e6c6d411e8b74f76ca8b8",
            ),
            (
              true, "268bad1385ccef2aba41ca646e529754aad317ae1fe80d191e416da8cf5242263d8a3367c1459099ef1276d3c42738f53e8655fdc90b1c91f38dadc5c2f87",
              "2b18b3eef3eb5cf2a1ad1a2d9feffe5fbb10174f546088fee40ec79a4166b4746b4a7d6484ec3767beadb8c0e84656f0bc32b3956e6c6d411e8b74f76ca8b8",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "3507eff334d059f94dadaec577e66ba727a64d81d241b56fda784165a16617b0704a85bed8e0d69e670fa0fc528f041044681055a054a9878a2c482cc472d",
              "1aef707558731a17a50c305c83f5fefbd4ea0e9194bc559f4e893cc068e030c8c30e8e5ed313a2a0d72c9378912bf656759fb03d6503c448b317291aa3e973",
            ),
            (
              false, "3507eff334d059f94dadaec577e66ba727a64d81d241b56fda784165a16617b0704a85bed8e0d69e670fa0fc528f041044681055a054a9878a2c482cc472d",
              "1aef707558731a17a50c305c83f5fefbd4ea0e9194bc559f4e893cc068e030c8c30e8e5ed313a2a0d72c9378912bf656759fb03d6503c448b317291aa3e973",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (
              false, "71c18f2a4c3ff29189d50cc857d5293ad7c82bf1c08d12f3bb647d739d2adc7111e16f0627a3df3a2cd",
              "22a74ed278fcbdf33ab9138abb609abb16b46941a25aa083982333b9fcde8b1cabec7751b95c18c419dc0",
            ),
            (
              true, "71c18f2a4c3ff29189d50cc857d5293ad7c82bf1c08d12f3bb647d739d2adc7111e16f0627a3df3a2cd",
              "22a74ed278fcbdf33ab9138abb609abb16b46941a25aa083982333b9fcde8b1cabec7751b95c18c419dc0",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "bb0b3e175f0908b8eb290dddbc74f85b171d81307975e761025e92c4f48f108a2fcc22b62e87f609491",
              "6c4ad651ba15d19817825d11898de388a6f3c8ed1b5b359b3b6e01a5363772b99942f4df633fcd64d0cf8",
            ),
            (
              false, "bb0b3e175f0908b8eb290dddbc74f85b171d81307975e761025e92c4f48f108a2fcc22b62e87f609491",
              "6c4ad651ba15d19817825d11898de388a6f3c8ed1b5b359b3b6e01a5363772b99942f4df633fcd64d0cf8",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "463f330408a7a58e83e72eb2c16fc737ae7db73418a8d037b751280efbee0670110e8894a3b4290f5b1",
              "36256b28dd0ae8cc0bc12e88c4c6f1c45379e4768dad9acd9db700d29b1bb95ccca17a6fb19fe6b26867c",
            ),
            (
              true, "463f330408a7a58e83e72eb2c16fc737ae7db73418a8d037b751280efbee0670110e8894a3b4290f5b1",
              "36256b28dd0ae8cc0bc12e88c4c6f1c45379e4768dad9acd9db700d29b1bb95ccca17a6fb19fe6b26867c",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "c5aa5db832a30929a25f1cc9b6dd8db999ca9bcbcfb14c07087cb5933ce27a62514e316c88eb64912",
              "35502a7ee184d57632f5592433f7156e99158e3d97505967fdc000cf5da524c9a609551b448daff29df",
            ),
            (
              false, "c5aa5db832a30929a25f1cc9b6dd8db999ca9bcbcfb14c07087cb5933ce27a62514e316c88eb64912",
              "35502a7ee184d57632f5592433f7156e99158e3d97505967fdc000cf5da524c9a609551b448daff29df",
            ),
            (false, "0", "1"),
          ],
          ricci: [
            (
              true, "268bad1385ccef2aba41ca646e529754aad317ae1fe80d191e416da8cf5242263d8a3367c1459099ef1276d3c42738f53e8655fdc90b1c91f38dadc5c2f87",
              "2b18b3eef3eb5cf2a1ad1a2d9feffe5fbb10174f546088fee40ec79a4166b4746b4a7d6484ec3767beadb8c0e84656f0bc32b3956e6c6d411e8b74f76ca8b8",
            ),
            (
              false, "29ddaacbe10fab2b227ccf4863e4ec5ad5e52789da158222959239b7030f3c5db3b4c749041d060d3cc82a7086c713369730658e0195c6a7585a3dc3a7419",
              "1aef707558731a17a50c305c83f5fefbd4ea0e9194bc559f4e893cc068e030c8c30e8e5ed313a2a0d72c9378912bf656759fb03d6503c448b317291aa3e973",
            ),
            (
              false, "3507eff334d059f94dadaec577e66ba727a64d81d241b56fda784165a16617b0704a85bed8e0d69e670fa0fc528f041044681055a054a9878a2c482cc472d",
              "1aef707558731a17a50c305c83f5fefbd4ea0e9194bc559f4e893cc068e030c8c30e8e5ed313a2a0d72c9378912bf656759fb03d6503c448b317291aa3e973",
            ),
            (
              true, "8d65951e9298bea0a54537504dee3af7d5f22d704b2d796fbb935f0543ac2fb66600500c6e60c680546264527723744f6e40edb2da6acec35705f87c67f28",
              "86ad324aba3f8276393cf1ce93cdfaeb289248d7e7adac1c88ae2fc20c60f3ebcf48c7da1f622d2433dee15ad5dbcfb04c1e7132f912d56b7f73cd85338f3f",
            ),
          ],
        },
        {
          alpha: (true, "3", "5"),
          scalar: (
            true, "1e3a13c566be26bc9e8c154614b82cf06ef6cd1c76c2a9e89c6db4f031116296efcf25697f424ca8b0ecce",
            "2ec9292e64dc2d704b87d2c9708c5779b4748089b96a8b4209a23cf185dedf77d9fc88c803bd450295db39",
          ),
          lower: [
            (
              true, "27b51d49080f98a4e80452fdb27170af4987fbb196f01fc3dbfac11431f3cb3b815d2e9e413d4d331",
              "599a3bad6182f3b9b32dde3fdcb89a595941272642bcca3edb5ce795aec6a2ee867b31e25876d93400",
            ),
            (
              true, "14b6078fde44695ea2e42a6b02b295a7c33d2a3ea4c6e08bb57a218761eb9d3b8ee93b6b0d4e4860d",
              "1c0032a62e78ec2a07fe5573f4f9b03bebe45c3bf4daff33a48d085ec69e12ea8a067f96bba523e040",
            ),
            (
              false, "401f56586dc07a6b62423a487042301d691a29e196eff0c4e862a030218e61fe7c5c467347885845",
              "955663764d2f96357ff71d151a89013f94c1ebea6f3aa668c2f02ca4234b0f8d8acd5323e8c614ac0",
            ),
            (
              false, "12dd4d095df2200d45da43ec84c8603de27cbc5c976aaa20b2d149f01aa4a4050d108b21b8b06179",
              "2eaaff14f81edef0b7fd3916984ad063de7c99b942c25400bceb0df34b0774dc3b6029fb38bde675c",
            ),
            (
              false, "401f56586dc07a6b62423a487042301d691a29e196eff0c4e862a030218e61fe7c5c467347885845",
              "955663764d2f96357ff71d151a89013f94c1ebea6f3aa668c2f02ca4234b0f8d8acd5323e8c614ac0",
            ),
            (
              false, "12dd4d095df2200d45da43ec84c8603de27cbc5c976aaa20b2d149f01aa4a4050d108b21b8b06179",
              "2eaaff14f81edef0b7fd3916984ad063de7c99b942c25400bceb0df34b0774dc3b6029fb38bde675c",
            ),
            (
              false, "357b5f6192cc557ddf36401479d0c3c15ddd9ab1a702f2b86507b441a33eecfe9366914a506cc95",
              "2eaaff14f81edef0b7fd3916984ad063de7c99b942c25400bceb0df34b0774dc3b6029fb38bde675c",
            ),
            (
              false, "3d855d6b0b99fa3de8bb3c931c8fa6682452e8a4a54f63e692e8f6f9245a5de88d330cacb13f69144",
              "4c908a7e6712a5c2eddb71a911dabde3d9046c33f186d1d135f1a2e327183bb95169c4e029178e192f",
            ),
          ],
          lower_first: [
            (
              false, "1a9d41870d7cabadc3780514d8ee9f3b42049be326726a7f3ade6606f9e8883bedd5b25432118dcadfb47d83172e3276dfcfc11ffd3d6c59808725d7",
              "9e7886b0f97031cdd7986c02d002c09eec9fa695f129f24904b1e308485f26bf9b68748ac8c3aae3965b8e01ab8bdddfe559021a5282a4752ee462000",
            ),
            (
              true, "6c5cebf55556ab817fb09852023b30f32dda6b7de400cbd7a4b78cbb9fb5192d5cb9c4b24a55f4786a0a9de27aafca9c3ed3f4b9167636741570df7",
              "580a11f08a93a9e422711f8fc8e515ad9fe6eac51433bf7de629efe82834dca3565679a26f89260ca8dd87c809f85ed1b84de4b94a4894411a0d1a00",
            ),
            (
              false, "e7afa5718f151757b2a0acce0f6109dddcfb069ee452c5e963dec8037b364865fe0b7a59e27a63d8e6357e5e96ffdfa862d620db37beb04c8bf38d5",
              "1081e35d19fbafdac67535eaf5aaf4108dfb4c04f3c9b3e79b27dcfb8789e95ea03036ce74e9b7225fa9897581de91c7528e9ae2bded9bcc34e274e00",
            ),
            (
              false, "8ee219bc64e3c20068beb16a017e8207ee39e931d4bf87628bab7bd19b984baeb044abba7c9f58df805e0b2699249782ff90f2198413c75bf45591",
              "1b83259b2b4e25174ac359dceec796c641f8295d96502bd757ed1af88c9084f30afb0602c2dadbe3f4c53a6e831d9da189985779e736ae5458241820",
            ),
            (
              false, "e7afa5718f151757b2a0acce0f6109dddcfb069ee452c5e963dec8037b364865fe0b7a59e27a63d8e6357e5e96ffdfa862d620db37beb04c8bf38d5",
              "1081e35d19fbafdac67535eaf5aaf4108dfb4c04f3c9b3e79b27dcfb8789e95ea03036ce74e9b7225fa9897581de91c7528e9ae2bded9bcc34e274e00",
            ),
            (
              false, "8ee219bc64e3c20068beb16a017e8207ee39e931d4bf87628bab7bd19b984baeb044abba7c9f58df805e0b2699249782ff90f2198413c75bf45591",
              "1b83259b2b4e25174ac359dceec796c641f8295d96502bd757ed1af88c9084f30afb0602c2dadbe3f4c53a6e831d9da189985779e736ae5458241820",
            ),
            (
              true, "549fa20310f66161a5137032de48071d7a37cf52e89c9c505fc2c10e6c4bea3ea3be0318ef3f28c2582a7afd9d97ee99b780eef127f56d95c39ea7",
              "528970d181ea6f45e04a0d96cc56c452c5e87c18c2f0838607c750e9a5b18ed920f11208489093abde4faf4b8958d8e49cc9066db5a40afd086c4860",
            ),
            (
              false, "ca7e52345d800b780fd1da176f4728342f89cf20a832f63f851fc8e371e7e32572194fca30d31d34bdb69cf24c3d723dd13f65acfeeaedcea0d37",
              "c816e2f423acb0a9658cbc183cf15fd06b69e705b98ce1c10b197e5572a6afa1c438e5e589206dbfae5491af5c7a4bdca2df9376918dae08527ade",
            ),
            (
              false, "3676375df2604b9f249a62672a6920095ac8b25d1396fb71d2ff319180c37830f2210a67c64ef72d3b5d40cb3572dc6a35f2d2ea36787cd09c9eb33",
              "34d2d790532565ef47dd795645564034f98a8cdca5b8a61856e5f658181fb79533cd7c2e42ebe3a1321e84ab392e9f4aa1c85608c62b8c270fa17600",
            ),
            (
              true, "2c4b434de89cc5c25447bf601794ebed185f2e9d6c31eb6687c5987a1eb218f5d902720d97511caab386c82ccfeeec0167c9431cdfb7edaf6ac5d5",
              "780dbb5f489ad065a35470db57c40649da0c5769d5baedda39dc1899ab30cfc775bbbd235246a83fceff8a9c6aafc71dfb52f213f0ee9b9e97e3520",
            ),
            (
              false, "10cfbcdda7116eae8716c84d743eb2904073accbde3d9c711de9b7163f1b37a2456d8266ccd8f2da0b39cf9f517d9ff9b043180e038b1687ed9bb11",
              "1b83259b2b4e25174ac359dceec796c641f8295d96502bd757ed1af88c9084f30afb0602c2dadbe3f4c53a6e831d9da189985779e736ae5458241820",
            ),
            (
              false, "6167e8496869b99d063c43f0031e8b2367b99b0207181e182d04f534dd81fa1a6a5e6f28f21aeb4a7ccad64a3c8137028627deec03e1556d0f29bf",
              "898fbc07d886b97475d0c150a9e5f1df49d8ced3ef90db34b7a186dabed298bf36e71e0dce464b73c7da24288f941427aff9b561841167a5b8b478a",
            ),
            (
              false, "10cfbcdda7116eae8716c84d743eb2904073accbde3d9c711de9b7163f1b37a2456d8266ccd8f2da0b39cf9f517d9ff9b043180e038b1687ed9bb11",
              "1b83259b2b4e25174ac359dceec796c641f8295d96502bd757ed1af88c9084f30afb0602c2dadbe3f4c53a6e831d9da189985779e736ae5458241820",
            ),
            (
              false, "6167e8496869b99d063c43f0031e8b2367b99b0207181e182d04f534dd81fa1a6a5e6f28f21aeb4a7ccad64a3c8137028627deec03e1556d0f29bf",
              "898fbc07d886b97475d0c150a9e5f1df49d8ced3ef90db34b7a186dabed298bf36e71e0dce464b73c7da24288f941427aff9b561841167a5b8b478a",
            ),
            (
              true, "521cd1c746d471b7d9014cdd566e4c9b89843b0760d2aae16faae49231cf5a7ea21c8978dad8fe410986577d3898913986376eb27cdf3bbf3542d",
              "19caf341789942c5d617243f1fdb1d59ddd8a6c7bceb2919e26e494903c77ca3da4b55a296ad2e25b578e6c79aebc3c770fed20248c3436f12a1d69e",
            ),
            (
              false, "3e47f7f4caa4de04e753eb68f7be9002c95466091bd8b899ae0d107d668167b5deabae11eb597aa95e8d9758d0db01afb98ab8d19d2cf84e013551d8",
              "1c35fa0f9be7a10862294fa50ad7a81a4aa4f66a76a134f44fa8a027dc22305336c265a9d4cd6a793e7c3c6a5171de222396b5b27f9591c17c6102bcd",
            ),
          ],
          coefficients: [
            (
              true, "2316ac24eb0d0cab98812d0c070baf328343c25a6de16678eb4b0ce999996617312c1c78a2400e7a4c7f",
              "8a9d3b49e3f2f7cceae44e2aed826aec5ad1a506896a820e608ccee7f37a2c72afb1dd46e57063106770",
            ),
            (
              true, "58c9b876b61ae0872d925e949322b57c43733a652f1e485b8b9dc96caf6f632ad09d84ed63953cfbb0d7",
              "ddc85edc9feb2614ab06e377e26a44ad5e1c3b3da8aa69b09a7ae4a6525d13eab2b62ed7d5809e80a580",
            ),
            (
              false, "996077b1a2c040cac4e9b40f4c54cc02d05474ff2fc991772946e0258d16db9f4d5268cd4b17bb6b249",
              "2b512287173bed700967586d6a38c169dc6183920af148a47e2c00a87c162de3d6e7952627b31ef52053",
            ),
            (
              false, "1028a716afa8e1f05cdd0d9cfcf5f0570c3f727415ce0bcd54566092d164e24bfcdc13c70ba0b87bd35d",
              "454e9da4f1f97be67572271576c135762d68d28344b5410730466773f9bd163957d8eea372b8318833b8",
            ),
            (
              false, "996077b1a2c040cac4e9b40f4c54cc02d05474ff2fc991772946e0258d16db9f4d5268cd4b17bb6b249",
              "2b512287173bed700967586d6a38c169dc6183920af148a47e2c00a87c162de3d6e7952627b31ef52053",
            ),
            (
              false, "1028a716afa8e1f05cdd0d9cfcf5f0570c3f727415ce0bcd54566092d164e24bfcdc13c70ba0b87bd35d",
              "454e9da4f1f97be67572271576c135762d68d28344b5410730466773f9bd163957d8eea372b8318833b8",
            ),
            (
              false, "1439fbf575a324506948f35e92211ba7e1e745a4a88e9f21d6214207a0b29541e92c243b2c140cc6d2d0",
              "d895aca3742ba3302f04ba23131bc7114de791da36b66b3676dc034a6c6ee5733285e9bec67f9ac9a19f",
            ),
            (
              false, "117a08be430c7f950522bdbbf4de9149c16507e18f82f933e2a8066c9555deb1e79d2501991e6666423e",
              "2b512287173bed700967586d6a38c169dc6183920af148a47e2c00a87c162de3d6e7952627b31ef52053",
            ),
          ],
          derivatives: [
            (
              true, "bb82fd9e820ee46e55c4b9649e095ba9746d61dfa7750ea8151756912ab2094a0e3814404d06bf421f271256c5cad94b83adb186b2e0fcf18c9d7925fdff409750bfaf13666db0ea69e2bac12673202938623",
              "45de6321eba1af8b514fe39ba5856f7cf03e9b9ab8b87b6ef264be624b48c18eb3b87a8174abe5e15719746b43e977adf3740efa89af52d6098a320f8a797014b4cf1728248d0616ad234c579e3fd628b28b00",
            ),
            (
              true, "1010715342e3fc460b916b06c93cc753cca627937746b6a994204e2a1b71c38f36c207aa59de5d7ce6a020530d07133614f8d6cf1e18cf89b83be02375d2f12ce08475ae71dbc83cb7da359463faab789f022d7",
              "22ef3190f5d0d7c5a8a7f1cdd2c2b7be781f4dcd5c5c3db779325f3125a460c759dc3d40ba55f2f0ab8cba35a1f4bbd6f9ba077d44d7a96b04c51907c53cb80a5a678b941246830b5691a62bcf1feb145945800",
            ),
            (
              false, "25884752983ac8d50a8dcb99c30a092f4c13142e17fe2c5d1a49acb8ae085df6ee192c08c2b6f2723538dd1bf2c8ceb9ad04ca6c8196dae79615e12aa39f5ca8a3f7ecdb2cdd30c78cca8551882fc2bad3dd9",
              "45de6321eba1af8b514fe39ba5856f7cf03e9b9ab8b87b6ef264be624b48c18eb3b87a8174abe5e15719746b43e977adf3740efa89af52d6098a320f8a797014b4cf1728248d0616ad234c579e3fd628b28b0",
            ),
            (
              false, "5c3a4a8426d7bf7a7f2de899b1c05533387e45b57cd6ba40ce1300bc1a8bb76200437f462cd75a9555fb3607e2db4d98fe7fa3dc98d4b05ecae682ecd1960709739d796976657d7a8ad7ea331d65694228db5",
              "22ef3190f5d0d7c5a8a7f1cdd2c2b7be781f4dcd5c5c3db779325f3125a460c759dc3d40ba55f2f0ab8cba35a1f4bbd6f9ba077d44d7a96b04c51907c53cb80a5a678b941246830b5691a62bcf1feb14594580",
            ),
            (
              false, "25884752983ac8d50a8dcb99c30a092f4c13142e17fe2c5d1a49acb8ae085df6ee192c08c2b6f2723538dd1bf2c8ceb9ad04ca6c8196dae79615e12aa39f5ca8a3f7ecdb2cdd30c78cca8551882fc2bad3dd9",
              "45de6321eba1af8b514fe39ba5856f7cf03e9b9ab8b87b6ef264be624b48c18eb3b87a8174abe5e15719746b43e977adf3740efa89af52d6098a320f8a797014b4cf1728248d0616ad234c579e3fd628b28b0",
            ),
            (
              false, "5c3a4a8426d7bf7a7f2de899b1c05533387e45b57cd6ba40ce1300bc1a8bb76200437f462cd75a9555fb3607e2db4d98fe7fa3dc98d4b05ecae682ecd1960709739d796976657d7a8ad7ea331d65694228db5",
              "22ef3190f5d0d7c5a8a7f1cdd2c2b7be781f4dcd5c5c3db779325f3125a460c759dc3d40ba55f2f0ab8cba35a1f4bbd6f9ba077d44d7a96b04c51907c53cb80a5a678b941246830b5691a62bcf1feb14594580",
            ),
            (
              false, "cab5fd0661cd6161393b11c65f0b7117b7a92b2f003014369c5048416c5fee63a5d7c3ce3a7c685ed11d6edb31e69fe15030e7fe6fd38ca981dc256e47a98d94375c6c2aca3e48740681d825ec32d123942d",
              "6d2b7ae5002ca249af0cd3a332a07e333761d321c0a040dd5abd697995a1ae6ef8d03f6a464c97301817c5e79a1ccaffcc6557677721f16e6ee7ee38485dbf205a83942eb91c59836e872748e743be9f96f93",
            ),
            (
              false, "b3eb17e62386fb07a3c7f6d004cfaba8fd0c086af2cb80e6942628d28ceb4e52b8323d0426badd11a793c9f9dce70fae1a96601568c0f73e8a8646d40164255229a5d3faab7fc9a05bfc02a5a3d0130b01f1",
              "22ef3190f5d0d7c5a8a7f1cdd2c2b7be781f4dcd5c5c3db779325f3125a460c759dc3d40ba55f2f0ab8cba35a1f4bbd6f9ba077d44d7a96b04c51907c53cb80a5a678b941246830b5691a62bcf1feb1459458",
            ),
            (
              false, "3186042c4e329e344187980363bfe79f8130c59792a38775b577163297da821efc6f85f4beb1f00d471a59b2efc7802f507d88a8a77d0a603412fd54b3c9f969960b115a64a8be04cef6f5f55a51f6bbc00d1",
              "45de6321eba1af8b514fe39ba5856f7cf03e9b9ab8b87b6ef264be624b48c18eb3b87a8174abe5e15719746b43e977adf3740efa89af52d6098a320f8a797014b4cf1728248d0616ad234c579e3fd628b28b0",
            ),
            (
              false, "af465530cf8af45e66cb0d8735fb9b81801732516f948ee85ca8d256fe7099c51073ba90cc4bc0590e3ec449a007d4f9921e5facfd9389985ae14d29e0e0d5bcdbce88854a4e5f516aa35ca7f2cd7b71ac471",
              "22ef3190f5d0d7c5a8a7f1cdd2c2b7be781f4dcd5c5c3db779325f3125a460c759dc3d40ba55f2f0ab8cba35a1f4bbd6f9ba077d44d7a96b04c51907c53cb80a5a678b941246830b5691a62bcf1feb14594580",
            ),
            (
              false, "e1839780b2596f73e58f8ad4f0c59c63c9bc72a84172666701043727ace220a7dcca2b4a35aabd9981f92f9d3e2a90f9c8a2dd06681583475251ffa588c014c191ced988a5f2d9357089067d000121f0b30d",
              "6d2b7ae5002ca249af0cd3a332a07e333761d321c0a040dd5abd697995a1ae6ef8d03f6a464c97301817c5e79a1ccaffcc6557677721f16e6ee7ee38485dbf205a83942eb91c59836e872748e743be9f96f93",
            ),
            (
              false, "4582183b00b222ae32c0f4348574cc97ef82cb2cceffba3cc9c423979597fc2a7327cb66e4679a7ae1b8f166bf61ff6cca833dc5e095ef8b8288667e8b7d9c9c49e52fb49bd5e7e8a7d9b59f76556d9872d5",
              "22ef3190f5d0d7c5a8a7f1cdd2c2b7be781f4dcd5c5c3db779325f3125a460c759dc3d40ba55f2f0ab8cba35a1f4bbd6f9ba077d44d7a96b04c51907c53cb80a5a678b941246830b5691a62bcf1feb1459458",
            ),
            (
              false, "e1839780b2596f73e58f8ad4f0c59c63c9bc72a84172666701043727ace220a7dcca2b4a35aabd9981f92f9d3e2a90f9c8a2dd06681583475251ffa588c014c191ced988a5f2d9357089067d000121f0b30d",
              "6d2b7ae5002ca249af0cd3a332a07e333761d321c0a040dd5abd697995a1ae6ef8d03f6a464c97301817c5e79a1ccaffcc6557677721f16e6ee7ee38485dbf205a83942eb91c59836e872748e743be9f96f93",
            ),
            (
              false, "4582183b00b222ae32c0f4348574cc97ef82cb2cceffba3cc9c423979597fc2a7327cb66e4679a7ae1b8f166bf61ff6cca833dc5e095ef8b8288667e8b7d9c9c49e52fb49bd5e7e8a7d9b59f76556d9872d5",
              "22ef3190f5d0d7c5a8a7f1cdd2c2b7be781f4dcd5c5c3db779325f3125a460c759dc3d40ba55f2f0ab8cba35a1f4bbd6f9ba077d44d7a96b04c51907c53cb80a5a678b941246830b5691a62bcf1feb1459458",
            ),
            (
              true, "1975ebf2dc6484f461f6712a911b292dc889779cb0a7e8797f15465927eb7fd52aae1f706701fa5b8758734b71f9edba67bbfabbf80fd8746743b446cbf9f16cd00ebbc93208808d95f6a2731cd80cb569cb0",
              "221d9667900df2b706b40222ffd22770014e91fa8c3214452c5b30f5fec28682adc113d135f7ef3f07876dd86028ff6fefdfab50553a9b7282a87a71969d4bba1c491e4e99d8dbf9128a3c46c8452b91df2ddf",
            ),
            (
              false, "5097ba7dab5d84a0b3fbc8c5174ab5870e44307b56bff4be819c4a0603ea2f6a92e03a78159cd7376bf6665d6df42fa2b13e95c2f399d3017b0f653d16dc8d08d2943ef5aee9ae1be0b9e4b482ce03a425842",
              "6d2b7ae5002ca249af0cd3a332a07e333761d321c0a040dd5abd697995a1ae6ef8d03f6a464c97301817c5e79a1ccaffcc6557677721f16e6ee7ee38485dbf205a83942eb91c59836e872748e743be9f96f93",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              true, "30f8b5a13f1b6b4cab1a9a45fd8640c53b6d56a182b350c410f6931be2b680b58e612ab579f00db154b9ba27b9c5c0aaeb7ac57f375dd752a3b6d9e7b2f9a9",
              "25093aa1599e43e082f0c27f35723e9a44c1d4082c82f5bb0bfcb388903443140c3403c2623aff9d27dd4ac5c79c72b6e1bb92546ae52de3f63fd884a160fe2",
            ),
            (
              false, "30f8b5a13f1b6b4cab1a9a45fd8640c53b6d56a182b350c410f6931be2b680b58e612ab579f00db154b9ba27b9c5c0aaeb7ac57f375dd752a3b6d9e7b2f9a9",
              "25093aa1599e43e082f0c27f35723e9a44c1d4082c82f5bb0bfcb388903443140c3403c2623aff9d27dd4ac5c79c72b6e1bb92546ae52de3f63fd884a160fe2",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "1ae5b1b3b5a9d0a097bfc00192d511f14ae42b72c4dcc64f73271d17f04dde49ae97a5bdbb108951f2162c66e33e9bd64552736d573769be04bf98f425be28",
              "5c971293600ba9b14759e63e059d9c81abe492146f4766539df7c0d56882a7b21e820965f5937f08e3a93aee73071ec93454edd30b3cf2b9e79f9d4b93727b5",
            ),
            (
              false, "1ae5b1b3b5a9d0a097bfc00192d511f14ae42b72c4dcc64f73271d17f04dde49ae97a5bdbb108951f2162c66e33e9bd64552736d573769be04bf98f425be28",
              "5c971293600ba9b14759e63e059d9c81abe492146f4766539df7c0d56882a7b21e820965f5937f08e3a93aee73071ec93454edd30b3cf2b9e79f9d4b93727b5",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "47896243ffc78a22bcc432d48d1e4436f4b6f4b1ee36dcec11ed6d747d72b54c0ce31c27d2883d8d90a1b748b7c7add00ac33d46c47d2a4bf5931108cebfcd",
              "7683eed11ec73f9b3c9c07fd77d3fb87426c401a280978bcf328a4e833da7040270cd8d46d89985d4c5dbc127ec16f16058b6ddaefaa2c7313ff81a86acffa0",
            ),
            (
              true, "47896243ffc78a22bcc432d48d1e4436f4b6f4b1ee36dcec11ed6d747d72b54c0ce31c27d2883d8d90a1b748b7c7add00ac33d46c47d2a4bf5931108cebfcd",
              "7683eed11ec73f9b3c9c07fd77d3fb87426c401a280978bcf328a4e833da7040270cd8d46d89985d4c5dbc127ec16f16058b6ddaefaa2c7313ff81a86acffa0",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "4052d4b752445ba8267dcd91f9084fce2bd6ead677f0174e4fb2ddabfc6dee4751af10977e7d4c78eedbfd27f1f8abd639a75051b1a44f46e837a8383b1d61",
              "25093aa1599e43e082f0c27f35723e9a44c1d4082c82f5bb0bfcb388903443140c3403c2623aff9d27dd4ac5c79c72b6e1bb92546ae52de3f63fd884a160fe2",
            ),
            (
              true, "4052d4b752445ba8267dcd91f9084fce2bd6ead677f0174e4fb2ddabfc6dee4751af10977e7d4c78eedbfd27f1f8abd639a75051b1a44f46e837a8383b1d61",
              "25093aa1599e43e082f0c27f35723e9a44c1d4082c82f5bb0bfcb388903443140c3403c2623aff9d27dd4ac5c79c72b6e1bb92546ae52de3f63fd884a160fe2",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (
              true, "71c18f2a4c3ff29189d50cc857d5293ad7c82bf1c08d12f3bb647d739d2adc7111e16f0627a3df3a2cd",
              "22a74ed278fcbdf33ab9138abb609abb16b46941a25aa083982333b9fcde8b1cabec7751b95c18c419dc0",
            ),
            (
              false, "71c18f2a4c3ff29189d50cc857d5293ad7c82bf1c08d12f3bb647d739d2adc7111e16f0627a3df3a2cd",
              "22a74ed278fcbdf33ab9138abb609abb16b46941a25aa083982333b9fcde8b1cabec7751b95c18c419dc0",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "463f330408a7a58e83e72eb2c16fc737ae7db73418a8d037b751280efbee0670110e8894a3b4290f5b1",
              "36256b28dd0ae8cc0bc12e88c4c6f1c45379e4768dad9acd9db700d29b1bb95ccca17a6fb19fe6b26867c",
            ),
            (
              false, "463f330408a7a58e83e72eb2c16fc737ae7db73418a8d037b751280efbee0670110e8894a3b4290f5b1",
              "36256b28dd0ae8cc0bc12e88c4c6f1c45379e4768dad9acd9db700d29b1bb95ccca17a6fb19fe6b26867c",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "bb0b3e175f0908b8eb290dddbc74f85b171d81307975e761025e92c4f48f108a2fcc22b62e87f609491",
              "6c4ad651ba15d19817825d11898de388a6f3c8ed1b5b359b3b6e01a5363772b99942f4df633fcd64d0cf8",
            ),
            (
              true, "bb0b3e175f0908b8eb290dddbc74f85b171d81307975e761025e92c4f48f108a2fcc22b62e87f609491",
              "6c4ad651ba15d19817825d11898de388a6f3c8ed1b5b359b3b6e01a5363772b99942f4df633fcd64d0cf8",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "c5aa5db832a30929a25f1cc9b6dd8db999ca9bcbcfb14c07087cb5933ce27a62514e316c88eb64912",
              "35502a7ee184d57632f5592433f7156e99158e3d97505967fdc000cf5da524c9a609551b448daff29df",
            ),
            (
              true, "c5aa5db832a30929a25f1cc9b6dd8db999ca9bcbcfb14c07087cb5933ce27a62514e316c88eb64912",
              "35502a7ee184d57632f5592433f7156e99158e3d97505967fdc000cf5da524c9a609551b448daff29df",
            ),
            (false, "0", "1"),
          ],
          ricci: [
            (
              true, "47896243ffc78a22bcc432d48d1e4436f4b6f4b1ee36dcec11ed6d747d72b54c0ce31c27d2883d8d90a1b748b7c7add00ac33d46c47d2a4bf5931108cebfcd",
              "7683eed11ec73f9b3c9c07fd77d3fb87426c401a280978bcf328a4e833da7040270cd8d46d89985d4c5dbc127ec16f16058b6ddaefaa2c7313ff81a86acffa0",
            ),
            (
              true, "30f8b5a13f1b6b4cab1a9a45fd8640c53b6d56a182b350c410f6931be2b680b58e612ab579f00db154b9ba27b9c5c0aaeb7ac57f375dd752a3b6d9e7b2f9a9",
              "25093aa1599e43e082f0c27f35723e9a44c1d4082c82f5bb0bfcb388903443140c3403c2623aff9d27dd4ac5c79c72b6e1bb92546ae52de3f63fd884a160fe2",
            ),
            (
              true, "4052d4b752445ba8267dcd91f9084fce2bd6ead677f0174e4fb2ddabfc6dee4751af10977e7d4c78eedbfd27f1f8abd639a75051b1a44f46e837a8383b1d61",
              "25093aa1599e43e082f0c27f35723e9a44c1d4082c82f5bb0bfcb388903443140c3403c2623aff9d27dd4ac5c79c72b6e1bb92546ae52de3f63fd884a160fe2",
            ),
            (
              true, "1ae5b1b3b5a9d0a097bfc00192d511f14ae42b72c4dcc64f73271d17f04dde49ae97a5bdbb108951f2162c66e33e9bd64552736d573769be04bf98f425be28",
              "5c971293600ba9b14759e63e059d9c81abe492146f4766539df7c0d56882a7b21e820965f5937f08e3a93aee73071ec93454edd30b3cf2b9e79f9d4b93727b5",
            ),
          ],
        },
      ],
    },
    {
      name: "five_outcome_1",
      point: [(true, "1", "3"), (false, "1", "6")],
      polynomials: [
        [
          { coefficient: (false, "1", "21"), exponents: [2, 2], },
          { coefficient: (false, "1", "19"), exponents: [2, 1], },
          { coefficient: (false, "1", "9"), exponents: [1, 0], },
          { coefficient: (true, "1", "11"), exponents: [0, 1], },
          { coefficient: (false, "1", "5"), exponents: [0, 0], },
        ],
        [
          { coefficient: (false, "1", "1d"), exponents: [1, 2], },
          { coefficient: (true, "1", "d"), exponents: [1, 0], },
          { coefficient: (false, "1", "2d"), exponents: [0, 3], },
          { coefficient: (false, "1", "b"), exponents: [0, 1], },
          { coefficient: (false, "1", "6"), exponents: [0, 0], },
        ],
        [
          { coefficient: (true, "1", "1f"), exponents: [2, 0], },
          { coefficient: (false, "1", "25"), exponents: [1, 1], },
          { coefficient: (false, "1", "f"), exponents: [1, 0], },
          { coefficient: (false, "1", "13"), exponents: [0, 1], },
          { coefficient: (false, "1", "7"), exponents: [0, 0], },
        ],
        [
          { coefficient: (false, "1", "29"), exponents: [3, 0], },
          { coefficient: (true, "1", "17"), exponents: [1, 0], },
          { coefficient: (true, "1", "2b"), exponents: [0, 2], },
          { coefficient: (true, "1", "15"), exponents: [0, 1], },
          { coefficient: (false, "1", "8"), exponents: [0, 0], },
        ],
        [
          { coefficient: (true, "1", "29"), exponents: [3, 0], },
          { coefficient: (true, "1", "21"), exponents: [2, 2], },
          { coefficient: (true, "1", "19"), exponents: [2, 1], },
          { coefficient: (false, "1", "1f"), exponents: [2, 0], },
          { coefficient: (true, "1", "1d"), exponents: [1, 2], },
          { coefficient: (true, "1", "25"), exponents: [1, 1], },
          { coefficient: (true, "304", "348f"), exponents: [1, 0], },
          { coefficient: (true, "1", "2d"), exponents: [0, 3], },
          { coefficient: (false, "1", "2b"), exponents: [0, 2], },
          { coefficient: (true, "ad0", "12375"), exponents: [0, 1], },
          { coefficient: (false, "133", "348"), exponents: [0, 0], },
        ],
      ],
      jets: [
        {
          p: (false, "aad71", "455664"),
          gradient: [(false, "1277", "ae06"), (true, "4ec7", "5c733")],
          hessian: [
            (false, "df", "3a02"),
            (true, "f8", "1d01"),
            (true, "f8", "1d01"),
            (false, "2", "129"),
          ],
          third: [
            (false, "0", "1"),
            (false, "f8", "9ab"),
            (false, "f8", "9ab"),
            (true, "4", "63"),
            (false, "f8", "9ab"),
            (true, "4", "63"),
            (true, "4", "63"),
            (false, "0", "1"),
          ],
        },
        {
          p: (false, "7f77b5", "2671068"),
          gradient: [(true, "407", "3504"), (false, "3bd7", "2a0e4")],
          hessian: [
            (false, "0", "1"),
            (false, "1", "57"),
            (false, "1", "57"),
            (true, "1", "519"),
          ],
          third: [
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "2", "1d"),
            (false, "0", "1"),
            (false, "2", "1d"),
            (false, "2", "1d"),
            (false, "2", "f"),
          ],
        },
        {
          p: (false, "d05bf", "68bf9b"),
          gradient: [(false, "427", "2cce"), (false, "5c", "83d")],
          hessian: [
            (true, "2", "1f"),
            (false, "1", "25"),
            (false, "1", "25"),
            (false, "0", "1"),
          ],
          third: [
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
          ],
        },
        {
          p: (false, "799faf", "3a78488"),
          gradient: [(true, "64", "b0d"), (true, "32", "387")],
          hessian: [
            (true, "2", "29"),
            (false, "0", "1"),
            (false, "0", "1"),
            (true, "2", "2b"),
          ],
          third: [
            (false, "6", "29"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
          ],
        },
        {
          p: (false, "12d871b245a13a83", "310569923cf5d6c4"),
          gradient: [
            (true, "2e3ec5d3683", "210b4c2f4b1c"),
            (true, "33c69b695f", "8742568e114"),
          ],
          hessian: [
            (false, "1c4df7", "11fffee"),
            (true, "9f5c", "799131"),
            (true, "9f5c", "799131"),
            (false, "12547", "1c4193"),
          ],
          third: [
            (true, "6", "29"),
            (true, "f8", "9ab"),
            (true, "f8", "9ab"),
            (true, "52", "b37"),
            (true, "f8", "9ab"),
            (true, "52", "b37"),
            (true, "52", "b37"),
            (true, "2", "f"),
          ],
        },
      ],
      metric: [
        (
          false, "35d1073e5122bda8c48346250429e76a74665bb", "10daf324b2c13a485a2c76f85a120a1b60d622ca",
        ),
        (
          true, "1c1738312f708b5c66a16129a710998d0ed7ad", "6bdfadb7ab3b0e9bdab62c9bda0d0d7c055a784",
        ),
        (
          true, "1c1738312f708b5c66a16129a710998d0ed7ad", "6bdfadb7ab3b0e9bdab62c9bda0d0d7c055a784",
        ),
        (
          false, "16e119ea720446035cf6a69cb35f48ba66c8a5df", "ebf94c01c6912ff4ee6e8194ecfc8d7f4bb5e70c",
        ),
      ],
      first: [
        (
          true, "5d1a81ba7264c0ffa3b284bfa1d3c0e9ad330849323b910ecee834db7d4764f95a6b3481281",
          "20a69ac28bc8b81a0233b8a0f057a56ec72fb8882f330a9d225bdf1864361108e5e70a3fd5f8",
        ),
        (
          true, "670ff100410f934382943eaf5a5c40a560dbf2f93319da172cec43e7b8156bbe0a843bb6db",
          "10534d6145e45c0d0119dc50782bd2b76397dc441799854e912def8c321b088472f3851feafc",
        ),
        (
          true, "670ff100410f934382943eaf5a5c40a560dbf2f93319da172cec43e7b8156bbe0a843bb6db",
          "10534d6145e45c0d0119dc50782bd2b76397dc441799854e912def8c321b088472f3851feafc",
        ),
        (
          false, "cda868852335f9e6e014fead9d7b5d20f506a44b212c12e37b57110d7664d7ba5c1ec36baf",
          "10534d6145e45c0d0119dc50782bd2b76397dc441799854e912def8c321b088472f3851feafc",
        ),
        (
          true, "48bbd012e1aebc22f748a314c0be4c8fa8288fbb5fb6f32d2f19cc91f64f1cc85428af651f",
          "10534d6145e45c0d0119dc50782bd2b76397dc441799854e912def8c321b088472f3851feafc",
        ),
        (
          false, "82aae2dff4ae55f98d070fb55fbe62ceedcaaa944524f0032de6596f4658163cc99685557b",
          "10534d6145e45c0d0119dc50782bd2b76397dc441799854e912def8c321b088472f3851feafc",
        ),
        (
          false, "82aae2dff4ae55f98d070fb55fbe62ceedcaaa944524f0032de6596f4658163cc99685557b",
          "10534d6145e45c0d0119dc50782bd2b76397dc441799854e912def8c321b088472f3851feafc",
        ),
        (
          false, "2bea98da1f85094d651fe309990987a0eabea0c87d0ad236eb038b0f7c2dbd9bb5bbce85807",
          "72471da8e93e845b07b506334932c303b92705dca532a525f8418cd55ebd3b9f24a8a3df6ce4",
        ),
      ],
      second: [
        (
          false, "161e5a29f57a521ef223f52f3b879271ad9e3ef7449629ffd1fc50c3802bcf28a22ed6611e63e463761b1890c8b1cc589233bfcbcd36279",
          "3299574a012c043ac1540648081ca2cda1e10ecc7c389358fdb070b4a1d388baf50e26f9bbbecf06bd813e7657b4840fb44371e4050ce48",
        ),
        (
          false, "46db01e223cd0c56ff98eebf8fa0aaa4498b50397a0a485068a1566be38fe07b251988f6eecce0088605fe14ad9dcbde34087c2f1b2641",
          "3f3fad1c8177054971a907da0a23cb810a59527f9b46b82f3d1c8ce1ca486ae9b251b0b82aae82c86ce18e13eda1a513a1544e5d06501da",
        ),
        (
          false, "46db01e223cd0c56ff98eebf8fa0aaa4498b50397a0a485068a1566be38fe07b251988f6eecce0088605fe14ad9dcbde34087c2f1b2641",
          "3f3fad1c8177054971a907da0a23cb810a59527f9b46b82f3d1c8ce1ca486ae9b251b0b82aae82c86ce18e13eda1a513a1544e5d06501da",
        ),
        (
          true, "1e627f4612f5e80940aacc4d2fcd696f0f1067c31c9e019344b9b0065d8f2d6a738ca93058db51f57e182df2754be92fef5740039abb1",
          "6532ae940258087582a80c901039459b43c21d98f87126b1fb60e16943a71175ea1c4df3777d9e0d7b027cecaf69081f6886e3c80a19c9",
        ),
        (
          false, "18066a69da0ced11c804c4f94ef19ef9138d4c288cfe09b442bcc09f4bfd762bc224e8e936b2c7a91aeae6eda259d377b3288da64bb97df",
          "7e7f5a3902ee0a92e3520fb41447970214b2a4ff368d705e7a3919c39490d5d364a36170555d0590d9c31c27db434a2742a89cba0ca03b4",
        ),
        (
          true, "11b1485e687b34d32be7fa1a045308aa8ca8094751503e386e81bc091b6fffdbad86bdeea5f096569aed473de2d99804c43e3b3c60b99",
          "6532ae940258087582a80c901039459b43c21d98f87126b1fb60e16943a71175ea1c4df3777d9e0d7b027cecaf69081f6886e3c80a19c9",
        ),
        (
          true, "11b1485e687b34d32be7fa1a045308aa8ca8094751503e386e81bc091b6fffdbad86bdeea5f096569aed473de2d99804c43e3b3c60b99",
          "6532ae940258087582a80c901039459b43c21d98f87126b1fb60e16943a71175ea1c4df3777d9e0d7b027cecaf69081f6886e3c80a19c9",
        ),
        (
          false, "58af9213c55b9cc3d0500d3b37004a4c45de0b2ff5e76f1ccb450eceefe2d9d382028f1d65380eedbc3e72e8e0844d6c0b0703b49f2e75",
          "3f3fad1c8177054971a907da0a23cb810a59527f9b46b82f3d1c8ce1ca486ae9b251b0b82aae82c86ce18e13eda1a513a1544e5d06501da",
        ),
        (
          false, "18066a69da0ced11c804c4f94ef19ef9138d4c288cfe09b442bcc09f4bfd762bc224e8e936b2c7a91aeae6eda259d377b3288da64bb97df",
          "7e7f5a3902ee0a92e3520fb41447970214b2a4ff368d705e7a3919c39490d5d364a36170555d0590d9c31c27db434a2742a89cba0ca03b4",
        ),
        (
          true, "11b1485e687b34d32be7fa1a045308aa8ca8094751503e386e81bc091b6fffdbad86bdeea5f096569aed473de2d99804c43e3b3c60b99",
          "6532ae940258087582a80c901039459b43c21d98f87126b1fb60e16943a71175ea1c4df3777d9e0d7b027cecaf69081f6886e3c80a19c9",
        ),
        (
          true, "11b1485e687b34d32be7fa1a045308aa8ca8094751503e386e81bc091b6fffdbad86bdeea5f096569aed473de2d99804c43e3b3c60b99",
          "6532ae940258087582a80c901039459b43c21d98f87126b1fb60e16943a71175ea1c4df3777d9e0d7b027cecaf69081f6886e3c80a19c9",
        ),
        (
          false, "58af9213c55b9cc3d0500d3b37004a4c45de0b2ff5e76f1ccb450eceefe2d9d382028f1d65380eedbc3e72e8e0844d6c0b0703b49f2e75",
          "3f3fad1c8177054971a907da0a23cb810a59527f9b46b82f3d1c8ce1ca486ae9b251b0b82aae82c86ce18e13eda1a513a1544e5d06501da",
        ),
        (
          true, "4865ca9fad7ea1f3f632eb264afcbab51ff1ae511b8d94b703f29904108bbec6758e74e3625e2e124c3298100b9cf202521a089491c18f",
          "3f3fad1c8177054971a907da0a23cb810a59527f9b46b82f3d1c8ce1ca486ae9b251b0b82aae82c86ce18e13eda1a513a1544e5d06501da",
        ),
        (
          false, "65f18fdcc0dea156bd0093cce001529735728bf7fada75954ab18779bba794f5b03ae018fbd537bfdded939d4188eee6134d8ac827bcb",
          "ca655d2804b010eb0550192020728b3687843b31f0e24d63f6c1c2d2874e22ebd4389be6eefb3c1af604f9d95ed2103ed10dc790143392",
        ),
        (
          false, "65f18fdcc0dea156bd0093cce001529735728bf7fada75954ab18779bba794f5b03ae018fbd537bfdded939d4188eee6134d8ac827bcb",
          "ca655d2804b010eb0550192020728b3687843b31f0e24d63f6c1c2d2874e22ebd4389be6eefb3c1af604f9d95ed2103ed10dc790143392",
        ),
        (
          false, "f53a5cd08fc5dfd255d9aea61fae76d107e063f1720611951542e27a23ec886c9d44ff6b94f2eb50bcac182e5e4c8250bf3e2d69b770a5",
          "3f3fad1c8177054971a907da0a23cb810a59527f9b46b82f3d1c8ce1ca486ae9b251b0b82aae82c86ce18e13eda1a513a1544e5d06501da",
        ),
      ],
      cubic: [
        (
          false, "2c2893551c1fc667b64788abb0238a585a47e8dd9c63f92bb01388b1f76f02b92057bd1dcb9",
          "20a69ac28bc8b81a0233b8a0f057a56ec72fb8882f330a9d225bdf1864361108e5e70a3fd5f8",
        ),
        (
          false, "174bdfdd1d5c98cbe0522ec69758bb7dc5fe6a6f1d0da750161814f847426c3917cb63d70b",
          "10534d6145e45c0d0119dc50782bd2b76397dc441799854e912def8c321b088472f3851feafc",
        ),
        (
          false, "174bdfdd1d5c98cbe0522ec69758bb7dc5fe6a6f1d0da750161814f847426c3917cb63d70b",
          "10534d6145e45c0d0119dc50782bd2b76397dc441799854e912def8c321b088472f3851feafc",
        ),
        (
          false, "e0d8bc1c2b6c644d5c338bc30962cac0a802f0b5a3ab3bae86d3f2c13c1e7beb2fba67801",
          "10534d6145e45c0d0119dc50782bd2b76397dc441799854e912def8c321b088472f3851feafc",
        ),
        (
          false, "174bdfdd1d5c98cbe0522ec69758bb7dc5fe6a6f1d0da750161814f847426c3917cb63d70b",
          "10534d6145e45c0d0119dc50782bd2b76397dc441799854e912def8c321b088472f3851feafc",
        ),
        (
          false, "e0d8bc1c2b6c644d5c338bc30962cac0a802f0b5a3ab3bae86d3f2c13c1e7beb2fba67801",
          "10534d6145e45c0d0119dc50782bd2b76397dc441799854e912def8c321b088472f3851feafc",
        ),
        (
          false, "e0d8bc1c2b6c644d5c338bc30962cac0a802f0b5a3ab3bae86d3f2c13c1e7beb2fba67801",
          "10534d6145e45c0d0119dc50782bd2b76397dc441799854e912def8c321b088472f3851feafc",
        ),
        (
          false, "99463c5599bfff7b373b88aeeb87f8461c4858ca843d63133f391a22b6ccafed90092d42a1",
          "72471da8e93e845b07b506334932c303b92705dca532a525f8418cd55ebd3b9f24a8a3df6ce4",
        ),
      ],
      natural_gradient: [
        (
          false, "31ff4d028141754ed89981ff72fa9475380794f46", "10e304bec299936bca2caf9af151a7491d2f298a9",
        ),
        (
          true, "4eb1002d6d660786cd53365efe3a932ef06536cb4", "10e304bec299936bca2caf9af151a7491d2f298a9",
        ),
      ],
      scores: [
        (false, "75b6a", "aad71"),
        (true, "3b154", "aad71"),
        (true, "2eb936", "7f77b5"),
        (false, "36b286", "7f77b5"),
        (false, "136a5b", "1a0b7e"),
        (false, "491c4", "d05bf"),
        (true, "69d20", "185323"),
        (true, "a5c30", "185323"),
        (true, "449ae1abc2950d5", "12d871b245a13a83"),
        (true, "12c3c94e0b52763", "12d871b245a13a83"),
      ],
      cubic_pullback: (
        false, "1a20eb896774bcad56c0b3499ab9a627c9598102da833e0f954284745961faa0092fc4c9192fd",
        "c0d8020d09997f599d017a768b85a9164871d9e456c576b012ee9da80fdf549c8ddc948907c0c0",
      ),
      alphas: [
        {
          alpha: (false, "0", "1"),
          scalar: (
            false, "9abdff3879e3149ec100746ed2170a39caf2a2123afab7c044f7d3ac00095cb941225c04ccbeb118",
            "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
          ),
          lower: [
            (
              true, "5d1a81ba7264c0ffa3b284bfa1d3c0e9ad330849323b910ecee834db7d4764f95a6b3481281",
              "414d35851791703404677141e0af4add8e5f71105e66153a44b7be30c86c2211cbce147fabf0",
            ),
            (
              true, "856411eda0706a640ddfda49f3fa34bb198f5637067cc1012abebb3d79dbbab3c0dfc80897",
              "20a69ac28bc8b81a0233b8a0f057a56ec72fb8882f330a9d225bdf1864361108e5e70a3fd5f8",
            ),
            (
              true, "48bbd012e1aebc22f748a314c0be4c8fa8288fbb5fb6f32d2f19cc91f64f1cc85428af651f",
              "20a69ac28bc8b81a0233b8a0f057a56ec72fb8882f330a9d225bdf1864361108e5e70a3fd5f8",
            ),
            (
              false, "cda868852335f9e6e014fead9d7b5d20f506a44b212c12e37b57110d7664d7ba5c1ec36baf",
              "20a69ac28bc8b81a0233b8a0f057a56ec72fb8882f330a9d225bdf1864361108e5e70a3fd5f8",
            ),
            (
              true, "48bbd012e1aebc22f748a314c0be4c8fa8288fbb5fb6f32d2f19cc91f64f1cc85428af651f",
              "20a69ac28bc8b81a0233b8a0f057a56ec72fb8882f330a9d225bdf1864361108e5e70a3fd5f8",
            ),
            (
              false, "cda868852335f9e6e014fead9d7b5d20f506a44b212c12e37b57110d7664d7ba5c1ec36baf",
              "20a69ac28bc8b81a0233b8a0f057a56ec72fb8882f330a9d225bdf1864361108e5e70a3fd5f8",
            ),
            (
              false, "37ad5d3ac626b20c39f920bd2201687ce68eb0dd691dcd22e075a1d1164b54bf370e473f47",
              "20a69ac28bc8b81a0233b8a0f057a56ec72fb8882f330a9d225bdf1864361108e5e70a3fd5f8",
            ),
            (
              false, "2bea98da1f85094d651fe309990987a0eabea0c87d0ad236eb038b0f7c2dbd9bb5bbce85807",
              "e48e3b51d27d08b60f6a0c6692658607724e0bb94a654a4bf08319aabd7a773e495147bed9c8",
            ),
          ],
          lower_first: [
            (
              false, "161e5a29f57a521ef223f52f3b879271ad9e3ef7449629ffd1fc50c3802bcf28a22ed6611e63e463761b1890c8b1cc589233bfcbcd36279",
              "6532ae940258087582a80c901039459b43c21d98f87126b1fb60e16943a71175ea1c4df3777d9e0d7b027cecaf69081f6886e3c80a19c90",
            ),
            (
              true, "64fa9f15119a9fc081e89496b097450012a781a2e7b77a028946b0453197e0cf8de86ab7aff8fa6f969676876f2608026266e9a84efedb",
              "fcfeb47205dc1525c6a41f68288f2e04296549fe6d1ae0bcf47233872921aba6c946c2e0aaba0b21b386384fb686944e855139741940768",
            ),
            (
              false, "18066a69da0ced11c804c4f94ef19ef9138d4c288cfe09b442bcc09f4bfd762bc224e8e936b2c7a91aeae6eda259d377b3288da64bb97df",
              "fcfeb47205dc1525c6a41f68288f2e04296549fe6d1ae0bcf47233872921aba6c946c2e0aaba0b21b386384fb686944e855139741940768",
            ),
            (
              true, "1e627f4612f5e80940aacc4d2fcd696f0f1067c31c9e019344b9b0065d8f2d6a738ca93058db51f57e182df2754be92fef5740039abb1",
              "ca655d2804b010eb0550192020728b3687843b31f0e24d63f6c1c2d2874e22ebd4389be6eefb3c1af604f9d95ed2103ed10dc790143392",
            ),
            (
              false, "18066a69da0ced11c804c4f94ef19ef9138d4c288cfe09b442bcc09f4bfd762bc224e8e936b2c7a91aeae6eda259d377b3288da64bb97df",
              "fcfeb47205dc1525c6a41f68288f2e04296549fe6d1ae0bcf47233872921aba6c946c2e0aaba0b21b386384fb686944e855139741940768",
            ),
            (
              true, "1e627f4612f5e80940aacc4d2fcd696f0f1067c31c9e019344b9b0065d8f2d6a738ca93058db51f57e182df2754be92fef5740039abb1",
              "ca655d2804b010eb0550192020728b3687843b31f0e24d63f6c1c2d2874e22ebd4389be6eefb3c1af604f9d95ed2103ed10dc790143392",
            ),
            (
              true, "5001176be00819d172527e6d8d8a7e60a3faacb86027add9849c80bd950d24ce780d2acf305dab7b7c26089506746d99925367526b81",
              "ca655d2804b010eb0550192020728b3687843b31f0e24d63f6c1c2d2874e22ebd4389be6eefb3c1af604f9d95ed2103ed10dc790143392",
            ),
            (
              false, "58af9213c55b9cc3d0500d3b37004a4c45de0b2ff5e76f1ccb450eceefe2d9d382028f1d65380eedbc3e72e8e0844d6c0b0703b49f2e75",
              "7e7f5a3902ee0a92e3520fb41447970214b2a4ff368d705e7a3919c39490d5d364a36170555d0590d9c31c27db434a2742a89cba0ca03b4",
            ),
            (
              false, "18066a69da0ced11c804c4f94ef19ef9138d4c288cfe09b442bcc09f4bfd762bc224e8e936b2c7a91aeae6eda259d377b3288da64bb97df",
              "fcfeb47205dc1525c6a41f68288f2e04296549fe6d1ae0bcf47233872921aba6c946c2e0aaba0b21b386384fb686944e855139741940768",
            ),
            (
              false, "49232ec83e63d15744d2d51fab072e5d002e03f44e6a95badfbace80fd73fe79fb200adea730a608c982e749ba4162e36fb4b80d3b6b1",
              "b7ff0ede8fe5e0d5a7bd2e1d34c538bd3560effedafc465ae0530e33c0d2ab6206bf195d93700818829028f427a7b1ad783b1282fb179c",
            ),
            (
              true, "4865ca9fad7ea1f3f632eb264afcbab51ff1ae511b8d94b703f29904108bbec6758e74e3625e2e124c3298100b9cf202521a089491c18f",
              "7e7f5a3902ee0a92e3520fb41447970214b2a4ff368d705e7a3919c39490d5d364a36170555d0590d9c31c27db434a2742a89cba0ca03b4",
            ),
            (
              false, "58af9213c55b9cc3d0500d3b37004a4c45de0b2ff5e76f1ccb450eceefe2d9d382028f1d65380eedbc3e72e8e0844d6c0b0703b49f2e75",
              "7e7f5a3902ee0a92e3520fb41447970214b2a4ff368d705e7a3919c39490d5d364a36170555d0590d9c31c27db434a2742a89cba0ca03b4",
            ),
            (
              true, "4865ca9fad7ea1f3f632eb264afcbab51ff1ae511b8d94b703f29904108bbec6758e74e3625e2e124c3298100b9cf202521a089491c18f",
              "7e7f5a3902ee0a92e3520fb41447970214b2a4ff368d705e7a3919c39490d5d364a36170555d0590d9c31c27db434a2742a89cba0ca03b4",
            ),
            (
              false, "58af9213c55b9cc3d0500d3b37004a4c45de0b2ff5e76f1ccb450eceefe2d9d382028f1d65380eedbc3e72e8e0844d6c0b0703b49f2e75",
              "7e7f5a3902ee0a92e3520fb41447970214b2a4ff368d705e7a3919c39490d5d364a36170555d0590d9c31c27db434a2742a89cba0ca03b4",
            ),
            (
              true, "18f89829ccd077ed9a2fb0db2aff76adc47673b4f91ee59f7c961a22da9a1cb9f3ddc30dc7d2cc15d189f6a6978eb81c3ef68cf7865887",
              "7e7f5a3902ee0a92e3520fb41447970214b2a4ff368d705e7a3919c39490d5d364a36170555d0590d9c31c27db434a2742a89cba0ca03b4",
            ),
            (
              false, "f53a5cd08fc5dfd255d9aea61fae76d107e063f1720611951542e27a23ec886c9d44ff6b94f2eb50bcac182e5e4c8250bf3e2d69b770a5",
              "7e7f5a3902ee0a92e3520fb41447970214b2a4ff368d705e7a3919c39490d5d364a36170555d0590d9c31c27db434a2742a89cba0ca03b4",
            ),
          ],
          coefficients: [
            (
              true, "1f76be957087947b151763bc7dcf8df1b365943427f3fa78e0093bc434692a2e5654a43cefe3e3",
              "4377dbf0c9df3fb996b503b1f0861bc71bea36c78cd5d7450bc482180a8b4d2c3fb1bb8923ecac",
            ),
            (
              true, "1062e994f1c23dfcf5503b55f033068ce6c1f8a642755d59966427df8d0bf132e8907b0e1f53f9",
              "4377dbf0c9df3fb996b503b1f0861bc71bea36c78cd5d7450bc482180a8b4d2c3fb1bb8923ecac",
            ),
            (
              true, "644aff5b60b1c9f79d49e2dbc1c4b8f9b6d3f0d13ff8bff55634aadbf67c93d6dc860c44bdc4",
              "10ddf6fc3277cfee65ad40ec7c2186f1c6fa8db1e33575d142f1208602a2d34b0fec6ee248fb2b",
            ),
            (
              false, "86dd4988e284ead263704b805af892edd61e0a94b82d4969db45d9d4911ed42063ecf1acef307",
              "21bbedf864ef9fdccb5a81d8f8430de38df51b63c66aeba285e2410c0545a6961fd8ddc491f656",
            ),
            (
              true, "644aff5b60b1c9f79d49e2dbc1c4b8f9b6d3f0d13ff8bff55634aadbf67c93d6dc860c44bdc4",
              "10ddf6fc3277cfee65ad40ec7c2186f1c6fa8db1e33575d142f1208602a2d34b0fec6ee248fb2b",
            ),
            (
              false, "86dd4988e284ead263704b805af892edd61e0a94b82d4969db45d9d4911ed42063ecf1acef307",
              "21bbedf864ef9fdccb5a81d8f8430de38df51b63c66aeba285e2410c0545a6961fd8ddc491f656",
            ),
            (
              false, "be5bc94b287e94253c99213f5446612afe0a400f63b92865e727c55f1f1a6f1caceae2b381c0",
              "10ddf6fc3277cfee65ad40ec7c2186f1c6fa8db1e33575d142f1208602a2d34b0fec6ee248fb2b",
            ),
            (
              false, "46d90bc9f6b77ff45018425b5dac234bcd25ba4b187a9e98c91a530818309ef823c42abc2a8e1",
              "21bbedf864ef9fdccb5a81d8f8430de38df51b63c66aeba285e2410c0545a6961fd8ddc491f656",
            ),
          ],
          derivatives: [
            (
              false, "ea454e4aed26b4872c6bf957d3f1d8572ff5ec5bfe9c940754e6588146bee2acdf1f094ad2b63ca8b414cbf2037505424488ce48987f411b05d370ac1eb092411a7c2bbb24773d80d61e932df",
              "16fd5c1cc5274bff55a32d007ab38963087cbb079d917160ca03b2f58500291bd94bf126396dcc004a6a6682f43006910fa1d6c1741b81345e5e3d2d16d306792cacd5338b065f854558c6e598",
            ),
            (
              true, "359a52766baf855078e365eae21b49936d2338d814446ea829693292060b0470f8e3dac1b65622b68a5f0e911c42090a166f39e55223b4a7699448bf84cfb9d589b67cf8f3d32e3a0dce5e199",
              "16fd5c1cc5274bff55a32d007ab38963087cbb079d917160ca03b2f58500291bd94bf126396dcc004a6a6682f43006910fa1d6c1741b81345e5e3d2d16d306792cacd5338b065f854558c6e598",
            ),
            (
              false, "2b916a534dd370096fa5888cc6cb2a7861cd2c45a930921b7c7da84d6f1fdd70dd879239e8398658efa4ab4cde9d729d001842886c3a2f6a0a47cea25ca9bbee5b68c4caa59f577f74426af1d",
              "5bf57073149d2ffd568cb401eace258c21f2ec1e7645c583280ecbd61400a46f652fc498e5b7300129a99a0bd0c01a443e875b05d06e04d17978f4b45b4c19e4b2b354ce2c197e1515631b966",
            ),
            (
              true, "6e5390cf844353dff81b6756822a5c0c6ea670c551897bf57fb93e2b425f497f4291024d1548803e0722654de303c6a35ab5512a254c1356a02594a9dbb02e24ccd534b784fa73abf9a939e9",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "2b916a534dd370096fa5888cc6cb2a7861cd2c45a930921b7c7da84d6f1fdd70dd879239e8398658efa4ab4cde9d729d001842886c3a2f6a0a47cea25ca9bbee5b68c4caa59f577f74426af1d",
              "5bf57073149d2ffd568cb401eace258c21f2ec1e7645c583280ecbd61400a46f652fc498e5b7300129a99a0bd0c01a443e875b05d06e04d17978f4b45b4c19e4b2b354ce2c197e1515631b966",
            ),
            (
              true, "6e5390cf844353dff81b6756822a5c0c6ea670c551897bf57fb93e2b425f497f4291024d1548803e0722654de303c6a35ab5512a254c1356a02594a9dbb02e24ccd534b784fa73abf9a939e9",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "3bd0dd186671ca988b4043f23d65895e1e4d62b7371895ad0dbbd3cec07b35bfaec3b18050f16bf95f1e2422a693f0fcfa32c9bc17abc80c352efbf7a35574062a9cf908ac9d98b144785b13",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "25b816eeb6329ee68b9e0b30d38448ecbc0fd25da4d981488c5f601aa06a82cf76dfdfad64bc1a7c9f514582638fdbd53f81e181e10d10a4eddccc4a06083a91d500cbb80d73c9c592389942f",
              "5bf57073149d2ffd568cb401eace258c21f2ec1e7645c583280ecbd61400a46f652fc498e5b7300129a99a0bd0c01a443e875b05d06e04d17978f4b45b4c19e4b2b354ce2c197e1515631b966",
            ),
            (
              false, "2fac72200670ef26647a36b8101279c35328ccf5e191256c0ca9cad1c91dd14c727c10951e47445fc4f47a41acab3ea77d12f37223da52f9332bdca8e764308117f793d98e66af73afceaa743",
              "5bf57073149d2ffd568cb401eace258c21f2ec1e7645c583280ecbd61400a46f652fc498e5b7300129a99a0bd0c01a443e875b05d06e04d17978f4b45b4c19e4b2b354ce2c197e1515631b966",
            ),
            (
              false, "1976a66a30ea33ec4072644691e04eb6c16247cc198dbf8a26237a1d8e02b9c49c8d78e6aae67c89da9f956dce30c834cbd2d82358585987e062f24ed70780cf4b7cd15c51776a1f63181bd92",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              true, "8c3a8a08a0af9d924dddea2cbdf29f8f400e08399770557e3a0bec9fc72e4e766dbf469f1ca00ee27de6455af41b2c5d3b26bc9bee01cfbf9a5cc946ad575651d95795a9dbb7d295ed997208",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "219d0f21fd951fc996c95d058a3cf9a1cab431ad6c78edf7fc333d96466c8ef3e1eb61522eae5c75ca01768d95820fcac2873098296ced15c4f8be437b4dc5ff1871fca924ac71d156ac59c09",
              "5bf57073149d2ffd568cb401eace258c21f2ec1e7645c583280ecbd61400a46f652fc498e5b7300129a99a0bd0c01a443e875b05d06e04d17978f4b45b4c19e4b2b354ce2c197e1515631b966",
            ),
            (
              true, "8c3a8a08a0af9d924dddea2cbdf29f8f400e08399770557e3a0bec9fc72e4e766dbf469f1ca00ee27de6455af41b2c5d3b26bc9bee01cfbf9a5cc946ad575651d95795a9dbb7d295ed997208",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "219d0f21fd951fc996c95d058a3cf9a1cab431ad6c78edf7fc333d96466c8ef3e1eb61522eae5c75ca01768d95820fcac2873098296ced15c4f8be437b4dc5ff1871fca924ac71d156ac59c09",
              "5bf57073149d2ffd568cb401eace258c21f2ec1e7645c583280ecbd61400a46f652fc498e5b7300129a99a0bd0c01a443e875b05d06e04d17978f4b45b4c19e4b2b354ce2c197e1515631b966",
            ),
            (
              false, "e96f61132316b946af80c50a030748821a791e5e7e579cb339fb08452f0732dce98dcaee9ab9415c98a168ef852acb461cbf087a0fd2ba3132fb84a7c849d007d797fd2d370023682c99c34",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "6eecd60724e6ed185c3cc61e0f9ee123e7b9e3a84279627c97873bc121e8d57b593a0563dc87f7c96ea479cd3980674cbc54d23fb30177bfda49075795d89626884e3db33caf0febf6c35137b",
              "5bf57073149d2ffd568cb401eace258c21f2ec1e7645c583280ecbd61400a46f652fc498e5b7300129a99a0bd0c01a443e875b05d06e04d17978f4b45b4c19e4b2b354ce2c197e1515631b966",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              true, "141fc83ceafeb3604fcb8370ad7e262f25710b9272a905aab5d0eb46f44e0cccf2e1f39ce18d2c99091da29b70f09f799ba5e4fb86daad883065",
              "1fa5d74fccde4dfcfa91ee86b8b71d698da38b026b2d6edbde872c8d1052e2b9cde39368815e6e02ed0af1086ff16e8fb1188bfdf61fe44e25f0b",
            ),
            (
              false, "141fc83ceafeb3604fcb8370ad7e262f25710b9272a905aab5d0eb46f44e0cccf2e1f39ce18d2c99091da29b70f09f799ba5e4fb86daad883065",
              "1fa5d74fccde4dfcfa91ee86b8b71d698da38b026b2d6edbde872c8d1052e2b9cde39368815e6e02ed0af1086ff16e8fb1188bfdf61fe44e25f0b",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "77e2e5f0d11f3fbec875e97e0f9ceed933801a5e83e8876466fabc3d69f8909337e9a6a0465753e71175ea83099bf8366ef570a560ddf8edbf8d",
              "1fa5d74fccde4dfcfa91ee86b8b71d698da38b026b2d6edbde872c8d1052e2b9cde39368815e6e02ed0af1086ff16e8fb1188bfdf61fe44e25f0b",
            ),
            (
              true, "77e2e5f0d11f3fbec875e97e0f9ceed933801a5e83e8876466fabc3d69f8909337e9a6a0465753e71175ea83099bf8366ef570a560ddf8edbf8d",
              "1fa5d74fccde4dfcfa91ee86b8b71d698da38b026b2d6edbde872c8d1052e2b9cde39368815e6e02ed0af1086ff16e8fb1188bfdf61fe44e25f0b",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "f6bf08347c3ca18e139da87d61cddcd21c6e7ef81a3fab7fb7c4b34c2ccbb6dbf0af83250e07a981877106e60a0203fe2b5cc85e2e6d84ae544e",
              "1fa5d74fccde4dfcfa91ee86b8b71d698da38b026b2d6edbde872c8d1052e2b9cde39368815e6e02ed0af1086ff16e8fb1188bfdf61fe44e25f0b",
            ),
            (
              false, "f6bf08347c3ca18e139da87d61cddcd21c6e7ef81a3fab7fb7c4b34c2ccbb6dbf0af83250e07a981877106e60a0203fe2b5cc85e2e6d84ae544e",
              "1fa5d74fccde4dfcfa91ee86b8b71d698da38b026b2d6edbde872c8d1052e2b9cde39368815e6e02ed0af1086ff16e8fb1188bfdf61fe44e25f0b",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "141fc83ceafeb3604fcb8370ad7e262f25710b9272a905aab5d0eb46f44e0cccf2e1f39ce18d2c99091da29b70f09f799ba5e4fb86daad883065",
              "1fa5d74fccde4dfcfa91ee86b8b71d698da38b026b2d6edbde872c8d1052e2b9cde39368815e6e02ed0af1086ff16e8fb1188bfdf61fe44e25f0b",
            ),
            (
              true, "141fc83ceafeb3604fcb8370ad7e262f25710b9272a905aab5d0eb46f44e0cccf2e1f39ce18d2c99091da29b70f09f799ba5e4fb86daad883065",
              "1fa5d74fccde4dfcfa91ee86b8b71d698da38b026b2d6edbde872c8d1052e2b9cde39368815e6e02ed0af1086ff16e8fb1188bfdf61fe44e25f0b",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "53d6d256676c21ed720cb53204ecc9abe8aca29409330c0e3b94a1473f23af1f4a91f04c49013",
              "70726e91507414dffb2db0d33b8a2e4bd93105f7400f1173139cd8d2bc3d809f14d2e339e68a74",
            ),
            (
              true, "53d6d256676c21ed720cb53204ecc9abe8aca29409330c0e3b94a1473f23af1f4a91f04c49013",
              "70726e91507414dffb2db0d33b8a2e4bd93105f7400f1173139cd8d2bc3d809f14d2e339e68a74",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "53d6d256676c21ed720cb53204ecc9abe8aca29409330c0e3b94a1473f23af1f4a91f04c49013",
              "70726e91507414dffb2db0d33b8a2e4bd93105f7400f1173139cd8d2bc3d809f14d2e339e68a74",
            ),
            (
              false, "53d6d256676c21ed720cb53204ecc9abe8aca29409330c0e3b94a1473f23af1f4a91f04c49013",
              "70726e91507414dffb2db0d33b8a2e4bd93105f7400f1173139cd8d2bc3d809f14d2e339e68a74",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
            (false, "0", "1"),
          ],
          ricci: [
            (
              false, "f6bf08347c3ca18e139da87d61cddcd21c6e7ef81a3fab7fb7c4b34c2ccbb6dbf0af83250e07a981877106e60a0203fe2b5cc85e2e6d84ae544e",
              "1fa5d74fccde4dfcfa91ee86b8b71d698da38b026b2d6edbde872c8d1052e2b9cde39368815e6e02ed0af1086ff16e8fb1188bfdf61fe44e25f0b",
            ),
            (
              true, "141fc83ceafeb3604fcb8370ad7e262f25710b9272a905aab5d0eb46f44e0cccf2e1f39ce18d2c99091da29b70f09f799ba5e4fb86daad883065",
              "1fa5d74fccde4dfcfa91ee86b8b71d698da38b026b2d6edbde872c8d1052e2b9cde39368815e6e02ed0af1086ff16e8fb1188bfdf61fe44e25f0b",
            ),
            (
              true, "141fc83ceafeb3604fcb8370ad7e262f25710b9272a905aab5d0eb46f44e0cccf2e1f39ce18d2c99091da29b70f09f799ba5e4fb86daad883065",
              "1fa5d74fccde4dfcfa91ee86b8b71d698da38b026b2d6edbde872c8d1052e2b9cde39368815e6e02ed0af1086ff16e8fb1188bfdf61fe44e25f0b",
            ),
            (
              false, "77e2e5f0d11f3fbec875e97e0f9ceed933801a5e83e8876466fabc3d69f8909337e9a6a0465753e71175ea83099bf8366ef570a560ddf8edbf8d",
              "1fa5d74fccde4dfcfa91ee86b8b71d698da38b026b2d6edbde872c8d1052e2b9cde39368815e6e02ed0af1086ff16e8fb1188bfdf61fe44e25f0b",
            ),
          ],
        },
        {
          alpha: (false, "1", "1"),
          scalar: (
            false, "9c43ff43cfc2c0fbbdf6f026e652219785aa2ce805b25a4817259ae433f31269e6b8c2286d3e4f10",
            "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
          ),
          lower: [
            (
              true, "63d3b239dc034b33e458c3f0f5cb1f75d6e50c79507407705c59fe3854e1bfc79f1969e7f7",
              "2f7df860cb528025d4a8525e74dc9389dbe8523a7332f82a6085a197d79475de65ad262e4e8",
            ),
            (
              true, "4e57f8e55ee68197f719048845a9781c6fc6e05311c53428a06b681ae08f13766c5595efd1",
              "10534d6145e45c0d0119dc50782bd2b76397dc441799854e912def8c321b088472f3851feafc",
            ),
            (
              true, "99a5e64ccb4554b158f7b62bc024d9af16a4c3772e075d953b830276c8e8db357986852d1",
              "343dc46a794126900385f434b3bf6f17a51927404b84ddc836f964f3d389b4db0971a9ffbcc",
            ),
            (
              false, "1329161389a651f69aa1c6fe8ae3b80bb10d721ffa4b5650db7dc8302376b1992a8382e52b",
              "343dc46a794126900385f434b3bf6f17a51927404b84ddc836f964f3d389b4db0971a9ffbcc",
            ),
            (
              true, "99a5e64ccb4554b158f7b62bc024d9af16a4c3772e075d953b830276c8e8db357986852d1",
              "343dc46a794126900385f434b3bf6f17a51927404b84ddc836f964f3d389b4db0971a9ffbcc",
            ),
            (
              false, "1329161389a651f69aa1c6fe8ae3b80bb10d721ffa4b5650db7dc8302376b1992a8382e52b",
              "343dc46a794126900385f434b3bf6f17a51927404b84ddc836f964f3d389b4db0971a9ffbcc",
            ),
            (
              false, "14cfe8bc81b7f5e3b21af40078b59de86e0740e907718cb3fc0431528144b68042095063a3",
              "10534d6145e45c0d0119dc50782bd2b76397dc441799854e912def8c321b088472f3851feafc",
            ),
            (
              false, "112b1a8a62f484aad8d6153f5528840e447d0d9dea637e02db87fcb6a860794e6e5d9dd8ab3",
              "72471da8e93e845b07b506334932c303b92705dca532a525f8418cd55ebd3b9f24a8a3df6ce4",
            ),
          ],
          lower_first: [
            (
              false, "5584009afafc5c5e65690e378ae20226371e061d5c4e39e69e7a3a3a2ea0449168b225da00972760a912999b9af66294c1b96312361e545",
              "fcfeb47205dc1525c6a41f68288f2e04296549fe6d1ae0bcf47233872921aba6c946c2e0aaba0b21b386384fb686944e855139741940768",
            ),
            (
              true, "5a5d9ead012529503f7df58dd203f1d900d5e78a052da5fe57a696db3e9babf7f51b3f0d97ec512d78d3b5efc8aa8321b1e308c53ae65",
              "7e7f5a3902ee0a92e3520fb41447970214b2a4ff368d705e7a3919c39490d5d364a36170555d0590d9c31c27db434a2742a89cba0ca03b4",
            ),
            (
              false, "3b42b23ba24899765f48a4af3cae16cac56c30e74ede4c10dd43bcebd13379c19632722d2d04fd5b72c54dd47375bde32bd66c5e8c673e",
              "1f9fd68e40bb82a4b8d483ed0511e5c0852ca93fcda35c179e8e4670e5243574d928d85c155741643670c709f6d0d289d0aa272e83280ed",
            ),
            (
              false, "48a81d7a43e1ed63e5a6928553d3c5b19ce05a08a1268e4ecaffdc5cea94010017d627ba68d216fde5b7c6ff5d6a3811251fe2638f4d8",
              "1f9fd68e40bb82a4b8d483ed0511e5c0852ca93fcda35c179e8e4670e5243574d928d85c155741643670c709f6d0d289d0aa272e83280ed",
            ),
            (
              false, "3b42b23ba24899765f48a4af3cae16cac56c30e74ede4c10dd43bcebd13379c19632722d2d04fd5b72c54dd47375bde32bd66c5e8c673e",
              "1f9fd68e40bb82a4b8d483ed0511e5c0852ca93fcda35c179e8e4670e5243574d928d85c155741643670c709f6d0d289d0aa272e83280ed",
            ),
            (
              false, "48a81d7a43e1ed63e5a6928553d3c5b19ce05a08a1268e4ecaffdc5cea94010017d627ba68d216fde5b7c6ff5d6a3811251fe2638f4d8",
              "1f9fd68e40bb82a4b8d483ed0511e5c0852ca93fcda35c179e8e4670e5243574d928d85c155741643670c709f6d0d289d0aa272e83280ed",
            ),
            (
              false, "881e300098476d724d74ad852d37a98828ea327399ab5f14fa17a04f352fe4c9f5f3c002e767c118558e488639a5cde8fc9cfa47b1550",
              "1f9fd68e40bb82a4b8d483ed0511e5c0852ca93fcda35c179e8e4670e5243574d928d85c155741643670c709f6d0d289d0aa272e83280ed",
            ),
            (
              false, "267e85e50991556f35ae6ae427d2f2e5bd470250ba5500d0958dc370570b81db5320cb35369fa21da88ff7dc354a4ffef3818e5d776787",
              "3f3fad1c8177054971a907da0a23cb810a59527f9b46b82f3d1c8ce1ca486ae9b251b0b82aae82c86ce18e13eda1a513a1544e5d06501da",
            ),
            (
              false, "ba225f8437de6a5179b1b57790a0135ae7b05febbd07938e6a342ed7854b6bd0abdb4c7417c9025188455bb4460c9415f2ca07895e222d",
              "7e7f5a3902ee0a92e3520fb41447970214b2a4ff368d705e7a3919c39490d5d364a36170555d0590d9c31c27db434a2742a89cba0ca03b4",
            ),
            (
              false, "38b2566a55e9145b7020e8b31b161d15bbb3384ad6a434103b9ae79c2906ddb6dff70970dc259c17ddbb9ba01cfe2c0c8c64000183f1a",
              "6532ae940258087582a80c901039459b43c21d98f87126b1fb60e16943a71175ea1c4df3777d9e0d7b027cecaf69081f6886e3c80a19c9",
            ),
            (
              true, "19e78762367ff436d4ad5d66175b031cf2b8a555c294cd4999a0b2bcc5c1744add1fd847b1104e8d40c90a454bb617777fb4a38de2d691",
              "3f3fad1c8177054971a907da0a23cb810a59527f9b46b82f3d1c8ce1ca486ae9b251b0b82aae82c86ce18e13eda1a513a1544e5d06501da",
            ),
            (
              false, "2e4ff7674888a78d10ab35a59ff15babe9b4cdb3b8130a27a3f7832ee0411ad7e039bef4b7b69cd99640fca527e7f2a06f468abd11c501",
              "3f3fad1c8177054971a907da0a23cb810a59527f9b46b82f3d1c8ce1ca486ae9b251b0b82aae82c86ce18e13eda1a513a1544e5d06501da",
            ),
            (
              true, "19e78762367ff436d4ad5d66175b031cf2b8a555c294cd4999a0b2bcc5c1744add1fd847b1104e8d40c90a454bb617777fb4a38de2d691",
              "3f3fad1c8177054971a907da0a23cb810a59527f9b46b82f3d1c8ce1ca486ae9b251b0b82aae82c86ce18e13eda1a513a1544e5d06501da",
            ),
            (
              false, "2e4ff7674888a78d10ab35a59ff15babe9b4cdb3b8130a27a3f7832ee0411ad7e039bef4b7b69cd99640fca527e7f2a06f468abd11c501",
              "3f3fad1c8177054971a907da0a23cb810a59527f9b46b82f3d1c8ce1ca486ae9b251b0b82aae82c86ce18e13eda1a513a1544e5d06501da",
            ),
            (
              true, "21a6c57e682ad5bedb7551450361a9038b116bfbfe339a47ffe03753432ace2f88ae20692f629bb3ced71a08406b66d8abe72b8336619",
              "ca655d2804b010eb0550192020728b3687843b31f0e24d63f6c1c2d2874e22ebd4389be6eefb3c1af604f9d95ed2103ed10dc790143392",
            ),
            (
              false, "1df38a85b532d6423238861a3db0fc2acf9f1cacb40e0e018fe088e2650eb0327b2aca51e744dd8e8685ad1367c4110b16815ce73e05b7",
              "ca655d2804b010eb0550192020728b3687843b31f0e24d63f6c1c2d2874e22ebd4389be6eefb3c1af604f9d95ed2103ed10dc790143392",
            ),
          ],
          coefficients: [
            (
              true, "136a5e6c0f8d5d2e79217d19ec422ef5d6215de7e753654a6f9fbcd6f4e4264c8e2549c36fd01",
              "1c685c9b47866bac7559b0b6b61d84f585044cf5b48feed9b41cd875e97e058be4ec84db6d712",
            ),
            (
              true, "8c05d1451f3b7530ea576d0aeea6598d697f79639db3828297aed2682bcef676f2f8e2451f8f",
              "1c685c9b47866bac7559b0b6b61d84f585044cf5b48feed9b41cd875e97e058be4ec84db6d712",
            ),
            (
              true, "a7a11995eca9702d5943a7a6294c2bb908bb714f2b566f6531dc27e8e8f22cabeb5e787f659e",
              "10ddf6fc3277cfee65ad40ec7c2186f1c6fa8db1e33575d142f1208602a2d34b0fec6ee248fb2b",
            ),
            (
              false, "3e0bce2c95ff1161813b867c7e254ec2b82248e82b3a6052c9064cdf3f7b427847a6383a0cd49",
              "10ddf6fc3277cfee65ad40ec7c2186f1c6fa8db1e33575d142f1208602a2d34b0fec6ee248fb2b",
            ),
            (
              true, "a7a11995eca9702d5943a7a6294c2bb908bb714f2b566f6531dc27e8e8f22cabeb5e787f659e",
              "10ddf6fc3277cfee65ad40ec7c2186f1c6fa8db1e33575d142f1208602a2d34b0fec6ee248fb2b",
            ),
            (
              false, "3e0bce2c95ff1161813b867c7e254ec2b82248e82b3a6052c9064cdf3f7b427847a6383a0cd49",
              "10ddf6fc3277cfee65ad40ec7c2186f1c6fa8db1e33575d142f1208602a2d34b0fec6ee248fb2b",
            ),
            (
              false, "791e2eadc5b3e0a6f0122bdad0c1196843cfc0853d12e69e9c1daa12833ca70d99b6c36aed0",
              "e342e4da3c335d63aacd85b5b0ec27ac282267ada47f76cda0e6c3af4bf02c5f276426db6b89",
            ),
            (
              false, "174783b5e7ccfe642c90f48cbddd259d3731fa023fd07e5cb669407a8b4481c746489631bbc7",
              "e342e4da3c335d63aacd85b5b0ec27ac282267ada47f76cda0e6c3af4bf02c5f276426db6b89",
            ),
          ],
          derivatives: [
            (
              false, "a38ffca7a3ddbf3f81d6ab96ab12075d6b5c6e3e8209d4850c218293c5f8c8fbdfbd84dc9c649872e131d65f157c50c2e3d96227fb2a0b64d3018cdbcbb87001e8b574d8e9cc5d9604c71f1d",
              "9ae0bd638108bc9d3373b5e84817d372bfe9f976ac3f9d7e944ed090f94473425993d1d917199437da6103723728980725f170e15f0a230ff5019c2248ebf5b712059c4dc389402382561384",
            ),
            (
              false, "144a7c07f948822fe58a1c7121e2fac5c8f51185546cad83f51161b14bc2d8f718ed1d4389e65a5277f9dbf59adb055cc41913c2f0b67352d4a413cfe481e384e982c5c06de495c9661ae9e5",
              "9ae0bd638108bc9d3373b5e84817d372bfe9f976ac3f9d7e944ed090f94473425993d1d917199437da6103723728980725f170e15f0a230ff5019c2248ebf5b712059c4dc389402382561384",
            ),
            (
              false, "1af05472463bd9f71a5e70e06615c73f9f7c4b642de66486d82385ae22aa36dd02d0e5a76007c85a0db5d03930a712cdd299a3a4bc3e293f23a2b43b68f1d8010316a6e4da6eb1ed6176eadcd",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "2f572ae8f44c641b006230bc0331a04bed014d51d09c0caee33d0ec1c364e5cee48dbc00c4e1683645949a2fc34a5bf2465217314dc1ae3cba2ee928a794c500aa848ed659894222de5081aa",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "1af05472463bd9f71a5e70e06615c73f9f7c4b642de66486d82385ae22aa36dd02d0e5a76007c85a0db5d03930a712cdd299a3a4bc3e293f23a2b43b68f1d8010316a6e4da6eb1ed6176eadcd",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "2f572ae8f44c641b006230bc0331a04bed014d51d09c0caee33d0ec1c364e5cee48dbc00c4e1683645949a2fc34a5bf2465217314dc1ae3cba2ee928a794c500aa848ed659894222de5081aa",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "616cf413cdeeaa238bacbe0bdd449c72f725fbf6d4eab5ac59dd78d16d7c5c97f30d3f7c92b8652e0fd694e73978fdff1f167e4c205ce001685a548c77dac266cefa8b1ef383e51ef14d1b2",
              "26b82f58e0422f274cdced7a1205f4dcaffa7e5dab0fe75fa513b4243e511cd09664f47645c6650df69840dc8dca2601c97c5c3857c288c3fd406708923afd6dc481671370e25008e09584e1",
            ),
            (
              false, "e871ac3d5b8b94055fbffa8dd3b2c9e031b47b16028204f10b7501104077b5026fc834886d7b447fca538cc84469e530796edc36906d1d0c8ed052f7a35efcb2dc12607909cca3c0669259d",
              "26b82f58e0422f274cdced7a1205f4dcaffa7e5dab0fe75fa513b4243e511cd09664f47645c6650df69840dc8dca2601c97c5c3857c288c3fd406708923afd6dc481671370e25008e09584e1",
            ),
            (
              false, "13c0bef442e6c46c0c33a24dcb3ef57532e6de3276a0a80aacf8fd39d4e61c3d9c128377241009087ff97c5f79fa0cfeab1de375f0d229bc3a93536c68ffa4395beabacd2ffb199d49ef0909",
              "26b82f58e0422f274cdced7a1205f4dcaffa7e5dab0fe75fa513b4243e511cd09664f47645c6650df69840dc8dca2601c97c5c3857c288c3fd406708923afd6dc481671370e25008e09584e1",
            ),
            (
              false, "1cc9a0949b8d47238c624294925df24454d0eb6feb9fc7cad7b226bbb933b61812d9cf149b79a6faf61d385d68d90a5aa9a18c9178d56855abbab9f97c213c83491ffc68ffd87e45676359a0",
              "26b82f58e0422f274cdced7a1205f4dcaffa7e5dab0fe75fa513b4243e511cd09664f47645c6650df69840dc8dca2601c97c5c3857c288c3fd406708923afd6dc481671370e25008e09584e1",
            ),
            (
              true, "630f87e1ccca4b7aeb1bac4052f672a20faac5e6d873057a6ca04a6e0e036200b3eb655090f68bd6c239bdfffbd9311969987514994406df33483d7a34440cd478fd67c984ba93ba1e795274",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "129ebf71b24efb2058c3d818b6f0da75f979fff2a6fe722fc8ff8408a1009792b2143e900f1aebb14afede11bdbb7a568171b736e1db6b5f553abce4eea41352b9aea9f2b49b812614f39a47d",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              true, "630f87e1ccca4b7aeb1bac4052f672a20faac5e6d873057a6ca04a6e0e036200b3eb655090f68bd6c239bdfffbd9311969987514994406df33483d7a34440cd478fd67c984ba93ba1e795274",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "129ebf71b24efb2058c3d818b6f0da75f979fff2a6fe722fc8ff8408a1009792b2143e900f1aebb14afede11bdbb7a568171b736e1db6b5f553abce4eea41352b9aea9f2b49b812614f39a47d",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "235f8eaac9c12269bb6b7c6d105e65513520abbab2ed0fd67cf6fa65d06fdcf0ed47b045007121777b8dafd1ebb19056a541bb80b4e81b1e275967b6110b45b5732eef5506baab94cda1578",
              "26b82f58e0422f274cdced7a1205f4dcaffa7e5dab0fe75fa513b4243e511cd09664f47645c6650df69840dc8dca2601c97c5c3857c288c3fd406708923afd6dc481671370e25008e09584e1",
            ),
            (
              false, "3a11d273f8e6e91875af4e7b95a5b7f1e81b42fe81b9a1e5f753b3bcec7a0c65c43492cb8dff6f56147c42079f332054cbafca24c3598357cf5aa6cde81e9b82891a232f7bc09d0c0051bf41",
              "26b82f58e0422f274cdced7a1205f4dcaffa7e5dab0fe75fa513b4243e511cd09664f47645c6650df69840dc8dca2601c97c5c3857c288c3fd406708923afd6dc481671370e25008e09584e1",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              false, "d022ec90938d8e980ce28b4b3fdbf2b4f5155965522de3f66eeecc0b449e2196f58637236464dfef5c42060eee65d23ecc5fd08d47c4323b5f0",
              "a8c9d1a999f6f545385fa2ce83d09cdd9e12e5623b9cf9e9f82642f0570f63def4bdbcd8074cf564f03a5ad7aa5cf853b082ea9fcb54c1a0ca59",
            ),
            (
              true, "d022ec90938d8e980ce28b4b3fdbf2b4f5155965522de3f66eeecc0b449e2196f58637236464dfef5c42060eee65d23ecc5fd08d47c4323b5f0",
              "a8c9d1a999f6f545385fa2ce83d09cdd9e12e5623b9cf9e9f82642f0570f63def4bdbcd8074cf564f03a5ad7aa5cf853b082ea9fcb54c1a0ca59",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "2b3613a9aa50b084337bc831d0f3fb3cf774f197f5b93161b1d75a37f34e7e9943a64e7208a1b53771ba138f21c71c4409254303a6b0c2ab648c",
              "a8c9d1a999f6f545385fa2ce83d09cdd9e12e5623b9cf9e9f82642f0570f63def4bdbcd8074cf564f03a5ad7aa5cf853b082ea9fcb54c1a0ca59",
            ),
            (
              true, "2b3613a9aa50b084337bc831d0f3fb3cf774f197f5b93161b1d75a37f34e7e9943a64e7208a1b53771ba138f21c71c4409254303a6b0c2ab648c",
              "a8c9d1a999f6f545385fa2ce83d09cdd9e12e5623b9cf9e9f82642f0570f63def4bdbcd8074cf564f03a5ad7aa5cf853b082ea9fcb54c1a0ca59",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "47d79207131f5c8edf4a39d253916158c3f45e9d8af52632bd1e0a1cb19c270a6f56191eaba7390d737922bd6e23055e0e18173a3f778304a600",
              "a8c9d1a999f6f545385fa2ce83d09cdd9e12e5623b9cf9e9f82642f0570f63def4bdbcd8074cf564f03a5ad7aa5cf853b082ea9fcb54c1a0ca59",
            ),
            (
              false, "47d79207131f5c8edf4a39d253916158c3f45e9d8af52632bd1e0a1cb19c270a6f56191eaba7390d737922bd6e23055e0e18173a3f778304a600",
              "a8c9d1a999f6f545385fa2ce83d09cdd9e12e5623b9cf9e9f82642f0570f63def4bdbcd8074cf564f03a5ad7aa5cf853b082ea9fcb54c1a0ca59",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "53fb4da6bc9fe1fe2afb8034f4ee181a44c01fb0cf8a938458fa4631c420364dc5a136d2e5b3c758e008b1b1789ecd69fb37203b402e7044c0c",
              "a8c9d1a999f6f545385fa2ce83d09cdd9e12e5623b9cf9e9f82642f0570f63def4bdbcd8074cf564f03a5ad7aa5cf853b082ea9fcb54c1a0ca59",
            ),
            (
              false, "53fb4da6bc9fe1fe2afb8034f4ee181a44c01fb0cf8a938458fa4631c420364dc5a136d2e5b3c758e008b1b1789ecd69fb37203b402e7044c0c",
              "a8c9d1a999f6f545385fa2ce83d09cdd9e12e5623b9cf9e9f82642f0570f63def4bdbcd8074cf564f03a5ad7aa5cf853b082ea9fcb54c1a0ca59",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (
              false, "3582e75410342355ae4f410dd9dbef93ebc0a2f96d240e8a38a8a616a2d1d3cb4470fd275838",
              "95ede8c1c09ac67ff9924119a4b83dba76ec07f455696c996f7bcbc3a5a7562971192ef7de0df",
            ),
            (
              true, "3582e75410342355ae4f410dd9dbef93ebc0a2f96d240e8a38a8a616a2d1d3cb4470fd275838",
              "95ede8c1c09ac67ff9924119a4b83dba76ec07f455696c996f7bcbc3a5a7562971192ef7de0df",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "7bc4239b12373208d5b569e976968f899516bb6b47a8830d461e76e1016f2f37f7cd4fd01c97",
              "95ede8c1c09ac67ff9924119a4b83dba76ec07f455696c996f7bcbc3a5a7562971192ef7de0df",
            ),
            (
              true, "7bc4239b12373208d5b569e976968f899516bb6b47a8830d461e76e1016f2f37f7cd4fd01c97",
              "95ede8c1c09ac67ff9924119a4b83dba76ec07f455696c996f7bcbc3a5a7562971192ef7de0df",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "1466b461b78890ecbb0b0437bb883d7033a987b3c64a7d086c8e35b4c9fcfb4c95de1c219cc4",
              "1dfc61c059b88e199850736b87580c587e2f34ca777b7c1eafe58f27212177a1e36b6fcb2c693",
            ),
            (
              false, "1466b461b78890ecbb0b0437bb883d7033a987b3c64a7d086c8e35b4c9fcfb4c95de1c219cc4",
              "1dfc61c059b88e199850736b87580c587e2f34ca777b7c1eafe58f27212177a1e36b6fcb2c693",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "113a5990b346e08563fc397fae9c3571494557e235c6784ff1b7a35d5106cadbf00be587622a",
              "95ede8c1c09ac67ff9924119a4b83dba76ec07f455696c996f7bcbc3a5a7562971192ef7de0df",
            ),
            (
              false, "113a5990b346e08563fc397fae9c3571494557e235c6784ff1b7a35d5106cadbf00be587622a",
              "95ede8c1c09ac67ff9924119a4b83dba76ec07f455696c996f7bcbc3a5a7562971192ef7de0df",
            ),
            (false, "0", "1"),
          ],
          ricci: [
            (
              false, "47d79207131f5c8edf4a39d253916158c3f45e9d8af52632bd1e0a1cb19c270a6f56191eaba7390d737922bd6e23055e0e18173a3f778304a600",
              "a8c9d1a999f6f545385fa2ce83d09cdd9e12e5623b9cf9e9f82642f0570f63def4bdbcd8074cf564f03a5ad7aa5cf853b082ea9fcb54c1a0ca59",
            ),
            (
              false, "d022ec90938d8e980ce28b4b3fdbf2b4f5155965522de3f66eeecc0b449e2196f58637236464dfef5c42060eee65d23ecc5fd08d47c4323b5f0",
              "a8c9d1a999f6f545385fa2ce83d09cdd9e12e5623b9cf9e9f82642f0570f63def4bdbcd8074cf564f03a5ad7aa5cf853b082ea9fcb54c1a0ca59",
            ),
            (
              false, "53fb4da6bc9fe1fe2afb8034f4ee181a44c01fb0cf8a938458fa4631c420364dc5a136d2e5b3c758e008b1b1789ecd69fb37203b402e7044c0c",
              "a8c9d1a999f6f545385fa2ce83d09cdd9e12e5623b9cf9e9f82642f0570f63def4bdbcd8074cf564f03a5ad7aa5cf853b082ea9fcb54c1a0ca59",
            ),
            (
              false, "2b3613a9aa50b084337bc831d0f3fb3cf774f197f5b93161b1d75a37f34e7e9943a64e7208a1b53771ba138f21c71c4409254303a6b0c2ab648c",
              "a8c9d1a999f6f545385fa2ce83d09cdd9e12e5623b9cf9e9f82642f0570f63def4bdbcd8074cf564f03a5ad7aa5cf853b082ea9fcb54c1a0ca59",
            ),
          ],
        },
        {
          alpha: (true, "1", "1"),
          scalar: (
            false, "9c43ff43cfc2c0fbbdf6f026e652219785aa2ce805b25a4817259ae433f31269e6b8c2286d3e4f10",
            "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
          ),
          lower: [
            (
              true, "8751b9e6d8efa8d01960dbe6898d465d", "b48a5e54c00975963c6078395976695f6",
            ),
            (
              true, "260c2b459da20e0ed67ff9b75c4ac62f", "b48a5e54c00975963c6078395976695f6",
            ),
            (
              true, "598793a0f6c481da2a41651d883b34af", "3b213767c3eb0bc1d13001b1d33eb3793a",
            ),
            (
              false, "c6f1fbc7bfe5fd7af5f8b879e65b5122", "1d909bb3e1f585e0e89800d8e99f59bc9d",
            ),
            (
              true, "598793a0f6c481da2a41651d883b34af", "3b213767c3eb0bc1d13001b1d33eb3793a",
            ),
            (
              false, "c6f1fbc7bfe5fd7af5f8b879e65b5122", "1d909bb3e1f585e0e89800d8e99f59bc9d",
            ),
            (
              false, "75f07599cd1995dffa9b3828eb95edcf", "37397a10b8fbb3851d590a5dacedb83349",
            ),
            (
              false, "ced09a226fc8b6cd9faea135c6b07b25", "37397a10b8fbb3851d590a5dacedb83349",
            ),
          ],
          lower_first: [
            (
              false, "ca8897baad6a0bb931ab680c91184738e215e0ef08479243da938f3a6e0d9",
              "7fb4a5bfeb1eb42580349900b4ea1ce4fba3eeac8d4e042b668a64774b6197",
            ),
            (
              true, "1a776970a0f424d721a57eaaa14f96111d96a176ef21ab7d02b8f5f3eb2e6f",
              "231e7a6193dba4bd8341aa1364f394bef866ae6f73a8a78bef660ed40187a32",
            ),
            (
              false, "2be224e51917f0c4acb9b99322e6d802eed019b66d9f2d8bc96a9ef5f181a967",
              "25abbe12b736ee459633fbca1fbf55824c64311b6a62e75bd3686b017206201b4",
            ),
            (
              true, "42e142e291c3885d2cc9dc9ee51012b73b056c7343128eda91af1ef19f15ecd",
              "96aef84adcdbb91658cfef287efd56093190c46da98b9d6f4da1ac05c818806d",
            ),
            (
              false, "2be224e51917f0c4acb9b99322e6d802eed019b66d9f2d8bc96a9ef5f181a967",
              "25abbe12b736ee459633fbca1fbf55824c64311b6a62e75bd3686b017206201b4",
            ),
            (
              true, "42e142e291c3885d2cc9dc9ee51012b73b056c7343128eda91af1ef19f15ecd",
              "96aef84adcdbb91658cfef287efd56093190c46da98b9d6f4da1ac05c818806d",
            ),
            (
              true, "a7691e3973ca716deaa7941ed3cd53d2bc77c18093616ff061669e821e7583d",
              "20dbf6a2727e748b1eda0e23941cd3262497d924a9de0a81e5c8e42fa95cb7515",
            ),
            (
              false, "53713db456f6b6f575f9a95ee067ea866d45cb1a23e1dfe089d878c2263d1e3",
              "6926486e3b2e41bd2f8693a50d290a13a84c507552c688061282da321df57dd1",
            ),
            (
              false, "1133872d446396c33549a8c90c22cee2bbbf26cb80e1ddb9cc12aca54debb29",
              "af9863e7e34a37b390485260f8c1e7bada01682d424b45bbacfe4a2407a62fa",
            ),
            (
              false, "2937d3c7bf9c2d23bee61ac1afe5979de7becd08f9e1c8a43e68c65f2b4d47",
              "af9863e7e34a37b390485260f8c1e7bada01682d424b45bbacfe4a2407a62fa",
            ),
            (
              true, "16272dacdf4bee7ef309e2d0bc2fd9d77402adeb30be024f308ce0382e53b33",
              "1e22fe755f5f25047829963b4c99113509e9c0e2bb8252afdc5388cdf4d1b349",
            ),
            (
              false, "1430a7e1eb472f11511f2887ecade9e83fbd2fe5e842ae6e0747e428636b3f2",
              "1e22fe755f5f25047829963b4c99113509e9c0e2bb8252afdc5388cdf4d1b349",
            ),
            (
              true, "16272dacdf4bee7ef309e2d0bc2fd9d77402adeb30be024f308ce0382e53b33",
              "1e22fe755f5f25047829963b4c99113509e9c0e2bb8252afdc5388cdf4d1b349",
            ),
            (
              false, "1430a7e1eb472f11511f2887ecade9e83fbd2fe5e842ae6e0747e428636b3f2",
              "1e22fe755f5f25047829963b4c99113509e9c0e2bb8252afdc5388cdf4d1b349",
            ),
            (
              true, "7827cb07f83b90f2f993db3391574d5333f9fc7038951cfa465d584f664bbed",
              "20dbf6a2727e748b1eda0e23941cd3262497d924a9de0a81e5c8e42fa95cb7515",
            ),
            (
              false, "319981a59d20b30f032f73ef25e93651d18ec597b6ec6e5add11f372586e8011",
              "20dbf6a2727e748b1eda0e23941cd3262497d924a9de0a81e5c8e42fa95cb7515",
            ),
          ],
          coefficients: [
            (
              true, "167288ffca3e446fdb43fa8e83c6898ba1f946a8", "5a10194eb88867943643a88fb1b37c309ba632e3",
            ),
            (
              true, "1000bcd72df4c7c74342d53e9f10e6cf19e1ef5e", "5a10194eb88867943643a88fb1b37c309ba632e3",
            ),
            (
              true, "aff97011c52a6c10c5d9efae7c4d1bc710507a", "5a10194eb88867943643a88fb1b37c309ba632e3",
            ),
            (
              false, "184d199716b25c64049acb115bc5b0fdef08756e", "5a10194eb88867943643a88fb1b37c309ba632e3",
            ),
            (
              true, "aff97011c52a6c10c5d9efae7c4d1bc710507a", "5a10194eb88867943643a88fb1b37c309ba632e3",
            ),
            (
              false, "184d199716b25c64049acb115bc5b0fdef08756e", "5a10194eb88867943643a88fb1b37c309ba632e3",
            ),
            (
              false, "4f0e3c76b1cd28af561579b812e3504605e4c90", "5a10194eb88867943643a88fb1b37c309ba632e3",
            ),
            (
              false, "e6b05bfa355360b5a6e8c9ca054f0b74291597c", "5a10194eb88867943643a88fb1b37c309ba632e3",
            ),
          ],
          derivatives: [
            (
              false, "6e5e67deb12879347a7cbeaf31ea372e32c907cfedeae0c27e9691e527d95d95dd6f8225d0a01aa",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              true, "d62bbd7c2bac8f05ecdc2ca97d365e455435961d802f6d7ab1454e444d8da3be2e0070a7efb0c92",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              false, "b7599e8351203727d20f4de8d4cd7643437356b598422fdfe3c25ef439e2b0c2cc497c221b4d8f0",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              true, "b8ad4da7ff321ec83fdaed2d765b97e83450a24d90d38370f5bb2cba179f2c6dba11274021fc834",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              false, "b7599e8351203727d20f4de8d4cd7643437356b598422fdfe3c25ef439e2b0c2cc497c221b4d8f0",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              true, "b8ad4da7ff321ec83fdaed2d765b97e83450a24d90d38370f5bb2cba179f2c6dba11274021fc834",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              false, "2b6dc66ebd3d0cce26bc9a18eec95a63f854f8dcc0bf27f2b01581e13a2d55eb5ec0877e6010d0",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              false, "e1ab2d0fc45afc5afacd817d042892614c740dccc926e7fcedd58a7c61c0e0c17d3fd421eded518",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              false, "10b02e29485f4f0406670390a0312f0971812ded5e7381bbae4eadcac68055663afe2a828e074c48",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              false, "b896f738c89fcbd04d2f7956b0ac6ba5fea24434493bae16cc55d8c35ced7b0acc6264f9d12310c",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              true, "7d0096f76e4801989da91b41f8b3a300cdfebc0bceecda99314380ba3a85c4d59bca7923070de94",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              false, "a550505ed7082e0bac71e08e6fcf00bd73c1fd058acbb079aa6d4fbe53095e13556771045ecaf64",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              true, "7d0096f76e4801989da91b41f8b3a300cdfebc0bceecda99314380ba3a85c4d59bca7923070de94",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              false, "a550505ed7082e0bac71e08e6fcf00bd73c1fd058acbb079aa6d4fbe53095e13556771045ecaf64",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              true, "8d6baaf5ecfc22ac58d9ac60ae0c74bd6248338da6fd42e7dd04419bea2f117f5369aeadcd1680",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              false, "1ceb931c08f99016ca7badc72c00be66181e1f712cb7221f9e0754df4be4edc8b43600ffedcc1f78",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              true, "4fc36c1adba2eefacf5e03ead6844ec086f212bcb17d8c05d0e718ee9901498f62a84820d423ce4",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              false, "4fc36c1adba2eefacf5e03ead6844ec086f212bcb17d8c05d0e718ee9901498f62a84820d423ce4",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "70a193e744a49a96e38af165298aa43cb5c77a5081125cb38419f29192d860b45ffa6685464bbc8",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              true, "70a193e744a49a96e38af165298aa43cb5c77a5081125cb38419f29192d860b45ffa6685464bbc8",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "11b27da830db09afaec518816a4f2048fdaa50f4556328a2bd11a229cdeb89af63ff9de83c8e0778",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              false, "11b27da830db09afaec518816a4f2048fdaa50f4556328a2bd11a229cdeb89af63ff9de83c8e0778",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "387504ba942104318958b9b83c9866108b049b63a0e2d7ae1326d5f47996269ca6e77f379e1ef40",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              true, "387504ba942104318958b9b83c9866108b049b63a0e2d7ae1326d5f47996269ca6e77f379e1ef40",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (
              true, "3582e75410342355ae4f410dd9dbef93ebc0a2f96d240e8a38a8a616a2d1d3cb4470fd275838",
              "95ede8c1c09ac67ff9924119a4b83dba76ec07f455696c996f7bcbc3a5a7562971192ef7de0df",
            ),
            (
              false, "3582e75410342355ae4f410dd9dbef93ebc0a2f96d240e8a38a8a616a2d1d3cb4470fd275838",
              "95ede8c1c09ac67ff9924119a4b83dba76ec07f455696c996f7bcbc3a5a7562971192ef7de0df",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "1466b461b78890ecbb0b0437bb883d7033a987b3c64a7d086c8e35b4c9fcfb4c95de1c219cc4",
              "1dfc61c059b88e199850736b87580c587e2f34ca777b7c1eafe58f27212177a1e36b6fcb2c693",
            ),
            (
              true, "1466b461b78890ecbb0b0437bb883d7033a987b3c64a7d086c8e35b4c9fcfb4c95de1c219cc4",
              "1dfc61c059b88e199850736b87580c587e2f34ca777b7c1eafe58f27212177a1e36b6fcb2c693",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "7bc4239b12373208d5b569e976968f899516bb6b47a8830d461e76e1016f2f37f7cd4fd01c97",
              "95ede8c1c09ac67ff9924119a4b83dba76ec07f455696c996f7bcbc3a5a7562971192ef7de0df",
            ),
            (
              false, "7bc4239b12373208d5b569e976968f899516bb6b47a8830d461e76e1016f2f37f7cd4fd01c97",
              "95ede8c1c09ac67ff9924119a4b83dba76ec07f455696c996f7bcbc3a5a7562971192ef7de0df",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "113a5990b346e08563fc397fae9c3571494557e235c6784ff1b7a35d5106cadbf00be587622a",
              "95ede8c1c09ac67ff9924119a4b83dba76ec07f455696c996f7bcbc3a5a7562971192ef7de0df",
            ),
            (
              true, "113a5990b346e08563fc397fae9c3571494557e235c6784ff1b7a35d5106cadbf00be587622a",
              "95ede8c1c09ac67ff9924119a4b83dba76ec07f455696c996f7bcbc3a5a7562971192ef7de0df",
            ),
            (false, "0", "1"),
          ],
          ricci: [
            (
              false, "11b27da830db09afaec518816a4f2048fdaa50f4556328a2bd11a229cdeb89af63ff9de83c8e0778",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              true, "4fc36c1adba2eefacf5e03ead6844ec086f212bcb17d8c05d0e718ee9901498f62a84820d423ce4",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              true, "387504ba942104318958b9b83c9866108b049b63a0e2d7ae1326d5f47996269ca6e77f379e1ef40",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
            (
              false, "70a193e744a49a96e38af165298aa43cb5c77a5081125cb38419f29192d860b45ffa6685464bbc8",
              "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
            ),
          ],
        },
        {
          alpha: (false, "3", "5"),
          scalar: (
            false, "9b4a65a2f4f629b5fd593054edda648ebc3ef2c5987006bdf7084e9745ecdb927281768c81678390",
            "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
          ),
          lower: [
            (
              true, "255fe42a390571835555331c1398d639970d6e406d055c0cd1ac3a25f58b2010a251f3ddf2b",
              "146820b9975d7310416053649636c7653c7dd3551d7fe6a235796b6f3ea1caa58fb06667e5bb",
            ),
            (
              true, "b835fe4ede91f795f99573f1627b4e883471fb981de62ebd860079c70dc47a8b82f044ec05",
              "28d041732ebae62082c0a6c92c6d8eca78fba6aa3affcd446af2d6de7d43954b1f60cccfcb76",
            ),
            (
              true, "6c63abfd701fddc49d586eeee2706c51e6b1837d8d6eed748b724f70a954b5253b0b661faf",
              "28d041732ebae62082c0a6c92c6d8eca78fba6aa3affcd446af2d6de7d43954b1f60cccfcb76",
            ),
            (
              false, "b34be43de45902ac571cf71fe906f67a4d630755614dddaeab87ed0b78207441667b6e207",
              "1daebb3c7f139017a4e9337b0909dc362971336487ffdb1a7c5384fee6bcc9aaff8c37dcf11",
            ),
            (
              true, "6c63abfd701fddc49d586eeee2706c51e6b1837d8d6eed748b724f70a954b5253b0b661faf",
              "28d041732ebae62082c0a6c92c6d8eca78fba6aa3affcd446af2d6de7d43954b1f60cccfcb76",
            ),
            (
              false, "b34be43de45902ac571cf71fe906f67a4d630755614dddaeab87ed0b78207441667b6e207",
              "1daebb3c7f139017a4e9337b0909dc362971336487ffdb1a7c5384fee6bcc9aaff8c37dcf11",
            ),
            (
              false, "2af34e576133d89fc01ae78b1baf5de528f5fb7d459dfb5caa5de50320c3718ba1e0ceb24",
              "1daebb3c7f139017a4e9337b0909dc362971336487ffdb1a7c5384fee6bcc9aaff8c37dcf11",
            ),
            (
              false, "17dafa1e5218a5d37be888b1e620c4f2ee0d72688f0d530fdf66e04cdd53ca61c0352a03e08",
              "8ed8e513238e2571c9a247c01b7f73c4a770c753ce7f4e6f7651f00ab66c8a86edd2ccd7481d",
            ),
          ],
          lower_first: [
            (
              false, "5bc8f128af162bed7abbbd24b292f8aac25c534b1af65fecbd5710a0032ef65fd940285ce66e3b04d26fd1e9af17095e480bba0c691a70b",
              "13c3e618e87531a6f384d274232b2f98533be9c7e086198ec318ec068f36a16907b987398d5688dea2067c663a428396226a587d11f90942",
            ),
            (
              true, "3af6166ac0e8cbbfc6e81950a3fc012c6167ce86645804911cdaf64726aa888705eec3451e3aa4d40e9f14523263004c59e0bda6a50505",
              "13c3e618e87531a6f384d274232b2f98533be9c7e086198ec318ec068f36a16907b987398d5688dea2067c663a428396226a587d11f90942",
            ),
            (
              false, "4478701693c3602a8f7b407cbc743011279e70d60824c2c0e8af8e5028e4117cf2cabe8b187685adb0fee14cf8f221e214095eed3506ec7",
              "2787cc31d0ea634de709a4e846565f30a677d38fc10c331d8631d80d1e6d42d20f730e731aad11bd440cf8cc7485072c44d4b0fa23f21284",
            ),
            (
              false, "420bdc106cd83ffd6d9dba0e0c7841e98b4f074a545da30c095f24f6ebf01fec05c3293d7e2dab2e3aae6f41cdc31a43c2ab6718a8413",
              "9e1f30c743a98d379c2693a119597cc299df4e3f0430cc7618c7603479b50b483dcc39cc6ab446f51033e331d2141cb11352c3e88fc84a1",
            ),
            (
              false, "4478701693c3602a8f7b407cbc743011279e70d60824c2c0e8af8e5028e4117cf2cabe8b187685adb0fee14cf8f221e214095eed3506ec7",
              "2787cc31d0ea634de709a4e846565f30a677d38fc10c331d8631d80d1e6d42d20f730e731aad11bd440cf8cc7485072c44d4b0fa23f21284",
            ),
            (
              false, "420bdc106cd83ffd6d9dba0e0c7841e98b4f074a545da30c095f24f6ebf01fec05c3293d7e2dab2e3aae6f41cdc31a43c2ab6718a8413",
              "9e1f30c743a98d379c2693a119597cc299df4e3f0430cc7618c7603479b50b483dcc39cc6ab446f51033e331d2141cb11352c3e88fc84a1",
            ),
            (
              false, "17f5a38b012d3c04574a4410d4b6bb51a478041612ef5b6eaf4d5f8b260fb92dd5c5722a7f719fdb269def6e41aed077af81cde8d5266b",
              "9e1f30c743a98d379c2693a119597cc299df4e3f0430cc7618c7603479b50b483dcc39cc6ab446f51033e331d2141cb11352c3e88fc84a1",
            ),
            (
              false, "661591e17107ce88b8ada6f3d73c917ebed98911127338c745f72c8ffa82afb2bdb2785e848b7aa35af72d3ec0319eb472c5d76682b285",
              "9e1f30c743a98d379c2693a119597cc299df4e3f0430cc7618c7603479b50b483dcc39cc6ab446f51033e331d2141cb11352c3e88fc84a1",
            ),
            (
              false, "1d766e2952435080876b0b7fdd07d14d0f7f2f126037baaf7b5344b3da7dcd31712f039f7d943c0c323bf40fb7be179de857378806aff33",
              "13c3e618e87531a6f384d274232b2f98533be9c7e086198ec318ec068f36a16907b987398d5688dea2067c663a428396226a587d11f90942",
            ),
            (
              false, "9c9692310bf9a617718ea6d5985e6668b00fac44485d288ee992e03d7b2c9eaac095392cafb7f6d2ca49c2cee6698693e407be8bf03ea7",
              "13c3e618e87531a6f384d274232b2f98533be9c7e086198ec318ec068f36a16907b987398d5688dea2067c663a428396226a587d11f90942",
            ),
            (
              true, "4b0e3063287f3f4c3a1d81ac4886e205fc0dcf2931a5fe49e86a589d30e80dd38676fedd3ac78cdd0746db6ff75f9c34689bf99f1d22a1",
              "9e1f30c743a98d379c2693a119597cc299df4e3f0430cc7618c7603479b50b483dcc39cc6ab446f51033e331d2141cb11352c3e88fc84a1",
            ),
            (
              false, "71cfbc24cf7ac9b58128d7160b6a2ea8017e3a258f1046c9db95cc2dc853152d9157e5fdc62df2bd3f80b46c2c1e12a6ac6d51f5ea3ebc",
              "9e1f30c743a98d379c2693a119597cc299df4e3f0430cc7618c7603479b50b483dcc39cc6ab446f51033e331d2141cb11352c3e88fc84a1",
            ),
            (
              true, "4b0e3063287f3f4c3a1d81ac4886e205fc0dcf2931a5fe49e86a589d30e80dd38676fedd3ac78cdd0746db6ff75f9c34689bf99f1d22a1",
              "9e1f30c743a98d379c2693a119597cc299df4e3f0430cc7618c7603479b50b483dcc39cc6ab446f51033e331d2141cb11352c3e88fc84a1",
            ),
            (
              false, "71cfbc24cf7ac9b58128d7160b6a2ea8017e3a258f1046c9db95cc2dc853152d9157e5fdc62df2bd3f80b46c2c1e12a6ac6d51f5ea3ebc",
              "9e1f30c743a98d379c2693a119597cc299df4e3f0430cc7618c7603479b50b483dcc39cc6ab446f51033e331d2141cb11352c3e88fc84a1",
            ),
            (
              true, "1c4278a8273c502843f6d685ef1582908b6b64789bb7a3217e3c270074c91f03420080b8321f9f0731b9cf8729f9b443b00fa2e144a9ff",
              "9e1f30c743a98d379c2693a119597cc299df4e3f0430cc7618c7603479b50b483dcc39cc6ab446f51033e331d2141cb11352c3e88fc84a1",
            ),
            (
              false, "15b3fbd5316e036d9a394c517de869ea999198907ff6c71d641b573df07e46db0ea636d1c10fdf3554f409e28b964c0fb88694f7b2ce32f",
              "9e1f30c743a98d379c2693a119597cc299df4e3f0430cc7618c7603479b50b483dcc39cc6ab446f51033e331d2141cb11352c3e88fc84a1",
            ),
          ],
          coefficients: [
            (
              true, "3250d77b33f79838524f58b46bbdaa9ebf1e395f280689a906d92640fe6af94f885cbd82971c8e",
              "5455d2ecfc570fa7fc62449e6ca7a2b8e2e4c479700b4d164eb5a29e0d2e20774f9e2a6b6ce7d7",
            ),
            (
              true, "17c81a96aadb3d8a6cbed94eafab083eb19fad56b8492ab455150a5c5f668309b254f2b7c1ad68",
              "5455d2ecfc570fa7fc62449e6ca7a2b8e2e4c479700b4d164eb5a29e0d2e20774f9e2a6b6ce7d7",
            ),
            (
              true, "2bf794b78875fe477465ebca9ff6df51e87da359001f4ce1a41fdcd72a7cfadb17b278207ac62",
              "5455d2ecfc570fa7fc62449e6ca7a2b8e2e4c479700b4d164eb5a29e0d2e20774f9e2a6b6ce7d7",
            ),
            (
              false, "14100b40ea4821ef6e722def5d5687f35fe84e54d39dc6a623658c0724f909b893adf9a5b15ae2",
              "5455d2ecfc570fa7fc62449e6ca7a2b8e2e4c479700b4d164eb5a29e0d2e20774f9e2a6b6ce7d7",
            ),
            (
              true, "2bf794b78875fe477465ebca9ff6df51e87da359001f4ce1a41fdcd72a7cfadb17b278207ac62",
              "5455d2ecfc570fa7fc62449e6ca7a2b8e2e4c479700b4d164eb5a29e0d2e20774f9e2a6b6ce7d7",
            ),
            (
              false, "14100b40ea4821ef6e722def5d5687f35fe84e54d39dc6a623658c0724f909b893adf9a5b15ae2",
              "5455d2ecfc570fa7fc62449e6ca7a2b8e2e4c479700b4d164eb5a29e0d2e20774f9e2a6b6ce7d7",
            ),
            (
              false, "32c3318e1614df89d3072feba303cacd96da89df97105a660da7938a031bcf159cd70dd93efd0",
              "5455d2ecfc570fa7fc62449e6ca7a2b8e2e4c479700b4d164eb5a29e0d2e20774f9e2a6b6ce7d7",
            ),
            (
              false, "99c7d1020081ca392edca990c20ff94be1c7c4f31bd160c312f148bca854ad4e0e26c1cd57830",
              "5455d2ecfc570fa7fc62449e6ca7a2b8e2e4c479700b4d164eb5a29e0d2e20774f9e2a6b6ce7d7",
            ),
          ],
          derivatives: [
            (
              false, "28d91ceb350bd57e1226096e6dde80edccb8c2a7bbe4c7a810ce4948c9337588b568e8ee3ccb07c9b2b78461d666650c6d9cc2ff8d29da15b5e072b95b6c14dd31f9bafffeab2a2529f4ff4d1",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "4abc1d97f18b29e8a3627da09a754f34bb17564ba1faedf7be92e5d65f6c81fd3fa375fb93b9fc3d042c44276da8e84190a872049d9918beafd0f75464fc02cfd8ad8e124eac9d8db7c60c99",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              false, "7c6267aa2086fdeebec0db2df90c803740420e7232e3bfb004e83957d71e8207e5fa43300850df6718c61bf87092ab0677e52d76a0f4ab27752feb54977f43f164acb97934eb6d4798a72b884",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              true, "fb9ecfa6f204be2fc9cd8e4fef32b0a9e0e985109d95d2c778bdcd03ee99383917e901e5f2f5b2b72b498cf4c08184993b0df59ad109f3169f2e2c52686cf74b86c25c8cc45069644e02fc4",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "7c6267aa2086fdeebec0db2df90c803740420e7232e3bfb004e83957d71e8207e5fa43300850df6718c61bf87092ab0677e52d76a0f4ab27752feb54977f43f164acb97934eb6d4798a72b884",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              true, "fb9ecfa6f204be2fc9cd8e4fef32b0a9e0e985109d95d2c778bdcd03ee99383917e901e5f2f5b2b72b498cf4c08184993b0df59ad109f3169f2e2c52686cf74b86c25c8cc45069644e02fc4",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "5d579324abb45d765804c8fc8c9cb3378f6a049c5a8aaa1cd252879b1e337ddf5647b76f48ea59ae2aee8bbf6861622af7078aae46ed493916065aa0bd213f521e1e19efec269d202750ae28",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "597966485f94b2dbbdefc9fa67a717dfa72101c58b68746237ec6d573ec52a1d01c3735fc51c8cbd135ddfdafacb6fdd0a8b908a07355c1cb9a92ec3296860d5a800e33300a25a3b690f2f424",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              false, "760b1a6634c70ae74ff228ed3422c434d87f4489a82d7c1214e0d0efcf9195e7ee7e04ed8ec0648e0cdd4555cf360cf2bead6dc64dc707a7c3d8b5db1d72e98d6f6bcd5489553ab407323aa44",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              false, "997b98e5cbfbb5472502d5be6d2f4c80f0ecd656ea84b6d6ecb19e37dfcdac3efc42e386bfae5bf1c20743a861e6c54c93f5350cef28f6c0f48f1b26784569324b7b95eeb2621616068226fc4",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              true, "241a3abb6a7be1d955d0ed91a74c89704af1c6227b839bb6bb9f8b889b866c2eef740bd2fec23c1494279c4b5dbc1ec06b316d875a7cfb41cce924afbf77ad3211da762b0459f605a369edb6c",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              false, "59794d771482112aa114e54faf0f8903b7223185617444875731c9b0296e55abf8281d025bff1f89aafe10c2ceb47ece46dc563cceff2f33c4a8f4f24739fff7457dfa81427ef543958728980",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              true, "241a3abb6a7be1d955d0ed91a74c89704af1c6227b839bb6bb9f8b889b866c2eef740bd2fec23c1494279c4b5dbc1ec06b316d875a7cfb41cce924afbf77ad3211da762b0459f605a369edb6c",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              false, "59794d771482112aa114e54faf0f8903b7223185617444875731c9b0296e55abf8281d025bff1f89aafe10c2ceb47ece46dc563cceff2f33c4a8f4f24739fff7457dfa81427ef543958728980",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              false, "9b325862d322e1c1819f03e5cab1320190938794ed377c02846f3d135c6f6975ea811d53a4ea2f653b3cef79c84deb9d70520d09c67537e1928df20d95c16257654a34448ed907af22220020",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              false, "13dcc53c44b9d8b7f7f7d4db654bd4071b29b0252f09eb33fd8a16c122c5ba1a5e43550590665f46c179f250860a68a7ad1f71262aaf05ba8acfbf99520c5a02790bb5b0c658d3f66b7e68a8f4",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              false, "4d10f19301c6677ca0a01ec5b044153300da4aecef08dcd7680b16ac41f16f8ce1d96c8c06a4ad5021a0100d95bd0f092baf767e60980af76124",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (
              true, "4d10f19301c6677ca0a01ec5b044153300da4aecef08dcd7680b16ac41f16f8ce1d96c8c06a4ad5021a0100d95bd0f092baf767e60980af76124",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "27341e7b228f949c66e80ad5015710c976e79c316e6218f55d859c12384742e3dcb2c86f7af00f77a4c0726c7944aae34457fda76309cb614ff98",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (
              true, "27341e7b228f949c66e80ad5015710c976e79c316e6218f55d859c12384742e3dcb2c86f7af00f77a4c0726c7944aae34457fda76309cb614ff98",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "47127f11d71a6076cc6edc55fd8c7093bec54deab15dad1c42d9a4550785cca0090f09081d964c0eec103dad98a6cbccd0b0fa65f6e247c61e208",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (
              false, "47127f11d71a6076cc6edc55fd8c7093bec54deab15dad1c42d9a4550785cca0090f09081d964c0eec103dad98a6cbccd0b0fa65f6e247c61e208",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "73aa82f78e0b666118e2889261e4a3bfdaa5a77658cff973bb18b61e9aa9b33b6e89c5ebf610f7b7bbfd099037d1c51760893503c53cddca820",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (
              false, "73aa82f78e0b666118e2889261e4a3bfdaa5a77658cff973bb18b61e9aa9b33b6e89c5ebf610f7b7bbfd099037d1c51760893503c53cddca820",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (
              false, "a088b5fc309c6a010aedc3298d93cebbc341e8ec476c2b9ea9f9f243e8757b61cd52f77608a8",
              "2eda58bc8c305e07fdfdb4580379934a4529c27c5ab0f1eff2d6afad23c44aecf357dead75645b",
            ),
            (
              true, "a088b5fc309c6a010aedc3298d93cebbc341e8ec476c2b9ea9f9f243e8757b61cd52f77608a8",
              "2eda58bc8c305e07fdfdb4580379934a4529c27c5ab0f1eff2d6afad23c44aecf357dead75645b",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "6f4a593a56e5b9bcc5659b0b53048c2b8691c6de61aac4afd227d1e88e56ad9723aa9abaf8b04",
              "8c8f0a35a4911a17f9f91d080a6cb9decf7d47751012d5cfd8840f076b4ce0c6da079c08602d11",
            ),
            (
              true, "6f4a593a56e5b9bcc5659b0b53048c2b8691c6de61aac4afd227d1e88e56ad9723aa9abaf8b04",
              "8c8f0a35a4911a17f9f91d080a6cb9decf7d47751012d5cfd8840f076b4ce0c6da079c08602d11",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "630ce085f0d6c5319b3e8b54bfbf0839b401cb1ba70d7aa00c06a616759fa5cf0dc7ccf471829",
              "8c8f0a35a4911a17f9f91d080a6cb9decf7d47751012d5cfd8840f076b4ce0c6da079c08602d11",
            ),
            (
              false, "630ce085f0d6c5319b3e8b54bfbf0839b401cb1ba70d7aa00c06a616759fa5cf0dc7ccf471829",
              "8c8f0a35a4911a17f9f91d080a6cb9decf7d47751012d5cfd8840f076b4ce0c6da079c08602d11",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "33af0cb219d4a1902bf4ac7f0bd4a053dbd007a6a15368efd526ea17f3146093d023b096267e",
              "2eda58bc8c305e07fdfdb4580379934a4529c27c5ab0f1eff2d6afad23c44aecf357dead75645b",
            ),
            (
              false, "33af0cb219d4a1902bf4ac7f0bd4a053dbd007a6a15368efd526ea17f3146093d023b096267e",
              "2eda58bc8c305e07fdfdb4580379934a4529c27c5ab0f1eff2d6afad23c44aecf357dead75645b",
            ),
            (false, "0", "1"),
          ],
          ricci: [
            (
              false, "47127f11d71a6076cc6edc55fd8c7093bec54deab15dad1c42d9a4550785cca0090f09081d964c0eec103dad98a6cbccd0b0fa65f6e247c61e208",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (
              false, "4d10f19301c6677ca0a01ec5b044153300da4aecef08dcd7680b16ac41f16f8ce1d96c8c06a4ad5021a0100d95bd0f092baf767e60980af76124",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (
              false, "73aa82f78e0b666118e2889261e4a3bfdaa5a77658cff973bb18b61e9aa9b33b6e89c5ebf610f7b7bbfd099037d1c51760893503c53cddca820",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (
              false, "27341e7b228f949c66e80ad5015710c976e79c316e6218f55d859c12384742e3dcb2c86f7af00f77a4c0726c7944aae34457fda76309cb614ff98",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
          ],
        },
        {
          alpha: (true, "3", "5"),
          scalar: (
            false, "9b4a65a2f4f629b5fd593054edda648ebc3ef2c5987006bdf7084e9745ecdb927281768c81678390",
            "1faf52ce86177220c50cc977a872b5b1eea371ef499dfdbf2e4751188cbd6666cdb3aaa4ea817549",
          ),
          lower: [
            (
              true, "a685675273cc38e387d2fedd8c5c12c3a993b76a92fef4e37d273719c60bf859b188679632d",
              "a34105ccbaeb98820b029b24b1b63b29e3ee9aa8ebff3511abcb5b79f50e552c7d83333f2dd8",
            ),
            (
              true, "12a885d06650e24c852345b8efeec6a9716e8b7e2e4a3678ac9b8b4a545c1b06bbe7e5e52e9",
              "51a082e65d75cc4105814d9258db1d94f1f74d5475ff9a88d5e5adbcfa872a963ec1999f96ec",
            ),
            (
              true, "92e3b8638829f12599ba5189fed6a62a7b67c7adc3b4e4f8d49c5ff87ce2259f2eb4a0ba3d",
              "51a082e65d75cc4105814d9258db1d94f1f74d5475ff9a88d5e5adbcfa872a963ec1999f96ec",
            ),
            (
              false, "2173956ef7c191a2870d951cc5295abd47450e14cda463cd110fd8963c59ef6eff2c6624137",
              "51a082e65d75cc4105814d9258db1d94f1f74d5475ff9a88d5e5adbcfa872a963ec1999f96ec",
            ),
            (
              true, "92e3b8638829f12599ba5189fed6a62a7b67c7adc3b4e4f8d49c5ff87ce2259f2eb4a0ba3d",
              "51a082e65d75cc4105814d9258db1d94f1f74d5475ff9a88d5e5adbcfa872a963ec1999f96ec",
            ),
            (
              false, "2173956ef7c191a2870d951cc5295abd47450e14cda463cd110fd8963c59ef6eff2c6624137",
              "51a082e65d75cc4105814d9258db1d94f1f74d5475ff9a88d5e5adbcfa872a963ec1999f96ec",
            ),
            (
              false, "a045bab59372e685d193a6f31de4c83a502500ba8e228e6f8dc9f34cd55f2f7c161d2bd233",
              "51a082e65d75cc4105814d9258db1d94f1f74d5475ff9a88d5e5adbcfa872a963ec1999f96ec",
            ),
            (
              false, "7c2913c95536973509fd4c6864ac9258dd835a483500ced319763619f7958a838bd6608c003",
              "23b63944c8e3895c726891f006dfdcf129dc31d4f39fd39bdd947c02ad9b22a1bb74b335d2074",
            ),
          ],
          lower_first: [
            (
              false, "b9d309763c99554fba93fd0a05f16a6eeb02d8f946d09a488c47a097778b617871924e085e0861a33ee61e7cdd00cf2d26ded2b565e01a5",
              "4f0f9863a1d4c69bce1349d08cacbe614cefa71f8218663b0c63b01a3cda85a41ee61ce6355a237a8819f198e90a0e5889a961f447e42508",
            ),
            (
              true, "182f8ee93d6338742fbbab4502afc56a79a75eb21bde558ea74ab84cbaaa252ffb9ac8f0c33679a85d3b22800c6f82773384114fc40f03d",
              "2787cc31d0ea634de709a4e846565f30a677d38fc10c331d8631d80d1e6d42d20f730e731aad11bd440cf8cc7485072c44d4b0fa23f21284",
            ),
            (
              false, "ce9e8feab9f504b962726187390fab30e8902fd2e345b7119400d3314c3cf5775fb7380be41d827f565e855ccb3bfdd1af059549166225",
              "9e1f30c743a98d379c2693a119597cc299df4e3f0430cc7618c7603479b50b483dcc39cc6ab446f51033e331d2141cb11352c3e88fc84a1",
            ),
            (
              true, "4b0f7b151db6e6a06e63f88227f50ce317a0d5368e86e3db6e801f0da443f5c192c5ca16610de11ade1843fe7a612ba1a6046c5040694",
              "e5fed29633df590b11ac79a481f686ec82b92bfe91bb57f19867d1c0b107563a886edfb4f84c0a1ea334333131919e18d649d723b9dd83",
            ),
            (
              false, "ce9e8feab9f504b962726187390fab30e8902fd2e345b7119400d3314c3cf5775fb7380be41d827f565e855ccb3bfdd1af059549166225",
              "9e1f30c743a98d379c2693a119597cc299df4e3f0430cc7618c7603479b50b483dcc39cc6ab446f51033e331d2141cb11352c3e88fc84a1",
            ),
            (
              true, "4b0f7b151db6e6a06e63f88227f50ce317a0d5368e86e3db6e801f0da443f5c192c5ca16610de11ade1843fe7a612ba1a6046c5040694",
              "e5fed29633df590b11ac79a481f686ec82b92bfe91bb57f19867d1c0b107563a886edfb4f84c0a1ea334333131919e18d649d723b9dd83",
            ),
            (
              true, "2e36e7069a42f23ccad7bdb0c524bc98d7f972d76361cac72a8c9770f6b74865d0b85652849b4df793fc94c12d8be7855b5732e88e08c",
              "e5fed29633df590b11ac79a481f686ec82b92bfe91bb57f19867d1c0b107563a886edfb4f84c0a1ea334333131919e18d649d723b9dd83",
            ),
            (
              false, "ef42b69ff8ba72c1a034f4406488507fdfa325cda89eba016c6af0eaba68e1bc0ea7dad5f101555df749e40ee23245b3519763ba16833f",
              "13c3e618e87531a6f384d274232b2f98533be9c7e086198ec318ec068f36a16907b987398d5688dea2067c663a428396226a587d11f90942",
            ),
            (
              false, "3d3337be9dba0057d941c1ded0a8784342c41ea60086bb26570939b4c6f7b477e85a854f16556e35221e9a84bc44f21aaf1c552f6d3f8f5",
              "2787cc31d0ea634de709a4e846565f30a677d38fc10c331d8631d80d1e6d42d20f730e731aad11bd440cf8cc7485072c44d4b0fa23f21284",
            ),
            (
              false, "2f692f4fa53ebcc245830ae3a1c5247b804740a9c2989d11bbbfa2cef6090e0c47547618577fa1f5b5341c1f44eb9eacf5fabd10c600b0",
              "9e1f30c743a98d379c2693a119597cc299df4e3f0430cc7618c7603479b50b483dcc39cc6ab446f51033e331d2141cb11352c3e88fc84a1",
            ),
            (
              true, "d3e09458127aab2b5ac39466e5e1e17da79cc9432677eaff42e84bd9f0ea9e393eda4ab67647cca16e6f41704b5181a2c94a37a89e8289",
              "13c3e618e87531a6f384d274232b2f98533be9c7e086198ec318ec068f36a16907b987398d5688dea2067c663a428396226a587d11f90942",
            ),
            (
              false, "d7ce62193bd47c680f3e93fbfc2d162d5a59c3a4af649dfc412db1af1ec816c6675cff976dbc652a2e36d5b40a595dcede486e9b476ad1",
              "13c3e618e87531a6f384d274232b2f98533be9c7e086198ec318ec068f36a16907b987398d5688dea2067c663a428396226a587d11f90942",
            ),
            (
              true, "d3e09458127aab2b5ac39466e5e1e17da79cc9432677eaff42e84bd9f0ea9e393eda4ab67647cca16e6f41704b5181a2c94a37a89e8289",
              "13c3e618e87531a6f384d274232b2f98533be9c7e086198ec318ec068f36a16907b987398d5688dea2067c663a428396226a587d11f90942",
            ),
            (
              false, "d7ce62193bd47c680f3e93fbfc2d162d5a59c3a4af649dfc412db1af1ec816c6675cff976dbc652a2e36d5b40a595dcede486e9b476ad1",
              "13c3e618e87531a6f384d274232b2f98533be9c7e086198ec318ec068f36a16907b987398d5688dea2067c663a428396226a587d11f90942",
            ),
            (
              true, "44560780b199b7537b00c73bf8d24c43bf797997a62b35da727634ad5b70519b3f53cdd482debe5eb43e3232a1d63005dab17b131666a5",
              "13c3e618e87531a6f384d274232b2f98533be9c7e086198ec318ec068f36a16907b987398d5688dea2067c663a428396226a587d11f90942",
            ),
            (
              false, "213a4556ca11cf1686616df0ee15b14c1f52ee1a73b45743ce6e384a4a3d5cebd3d9222e1c6c2b1e910db3c9664b5099cab64441a3b6cdb",
              "13c3e618e87531a6f384d274232b2f98533be9c7e086198ec318ec068f36a16907b987398d5688dea2067c663a428396226a587d11f90942",
            ),
          ],
          coefficients: [
            (
              true, "38b009f4cab6b5f6c4d641459d92707b02bf724677b6d10a527bde530937e0489eedba2b813a53",
              "a8aba5d9f8ae1f4ff8c4893cd94f4571c5c988f2e0169a2c9d6b453c1a5c40ee9f3c54d6d9cfae",
            ),
            (
              true, "225e5abb6314badbf113761051a910431e8a8091dbb87d5745cab2a5026eafeb262881d719490d",
              "a8aba5d9f8ae1f4ff8c4893cd94f4571c5c988f2e0169a2c9d6b453c1a5c40ee9f3c54d6d9cfae",
            ),
            (
              true, "12b74ae193f91ff34de841feb924144a29c6d329c7dc2b17b1c10df24f90e18b32214f8a7bd46",
              "5455d2ecfc570fa7fc62449e6ca7a2b8e2e4c479700b4d164eb5a29e0d2e20774f9e2a6b6ce7d7",
            ),
            (
              false, "16151bb9dc81677250a0e9a8bf1725f6f30114f9a5f0604af120480b486098918b8c11e0596441",
              "5455d2ecfc570fa7fc62449e6ca7a2b8e2e4c479700b4d164eb5a29e0d2e20774f9e2a6b6ce7d7",
            ),
            (
              true, "12b74ae193f91ff34de841feb924144a29c6d329c7dc2b17b1c10df24f90e18b32214f8a7bd46",
              "5455d2ecfc570fa7fc62449e6ca7a2b8e2e4c479700b4d164eb5a29e0d2e20774f9e2a6b6ce7d7",
            ),
            (
              false, "16151bb9dc81677250a0e9a8bf1725f6f30114f9a5f0604af120480b486098918b8c11e0596441",
              "5455d2ecfc570fa7fc62449e6ca7a2b8e2e4c479700b4d164eb5a29e0d2e20774f9e2a6b6ce7d7",
            ),
            (
              false, "44362c40e33a3d0d72d884dbf1a831ed47ebde2a07435ed9a2d147d17054b65c4f3bbfd6f21b0",
              "5455d2ecfc570fa7fc62449e6ca7a2b8e2e4c479700b4d164eb5a29e0d2e20774f9e2a6b6ce7d7",
            ),
            (
              false, "c87569efd113b58c619ca238124cb72f1ff4de845e93b838da92566bd09e6d8aa4ae13df7d435",
              "5455d2ecfc570fa7fc62449e6ca7a2b8e2e4c479700b4d164eb5a29e0d2e20774f9e2a6b6ce7d7",
            ),
          ],
          derivatives: [
            (
              false, "46e0da9e18f75e8ee3d3d39e1c77d49ffd12e1bd0f09756711ad335e21f10c8a097b6591df8a1d81e936ba6aa9db71108e15c24a63d7d8c42e51a5c6b1003ecc52953fbb29ca94ec2e4a95f9b",
              "b7eae0e6293a5ffaad196803d59c4b1843e5d83cec8b8b06501d97ac280148deca5f8931cb6e600253533417a18034887d0eb60ba0dc09a2f2f1e968b69833c96566a99c5832fc2a2ac6372cc",
            ),
            (
              true, "11eb2a3b616d0650c85499cfe9125c3ae5075f1cb4dd4e4c6beb2b64fb61236b42c5c2347749d2c9ff4e659df68b46742d4563dfbc218cd74bbd9a992b14da1dfa6bbd46156cb0e85b2f959a61",
              "39796647ece23dfe5617f08132c0d7779537d39309eb9b71f9093f65cc8066c59f3ddadf8f927e00ba0a00476278106aa71498e3a244c302ebeb98f0b90f902eefb01500db8feecd2d5df13dfc",
            ),
            (
              false, "5d74abf6649a32406f7acf91e8eb5422a8bfceea1b0f1ad9698c102b5480d12c6dab97f180cec05595713c87e880920a88941f337c2e41eabe371dd737d167b6645f1e7c07314835aca4eb30d",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              true, "cced34a499665bdcf399f5c805618d0e3f3e493999399abe87e69f8645d4ff7af3a3747bcb61a5509b9031cc79ff74fd21b9c2fa9d87877bd658468e90d98cd4e13e43a63dafe0c1ae72440e",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "5d74abf6649a32406f7acf91e8eb5422a8bfceea1b0f1ad9698c102b5480d12c6dab97f180cec05595713c87e880920a88941f337c2e41eabe371dd737d167b6645f1e7c07314835aca4eb30d",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              true, "cced34a499665bdcf399f5c805618d0e3f3e493999399abe87e69f8645d4ff7af3a3747bcb61a5509b9031cc79ff74fd21b9c2fa9d87877bd658468e90d98cd4e13e43a63dafe0c1ae72440e",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "1a4a270c212f37babe7bbee7ee2e5f84ad30c0d213a6813d4925200262c2eda0073fab9158f87e44934dbc85e4c67fcefd5e08c9e86a46df54579d4e8989a8ba371bd8216d14944261a007fe",
              "2dfab8398a4e97feab465a00f56712c610f9760f3b22e2c1940765eb0a005237b297e24c72db980094d4cd05e8600d221f43ad82e8370268bcbc7a5a2da60cf25959aa67160cbf0a8ab18dcb3",
            ),
            (
              false, "631f0c612f6867a4fc266df9b9ee54c0052e1a0eacd7120885f0732de34f63f0509beb03328ff7b209387bb0f703db4d32fdd6ff5e0bf71beba6ceaef4c0c4038103176542a096a0720bcf0c7",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              false, "78532039eb6da0d8a670e8ab1c399c9bc74cbc43bfa83f0a2a7025291e0380964dee4dfc08a3f150cbe91df290222c52b2b15374657c97363c029971678208f8086a15eb3eac328e67d719a0b",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              false, "6526e7401d2a51f35f7515034593c6a29ce9f7a21504c48e90b126efac4d956f2143d57bed528170c83492a1ac010cc362473c54844a888dcf4e5bedee059ee6a76497ac7c480f23d86eef7f0",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              true, "338a5b89f9f1e0a21ad9c4ca4f6b1a493d16ff01832299b828a7e85b40f684db152380507321cd38fa884f0d7ad4dcf9d9c6c85a1a442695f390d91c6cdee8c115fc475f24f8ed981115f98e4",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              false, "4e97fe32df678dc550d9ebcc042157253e62c6ddbce8615095ce6a3f36b075177170c9988d68aec3470940011cd5d02785c79cbc002172391432c25f214ade0434bbf4cc74df43d31bd6982ad",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              true, "338a5b89f9f1e0a21ad9c4ca4f6b1a493d16ff01832299b828a7e85b40f684db152380507321cd38fa884f0d7ad4dcf9d9c6c85a1a442695f390d91c6cdee8c115fc475f24f8ed981115f98e4",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              false, "4e97fe32df678dc550d9ebcc042157253e62c6ddbce8615095ce6a3f36b075177170c9988d68aec3470940011cd5d02785c79cbc002172391432c25f214ade0434bbf4cc74df43d31bd6982ad",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              true, "94cbbb6dd34adf553ee88bf88cca4b04007d499de40ba12803257e81f0ae9abd8887e7e8436668b5bd80de415132c919e5aa7bd7c918382d2b0bf24b89340527e8b36084c78f18e0641e618",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
            (
              false, "ecd3da5f6ce515fa4db290dff95d2541d4066ff65bc0392f1d02beb37d3089c2d9ecca9a4841e28311973bf9bedb7a04dbb108dbd416fb1696712b20cc754e9918cbd973c9de103519ea0b873",
              "e5e5991fb388f7f9585fc204cb035dde54df4e4c27ae6dc7e424fd9732019b167cf76b7e3e49f802e828011d89e041aa9c52638e89130c0bafae63c2e43e40bbbec054036e3fbb34b577c4f7f",
            ),
          ],
          riemann: [
            (false, "0", "1"),
            (
              true, "117055ae6be05f356e97a67129d2f8e2cfce5ddffec065d59220816cd48dbb253f7326ef279fb44ed2caaffb433b260f4703a79c386efef9c5a90",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (
              false, "117055ae6be05f356e97a67129d2f8e2cfce5ddffec065d59220816cd48dbb253f7326ef279fb44ed2caaffb433b260f4703a79c386efef9c5a90",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "23fdad329649172c43b69ffe1adc63aa397701493908a6e3ccffb432f36ffaa667472942c927f7d60e5e21d2ad894c5c2d045b1dfe0113e9b9534",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (
              true, "23fdad329649172c43b69ffe1adc63aa397701493908a6e3ccffb432f36ffaa667472942c927f7d60e5e21d2ad894c5c2d045b1dfe0113e9b9534",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "53b0d25910180be3faaf78b858a16ec8ec05a6f72f46a7844b80d3087a6c063d6854a9685958a98c8a0c7acf5141edd9a06185f89dfe12adb3ec0",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (
              false, "53b0d25910180be3faaf78b858a16ec8ec05a6f72f46a7844b80d3087a6c063d6854a9685958a98c8a0c7acf5141edd9a06185f89dfe12adb3ec0",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "d12f1183352042405a6870d61309c335f9b5ed8a628a8018f5ae8b82f094ddfacc419ec532b7a71886cac03fa1726e3cba93969562abb281a18c",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (
              true, "d12f1183352042405a6870d61309c335f9b5ed8a628a8018f5ae8b82f094ddfacc419ec532b7a71886cac03fa1726e3cba93969562abb281a18c",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (false, "0", "1"),
          ],
          lowered: [
            (false, "0", "1"),
            (
              true, "a088b5fc309c6a010aedc3298d93cebbc341e8ec476c2b9ea9f9f243e8757b61cd52f77608a8",
              "2eda58bc8c305e07fdfdb4580379934a4529c27c5ab0f1eff2d6afad23c44aecf357dead75645b",
            ),
            (
              false, "a088b5fc309c6a010aedc3298d93cebbc341e8ec476c2b9ea9f9f243e8757b61cd52f77608a8",
              "2eda58bc8c305e07fdfdb4580379934a4529c27c5ab0f1eff2d6afad23c44aecf357dead75645b",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "630ce085f0d6c5319b3e8b54bfbf0839b401cb1ba70d7aa00c06a616759fa5cf0dc7ccf471829",
              "8c8f0a35a4911a17f9f91d080a6cb9decf7d47751012d5cfd8840f076b4ce0c6da079c08602d11",
            ),
            (
              true, "630ce085f0d6c5319b3e8b54bfbf0839b401cb1ba70d7aa00c06a616759fa5cf0dc7ccf471829",
              "8c8f0a35a4911a17f9f91d080a6cb9decf7d47751012d5cfd8840f076b4ce0c6da079c08602d11",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              true, "6f4a593a56e5b9bcc5659b0b53048c2b8691c6de61aac4afd227d1e88e56ad9723aa9abaf8b04",
              "8c8f0a35a4911a17f9f91d080a6cb9decf7d47751012d5cfd8840f076b4ce0c6da079c08602d11",
            ),
            (
              false, "6f4a593a56e5b9bcc5659b0b53048c2b8691c6de61aac4afd227d1e88e56ad9723aa9abaf8b04",
              "8c8f0a35a4911a17f9f91d080a6cb9decf7d47751012d5cfd8840f076b4ce0c6da079c08602d11",
            ),
            (false, "0", "1"),
            (false, "0", "1"),
            (
              false, "33af0cb219d4a1902bf4ac7f0bd4a053dbd007a6a15368efd526ea17f3146093d023b096267e",
              "2eda58bc8c305e07fdfdb4580379934a4529c27c5ab0f1eff2d6afad23c44aecf357dead75645b",
            ),
            (
              true, "33af0cb219d4a1902bf4ac7f0bd4a053dbd007a6a15368efd526ea17f3146093d023b096267e",
              "2eda58bc8c305e07fdfdb4580379934a4529c27c5ab0f1eff2d6afad23c44aecf357dead75645b",
            ),
            (false, "0", "1"),
          ],
          ricci: [
            (
              false, "53b0d25910180be3faaf78b858a16ec8ec05a6f72f46a7844b80d3087a6c063d6854a9685958a98c8a0c7acf5141edd9a06185f89dfe12adb3ec0",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (
              true, "117055ae6be05f356e97a67129d2f8e2cfce5ddffec065d59220816cd48dbb253f7326ef279fb44ed2caaffb433b260f4703a79c386efef9c5a90",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (
              true, "d12f1183352042405a6870d61309c335f9b5ed8a628a8018f5ae8b82f094ddfacc419ec532b7a71886cac03fa1726e3cba93969562abb281a18c",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
            (
              false, "23fdad329649172c43b69ffe1adc63aa397701493908a6e3ccffb432f36ffaa667472942c927f7d60e5e21d2ad894c5c2d045b1dfe0113e9b9534",
              "9e3d348f005785f0e4d9a8a19b93930fc431b70c17e32a4b58a3dec1519e6da10571e10a86d8260ea136b52a2fb728ce757abbf5ce9f7586bdb37",
            ),
          ],
        },
      ],
    },
  ]
}

///|
fn ir_family(f : IRFinite) -> @infogeom.Family {
  let polynomials = f.polynomials.map(fn(terms) {
    @polynomial.polynomial(
      @oracle.nat(2),
      @oracle.chain(
        terms.map(fn(t) {
          @polynomial.Term::{
            coefficient: ir_q(t.coefficient),
            exponents: @oracle.chain(t.exponents.map(@oracle.nat)),
          }
        }),
      ),
    ).unwrap()
  })
  @infogeom.family(@oracle.nat(2), @oracle.chain(polynomials)).unwrap()
}

///|
test "independent Sympy nonclosedform finite family jets and alpha curvature" {
  for f in ir_finites() {
    let family = ir_family(f)
    let point = @infogeom.at(family, ir_values(f.point)).unwrap()
    let model = @infogeom.local_model(point)
    assert_eq(@infogeom.dimension(model), @oracle.nat(2), msg=f.name)
    let jets = @oracle.array(@infogeom.jets(model))
    let thirds = @oracle.array(@infogeom.third_derivatives(point))
    assert_eq(jets.length(), f.jets.length(), msg=f.name)
    assert_eq(thirds.length(), f.jets.length(), msg=f.name)
    for i in 0..<f.jets.length() {
      assert_eq(jets[i].probability, ir_q(f.jets[i].p), msg=f.name)
      assert_eq(jets[i].gradient, ir_values(f.jets[i].gradient), msg=f.name)
      assert_eq(
        ir_flat_matrix(jets[i].hessian),
        ir_values(f.jets[i].hessian),
        msg=f.name,
      )
      assert_eq(
        ir_flat_first(thirds[i]),
        ir_values(f.jets[i].third),
        msg=f.name,
      )
    }
    assert_eq(@infogeom.fisher(model), ir_matrix(f.metric, 2), msg=f.name)
    assert_eq(
      ir_flat_matrix(@infogeom.scores(model).unwrap()),
      ir_values(f.scores),
      msg=f.name,
    )
    assert_eq(
      ir_flat_first(@infogeom.metric_first(model).unwrap()),
      ir_values(f.first),
      msg=f.name,
    )
    assert_eq(
      ir_flat_second(@infogeom.metric_second(point).unwrap()),
      ir_values(f.second),
      msg=f.name,
    )
    assert_eq(
      ir_flat_first(@infogeom.cubic(model).unwrap()),
      ir_values(f.cubic),
      msg=f.name,
    )
    assert_eq(
      @tensor.entries(cubic_tensor(model).unwrap()),
      ir_values(f.cubic),
      msg=f.name,
    )
    assert_eq(
      @infogeom.natural_gradient(
        model,
        @oracle.chain([@oracle.rational(2, 3), @oracle.rational(-1, 2)]),
      ).unwrap(),
      ir_values(f.natural_gradient),
      msg=f.name,
    )
    let jacobian = @matrix.matrix(
      @oracle.nat(1),
      @oracle.chain([
        @oracle.chain([@oracle.rational(1, 2)]),
        @oracle.chain([@oracle.rational(-2, 3)]),
      ]),
    ).unwrap()
    assert_eq(
      @tensor.entries(pullback_cubic(model, jacobian).unwrap()),
      @core.Cons(ir_q(f.cubic_pullback), @core.Nil),
      msg=f.name,
    )
    for index, a in f.alphas {
      let label = f.name + " alpha#" + index.to_string()
      let alpha = ir_q(a.alpha)
      let actual = alpha_geometry(point, alpha).unwrap()
      let three = @oracle.chain([2, 2, 2].map(@oracle.nat))
      let four = @oracle.chain([2, 2, 2, 2].map(@oracle.nat))
      assert_eq(@tensor.shape(alpha_coefficients(actual)), three, msg=label)
      assert_eq(@tensor.shape(alpha_derivatives(actual)), four, msg=label)
      assert_eq(@tensor.shape(alpha_riemann(actual)), four, msg=label)
      assert_eq(@tensor.shape(alpha_lowered_riemann(actual)), four, msg=label)
      assert_eq(
        ir_flat_first(@infogeom.alpha_lower(model, alpha).unwrap()),
        ir_values(a.lower),
        msg=label,
      )
      assert_eq(
        ir_flat_second(@infogeom.alpha_lower_first(point, alpha).unwrap()),
        ir_values(a.lower_first),
        msg=label,
      )
      assert_eq(
        @tensor.entries(alpha_coefficients(actual)),
        ir_values(a.coefficients),
        msg=label,
      )
      assert_eq(
        @tensor.entries(alpha_raised(model, alpha).unwrap()),
        ir_values(a.coefficients),
        msg=label,
      )
      assert_eq(
        @tensor.entries(alpha_derivatives(actual)),
        ir_values(a.derivatives),
        msg=label,
      )
      assert_eq(
        @tensor.entries(alpha_riemann(actual)),
        ir_values(a.riemann),
        msg=label,
      )
      assert_eq(
        @tensor.entries(alpha_lowered_riemann(actual)),
        ir_values(a.lowered),
        msg=label,
      )
      assert_eq(
        ir_flat_matrix(alpha_ricci(actual)),
        ir_values(a.ricci),
        msg=label,
      )
      assert_eq(alpha_scalar(actual), ir_q(a.scalar), msg=label)
      if index == 0 {
        let ordinary = curvature(point).unwrap()
        let upper = @core.fold_left(@riemann.riemann(ordinary), @core.Nil, fn(
          result,
          tensor,
        ) {
          @core.fold_left(tensor, result, fn(result, matrix) {
            @core.fold_left(matrix, result, @core.append)
          })
        })
        assert_eq(upper, ir_values(a.riemann), msg=label)
        assert_eq(
          scalar_by_contraction(ordinary).unwrap(),
          ir_q(a.scalar),
          msg=label,
        )
      }
    }
  }
}
