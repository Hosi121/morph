import Std.Tactic

namespace Morph.Binary

inductive Chain where
  | nil
  | cons (bit : Bool) (rest : Chain)
  deriving Repr, DecidableEq

def bitValue (bit : Bool) : Nat := if bit then 1 else 0

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

-- Model of the shared core.halve_nat accumulator used by binary.from_nat.
def split : Nat → Nat → Nat × Bool
  | 0, half => (half, false)
  | 1, half => (half, true)
  | n + 2, half => split n (half + 1)

theorem split_sound (n half : Nat) :
    2 * (split n half).1 + bitValue (split n half).2 = n + 2 * half := by
  induction n using Nat.strongRecOn generalizing half with
  | ind n ih =>
    cases n with
    | zero => simp [split, bitValue]
    | succ n =>
      cases n with
      | zero => simp [split, bitValue]; omega
      | succ n =>
        have h := ih n (by omega) (half + 1)
        simpa [split, Nat.mul_add, Nat.add_assoc, Nat.add_comm, Nat.add_left_comm] using h

theorem split_lt {n : Nat} (positive : 0 < n) : (split n 0).1 < n := by
  have h := split_sound n 0
  have bound : bitValue (split n 0).2 ≤ 1 := by
    cases (split n 0).2 <;> decide
  omega

def fromNat (n : Nat) : Chain :=
  match n with
  | 0 => .nil
  | n + 1 =>
    let divided := split (n + 1) 0
    .cons divided.2 (fromNat divided.1)
termination_by n
decreasing_by exact split_lt (Nat.zero_lt_succ _)

theorem fromNat_sound (n : Nat) : value (fromNat n) = n := by
  induction n using Nat.strongRecOn with
  | ind n ih =>
    cases n with
    | zero => simp [fromNat, value]
    | succ n =>
      have h := ih (split (n + 1) 0).1 (split_lt (by omega))
      have hs := split_sound (n + 1) 0
      rw [fromNat]
      simp only [value]
      omega

#print axioms fullAdder_sound
#print axioms increment_sound
#print axioms addition_sound
#print axioms carry_stabilizes
#print axioms borrow_stabilizes
#print axioms split_sound
#print axioms fromNat_sound

end Morph.Binary
