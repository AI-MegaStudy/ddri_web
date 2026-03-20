"""
DDRI 관리자 페이지 API - 재배치 판단 목록 조회
14_ddri_api_schema.md 기준
"""

from fastapi import APIRouter, Query, HTTPException
from typing import Optional

from datetime import datetime

from .beta_station_data import get_beta_admin_items, get_beta_weather_reference
from ..core.runtime_config import get_service_mode, is_beta_mode
from ..utils.security import (
    validate_sort_by,
    validate_sort_order,
    validate_district_name,
    validate_cluster_code,
    validate_iso_datetime,
    get_safe_bad_request_detail,
)
from ..utils.weather_service import WeatherService

router = APIRouter()


def _build_weather_payload(base_datetime: str, district_name: str | None) -> dict:
    """관리자 화면용 실제 날씨 응답을 구성한다."""
    lat, lon = get_beta_weather_reference(district_name=district_name)
    weather_service = WeatherService()

    target_dt = datetime.fromisoformat(base_datetime.replace("Z", "+00:00"))
    weekly = weather_service.fetch_daily_forecast(lat=lat, lon=lon)
    selected = weather_service.fetch_single_datetime_weather(
        lat=lat,
        lon=lon,
        target_datetime=target_dt,
    )

    weekly_forecast = [
        {
            "weather_datetime": forecast["weather_datetime"].isoformat()
            if isinstance(forecast["weather_datetime"], datetime)
            else str(forecast["weather_datetime"]),
            "weather_type": forecast["weather_type"],
            "weather_low": forecast["weather_low"],
            "weather_high": forecast["weather_high"],
            "precipitation_probability_max": forecast["precipitation_probability_max"],
            "icon_url": forecast["icon_url"],
        }
        for forecast in weekly
    ]

    selected_forecast = {
        "weather_datetime": selected["weather_datetime"].isoformat()
        if isinstance(selected["weather_datetime"], datetime)
        else str(selected["weather_datetime"]),
        "weather_type": selected["weather_type"],
        "weather_low": selected["weather_low"],
        "weather_high": selected["weather_high"],
        "temperature": selected["temperature"],
        "precipitation_probability": selected["precipitation_probability"],
        "icon_url": selected["icon_url"],
    }

    return {
        "weekly_forecast": weekly_forecast,
        "selected_forecast": selected_forecast,
    }


@router.get("/stations/risk")
async def get_stations_risk(
    base_datetime: str = Query(..., description="기준 시각 (ISO 8601)"),
    urgent_only: Optional[bool] = Query(None, description="true 시 위험 대여소만"),
    district_name: Optional[str] = Query(None, description="행정동 필터 (예: 역삼동)"),
    cluster_code: Optional[str] = Query(None, description="지역 특성 필터 (예: cluster00)"),
    sort_by: Optional[str] = Query(
        "risk_score",
        description="risk_score | reallocation_priority | stock_gap",
    ),
    sort_order: Optional[str] = Query("desc", description="asc | desc"),
):
    """
    재배치 판단 목록 조회 (시간대별 위험도·우선순위)

    - 관리자 페이지용
    - 베타 기간에는 실제 전체 스테이션 대신 사전 선정된 6개만 노출
    """
    # 인젝션 방지: 입력 검증
    base_dt = validate_iso_datetime(base_datetime)
    if not base_dt:
        raise HTTPException(status_code=400, detail=get_safe_bad_request_detail())
    district = validate_district_name(district_name)
    cluster = validate_cluster_code(cluster_code)
    sort_col = validate_sort_by(sort_by or "risk_score")
    sort_dir = validate_sort_order(sort_order or "desc")

    # TODO: DB 연동 시 base_dt, district, cluster, sort_col, sort_dir 사용 (파라미터 바인딩)
    _ = (district, cluster, sort_col, sort_dir)  # DB 연동 시 사용
    service_mode = get_service_mode()

    if is_beta_mode():
        items = get_beta_admin_items(
            district_name=district,
            urgent_only=urgent_only,
            sort_by=sort_col,
            sort_order=sort_dir,
            base_datetime=base_dt,
            service_tag="베타",
        )
        summary = {
            "total_count": len(items),
            "risk_count": len([item for item in items if item["predicted_remaining_bikes"] <= 5.0]),
            "exception_count": 0,
            "avg_risk_score": round(
                sum(item["risk_score"] for item in items) / len(items),
                2,
            ) if items else 0.0,
            "avg_predicted_remaining_bikes": round(
                sum(item["predicted_remaining_bikes"] for item in items) / len(items),
                1,
            ) if items else 0.0,
        }
        list_mode = "beta_fixed_6"
    else:
        items = get_beta_admin_items(
            district_name=district,
            urgent_only=urgent_only,
            sort_by=sort_col,
            sort_order=sort_dir,
            base_datetime=base_dt,
            service_tag="",
        )
        summary = {
            "total_count": len(items),
            "risk_count": len([item for item in items if item["predicted_remaining_bikes"] <= 5.0]),
            "exception_count": 0,
            "avg_risk_score": round(
                sum(item["risk_score"] for item in items) / len(items),
                2,
            ) if items else 0.0,
            "avg_predicted_remaining_bikes": round(
                sum(item["predicted_remaining_bikes"] for item in items) / len(items),
                1,
            ) if items else 0.0,
        }
        list_mode = "live_runtime_fixed_6"

    try:
        weather_payload = _build_weather_payload(
            base_datetime=base_dt,
            district_name=district,
        )
    except Exception:
        weather_payload = {
            "weekly_forecast": [],
            "selected_forecast": None,
        }

    return {
        "base_datetime": base_dt,
        "service_mode": service_mode,
        "list_mode": list_mode,
        "weather": weather_payload,
        "summary": summary,
        "items": items,
        "exceptions": [],
    }
