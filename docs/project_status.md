# Project status

This repository is a portfolio-oriented engineering demonstration for a fictional automotive supplier. Sales and product-master data are synthetic; automotive market, calendar and weather inputs are external contextual datasets.

## Implemented

- Synthetic product and daily sales generation in R.
- German automotive market and six-segment sales forecasting, with documented holdout diagnostics and remaining residual autocorrelation.
- Installable Python pipeline package, automated tests, Ruff and GitHub Actions.
- Versioned Azure ML job specifications and documented prior cloud runs.
- Architectural decisions in `docs/decisions/`.

## Outstanding verification

- Re-run the HypoForge experiment after the new dependency is published and pinned to an immutable commit.
- Verify R/Python calendar-feature parity or explicitly accept and quantify the differences; no parity claim is made.
- Confirm exact dataset attribution, source versions, licenses and redistribution permissions in `docs/data_sources.md`.
- Re-run Azure jobs after the repository cleanup if reproducibility of this release is required.

Historical run results in the README refer to earlier recorded executions; they are not a claim that this cleaned release has been re-executed in Azure.
