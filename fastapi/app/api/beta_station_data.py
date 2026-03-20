"""
DDRI 베타 노출용 고정 스테이션 데이터.

- 예측 모델과 전체 스테이션 운영이 완료되기 전까지 사용자/관리자 화면 모두 동일한 6개만 사용한다.
- 사용자 위치·반경과 무관하게 이 목록만 반환하되, 사용자 화면의 distance_m은 입력 좌표 기준으로 계산한다.
"""

from __future__ import annotations

from math import asin, cos, radians, sin, sqrt


BETA_STATIONS = [
    {
        "station_id": 2328,
        "api_station_id": "ST-2328",
        "station_name": "르네상스 호텔 사거리 역삼지하보도 7번출구 앞",
        "district_name": "역삼동",
        "address": "서울 강남구 역삼동 676-18",
        "latitude": 37.5001,
        "longitude": 127.0389,
        "cluster_code": "cluster00",
        "operational_status": "operational",
        "current_bike_stock": 7,
        "predicted_rental_count": 5.2,
        "predicted_remaining_bikes": 1.8,
        "bike_availability_flag": True,
        "availability_level": "low",
        "predicted_demand": 12.0,
        "stock_gap": -5.0,
        "risk_score": 0.72,
        "reallocation_priority": 1,
        "service_tag": "베타",
    },
    {
        "station_id": 2348,
        "api_station_id": "ST-2348",
        "station_name": "강남역 2번출구 앞",
        "district_name": "역삼동",
        "address": "서울 강남구 역삼동 822-7",
        "latitude": 37.4985,
        "longitude": 127.0276,
        "cluster_code": "cluster01",
        "operational_status": "operational",
        "current_bike_stock": 12,
        "predicted_rental_count": 8.0,
        "predicted_remaining_bikes": 4.0,
        "bike_availability_flag": True,
        "availability_level": "normal",
        "predicted_demand": 8.0,
        "stock_gap": -5.0,
        "risk_score": 0.68,
        "reallocation_priority": 2,
        "service_tag": "베타",
    },
    {
        "station_id": 2215,
        "api_station_id": "ST-2215",
        "station_name": "선릉역 5번출구 앞",
        "district_name": "대치동",
        "address": "서울 강남구 대치동 889-5",
        "latitude": 37.5047,
        "longitude": 127.0489,
        "cluster_code": "cluster02",
        "operational_status": "operational",
        "current_bike_stock": 9,
        "predicted_rental_count": 4.5,
        "predicted_remaining_bikes": 4.5,
        "bike_availability_flag": True,
        "availability_level": "normal",
        "predicted_demand": 6.0,
        "stock_gap": 3.0,
        "risk_score": 0.31,
        "reallocation_priority": 5,
        "service_tag": "베타",
    },
    {
        "station_id": 3623,
        "api_station_id": "ST-3623",
        "station_name": "삼성역 4번출구 앞",
        "district_name": "삼성동",
        "address": "서울 강남구 삼성동 159-1",
        "latitude": 37.5086,
        "longitude": 127.0637,
        "cluster_code": "cluster03",
        "operational_status": "operational",
        "current_bike_stock": 4,
        "predicted_rental_count": 6.5,
        "predicted_remaining_bikes": 0.0,
        "bike_availability_flag": False,
        "availability_level": "low",
        "predicted_demand": 9.0,
        "stock_gap": -5.0,
        "risk_score": 0.77,
        "reallocation_priority": 1,
        "service_tag": "베타",
    },
    {
        "station_id": 2303,
        "api_station_id": "ST-2303",
        "station_name": "학동역 1번출구 앞",
        "district_name": "논현동",
        "address": "서울 강남구 논현동 88-5",
        "latitude": 37.5142,
        "longitude": 127.0312,
        "cluster_code": "cluster01",
        "operational_status": "operational",
        "current_bike_stock": 14,
        "predicted_rental_count": 7.1,
        "predicted_remaining_bikes": 6.9,
        "bike_availability_flag": True,
        "availability_level": "sufficient",
        "predicted_demand": 7.0,
        "stock_gap": 7.0,
        "risk_score": 0.19,
        "reallocation_priority": 6,
        "service_tag": "베타",
    },
    {
        "station_id": 2407,
        "api_station_id": "ST-2407",
        "station_name": "압구정로데오역 6번출구 앞",
        "district_name": "압구정동",
        "address": "서울 강남구 신사동 662-7",
        "latitude": 37.5274,
        "longitude": 127.0401,
        "cluster_code": "cluster04",
        "operational_status": "operational",
        "current_bike_stock": 6,
        "predicted_rental_count": 5.8,
        "predicted_remaining_bikes": 0.2,
        "bike_availability_flag": True,
        "availability_level": "low",
        "predicted_demand": 10.0,
        "stock_gap": -4.0,
        "risk_score": 0.64,
        "reallocation_priority": 3,
        "service_tag": "베타",
    },
]


