# Top 6 모델 런타임 준비 문서

작성일: 2026-03-20
목적: `/Users/cheng80/Desktop/ddri_work/hmw3/Note/hmw_top5_station_trends_2023_2025.ipynb` 및 관련 노트북/데이터 경로를 읽고, 추후 FastAPI 런타임 연결 작업을 진행하기 위한 사전 정리 문서.

## 현재 원칙

- 이 문서는 분석과 준비만 다룬다.
- 지금 단계에서는 `joblib` 파일을 바로 생성하지 않는다.
- 추후 별도 노트북이나 스크립트에서 재현 가능하게 경로와 작업 단위를 먼저 고정한다.

## 1. 확인한 노트북과 역할

### 1-1. 시각화 노트북

- 경로: `/Users/cheng80/Desktop/ddri_work/hmw3/Note/hmw_top5_station_trends_2023_2025.ipynb`
- 역할:
  - `station_hour_bike_flow_2023_2025.csv`를 찾는다.
  - `rental_count + return_count` 기준 이용량 상위 스테이션을 뽑는다.
  - 시간별, 요일별, 월별, 연도별 추이를 시각화한다.
- 한계:
  - 모델 학습을 하지 않는다.
  - `joblib` 저장 로직이 없다.
  - FastAPI 배포 단위를 직접 결정하지 않는다.

### 1-2. 실제 모델 구조 확인용 노트북

- 경로: `/Users/cheng80/Desktop/ddri_work/hmw3/Note/hmw2332.ipynb`
- 역할:
  - `station_2332.csv` 기준으로 학습 구조를 보여준다.
  - `rental_count`, `return_count`를 각각 Ridge로 학습한다.
  - `day_type`, `hour`, `month`, `year` 기반 feature와 보정 weight를 사용한다.
  - 결과는 현재 CSV 산출물 중심으로 저장한다.

### 1-3. 상위 스테이션 통합 생성 스크립트

- 경로: `/Users/cheng80/Desktop/ddri_work/hmw3/scripts/generate_top20_station_suite.py`
- 역할:
  - 상위 20개 스테이션 기준 데이터/노트북/지표를 생성한다.
  - 통합 test `R^2` 기준 랭킹을 만든다.
  - 상위 6개 스테이션을 별도로 추린다.

## 2. 현재 확인한 관련 경로

### 2-1. 원천/중간 데이터

- `/Users/cheng80/Desktop/ddri_work/hmw3/Data`
- `/Users/cheng80/Desktop/ddri_work/hmw3/Data/top20_station_metrics_summary.csv`
- `/Users/cheng80/Desktop/ddri_work/hmw3/Data/station_2306.csv`
- `/Users/cheng80/Desktop/ddri_work/hmw3/Data/station_2335.csv`
- `/Users/cheng80/Desktop/ddri_work/hmw3/Data/station_2348.csv`
- `/Users/cheng80/Desktop/ddri_work/hmw3/Data/station_2375.csv`
- `/Users/cheng80/Desktop/ddri_work/hmw3/Data/station_2377.csv`
- `/Users/cheng80/Desktop/ddri_work/hmw3/Data/station_2384.csv`

### 2-2. 참고 문서/코드

- `/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/02_system_design.md`
- `/Users/cheng80/Desktop/ddri_web/fastapi/requirements.txt`

## 3. 현재 기준 상위 6개 스테이션

- 통합 test `R^2` 기준 확인 결과:
  - `2348`
  - `2335`
  - `2377`
  - `2384`
  - `2306`
  - `2375`

주의:

- `hmw_top5_station_trends_2023_2025.ipynb`는 이용량 기준 top5 시각화 노트북이다.
- 현재 웹서비스 후보 6개는 통합 test `R^2` 기준 상위 6개이며 기준이 다르다.
- 따라서 이후 작업용 노트북은 `top5 시각화 기준`이 아니라 `top6 모델 배포 기준`으로 새로 정리하는 편이 맞다.

