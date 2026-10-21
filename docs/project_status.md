# WKR Automotive Forecasting Lab — Engineering Development Log

**Project:** WKR Automotive Forecasting Lab  
**Scope:** Public technical development record  
**Source of historical milestones:** The project's original internal status document (dated 2026-09-20), cross-referenced with repository decision records.  
**Important:** Historical run results are reported as recorded at the time. They are not a claim that the current cleaned repository has been rerun or revalidated.

## 1. Project purpose and scope

WKR Automotive Forecasting Lab demonstrates an end-to-end forecasting and ML engineering workflow for **WKR Komponenten KGaA**, a fictional German automotive supplier. The WKR company, product master and sales observations are synthetic. Automotive-market, weather and calendar inputs provide external context and have separate provenance and licensing considerations.

The central engineering objective is to carry one coherent analytical workload from data generation through model validation, packaging, automated tests, version-controlled Azure ML job specifications and cloud execution.

The business question is how German sales and the product mix across six segments could develop under changes in vehicle production, registrations, drivetrain mix and calendar-related operating patterns. This is a simulation and engineering exercise, not a real company's forecast.

## 2. System architecture

```text
Synthetic product master + synthetic daily sales
                    |
Automotive market + calendar + weather context
                    |
          Data contracts / validation
                    |
         Six-segment sales forecast
                    |
         Holdout + residual diagnostics
                    |
     Installable Python package and tests
                    |
         Version-controlled Azure ML YAML
                    |
       Azure ML command job and artifacts
```

The repository contains R-based reference and synthetic-data generation scripts, a Python package under `src/wkr_pipeline/`, tests under `tests/`, Azure ML job definitions under `azureml/`, and architecture decisions under `docs/decisions/`.

The R and Python implementations are **not asserted to be numerically identical**. Known differences are recorded below.

## 3. Development milestones

### 3.1 Analytical workload and synthetic data

The initial workload defined a fictional automotive supplier, six product segments, a 24,000-item synthetic product master, and daily synthetic sales. The original design used a fixed seed for product generation, market and drivetrain relevance, daily calendar effects, and persistent stochastic variation.

Key files:
- `R/generate_product_master.R`
- `R/generate_sales_daily_de.R`
- `R/forecast_automotive_market_de.R`
- `data/raw/automotive_market_de.csv`
- `data/forecast/automotive_market_de_forecast_2026.csv`

The sales generator expects the `registrations_bev` input and distinguishes BEV from non-BEV exposure, with stronger production sensitivity for original-equipment sales than for replacement demand. These assumptions are part of the synthetic data-generating process, not empirical causal estimates.

### 3.2 Calendar pipeline and first Azure ML job

The Python calendar pipeline uses holiday-event inputs, expands them to relevant dates and states, derives timing features, validates outputs, and generates comparison diagnostics against a legacy calendar representation.

The original project record documents an initial Azure resource-allocation problem in **West Europe**. The project subsequently used **Poland Central**, where a calendar command job completed successfully. The historical run was recorded as `coral_pear_6pll5ty44w`.

The calendar comparison was not perfect. The original report recorded 21,181 common rows, 467 `Ferien` mismatches, 42 `Weihnachten` mismatches, and no mismatches on the common rows for several other reported holiday fields. These are **historical comparison results**, not a current regression-test guarantee.

**Engineering lesson:** A successful cloud run and an exact reproduction of a reference dataset are separate acceptance criteria. Infrastructure failures also need to be distinguished from code and data failures.

See `docs/decisions/0003-first-azure-ml-job.md` and `docs/run-github-code-on-azure-ml.md`.

### 3.3 Sales forecast: data-contract failure and recovery

The first cloud sales-forecast attempt exposed a missing `registrations_bev` column. The original status document describes a GitHub-side correction followed by a successful Azure rerun, recorded as `amiable_carrot_10g1wp89q4`.

This is a useful engineering incident because the failure was not solved by weakening the model's expectations: the required input contract had to be satisfied.

**Engineering lesson:** Diagnose failures at the right layer. Data schema, feature generation, package execution, environment resolution and cloud orchestration are different responsibilities. A data-contract error should be repaired and tested as such.

See `docs/data_contract.md`, `docs/decisions/0004-first-cloud-sales-forecast.md`, and `docs/sales_forecast_pipeline.md`.

### 3.4 Forecast acceptance and statistical limitations

The historical Azure forecast was accepted as a working engineering baseline, not as a statistically flawless model. The original report recorded segment holdout errors and diagnostics, including Durbin–Watson values around 1.23–1.27, positive lag-one residual autocorrelation, and Ljung–Box results inconsistent with independent residuals.

The original record reported a synthetic September–December 2026 aggregate forecast of approximately **EUR 111.89 million**. This is an output of the fictional workload, not a real business result.

**Methodological lesson:** A pipeline can be operationally successful while retaining known statistical limitations. Residual dependence should be visible in the documentation and evaluated against the intended use, rather than hidden behind a successful job status.

The project deliberately did not reopen every settled autoregressive modeling choice while shifting attention to engineering reliability. This was a scope decision, not proof that the model was optimal.

## 4. Engineering decisions and lessons

### 4.1 GitHub as the source of truth

The intended workflow is to version the code, environment and job specification together, then submit the version-controlled Azure ML job. The original project established the chain:

```text
GitHub source → Azure ML YAML → workspace/compute/environment
              → command execution → named outputs → validation
```

This avoids relying on undocumented manual edits in a cloud session. The YAML specifies **how and where a job is run**; Python and R define the computation.

