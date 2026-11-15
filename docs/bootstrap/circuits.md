# SATを基礎演算の検査へ使う

Boolean.Algebraへ同じ加算器プログラムを渡し、Boolとして実行する場合とExprの回路を作る場合を共有する。
minterm、propagate、multiplexerの3種類を用意し、整数算術の真理値表とも照合する。
固定幅語はlittle endian、繰り上がりを別出力に保持する。

Exprは変数・定数・否定・AND/OR/XOR・条件選択。Tseitinの定義節へ変換し、
同じ構造の式は一つの補助変数を共有する。否定はliteralの極性で表す。
補助変数の開始値を全入力変数より後ろに取り、疎な変数ラベルとの衝突を避ける。

二つの出力列のxorの和をassertするmiterを作る。
SATなら元の変数へmodelを戻し、Exprを直接再評価して反例を確認する。
UNSATなら既存DPLLの反証または新CDCLのRUP列を別のcheckerへ通す。
元の式・CNF変換・checkerの正しさを一括で形式証明したわけではない。

最初の検証：各gate形と否定引数、生成した複合式を全入力割当てで直接評価し、
入力を固定したCNFの充足可能性と比較した。異なる式を同じとする壊れた変形では反例が返る。
全加算器は全8入力、固定幅Bool加算は0..6bitの全入力と繰り上がりを整数算術と比較。
propagate/muxの0..5bitの語はCDCLのUNSATとRUP検査で等価性を確認した。
これは指定した有限の幅の証拠であり、任意幅の帰納的定理ではない。

`circuit.adder_miter(width,left,right)` がエンジンに依存しないCNFを生成する。
回路規模が小さいこととMoonBit上の実行速度は別に測定する。
