-- Add headcount limit to subscription plans and plan attribution to user subscriptions
-- This migration enables per-plan purchase headcount limits

-- 1. Add headcount_limit to subscription_plans
ALTER TABLE subscription_plans
ADD COLUMN IF NOT EXISTS headcount_limit INTEGER NOT NULL DEFAULT 0;

COMMENT ON COLUMN subscription_plans.headcount_limit IS
'Maximum number of active subscriptions allowed for this plan (0 = unlimited)';

-- 2. Add plan_id to user_subscriptions
ALTER TABLE user_subscriptions
ADD COLUMN IF NOT EXISTS plan_id BIGINT NULL;

COMMENT ON COLUMN user_subscriptions.plan_id IS
'The subscription plan this subscription is attributed to (NULL for legacy/non-plan subscriptions)';

-- 3. Add indexes for plan_id queries
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_plan_id
ON user_subscriptions(plan_id);

-- Composite index for active subscription counting by plan
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_plan_active
ON user_subscriptions(plan_id, status, expires_at)
WHERE deleted_at IS NULL;

-- 4. Backfill plan_id for existing subscriptions from completed payment orders
-- Only backfill subscriptions that can be clearly attributed to a plan purchase
-- Legacy subscriptions from redeem codes, admin assignments, or default grants remain NULL

UPDATE user_subscriptions us
SET plan_id = subq.plan_id
FROM (
    SELECT DISTINCT ON (po.user_id, po.subscription_group_id)
        po.user_id,
        po.subscription_group_id,
        po.plan_id
    FROM payment_orders po
    WHERE po.order_type = 'subscription'
      AND po.plan_id IS NOT NULL
      AND po.status IN ('COMPLETED', 'PAID', 'RECHARGING')
    ORDER BY po.user_id, po.subscription_group_id, po.completed_at DESC NULLS LAST, po.paid_at DESC NULLS LAST
) subq
WHERE us.user_id = subq.user_id
  AND us.group_id = subq.subscription_group_id
  AND us.plan_id IS NULL
  AND us.deleted_at IS NULL;
