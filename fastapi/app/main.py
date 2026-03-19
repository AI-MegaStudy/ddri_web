"""
DDRI FastAPI 백엔드
강남구 따릉이 대여소 조회·재배치 지원 웹서비스
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os
from app.core.runtime_config import get_service_mode

# .env 파일에서 환경변수 로드
env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
load_dotenv(dotenv_path=env_path)

app = FastAPI(
    title="DDRI API",
    description="강남구 따릉이 대여소 조회·재배치 지원 REST API",
    version="1.0.0"
)

# CORS 설정 (Flutter 웹과 통신을 위해 필요)
# allow_credentials=True일 때 allow_origins=["*"] 사용 불가 → credentials=False
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================
# 라우터 등록
# ============================================
from app.api import weather, ddri_user, ddri_admin, ddri_stations
app.include_router(weather.router, prefix="/v1/weather", tags=["weather"])
app.include_router(ddri_user.router, prefix="/v1/user", tags=["ddri-user"])
app.include_router(ddri_admin.router, prefix="/v1/admin", tags=["ddri-admin"])
app.include_router(ddri_stations.router, prefix="/v1/stations", tags=["ddri-stations"])

@app.get("/")
async def root():
    """루트 엔드포인트 - API 정보 반환"""
    return {
        "message": "DDRI API",
        "status": "running",
        "version": "1.0.0",
        "service_mode": get_service_mode(),
        "endpoints": {
            "health": "/health",
            "docs": "/docs",
            "redoc": "/redoc"
        }
    }


@app.get("/health")
async def health_check():
    """헬스 체크 엔드포인트"""
    # 데이터베이스 연결이 필요할 때 주석 해제
    # try:
    #     conn = connect_db()
    #     conn.close()
    #     return {"status": "healthy", "database": "connected"}
    # except Exception as e:
    #     return {"status": "unhealthy", "error": str(e)}
    
    return {
        "status": "healthy",
        "message": "API is running",
        "service_mode": get_service_mode(),
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
