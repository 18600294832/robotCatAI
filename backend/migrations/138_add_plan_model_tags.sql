-- Add model_tags field to subscription_plans table
-- This field allows custom model tags to be displayed on the plan card

ALTER TABLE subscription_plans ADD COLUMN IF NOT EXISTS model_tags TEXT[] DEFAULT '{}';

COMMENT ON COLUMN subscription_plans.model_tags IS '套餐展示的模型标签，例如 ["Claude", "Gemini", "Imagen"]';
