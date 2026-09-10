# Method boundaries

## Estimand and identification

For each observational center and calibration variable, the core identity is

`theta = (gamma_O - gamma_R) / pi`,

where `gamma_O` is the observational marginal outcome association, `gamma_R` is the shared-reference marginal outcome association, and `pi` is the observational exposure association. Multiple-variable strategies combine analogous moment conditions using a specified weight matrix.

For binary outcomes, `theta` is estimated on the risk-difference scale through linear probability slopes. A latent data-generating coefficient such as `beta_XY` is not this estimand.

The estimator depends on the scientific CON-IV assumptions, including transportability of the non-treatment outcome association from the shared reference population to each center, exposure independence in the randomized/interventional reference, and nonzero observational exposure associations. Software diagnostics cannot verify these assumptions.

## Variance and multicenter combination

Slope associations use intercept-adjusted marginal OLS and sample-scaled influence contributions. Center variance uses a complete delta expansion containing outcome, exposure, and their cross-covariance terms.

The same reference rows contribute to every center estimate. Consequently, the center covariance matrix generally has nonzero off-diagonal entries. The common effect is combined with full-matrix FGLS, not an independent-study diagonal approximation.

Raw FGLS requires a positive-definite invertible covariance matrix. If `ridge_relative > 0` and stabilization is needed, the software retains all matrix versions and labels the result `FGLS_ridge_finite_sample`. Version 0.1.0 does not silently use a generalized inverse or nearest-positive-definite replacement.

## Interpretation limits

- FGLS is a common-effect combination. Under uncontrolled center effect heterogeneity, it must not automatically be interpreted as a population-average causal effect.
- Automatic screening is data dependent. Reported intervals and p values condition on the final variable set; version 0.1.0 does not provide post-selection-valid inference.
- Complete-case inputs are required. The package does not address missing-data mechanisms.
- Normal critical values are used for the overall interval and p value.
- A weak or nearzero denominator is reported as failure. Users should not reduce `min_abs_pi` merely to obtain an estimate without a scientific weak-identification analysis.
- Synthetic examples demonstrate mechanics, not empirical performance or clinical validity.

Version 0.1.0 does not include data generation, traditional comparator estimators, bootstrap selection inference, random-effects meta-analysis, multiple-outcome correction, database access, patient-level preprocessing, or Lean formalization.

