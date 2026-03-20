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
        items = get_beta_master_items(
            district_name=district,
            cluster_code=cluster,
            service_tag="베타",
        )
        list_mode = "beta_fixed_6"
        total_count = len(items)
    else:
        items = get_beta_master_items(
            district_name=district,
            cluster_code=cluster,
            service_tag="",
        )
        list_mode = "live_runtime_fixed_6"
        total_count = len(items)
    return {
        "service_mode": service_mode,
        "list_mode": list_mode,
        "items": items,
        "total_count": total_count,
    }
