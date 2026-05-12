-- 修改 subscription_plans.model_tags 字段类型从 text[] 改为 jsonb
-- 这样可以正确处理 JSON 序列化和反序列化

-- 先将现有的 text[] 数据转换为 jsonb
ALTER TABLE subscription_plans
ALTER COLUMN model_tags TYPE jsonb
USING CASE
    WHEN model_tags IS NULL OR model_tags = '{}' THEN '[]'::jsonb
    ELSE to_jsonb(model_tags)
END;

-- 设置默认值
ALTER TABLE subscription_plans
ALTER COLUMN model_tags SET DEFAULT '[]'::jsonb;
