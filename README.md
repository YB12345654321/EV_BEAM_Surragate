# EV_BEAM_Surragate

Backup repository for the BEAM household EV smart charging response model.

## Repository layout

```
EV_BEAM_Surragate/
├── src/                              # BEAM runtime patches (Scala only)
│   └── main/scala/beam/agentsim/
│       ├── agents/pricing/           # Response model module
│       └── infrastructure/power/     # SitePowerManager integration
├── test/input/                       # Simulation inputs (config, price, vehicles)
├── experiments/smart_charging_ev60/  # Experiment automation (no Scala)
│   ├── price_profiles/               # Candidate TOU price curves
│   ├── runs/<profile>/               # Per-run BEAM outputs
│   ├── scripts/                      # Batch runner + post-processing
│   └── surrogate/
│       ├── datasets/                 # Training tables
│       └── models/                   # Future .pkl / .onnx
├── analysis/                         # Notebooks and figures
│   ├── plot_household_smart_charging_figures.py.ipynb
│   └── figures/
└── README.md
```

## Main components

- `src/main/scala/beam/agentsim/agents/pricing/` — smart charging response model
- `src/main/scala/beam/agentsim/infrastructure/power/SitePowerManager.scala` — BEAM integration point
- `test/input/sf-light/sf-light-1k-smart-ev60.conf` — EV60 experiment config
- `test/input/sf-light/sample/1k/vehicles_ev60.csv.gz` — ~60% EV penetration vehicles
- `test/input/smart-charging/price.csv` — runtime price input
- `experiments/smart_charging_ev60/scripts/collect_surrogate_training_data.sh` — batch data collection

## Running simulations

This repo is a **patch backup**. Full BEAM runs require the complete BEAM repo (e.g. `beam_smart_recovered` worktree with `gradlew`).

```bash
BEAM_ROOT=/path/to/beam_smart_recovered \
SYNC_CODE=1 SKIP_EXISTING=1 \
./experiments/smart_charging_ev60/scripts/collect_surrogate_training_data.sh
```

## Current status

1. Household-only EV charging response (Residential + Home)
2. Dynamic price input via CSV
3. User segment heterogeneity (price_sensitive / balanced / convenience_oriented)
4. Formal CSV output (`smart_charging_decisions.csv`)
5. EV60 scenario for stronger aggregate response
6. Surrogate data collection pipeline (batch runner + training table builder)
