#!/bin/bash
# ==========================================
# feeds 配置：官方默认源 + kenzok8 全家桶 + helloworld + openwrt-cups + brlaser
# OpenWrt 25.12 专用
# 修正：移除与 25.12 不兼容的 immortalwrt 源
# ==========================================

echo "===== 配置 feeds 源 ====="

# 清除旧的 feeds.conf，从零开始
> feeds.conf

# 先写官方 feeds（保证基础源正确）
echo "src-git packages https://github.com/openwrt/packages.git;openwrt-25.12" >> feeds.conf
echo "src-git luci https://github.com/openwrt/luci.git;openwrt-25.12" >> feeds.conf

# 再添加第三方 feeds（已移除 immortalwrt）
echo "src-git kenzo https://github.com/kenzok8/openwrt-packages.git" >> feeds.conf
echo "src-git small https://github.com/kenzok8/small.git" >> feeds.conf
echo "src-git smpackage https://github.com/kenzok8/small-package" >> feeds.conf
echo "src-git helloworld https://github.com/fw876/helloworld" >> feeds.conf
echo "src-git cups https://github.com/op4packages/openwrt-cups.git" >> feeds.conf
echo "src-git brlaser https://github.com/pdewacht/brlaser.git" >> feeds.conf

echo "✅ feeds.conf 配置完成"
echo "已添加："
echo "  - 官方: packages, luci (分支 openwrt-25.12)"
echo "  - 第三方: kenzo, small, smpackage, helloworld, cups, brlaser"
echo "  - (已移除与 25.12 不兼容的 immortalwrt 源)"
cat feeds.conf
