# Verification report

Date: 2026-09-11 (Asia/Singapore)

## Outcome

The `coniv` 0.1.0 source package, command-line adapter, synthetic examples, documentation, and repository Agent Skill were verified in the authorized local workspace. No patient data, remote repository, release service, or package installation from the network was used.

## Environment

- R 4.4.3, x86_64-w64-mingw32, Windows 11 x64.
- Runtime dependency available: `jsonlite` 2.0.0.
- Git 2.53.0.
- Windows R commands were run after removing externally injected `LC_ALL`, `LC_CTYPE`, and `LANG` values of `C.UTF-8`; Windows R then used its supported UTF-8 locale for the Unicode workspace path.

## Automated checks

1. Source installation into an isolated local library: passed.
2. Six base-R behavior test scripts: passed.
3. `R CMD build`: passed; produced `coniv_0.1.0.tar.gz`.
4. `R CMD check --no-manual`: package log ended with `Status: OK` and all six test scripts passed.

The check runner also attempted to query CRAN and Bioconductor package indexes. Network access was unavailable, so those repository lookups emitted shell-level warnings and the host process returned code 1 even though the package check itself recorded no ERROR, WARNING, or NOTE and ended `Status: OK`. No dependency was downloaded or changed.

## Behaviors covered

- Hand-calculated single-variable identity: estimate equals `(gamma_O - gamma_R) / pi = 8/7` in the worked fixture.
- All four strategies reduce to that same result when only one calibration variable is supplied.
- Continuous and binary examples complete through the same CLI and return four valid strategies.
- Repeated CLI runs produce byte-equivalent parsed numerical estimate tables.
- Screen mode retains the designed strong candidate and records decisions.
- Shared-reference cross-center covariance equals the hand-calculated `97/17010` in the worked fixture.
- FGLS weights sum to one, and full-covariance pooling differs from diagonal-only pooling in a constructed correlated case.
- Weak denominators, a missing reference candidate, invalid binary coding, a missing center-specific variable set, and a singular center covariance matrix fail with explicit reasons.
- The stable output files are written, and the run manifest does not contain input-level data frames.

## Repository and content audit

- Independent Git root is the `coniv-toolkit/` directory; the surrounding research workspace is not tracked.
- Initial implementation commit: `1277b37` (`Implement coniv R package and analysis skill`).
- Tracked files contain no local absolute drive paths and no file larger than 1 MB.
- Package code has no top-level simulation or analysis execution.
- The Skill contains no second estimator and delegates calculation to the CLI/package seam.
- `.Rbuildignore` keeps repository-only Skill files, local verification libraries, check output, and `CITATION.cff` out of the R source tarball while retaining them in Git.

## Skill validation

The official `skill-creator` validator could not start because its local Python environment lacks the `yaml` module (`ModuleNotFoundError: No module named 'yaml'`). Installing it was outside the approved no-install boundary. The validator's documented checks were therefore reproduced locally: frontmatter delimiters, allowed keys, required name/description, hyphen-case name, length limits, angle-bracket exclusion, and unfinished TODO detection all passed.

## Remaining release-only items

- Replace project-level author and copyright placeholders in `DESCRIPTION`, `CITATION.cff`, and `LICENSE` with explicitly approved legal/public metadata.
- Create and push a remote repository only with separate authorization.
- Add CI on other operating systems before claiming cross-platform verification.
- Add a release archive/DOI and update the software availability statement only after those actions occur.

