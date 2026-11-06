/-
Copyright (c) 2026 David Ledvinka. All rights reserved.
Released under Apache 2.0; see third_party/lean-eval/LICENSE.
Authors: David Ledvinka

Adapted for this challenge: imports consolidated, evaluation marker and docstrings removed,
and the unproved theorem represented as Problem.Statement.
-/

import Mathlib

set_option autoImplicit false

namespace Problem

open Laplacian Metric ContDiff MeasureTheory ENNReal

section Definitions

variable {E F : Type*} [NormedAddCommGroup E] [NormedAddCommGroup F]

noncomputable def eC1NormOn [NormedSpace ℝ E] [NormedSpace ℝ F] [MeasurableSpace E]
    (f : E → F) (s : Set E) (μ : Measure E := by volume_tac) : ℝ≥0∞ :=
  eLpNorm f ∞ (μ.restrict s) + eLpNorm (fderiv ℝ f) ∞ (μ.restrict s)

variable [InnerProductSpace ℝ E] [InnerProductSpace ℝ F]

noncomputable def H [CompleteSpace E] (f : E → ℝ) (s : Set E) (x : E) : E →L[ℝ] E :=
  InnerProductSpace.continuousLinearMapOfBilin (fderivWithin ℝ (fderivWithin ℝ f s) s x)

variable [FiniteDimensional ℝ E] [FiniteDimensional ℝ F]

noncomputable def frobeniusNorm (T : E →L[ℝ] F) : ℝ :=
  √ ((T.toLinearMap.adjoint ∘ₗ T).trace ℝ E)

open Classical in
noncomputable def σ₂ (T : E →L[ℝ] E) : ℝ :=
  if hT : T.IsSymmetric then
    ∑ j, ∑ i < j, hT.eigenvalues rfl i * hT.eigenvalues rfl j
  else
    0

end Definitions

local notation "‖" f "‖_C¹(" s ")" => eC1NormOn f s volume

local notation "‖" T "‖_F" => frobeniusNorm T

local notation "ℝ⁴" => EuclideanSpace ℝ (Fin 4)

local notation "B₁(0)" => ball 0 1

def Statement : Prop :=
  ∃ C : ℝ≥0∞ → ℝ, ∀ (u : ℝ⁴ → ℝ)
    (_smooth : ContDiffOn ℝ ∞ u B₁(0))
    (_bounded : ‖u‖_C¹(B₁(0)) < (∞ : ℝ≥0∞))
    (_positive_branch : ∀ x ∈ B₁(0), (Δ u) x > 0)
    (_solution : ∀ x ∈ B₁(0), σ₂ (H u B₁(0) x) = 1),
    ‖H u B₁(0) 0‖_F ≤ C (‖u‖_C¹(B₁(0)))

end Problem
