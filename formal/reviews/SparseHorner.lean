import Std.Tactic

namespace Morph.SparseHorner

/- Explicit, sufficient laws. Every semiring supplies these laws, but neither
   additive commutativity nor multiplicative commutativity is needed here. -/
structure Laws (R : Type u) where
  zero : R
  one : R
  add : R → R → R
  mul : R → R → R
  add_assoc : ∀ a b c, add (add a b) c = add a (add b c)
  add_zero : ∀ a, add a zero = a
  zero_add : ∀ a, add zero a = a
  mul_assoc : ∀ a b c, mul (mul a b) c = mul a (mul b c)
  mul_one : ∀ a, mul a one = a
  one_mul : ∀ a, mul one a = a
  add_mul : ∀ a b c, mul (add a b) c = add (mul a c) (mul b c)

variable {R : Type u} (A : Laws R)

def power (x : R) : Nat → R
  | 0 => A.one
  | n + 1 => A.mul x (power x n)

theorem power_add (x : R) (m n : Nat) :
    power A x (m + n) = A.mul (power A x m) (power A x n) := by
  induction m with
  | zero => simp only [Nat.zero_add, power, A.one_mul]
  | succ m ih =>
    simp only [Nat.succ_add, power, ih, A.mul_assoc]

def bitsValue : List Bool → Nat
  | [] => 0
  | false :: rest => bitsValue rest + bitsValue rest
  | true :: rest => bitsValue rest + bitsValue rest + 1

def bitsPower (x : R) : List Bool → R
  | [] => A.one
  | bit :: rest =>
    let half := bitsPower x rest
    let square := A.mul half half
    if bit then A.mul x square else square

theorem bitsPower_sound (x : R) (bits : List Bool) :
    bitsPower A x bits = power A x (bitsValue bits) := by
  induction bits with
  | nil => rfl
  | cons bit rest ih =>
    cases bit with
    | false =>
      simp only [bitsPower, bitsValue, Bool.false_eq_true, ↓reduceIte, ih]
      exact (power_add A x _ _).symm
    | true =>
      simp only [bitsPower, bitsValue, ↓reduceIte, ih]
      rw [power, power_add]

/- Binary/Nat conversion is an explicit assumption here, not silently proved by
   replacing the production converter with a host-language implementation. -/
def optimizedPower (encode : Nat → List Bool) (x : R) (n : Nat) : R :=
  match n with
  | 0 => A.one
  | 1 => x
  | _ => bitsPower A x (encode n)

theorem optimizedPower_sound (encode : Nat → List Bool)
    (encodingSound : ∀ n, bitsValue (encode n) = n) (x : R) (n : Nat) :
    optimizedPower A encode x n = power A x n := by
  cases n with
  | zero => rfl
  | succ n =>
    cases n with
    | zero => exact (A.mul_one x).symm
    | succ n =>
      change bitsPower A x (encode (n + 2)) = power A x (n + 2)
      rw [bitsPower_sound, encodingSound]

abbrev Term (R : Type u) := Nat × R

def sumTerms (x : R) : List (Term R) → R
  | [] => A.zero
  | (e,c) :: rest => A.add (A.mul c (power A x e)) (sumTerms x rest)

def genericSum (x : R) : List (Term R) → R → R
  | [], accumulated => accumulated
  | (e,c) :: rest, accumulated =>
    genericSum x rest (A.add accumulated (A.mul c (power A x e)))

theorem genericSum_invariant (x : R) (terms : List (Term R)) (accumulated : R) :
    genericSum A x terms accumulated = A.add accumulated (sumTerms A x terms) := by
  induction terms generalizing accumulated with
  | nil => exact (A.add_zero accumulated).symm
  | cons head rest ih =>
    rcases head with ⟨e,c⟩
    simp only [genericSum, sumTerms, ih, A.add_assoc]

theorem genericSum_eq_sum (x : R) (terms : List (Term R)) :
    genericSum A x terms A.zero = sumTerms A x terms := by
  rw [genericSum_invariant, A.zero_add]

/- The implementation uses truncated subtraction. This hypothesis is essential.
   Equality is allowed: zero coefficients and repeated degrees need no extra law. -/
