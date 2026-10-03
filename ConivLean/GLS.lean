import ConivLean.Definitions

/-!
# Finite-center generalized least squares for CON-IV

The optimization theorem is stated first for a supplied positive-definite precision matrix. The
covariance-form corollaries instantiate that precision matrix with a positive-definite inverse.
The final covariance quadratic form is deterministic and is not called a random-estimator variance.
-/

namespace ConivLean

open Matrix

universe u

variable {ι : Type u}

noncomputable section

theorem ones_ne_zero [Nonempty ι] : (ones : ι → ℝ) ≠ 0 := by
  intro h
  let i : ι := Classical.choice inferInstance
  have hi := congr_fun h i
  norm_num [ones] at hi

theorem glsDenominator_pos [Fintype ι] [Nonempty ι]
    {precision : Matrix ι ι ℝ} (hprecision : precision.PosDef) :
    0 < glsDenominator precision := by
  simpa [glsDenominator] using
    hprecision.dotProduct_mulVec_pos (ones_ne_zero (ι := ι))

theorem sum_glsWeights_eq_one [Fintype ι]
    {precision : Matrix ι ι ℝ} (hden : glsDenominator precision ≠ 0) :
    (ones : ι → ℝ) ⬝ᵥ glsWeights precision = 1 := by
  simpa [glsWeights, dotProduct_smul, glsDenominator] using
    inv_mul_cancel₀ hden

theorem glsEstimate_eq_dotProduct_weights [Fintype ι] [Nonempty ι]
    {precision : Matrix ι ι ℝ} (hprecision : precision.PosDef)
    (centerEstimate : ι → ℝ) :
    glsEstimate precision centerEstimate = glsWeights precision ⬝ᵥ centerEstimate := by
  have hsymm : precision.IsSymm := by
    simpa [Matrix.isHermitian_iff_isSymm] using hprecision.1
  have hbilin : (precision *ᵥ (ones : ι → ℝ)) ⬝ᵥ centerEstimate =
      (ones : ι → ℝ) ⬝ᵥ (precision *ᵥ centerEstimate) := by
    calc
      (precision *ᵥ (ones : ι → ℝ)) ⬝ᵥ centerEstimate =
          centerEstimate ⬝ᵥ (precision *ᵥ ones) := dotProduct_comm _ _
      _ = (ones : ι → ℝ) ⬝ᵥ (precisionᵀ *ᵥ centerEstimate) :=
        (dotProduct_transpose_mulVec precision ones centerEstimate).symm
      _ = (ones : ι → ℝ) ⬝ᵥ (precision *ᵥ centerEstimate) := by rw [hsymm.eq]
  rw [glsEstimate, glsWeights, smul_dotProduct, hbilin]
  simp [div_eq_mul_inv, mul_comm]

lemma gls_normalEquation [Fintype ι] [Nonempty ι]
    {precision : Matrix ι ι ℝ} (hprecision : precision.PosDef)
    (centerEstimate : ι → ℝ) :
    (ones : ι → ℝ) ⬝ᵥ
      (precision *ᵥ (centerEstimate - glsEstimate precision centerEstimate • ones)) = 0 := by
  rw [Matrix.mulVec_sub, Matrix.mulVec_smul, dotProduct_sub, dotProduct_smul]
  have hden : glsDenominator precision ≠ 0 := ne_of_gt (glsDenominator_pos hprecision)
  change (ones ⬝ᵥ precision *ᵥ centerEstimate) -
      ((ones ⬝ᵥ precision *ᵥ centerEstimate) / glsDenominator precision) *
        glsDenominator precision = 0
  exact sub_eq_zero.mpr (div_mul_cancel₀ _ hden).symm

lemma gls_crossTerm_eq_zero [Fintype ι] [Nonempty ι]
    {precision : Matrix ι ι ℝ} (hprecision : precision.PosDef)
    (centerEstimate : ι → ℝ) :
    (centerEstimate - glsEstimate precision centerEstimate • ones) ⬝ᵥ
      (precision *ᵥ (ones : ι → ℝ)) = 0 := by
  have hsymm : precision.IsSymm := by
    simpa [Matrix.isHermitian_iff_isSymm] using hprecision.1
  calc
    (centerEstimate - glsEstimate precision centerEstimate • ones) ⬝ᵥ
        (precision *ᵥ (ones : ι → ℝ)) =
        (ones : ι → ℝ) ⬝ᵥ
          (precisionᵀ *ᵥ (centerEstimate - glsEstimate precision centerEstimate • ones)) :=
      (dotProduct_transpose_mulVec precision ones
        (centerEstimate - glsEstimate precision centerEstimate • ones)).symm
    _ = (ones : ι → ℝ) ⬝ᵥ
        (precision *ᵥ (centerEstimate - glsEstimate precision centerEstimate • ones)) := by
      rw [hsymm.eq]
    _ = 0 := gls_normalEquation hprecision centerEstimate

