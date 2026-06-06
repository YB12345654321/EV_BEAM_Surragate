# Smart Charging EV60 Experiments

Experiment automation for household EV smart charging surrogate data generation.

Scala runtime code stays in `src/`. This folder holds price profiles, batch outputs, and surrogate datasets.

## Directory layout

```
experiments/smart_charging_ev60/
  price_profiles/     # candidate TOU price curves
  runs/               # one subfolder per BEAM run
  scripts/            # batch runner + post-processing
  surrogate/
    datasets/         # surrogate_training_table_v0.csv
    models/           # future trained models
```

## Quick start

Run from a **full BEAM repo** that has `gradlew` (e.g. `beam_smart_recovered`):

```bash
chmod +x experiments/smart_charging_ev60/scripts/collect_surrogate_training_data.sh
SYNC_CODE=1 GENERATE_PROFILES=1 SKIP_EXISTING=1 \
  ./experiments/smart_charging_ev60/scripts/collect_surrogate_training_data.sh
```

Set `BEAM_ROOT` if auto-detection fails:

```bash
BEAM_ROOT=/Users/yu/Desktop/beam_smart_recovered \
  /Users/yu/Desktop/beam/experiments/smart_charging_ev60/scripts/collect_surrogate_training_data.sh
```

## Per-run outputs

`runs/<profile_name>/`:

- `price.csv`
- `smart_charging_decisions.csv`
- `aggregate_household_load.csv`
- `metadata.json`
- `run.log`

Combined output: `surrogate/datasets/surrogate_training_table_v0.csv`

Target variable for surrogate v0: `household_ev_load_kw`.
