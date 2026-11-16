import Core

namespace Morph.Binary

inductive Chain where
  | nil
  | cons (bit : Bool) (rest : Chain)
  deriving Repr, DecidableEq

def bitValue (bit : Bool) : Nat := if bit then 1 else 0

def canonical : Chain → Prop
  | .nil => True
  | .cons bit rest => canonical rest ∧ (rest ≠ .nil ∨ bit = true)

def value : Chain → Nat
  | .nil => 0
  | .cons bit rest => bitValue bit + 2 * value rest

-- This is the eight-row MoonBit arithmetic primitive, expressed in Lean.
def fullAdder (a b carry : Bool) : Bool × Bool :=
  match a, b, carry with
  | false, false, false => (false, false)
  | false, false, true | false, true, false | true, false, false => (true, false)
  | true, true, true => (true, true)
  | _, _, _ => (false, true)

def increment : Chain → Chain
  | .nil => .cons true .nil
  | .cons false rest => .cons true rest
  | .cons true rest => .cons false (increment rest)

def add : Chain → Chain → Bool → Chain
  | .cons a xs, .cons b ys, carry =>
    let (sum, next) := fullAdder a b carry
    .cons sum (add xs ys next)
  | xs, .nil, false => xs
  | .nil, ys, false => ys
  | xs, .nil, true => increment xs
  | .nil, ys, true => increment ys

theorem fullAdder_sound (a b carry : Bool) :
    bitValue (fullAdder a b carry).1 + 2 * bitValue (fullAdder a b carry).2 =
      bitValue a + bitValue b + bitValue carry := by
  cases a <;> cases b <;> cases carry <;> decide

theorem increment_sound (xs : Chain) : value (increment xs) = value xs + 1 := by
  induction xs with
  | nil => rfl
  | cons bit rest ih =>
    cases bit <;> simp [increment, value, bitValue, ih] <;> omega

-- The statement quantifies over every finite pair of bit lists and both carries.
-- It does not require canonical input: high zero bits may occur as well.
theorem addition_sound (xs ys : Chain) (carry : Bool) :
    value (add xs ys carry) = value xs + value ys + bitValue carry := by
  induction xs generalizing ys carry with
  | nil =>
    cases ys <;> cases carry <;>
      simp [add, value, bitValue, increment_sound] <;> omega
  | cons a xs ih =>
    cases ys with
    | nil =>
      cases carry <;> simp [add, value, bitValue, increment_sound] <;> omega
    | cons b ys =>
      have hfalse := ih ys false
      have htrue := ih ys true
      cases a <;> cases b <;> cases carry <;>
        simp [add, fullAdder, value, bitValue] at * <;> omega

theorem carry_stabilizes (a b carry : Bool) :
    (fullAdder a b (fullAdder a b carry).2).2 = (fullAdder a b carry).2 := by
  cases a <;> cases b <;> cases carry <;> decide

def borrowStep (a b borrow : Bool) : Bool × Bool :=
  let (sum, carry) := fullAdder a (!b) (!borrow)
  (sum, !carry)

theorem borrow_stabilizes (a b borrow : Bool) :
    (borrowStep a b (borrowStep a b borrow).2).2 = (borrowStep a b borrow).2 := by
  cases a <;> cases b <;> cases borrow <;> decide

-- Reuse the checked Core helper rather than model a second halving algorithm.
def split (n : Nat) : Nat × Bool := Morph.Core.halveNat n

theorem split_sound (n : Nat) :
    2 * (split n).1 + bitValue (split n).2 = n := by
  simpa [split, bitValue, Morph.Core.remainderValue] using Morph.Core.halveNat_sound n

theorem split_lt {n : Nat} (positive : 0 < n) : (split n).1 < n := by
  have h := split_sound n
  have bound : bitValue (split n).2 ≤ 1 := by
    cases (split n).2 <;> decide
  omega

def fromNatByHalves (n : Nat) : Chain :=
  match n with
  | 0 => .nil
  | n + 1 =>
    let divided := split (n + 1)
    .cons divided.2 (fromNatByHalves divided.1)
