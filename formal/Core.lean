import Std.Tactic

namespace Morph.Core

inductive Chain (α : Type u) where
  | nil
  | cons (head : α) (tail : Chain α)

def append (xs ys : Chain α) : Chain α :=
  match xs with
  | .nil => ys
  | .cons x rest => .cons x (append rest ys)

def replicate (n : Nat) (x : α) : Chain α :=
  match n with
  | 0 => .nil
  | n + 1 => .cons x (replicate n x)

def replicateOnto (n : Nat) (x : α) (tail : Chain α) : Chain α :=
  match n with
  | 0 => tail
  | n + 1 => replicateOnto n x (.cons x tail)

theorem replicate_append_cons (n : Nat) (x : α) (tail : Chain α) :
    append (replicate n x) (.cons x tail) = .cons x (append (replicate n x) tail) := by
  induction n with
  | zero => rfl
  | succ n ih => simp [replicate, append, ih]

theorem replicateOnto_eq_append (n : Nat) (x : α) (tail : Chain α) :
    replicateOnto n x tail = append (replicate n x) tail := by
  induction n generalizing tail with
  | zero => rfl
  | succ n ih =>
    simp only [replicateOnto, ih, replicate_append_cons, replicate, append]

theorem append_nil (xs : Chain α) : append xs .nil = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp [append, ih]

theorem replicateOnto_nil (n : Nat) (x : α) : replicateOnto n x .nil = replicate n x := by
  rw [replicateOnto_eq_append, append_nil]

#print axioms replicateOnto_eq_append
#print axioms replicateOnto_nil

def remainderValue (bit : Bool) : Nat := if bit then 1 else 0

def halveLoop : Nat → Nat → Nat × Bool
  | 0, quotient => (quotient, false)
  | 1, quotient => (quotient, true)
  | n + 2, quotient => halveLoop n (quotient + 1)

def halveNat (n : Nat) : Nat × Bool := halveLoop n 0
def halfNat (n : Nat) : Nat := (halveNat n).1

theorem halveLoop_sound (n quotient : Nat) :
    2 * (halveLoop n quotient).1 + remainderValue (halveLoop n quotient).2 = n + 2 * quotient := by
  induction n using Nat.strongRecOn generalizing quotient with
  | ind n ih =>
    cases n with
    | zero => simp [halveLoop, remainderValue]
    | succ n =>
      cases n with
      | zero => simp [halveLoop, remainderValue]; omega
      | succ n =>
        have h := ih n (by omega) (quotient + 1)
        simpa [halveLoop, Nat.mul_add, Nat.add_assoc, Nat.add_comm, Nat.add_left_comm] using h

theorem halveNat_sound (n : Nat) :
    2 * (halveNat n).1 + remainderValue (halveNat n).2 = n := by
  simpa [halveNat] using halveLoop_sound n 0

theorem halfNat_floor (n : Nat) : halfNat n = n / 2 := by
  have h := halveNat_sound n
  have bound : remainderValue (halveNat n).2 ≤ 1 := by
    cases (halveNat n).2 <;> decide
  simp only [halfNat]
  omega

#print axioms halveNat_sound
#print axioms halfNat_floor

end Morph.Core
