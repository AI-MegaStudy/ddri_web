"""
DDRI 베타 노출용 고정 스테이션 데이터.

- 예측 번들이 준비된 6개 스테이션만 사용자/관리자 화면에서 동일하게 사용한다.
- 현재 고정 목록: 2348, 2335, 2377, 2384, 2306, 2375
- 사용자 위치·반경과 무관하게 이 목록만 반환하되, 사용자 화면의 distance_m은 입력 좌표 기준으로 계산한다.
"""

from __future__ import annotations

from datetime import datetime
import logging
from math import asin, cos, radians, sin, sqrt

from ..core.prediction_runtime import PredictionRuntime
from ..core.runtime_config import is_debug_log_enabled
from ..utils.realtime_bike_service import RealtimeBikeService


BETA_STATIONS = [
    {
        "station_id": 2348,
        "api_station_id": "ST-797",
        "station_name": "포스코사거리(기업은행)",
        "district_name": "삼성동",
        "address": "서울특별시 강남구 테헤란로 501",
        "latitude": 37.50723267,
        "longitude": 127.05685425,
        "cluster_code": "cluster01",
        "operational_status": "operational",
        "current_bike_stock": 4,
        "predicted_rental_count": 8.0,
        "predicted_remaining_bikes": 0.0,
        "bike_availability_flag": True,
        "availability_level": "low",
        "predicted_demand": 8.0,
        "stock_gap": -4.0,
        "risk_score": 0.76,
        "reallocation_priority": 1,
        "service_tag": "베타",
    },
    {
        "station_id": 2335,
        "api_station_id": "ST-818",
        "station_name": "3호선 매봉역 3번출구앞",
        "district_name": "도곡동",
        "address": "서울특별시 강남구 남부순환로 2748",
        "latitude": 37.48676682,
        "longitude": 127.04676056,
        "cluster_code": "cluster00",
        "operational_status": "operational",
        "current_bike_stock": 27,
        "predicted_rental_count": 7.0,
        "predicted_remaining_bikes": 20.0,
        "bike_availability_flag": True,
        "availability_level": "sufficient",
        "predicted_demand": 7.0,
        "stock_gap": -7.0,
        "risk_score": 0.26,
        "reallocation_priority": 2,
        "service_tag": "베타",
    },
    {
        "station_id": 2377,
        "api_station_id": "ST-1186",
        "station_name": "수서역 5번출구",
        "district_name": "수서동",
        "address": "서울특별시 강남구 수서동 724-4",
        "latitude": 37.48735046,
        "longitude": 127.10232544,
        "cluster_code": "cluster00",
        "operational_status": "operational",
        "current_bike_stock": 38,
        "predicted_rental_count": 6.0,
        "predicted_remaining_bikes": 32.0,
        "bike_availability_flag": True,
        "availability_level": "sufficient",
        "predicted_demand": 6.0,
        "stock_gap": -6.0,
        "risk_score": 0.16,
        "reallocation_priority": 3,
        "service_tag": "베타",
    },
    {
        "station_id": 2384,
        "api_station_id": "ST-1364",
        "station_name": "자곡사거리",
        "district_name": "자곡동",
        "address": "서울특별시 강남구 밤고개로 206",
        "latitude": 37.47602844,
        "longitude": 127.10594177,
        "cluster_code": "cluster02",
        "operational_status": "operational",
        "current_bike_stock": 29,
        "predicted_rental_count": 5.0,
        "predicted_remaining_bikes": 24.0,
        "bike_availability_flag": True,
        "availability_level": "sufficient",
        "predicted_demand": 5.0,
        "stock_gap": -5.0,
        "risk_score": 0.17,
        "reallocation_priority": 4,
        "service_tag": "베타",
    },
    {
        "station_id": 2306,
        "api_station_id": "ST-791",
        "station_name": "압구정역 2번 출구 옆",
        "district_name": "압구정동",
        "address": "서울특별시 강남구 압구정로 지하 172",
        "latitude": 37.5271225,
        "longitude": 127.02871704,
        "cluster_code": "cluster02",
        "operational_status": "operational",
        "current_bike_stock": 4,
        "predicted_rental_count": 3.0,
        "predicted_remaining_bikes": 1.0,
        "bike_availability_flag": True,
        "availability_level": "low",
        "predicted_demand": 3.0,
        "stock_gap": -3.0,
        "risk_score": 0.75,
        "reallocation_priority": 5,
        "service_tag": "베타",
    },
    {
        "station_id": 2375,
        "api_station_id": "ST-1184",
        "station_name": "수서역 1번출구 앞",
        "district_name": "수서동",
        "address": "서울특별시 강남구 수서동 728",
        "latitude": 37.48735046,
        "longitude": 127.10099792,
        "cluster_code": "cluster00",
        "operational_status": "operational",
        "current_bike_stock": 28,
        "predicted_rental_count": 4.0,
        "predicted_remaining_bikes": 24.0,
        "bike_availability_flag": True,
        "availability_level": "sufficient",
        "predicted_demand": 4.0,
        "stock_gap": -4.0,
        "risk_score": 0.14,
        "reallocation_priority": 6,
        "service_tag": "베타",
    },
]

