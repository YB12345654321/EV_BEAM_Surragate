from pathlib import Path
import pandas as pd
import numpy as np

OUT_DIR = Path("experiments/smart_charging_ev60/price_profiles")
OUT_DIR.mkdir(parents=True, exist_ok=True)

profiles = {}

profiles["flat_low"] = [
    (0, 0.10), (86400, 0.10)
]

profiles["flat_medium"] = [
    (0, 0.20), (86400, 0.20)
]

profiles["flat_high"] = [
    (0, 0.30), (86400, 0.30)
]

profiles["evening_peak"] = [
    (0, 0.20), (61200, 0.45), (79200, 0.10), (86400, 0.20)
]

profiles["midday_low_evening_high"] = [
    (0, 0.25), (39600, 0.10), (54000, 0.25), (61200, 0.45), (79200, 0.20), (86400, 0.20)
]

profiles["night_low"] = [
    (0, 0.10), (25200, 0.25), (61200, 0.35), (79200, 0.10), (86400, 0.10)
]

profiles["high_low_high"] = [
    (0, 0.30), (39600, 0.10), (54000, 0.30), (86400, 0.30)
]

profiles["low_high_low"] = [
    (0, 0.10), (61200, 0.45), (79200, 0.10), (86400, 0.10)
]

rng = np.random.default_rng(42)
for i in range(1, 4):
    times = [0, 21600, 43200, 61200, 79200, 86400]
    prices = rng.choice([0.10, 0.15, 0.20, 0.30, 0.45], size=len(times)-1)
    profile = [(times[j], float(prices[j])) for j in range(len(prices))]
    profile.append((86400, float(prices[-1])))
    profiles[f"random_tou_{i:02d}"] = profile

summary_rows = []

for name, rows in profiles.items():
    df = pd.DataFrame(rows, columns=["time", "price"])
    path = OUT_DIR / f"{name}.csv"
    df.to_csv(path, index=False)
    summary_rows.append({
        "profile": name,
        "file": str(path),
        "min_price": df["price"].min(),
        "max_price": df["price"].max(),
        "mean_price": df["price"].mean(),
    })

summary = pd.DataFrame(summary_rows)
summary.to_csv(OUT_DIR / "price_profile_summary.csv", index=False)

print(summary.to_string(index=False))
print(f"\nGenerated {len(profiles)} price profiles in {OUT_DIR}")
