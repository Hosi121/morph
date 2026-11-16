# 検証する主張の台帳

[ドキュメント](../README.md) / [探索・改善記録](README.md)

formal-methods-reconcilerの手順で、期待する性質・機械検査・信頼境界を分ける。
源となる契約は「純記号の制約、厳密な結果、公開APIの意味を維持する」というユーザー指示。

| ID | 主張 | 検査 | 到達範囲 |
| --- | --- | --- | --- |
| CIR-1 | 定義CNFは元のBool式のassertと充足可能性が一致 | 全小gate割当て、生成式、独立の直接評価 | 有限モデルの検査。変換器全体の帰納的形式証明なし |
| CIR-2 | 入力と補助変数が衝突しない | 疎なラベルを持つ式、共有式と否定の矛盾 | opaque Encodingとfresh規則を信頼 |
| CIR-3 | 同じ幅の加算回路が同じ出力を返す | miterのUNSAT、RUP検査、Bool側の整数oracle | 個別の有限幅に対する等価性証拠 |
| CIR-4 | 壊れた最適化は検査に落ちる | ANDをORへ変えたmiterの反例を元の式で再評価 | 陽性・陰性のsanity case |
| SAT-1 | RUP受理は探索とは別に検査する | 独立レビュー、偽造列、整数固定点oracle | checker自体の形式証明なし |
| CDCL-INPUT-1 | 単調な入力節追加後もモデルと最終RUPを元の増強CNFへ結ぶ | 独立真理値表・追加/backjump/active watchの反例・入力節を除いた反証の拒否 | 有限の入力・スケジュール照合。節削除・仮定のpush/popは未実装 |
| PREFIX-BOOL-1 | 原子観測の一様性を任意深さのBoolean式へ伝える | Lean known_is_uniform、壊したAND/ORの拒否、source lock | 原子観測の健全性が明示的な仮定。係数分解・射影・CAD被覆の証明ではない |
| CAD-PRUNE-1 | 短い葉を一点の真偽から受理しない | 係数の元式への再束縛、親族の符号再検査、16入力の独立Z3/完全CAD照合、偽造証拠検査 | 有限の実行検査と人手レビュー。全CAD checkerの形式証明ではない |
| NAT-1 | 大きなNatラベルでも変換を開始できる | ID65535の単一unit節、JS/Wasm/native回帰、Nat変換100000まで | from_natを末尾再帰化して全3backendで回帰を解消。任意の大きさに対する資源上限の証明ではない |
| PURE-1 | 核に数値型・配列・可変状態・FFIが混入しない | Pythonソースゲートとコンパイラの警告禁止 | 保守的な字句検査であり、コンパイラ証明ではない |
| SYN-1 | NAND選択CNFは指定上限内の回路を表す | 2入力全16関数×0〜5gate、CNFを使わない全プログラム列挙との照合 | 有限問題の符号化検査。一般の入力数・gate数に対する形式証明なし |
| SYN-2 | 合成結果は元の関数を計算する | model検査→selector復号→全真理値表の直接評価 | 全行を列挙できる問題に限定 |
| SYN-3 | 下限証拠と上限の取り違えを拒否する | XORの3gate不可能証拠を4gate問題へ流用すると拒否 | 個別CNFに対するRUP受理。gate最小化と実時間最小化は異なる |
| RUN-1 | 同じbitのblockではcarry/borrowが一桁後に安定する | 各操作の全Bool条件、Leanのcarry/borrow_stabilizes | 局所モデルの定理。全run算術の帰納的証明とは別 |
| RUN-2 | 圧縮演算は通常の自然数算術と一致する | 全16384小対、Python任意精度fixture、巨大値の圧縮恒等式 | 有限照合と恒等式のsanity check。一般のrun数に対する形式証明なし |
| BIN-ADD-1 | 加算とincrementが値を保存する | Leanの全称定理・source差分lock・MoonBit全小例 | 任意の有限列のモデルに対する帰納的証明。MoonBitへの翻訳は手動対応 |
| NAT-2 | 構造的半分化による旧Nat→二進数が値を保存する | Lean split_sound/fromNatByHalves_sound | 任意の自然数の参照モデル。現在の経路はNAT-3。stack/メモリ上限を保証しない |
| CORE-HALF-1 | Natの商と余り、floor(n/2)を直接構成する | Lean halveNat_sound/halfNat_floor、0〜4096と200001の実行検査 | モデルは全称、実装への対応は手動レビューとsource lock |
| CORE-PREFIX-1 | replicate_ontoはreplicate→appendと同じ列を返す | Lean generic Chainの等式、100000 prefixとpair | 任意型のモデル定理。backendの速度・資源保証とは別 |
| PATH-1 | 代表的な直接往復を再導入しない | tools/audit_paths.pyと陽性/陰性のPython検査 | 字句ゲート。変数を介する経路やプログラム全体の到達可能性は証明しない |
| NAT-3 | 8進単位の変換が値・正規性を保存し商が減少する | Lean splitGrouped/lowBit/fromNatの各定理、三backend小値/境界oracle | 任意のNatのモデル。factory/globalを含めsource対応をlock、翻訳は手動レビュー |
| BIN-CMP-1 | 新しい比較は旧比較と一致し、canonical値の順序を返す | Lean protectedCompare_eq_reference/protectedCompare_sound、raw列全小対・20k bit | 旧比較との一致は全有限raw列、数値順序はcanonicalを前提 |
| BIN-TABLE-1 | 有界積・差表の結果と外域fallbackが正しい | 65536 byte対、64〜2048bit境界、生成物gate | 有限域の独立整数oracle。unbounded multiply/subtract全体の形式証明ではない |
| CORE-FOLD-1 | reverse-left fold、group4、有限prefixがright foldと一致 | Fold.leanの全称定理 | 任意型/state/stepのモデル。未採用の除算試作の値・速度・資源全体の証明とは別 |

定理の全入力の正しさ、固定幅の完全なBoolean検査、有限の生成例の一致を同一視しない。
