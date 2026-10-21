# WKR × HypoForge forecasting experiment

This experiment originally ran with HypoForge v0.3.0 and a historical source revision. The original dependency has been removed to avoid installing the superseded repository.

`environment.yml` now targets `sayac007/HypoForge-Python` at tag `v0.4.0` as a **proposed replacement**, not a verified installation. Before running the Azure job, confirm that the new repository and tag exist, verify the exported `discover`, `evaluate`, and `select_candidates` APIs against `run.py`, then replace the tag with a tested immutable commit SHA.

**Validation status:** The historical challenger results do not validate this new dependency or a fresh Azure ML execution. Re-run the job and record its commit, environment and outputs. The accepted WKR baseline is unaffected by this experimental dependency.
