# 동아리 회비 -- 테이블 정의서

DB: postgresql

## 성공 기준 -- 이 데이터로 할 수 있어야 하는 것

`datalight.py verify` 가 아래 확인 쿼리를 샘플 데이터로 실제로 돌려 봅니다.

1. 활동 중인데 이번 달(2026-10) 회비를 안 낸 회원을 볼 수 있다 (미납 보기)  
   `SELECT m.member_id FROM member m WHERE m.status = '활동' AND NOT EXISTS (SELECT 1 FROM dues_payment d WHERE d.member_id = m.member_id AND d.dues_month = '2026-10')`
2. 회원별로 지금까지 낸 회비 합계를 볼 수 있다 (회비 입력·미납 보기)  
   `SELECT member_id, SUM(amount) FROM dues_payment GROUP BY member_id`

**이번에 만들지 않을 것:** 문자 알림, 자동이체 연동


## 회원 (`member`)

동아리 회원 한 명

| 순번 | 칸 | 칸 이름표 | 자료형 | 키 | 규칙 | 개인정보 | 설명 |
|---|---|---|---|---|---|---|---|
| 1 | member_id | 회원 번호 | 번호(자동) | 키 | 필수 |  |  |
| 2 | joined_on | 들어온 날 | 날짜 |  | 필수 |  |  |
| 3 | status | 상태 | 글자 |  | 필수, 선택: 활동/휴면/탈퇴 |  |  |
| 4 | created_at | 만든 시각 | 날짜+시각 |  | 필수 |  | 자동 |
| 5 | updated_at | 고친 시각 | 날짜+시각 |  | 필수 |  | 자동 |

## 회원 개인정보 (`pi_member`)

회원의 개인정보. 본 테이블과 1:1, 본 행을 지우면 같이 지워진다

| 순번 | 칸 | 칸 이름표 | 자료형 | 키 | 규칙 | 개인정보 | 설명 |
|---|---|---|---|---|---|---|---|
| 1 | member_id | 회원 번호 | 다른 표 가리킴 | 키 | 필수, → member (같이 지움) |  |  |
| 2 | member_name | 이름 | 글자 |  | 필수 | name |  |
| 3 | phone | 전화번호 | 글자 |  |  | phone |  |
| 4 | created_at | 만든 시각 | 날짜+시각 |  | 필수 |  | 자동 |
| 5 | updated_at | 고친 시각 | 날짜+시각 |  | 필수 |  | 자동 |

## 회비 납부 (`dues_payment`)

회원이 어느 달 회비를 언제 얼마 냈는지 한 번에 한 줄

함께 중복 금지: member_id + dues_month

| 순번 | 칸 | 칸 이름표 | 자료형 | 키 | 규칙 | 개인정보 | 설명 |
|---|---|---|---|---|---|---|---|
| 1 | dues_payment_id | 납부 번호 | 번호(자동) | 키 | 필수 |  |  |
| 2 | member_id | 회원 | 다른 표 가리킴 |  | 필수, → member (지우지 못하게) |  |  |
| 3 | dues_month | 회비 달 | 글자 |  | 필수 |  | 몇 월 회비인지 2026-10 처럼 |
| 4 | amount | 금액 | 금액 |  | 필수 |  |  |
| 5 | paid_on | 낸 날 | 날짜 |  | 필수 |  |  |
| 6 | method | 낸 방법 | 글자 |  | 필수, 선택: 계좌이체/현금 |  |  |
| 7 | memo | 메모 | 긴 글 |  |  |  |  |
| 8 | created_at | 만든 시각 | 날짜+시각 |  | 필수 |  | 자동 |
| 9 | updated_at | 고친 시각 | 날짜+시각 |  | 필수 |  | 자동 |
