import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.Algebra.Order.Star.Real

/-!
# Deterministic definitions for the CON-IV algebraic layer

These are supplied finite-dimensional moments and functionals. They are not random estimators and
do not by themselves establish causal identification.
-/

namespace ConivLean

open Matrix

universe u

variable {ι : Type u}

noncomputable section

/-- Observed-center moment minus randomized-reference moment. -/
def momentContrast (gammaObs gammaRef : ℝ) : ℝ := gammaObs - gammaRef

/-- Numerator `pi' W delta` of the weighted CON-IV functional. -/
def weightedNumerator [Fintype ι] (W : Matrix ι ι ℝ) (pi delta : ι → ℝ) : ℝ :=
  pi ⬝ᵥ (W *ᵥ delta)

/-- Denominator `pi' W pi` of the weighted CON-IV functional. -/
def weightedDenominator [Fintype ι] (W : Matrix ι ι ℝ) (pi : ι → ℝ) : ℝ :=
  pi ⬝ᵥ (W *ᵥ pi)

/-- Deterministic weighted observed-moment functional. -/
def weightedMomentEstimate [Fintype ι] (W : Matrix ι ι ℝ)
    (pi delta : ι → ℝ) : ℝ :=
  weightedNumerator W pi delta / weightedDenominator W pi

/-- The all-ones vector for a finite family of centers. -/
def ones : ι → ℝ := fun _ => 1

/-- GLS normalizing denominator `1' P 1`. -/
def glsDenominator [Fintype ι] (precision : Matrix ι ι ℝ) : ℝ :=
  (ones : ι → ℝ) ⬝ᵥ (precision *ᵥ ones)

/-- Closed-form common-effect GLS functional for a supplied precision matrix. -/
def glsEstimate [Fintype ι] (precision : Matrix ι ι ℝ)
    (centerEstimate : ι → ℝ) : ℝ :=
  ((ones : ι → ℝ) ⬝ᵥ (precision *ᵥ centerEstimate)) / glsDenominator precision

/-- Normalized GLS weight vector. -/
def glsWeights [Fintype ι] (precision : Matrix ι ι ℝ) : ι → ℝ :=
  (glsDenominator precision)⁻¹ • (precision *ᵥ (ones : ι → ℝ))

/-- GLS quadratic objective at a scalar common-effect candidate. -/
def glsObjective [Fintype ι] (precision : Matrix ι ι ℝ)
    (centerEstimate : ι → ℝ) (theta : ℝ) : ℝ :=
  (centerEstimate - theta • (ones : ι → ℝ)) ⬝ᵥ
    (precision *ᵥ (centerEstimate - theta • (ones : ι → ℝ)))

end

end ConivLean
