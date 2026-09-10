# Software availability

The source is structured as the R package `coniv` with a thin command-line adapter and a repository Agent Skill. Version 0.1.0 has been developed and tested locally with R 4.4.3 on 64-bit Windows. The package declares R 4.1.0 or newer and imports `jsonlite`; portability to other operating systems has not yet been verified by continuous integration.

The repository is not currently published to CRAN, GitHub, Zenodo, or another remote archive. A public availability statement must not claim a URL, accession, DOI, release, or review status until the corresponding external action has actually occurred.

For a manuscript before release, an accurate statement is:

> The CON-IV implementation was developed as an R package with a command-line interface. The analysis version, configuration, software versions, selected variables, covariance matrices, diagnostics, and GLS weights are recorded in the run outputs. Public repository and archival identifiers will be added after release.

For a future release, replace the final sentence with the actual immutable release URL and archival identifier, and replace the pending author/copyright metadata in `DESCRIPTION`, `CITATION.cff`, and `LICENSE`.

