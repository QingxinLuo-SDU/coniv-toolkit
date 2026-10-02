---
name: coniv-analysis
description: Run or interpret this repository's MCM-CONIV (multicenter multiple confounding instrumental variables) analysis for continuous outcomes or binary risk differences using observational centers and one shared reference sample. Use when asked to configure, execute, troubleshoot, or explain the four CON-IV strategies, shared-reference covariance, FGLS weights, diagnostics, or output files in this project.
---

# MCM-CONIV analysis

Use the installed `coniv` R package as the only calculation source. Do not reproduce its formulas in another script or calculate replacement estimates from output tables.

## Workflow

1. Read `docs/input-contract.md` and `docs/method-boundaries.md` before configuring a run.
2. Confirm, in order: observational CSV, shared-reference CSV, outcome type, column mapping, candidate variables, and whether selection is `provided` or `screen`. If a required item is missing, ask for only the first missing item.
3. Start from the matching file under `inst/config/`. Keep paths local; do not upload data or install software without explicit approval.
4. Run `Rscript inst/cli/check-environment.R`, then `Rscript inst/cli/coniv.R --config <file>`. If `Rscript` is unavailable on Windows, locate the installed R `bin` directory. Do not modify statistical files under `R/` to bypass an input or environment error.
5. Treat the process exit code and `diagnostics.json` as the success signal. A zero exit can still contain a partially failed strategy; inspect `valid` and `reason` in `estimates.csv`.
6. Read `docs/output-contract.md`, then report the effect scale, estimates, intervals, effective centers, GLS method, negative weights, variable sets, and material diagnostics. Link the output directory and files.

## Interpretation rules

- Call a binary result a risk difference. Never equate it with a latent-scale `beta_XY`.
- Explain that all centers share one reference sample and the full center covariance, including off-diagonal terms, is used.
- If the method is `FGLS_ridge_finite_sample`, report that stabilization occurred and cite the ridge and stabilization diagnostics. Do not call it raw FGLS.
- For `screen`, state that inference is conditional on the selected set and is not selection-adjusted.
- Do not interpret the common-effect FGLS estimate as a population-average effect when center effects may be heterogeneous without an explicit scientific justification.
- Preserve failures such as weak denominators, missing variables, invalid binary coding, or a non-invertible covariance matrix. Do not silently drop data or relax thresholds to force success.

The Skill may create or edit configuration and derived output files inside the authorized workspace. It must not publish a repository, send external messages, use patient data outside its authorized environment, or claim CRAN/GitHub/Zenodo availability that has not been verified.

