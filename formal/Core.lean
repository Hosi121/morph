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
  | 0, slow => (slow, false)
  | 1, slow + 1 => (slow, true)
  | n + 2, slow + 1 => halveLoop n slow
  | _, 0 => (0, false)

def halveNat (n : Nat) : Nat × Bool := halveLoop n n
def halfNat (n : Nat) : Nat := (halveNat n).1

theorem halveLoop_sound (fast slow : Nat) (bound : fast ≤ slow) :
    2 * (halveLoop fast slow).1 + remainderValue (halveLoop fast slow).2 = 2 * slow - fast := by
  induction fast using Nat.strongRecOn generalizing slow with
  | ind fast ih =>
    cases fast with
    | zero => simp [halveLoop, remainderValue]
    | succ fast =>
      cases fast with
      | zero =>
        cases slow with
        | zero => omega
        | succ slow => simp [halveLoop, remainderValue]; omega
      | succ fast =>
        cases slow with
        | zero => omega
        | succ slow =>
          have h := ih fast (by omega) slow (by omega)
          simp only [halveLoop]
          omega

theorem halveNat_sound (n : Nat) :
    2 * (halveNat n).1 + remainderValue (halveNat n).2 = n := by
  have h := halveLoop_sound n n (by omega)
  dsimp [halveNat]
  omega

theorem halfNat_floor (n : Nat) : halfNat n = n / 2 := by
  have h := halveNat_sound n
  have bound : remainderValue (halveNat n).2 ≤ 1 := by
    cases (halveNat n).2 <;> decide
  simp only [halfNat]
  omega

#print axioms halveNat_sound
#print axioms halfNat_floor

end Morph.Core