### 4.2 Batch workflow before API deployment

The project chose a reproducible batch workload as its initial engineering target. An API or always-on service was not necessary to prove data preparation, forecasting, artifact production and job reproducibility.

See `docs/decisions/0001-batch-before-api.md`.

### 4.3 R reference and Python engineering implementation

The architecture separates an R-oriented analytical reference and synthetic-data process from the installable Python engineering pipeline.

The original project status explicitly records two known differences:

| Concern | R data-generating process | Python implementation recorded in the original status |
|---|---|---|
| Regional calendar weights | Explicit seven-state weights (including Niedersachsen 0.30) | Simpler dynamic weighting with extra weight for Niedersachsen |
| Summer shutdown | Approximately July 20–August 15 | Broadly July/August |
| Year-end shutdown | Approximately December 23–January 2 | Broadly December 20–31 |

These differences may be intentional approximations, but **cross-language parity has not been established**. They should either be reconciled or explicitly covered by comparison tests before claiming the Python implementation reproduces the R reference.

See `docs/decisions/0002-r-reference-python-engineering.md` and `docs/calendar_parity.md`.

### 4.4 Packaging and test isolation

The current repository uses a `src/` layout and tests under `tests/`. This layout is intended to test an installable package rather than accidentally importing local source files by path.

A previous review identified the risk of tests importing directly from `src`, which can mask packaging errors. The appropriate acceptance criterion is an installation-based test run in a clean environment, alongside linting and CI. The historical status document predates some of these later improvements, so it should not be read as evidence of their successful execution.

### 4.5 CI and cloud execution are different layers

The original status document records a concept-first exploration of CI, including GitHub Actions, hosted runners, triggers and test execution. It initially proposed keeping Azure job submission outside CI.

The cleaned repository now contains `.github/workflows/ci.yml`, but the presence of this file does not itself establish a green run. Check the GitHub Actions results on the published commit.

Azure execution requires separate consideration of identity, permissions, environment and compute. No credentials should be committed to the repository.

## 5. Data contracts, sources and reproducibility

- **Synthetic data:** WKR-specific product, sales and company information are fictional.
- **Automotive market:** External market observations need an explicit, verified source and usage statement; see `docs/data_sources.md`.
- **Calendar:** The project has used OpenHolidays API events and a legacy research-derived calendar representation. The latter should not be described as a fully verified authoritative holiday dataset.
- **Weather:** The file `data/raw/germany_weekly_weather_features.csv` contains derived weather features. Its neutral name does not replace source attribution or licensing review.
- **Encoding:** The historical calendar data includes UTF-8 BOM and state names such as `Thüringen`; the Python calendar pipeline explicitly handles `utf-8-sig`.

The historical calendar comparison recorded both mismatched values and differing row coverage. The data contract should specify not only column names and types but also temporal coverage, geographic coverage and the meaning of derived features.

## 6. Current repository capabilities

The cleaned repository includes:

- R scripts for synthetic product and sales generation and market forecasting.
- Python package modules for calendar processing and sales forecasting.
- Python tests and a GitHub Actions workflow.
- Azure ML job and environment specifications.
- Architecture documentation, data contracts and decision records.
- A HypoForge forecasting experiment under `experiments/hypoforge_forecast/`.

The HypoForge experiment must be checked against an **existing, installable repository revision** before being described as reproducible. A placeholder tag or unverified Git reference is not sufficient.

## 7. Validation evidence and open checks

| Area | Evidence available | Status / qualification |
|---|---|---|
| Historical Azure calendar job | Completed run recorded in the original project status | Historical evidence; not rerun here |
| Historical Azure sales forecast | Successful rerun recorded after schema correction | Historical evidence; not rerun here |
| Statistical diagnostics | Holdout and residual metrics recorded in the original status | Residual autocorrelation remains |
| Python tests | Test suite present in the repository | Recheck on the published commit |
| Ruff | Tooling/CI configuration present | Recheck on the published commit |
| Azure ML job from new repository | YAML and documentation present | Not verified after repository recreation |
| R/Python calendar parity | Known differences documented | Open |
| External data attribution | `docs/data_sources.md` exists | Verify provenance and license details |
| HypoForge dependency | Experiment and environment specification present | Pin a confirmed commit and rerun |

This table distinguishes **historical evidence**, **repository content** and **unverified release conditions**.

## 8. Practical next steps

1. Run tests and Ruff against a clean installation of the published Python package.
2. Inspect the GitHub Actions result for the new repository's initial commit.
3. Verify external-data attribution and usage conditions.
4. Pin the HypoForge experiment to a real, tested commit and execute the job.
5. Add a focused R-versus-Python calendar comparison test or document the intended semantic differences as explicit contracts.
6. Re-run the Azure ML jobs from the recreated repository before making fresh reproducibility claims.

## 9. Reading guide

For implementation details and decisions, start with:

- `README.md` — project entry point and scope.
- `docs/architecture.md` — architecture overview.
- `docs/data_contract.md` — input/output expectations.
- `docs/sales_forecast_pipeline.md` — forecasting pipeline and diagnostics.
- `docs/calendar_parity.md` — calendar implementation differences.
- `docs/decisions/` — technical decision history.
- `docs/run-github-code-on-azure-ml.md` — cloud execution runbook.
- `CLEANUP_REPORT.md` — changes made during public-repository cleanup.

---

*This document is a curated public engineering record reconstructed from the original 2026-09-20 project status and the repository's documentation. It intentionally omits personal background, career plans, conversational instructions and private AI handover material. It does not claim tests or cloud jobs were executed during this documentation revision.*