_prediction_runtime = PredictionRuntime()
_realtime_bike_service = RealtimeBikeService()
logger = logging.getLogger(__name__)


def _runtime_debug(message: str, *args: object) -> None:
    if is_debug_log_enabled():
        logger.info(message, *args)


def _haversine_distance_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """두 좌표의 직선거리(m)를 계산한다."""
    earth_radius_m = 6371000.0
    d_lat = radians(lat2 - lat1)
    d_lon = radians(lon2 - lon1)
    lat1_rad = radians(lat1)
    lat2_rad = radians(lat2)

    a = sin(d_lat / 2) ** 2 + cos(lat1_rad) * cos(lat2_rad) * sin(d_lon / 2) ** 2
    return 2 * earth_radius_m * asin(sqrt(a))


def _resolve_availability_level(predicted_remaining_bikes: float) -> str:
    if predicted_remaining_bikes <= 2:
        return "low"
    if predicted_remaining_bikes <= 8:
        return "normal"
    return "sufficient"


def _resolve_bike_availability_flag(predicted_remaining_bikes: float) -> bool:
    return predicted_remaining_bikes > 0.0


def _resolve_risk_score(current_bike_stock: float, predicted_remaining_bikes: float) -> float:
    if current_bike_stock <= 0:
        return 1.0
    shortage_ratio = max(0.0, (current_bike_stock - predicted_remaining_bikes) / current_bike_stock)
    return round(min(1.0, shortage_ratio), 2)


def _enrich_station_prediction(station: dict, target_datetime: str | None) -> dict:
    enriched = dict(station)
    realtime_source = "static"

    try:
        snapshot = _realtime_bike_service.get_station_snapshot(int(station["station_id"]))
    except Exception:
        snapshot = None

    if snapshot is not None:
        enriched["current_bike_stock"] = round(float(snapshot.current_bike_stock), 1)
        enriched["operational_status"] = "operational"
        if snapshot.current_capacity is not None:
            enriched["current_capacity"] = round(float(snapshot.current_capacity), 1)
        enriched["realtime_api_station_id"] = snapshot.api_station_id
        enriched["source_updated_at"] = snapshot.source_updated_at
        realtime_source = "seoul_api"

    if not target_datetime:
        _runtime_debug(
            "[DDRI][runtime] station_id=%s station_name=%s realtime_source=%s current_bike_stock=%s target_datetime=%s prediction=skipped",
            enriched["station_id"],
            enriched["station_name"],
            realtime_source,
            enriched["current_bike_stock"],
            target_datetime,
        )
        return enriched

    try:
        target_dt = datetime.fromisoformat(str(target_datetime).replace("Z", "+00:00"))
    except ValueError:
        if is_debug_log_enabled():
            logger.warning(
                "[DDRI][runtime] station_id=%s invalid target_datetime=%s",
                enriched["station_id"],
                target_datetime,
            )
        return enriched

    if not _prediction_runtime.has_bundle(int(station["station_id"])):
        _runtime_debug(
            "[DDRI][runtime] station_id=%s station_name=%s realtime_source=%s current_bike_stock=%s target_datetime=%s bundle=missing prediction=skipped",
            enriched["station_id"],
            enriched["station_name"],
            realtime_source,
            enriched["current_bike_stock"],
            target_datetime,
        )
        return enriched

    prediction = _prediction_runtime.predict_station(
        station_id=int(station["station_id"]),
        target_datetime=target_dt,
        current_bike_stock=float(enriched["current_bike_stock"]),
    ).to_dict()

    predicted_remaining_bikes = round(float(prediction["predicted_remaining_bikes"] or 0.0), 1)
    predicted_rental_count = round(float(prediction["predicted_rental_count"]), 1)
    predicted_return_count = round(float(prediction["predicted_return_count"]), 1)
    predicted_net_change = round(float(prediction["predicted_net_change"]), 1)
    stock_gap = round(predicted_remaining_bikes - float(enriched["current_bike_stock"]), 1)
    risk_score = _resolve_risk_score(
        current_bike_stock=float(enriched["current_bike_stock"]),
        predicted_remaining_bikes=predicted_remaining_bikes,
    )

    enriched.update(
        {
            "predicted_rental_count": predicted_rental_count,
            "predicted_return_count": predicted_return_count,
            "predicted_net_change": predicted_net_change,
            "predicted_remaining_bikes": predicted_remaining_bikes,
            "predicted_demand": predicted_rental_count,
            "stock_gap": stock_gap,
            "risk_score": risk_score,
            "bike_availability_flag": _resolve_bike_availability_flag(predicted_remaining_bikes),
            "availability_level": _resolve_availability_level(predicted_remaining_bikes),
            "model_version": "2026-03-20.v1",
        }
    )
    _runtime_debug(
        "[DDRI][runtime] station_id=%s station_name=%s realtime_source=%s current_bike_stock=%s target_datetime=%s predicted_rental=%s predicted_return=%s predicted_remaining=%s risk_score=%s",
        enriched["station_id"],
        enriched["station_name"],
        realtime_source,
        enriched["current_bike_stock"],
        target_datetime,
        predicted_rental_count,
        predicted_return_count,
        predicted_remaining_bikes,
        risk_score,
    )
    return enriched


