# Verification report

Dates: 2026-09-11; rechecked 2026-10-03.

## Outcome

The `coniv` 0.1.0 source package, command-line interface, synthetic examples, documentation, and repository Agent Skill were checked locally. No patient data were used, and no dependency was downloaded.

## Environment

- R 4.4.3, x86_64-w64-mingw32, Windows 11 x64.
- Runtime dependency: `jsonlite` 2.0.0.
- On Windows, R commands were run with `LC_ALL`, `LC_CTYPE`, and `LANG` unset so that R used its supported UTF-8 locale for the Unicode workspace path.

## Automated checks

1. Source installation into an isolated local library: passed.
2. Six base-R behavior test scripts: passed.
3. `R CMD build`: passed; produced `coniv_0.1.0.tar.gz`.
4. `R CMD check --no-manual`: `Status: OK`; all six test scripts passed.

On 2026-10-03, after the package metadata and naming were updated, steps 3 and 4 were repeated with the same result, and both command-line examples and an R-interface example with center-specific variable sets ran successfully.

Without network access, the repository-index lookups made by the check runner emitted shell-level warnings; the package check itself recorded no ERROR, WARNING, or NOTE.

## Behaviors covered

- Hand-calculated single-variable identity: estimate equals `(gamma_O - gamma_R) / pi = 8/7` in the worked fixture.
- All four strategies reduce to that same result when only one CON-IV variable is supplied.
- Continuous and binary examples complete through the same CLI and return four valid strategies.
- Repeated CLI runs produce identical parsed numerical estimate tables.
- Screen mode retains the designed strong candidate and records decisions.
- Shared-reference cross-center covariance equals the hand-calculated `97/17010` in the worked fixture.
- FGLS weights sum to one, and full-covariance pooling differs from diagonal-only pooling in a constructed correlated case.
- Weak denominators, a missing reference candidate, invalid binary coding, a missing center-specific variable set, and a singular center covariance matrix fail with explicit reasons.
- The stable output files are written, and the run manifest does not contain input-level data frames.

## Repository and content audit

- The Git root is the `coniv-toolkit/` directory.
- Tracked files contain no local absolute drive paths and no file larger than 1 MB.
- Package code has no top-level simulation or analysis execution.
- The Skill contains no second estimator and delegates calculation to the CLI and package.
- `.Rbuildignore` keeps repository-only Skill files, local verification libraries, check output, and `CITATION.cff` out of the R source tarball while retaining them in Git.

## Skill check

The Skill frontmatter was checked for delimiters, allowed keys, the required name and description, a hyphen-case name, length limits, and the absence of angle brackets and unfinished TODO markers; all checks passed. The two commands it calls and the documents it references exist and were run or opened successfully.

## Remaining release items

- Create the public repository.
- Add CI on other operating systems before claiming cross-platform verification.
- Add a release archive and DOI, then update the software availability statement.
