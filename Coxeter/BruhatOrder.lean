import Coxeter.CoxeterSystem

import Mathlib.Data.Set.Card

open OrderTwoGen HOrderTwoGenGroup

namespace CoxeterGroup
namespace Bruhat

/-Let G be a Coxeter group-/
variable {G : Type*} [CoxeterGroup G]

/- For any u, w ∈ G,
we say u ≤ w if there exists a reflection t such that w = u t and ℓ(u) < ℓ(w)-/
@[simp]
abbrev lt_adj (u w : G) := ∃ t ∈ Refl G, w = u * t ∧ ℓ(u) < ℓ(w)

/- For any u, w ∈ G,
we say u ≤' w if there exists a reflection t such that w = t u and ℓ(u) < ℓ(w)-/
@[simp]
abbrev lt_adj' (u w : G) := ∃ t ∈ Refl G, w = t * u ∧ ℓ(u) < ℓ(w)

/- Lemma: For any u ,w ∈ G, we have u ≤ w if and only if u ≤' w.
-/
lemma lt_adj_iff_lt_adj' {u w : G} : lt_adj u w ↔ lt_adj' u w := by
  constructor
  · rintro ⟨t, ⟨trfl, wut, ulew⟩⟩
    use u * t * u⁻¹
    have uturfl : u * t * u⁻¹ ∈ Refl G := by
      --simp [Refl] at trfl ⊢
      rcases trfl with ⟨v, s, vsv⟩
      use u * v, s
      rw [vsv]
      group
    have wexp : w = u * t * u⁻¹ * u := by
      rw [wut]
      group
    exact ⟨uturfl, wexp, ulew⟩
  · rintro ⟨t, ⟨trfl, wtu, ulew⟩⟩
    use u⁻¹ * t * u
    have uturfl : u⁻¹ * t * u ∈ Refl G := by
      --rw [Refls] at trfl ⊢
      rcases trfl with ⟨v, s, vsv⟩
      use u⁻¹ * v, s
      rw [vsv]
      group
    have wexp : w = u * (u⁻¹ * t * u) := by
      rw [wtu]
      group
    exact ⟨uturfl, wexp, ulew⟩

/- We define a relation < on G by the transitive closure of <
-/
abbrev lt (u w : G) := Relation.TransGen Bruhat.lt_adj u w

/- We define a relation ≤  on G by the transitive closure of <
and the relation w ≤ w for any w ∈ G.
-/
abbrev le (u w : G) := Relation.ReflTransGen Bruhat.lt_adj u w

/-instance Bruhat.LT {G:Type*} [CoxeterGroup G] : LT G where
  lt := lt

instance Bruhat.LE {G:Type*} [CoxeterGroup G] : LE G where
  le := le-/

/- Lemma: let u, w ∈ G be such that u ≤ w, then we have ℓ(u) ≤ ℓ(w).
-/
lemma length_le_of_le {u w : G} : le u w → ℓ(u) ≤ ℓ(w) := by
  rw [le]
  intro trans
  induction trans with
  | refl => exact le_rfl
  | tail _ bltc uleb =>
    rcases bltc with ⟨_, ⟨_, _, bltc⟩⟩
    exact le_of_lt (lt_of_le_of_lt uleb bltc)

/- Lemma: let u, w ∈ G be such that u < w, then we have ℓ(u) < ℓ(w).
-/
lemma length_lt_of_lt {u w : G} : lt u w → ℓ(u) < ℓ(w) := by
  rw [lt]
  intro trans
  induction trans with
  | single ultb =>
    rcases ultb with ⟨_, ⟨_, _, ultb⟩⟩
    exact ultb
  | tail _ bltc ultb =>
    rcases bltc with ⟨_, ⟨_, _, bltc⟩⟩
    exact lt_trans ultb bltc

/- Lemma: let u, w ∈ G be such that u ≤ w and ℓ(u) < ℓ(w), then we have u < w. -/
lemma lt_of_le_of_length_lt {u w : G} : le u w → ℓ(u) < ℓ(w) → lt u w := by
  intro ulew ultw
  induction ulew with
  | refl => by_contra; exact lt_irrefl _ ultw
  | tail hyp bltc _ =>
    refine Relation.TransGen.tail'_iff.mpr ?tail.intro.intro.intro.a
    exact ⟨_, hyp, bltc⟩


/-
Lemma: let u, w ∈ G be such that u ≤ w and ℓ(u) ≥  ℓ(w), then we have u = w
-/
lemma eq_of_le_of_length_ge {u w : G} : le u w → ℓ(u) ≥ ℓ(w) → u = w := by
  intro ulew ugew
  rcases ulew with (_ | ⟨uleb, b, ⟨_, _, bltw⟩⟩)
  · rfl
  · by_contra; linarith [length_le_of_le uleb, bltw, ugew]


