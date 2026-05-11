#!/bin/bash

# 易支付配置测试脚本
# 用于测试易支付 API 是否配置正确

echo "==================================="
echo "易支付配置测试"
echo "==================================="
echo ""

# 配置参数（请根据实际情况修改）
PID="16405"
PKEY="你的密钥"  # 请替换为实际的 PKey
API_BASE="https://zpayz.cn"
OUT_TRADE_NO="TEST_$(date +%s)"
AMOUNT="0.01"
NAME="测试订单"
NOTIFY_URL="https://robotcat.win/api/v1/payment/webhook/easypay"
RETURN_URL="https://robotcat.win/payment/result"

echo "配置信息："
echo "PID: $PID"
echo "API Base: $API_BASE"
echo "订单号: $OUT_TRADE_NO"
echo ""

# 生成签名
generate_sign() {
    local params="money=${AMOUNT}&name=${NAME}&notify_url=${NOTIFY_URL}&out_trade_no=${OUT_TRADE_NO}&pid=${PID}&return_url=${RETURN_URL}&type=alipay${PKEY}"
    echo -n "$params" | md5sum | awk '{print $1}'
}

SIGN=$(generate_sign)

echo "生成的签名: $SIGN"
echo ""
echo "==================================="
echo "测试 1: 检查 API 可访问性"
echo "==================================="

curl -I "$API_BASE" 2>&1 | head -5
echo ""

echo "==================================="
echo "测试 2: 调用支付 API (mapi.php)"
echo "==================================="

response=$(curl -s -X POST "$API_BASE/mapi.php" \
  -d "pid=$PID" \
  -d "type=alipay" \
  -d "out_trade_no=$OUT_TRADE_NO" \
  -d "notify_url=$NOTIFY_URL" \
  -d "return_url=$RETURN_URL" \
  -d "name=$NAME" \
  -d "money=$AMOUNT" \
  -d "sign=$SIGN" \
  -d "sign_type=MD5")

echo "API 响应："
echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
echo ""

# 解析响应
code=$(echo "$response" | grep -o '"code":[0-9]*' | cut -d':' -f2)
msg=$(echo "$response" | grep -o '"msg":"[^"]*"' | cut -d'"' -f4)

echo "==================================="
echo "测试结果"
echo "==================================="

if [ "$code" = "1" ]; then
    echo "✅ 成功！易支付配置正确"
    echo ""
    echo "返回的支付信息："
    echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
else
    echo "❌ 失败！"
    echo "错误代码: $code"
    echo "错误信息: $msg"
    echo ""
    echo "可能的原因："
    echo "1. PID 或 PKey 配置错误"
    echo "2. 易支付账户未开通支付宝通道"
    echo "3. 易支付账户余额不足"
    echo "4. 易支付账户状态异常"
    echo ""
    echo "请检查："
    echo "- 登录易支付后台确认 PID 和 PKey"
    echo "- 确认支付宝通道已开通且状态正常"
    echo "- 确认账户余额充足"
fi

echo ""
echo "==================================="
echo "完整响应内容："
echo "==================================="
echo "$response"
