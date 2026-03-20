"""
DDRI 사용자 페이지 API - 근처 대여소 조회
14_ddri_api_schema.md 기준
"""

from fastapi import APIRouter, Query, HTTPException
from typing import Optional

from .beta_station_data import get_beta_user_items
from ..core.runtime_config import get_service_mode, is_beta_mode
from ..utils.security import validate_iso_datetime, get_safe_bad_request_detail

router = APIRouter()


@router.get("/stations/nearby")
async def get_stations_nearby(
    lat: float = Query(..., description="위도"),
    lng: float = Query(..., description="경도"),
    target_datetime: str = Query(..., description="예측 기준 시각 (ISO 8601, 예: 2026-03-18T18:00:00+09:00)"),
    limit: Optional[int] = Query(20, ge=1, le=50, description="반환 개수"),
    radius_m: Optional[int] = Query(None, description="반경(m). 미지정 시 전체 중 거리순"),
):
    """
    근처 대여소 목록 조회 (거리순, 지정 시간대 예측)

    - 사용자 페이지용
    - 베타 기간에는 실제 위치 근처 전체 스테이션 대신 사전 선정된 6개만 노출
    - 입력 좌표 기준 distance_m만 계산해 정렬
    """
    # 인젝션 방지: target_datetime 검증
    target_dt = validate_iso_datetime(target_datetime)
    if not target_dt:
        raise HTTPException(status_code=400, detail=get_safe_bad_request_detail())

    service_mode = get_service_mode()

    if is_beta_mode():
        items = get_beta_user_items(lat=lat, lng=lng, limit=limit or 6)
        list_mode = "beta_fixed_6"
    else:
        items = [
            {
                "station_id": 2328,
                "station_name": "르네상스 호텔 사거리 역삼지하보도 7번출구 앞",
                "address": "서울 강남구 역삼동 123-45",
                "latitude": 37.5001,
                "longitude": 127.0389,
                "distance_m": 150,
                "current_bike_stock": 7,
                "predicted_rental_count": 5.2,
                "predicted_remaining_bikes": 1.8,
                "bike_availability_flag": True,
                "availability_level": "low",
                "operational_status": "operational",
                "service_tag": "",
            },
            {
                "station_id": 2348,
                "station_name": "강남역 2번출구 앞",
                "address": "서울 강남구 역삼동 456-78",
                "latitude": 37.4985,
                "longitude": 127.0276,
                "distance_m": 320,
                "current_bike_stock": 12,
                "predicted_rental_count": 8.0,
                "predicted_remaining_bikes": 4.0,
                "bike_availability_flag": True,
                "availability_level": "normal",
                "operational_status": "operational",
                "service_tag": "",
            },
        ]
        list_mode = "live_nearby"

    return {
        "target_datetime": target_dt,
        "service_mode": service_mode,
        "list_mode": list_mode,
        "user_location": {"lat": lat, "lng": lng},
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
                "weather_datetime": target_dt,
                "weather_type": "구름많음",
                "weather_low": 6.0,
                "weather_high": 14.0,
                "icon_url": "https://openweathermap.org/img/wn/03d@2x.png",
            },
        },
        "items": items,
        "exceptions": [],
    }
