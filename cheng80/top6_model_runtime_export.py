from __future__ import annotations

import argparse
from pathlib import Path
import json

import joblib
import pandas as pd


BASE_DIR = Path("/Users/cheng80/Desktop/ddri_work/hmw3")
DATA_DIR = BASE_DIR / "Data"
OUTPUT_DIR = Path("/Users/cheng80/Desktop/ddri_web/fastapi/app/models/runtime")

TOP6_STATION_IDS = [2348, 2335, 2377, 2384, 2306, 2375]
TARGETS = ["rental_count", "return_count"]
FEATURE_COLUMNS = [
    "base_value",
    "month_weight",
    "year_weight",
    "hour_weight",
    "pattern_prior",
    "corrected_pattern_prior",
    "day_type_weekday",
    "day_type_offday",
]


def load_ranking() -> pd.DataFrame:
    metric_path = DATA_DIR / "top20_station_metrics_summary.csv"
    metric_df = pd.read_csv(metric_path)
    test_df = metric_df[
        (metric_df["split"] == "test")
        & (metric_df["target"].isin(TARGETS))
    ].copy()

    r2_df = (
        test_df.pivot_table(
            index="station_id", columns="target", values="r2", aggfunc="mean"
        )
        .reset_index()
    )
    rmse_df = (
        test_df.pivot_table(
            index="station_id", columns="target", values="rmse", aggfunc="mean"
        )
        .reset_index()
        .rename(
            columns={
                "rental_count": "rental_rmse",
                "return_count": "return_rmse",
            }
        )
    )
    mae_df = (
        test_df.pivot_table(
            index="station_id", columns="target", values="mae", aggfunc="mean"
        )
        .reset_index()
        .rename(
            columns={
                "rental_count": "rental_mae",
                "return_count": "return_mae",
            }
        )
    )

    ranking_df = r2_df.merge(rmse_df, on="station_id").merge(mae_df, on="station_id")
    ranking_df["combined_test_r2"] = ranking_df[["rental_count", "return_count"]].mean(
        axis=1
    )
    ranking_df["combined_test_rmse"] = ranking_df[
        ["rental_rmse", "return_rmse"]
    ].mean(axis=1)
    ranking_df["combined_test_mae"] = ranking_df[["rental_mae", "return_mae"]].mean(
        axis=1
    )
    ranking_df = ranking_df.sort_values("combined_test_r2", ascending=False).reset_index(
        drop=True
    )
    return ranking_df


def build_station_file_check(station_id: int) -> dict[str, object]:
    required_files = {
        "raw_csv": DATA_DIR / f"station_{station_id}.csv",
        "metrics_csv": DATA_DIR / f"station_{station_id}_offday_month_ridge_metrics.csv",
        "formulas_csv": DATA_DIR / f"station_{station_id}_offday_hour_formulas.csv",
        "weights_csv": DATA_DIR / f"station_{station_id}_month_weights.csv",
        "coefficients_csv": DATA_DIR
        / f"station_{station_id}_offday_month_ridge_coefficients.csv",
        "feature_importance_csv": DATA_DIR / f"station_{station_id}_feature_importance.csv",
    }
    row: dict[str, object] = {"station_id": station_id}
    for key, path in required_files.items():
        row[f"{key}_path"] = str(path)
        row[f"{key}_exists"] = path.exists()
    row["all_required_files_exist"] = all(path.exists() for path in required_files.values())
    return row


def build_bundle_preview(station_id: int) -> dict[str, object]:
    return {
        "station_id": station_id,
        "bundle_filename": f"station_{station_id}_runtime_bundle.joblib",
        "output_dir": str(OUTPUT_DIR),
        "targets": TARGETS,
        "contains_formula": True,
        "contains_weights": True,
        "contains_coefficients": True,
        "contains_feature_schema": True,
        "contains_metadata": True,
        "joblib_dump_enabled": False,
    }


def _load_csv(station_id: int, suffix: str) -> pd.DataFrame:
    return pd.read_csv(DATA_DIR / f"station_{station_id}{suffix}")


def _load_feature_coefficients(station_id: int) -> dict[str, dict[str, object]]:
    coef_df = _load_csv(station_id, "_offday_month_ridge_coefficients.csv")
    target_payloads: dict[str, dict[str, object]] = {}
    for target in TARGETS:
        target_df = coef_df[coef_df["target"] == target].copy()
        intercept_row = target_df[target_df["feature"] == "intercept"]
        feature_df = target_df[target_df["feature"] != "intercept"]
        target_payloads[target] = {
            "alpha": float(target_df["alpha"].dropna().iloc[0]),
            "intercept": float(intercept_row["coefficient"].iloc[0]),
            "feature_coefficients": {
                str(row["feature"]): float(row["coefficient"])
                for _, row in feature_df.iterrows()
            },
        }
    return target_payloads


