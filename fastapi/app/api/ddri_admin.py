"""
DDRI 관리자 페이지 API - 재배치 판단 목록 조회
14_ddri_api_schema.md 기준
"""

from fastapi import APIRouter, Query, HTTPException
from typing import Optional

from .beta_station_data import get_beta_admin_items
from ..core.runtime_config import get_service_mode, is_beta_mode
from ..utils.security import (
    validate_sort_by,
    validate_sort_order,
    validate_district_name,
    validate_cluster_code,
    validate_iso_datetime,
)

router = APIRouter()


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
        raise HTTPException(status_code=400, detail="base_datetime 형식이 올바르지 않습니다. (ISO 8601)")
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
        )
        summary = {
            "total_count": len(items),
            "risk_count": len([item for item in items if item["risk_score"] >= 0.5]),
            "exception_count": 0,
            "avg_risk_score": round(
                sum(item["risk_score"] for item in items) / len(items),
                2,
            ) if items else 0.0,
        }
        list_mode = "beta_fixed_6"
    else:
        items = [
            {
                "station_id": 2328,
                "station_name": "르네상스 호텔 사거리 역삼지하보도 7번출구 앞",
                "district_name": "역삼동",
                "cluster_code": "cluster00",
                "current_bike_stock": 7,
                "predicted_demand": 12.0,
                "stock_gap": -5.0,
                "risk_score": 0.72,
                "reallocation_priority": 1,
                "operational_status": "operational",
                "service_tag": "",
            },
            {
                "station_id": 2348,
                "station_name": "강남역 2번출구 앞",
                "district_name": "역삼동",
                "cluster_code": "cluster01",
                "current_bike_stock": 3,
                "predicted_demand": 8.0,
                "stock_gap": -5.0,
                "risk_score": 0.68,
                "reallocation_priority": 2,
                "operational_status": "operational",
                "service_tag": "",
            },
        ]
        summary = {
            "total_count": 161,
            "risk_count": 23,
            "exception_count": 3,
            "avg_risk_score": 0.42,
        }
        list_mode = "live_risk"

    return {
        "base_datetime": base_dt,
        "service_mode": service_mode,
        "list_mode": list_mode,
        "weather": {
            "weekly_forecast": [
                {
                    "weather_datetime": "2026-03-20T00:00:00+09:00",
                    "weather_type": "맑음",
                    "weather_low": 4.0,
                    "weather_high": 13.0,
                    "icon_url": "https://openweathermap.org/img/wn/01d@2x.png",
                },
                {
                    "weather_datetime": "2026-03-21T00:00:00+09:00",
                    "weather_type": "구름많음",
                    "weather_low": 6.0,
                    "weather_high": 14.0,
                    "icon_url": "https://openweathermap.org/img/wn/03d@2x.png",
                },
                {
                    "weather_datetime": "2026-03-22T00:00:00+09:00",
                    "weather_type": "비",
                    "weather_low": 7.0,
                    "weather_high": 11.0,
                    "icon_url": "https://openweathermap.org/img/wn/10d@2x.png",
                },
            ],
            "selected_forecast": {
                "weather_datetime": base_dt,
                "weather_type": "구름많음",
                "weather_low": 6.0,
                "weather_high": 14.0,
                "icon_url": "https://openweathermap.org/img/wn/03d@2x.png",
            },
        },
        "summary": summary,
        "items": items,
        "exceptions": [] if is_beta_mode() else [
            {"station_id": 2314, "reason": "실시간 비노출"},
            {"station_id": 2323, "reason": "실시간 비노출"},
            {"station_id": 3628, "reason": "실시간 비노출"},
        ],
    }
