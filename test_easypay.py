#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
易支付配置测试脚本
用于测试 PID 和 PKey 是否配置正确
"""

import hashlib
import requests
import json
from urllib.parse import urlencode

# ========== 配置参数（请修改为实际值） ==========
PID = "16405"
PKEY = "你的密钥"  # 请从易支付后台"详情"中获取
API_BASE = "https://zpayz.cn"
# ===============================================

def md5_sign(params, key):
    """生成 MD5 签名"""
    # 按字典序排序参数
    sorted_params = sorted(params.items())
    # 拼接参数
    sign_str = '&'.join([f"{k}={v}" for k, v in sorted_params]) + key
    # MD5 加密
    return hashlib.md5(sign_str.encode('utf-8')).hexdigest()

def test_easypay():
    """测试易支付配置"""
    print("=" * 50)
    print("易支付配置测试")
    print("=" * 50)
    print(f"\nPID: {PID}")
    print(f"API Base: {API_BASE}")

    if PKEY == "你的密钥":
        print("\n❌ 错误：请先修改脚本中的 PKEY 为实际密钥！")
        print("\n获取方式：")
        print("1. 登录易支付后台")
        print("2. 找到你的渠道（PID: 16405）")
        print("3. 点击右侧的'详情'按钮")
        print("4. 复制'通信密钥'或'API密钥'")
        return

    # 构造测试订单参数
    import time
    params = {
        'pid': PID,
        'type': 'alipay',
        'out_trade_no': f'TEST_{int(time.time())}',
        'notify_url': 'https://robotcat.win/api/v1/payment/webhook/easypay',
        'return_url': 'https://robotcat.win/payment/result',
        'name': '测试订单',
        'money': '0.01',
    }

    # 生成签名
    sign = md5_sign(params, PKEY)
    params['sign'] = sign
    params['sign_type'] = 'MD5'

    print(f"\n生成的签名: {sign}")
    print("\n正在调用易支付 API...")

    try:
        # 调用 API
        response = requests.post(
            f"{API_BASE}/mapi.php",
            data=params,
            timeout=10
        )

        print(f"\nHTTP 状态码: {response.status_code}")
        print("\nAPI 响应:")
        print("-" * 50)

        try:
            result = response.json()
            print(json.dumps(result, indent=2, ensure_ascii=False))

            # 分析结果
            print("\n" + "=" * 50)
            print("测试结果")
            print("=" * 50)

            code = result.get('code')
            msg = result.get('msg', '')

            if code == 1:
                print("\n✅ 成功！易支付配置正确")
                print("\n返回的支付信息：")
                print(f"  - 交易号: {result.get('trade_no', 'N/A')}")
                print(f"  - 支付链接: {result.get('payurl', 'N/A')}")
                print(f"  - 二维码: {result.get('qrcode', 'N/A')}")
            else:
                print(f"\n❌ 失败！")
                print(f"\n错误代码: {code}")
                print(f"错误信息: {msg}")
                print("\n可能的原因：")

                if '签名' in msg or 'sign' in msg.lower():
                    print("  ❌ PKey（密钥）配置错误")
                    print("     → 请检查 PKey 是否正确")
                elif '商户' in msg or 'pid' in msg.lower():
                    print("  ❌ PID 配置错误")
                    print("     → 请确认 PID 是否为 16405")
                elif '余额' in msg or 'balance' in msg.lower():
                    print("  ❌ 账户余额不足")
                    print("     → 请充值易支付账户")
                elif '通道' in msg or 'channel' in msg.lower():
                    print("  ❌ 支付通道未开通或已关闭")
                    print("     → 请在易支付后台检查支付宝通道状态")
                else:
                    print(f"  ❌ {msg}")

                print("\n请检查：")
                print("  1. 登录易支付后台确认 PID 和 PKey")
                print("  2. 确认支付宝通道已开通且状态正常")
                print("  3. 确认账户余额充足")
                print("  4. 确认渠道开关已打开")

        except json.JSONDecodeError:
            print(response.text)
            print("\n❌ API 返回的不是有效的 JSON 格式")

    except requests.exceptions.RequestException as e:
        print(f"\n❌ 网络请求失败: {e}")
        print("\n可能的原因：")
        print("  1. API 地址不正确")
        print("  2. 网络连接问题")
        print("  3. 易支付服务器故障")

if __name__ == '__main__':
    test_easypay()