def get_beta_user_items(
    lat: float,
    lng: float,
    limit: int,
    target_datetime: str | None = None,
    radius_m: int | None = None,
    service_tag: str = "베타",
) -> list[dict]:
    """사용자 화면용 6개 고정 스테이션을 거리 계산 후 반환한다."""
    items = []
    for station in BETA_STATIONS:
        station_view = _enrich_station_prediction(station, target_datetime)
        item = {
            "station_id": station_view["station_id"],
            "station_name": station_view["station_name"],
            "address": station_view["address"],
            "latitude": station_view["latitude"],
            "longitude": station_view["longitude"],
            "distance_m": round(
                _haversine_distance_m(lat, lng, station_view["latitude"], station_view["longitude"]),
                1,
            ),
            "current_bike_stock": station_view["current_bike_stock"],
            "predicted_rental_count": station_view["predicted_rental_count"],
            "predicted_remaining_bikes": station_view["predicted_remaining_bikes"],
            "bike_availability_flag": station_view["bike_availability_flag"],
            "availability_level": station_view["availability_level"],
            "operational_status": station_view["operational_status"],
            "service_tag": service_tag,
        }
        items.append(item)

    if radius_m is not None:
        items = [item for item in items if item["distance_m"] <= float(radius_m)]

    items.sort(key=lambda item: item["distance_m"])
    return items[:limit]


def get_beta_admin_items(
    district_name: str | None,
    urgent_only: bool | None,
    sort_by: str,
    sort_order: str,
    base_datetime: str | None = None,
    service_tag: str = "베타",
) -> list[dict]:
    """관리자 화면용 6개 고정 스테이션을 필터·정렬해 반환한다."""
    items = []
    for station in BETA_STATIONS:
        station_view = _enrich_station_prediction(station, base_datetime)
        item = {
            "station_id": station_view["station_id"],
            "station_name": station_view["station_name"],
            "district_name": station_view["district_name"],
            "cluster_code": station_view["cluster_code"],
            "latitude": station_view["latitude"],
            "longitude": station_view["longitude"],
            "current_bike_stock": station_view["current_bike_stock"],
            "predicted_demand": station_view["predicted_demand"],
            "predicted_remaining_bikes": station_view["predicted_remaining_bikes"],
            "shortage_bikes": round(
                max(
                    0.0,
                    float(station_view["current_bike_stock"])
                    - float(station_view["predicted_remaining_bikes"]),
                ),
                1,
            ),
            "stock_gap": station_view["stock_gap"],
            "risk_score": station_view["risk_score"],
            "reallocation_priority": station_view["reallocation_priority"],
            "operational_status": station_view["operational_status"],
            "service_tag": service_tag,
        }
        items.append(item)

    if district_name:
        items = [item for item in items if item["district_name"] == district_name]
    if urgent_only:
        items = [item for item in items if item["predicted_remaining_bikes"] <= 5.0]

    reverse = sort_order == "desc"
    items.sort(key=lambda item: item[sort_by], reverse=reverse)
    for index, item in enumerate(items, start=1):
        item["reallocation_priority"] = index
    return items


def get_beta_master_items(
    district_name: str | None,
    cluster_code: str | None,
    service_tag: str = "베타",
) -> list[dict]:
    """마스터 목록도 베타 기간에는 같은 6개만 반환한다."""
    items = []
    for station in BETA_STATIONS:
        item = {
            "station_id": station["station_id"],
            "api_station_id": station["api_station_id"],
            "station_name": station["station_name"],
            "district_name": station["district_name"],
            "address": station["address"],
            "latitude": station["latitude"],
            "longitude": station["longitude"],
            "cluster_code": station["cluster_code"],
            "operational_status": station["operational_status"],
            "service_tag": service_tag,
        }
        items.append(item)

    if district_name:
        items = [item for item in items if item["district_name"] == district_name]
    if cluster_code:
        items = [item for item in items if item["cluster_code"] == cluster_code]
    return items


def get_beta_weather_reference(district_name: str | None = None) -> tuple[float, float]:
    """관리자 날씨 조회용 대표 좌표를 반환한다."""
    stations = BETA_STATIONS
    if district_name:
        filtered = [station for station in stations if station["district_name"] == district_name]
        if filtered:
            stations = filtered

    avg_lat = sum(station["latitude"] for station in stations) / len(stations)
    avg_lon = sum(station["longitude"] for station in stations) / len(stations)
    return avg_lat, avg_lon
