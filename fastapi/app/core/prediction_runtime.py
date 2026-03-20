"""
DDRI 예측 런타임 로더.

- station 단위 joblib 번들을 로드한다.
- 노트북에서 저장한 계수/공식/weight를 사용해 rental_count, return_count를 계산한다.
- 현재 재고가 있으면 예상 잔여 재고와 순변화를 함께 계산한다.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
import math
import os
from pathlib import Path
from typing import Any

import joblib


DEFAULT_RUNTIME_MODEL_DIR = Path(__file__).resolve().parent.parent / "models" / "runtime"
FEATURE_COLUMNS = (
    "base_value",
    "month_weight",
    "year_weight",
    "hour_weight",
    "pattern_prior",
    "corrected_pattern_prior",
    "day_type_weekday",
    "day_type_offday",
)


def get_runtime_model_dir() -> Path:
    configured = os.getenv("DDRI_RUNTIME_MODEL_DIR", "").strip()
    if configured:
        return Path(configured)
    return DEFAULT_RUNTIME_MODEL_DIR


def _clip_non_negative(value: float) -> float:
    return max(0.0, float(value))


def _resolve_day_type(target_datetime: datetime, is_holiday: bool = False) -> str:
    if is_holiday or target_datetime.weekday() >= 5:
        return "offday"
    return "weekday"


def _resolve_formula(bundle: dict[str, Any], target: str, day_type: str) -> dict[str, float]:
    return bundle["formulas"][target][day_type]


def _resolve_weight(bundle: dict[str, Any], target: str, weight_type: str, key: int) -> float:
    weight_map = bundle["weights"][target][weight_type]
    return float(weight_map.get(str(int(key)), 1.0))


def _build_feature_values(
    bundle: dict[str, Any],
    target: str,
    target_datetime: datetime,
    is_holiday: bool = False,
) -> dict[str, float]:
    day_type = _resolve_day_type(target_datetime=target_datetime, is_holiday=is_holiday)
    hour = target_datetime.hour
    month = target_datetime.month
    year = target_datetime.year

    formula = _resolve_formula(bundle=bundle, target=target, day_type=day_type)
    angle = 2.0 * math.pi * float(hour) / 24.0
    base_value = _clip_non_negative(
        formula["intercept"]
        + (formula["sin_hour_coef"] * math.sin(angle))
        + (formula["cos_hour_coef"] * math.cos(angle))
    )
    month_weight = _resolve_weight(bundle, target, "month_weight", month)
    year_weight = _resolve_weight(bundle, target, "year_weight", year)
    pattern_prior = base_value * month_weight * year_weight
    hour_weight = _resolve_weight(bundle, target, "hour_weight", hour)
    corrected_pattern_prior = pattern_prior * hour_weight

    return {
        "base_value": base_value,
        "month_weight": month_weight,
        "year_weight": year_weight,
        "hour_weight": hour_weight,
        "pattern_prior": pattern_prior,
        "corrected_pattern_prior": corrected_pattern_prior,
        "day_type_weekday": 1.0 if day_type == "weekday" else 0.0,
        "day_type_offday": 1.0 if day_type == "offday" else 0.0,
    }


def _predict_target(
    bundle: dict[str, Any],
    target: str,
    target_datetime: datetime,
    is_holiday: bool = False,
) -> dict[str, Any]:
    model_spec = bundle["models"][target]
    feature_values = _build_feature_values(
        bundle=bundle,
        target=target,
        target_datetime=target_datetime,
        is_holiday=is_holiday,
    )
    raw_prediction = float(model_spec["intercept"])
    for feature_name in FEATURE_COLUMNS:
        coef = float(model_spec["feature_coefficients"].get(feature_name, 0.0))
        raw_prediction += feature_values[feature_name] * coef
    prediction = _clip_non_negative(raw_prediction)
    return {
        "target": target,
        "prediction": prediction,
        "raw_prediction": raw_prediction,
        "alpha": float(model_spec["alpha"]),
        "features": feature_values,
    }


@dataclass
class StationPredictionResult:
    station_id: int
    target_datetime: str
    day_type: str
    predicted_rental_count: float
    predicted_return_count: float
    predicted_net_change: float
    predicted_remaining_bikes: float | None

    def to_dict(self) -> dict[str, Any]:
        return {
            "station_id": self.station_id,
            "target_datetime": self.target_datetime,
            "day_type": self.day_type,
            "predicted_rental_count": self.predicted_rental_count,
            "predicted_return_count": self.predicted_return_count,
            "predicted_net_change": self.predicted_net_change,
            "predicted_remaining_bikes": self.predicted_remaining_bikes,
        }


class PredictionRuntime:
    def __init__(self, model_dir: Path | None = None) -> None:
        self.model_dir = model_dir or get_runtime_model_dir()
        self._bundle_cache: dict[int, dict[str, Any]] = {}

    def get_bundle_path(self, station_id: int) -> Path:
        return self.model_dir / f"station_{station_id}_runtime_bundle.joblib"

    def has_bundle(self, station_id: int) -> bool:
        return self.get_bundle_path(station_id).exists()

    def load_bundle(self, station_id: int) -> dict[str, Any]:
        if station_id not in self._bundle_cache:
            bundle_path = self.get_bundle_path(station_id)
            if not bundle_path.exists():
                raise FileNotFoundError(f"runtime bundle not found: {bundle_path}")
            self._bundle_cache[station_id] = joblib.load(bundle_path)
        return self._bundle_cache[station_id]

    def predict_station(
        self,
        station_id: int,
        target_datetime: datetime,
        current_bike_stock: float | None = None,
        is_holiday: bool = False,
    ) -> StationPredictionResult:
        bundle = self.load_bundle(station_id)
        rental = _predict_target(bundle, "rental_count", target_datetime, is_holiday)
        returned = _predict_target(bundle, "return_count", target_datetime, is_holiday)
        predicted_net_change = float(returned["prediction"] - rental["prediction"])
        predicted_remaining_bikes = None
        if current_bike_stock is not None:
            predicted_remaining_bikes = _clip_non_negative(
                float(current_bike_stock) + predicted_net_change
            )
        return StationPredictionResult(
            station_id=station_id,
            target_datetime=target_datetime.isoformat(),
            day_type=_resolve_day_type(target_datetime, is_holiday),
            predicted_rental_count=float(rental["prediction"]),
            predicted_return_count=float(returned["prediction"]),
            predicted_net_change=predicted_net_change,
            predicted_remaining_bikes=predicted_remaining_bikes,
        )
