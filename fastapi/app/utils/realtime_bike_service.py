"""
서울시 따릉이 실시간 재고 서비스.

- OA-15493 bikeList 전체 페이지를 조회한 뒤 대상 station_id만 로컬 필터링한다.
- stationId query 파라미터는 현재 신뢰하지 않고 전체 조회 전략을 유지한다.
- 짧은 TTL 캐시를 둬서 같은 요청 구간에서 반복 호출을 줄인다.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
import os
from typing import Any

import requests


SEOUL_BIKE_API_BASE_URL = "http://openapi.seoul.go.kr:8088"
DEFAULT_PAGE_SIZE = 1000
DEFAULT_MAX_PAGES = 3
DEFAULT_CACHE_SECONDS = 30


@dataclass
class RealtimeBikeSnapshot:
    station_id: int
    api_station_id: str
    station_name: str
    current_bike_stock: float
    current_capacity: float | None
    shared: float | None
    station_latitude: float | None
    station_longitude: float | None
    source_updated_at: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "station_id": self.station_id,
            "api_station_id": self.api_station_id,
            "station_name": self.station_name,
            "current_bike_stock": self.current_bike_stock,
            "current_capacity": self.current_capacity,
            "shared": self.shared,
            "station_latitude": self.station_latitude,
            "station_longitude": self.station_longitude,
            "source_updated_at": self.source_updated_at,
        }


class RealtimeBikeService:
    def __init__(self) -> None:
        self._cached_rows: dict[int, dict[str, Any]] = {}
        self._cached_at: datetime | None = None

    def _get_api_key(self) -> str:
        return (
            os.getenv("SEOUL_BIKE_API_KEY", "").strip()
            or os.getenv("SEOUL_RTD_API_KEY", "").strip()
        )

    def _get_cache_seconds(self) -> int:
        raw = os.getenv("DDRI_BIKE_API_CACHE_SECONDS", str(DEFAULT_CACHE_SECONDS)).strip()
        try:
            return max(1, int(raw))
        except ValueError:
            return DEFAULT_CACHE_SECONDS

    def _is_cache_valid(self) -> bool:
        if self._cached_at is None:
            return False
        return datetime.now(timezone.utc) - self._cached_at < timedelta(
            seconds=self._get_cache_seconds()
        )

    def _build_url(self, api_key: str, start_index: int, end_index: int) -> str:
        return f"{SEOUL_BIKE_API_BASE_URL}/{api_key}/json/bikeList/{start_index}/{end_index}"

    def _extract_rows(self, payload: dict[str, Any]) -> list[dict[str, Any]]:
        for root_key in ("bikeList", "rentBikeStatus"):
            root = payload.get(root_key)
            if not isinstance(root, dict):
                continue
            rows = root.get("row")
            if isinstance(rows, list):
                return rows
        return []

    def _extract_result_code(self, payload: dict[str, Any]) -> str | None:
        for root_key in ("bikeList", "rentBikeStatus"):
            root = payload.get(root_key)
            if not isinstance(root, dict):
                continue
            result = root.get("RESULT")
            if not isinstance(result, dict):
                continue
            code = result.get("CODE")
            if code is not None:
                return str(code)
        return None

    def _normalize_row(self, row: dict[str, Any]) -> dict[str, Any] | None:
        station_num = row.get("stationNum") or row.get("station_num")
        if station_num is None:
            station_name = str(row.get("stationName", "")).strip()
            prefix = station_name.split(".", 1)[0].strip()
            if prefix.isdigit():
                station_num = prefix
        if station_num is None:
            return None

        try:
            station_id = int(float(station_num))
        except (TypeError, ValueError):
            return None

        def _float_or_none(value: Any) -> float | None:
            if value in (None, "", "null"):
                return None
            try:
                return float(value)
            except (TypeError, ValueError):
                return None

        return {
            "station_id": station_id,
            "api_station_id": str(row.get("stationId", "")).strip(),
            "station_name": str(row.get("stationName", "")).strip(),
            "current_bike_stock": _float_or_none(row.get("parkingBikeTotCnt")) or 0.0,
            "current_capacity": _float_or_none(row.get("rackTotCnt")),
            "shared": _float_or_none(row.get("shared")),
            "station_latitude": _float_or_none(row.get("stationLatitude")),
            "station_longitude": _float_or_none(row.get("stationLongitude")),
        }

    def refresh(self) -> dict[int, dict[str, Any]]:
        api_key = self._get_api_key()
        if not api_key:
            raise RuntimeError("SEOUL_BIKE_API_KEY is not configured")

        collected: dict[int, dict[str, Any]] = {}
        for page_index in range(DEFAULT_MAX_PAGES):
            start_index = (page_index * DEFAULT_PAGE_SIZE) + 1
            end_index = start_index + DEFAULT_PAGE_SIZE - 1
            response = requests.get(
                self._build_url(api_key, start_index, end_index),
                timeout=10,
            )
            response.raise_for_status()
            payload = response.json()
            result_code = self._extract_result_code(payload)
            rows = self._extract_rows(payload)

            for row in rows:
                normalized = self._normalize_row(row)
                if normalized is not None:
                    collected[int(normalized["station_id"])] = normalized

            if not rows:
                break
            if result_code and result_code != "INFO-000":
                break
            if len(rows) < DEFAULT_PAGE_SIZE:
                break

        self._cached_rows = collected
        self._cached_at = datetime.now(timezone.utc)
        return self._cached_rows

    def get_all_rows(self) -> dict[int, dict[str, Any]]:
        if self._is_cache_valid():
            return self._cached_rows
        return self.refresh()

    def get_station_snapshot(self, station_id: int) -> RealtimeBikeSnapshot | None:
        rows = self.get_all_rows()
        row = rows.get(int(station_id))
        if row is None:
            return None
        return RealtimeBikeSnapshot(
            station_id=int(row["station_id"]),
            api_station_id=str(row.get("api_station_id", "")),
            station_name=str(row.get("station_name", "")),
            current_bike_stock=float(row.get("current_bike_stock") or 0.0),
            current_capacity=row.get("current_capacity"),
            shared=row.get("shared"),
            station_latitude=row.get("station_latitude"),
            station_longitude=row.get("station_longitude"),
            source_updated_at=(self._cached_at or datetime.now(timezone.utc)).isoformat(),
        )