def _load_formulas(station_id: int) -> dict[str, dict[str, dict[str, float]]]:
    formula_df = _load_csv(station_id, "_offday_hour_formulas.csv")
    payload: dict[str, dict[str, dict[str, float]]] = {}
    for target in TARGETS:
        target_df = formula_df[formula_df["target"] == target].copy()
        payload[target] = {}
        for _, row in target_df.iterrows():
            payload[target][str(row["day_type"])] = {
                "intercept": float(row["intercept"]),
                "sin_hour_coef": float(row["sin_hour_coef"]),
                "cos_hour_coef": float(row["cos_hour_coef"]),
            }
    return payload


def _load_weights(station_id: int) -> dict[str, dict[str, dict[str, float]]]:
    weights_df = _load_csv(station_id, "_month_weights.csv")
    payload: dict[str, dict[str, dict[str, float]]] = {}
    for target in TARGETS:
        target_df = weights_df[weights_df["target"] == target].copy()
        payload[target] = {}
        for weight_type in ["month_weight", "year_weight", "hour_weight"]:
            sub = target_df[target_df["weight_type"] == weight_type]
            payload[target][weight_type] = {
                str(int(row["key"])): float(row["value"])
                for _, row in sub.iterrows()
            }
    return payload


def _load_metrics(station_id: int) -> dict[str, list[dict[str, object]]]:
    metrics_df = _load_csv(station_id, "_offday_month_ridge_metrics.csv")
    metrics_payload: dict[str, list[dict[str, object]]] = {}
    for target in metrics_df["target"].dropna().unique().tolist():
        sub = metrics_df[metrics_df["target"] == target].copy()
        metrics_payload[str(target)] = sub.to_dict(orient="records")
    return metrics_payload


def build_runtime_bundle(station_id: int) -> dict[str, object]:
    return {
        "bundle_version": "2026-03-20.v1",
        "station_id": station_id,
        "targets": TARGETS,
        "feature_columns": FEATURE_COLUMNS,
        "formulas": _load_formulas(station_id),
        "weights": _load_weights(station_id),
        "models": _load_feature_coefficients(station_id),
        "metrics": _load_metrics(station_id),
        "metadata": {
            "source_data_dir": str(DATA_DIR),
            "raw_station_csv": str(DATA_DIR / f"station_{station_id}.csv"),
            "coefficients_csv": str(
                DATA_DIR / f"station_{station_id}_offday_month_ridge_coefficients.csv"
            ),
            "formulas_csv": str(DATA_DIR / f"station_{station_id}_offday_hour_formulas.csv"),
            "weights_csv": str(DATA_DIR / f"station_{station_id}_month_weights.csv"),
        },
    }


def export_joblib_bundles() -> list[str]:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    written_paths: list[str] = []
    for station_id in TOP6_STATION_IDS:
        bundle = build_runtime_bundle(station_id)
        output_path = OUTPUT_DIR / f"station_{station_id}_runtime_bundle.joblib"
        joblib.dump(bundle, output_path)
        written_paths.append(str(output_path))
    return written_paths


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--write-joblib",
        action="store_true",
        help="Write station runtime bundles into fastapi/app/models/runtime",
    )
    args = parser.parse_args()

    ranking_df = load_ranking()
    detected_top6 = ranking_df.head(6)["station_id"].astype(int).tolist()

    print("[top6 ranking]")
    print(ranking_df.head(6).to_string(index=False))
    print()

    print("[configured top6]")
    print(TOP6_STATION_IDS)
    print()

    print("[ranking matches configured top6]")
    print(detected_top6 == TOP6_STATION_IDS)
    print()

    file_check_df = pd.DataFrame(
        [build_station_file_check(station_id) for station_id in TOP6_STATION_IDS]
    )
    print("[required file check]")
    print(file_check_df.to_string(index=False))
    print()

    bundle_preview = [build_bundle_preview(station_id) for station_id in TOP6_STATION_IDS]
    print("[bundle preview]")
    print(json.dumps(bundle_preview, ensure_ascii=False, indent=2))
    print()

    if args.write_joblib:
        written_paths = export_joblib_bundles()
        print("[written joblib bundles]")
        print(json.dumps(written_paths, ensure_ascii=False, indent=2))
        print()

    print("[note]")
    if args.write_joblib:
        print("This script validated inputs and wrote joblib runtime bundles.")
    else:
        print("This script validates inputs and previews runtime bundle layout only.")
        print("Use --write-joblib to create joblib files.")


if __name__ == "__main__":
    main()
