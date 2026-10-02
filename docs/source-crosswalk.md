# Source-to-package crosswalk

Version 0.1.0 was derived from the 2026-08 CON-IV simulation implementation after separating estimation from simulation, comparison methods, hard-coded paths, and top-level execution.

| Package component | Preserved methodological role | Deliberate change |
|---|---|---|
| `R/slope_if.R` | Marginal slopes and shared-reference joint influence contributions | One complete HC0/HC1 implementation for both outcome types |
| `R/center_estimation.R` | Single- and multi-variable center moment estimator and delta variance | Continuous outcomes use the same complete outcome/exposure/cross-covariance structure instead of the older diagonal approximation |
| `R/selection.R` | Common versus center-specific, single versus multiple CON-IV variable sets | Decisions and rejection reasons are returned as data rather than hidden in a simulation loop |
| `R/covariance_gls.R` | Shared-reference off-diagonal covariance and common-effect GLS | Raw, symmetrized, and used matrices plus normalized weights are retained; no silent `nearPD` or generalized inverse |
| `R/run_coniv.R` | Four-strategy analysis orchestration | Pure in-memory calculation is separated from output writing |
| `inst/cli/coniv.R` | Reproducible external entry | Thin adapter only; no statistical formulas or simulations |

The source archives remain read-only and are not bundled into the package. The finite-dimensional Lean work is also intentionally outside the runtime and was not duplicated.

