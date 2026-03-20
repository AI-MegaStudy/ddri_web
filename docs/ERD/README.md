# ERD (Entity Relationship Diagram)

Mermaid 스크립트로 DDRI 최소 영속 구조 ERD를 정의한다.

## 파일

| 파일 | 설명 |
|------|------|
| ERD.mmd | 현재 기준 최소 ERD (`prediction_logs`) |
| ERD.png | 렌더링 결과 (선택) |

## 기준

- `fastapi/mysql/init_schema.sql` — 실제 MySQL DDL

## 사용법

- **VS Code**: Mermaid 확장으로 미리보기
- **GitHub**: .mmd 또는 .md 내 mermaid 블록으로 렌더링
- **온라인**: [Mermaid Live Editor](https://mermaid.live/)

## 참조

- `docs/02_web_service_final/04_ddri_database_design.md` — 최소 DB 설계
- `docs/DBML/mysql.dbml` — DBML 스키마
