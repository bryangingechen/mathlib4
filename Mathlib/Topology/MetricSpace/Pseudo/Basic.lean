/-
Copyright (c) 2015, 2017 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jeremy Avigad, Robert Y. Lewis, Johannes Hölzl, Mario Carneiro, Sébastien Gouëzel
-/
import Mathlib.Data.ENNReal.Real
import Mathlib.Tactic.Bound.Attribute
import Mathlib.Topology.EMetricSpace.Basic
import Mathlib.Topology.MetricSpace.Pseudo.Defs

/-!
## Pseudo-metric spaces

Further results about pseudo-metric spaces.

-/

open Set Filter TopologicalSpace Bornology
open scoped ENNReal NNReal Uniformity Topology

universe u v w

variable {α : Type u} {β : Type v} {X ι : Type*}

variable [PseudoMetricSpace α]

/-- The triangle (polygon) inequality for sequences of points; `Finset.Ico` version. -/
theorem dist_le_Ico_sum_dist (f : ℕ → α) {m n} (h : m ≤ n) :
    dist (f m) (f n) ≤ ∑ i ∈ Finset.Ico m n, dist (f i) (f (i + 1)) := by
  induction n, h using Nat.le_induction with
  | base => rw [Finset.Ico_self, Finset.sum_empty, dist_self]
  | succ n hle ihn =>
    calc
      dist (f m) (f (n + 1)) ≤ dist (f m) (f n) + dist (f n) (f (n + 1)) := dist_triangle _ _ _
      _ ≤ (∑ i ∈ Finset.Ico m n, _) + _ := add_le_add ihn le_rfl
      _ = ∑ i ∈ Finset.Ico m (n + 1), _ := by
      { rw [Nat.Ico_succ_right_eq_insert_Ico hle, Finset.sum_insert, add_comm]; simp }

/-- The triangle (polygon) inequality for sequences of points; `Finset.range` version. -/
theorem dist_le_range_sum_dist (f : ℕ → α) (n : ℕ) :
    dist (f 0) (f n) ≤ ∑ i ∈ Finset.range n, dist (f i) (f (i + 1)) :=
  Nat.Ico_zero_eq_range ▸ dist_le_Ico_sum_dist f (Nat.zero_le n)

/-- A version of `dist_le_Ico_sum_dist` with each intermediate distance replaced
with an upper estimate. -/
theorem dist_le_Ico_sum_of_dist_le {f : ℕ → α} {m n} (hmn : m ≤ n) {d : ℕ → ℝ}
    (hd : ∀ {k}, m ≤ k → k < n → dist (f k) (f (k + 1)) ≤ d k) :
    dist (f m) (f n) ≤ ∑ i ∈ Finset.Ico m n, d i :=
  le_trans (dist_le_Ico_sum_dist f hmn) <|
    Finset.sum_le_sum fun _k hk => hd (Finset.mem_Ico.1 hk).1 (Finset.mem_Ico.1 hk).2

/-- A version of `dist_le_range_sum_dist` with each intermediate distance replaced
with an upper estimate. -/
theorem dist_le_range_sum_of_dist_le {f : ℕ → α} (n : ℕ) {d : ℕ → ℝ}
    (hd : ∀ {k}, k < n → dist (f k) (f (k + 1)) ≤ d k) :
    dist (f 0) (f n) ≤ ∑ i ∈ Finset.range n, d i :=
  Nat.Ico_zero_eq_range ▸ dist_le_Ico_sum_of_dist_le (zero_le n) fun _ => hd

namespace Metric

-- instantiate pseudometric space as a topology
variable {x y z : α} {δ ε ε₁ ε₂ : ℝ} {s : Set α}

nonrec theorem uniformInducing_iff [PseudoMetricSpace β] {f : α → β} :
    UniformInducing f ↔ UniformContinuous f ∧
      ∀ δ > 0, ∃ ε > 0, ∀ {a b : α}, dist (f a) (f b) < ε → dist a b < δ :=
  uniformInducing_iff'.trans <| Iff.rfl.and <|
    ((uniformity_basis_dist.comap _).le_basis_iff uniformity_basis_dist).trans <| by
      simp only [subset_def, Prod.forall, gt_iff_lt, preimage_setOf_eq, Prod.map_apply, mem_setOf]

nonrec theorem uniformEmbedding_iff [PseudoMetricSpace β] {f : α → β} :
    UniformEmbedding f ↔ Function.Injective f ∧ UniformContinuous f ∧
      ∀ δ > 0, ∃ ε > 0, ∀ {a b : α}, dist (f a) (f b) < ε → dist a b < δ := by
  rw [uniformEmbedding_iff, and_comm, uniformInducing_iff]

