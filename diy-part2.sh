#!/bin/bash
#
# diy-part2.sh - 更新feeds后的自定义配置
# OpenWrt 25.12 版本
#

echo "=========================================="
echo "OpenWrt 25.12 Build"
echo "diy-part2.sh - 自定义配置"
echo "=========================================="

# 1. 设置默认主机名
echo "[1/6] 设置默认主机名..."
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/files/bin/config_generate 2>/dev/null || true
sed -i 's/OpenWrt/OpenWrt-25.12/g' package/base-files/files/bin/config_generate 2>/dev/null || true

# 2. 设置默认时区为上海
echo "[2/6] 设置默认时区..."
sed -i "s/'UTC'/'CST-8'/g" package/base-files/files/bin/config_generate
sed -i "/'CST-8'/a \\\t\tset system.@system[-1].zonename='Asia/Shanghai'" package/base-files/files/bin/config_generate

# 3. 设置默认主题为Material
echo "[3/6] 设置默认主题为Material..."
sed -i 's/luci-theme-bootstrap/luci-theme-material/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true
sed -i 's/luci-theme-bootstrap/luci-theme-material/g' package/feeds/luci/luci/Makefile 2>/dev/null || true

# 4. 添加自定义banner
echo "[4/6] 添加自定义banner..."
cat > package/base-files/files/etc/banner << 'EOF'
  _______                     ________        __
 |       |.-----.-----.-----.|  |  |  |.----.|  |_
 |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|
 |_______||   __|_____|__|__||________||__|  |____|
          |__| W I R E L E S S   F R E E D O M
 -----------------------------------------------------
 OpenWrt 25.12 "Dave's Guitar"
 -----------------------------------------------------
EOF

# 5. CUPS 汉化集成
echo "[5/6] 集成CUPS中文汉化..."
mkdir -p package/base-files/files/usr/share/cups/templates
mkdir -p package/base-files/files/usr/share/cups/doc-root

if [ -f "$GITHUB_WORKSPACE/CUPS_2.3.1_zh_CN.zip" ]; then
    unzip -o $GITHUB_WORKSPACE/CUPS_2.3.1_zh_CN.zip -d /tmp/cups-zh
    cp -r /tmp/cups-zh/zh_CN/* package/base-files/files/usr/share/cups/templates/
    cp /tmp/cups-zh/index.html package/base-files/files/usr/share/cups/doc-root/ 2>/dev/null || true
    chmod -R 755 package/base-files/files/usr/share/cups/templates
    chmod -R 755 package/base-files/files/usr/share/cups/doc-root
    rm -rf /tmp/cups-zh
    echo "CUPS汉化文件已集成"
else
    echo "警告: 未找到CUPS_2.3.1_zh_CN.zip，跳过"
fi

# 6. GRUB等待时间 + CUPS默认配置
echo "[6/6] 配置GRUB和CUPS默认设置..."

# GRUB等待时间2秒
sed -i 's/set timeout=.*/set timeout=2/' package/base-files/files/boot/grub/grub.cfg 2>/dev/null || echo "set timeout=2" > package/base-files/files/boot/grub/grub.cfg

# CUPS配置（启用Avahi发现）
mkdir -p package/base-files/files/etc/cups
cat > package/base-files/files/etc/cups/cupsd.conf << 'EOF'
# CUPS 配置文件 - OpenWrt 25.12
Listen *:631
Listen /var/run/cups/cups.sock
LogLevel warn
AccessLog /var/log/cups/access_log
ErrorLog /var/log/cups/error_log
DefaultPolicy default

<Location />
  Order allow,deny
  Allow @LOCAL
</Location>

<Location /admin>
  Order allow,deny
  Allow @LOCAL
</Location>

<Location /admin/conf>
  AuthType Default
  Require user @SYSTEM
  Order allow,deny
  Allow @LOCAL
</Location>

<Location /printers>
  Order allow,deny
  Allow @LOCAL
</Location>

Browsing On
BrowseLocalProtocols dnssd
EOF

# Avahi服务文件（CUPS打印机发现）
mkdir -p package/base-files/files/etc/avahi/services
cat > package/base-files/files/etc/avahi/services/cups.service << 'EOF'
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">CUPS 打印服务器 @ %h</name>
  <service>
    <type>_ipp._tcp</type>
    <port>631</port>
    <txt-record>txtvers=1</txt-record>
    <txt-record>qtotal=1</txt-record>
    <txt-record>rp=printers/</txt-record>
  </service>
</service-group>
EOF

echo "=========================================="
echo "构建信息:"
echo "  - OpenWrt版本: 25.12 (Dave's Guitar)"
echo "  - 内核: 6.12"
echo "  - 包管理器: apk (替代opkg)"
echo "  - 目标平台: x86_64"
echo "  - 打印: CUPS + Avahi + 中文界面"
echo "  - VPN: WireGuard + pbr"
echo "  - 网络: Tailscale/ACME/frp"
echo "=========================================="
