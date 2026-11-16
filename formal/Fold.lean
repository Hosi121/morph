import Core

namespace Morph.Fold
open Morph.Core

def reverseOnto (xs ys : Chain α) : Chain α :=
  match xs with
  | .nil => ys
  | .cons a rest => reverseOnto rest (.cons a ys)

def reverse (xs : Chain α) : Chain α := reverseOnto xs .nil

def foldRight (step : α → σ → σ) (xs : Chain α) (state : σ) : σ :=
  match xs with
  | .nil => state
  | .cons a rest => step a (foldRight step rest state)

def foldLeft (step : α → σ → σ) (xs : Chain α) (state : σ) : σ :=
  match xs with
  | .nil => state
  | .cons a rest => foldLeft step rest (step a state)

theorem foldLeft_reverseOnto (step : α → σ → σ) (xs ys : Chain α) (state : σ) :
    foldLeft step (reverseOnto xs ys) state = foldLeft step ys (foldRight step xs state) := by
  induction xs generalizing ys state with
  | nil => rfl
  | cons a rest ih =>
    simpa only [reverseOnto, foldLeft, foldRight] using ih (.cons a ys) state

theorem foldLeft_reverse (step : α → σ → σ) (xs : Chain α) (state : σ) :
    foldLeft step (reverse xs) state = foldRight step xs state := by
  simpa only [reverse, foldLeft] using foldLeft_reverseOnto step xs .nil state

def length : Chain α → Nat
  | .nil => 0
  | .cons _ rest => length rest + 1

def foldFour (step : α → σ → σ) (xs : Chain α) (state : σ) : σ :=
  match xs with
  | .cons a (.cons b (.cons c (.cons d rest))) =>
    foldFour step rest (step d (step c (step b (step a state))))
  | .cons a rest => foldFour step rest (step a state)
  | .nil => state

theorem foldFour_eq_foldLeft (step : α → σ → σ) (xs : Chain α) (state : σ) :
    foldFour step xs state = foldLeft step xs state := by
  suffices ∀ n (xs : Chain α) (state : σ), length xs = n →
      foldFour step xs state = foldLeft step xs state by
    exact this (length xs) xs state rfl
  intro n
  induction n using Nat.strongRecOn with
  | ind n ih =>
    intro xs state bound
    cases xs with
    | nil => rfl
    | cons a xs =>
      cases xs with
      | nil => rfl
      | cons b xs =>
        cases xs with
        | nil => rfl
        | cons c xs =>
          cases xs with
          | nil => rfl
          | cons d rest =>
            have shorter : length rest < n := by simp only [length] at bound; omega
            simpa only [foldFour, foldLeft] using
              ih (length rest) shorter rest (step d (step c (step b (step a state)))) rfl

theorem foldFour_reverse (step : α → σ → σ) (xs : Chain α) (state : σ) :
    foldFour step (reverse xs) state = foldRight step xs state := by
  rw [foldFour_eq_foldLeft, foldLeft_reverse]

-- Preserve a fixed recursive prefix, then use the equivalent reversed tail.
def boundedRightFour (step : α → σ → σ) (fuel : Nat) (xs : Chain α) (state : σ) : σ :=
  match fuel with
  | 0 => foldLeft step (reverse xs) state
  | fuel + 1 =>
    match xs with
    | .cons a (.cons b (.cons c (.cons d rest))) =>
      step a (step b (step c (step d (boundedRightFour step fuel rest state))))
    | _ => foldRight step xs state

theorem boundedRightFour_eq_foldRight (step : α → σ → σ) (fuel : Nat)
    (xs : Chain α) (state : σ) :
    boundedRightFour step fuel xs state = foldRight step xs state := by
  induction fuel generalizing xs state with
  | zero => exact foldLeft_reverse step xs state
  | succ fuel ih =>
    cases xs with
    | nil => rfl
    | cons a xs =>
      cases xs with
      | nil => rfl
      | cons b xs =>
        cases xs with
        | nil => rfl
        | cons c xs =>
          cases xs with
          | nil => rfl
          | cons d rest => simp only [boundedRightFour, foldRight, ih]

#print axioms foldLeft_reverseOnto
#print axioms foldLeft_reverse
#print axioms foldFour_eq_foldLeft
#print axioms foldFour_reverse
#print axioms boundedRightFour_eq_foldRight

end Morph.Fold
