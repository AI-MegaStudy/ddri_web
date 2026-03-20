"""
Weather API - Open-Meteo API 조회 (DB 저장 없음, API 키 불필요)
작성일: 2026-03-18
"""

from fastapi import APIRouter, Query
from typing import Optional
from datetime import datetime

from ..utils.security import (
    validate_date_yyyy_mm_dd,
    validate_iso_datetime,
    get_safe_bad_request_detail,
    get_safe_weather_error_message,
)
from ..utils.weather_service import WeatherService

router = APIRouter()


@router.get("/direct")
async def fetch_weather_direct(
    lat: float = Query(..., description="위도 (필수)"),
    lon: float = Query(..., description="경도 (필수)"),
    start_date: Optional[str] = Query(None, description="시작 날짜 (YYYY-MM-DD), 없으면 오늘 포함 7일치 모두 반환"),
):
    """
    Open-Meteo API에서 직접 날씨 데이터 가져오기 (DB 저장 없음)

    - lat, lon으로 Open-Meteo Forecast API 호출
    - start_date가 없으면: 오늘 포함 7일치 모두 반환
    - start_date가 있으면: 해당 날짜부터 남은 날짜만 반환 (최대 16일)
    - API 키 불필요
    """
    try:
        start_date_obj = None
        if start_date:
            validated = validate_date_yyyy_mm_dd(start_date)
            if not validated:
                return {"result": "Error", "errorMsg": get_safe_bad_request_detail()}
            start_date_obj = datetime.strptime(validated, "%Y-%m-%d")

        weather_service = WeatherService()
        forecast_list = weather_service.fetch_daily_forecast(
            lat=lat,
            lon=lon,
            start_date=start_date_obj,
        )

        results = []
        for forecast in forecast_list:
            weather_datetime = forecast["weather_datetime"]
            if isinstance(weather_datetime, datetime):
                weather_datetime_str = weather_datetime.isoformat()
            else:
                weather_datetime_str = str(weather_datetime)

            results.append({
                "weather_datetime": weather_datetime_str,
                "weather_type": forecast["weather_type"],
                "weather_low": forecast["weather_low"],
                "weather_high": forecast["weather_high"],
                "precipitation_probability_max": forecast["precipitation_probability_max"],
                "icon_url": forecast["icon_url"],
            })

        return {"results": results}

    except ValueError:
        return {"result": "Error", "errorMsg": get_safe_bad_request_detail()}
    except Exception:
        return {"result": "Error", "errorMsg": get_safe_weather_error_message()}


@router.get("/direct/single")
async def fetch_weather_direct_single(
    lat: float = Query(..., description="위도 (필수)"),
    lon: float = Query(..., description="경도 (필수)"),
    target_datetime: Optional[str] = Query(
        None,
        description="조회할 시각 (ISO datetime), 없으면 현재 시각 기준 가장 가까운 시간별 예보",
    ),
    target_date: Optional[str] = Query(
        None,
        description="하위 호환용 날짜 (YYYY-MM-DD). target_datetime이 없을 때만 사용",
    ),
):
    """
    Open-Meteo API에서 특정 시각의 시간별 날씨 데이터 1건 가져오기

    - lat, lon으로 Open-Meteo Forecast API 호출
    - target_datetime이 있으면 해당 시각에 가장 가까운 시간별 날씨 반환
    - target_datetime이 없고 target_date가 있으면 해당 날짜 12:00 기준으로 반환
    - 값이 모두 없으면 현재 시각 기준 반환
    - API 키 불필요
    """
    try:
        target_datetime_obj = None
        if target_datetime:
            validated = validate_iso_datetime(target_datetime)
            if not validated:
                return {"result": "Error", "errorMsg": get_safe_bad_request_detail()}
            target_datetime_obj = datetime.fromisoformat(validated.replace("Z", "+00:00"))
        elif target_date:
            validated = validate_date_yyyy_mm_dd(target_date)
            if not validated:
                return {"result": "Error", "errorMsg": get_safe_bad_request_detail()}
            target_datetime_obj = datetime.strptime(validated, "%Y-%m-%d").replace(hour=12)

        weather_service = WeatherService()
        forecast = weather_service.fetch_single_datetime_weather(
            lat=lat,
            lon=lon,
            target_datetime=target_datetime_obj,
        )

        weather_datetime = forecast["weather_datetime"]
        if isinstance(weather_datetime, datetime):
            weather_datetime_str = weather_datetime.isoformat()
        else:
            weather_datetime_str = str(weather_datetime)

        result = {
            "weather_datetime": weather_datetime_str,
            "weather_type": forecast["weather_type"],
            "weather_low": forecast["weather_low"],
            "weather_high": forecast["weather_high"],
            "temperature": forecast["temperature"],
            "precipitation_probability": forecast["precipitation_probability"],
            "icon_url": forecast["icon_url"],
        }

        return {"result": result}

    except ValueError:
        return {"result": "Error", "errorMsg": get_safe_bad_request_detail()}
    except Exception:
        return {"result": "Error", "errorMsg": get_safe_weather_error_message()}
