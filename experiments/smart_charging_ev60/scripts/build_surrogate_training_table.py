#!/usr/bin/env python3
"""Combine completed BEAM runs into a tick-level surrogate training table."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
import pandas as pd


SEGMENTS = ("price_sensitive", "balanced", "convenience_oriented")
DECISIONS = ("wait_price_high", "price_acceptable", "urgent", "target_soc_reached")


def _price_features(price: pd.Series) -> pd.DataFrame:
    out = pd.DataFrame(index=price.index)
    out["price"] = price
    out["price_lag_1"] = price.shift(1).fillna(price.iloc[0] if len(price) else 0.0)
    out["price_lead_1"] = price.shift(-1).fillna(price.iloc[-1] if len(price) else 0.0)
    out["rolling_mean_price_3"] = price.rolling(3, min_periods=1).mean()
    out["is_low_price"] = (price <= 0.15).astype(int)
    out["is_high_price"] = (price >= 0.35).astype(int)
    return out


def build_run_features(run_id: str, decisions_path: Path) -> pd.DataFrame:
    df = pd.read_csv(decisions_path)
    hh = df[df["household"].astype(str).str.lower().eq("true")].copy()
    if hh.empty:
        return pd.DataFrame()

    for col in ("finalPowerKW", "duration", "deficitJ", "price", "tick"):
        hh[col] = pd.to_numeric(hh[col], errors="coerce").fillna(0.0)

    hh["active_deficit"] = hh["deficitJ"] > 0

    rows = []
    for tick, g in hh.groupby("tick"):
        row = {
            "run_id": run_id,
            "tick": int(tick),
            "hour": int(tick // 3600),
            "household_ev_load_kw": float(g["finalPowerKW"].sum()),
            "num_household_records": int(len(g)),
            "num_household_vehicles": int(g["vehicle"].nunique()),
            "num_active_deficit": int(g["active_deficit"].sum()),
            "price": float(g["price"].iloc[0]),
        }

        for seg in SEGMENTS:
            seg_rows = g[g["userSegment"] == seg]
            row[f"num_{seg}"] = int(len(seg_rows))
            row[f"num_{seg}_active_deficit"] = int(seg_rows["active_deficit"].sum())

        for decision in DECISIONS:
            row[f"num_{decision}"] = int((g["decision"] == decision).sum())

        rows.append(row)

    out = pd.DataFrame(rows).sort_values(["run_id", "tick"]).reset_index(drop=True)
    price_feats = _price_features(out["price"])
    return pd.concat([out, price_feats.drop(columns=["price"])], axis=1)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--runs-dir",
        type=Path,
        default=Path("experiments/smart_charging_ev60/runs"),
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("experiments/smart_charging_ev60/surrogate/datasets/surrogate_training_table_v0.csv"),
    )
    args = parser.parse_args()

    frames = []
    for run_dir in sorted(args.runs_dir.iterdir()):
        if not run_dir.is_dir():
            continue
        decisions = run_dir / "smart_charging_decisions.csv"
        if not decisions.exists():
            continue
        frames.append(build_run_features(run_dir.name, decisions))

    if not frames:
        raise SystemExit(f"No completed runs found under {args.runs_dir}")

    table = pd.concat(frames, ignore_index=True)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    table.to_csv(args.output, index=False)

    manifest = {
        "num_runs": int(table["run_id"].nunique()),
        "num_rows": int(len(table)),
        "run_ids": sorted(table["run_id"].unique().tolist()),
        "output": str(args.output),
    }
    manifest_path = args.output.with_suffix(".json")
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    print(f"Wrote {args.output} ({len(table)} rows, {table['run_id'].nunique()} runs)")
    print(f"Wrote {manifest_path}")


if __name__ == "__main__":
    main()