def _haversine_distance_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """두 좌표의 직선거리(m)를 계산한다."""
    earth_radius_m = 6371000.0
    d_lat = radians(lat2 - lat1)
    d_lon = radians(lon2 - lon1)
    lat1_rad = radians(lat1)
    lat2_rad = radians(lat2)

    a = sin(d_lat / 2) ** 2 + cos(lat1_rad) * cos(lat2_rad) * sin(d_lon / 2) ** 2
    return 2 * earth_radius_m * asin(sqrt(a))


def get_beta_user_items(lat: float, lng: float, limit: int) -> list[dict]:
    """사용자 화면용 6개 고정 스테이션을 거리 계산 후 반환한다."""
    items = []
    for station in BETA_STATIONS:
        item = {
            "station_id": station["station_id"],
            "station_name": station["station_name"],
            "address": station["address"],
            "latitude": station["latitude"],
            "longitude": station["longitude"],
            "distance_m": round(
                _haversine_distance_m(lat, lng, station["latitude"], station["longitude"]),
                1,
            ),
            "current_bike_stock": station["current_bike_stock"],
            "predicted_rental_count": station["predicted_rental_count"],
            "predicted_remaining_bikes": station["predicted_remaining_bikes"],
            "bike_availability_flag": station["bike_availability_flag"],
            "availability_level": station["availability_level"],
            "operational_status": station["operational_status"],
            "service_tag": station["service_tag"],
        }
        items.append(item)

    items.sort(key=lambda item: item["distance_m"])
    return items[:limit]


def get_beta_admin_items(
    district_name: str | None,
    urgent_only: bool | None,
    sort_by: str,
    sort_order: str,
) -> list[dict]:
    """관리자 화면용 6개 고정 스테이션을 필터·정렬해 반환한다."""
    items = []
    for station in BETA_STATIONS:
        item = {
            "station_id": station["station_id"],
            "station_name": station["station_name"],
            "district_name": station["district_name"],
            "cluster_code": station["cluster_code"],
            "latitude": station["latitude"],
            "longitude": station["longitude"],
            "current_bike_stock": station["current_bike_stock"],
            "predicted_demand": station["predicted_demand"],
            "stock_gap": station["stock_gap"],
            "risk_score": station["risk_score"],
            "reallocation_priority": station["reallocation_priority"],
            "operational_status": station["operational_status"],
            "service_tag": station["service_tag"],
        }
        items.append(item)

    if district_name:
        items = [item for item in items if item["district_name"] == district_name]
    if urgent_only:
        items = [item for item in items if item["risk_score"] >= 0.5]

    reverse = sort_order == "desc"
    items.sort(key=lambda item: item[sort_by], reverse=reverse)
    return items


def get_beta_master_items(
    district_name: str | None,
    cluster_code: str | None,
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
            "service_tag": station["service_tag"],
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
