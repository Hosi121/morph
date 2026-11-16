import Std

namespace Morph.PrefixLogic

/-
Boolean projection of src/prefixlogic/evaluate.mbt::evaluate_conditional.
Atom arithmetic is an explicit hypothesis, not a correctness axiom. This model
does not formalize coefficient grouping, projection, or geometric CAD coverage.
-/

inductive Truth where
  | known : Bool → Truth
  | undetermined : Truth
  deriving DecidableEq, Repr

inductive Formula (Atom : Type u) where
  | constant : Bool → Formula Atom
  | atom : Atom → Formula Atom
  | negation : Formula Atom → Formula Atom
  | conjunction : Formula Atom → Formula Atom → Formula Atom
  | disjunction : Formula Atom → Formula Atom → Formula Atom
  deriving Repr

def negate : Truth → Truth
  | .known value => .known (!value)
  | .undetermined => .undetermined

def conjoin : Truth → Truth → Truth
  | .known false, _ => .known false
  | _, .known false => .known false
  | .known true, .known true => .known true
  | _, _ => .undetermined

def disjoin : Truth → Truth → Truth
  | .known true, _ => .known true
  | _, .known true => .known true
  | .known false, .known false => .known false
  | _, _ => .undetermined

def partialEvaluate (observe : Atom → Truth) : Formula Atom → Truth
  | .constant value => .known value
  | .atom atom => observe atom
  | .negation body => negate (partialEvaluate observe body)
  | .conjunction left right =>
      conjoin (partialEvaluate observe left) (partialEvaluate observe right)
  | .disjunction left right =>
      disjoin (partialEvaluate observe left) (partialEvaluate observe right)

def totalEvaluate (assignment : Atom → Bool) : Formula Atom → Bool
  | .constant value => value
  | .atom atom => assignment atom
  | .negation body => !(totalEvaluate assignment body)
  | .conjunction left right =>
      totalEvaluate assignment left && totalEvaluate assignment right
  | .disjunction left right =>
      totalEvaluate assignment left || totalEvaluate assignment right

def SoundAt : Truth → Bool → Prop
  | .known observed, actual => actual = observed
  | .undetermined, _ => True

theorem negate_sound (observation : Truth) (actual : Bool)
    (sound : SoundAt observation actual) :
    SoundAt (negate observation) (!actual) := by
  cases observation with
  | undetermined => trivial
  | known observed =>
      simp only [SoundAt] at sound
      simp [negate, SoundAt, sound]

theorem conjoin_sound (left right : Truth) (a b : Bool)
    (leftSound : SoundAt left a) (rightSound : SoundAt right b) :
    SoundAt (conjoin left right) (a && b) := by
  cases left with
  | undetermined =>
      cases right with
      | undetermined => trivial
      | known value => cases value <;> simp_all [SoundAt, conjoin]
  | known leftValue =>
      cases right with
      | undetermined => cases leftValue <;> simp_all [SoundAt, conjoin]
      | known rightValue =>
          cases leftValue <;> cases rightValue <;> simp_all [SoundAt, conjoin]

theorem disjoin_sound (left right : Truth) (a b : Bool)
    (leftSound : SoundAt left a) (rightSound : SoundAt right b) :
    SoundAt (disjoin left right) (a || b) := by
  cases left with
  | undetermined =>
      cases right with
      | undetermined => trivial
      | known value => cases value <;> simp_all [SoundAt, disjoin]
  | known leftValue =>
      cases right with
      | undetermined => cases leftValue <;> simp_all [SoundAt, disjoin]
      | known rightValue =>
          cases leftValue <;> cases rightValue <;> simp_all [SoundAt, disjoin]

/-
The induction ranges over every finite formula, without a depth or atom-count
bound. Domain and admissible are arbitrary, including an empty domain.
-/
theorem partialEvaluate_sound
    (observe : Atom → Truth)
    (assignment : Domain → Atom → Bool)
    (admissible : Domain → Prop)
    (atomSound : ∀ atom point, admissible point →
      SoundAt (observe atom) (assignment point atom))
    (formula : Formula Atom) :
    ∀ point, admissible point →
      SoundAt (partialEvaluate observe formula)
        (totalEvaluate (assignment point) formula) := by
  induction formula with
  | constant value =>
      intro point allowed
      rfl
  | atom atom => exact atomSound atom
  | negation body ih =>
      intro point allowed
      exact negate_sound _ _ (ih point allowed)
  | conjunction left right leftIH rightIH =>
      intro point allowed
      exact conjoin_sound _ _ _ _ (leftIH point allowed) (rightIH point allowed)
  | disjunction left right leftIH rightIH =>
      intro point allowed
      exact disjoin_sound _ _ _ _ (leftIH point allowed) (rightIH point allowed)

theorem known_is_uniform
    (observe : Atom → Truth)
    (assignment : Domain → Atom → Bool)
    (admissible : Domain → Prop)
    (atomSound : ∀ atom value, observe atom = .known value →
      ∀ point, admissible point → assignment point atom = value)
    (formula : Formula Atom) (value : Bool)
    (known : partialEvaluate observe formula = .known value) :
    ∀ point, admissible point → totalEvaluate (assignment point) formula = value := by
  have soundAtoms : ∀ atom point, admissible point →
      SoundAt (observe atom) (assignment point atom) := by
    intro atom point allowed
    cases observed : observe atom with
    | undetermined => trivial
    | known result => exact atomSound atom result observed point allowed
  intro point allowed
  have sound := partialEvaluate_sound observe assignment admissible soundAtoms formula point allowed
  simpa only [known, SoundAt] using sound

-- Positive sanity cases exercise both determining operands and unknown tails.
example : conjoin (.known false) .undetermined = .known false := rfl
example : conjoin .undetermined (.known false) = .known false := rfl
example : disjoin (.known true) .undetermined = .known true := rfl
example : disjoin .undetermined (.known true) = .known true := rfl
example : conjoin (.known true) .undetermined = .undetermined := rfl
example : disjoin (.known false) .undetermined = .undetermined := rfl

example (observe : Atom → Truth) (body : Formula Atom) :
    partialEvaluate observe (.conjunction (.constant false) body) = .known false := by
  simp [partialEvaluate, conjoin]

example (observe : Atom → Truth) (body : Formula Atom) :
    partialEvaluate observe (.disjunction (.constant true) body) = .known true := by
  simp [partialEvaluate, disjoin]

#print axioms partialEvaluate_sound
#print axioms known_is_uniform

end Morph.PrefixLogic
