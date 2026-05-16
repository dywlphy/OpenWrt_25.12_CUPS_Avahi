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
echo "[1/4] 设置默认主机名..."
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/files/bin/config_generate 2>/dev/null || true
sed -i 's/OpenWrt/OpenWrt-25.12/g' package/base-files/files/bin/config_generate 2>/dev/null || true

# 2. 设置默认时区为上海
echo "[2/4] 设置默认时区..."
sed -i "s/'UTC'/'CST-8'/g" package/base-files/files/bin/config_generate
sed -i "/'CST-8'/a \\\t\tset system.@system[-1].zonename='Asia/Shanghai'" package/base-files/files/bin/config_generate

# 3. 设置默认主题为Material
echo "[3/4] 设置默认主题为Material..."
sed -i 's/luci-theme-bootstrap/luci-theme-material/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true
sed -i 's/luci-theme-bootstrap/luci-theme-material/g' package/feeds/luci/luci/Makefile 2>/dev/null || true

# 4. 添加自定义banner + 创建 cups-zh-cn 汉化包
echo "[4/4] 添加banner和CUPS汉化包..."

# 自定义banner
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

# 创建 cups-zh-cn 自定义包（刷机后自动替换CUPS英文模板为中文）
mkdir -p package/cups-zh-cn/files/usr/share/cups/zh_CN
mkdir -p package/cups-zh-cn/files/usr/share/cups/doc-root

if [ -f "$GITHUB_WORKSPACE/CUPS_2.3.1_zh_CN.zip" ]; then
    unzip -o $GITHUB_WORKSPACE/CUPS_2.3.1_zh_CN.zip -d /tmp/cups-zh
    cp -r /tmp/cups-zh/zh_CN/* package/cups-zh-cn/files/usr/share/cups/zh_CN/ 2>/dev/null || true
    cp /tmp/cups-zh/index.html package/cups-zh-cn/files/usr/share/cups/doc-root/ 2>/dev/null || true
    rm -rf /tmp/cups-zh
    echo "  - CUPS中文模板已准备"
else
    echo "  - 警告: 未找到CUPS_2.3.1_zh_CN.zip，跳过汉化"
fi

# cups-zh-cn Makefile
cat > package/cups-zh-cn/Makefile << 'MAKEEOF'
include $(TOPDIR)/rules.mk

PKG_NAME:=cups-zh-cn
PKG_VERSION:=2.3.1
PKG_RELEASE:=1

PKG_MAINTAINER:=OpenWrt Builder
PKG_LICENSE:=GPL-2.0-only

include $(INCLUDE_DIR)/package.mk

define Package/cups-zh-cn
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=CUPS Chinese (Simplified) Templates
  DEPENDS:=+cups
  PKGARCH:=all
endef

define Package/cups-zh-cn/description
  Simplified Chinese language templates for CUPS web interface.
  Replaces default English templates after installation.
endef

define Build/Compile
endef

define Package/cups-zh-cn/install
	$(INSTALL_DIR) $(1)/usr/share/cups/zh_CN
	$(CP) ./files/usr/share/cups/zh_CN/* $(1)/usr/share/cups/zh_CN/
	$(INSTALL_DIR) $(1)/usr/share/cups/doc-root
	$(INSTALL_BIN) ./files/usr/share/cups/doc-root/index.html $(1)/usr/share/cups/doc-root/
endef

define Package/cups-zh-cn/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	# 1. 替换CUPS中文模板
	[ -d /usr/share/cups/zh_CN ] && {
		cp -rf /usr/share/cups/zh_CN/* /usr/share/cups/templates/
		rm -rf /usr/share/cups/zh_CN
	}
	# 2. 配置cupsd.conf（局域网访问 + Avahi发现）
	cat > /etc/cups/cupsd.conf << 'CONF'
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
CONF
	# 3. 配置Avahi服务（打印机发现）
	mkdir -p /etc/avahi/services
	cat > /etc/avahi/services/cups.service << 'AVAHI'
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
AVAHI
	# 4. 重启服务
	[ -x /etc/init.d/avahi-daemon ] && /etc/init.d/avahi-daemon restart 2>/dev/null
	[ -x /etc/init.d/cupsd ] && /etc/init.d/cupsd restart 2>/dev/null
}
exit 0
endef

define Package/cups-zh-cn/postrm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	[ -x /etc/init.d/cupsd ] && /etc/init.d/cupsd restart 2>/dev/null
}
exit 0
endef

$(eval $(call BuildPackage,cups-zh-cn))
MAKEEOF

echo "  - cups-zh-cn 包已创建"

echo "=========================================="
echo "构建信息:"
echo "  - OpenWrt版本: 25.12 (Dave's Guitar)"
echo "  - 内核: 6.12"
echo "  - 包管理器: apk (替代opkg)"
echo "  - 目标平台: x86_64"
echo "  - 打印: CUPS + Avahi + 中文(cups-zh-cn)"
echo "  - VPN: WireGuard + pbr"
echo "  - 网络: Tailscale/ACME/frp"
echo "  - 控制: timecontrol"
echo "=========================================="