/- Instance: The relations (<, ≤) defined a partial order on G
-/
instance PartialOrder : PartialOrder G where
  le := le
  lt := lt
  le_refl := fun _ => Relation.ReflTransGen.refl
  le_trans := fun _ _ _ => Relation.ReflTransGen.trans
  lt_iff_le_not_le := by
    intro u w
    constructor
    · intro ultw
      constructor
      · apply Relation.TransGen.to_reflTransGen ultw
      · intro wleu
        have lultw : ℓ(u) < ℓ(w) := length_lt_of_lt ultw
        have lwleu : ℓ(w) ≤ ℓ(u) := length_le_of_le wleu
        have lwltw : ℓ(w) < ℓ(w) := lt_of_le_of_lt lwleu lultw
        exact lt_irrefl (ℓ(w)) lwltw
    · rintro ⟨ulew, nwleu⟩
      apply lt_of_le_of_length_lt ulew
      contrapose! nwleu
      have ueqw : u = w := eq_of_le_of_length_ge ulew nwleu
      rw [ueqw]
      exact Relation.ReflTransGen.refl
  le_antisymm := fun (u w : G) ulew wleu =>
    eq_of_le_of_length_ge ulew (length_le_of_le wleu)


/-
Definition: For any x y ∈ G, we define the interval [x,y] = {z ∈ G | x ≤ z ≤ y}
-/
/-
Q: We need to prove the interval is also an instance of poset.
-/
def Interval (x y : G) : Set G := Set.Icc x y

local notation "S" => (SimpleRefls G)

--  Bjorner, Brenti, Lemma 2.2.1
lemma SubwordAux {L L' : List S} (hne: (L:G) ≠ L') (hred: reduced_word L) (hred': reduced_word L') (hsub: List.Sublist L' L) : ∃ (L'' : List S), reduced_word L'' ∧ (L' :G) < L'' ∧ ℓ((L'':G)) = ℓ((L':G)) + 1 ∧ List.Sublist L'' L :=by
  sorry


theorem subwordProp {L: List S} (hred : reduced_word L) : u ≤ L ↔ ∃ (L': List S), reduced_word L' ∧ List.Sublist L' L ∧ u = L'.gprod where
  mp := by sorry
  mpr := fun
    | .intro w h => by
      sorry

-- Formulate the theorem on subword property

-- Show that Bruhat interval is finite

instance Interval.fintype {x y : G} : Fintype (Interval x y) where
  elems := by sorry
  complete := by sorry

end Bruhat

end CoxeterGroup

/-



lemma ltone_is_lt {u w:G}  : ltone u w → u < w := by{
  intro H
  use []
  simp
  assumption
}


#check Set.ncard
#check length

lemma SubwordAux (L L':List S) (hred:reduced_word L) (hw: (w:G) = L.gprod) (hsub: List.Sublist L' L) (hu: u = L'.gprod): ∃ (v: G) (L'':List S), u < v ∧ ℓ(v) = ℓ(u) + 1 ∧ v = L''.gprod:=by
  sorry

theorem SubwordProp (L: List S) (u w : G) (hred:reduced_word L) (hw: (w:G) = L.gprod) : u ≤ w ↔ ∃ (L': List S), reduced_word L' ∧ List.Sublist L' L ∧ u = L'.gprod where
  mp := by
    intro hle
    exact Or.elim hle (fun h1 =>(by rw [h1];use L)) (fun h1=>(by{
      rcases h1 with ⟨Laux,h2⟩
      induction' Laux with head tail tail_ih
      case nil => simp [ltone]at h2;sorry
      case cons =>sorry
    }))

  mpr := fun
    | .intro w h => by
      sorry

lemma BruhuatInteIsFin (u w :G)  : Set.ncard (@BruhatInte G  _  S _ u w) ≤ 2^ℓ(w):=sorry

lemma leIffInvle (u w : G) :  u ≤ w ↔ u⁻¹ ≤ w⁻¹ := sorry

theorem ChainProp (u w :G) (hlt: u < w) : ∃ (L: List G) (h:L ≠ [])(n:Fin L.length), u = L.head h∧ w =L.ilast' w ∧ ℓ(L.get n) = ℓ(u) + n:= sorry

def OrderCovering (u w:G) := u < w ∧ ℓ(u) + 1 = ℓ(w)

local notation lhs:65 " ◁  " rhs:65 => (@OrderCovering G  _ S _ _ lhs rhs)

lemma LiftingProp (u w : G) (h:s∈ D_L w) : u ≤ s*w ∧ s*u ≤ w := sorry

class DirectedPoset (α:Type u) extends PartialOrder α where
directed:∀ (u w:α) , ∃ z:α, u ≤ z ∧ w ≤ z

lemma BruhatOrderIsDir :DirectedPoset G:=sorry

lemma Bruhat'Congr' (x y :G) (t:T S) (hlt: x < x*t) (hlt: y < (t:G)*y) : x * y < x * t * y :=by
  let t' :=x * t * x⁻¹
  have hc :x*t*y = t'*x*y := by simp
  by_contra hf
  sorry
  -- have hredx := @reduced_word_exist G A _ _ S _ x
  -- have hredy := @reduced_word_exist G A _ _ S _ y
  -- --have hf' := @le_of_not_lt G _ (x * t * y) (x * y) hf
  -- let ⟨L1,hL1⟩ := hredx
  -- let ⟨L2,hL2⟩ := hredy
-/

section test
variable (G:Type*) [hG:CoxeterGroup G]

variable  (g:G)

#check ℓ(g)

variable (u v:G)
#check u < v

end test
