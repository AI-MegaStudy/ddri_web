"""
DDRI 스테이션 마스터 API.

- 정식 운영 전까지는 베타 노출용 6개만 반환한다.
"""

from fastapi import APIRouter, Query
from typing import Optional

from .beta_station_data import get_beta_master_items
from ..core.runtime_config import get_service_mode, is_beta_mode
from ..utils.security import validate_district_name, validate_cluster_code

router = APIRouter()


@router.get("")
async def get_stations(
    district_name: Optional[str] = Query(None, description="행정동 필터"),
    cluster_code: Optional[str] = Query(None, description="지역 특성 필터 (cluster00~04)"),
):
    """
    스테이션 마스터 목록 조회

    - 베타 기간에는 동일한 6개만 반환
    """
    # 인젝션 방지: 입력 검증
    district = validate_district_name(district_name)
    cluster = validate_cluster_code(cluster_code)
    # TODO: DB 연동 시 district, cluster 사용 (파라미터 바인딩)
    _ = (district, cluster)
    service_mode = get_service_mode()
    if is_beta_mode():
        items = get_beta_master_items(district_name=district, cluster_code=cluster)
        list_mode = "beta_fixed_6"
        total_count = len(items)
    else:
        items = [
            {
                "station_id": 2328,
                "api_station_id": "ST-1234",
                "station_name": "르네상스 호텔 사거리 역삼지하보도 7번출구 앞",
                "district_name": "역삼동",
                "address": "서울 강남구 역삼동 123-45",
                "latitude": 37.5001,
                "longitude": 127.0389,
                "cluster_code": "cluster00",
                "operational_status": "operational",
                "service_tag": "",
            },
            {
                "station_id": 2348,
                "api_station_id": "ST-1235",
                "station_name": "강남역 2번출구 앞",
                "district_name": "역삼동",
                "address": "서울 강남구 역삼동 456-78",
                "latitude": 37.4985,
                "longitude": 127.0276,
                "cluster_code": "cluster01",
                "operational_status": "operational",
                "service_tag": "",
            },
        ]
        list_mode = "live_master"
        total_count = 161
    return {
        "service_mode": service_mode,
        "list_mode": list_mode,
        "items": items,
        "total_count": total_count,
    }