def DescendingFrom : Nat → List (Term R) → Prop
  | _, [] => True
  | degree, (next,_) :: tail => next ≤ degree ∧ DescendingFrom next tail

def scan (x : R) : List (Term R) → Nat → R → R
  | [], degree, accumulated =>
    match degree with
    | 0 => accumulated
    | _ => A.mul accumulated (power A x degree)
  | (next,c) :: tail, degree, accumulated =>
    scan x tail next (A.add
      (A.mul accumulated (power A x (degree - next))) c)

theorem scan_invariant (x : R) (rest : List (Term R)) (degree : Nat)
    (accumulated : R) (descending : DescendingFrom degree rest) :
    scan A x rest degree accumulated =
      A.add (A.mul accumulated (power A x degree)) (sumTerms A x rest) := by
  induction rest generalizing degree accumulated with
  | nil =>
    cases degree <;> simp only [scan, sumTerms, power, A.mul_one, A.add_zero]
  | cons head tail ih =>
    rcases head with ⟨next,c⟩
    rcases descending with ⟨bound, ordered⟩
    simp only [scan]
    rw [ih next _ ordered]
    rw [A.add_mul, A.mul_assoc, ← power_add, Nat.sub_add_cancel bound]
    exact A.add_assoc _ _ _

def horner (x : R) : List (Term R) → R
  | [] => A.zero
  | (degree,c) :: rest => scan A x rest degree c

def Descending : List (Term R) → Prop
  | [] => True
  | (degree,_) :: rest => DescendingFrom degree rest

theorem horner_eq_sum (x : R) (terms : List (Term R))
    (descending : Descending terms) :
    horner A x terms = sumTerms A x terms := by
  cases terms with
  | nil => rfl
  | cons head rest =>
    rcases head with ⟨degree,c⟩
    exact scan_invariant A x rest degree c descending

theorem horner_eq_genericSum (x : R) (terms : List (Term R))
    (descending : Descending terms) :
    horner A x terms = genericSum A x terms A.zero := by
  rw [horner_eq_sum A x terms descending, genericSum_eq_sum]

/- Public dispatch routes every non-univariate request to the untouched generic
   evaluator. This theorem makes no claim about the semantics of that evaluator. -/
def dispatch (univariate : Bool) (terms : List (Term R)) (x : R)
    (generic : Option R) : Option R :=
  if univariate then some (horner A x terms) else generic

theorem dispatch_generic (terms : List (Term R)) (x : R) (generic : Option R) :
    dispatch A false terms x generic = generic := by rfl

theorem dispatch_univariate (terms : List (Term R)) (x : R)
    (generic : Option R) (descending : Descending terms) :
    dispatch A true terms x generic = some (sumTerms A x terms) := by
  simp only [dispatch, ↓reduceIte, horner_eq_sum A x terms descending]

/- A concrete semiring instance and a machine-checked countermodel demonstrate
   that the laws are inhabited and that dropping descent changes the result. -/
def natLaws : Laws Nat where
  zero := 0
  one := 1
  add := Nat.add
  mul := Nat.mul
  add_assoc := Nat.add_assoc
  add_zero := Nat.add_zero
  zero_add := Nat.zero_add
  mul_assoc := Nat.mul_assoc
  mul_one := Nat.mul_one
  one_mul := Nat.one_mul
  add_mul := Nat.add_mul

theorem ascending_countermodel :
    horner natLaws 2 [(0,1),(1,1)] = 4 ∧
    sumTerms natLaws 2 [(0,1),(1,1)] = 3 := by decide

theorem gap_zero_and_zero_coefficient :
    horner natLaws 2 [(3,2),(3,0),(3,4)] =
    sumTerms natLaws 2 [(3,2),(3,0),(3,4)] := by
  exact horner_eq_sum natLaws 2 _ (by simp [Descending, DescendingFrom])

#print axioms power_add
#print axioms bitsPower_sound
#print axioms optimizedPower_sound
#print axioms genericSum_invariant
#print axioms genericSum_eq_sum
#print axioms scan_invariant
#print axioms horner_eq_sum
#print axioms horner_eq_genericSum
#print axioms dispatch_generic
#print axioms dispatch_univariate
#print axioms ascending_countermodel
#print axioms gap_zero_and_zero_coefficient

end Morph.SparseHorner