/-- If a map between pseudometric spaces is a uniform embedding then the distance between `f x`
and `f y` is controlled in terms of the distance between `x` and `y`. -/
theorem controlled_of_uniformEmbedding [PseudoMetricSpace β] {f : α → β} (h : UniformEmbedding f) :
    (∀ ε > 0, ∃ δ > 0, ∀ {a b : α}, dist a b < δ → dist (f a) (f b) < ε) ∧
      ∀ δ > 0, ∃ ε > 0, ∀ {a b : α}, dist (f a) (f b) < ε → dist a b < δ :=
  ⟨uniformContinuous_iff.1 h.uniformContinuous, (uniformEmbedding_iff.1 h).2.2⟩

theorem totallyBounded_iff {s : Set α} :
    TotallyBounded s ↔ ∀ ε > 0, ∃ t : Set α, t.Finite ∧ s ⊆ ⋃ y ∈ t, ball y ε :=
  uniformity_basis_dist.totallyBounded_iff

/-- A pseudometric space is totally bounded if one can reconstruct up to any ε>0 any element of the
space from finitely many data. -/
theorem totallyBounded_of_finite_discretization {s : Set α}
    (H : ∀ ε > (0 : ℝ),
        ∃ (β : Type u) (_ : Fintype β) (F : s → β), ∀ x y, F x = F y → dist (x : α) y < ε) :
    TotallyBounded s := by
  rcases s.eq_empty_or_nonempty with hs | hs
  · rw [hs]
    exact totallyBounded_empty
  rcases hs with ⟨x0, hx0⟩
  haveI : Inhabited s := ⟨⟨x0, hx0⟩⟩
  refine totallyBounded_iff.2 fun ε ε0 => ?_
  rcases H ε ε0 with ⟨β, fβ, F, hF⟩
  let Finv := Function.invFun F
  refine ⟨range (Subtype.val ∘ Finv), finite_range _, fun x xs => ?_⟩
  let x' := Finv (F ⟨x, xs⟩)
  have : F x' = F ⟨x, xs⟩ := Function.invFun_eq ⟨⟨x, xs⟩, rfl⟩
  simp only [Set.mem_iUnion, Set.mem_range]
  exact ⟨_, ⟨F ⟨x, xs⟩, rfl⟩, hF _ _ this.symm⟩

theorem finite_approx_of_totallyBounded {s : Set α} (hs : TotallyBounded s) :
    ∀ ε > 0, ∃ t, t ⊆ s ∧ Set.Finite t ∧ s ⊆ ⋃ y ∈ t, ball y ε := by
  intro ε ε_pos
  rw [totallyBounded_iff_subset] at hs
  exact hs _ (dist_mem_uniformity ε_pos)

