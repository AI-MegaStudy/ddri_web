# DBML (Database Markup Language)

DDRI MySQL 스키마를 DBML 형식으로 정의한다.

## 파일

| 파일 | 설명 |
|------|------|
| mysql.dbml | ddri_db 테이블 정의 (prediction_logs) |

## 기준

- `fastapi/mysql/init_schema.sql` — 실제 MySQL DDL

## 사용법

- **dbdiagram.io**: [dbdiagram.io](https://dbdiagram.io)에 붙여넣기 → ERD 시각화
- **dbml-cli**: `npx dbml-renderer mysql.dbml` (설치 필요 시)

## 참조

- `docs/02_web_service_final/04_ddri_database_design.md` — 테이블 설계
- `docs/ERD/ERD.mmd` — Mermaid ERD
