#!/usr/bin/env python3
"""Build per-tick aggregate household EV load from smart_charging_decisions.csv."""

from __future__ import annotations

import argparse
from pathlib import Path

import pandas as pd


def build_aggregate_load(decisions_path: Path, output_path: Path) -> pd.DataFrame:
    df = pd.read_csv(decisions_path)
    hh = df[df["household"].astype(str).str.lower().eq("true")].copy()

    if hh.empty:
        out = pd.DataFrame(columns=["tick", "household_ev_load_kw", "num_household_records"])
        out.to_csv(output_path, index=False)
        return out

    for col in ("finalPowerKW", "duration", "deficitJ", "price"):
        hh[col] = pd.to_numeric(hh[col], errors="coerce").fillna(0.0)

    agg = (
        hh.groupby("tick", as_index=False)
        .agg(
            household_ev_load_kw=("finalPowerKW", "sum"),
            num_household_records=("vehicle", "count"),
            num_household_vehicles=("vehicle", "nunique"),
            num_active_deficit=("deficitJ", lambda s: int((s > 0).sum())),
            num_positive_charging=("finalPowerKW", lambda s: int((s > 0).sum())),
            price=("price", "first"),
        )
        .sort_values("tick")
    )
    agg["hour"] = (agg["tick"] // 3600).astype(int)
    agg.to_csv(output_path, index=False)
    return agg


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("decisions_csv", type=Path)
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="Default: aggregate_household_load.csv next to decisions file",
    )
    args = parser.parse_args()

    output = args.output or args.decisions_csv.parent / "aggregate_household_load.csv"
    build_aggregate_load(args.decisions_csv, output)
    print(f"Wrote {output}")


if __name__ == "__main__":
    main()
