# Cleanup report

- Removed the duplicate nested project under `data/wkr-automotive-forecasting-lab/`, including stale R script variants and generated sales. The top-level `R/` implementation and inputs remain.
- Removed tracked `__pycache__` files. If applying these changes to an existing Git checkout, commit the deletions; `.gitignore` alone does not untrack existing files.
- Renamed `data/raw/Wetterbericht MMM.csv` to `data/raw/germany_weekly_weather_features.csv` without changing data bytes; updated the R reader and data contract.
- Replaced the private AI handoff document with a public project summary.
- Replaced the old HypoForge dependency with a proposed new repository/tag, **not yet confirmed to exist or tested**. Pin an actual tested commit before deployment.
- Documented outstanding R/Python calendar parity and external-data provenance rather than claiming these are resolved.
- Historical Azure metrics were retained and labelled as historical; no new Azure job was executed here.