## 4. 현재 모델 구조 해석

- 모델 타깃은 2개다.
  - `rental_count`
  - `return_count`
- 스테이션별로 타깃 2개 모델이 존재한다.
- `bike_change`는 직접 학습 모델이 아니라 예측 결과에서 파생 계산한다.
- 재고 흐름도 직접 예측이 아니라 다음 식으로 누적 계산하는 구조다.
  - `다음 시점 재고 = 현재 재고 - 예측 rental_count + 예측 return_count`

## 5. 추후 런타임 변환 시 저장 단위 후보

### 권장안

- 스테이션당 1개 번들 파일
- 파일 내부 포함 항목 예시:
  - `station_id`
  - `rental_count` 모델
  - `return_count` 모델
  - `base/formula`
  - `month/year/hour weight`
  - feature 컬럼 정의
  - 메타데이터
- 상위 6개만 사용 시 총 6개 파일

### 대안

- 타깃별 개별 파일 저장
- 스테이션 6개 x 타깃 2개
- 총 12개 파일

## 6. 준비한 작업물

### 6-1. 준비용 문서

- `/Users/cheng80/Desktop/ddri_web/cheng80/03_top6_model_runtime_prep.md`

### 6-2. 준비용 노트북

- `/Users/cheng80/Desktop/ddri_web/cheng80/04_top6_model_runtime_prep.ipynb`
- 현재 포함 내용:
  - 핵심 경로 존재 여부 확인
  - 상위 6개 스테이션 관련 파일 점검
  - 통합 test `R^2` 기준 상위 6개 재검증
  - 번들 파일명/구성 미리보기 준비

### 6-3. 재실행용 스크립트

- `/Users/cheng80/Desktop/ddri_web/cheng80/top6_model_runtime_export.py`
- 현재 포함 내용:
  - 상위 6개 재검증
  - 스테이션별 필수 파일 점검
  - FastAPI용 번들 스키마 미리보기 생성
  - 아직 `joblib.dump(...)`는 수행하지 않음

## 7. 다음에 만들 작업물 제안

지금 바로 모델 파일을 만들지 않는다면, 다음 작업물 중 하나를 새로 만드는 방식이 적절하다.

### 옵션 A. 준비용 노트북

- 파일 예시: `/Users/cheng80/Desktop/ddri_web/cheng80/04_top6_model_runtime_prep.ipynb`
- 목적:
  - 상위 6개 스테이션 목록 고정
  - 각 스테이션의 입력 CSV/지표 확인
  - 모델 산출물 구조를 DataFrame으로 점검
  - 나중에 `joblib.dump(...)`만 추가할 수 있게 준비

### 옵션 B. 변환 스크립트

- 파일 예시: `/Users/cheng80/Desktop/ddri_web/cheng80/top6_model_runtime_export.py`
- 목적:
  - 노트북 의존성을 줄이고 재실행 가능한 export 경로 확보
  - FastAPI에서 바로 사용할 산출물 디렉터리 생성 준비

## 8. 권장 진행 순서

1. 상위 6개 기준을 문서로 고정한다.
2. 준비용 노트북 또는 변환 스크립트 중 하나를 선택한다.
3. 각 스테이션별 입력/산출물 경로를 검증한다.
4. 번들 스키마를 먼저 확정한다.
5. 그다음 `joblib` 저장 로직을 추가한다.
6. 마지막에 FastAPI 로더를 연결한다.

## 9. 현재 결론

- 가능하다.
- `cheng80` 아래 별도 문서를 두고 그 문서를 기준으로 다음 작업을 진행하는 방식이 적절하다.
- 지금 단계에서는 문서, 준비용 노트북, export 준비 스크립트까지 갖춘 상태다.
- 다음 차수에서는 번들 스키마 확정 후 `joblib` 저장 로직만 추가하면 된다.
