# EV_BEAM_Surragate

Backup repository for the BEAM household EV smart charging response model.

This repository contains the modified BEAM files and experiment configuration for household-level EV charging response under dynamic price signals.

## Main components

- `src/main/scala/beam/agentsim/agents/pricing/`
  - Smart charging response model
  - Dynamic price provider
  - User profile model
  - CSV output writer

- `src/main/scala/beam/agentsim/infrastructure/power/SitePowerManager.scala`
  - BEAM integration point for household charging response

- `test/input/sf-light/sf-light-1k-smart-ev60.conf`
  - 1k SF-light experiment config with higher EV penetration

- `test/input/sf-light/sample/1k/vehicles_ev60.csv.gz`
  - Modified vehicle file with approximately 60% EV penetration

- `test/input/smart-charging/price.csv`
  - Input price profile used by the response model

- `experiments/smart_charging_ev60/`
  - EV60 price profile experiments and generation script

- `plot_household_smart_charging_figures.py.ipynb`
  - Analysis and figure generation notebook

## Current status

The current implementation supports:

1. Household-only EV charging response
2. Residential home charging filtering
3. Dynamic price input
4. User segment heterogeneity
5. Formal CSV output of charging decisions
6. EV60 scenario for stronger aggregate response