termination_by n
decreasing_by exact split_lt (Nat.zero_lt_succ _)

theorem fromNatByHalves_sound (n : Nat) : value (fromNatByHalves n) = n := by
  induction n using Nat.strongRecOn with
  | ind n ih =>
    cases n with
    | zero => simp [fromNatByHalves, value]
    | succ n =>
      have h := ih (split (n + 1)).1 (split_lt (by omega))
      have hs := split_sound (n + 1)
      rw [fromNatByHalves]
      simp only [value]
      omega

abbrev GroupedSplit := Nat × Bool × Bool × Bool

def groupedRemainder (s : GroupedSplit) : Nat :=
  bitValue s.2.1 + 2 * bitValue s.2.2.1 + 4 * bitValue s.2.2.2

def splitGroupedLoop : Nat → Nat → GroupedSplit
  | 0, slow => (slow, false, false, false)
  | 1, slow + 1 => (slow, true, false, false)
  | 2, slow + 2 => (slow, false, true, false)
  | 3, slow + 3 => (slow, true, true, false)
  | 4, slow + 4 => (slow, false, false, true)
  | 5, slow + 5 => (slow, true, false, true)
  | 6, slow + 6 => (slow, false, true, true)
  | 7, slow + 7 => (slow, true, true, true)
  | fast + 8, slow + 7 => splitGroupedLoop fast slow
  | _, _ => (0, false, false, false)

theorem splitGroupedLoop_sound (fast slow : Nat) (bound : fast ≤ slow) :
    8 * (splitGroupedLoop fast slow).1 + groupedRemainder (splitGroupedLoop fast slow) = 8 * slow - 7 * fast := by
  induction fast using Nat.strongRecOn generalizing slow with
  | ind fast ih =>
    cases fast with
    | zero => simp [splitGroupedLoop, groupedRemainder, bitValue]
    | succ fast =>
      cases slow with
      | zero => omega
      | succ slow =>
        cases fast with
        | zero => simp [splitGroupedLoop, groupedRemainder, bitValue]; omega
        | succ fast =>
          cases slow with
          | zero => omega
          | succ slow =>
            cases fast with
            | zero => simp [splitGroupedLoop, groupedRemainder, bitValue]; omega
            | succ fast =>
              cases slow with
              | zero => omega
              | succ slow =>
                cases fast with
                | zero => simp [splitGroupedLoop, groupedRemainder, bitValue]; omega
                | succ fast =>
                  cases slow with
                  | zero => omega
                  | succ slow =>
                    cases fast with
                    | zero => simp [splitGroupedLoop, groupedRemainder, bitValue]; omega
                    | succ fast =>
                      cases slow with
                      | zero => omega
                      | succ slow =>
                        cases fast with
                        | zero => simp [splitGroupedLoop, groupedRemainder, bitValue]; omega
                        | succ fast =>
                          cases slow with
                          | zero => omega
                          | succ slow =>
                            cases fast with
                            | zero => simp [splitGroupedLoop, groupedRemainder, bitValue]; omega
                            | succ fast =>
                              cases slow with
                              | zero => omega
                              | succ slow =>
                                cases fast with
                                | zero => simp [splitGroupedLoop, groupedRemainder, bitValue]; omega
                                | succ fast =>
                                  have h := ih fast (by omega) slow (by omega)
                                  simp only [splitGroupedLoop]
                                  omega

-- This shares a suffix of n, exactly as split_nat_grouped in MoonBit.
def splitGrouped (n : Nat) : GroupedSplit := splitGroupedLoop n n

theorem splitGrouped_sound (n : Nat) :
    8 * (splitGrouped n).1 + groupedRemainder (splitGrouped n) = n := by
  have h := splitGroupedLoop_sound n n (by omega)
  dsimp [splitGrouped]
  omega

theorem splitGrouped_lt {n : Nat} (positive : 0 < n) : (splitGrouped n).1 < n := by
  have h := splitGrouped_sound n
  omega

