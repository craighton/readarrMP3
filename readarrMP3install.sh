#!/bin/bash
. /etc/swizzin/sources/globals.sh
. /etc/swizzin/sources/functions/utils

# Script by @ComputerByte
# Modified for Readarr by @Craighton
# For readarrMP3 Installs
#shellcheck=SC1017

# Log to Swizzin.log
export log=/root/logs/swizzin.log
touch $log
# Set variables
user=$(_get_master_username)

echo_progress_start "Making data directory and owning it to ${user}"
mkdir -p "/home/$user/.config/readarrMP3"
chown -R "$user":"$user" /home/$user/.config/readarrMP3
echo_progress_done "Data Directory created and owned."

echo_progress_start "Installing systemd service file"
cat >/etc/systemd/system/readarrMP3.service <<-SERV
# This file is owned by the readarr package, DO NOT MODIFY MANUALLY
# Instead use 'dpkg-reconfigure -plow readarr' to modify User/Group/UMask/-data
# Or use systemd built-in override functionality using 'systemctl edit readarr'
[Unit]
Description=readarr Daemon
After=network.target

[Service]
User=${user}
Group=${user}
UMask=0002

Type=simple
ExecStart=/usr/bin/mono --debug /opt/readarr/readarr.exe -nobrowser -data=/home/${user}/.config/readarrMP3
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERV
echo_progress_done "readarrMP3 service installed"

# This checks if nginx is installed, if it is, then it will install nginx config for readarrMP3
if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Installing nginx config"
    cat >/etc/nginx/apps/readarrMP3.conf <<-NGX
location ^~ /readarrMP3 {
    proxy_pass http://127.0.0.1:9992;
    proxy_set_header Host \$proxy_host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_redirect off;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$http_connection;
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};
}
# Allow the API External Access via NGINX
location ^~ /readarrMP3/api {
    auth_basic off;
    proxy_pass http://127.0.0.1:9992;
}
NGX
    # Reload nginx
    systemctl reload nginx
    echo_progress_done "Nginx config applied"
fi

echo_progress_start "Generating configuration"

# Start readarr to config
systemctl stop readarr.service >>$log 2>&1

cat > /home/${user}/.config/readarrMP3/config.xml << EOSC
<Config>
  <LogLevel>info</LogLevel>
  <UpdateMechanism>BuiltIn</UpdateMechanism>
  <Branch>main</Branch>
  <BindAddress>127.0.0.1</BindAddress>
  <Port>9992</Port>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>False</LaunchBrowser>
  <AuthenticationMethod>None</AuthenticationMethod>
  <UrlBase>readarrMP3</UrlBase>
  <UpdateAutomatically>False</UpdateAutomatically>
</Config>
EOSC

chown -R ${user}:${user} \/home/${user}/.config/readarrMP3/
systemctl enable --now readarr.service >>$log 2>&1
sleep 10
systemctl enable --now readarrMP3.service >>$log 2>&1

echo_progress_start "Patching panel."
systemctl start readarrMP3.service >>$log 2>&1
#Install Swizzin Panel Profiles
if [[ -f /install/.panel.lock ]]; then
    cat <<EOF >>/opt/swizzin/core/custom/profiles.py
class readarrMP3_meta:
    name = "readarrMP3"
    pretty_name = "readarrMP3"
    baseurl = "/readarrMP3"
    systemd = "readarrMP3"
    check_theD = False
    img = "readarr"
class readarr_meta(readarr_meta):
    systemd = "readarr"
    check_theD = False
EOF
fi
touch /install/.readarrMP3.lock >>$log 2>&1
echo_progress_done "Panel patched."
systemctl restart panel >>$log 2>&1
echo_progress_done "Done."
