import Std.Tactic
namespace Morph.AdderCandidates

def reference (a b carry : Bool) : Bool × Bool :=
  match a, b, carry with
  | false, false, false => (false, false)
  | false, false, true | false, true, false | true, false, false => (true, false)
  | true, true, true => (true, true)
  | _, _, _ => (false, true)

def candidate_0 (a b carry : Bool) : Bool × Bool :=
  match a with
  | false =>
    match b with
      | false => (carry, false)
      | true => (!carry, carry)
  | true =>
    match b with
      | false => (!carry, carry)
      | true => (carry, true)
theorem candidate_0_equal (a b carry : Bool) : candidate_0 a b carry = reference a b carry := by
  cases a <;> cases b <;> cases carry <;> decide
#print axioms candidate_0_equal

def candidate_1 (a b carry : Bool) : Bool × Bool :=
  match a with
  | false =>
    match b with
      | false => (carry, false)
      | true => (!carry, carry)
  | true =>
    match carry with
      | false => (!b, b)
      | true => (b, true)
theorem candidate_1_equal (a b carry : Bool) : candidate_1 a b carry = reference a b carry := by
  cases a <;> cases b <;> cases carry <;> decide
#print axioms candidate_1_equal

def candidate_2 (a b carry : Bool) : Bool × Bool :=
  match a with
  | false =>
    match carry with
      | false => (b, false)
      | true => (!b, b)
  | true =>
    match b with
      | false => (!carry, carry)
      | true => (carry, true)
theorem candidate_2_equal (a b carry : Bool) : candidate_2 a b carry = reference a b carry := by
  cases a <;> cases b <;> cases carry <;> decide
#print axioms candidate_2_equal

def candidate_3 (a b carry : Bool) : Bool × Bool :=
  match a with
  | false =>
    match carry with
      | false => (b, false)
      | true => (!b, b)
  | true =>
    match carry with
      | false => (!b, b)
      | true => (b, true)
theorem candidate_3_equal (a b carry : Bool) : candidate_3 a b carry = reference a b carry := by
  cases a <;> cases b <;> cases carry <;> decide
#print axioms candidate_3_equal

def candidate_4 (a b carry : Bool) : Bool × Bool :=
  match b with
  | false =>
    match a with
      | false => (carry, false)
      | true => (!carry, carry)
  | true =>
    match a with
      | false => (!carry, carry)
      | true => (carry, true)
theorem candidate_4_equal (a b carry : Bool) : candidate_4 a b carry = reference a b carry := by
  cases a <;> cases b <;> cases carry <;> decide
#print axioms candidate_4_equal

def candidate_5 (a b carry : Bool) : Bool × Bool :=
  match b with
  | false =>
    match a with
      | false => (carry, false)
      | true => (!carry, carry)
  | true =>
    match carry with
      | false => (!a, a)
      | true => (a, true)
theorem candidate_5_equal (a b carry : Bool) : candidate_5 a b carry = reference a b carry := by
  cases a <;> cases b <;> cases carry <;> decide
#print axioms candidate_5_equal

def candidate_6 (a b carry : Bool) : Bool × Bool :=
  match b with
  | false =>
    match carry with
      | false => (a, false)
      | true => (!a, a)
  | true =>
    match a with
      | false => (!carry, carry)
      | true => (carry, true)
theorem candidate_6_equal (a b carry : Bool) : candidate_6 a b carry = reference a b carry := by
  cases a <;> cases b <;> cases carry <;> decide
#print axioms candidate_6_equal

def candidate_7 (a b carry : Bool) : Bool × Bool :=
  match b with
  | false =>
    match carry with
      | false => (a, false)
      | true => (!a, a)
  | true =>
    match carry with
      | false => (!a, a)
      | true => (a, true)
theorem candidate_7_equal (a b carry : Bool) : candidate_7 a b carry = reference a b carry := by
  cases a <;> cases b <;> cases carry <;> decide
#print axioms candidate_7_equal

def candidate_8 (a b carry : Bool) : Bool × Bool :=
  match carry with
  | false =>
    match a with
      | false => (b, false)
      | true => (!b, b)
  | true =>
    match a with
      | false => (!b, b)
      | true => (b, true)
theorem candidate_8_equal (a b carry : Bool) : candidate_8 a b carry = reference a b carry := by
  cases a <;> cases b <;> cases carry <;> decide
#print axioms candidate_8_equal

def candidate_9 (a b carry : Bool) : Bool × Bool :=
  match carry with
  | false =>
    match a with
      | false => (b, false)
      | true => (!b, b)
  | true =>
    match b with
      | false => (!a, a)
      | true => (a, true)
theorem candidate_9_equal (a b carry : Bool) : candidate_9 a b carry = reference a b carry := by
  cases a <;> cases b <;> cases carry <;> decide
#print axioms candidate_9_equal

def candidate_10 (a b carry : Bool) : Bool × Bool :=
  match carry with
  | false =>
    match b with
      | false => (a, false)
      | true => (!a, a)
  | true =>
    match a with
      | false => (!b, b)
      | true => (b, true)
theorem candidate_10_equal (a b carry : Bool) : candidate_10 a b carry = reference a b carry := by
  cases a <;> cases b <;> cases carry <;> decide
#print axioms candidate_10_equal

def candidate_11 (a b carry : Bool) : Bool × Bool :=
  match carry with
  | false =>
    match b with
      | false => (a, false)
      | true => (!a, a)
  | true =>
    match b with
      | false => (!a, a)
      | true => (a, true)
theorem candidate_11_equal (a b carry : Bool) : candidate_11 a b carry = reference a b carry := by
  cases a <;> cases b <;> cases carry <;> decide
#print axioms candidate_11_equal

end Morph.AdderCandidates
