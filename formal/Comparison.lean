import Binary

namespace Morph.Binary.Comparison

open Morph.Binary

-- The previous higher-bit-first recursive comparison, including length priority.
def reference : Chain → Chain → Ordering
  | .nil, .nil => .eq
  | .nil, .cons _ _ => .lt
  | .cons _ _, .nil => .gt
  | .cons x xt, .cons y yt =>
    match reference xt yt with
    | .eq =>
      match x, y with
      | false, true => .lt
      | true, false => .gt
      | _, _ => .eq
    | order => order

def preferHigher (higher previous : Ordering) : Ordering :=
  match higher with
  | .eq => previous
  | order => order

def loop : Chain → Chain → Ordering → Ordering
  | .nil, .nil, previous => previous
  | .nil, .cons _ _, _ => .lt
  | .cons _ _, .nil, _ => .gt
  | .cons x xt, .cons y yt, previous =>
    let next := match x, y with
      | false, true => Ordering.lt
      | true, false => Ordering.gt
      | _, _ => previous
    loop xt yt next

def tail (xs ys : Chain) : Ordering := loop xs ys .eq

theorem loop_eq_reference (xs ys : Chain) (previous : Ordering) :
    loop xs ys previous = preferHigher (reference xs ys) previous := by
  induction xs generalizing ys previous with
  | nil => cases ys <;> rfl
  | cons x xt ih =>
    cases ys with
    | nil => rfl
    | cons y yt =>
      cases x <;> cases y <;>
        simp only [loop, reference, ih] <;>
        cases reference xt yt <;> rfl

-- This quantifies over all finite lists, including noncanonical high zeros.
theorem tail_eq_reference (xs ys : Chain) : tail xs ys = reference xs ys := by
  rw [tail, loop_eq_reference]
  cases reference xs ys <;> rfl

def correct (order : Ordering) (x y : Nat) : Prop :=
  match order with
  | .lt => x < y
  | .eq => x = y
  | .gt => x > y

theorem canonical_positive (xs : Chain) : canonical xs → xs ≠ .nil → 0 < value xs := by
  induction xs with
  | nil => simp
  | cons bit rest ih =>
    intro hc _
    have htail := hc.1
    have hhead := hc.2
    cases bit with
    | false =>
      have hn : rest ≠ .nil := by simpa using hhead
      have hp := ih htail hn
      simp only [value, bitValue, Bool.false_eq_true, ↓reduceIte, Nat.zero_add]
      omega
    | true => simp [value, bitValue]; omega

theorem reference_sound (xs ys : Chain) (hx : canonical xs) (hy : canonical ys) :
    correct (reference xs ys) (value xs) (value ys) := by
  induction xs generalizing ys with
  | nil =>
    cases ys with
    | nil => rfl
    | cons bit rest =>
      have hp := canonical_positive (.cons bit rest) hy (by intro h; cases h)
      simpa [reference, correct, value] using hp
  | cons x xt ih =>
    cases ys with
    | nil =>
      have hp := canonical_positive (.cons x xt) hx (by intro h; cases h)
      simpa [reference, correct, value] using hp
    | cons y yt =>
      have h := ih yt hx.1 hy.1
      cases hr : reference xt yt <;> cases x <;> cases y <;>
        simp only [hr, correct] at h <;>
        simp only [reference, correct, value, bitValue, hr, Bool.false_eq_true, ↓reduceIte, Nat.zero_add] <;> omega

theorem tail_sound (xs ys : Chain) (hx : canonical xs) (hy : canonical ys) :
    correct (tail xs ys) (value xs) (value ys) := by
  rw [tail_eq_reference]
  exact reference_sound xs ys hx hy

def groupFourOrder (a b c d w x y z : Bool) (previous : Ordering) : Ordering :=
  match d, z with
  | false, true => .lt
  | true, false => .gt
  | _, _ => match c, y with
    | false, true => .lt
    | true, false => .gt
    | _, _ => match b, x with
      | false, true => .lt
      | true, false => .gt
      | _, _ => match a, w with
        | false, true => .lt
        | true, false => .gt
        | _, _ => previous

