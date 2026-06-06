# Surrogate model workspace

This directory is for **post-BEAM** machine learning work only. Do not put Scala source here.

## Layout

- `datasets/` — tick-level training tables built from `runs/*/smart_charging_decisions.csv`
- `models/` — trained surrogate baselines (future)
- `notebooks/` — exploratory training notebooks (future)

## Build training data

From a full BEAM repo root (with `gradlew`):

```bash
chmod +x experiments/smart_charging_ev60/scripts/collect_surrogate_training_data.sh
SYNC_CODE=1 GENERATE_PROFILES=1 ./experiments/smart_charging_ev60/scripts/collect_surrogate_training_data.sh
```

Target variable: `household_ev_load_kw` in `datasets/surrogate_training_table_v0.csv`.
