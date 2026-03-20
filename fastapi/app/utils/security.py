"""
DDRI 입력 검증 - 인젝션 공격 방지
SQL/NoSQL/명령 인젝션, XSS 등 방지를 위한 화이트리스트·형식 검증
"""

import re
from datetime import datetime
from typing import Optional

SAFE_BAD_REQUEST_MESSAGE = "요청 값을 다시 확인해 주세요."
SAFE_WEATHER_ERROR_MESSAGE = "날씨 정보를 불러오지 못했습니다."


# ─── 허용 값 화이트리스트 ─────────────────────────────
SORT_BY_WHITELIST = frozenset({"risk_score", "reallocation_priority", "stock_gap"})
SORT_ORDER_WHITELIST = frozenset({"asc", "desc"})

# 강남구 행정동 (ddri_admin districtOptions 기준)
DISTRICT_WHITELIST = frozenset({
    "역삼동", "청담동", "삼성동", "대치동", "논현동",
    "압구정동", "세곡동", "자곡동", "율현동", "일원동", "수서동",
})

# cluster_code: cluster00 ~ cluster04
CLUSTER_CODE_PATTERN = re.compile(r"^cluster0[0-4]$")

# 행정동: 한글·숫자·공백만 (최대 20자, DB 연동 시 화이트리스트 우선)
DISTRICT_SAFE_PATTERN = re.compile(r"^[\uac00-\ud7a3\d\s]{1,20}$")

# ISO 8601 datetime 최대 길이 (예: 2026-03-20T18:00:00+09:00)
DATETIME_MAX_LEN = 32
DATE_MAX_LEN = 10  # YYYY-MM-DD


def validate_sort_by(value: str) -> str:
    """sort_by 화이트리스트 검증. DB ORDER BY 인젝션 방지."""
    v = (value or "").strip().lower()
    if v not in SORT_BY_WHITELIST:
        return "risk_score"
    return v


def validate_sort_order(value: str) -> str:
    """sort_order 화이트리스트 검증."""
    v = (value or "").strip().lower()
    if v not in SORT_ORDER_WHITELIST:
        return "desc"
    return v


def validate_district_name(value: Optional[str]) -> Optional[str]:
    """
    행정동 필터 검증.
    - 화이트리스트에 있으면 그대로 반환
    - 없으면 정규식으로 안전한 형식만 허용 (한글·숫자·공백)
    """
    if not value or not value.strip():
        return None
    v = value.strip()
    if v in DISTRICT_WHITELIST:
        return v
    if DISTRICT_SAFE_PATTERN.match(v):
        return v
    return None


def validate_cluster_code(value: Optional[str]) -> Optional[str]:
    """cluster_code 검증. cluster00~04만 허용."""
    if not value or not value.strip():
        return None
    v = value.strip().lower()
    if CLUSTER_CODE_PATTERN.match(v):
        return v
    return None


def validate_iso_datetime(value: str) -> Optional[str]:
    """
    ISO 8601 datetime 검증.
    - 형식 검증 후 파싱 가능하면 반환, 아니면 None
    """
    if not value or len(value) > DATETIME_MAX_LEN:
        return None
    v = value.strip()
    try:
        datetime.fromisoformat(v.replace("Z", "+00:00"))
        return v
    except (ValueError, TypeError):
        return None


def validate_date_yyyy_mm_dd(value: Optional[str]) -> Optional[str]:
    """YYYY-MM-DD 형식 검증."""
    if not value or len(value) > DATE_MAX_LEN:
        return None
    v = value.strip()
    try:
        datetime.strptime(v, "%Y-%m-%d")
        return v
    except (ValueError, TypeError):
        return None


def sanitize_for_display(value: Optional[str], max_len: int = 200) -> str:
    """
    화면 표시용 문자열 정제 (XSS·이상 문자 제거).
    Flutter Text 위젯은 기본 이스케이프하지만, API 응답에 포함될 때 대비.
    """
    if not value:
        return ""
    # 제어문자·null 제거
    s = "".join(c for c in str(value)[:max_len] if ord(c) >= 32 and ord(c) != 127)
    return s.strip()


def get_safe_bad_request_detail() -> str:
    """외부 응답용 공통 400 메시지."""
    return SAFE_BAD_REQUEST_MESSAGE


def get_safe_weather_error_message() -> str:
    """외부 응답용 공통 날씨 오류 메시지."""
    return SAFE_WEATHER_ERROR_MESSAGE


# ─── DB 연동 시 SQL 인젝션 방지 ─────────────────────
# 1. WHERE 절: 반드시 파라미터 바인딩 사용
#    cursor.execute("SELECT * FROM t WHERE district = %s", (district,))
# 2. ORDER BY: 컬럼/방향은 파라미터 바인딩 불가 → 화이트리스트 검증된 값만 사용
