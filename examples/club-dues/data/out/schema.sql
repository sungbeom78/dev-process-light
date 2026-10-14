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

-- 회원 개인정보: 회원 의 개인정보. 본 테이블과 1:1, 본 행을 지우면 같이 지워진다
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
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_dues_payment_member_id ON dues_payment (member_id);

COMMENT ON TABLE member IS '회원 -- 동아리 회원 한 명';
COMMENT ON COLUMN member.member_id IS '회원 번호';
COMMENT ON COLUMN member.joined_on IS '들어온 날';
COMMENT ON COLUMN member.status IS '상태';
COMMENT ON COLUMN member.created_at IS '만든 시각';
COMMENT ON COLUMN member.updated_at IS '고친 시각';
COMMENT ON TABLE pi_member IS '회원 개인정보 -- 회원 의 개인정보. 본 테이블과 1:1, 본 행을 지우면 같이 지워진다';
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
COMMIT;
