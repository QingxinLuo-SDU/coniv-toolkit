# Input contract

Version 0.1.0 accepts either an R configuration list or a JSON file. A JSON run points to two local CSV files:

- `observational_path`: long-format rows from all observational centers.
- `reference_path`: rows from the one shared randomized or interventional reference sample.

An R list may instead contain data frames named `observational_data` and `reference_data`.

## Required fields

```json
{
  "outcome_type": "continuous",
  "observational_path": "observational.csv",
  "reference_path": "reference.csv",
  "columns": {
    "center": "centre",
    "exposure": "X",
    "outcome": "Y"
  },
  "candidate_variables": ["Z1", "Z2"],
  "selection": {
    "mode": "provided",
    "shared": ["Z1"],
    "center_specific": {"A": ["Z1"], "B": ["Z2"]}
  }
}
```

`outcome_type` is `continuous` or `binary`. Binary outcomes must be numeric 0/1 in both datasets. The observation file must contain the mapped center, exposure, outcome, and every candidate column. The reference file must contain the mapped outcome and the same candidate columns; a reference exposure column is not used by the estimator.

Exposure, outcome, and candidates must be numeric, finite, and complete. Version 0.1.0 does not impute missing values. Center identifiers must be nonmissing and nonempty. Candidate variable names and their order are checked against the shared reference covariance calculation.

## Strategies

`strategies` may contain any subset of:

- `IV_single_same`
- `IV_single_diff`
- `IV_multi_same`
- `IV_multi_diff`

The default runs all four.

## Variable selection

For `mode = "provided"`, `shared` supplies the common set and `center_specific` supplies a named set for every observed center. Single-variable strategies take the first variable in the relevant set.

For `mode = "screen"`, the available controls are:

- `pi_min` (default `0.02`): minimum absolute marginal exposure slope.
- `F_min` (default `10`): minimum exposure-model F statistic.
- `p_y_cutoff` (default `0.10`): maximum candidate p value in the outcome screen.
- `y_adjust_x` (default `true`): use `Y ~ X + Z`; if false use `Y ~ Z`.
- `correlation_threshold` (default `0.90`): remove a lower-ranked candidate when its absolute correlation with a retained candidate exceeds the threshold.
- `multi_iv_threshold` (default `5`): a multi strategy uses only its first ranked candidate until more than this many candidates survive.
- `max_iv` (default unlimited): maximum retained candidates after the multi threshold is crossed.

Common-set screening uses the largest observational center. Every candidate-level result is written to `selected_variables.csv`. Inference remains conditional on the final selected set.

## Estimation controls

- `hc_type`: `HC0` or `HC1`; default `HC1`.
- `min_n`: minimum observations needed for each slope calculation; default `20`.
- `min_abs_pi`: minimum absolute center treatment-association component; default `0.02`.
- `weight_type_multi`: `identity`, `diag_delta`, or `inv_delta`; default `diag_delta`.
- `ridge_relative`: nonnegative ridge relative to the largest diagonal variance. Default `0`, which fails rather than stabilizes a non-positive-definite center covariance matrix.

`output_dir` is used by the CLI unless `--output` overrides it. `random_seed` is recorded for provenance; version 0.1.0 estimation is deterministic and does not consume random numbers.