def loop4 : Chain → Chain → Ordering → Ordering
  | .cons a (.cons b (.cons c (.cons d xt))), .cons w (.cons x (.cons y (.cons z yt))), previous =>
    loop4 xt yt (groupFourOrder a b c d w x y z previous)
  | .nil, .nil, previous => previous
  | .nil, .cons _ _, _ => .lt
  | .cons _ _, .nil, _ => .gt
  | .cons x xt, .cons y yt, previous =>
    let next := match x, y with
      | false, true => Ordering.lt
      | true, false => Ordering.gt
      | _, _ => previous
    loop4 xt yt next

theorem loop4_eq_loop (xs ys : Chain) (previous : Ordering) :
    loop4 xs ys previous = loop xs ys previous := by
  fun_induction loop4 xs ys previous
  case case1 a b c d xt w x y z yt previous ih =>
    cases a <;> cases b <;> cases c <;> cases d <;> cases w <;> cases x <;> cases y <;> cases z <;> exact ih
  case case2 => rfl
  case case3 => rfl
  case case4 bit rest previous => simp only [loop4.eq_4, loop]
  case case5 x xt y yt previous no4 next ih =>
    cases x <;> cases y
    · rw [loop4.eq_7 previous false xt false yt no4 (by decide) (by decide)]
      exact ih
    · rw [loop4.eq_5 previous xt yt no4]
      exact ih
    · rw [loop4.eq_6 previous xt yt no4]
      exact ih
    · rw [loop4.eq_7 previous true xt true yt no4 (by decide) (by decide)]
      exact ih

def groupedTail (xs ys : Chain) : Ordering := loop4 xs ys .eq

theorem groupedTail_eq_reference (xs ys : Chain) : groupedTail xs ys = reference xs ys := by
  rw [groupedTail, loop4_eq_loop]
  exact tail_eq_reference xs ys

-- A bounded prefix uses the original unwind rule; only its suffix uses loop4.
def peel (next : Chain → Chain → Ordering) : Chain → Chain → Ordering
  | .nil, .nil => .eq
  | .nil, .cons _ _ => .lt
  | .cons _ _, .nil => .gt
  | .cons x xt, .cons y yt =>
    match next xt yt with
    | .eq =>
      match x, y with
      | false, true => .lt
      | true, false => .gt
      | _, _ => .eq
    | order => order

theorem peel_eq_reference (next : Chain → Chain → Ordering)
    (h : ∀ xs ys, next xs ys = reference xs ys) :
    ∀ xs ys, peel next xs ys = reference xs ys := by
  intro xs ys
  cases xs with
  | nil => cases ys <;> rfl
  | cons x xt =>
    cases ys with
    | nil => rfl
    | cons y yt => simp only [peel, h, reference]

def protectedCompare : Chain → Chain → Ordering :=
  peel (peel (peel (peel (peel (peel (peel (peel groupedTail)))))))

theorem protectedCompare_eq_reference (xs ys : Chain) :
    protectedCompare xs ys = reference xs ys := by
  have h := peel_eq_reference _ (peel_eq_reference _ (peel_eq_reference _
    (peel_eq_reference _ (peel_eq_reference _ (peel_eq_reference _
      (peel_eq_reference _ (peel_eq_reference _ groupedTail_eq_reference)))))))
  exact h xs ys

theorem protectedCompare_sound (xs ys : Chain) (hx : canonical xs) (hy : canonical ys) :
    correct (protectedCompare xs ys) (value xs) (value ys) := by
  rw [protectedCompare_eq_reference]
  exact reference_sound xs ys hx hy

#print axioms loop_eq_reference
#print axioms tail_eq_reference
#print axioms canonical_positive
#print axioms reference_sound
#print axioms tail_sound
#print axioms loop4_eq_loop
#print axioms groupedTail_eq_reference
#print axioms peel_eq_reference
#print axioms protectedCompare_eq_reference
#print axioms protectedCompare_sound

end Morph.Binary.Comparison
