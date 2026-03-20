"""
DDRI 런타임 설정.

- 환경변수 기반으로 베타/운영 모드를 전환한다.
- 베타 종료 후 `DDRI_SERVICE_MODE=live`로 바꾸면 고정 6개 제한과 베타 표기가 비활성화된다.
- `DDRI_DEBUG_LOG`로 서버 디버그 로그 출력을 제어한다.
"""

from __future__ import annotations

import os


SERVICE_MODE_BETA = "beta"
SERVICE_MODE_LIVE = "live"
_VALID_SERVICE_MODES = frozenset({SERVICE_MODE_BETA, SERVICE_MODE_LIVE})
_TRUE_VALUES = frozenset({"1", "true", "yes", "on", "y"})


def get_service_mode() -> str:
    """현재 서비스 모드를 반환한다. 잘못된 값이면 beta로 안전하게 폴백한다."""
    value = os.getenv("DDRI_SERVICE_MODE", SERVICE_MODE_BETA).strip().lower()
    if value in _VALID_SERVICE_MODES:
        return value
    return SERVICE_MODE_BETA


def is_beta_mode() -> bool:
    """베타 모드 여부."""
    return get_service_mode() == SERVICE_MODE_BETA


def is_debug_log_enabled() -> bool:
    """디버그 로그 활성화 여부."""
    value = os.getenv("DDRI_DEBUG_LOG", "").strip().lower()
    return value in _TRUE_VALUES