-- low_bit may omit a zero above an empty tail without changing the value.
def lowBit (bit : Bool) (rest : Chain) : Chain :=
  match bit, rest with
  | false, .nil => .nil
  | _, _ => .cons bit rest

theorem lowBit_sound (bit : Bool) (rest : Chain) :
    value (lowBit bit rest) = bitValue bit + 2 * value rest := by
  cases bit <;> cases rest <;> rfl

theorem lowBit_canonical (bit : Bool) (rest : Chain) (tail : canonical rest) :
    canonical (lowBit bit rest) := by
  cases bit <;> cases rest <;> simp_all [lowBit, canonical]

def fromNatGroupedBits (n : Nat) : Chain :=
  match n with
  | 0 => .nil
  | n + 1 =>
    let divided := splitGrouped (n + 1)
    lowBit divided.2.1 (lowBit divided.2.2.1 (lowBit divided.2.2.2 (fromNatGroupedBits divided.1)))
termination_by n
decreasing_by exact splitGrouped_lt (Nat.zero_lt_succ _)

theorem fromNatGroupedBits_sound (n : Nat) : value (fromNatGroupedBits n) = n := by
  induction n using Nat.strongRecOn with
  | ind n ih =>
    cases n with
    | zero => simp [fromNatGroupedBits, value]
    | succ n =>
      have h := ih (splitGrouped (n + 1)).1 (splitGrouped_lt (by omega))
      have hs := splitGrouped_sound (n + 1)
      rw [fromNatGroupedBits]
      simp only [lowBit_sound]
      dsimp [groupedRemainder] at hs
      omega

theorem fromNatGroupedBits_canonical (n : Nat) : canonical (fromNatGroupedBits n) := by
  induction n using Nat.strongRecOn with
  | ind n ih =>
    cases n with
    | zero => simp [fromNatGroupedBits, canonical]
    | succ n =>
      have h := ih (splitGrouped (n + 1)).1 (splitGrouped_lt (by omega))
      rw [fromNatGroupedBits]
      exact lowBit_canonical _ _ (lowBit_canonical _ _ (lowBit_canonical _ _ h))

-- The immutable globals and the two aliasing helpers/factories have the same value.
def canonicalZeroValue : Chain := .nil
def canonicalOneValue : Chain := .cons true .nil
def canonicalZero : Chain := canonicalZeroValue
def canonicalOne : Chain := canonicalOneValue
def zero : Chain := canonicalZero
def one : Chain := canonicalOne

theorem zero_sound : value zero = 0 := by rfl
theorem one_sound : value one = 1 := by rfl

-- The Binary wrapper protects hot zero/one inputs through the existing factories.
def fromNat (n : Nat) : Chain :=
  match n with
  | 0 => zero
  | 1 => one
  | n + 2 => fromNatGroupedBits (n + 2)

theorem fromNat_sound (n : Nat) : value (fromNat n) = n := by
  cases n with
  | zero => rfl
  | succ n =>
    cases n with
    | zero => rfl
    | succ n => exact fromNatGroupedBits_sound (n + 2)

theorem fromNat_canonical (n : Nat) : canonical (fromNat n) := by
  cases n with
  | zero => trivial
  | succ n =>
    cases n with
    | zero => simp [fromNat, canonical, one, canonicalOne, canonicalOneValue]
    | succ n => exact fromNatGroupedBits_canonical (n + 2)

#print axioms fullAdder_sound
#print axioms increment_sound
#print axioms addition_sound
#print axioms carry_stabilizes
#print axioms borrow_stabilizes
#print axioms split_sound
#print axioms fromNatByHalves_sound
#print axioms splitGroupedLoop_sound
#print axioms splitGrouped_sound
#print axioms splitGrouped_lt
#print axioms lowBit_sound
#print axioms lowBit_canonical
#print axioms fromNatGroupedBits_sound
#print axioms fromNatGroupedBits_canonical
#print axioms zero_sound
#print axioms one_sound
#print axioms fromNat_sound
#print axioms fromNat_canonical

end Morph.Binary
