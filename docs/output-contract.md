# Output contract

`run_coniv(config)` returns an in-memory `coniv_result` and does not write files. `write_coniv_results(result, output_dir)` writes only derived estimates, diagnostics, and provenance; it does not copy input rows.

## Tables

- `estimates.csv`: one row per requested strategy with validity, reason, common estimate, standard error, variance, 95% normal interval, two-sided p value, valid-center count, and GLS method.
- `center_estimates.csv`: strategy-by-center estimates, standard errors, denominator, variable set, and failure reason.
- `selected_variables.csv`: candidate-level selection mode, rank, decision/reason, treatment slope, F statistic, and screening p values.
- `gls_weights.csv`: center order, center estimate, normalized weight, contribution, and negative-weight flag.
- `paper_table.csv` and `paper_table.md`: a compact review-ready subset of the overall estimates.

## Matrices

The `matrices/` directory contains up to three CSV files per strategy:

- `<strategy>-V_raw.csv`: center covariance before numerical symmetrization.
- `<strategy>-V_sym.csv`: `(V_raw + t(V_raw)) / 2`.
- `<strategy>-V_used.csv`: the matrix actually inverted, including any explicitly configured ridge.

Missing matrix files indicate that a strategy failed before that matrix was available; consult diagnostics rather than treating missing off-diagonal terms as zero.

## Diagnostics and provenance

- `diagnostics.json`: strategy validity, failure reason, center order, raw symmetry error, extreme eigenvalues, raw condition number, GLS label, ridge added, and stabilization norm.
- `run_manifest.json`: overall/partial status, package and dependency versions, outcome scale, requested strategies, sample sizes, center order, recorded seed, R version, platform, and generation time.
- `run.log`: a patient-row-free run summary intended for quick triage, not as the source of numerical truth.

A run may be partially successful. Always inspect the `valid` and `reason` fields by strategy. Repeated deterministic runs should match numerically; `generated_at` and paths/timestamps outside the numerical tables may differ.