/-- Expressing uniform convergence using `dist` -/
theorem tendstoUniformlyOnFilter_iff {F : ι → β → α} {f : β → α} {p : Filter ι} {p' : Filter β} :
    TendstoUniformlyOnFilter F f p p' ↔
      ∀ ε > 0, ∀ᶠ n : ι × β in p ×ˢ p', dist (f n.snd) (F n.fst n.snd) < ε := by
  refine ⟨fun H ε hε => H _ (dist_mem_uniformity hε), fun H u hu => ?_⟩
  rcases mem_uniformity_dist.1 hu with ⟨ε, εpos, hε⟩
  exact (H ε εpos).mono fun n hn => hε hn

/-- Expressing locally uniform convergence on a set using `dist`. -/
theorem tendstoLocallyUniformlyOn_iff [TopologicalSpace β] {F : ι → β → α} {f : β → α}
    {p : Filter ι} {s : Set β} :
    TendstoLocallyUniformlyOn F f p s ↔
      ∀ ε > 0, ∀ x ∈ s, ∃ t ∈ 𝓝[s] x, ∀ᶠ n in p, ∀ y ∈ t, dist (f y) (F n y) < ε := by
  refine ⟨fun H ε hε => H _ (dist_mem_uniformity hε), fun H u hu x hx => ?_⟩
  rcases mem_uniformity_dist.1 hu with ⟨ε, εpos, hε⟩
  rcases H ε εpos x hx with ⟨t, ht, Ht⟩
  exact ⟨t, ht, Ht.mono fun n hs x hx => hε (hs x hx)⟩

/-- Expressing uniform convergence on a set using `dist`. -/
theorem tendstoUniformlyOn_iff {F : ι → β → α} {f : β → α} {p : Filter ι} {s : Set β} :
    TendstoUniformlyOn F f p s ↔ ∀ ε > 0, ∀ᶠ n in p, ∀ x ∈ s, dist (f x) (F n x) < ε := by
  refine ⟨fun H ε hε => H _ (dist_mem_uniformity hε), fun H u hu => ?_⟩
  rcases mem_uniformity_dist.1 hu with ⟨ε, εpos, hε⟩
  exact (H ε εpos).mono fun n hs x hx => hε (hs x hx)

/-- Expressing locally uniform convergence using `dist`. -/
theorem tendstoLocallyUniformly_iff [TopologicalSpace β] {F : ι → β → α} {f : β → α}
    {p : Filter ι} :
    TendstoLocallyUniformly F f p ↔
      ∀ ε > 0, ∀ x : β, ∃ t ∈ 𝓝 x, ∀ᶠ n in p, ∀ y ∈ t, dist (f y) (F n y) < ε := by
  simp only [← tendstoLocallyUniformlyOn_univ, tendstoLocallyUniformlyOn_iff, nhdsWithin_univ,
    mem_univ, forall_const, exists_prop]

/-- Expressing uniform convergence using `dist`. -/
theorem tendstoUniformly_iff {F : ι → β → α} {f : β → α} {p : Filter ι} :
    TendstoUniformly F f p ↔ ∀ ε > 0, ∀ᶠ n in p, ∀ x, dist (f x) (F n x) < ε := by
  rw [← tendstoUniformlyOn_univ, tendstoUniformlyOn_iff]
  simp

protected theorem cauchy_iff {f : Filter α} :
    Cauchy f ↔ NeBot f ∧ ∀ ε > 0, ∃ t ∈ f, ∀ x ∈ t, ∀ y ∈ t, dist x y < ε :=
  uniformity_basis_dist.cauchy_iff

/-- Given a point `x` in a discrete subset `s` of a pseudometric space, there is an open ball
centered at `x` and intersecting `s` only at `x`. -/
theorem exists_ball_inter_eq_singleton_of_mem_discrete [DiscreteTopology s] {x : α} (hx : x ∈ s) :
    ∃ ε > 0, Metric.ball x ε ∩ s = {x} :=
  nhds_basis_ball.exists_inter_eq_singleton_of_mem_discrete hx

/-- Given a point `x` in a discrete subset `s` of a pseudometric space, there is a closed ball
of positive radius centered at `x` and intersecting `s` only at `x`. -/
theorem exists_closedBall_inter_eq_singleton_of_discrete [DiscreteTopology s] {x : α} (hx : x ∈ s) :
    ∃ ε > 0, Metric.closedBall x ε ∩ s = {x} :=
  nhds_basis_closedBall.exists_inter_eq_singleton_of_mem_discrete hx

end Metric

open Metric

theorem Metric.inseparable_iff {x y : α} : Inseparable x y ↔ dist x y = 0 := by
  rw [EMetric.inseparable_iff, edist_nndist, dist_nndist, ENNReal.coe_eq_zero, NNReal.coe_eq_zero]

section Real

theorem cauchySeq_iff_tendsto_dist_atTop_0 [Nonempty β] [SemilatticeSup β] {u : β → α} :
    CauchySeq u ↔ Tendsto (fun n : β × β => dist (u n.1) (u n.2)) atTop (𝓝 0) := by
  rw [cauchySeq_iff_tendsto, Metric.uniformity_eq_comap_nhds_zero, tendsto_comap_iff,
    Function.comp_def]
  simp_rw [Prod.map_fst, Prod.map_snd]

end Real

namespace Metric

variable {x y z : α} {ε ε₁ ε₂ : ℝ} {s : Set α}

-- Porting note: `TopologicalSpace.IsSeparable.separableSpace` moved to `EMetricSpace`

/-- The preimage of a separable set by an inducing map is separable. -/
protected theorem _root_.Inducing.isSeparable_preimage {f : β → α} [TopologicalSpace β]
    (hf : Inducing f) {s : Set α} (hs : IsSeparable s) : IsSeparable (f ⁻¹' s) := by
  have : SeparableSpace s := hs.separableSpace
  have : SecondCountableTopology s := UniformSpace.secondCountable_of_separable _
  have : Inducing ((mapsTo_preimage f s).restrict _ _ _) :=
    (hf.comp inducing_subtype_val).codRestrict _
  have := this.secondCountableTopology
  exact .of_subtype _

protected theorem _root_.Embedding.isSeparable_preimage {f : β → α} [TopologicalSpace β]
    (hf : Embedding f) {s : Set α} (hs : IsSeparable s) : IsSeparable (f ⁻¹' s) :=
  hf.toInducing.isSeparable_preimage hs

end Metric

/-- A compact set is separable. -/
theorem IsCompact.isSeparable {s : Set α} (hs : IsCompact s) : IsSeparable s :=
  haveI : CompactSpace s := isCompact_iff_compactSpace.mp hs
  .of_subtype s

namespace Metric

section SecondCountable

open TopologicalSpace

/-- A pseudometric space is second countable if, for every `ε > 0`, there is a countable set which
is `ε`-dense. -/
theorem secondCountable_of_almost_dense_set
    (H : ∀ ε > (0 : ℝ), ∃ s : Set α, s.Countable ∧ ∀ x, ∃ y ∈ s, dist x y ≤ ε) :
    SecondCountableTopology α := by
  refine EMetric.secondCountable_of_almost_dense_set fun ε ε0 => ?_
  rcases ENNReal.lt_iff_exists_nnreal_btwn.1 ε0 with ⟨ε', ε'0, ε'ε⟩
  choose s hsc y hys hyx using H ε' (mod_cast ε'0)
  refine ⟨s, hsc, iUnion₂_eq_univ_iff.2 fun x => ⟨y x, hys _, le_trans ?_ ε'ε.le⟩⟩
  exact mod_cast hyx x

end SecondCountable

end Metric