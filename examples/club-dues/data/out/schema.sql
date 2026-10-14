-- 동아리 회비 -- postgresql schema (data-light)
-- 이 파일은 model.light.json 에서 만들어졌습니다. 직접 고치지 말고 정본을 고친 뒤 다시 build 하세요.
BEGIN;

-- 회원: 동아리 회원 한 명
CREATE TABLE member (
  member_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  joined_on date NOT NULL,
  status text NOT NULL DEFAULT '활동' CHECK (status IN ('활동', '휴면', '탈퇴')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 회원 개인정보: 회원의 개인정보. 본 테이블과 1:1, 본 행을 지우면 같이 지워진다
CREATE TABLE pi_member (
  member_id bigint NOT NULL REFERENCES member (member_id) ON DELETE CASCADE,
  member_name text NOT NULL,
  phone text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (member_id)
);

-- 회비 납부: 회원이 어느 달 회비를 언제 얼마 냈는지 한 번에 한 줄
CREATE TABLE dues_payment (
  dues_payment_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  member_id bigint NOT NULL REFERENCES member (member_id) ON DELETE RESTRICT,
  dues_month text NOT NULL,
  amount numeric(15,2) NOT NULL CHECK (amount >= 0),
  paid_on date NOT NULL,
  method text NOT NULL DEFAULT '계좌이체' CHECK (method IN ('계좌이체', '현금')),
  memo text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (member_id, dues_month)
);
CREATE INDEX ix_dues_payment_member_id ON dues_payment (member_id);

COMMENT ON TABLE member IS '회원 -- 동아리 회원 한 명';
COMMENT ON COLUMN member.member_id IS '회원 번호';
COMMENT ON COLUMN member.joined_on IS '들어온 날';
COMMENT ON COLUMN member.status IS '상태';
COMMENT ON COLUMN member.created_at IS '만든 시각';
COMMENT ON COLUMN member.updated_at IS '고친 시각';
COMMENT ON TABLE pi_member IS '회원 개인정보 -- 회원의 개인정보. 본 테이블과 1:1, 본 행을 지우면 같이 지워진다';
COMMENT ON COLUMN pi_member.member_id IS '회원 번호';
COMMENT ON COLUMN pi_member.member_name IS '이름 [개인정보]';
COMMENT ON COLUMN pi_member.phone IS '전화번호 [개인정보]';
COMMENT ON COLUMN pi_member.created_at IS '만든 시각';
COMMENT ON COLUMN pi_member.updated_at IS '고친 시각';
COMMENT ON TABLE dues_payment IS '회비 납부 -- 회원이 어느 달 회비를 언제 얼마 냈는지 한 번에 한 줄';
COMMENT ON COLUMN dues_payment.dues_payment_id IS '납부 번호';
COMMENT ON COLUMN dues_payment.member_id IS '회원';
COMMENT ON COLUMN dues_payment.dues_month IS '회비 달';
COMMENT ON COLUMN dues_payment.amount IS '금액';
COMMENT ON COLUMN dues_payment.paid_on IS '낸 날';
COMMENT ON COLUMN dues_payment.method IS '낸 방법';
COMMENT ON COLUMN dues_payment.memo IS '메모';
COMMENT ON COLUMN dues_payment.created_at IS '만든 시각';
COMMENT ON COLUMN dues_payment.updated_at IS '고친 시각';

-- ===== 행 접근 규칙 (RLS) =====
-- Supabase 에서는 사이트 코드에 넣는 공개용 키(anon · publishable)로 누구나 모든 표에 접근을 시도할 수 있습니다.
-- 그래서 모든 표에 RLS 를 켭니다. 규칙(policy)이 없는 표는 공개용 키로 아무것도 읽고 쓸 수 없습니다 (안전한 기본값).
-- 규칙은 정본의 표에 "access" 를 적고 다시 build 하면 아래에 만들어집니다 (권장: members · own · read).
-- 틀만 있는 표는 이 파일을 고치지 말고, SQL 편집기에 붙여 넣은 뒤 고른 틀의 주석을 풀어 실행하고,
-- 실행한 규칙은 data/supabase-policies.sql 에 적어 둡니다 (이 파일을 고치면 verify 가 '정본과 다릅니다'로 멈춥니다).
-- 사이트 코드에는 공개용 키만. service_role · sb_secret_ 키는 절대 넣지 않습니다. 적용 뒤 Supabase 의 Security Advisor 를 확인하세요.
-- (일반 PostgreSQL 에서는 표 주인 계정에는 RLS 가 적용되지 않아 동작이 바뀌지 않습니다.)
-- 이 사이트는 새 가입을 끈 것으로 정했습니다(signup: closed). Supabase 의 가입 설정이 꺼져 있는지 확인하세요.
ALTER TABLE member ENABLE ROW LEVEL SECURITY;
CREATE POLICY member_members ON member FOR ALL TO authenticated USING (true) WITH CHECK (true);
ALTER TABLE pi_member ENABLE ROW LEVEL SECURITY;
CREATE POLICY pi_member_members ON pi_member FOR ALL TO authenticated USING (true) WITH CHECK (true);
ALTER TABLE dues_payment ENABLE ROW LEVEL SECURITY;
CREATE POLICY dues_payment_members ON dues_payment FOR ALL TO authenticated USING (true) WITH CHECK (true);
COMMIT;