theorem glsObjective_decomposition [Fintype ι] [Nonempty ι]
    {precision : Matrix ι ι ℝ} (hprecision : precision.PosDef)
    (centerEstimate : ι → ℝ) (theta : ℝ) :
    glsObjective precision centerEstimate theta =
      glsObjective precision centerEstimate (glsEstimate precision centerEstimate) +
        glsDenominator precision * (theta - glsEstimate precision centerEstimate) ^ 2 := by
  let thetaHat := glsEstimate precision centerEstimate
  let residual := centerEstimate - thetaHat • (ones : ι → ℝ)
  have hcenter : centerEstimate - theta • (ones : ι → ℝ) =
      residual - (theta - thetaHat) • (ones : ι → ℝ) := by
    ext i
    simp [residual, thetaHat, ones]
  have hcross : residual ⬝ᵥ (precision *ᵥ (ones : ι → ℝ)) = 0 := by
    simpa [residual, thetaHat] using gls_crossTerm_eq_zero hprecision centerEstimate
  have hcross' : (ones : ι → ℝ) ⬝ᵥ (precision *ᵥ residual) = 0 := by
    have hsymm : precision.IsSymm := by
      simpa [Matrix.isHermitian_iff_isSymm] using hprecision.1
    calc
      (ones : ι → ℝ) ⬝ᵥ (precision *ᵥ residual) =
          residual ⬝ᵥ (precisionᵀ *ᵥ ones) :=
        (dotProduct_transpose_mulVec precision residual ones).symm
      _ = residual ⬝ᵥ (precision *ᵥ ones) := by rw [hsymm.eq]
      _ = 0 := hcross
  change (centerEstimate - theta • (ones : ι → ℝ)) ⬝ᵥ
      (precision *ᵥ (centerEstimate - theta • (ones : ι → ℝ))) =
    (centerEstimate - thetaHat • (ones : ι → ℝ)) ⬝ᵥ
      (precision *ᵥ (centerEstimate - thetaHat • (ones : ι → ℝ))) +
        glsDenominator precision * (theta - thetaHat) ^ 2
  rw [hcenter]
  change (residual - (theta - thetaHat) • (ones : ι → ℝ)) ⬝ᵥ
      (precision *ᵥ (residual - (theta - thetaHat) • (ones : ι → ℝ))) =
    residual ⬝ᵥ (precision *ᵥ residual) +
      glsDenominator precision * (theta - thetaHat) ^ 2
  simp only [Matrix.mulVec_sub, Matrix.mulVec_smul, dotProduct_sub,
    dotProduct_smul, sub_dotProduct, smul_dotProduct]
  simp only [hcross, hcross', zero_sub]
  simp only [glsDenominator]
  ring

theorem glsEstimate_minimizes [Fintype ι] [Nonempty ι]
    {precision : Matrix ι ι ℝ} (hprecision : precision.PosDef)
    (centerEstimate : ι → ℝ) (theta : ℝ) :
    glsObjective precision centerEstimate (glsEstimate precision centerEstimate) ≤
      glsObjective precision centerEstimate theta := by
  rw [glsObjective_decomposition hprecision centerEstimate theta]
  exact le_add_of_nonneg_right
    (mul_nonneg (le_of_lt (glsDenominator_pos hprecision)) (sq_nonneg _))

theorem glsEstimate_unique_minimizer [Fintype ι] [Nonempty ι]
    {precision : Matrix ι ι ℝ} (hprecision : precision.PosDef)
    (centerEstimate : ι → ℝ) {theta : ℝ}
    (heq : glsObjective precision centerEstimate theta =
      glsObjective precision centerEstimate (glsEstimate precision centerEstimate)) :
    theta = glsEstimate precision centerEstimate := by
  rw [glsObjective_decomposition hprecision centerEstimate theta] at heq
  have hprod : glsDenominator precision *
      (theta - glsEstimate precision centerEstimate) ^ 2 = 0 := by
    linarith
  have hsq : (theta - glsEstimate precision centerEstimate) ^ 2 = 0 :=
    (mul_eq_zero.mp hprod).resolve_left (ne_of_gt (glsDenominator_pos hprecision))
  nlinarith

theorem gls_covarianceForm_minimizes [Fintype ι] [Nonempty ι] [DecidableEq ι]
    {covariance : Matrix ι ι ℝ} (hcovariance : covariance.PosDef)
    (centerEstimate : ι → ℝ) (theta : ℝ) :
    glsObjective covariance⁻¹ centerEstimate (glsEstimate covariance⁻¹ centerEstimate) ≤
      glsObjective covariance⁻¹ centerEstimate theta :=
  glsEstimate_minimizes hcovariance.inv centerEstimate theta

lemma covariance_mulVec_glsWeights [Fintype ι] [Nonempty ι] [DecidableEq ι]
    {covariance : Matrix ι ι ℝ} (hcovariance : covariance.PosDef) :
    covariance *ᵥ glsWeights covariance⁻¹ =
      (glsDenominator covariance⁻¹)⁻¹ • (ones : ι → ℝ) := by
  letI := hcovariance.isUnit.invertible
  rw [glsWeights, Matrix.mulVec_smul, Matrix.mulVec_mulVec,
    Matrix.mul_inv_of_invertible, Matrix.one_mulVec]

theorem glsWeights_covariance_quadraticForm [Fintype ι] [Nonempty ι] [DecidableEq ι]
    {covariance : Matrix ι ι ℝ} (hcovariance : covariance.PosDef) :
    glsWeights covariance⁻¹ ⬝ᵥ (covariance *ᵥ glsWeights covariance⁻¹) =
      (glsDenominator covariance⁻¹)⁻¹ := by
  rw [covariance_mulVec_glsWeights hcovariance, dotProduct_smul]
  rw [dotProduct_comm]
  rw [sum_glsWeights_eq_one (ne_of_gt (glsDenominator_pos hcovariance.inv))]
  simp

end

end ConivLean
