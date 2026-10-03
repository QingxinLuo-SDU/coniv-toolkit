import ConivLean.Definitions

/-!
# Arbitrary finite-dimensional CON-IV weighted moment algebra

No symmetry or positive-definiteness of `W` is needed for these identities. Relevance is exposed as
the exact nonzero denominator used for field cancellation.
-/

namespace ConivLean

open Matrix

universe u

variable {ι : Type u}

noncomputable section

theorem weightedNumerator_eq_theta_mul_denominator [Fintype ι]
    (W : Matrix ι ι ℝ) (pi delta : ι → ℝ) (theta : ℝ)
    (hmoment : delta = theta • pi) :
    weightedNumerator W pi delta = theta * weightedDenominator W pi := by
  subst delta
  simp [weightedNumerator, weightedDenominator, Matrix.mulVec_smul, dotProduct_smul]

theorem weightedMoment_identification [Fintype ι]
    (W : Matrix ι ι ℝ) (pi delta : ι → ℝ) (theta : ℝ)
    (hmoment : delta = theta • pi)
    (hden : weightedDenominator W pi ≠ 0) :
    weightedMomentEstimate W pi delta = theta := by
  rw [weightedMomentEstimate,
    weightedNumerator_eq_theta_mul_denominator W pi delta theta hmoment]
  exact mul_div_cancel_right₀ theta hden

theorem weightedMoment_bias [Fintype ι]
    (W : Matrix ι ι ℝ) (pi delta transportBias : ι → ℝ) (theta : ℝ)
    (hmoment : delta = theta • pi + transportBias)
    (hden : weightedDenominator W pi ≠ 0) :
    weightedMomentEstimate W pi delta - theta =
      weightedNumerator W pi transportBias / weightedDenominator W pi := by
  subst delta
  have hden' : pi ⬝ᵥ (W *ᵥ pi) ≠ 0 := by
    simpa [weightedDenominator] using hden
  simp only [weightedMomentEstimate, weightedNumerator, Matrix.mulVec_add, dotProduct_add,
    Matrix.mulVec_smul, dotProduct_smul, weightedDenominator]
  field_simp [hden']
  ring

theorem weightedMoment_bias_eq_zero [Fintype ι]
    (W : Matrix ι ι ℝ) (pi delta : ι → ℝ) (theta : ℝ)
    (hmoment : delta = theta • pi)
    (hden : weightedDenominator W pi ≠ 0) :
    weightedMomentEstimate W pi delta - theta = 0 := by
  rw [weightedMoment_identification W pi delta theta hmoment hden]
  ring

end


end ConivLean
