-- Add extra_rate_multiplier field to groups table
-- This field is used internally for billing calculations but not displayed to end users
-- The effective rate multiplier = rate_multiplier + extra_rate_multiplier

ALTER TABLE groups ADD COLUMN IF NOT EXISTS extra_rate_multiplier DECIMAL(10,4) DEFAULT 0.0 NOT NULL;

COMMENT ON COLUMN groups.extra_rate_multiplier IS '额外费率倍数，仅用于内部计费计算，不对客户端展示。实际费率 = rate_multiplier + extra_rate_multiplier';
