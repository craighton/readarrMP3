#!/bin/bash
. /etc/swizzin/sources/globals.sh
. /etc/swizzin/sources/functions/utils

# Script by @ComputerByte
# Modified for Readarr by @Craighton
# For ReadarrMP3 Installs
#shellcheck=SC1017

# Log to Swizzin.log
export log=/root/logs/swizzin.log
touch $log
# Set variables
user=$(_get_master_username)

echo_progress_start "Making data directory and owning it to ${user}"
mkdir -p "/home/$user/.config/readarrmp3"
chown -R "$user":"$user" /home/$user/.config/readarrmp3
echo_progress_done "Data Directory created and owned."

echo_progress_start "Installing systemd service file"
cat >/etc/systemd/system/readarrmp3.service <<-SERV
[Unit]
Description=ReadarrMP3
After=syslog.target network.target

[Service]
# Change the user and group variables here.
User=${user}
Group=${user}

Type=simple

# Change the path to Readarr or mono here if it is in a different location for you.
ExecStart=/opt/Readarr/Readarr -nobrowser --data=/home/${user}/.config/readarrmp3
TimeoutStopSec=20
KillMode=process
Restart=on-failure

# These lines optionally isolate (sandbox) Readarr from the rest of the system.
# Make sure to add any paths it might use to the list below (space-separated).
#ReadWritePaths=/opt/Readarr /path/to/movies/folder
#ProtectSystem=strict
#PrivateDevices=true
#ProtectHome=true

[Install]
WantedBy=multi-user.target
SERV
echo_progress_done "ReadarrMP3 service installed"

# This checks if nginx is installed, if it is, then it will install nginx config for readarrMP3
if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Installing nginx config"
    cat >/etc/nginx/apps/readarrmp3.conf <<-NGX
location ^~ /readarrmp3 {
    proxy_pass http://127.0.0.1:9888/readarrmp3;
    proxy_set_header Host \$host;
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
location ^~ /readarrmp3/api {
    auth_basic off;
    proxy_pass http://127.0.0.1:9888;
}
NGX
    # Reload nginx
    systemctl reload nginx
    echo_progress_done "Nginx config applied"
fi

echo_progress_start "Generating configuration"

# Start readarr to config
systemctl stop readarr.service >>$log 2>&1


cat > /home/${user}/.config/readarrmp3/config.xml << EOSC
<Config>
  <LogLevel>info</LogLevel>
  <UpdateMechanism>BuiltIn</UpdateMechanism>
  <Branch>master</Branch>
  <BindAddress>127.0.0.1</BindAddress>
  <Port>9888</Port>
  <SslPort>6969</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>False</LaunchBrowser>
  <AuthenticationMethod>None</AuthenticationMethod>
  <UrlBase>readarrmp3</UrlBase>
  <UpdateAutomatically>False</UpdateAutomatically>
</Config>
EOSC

chown -R ${user}:${user} /home/${user}/.config/readarrmp3/config.xml
systemctl enable --now readarr.service >>$log 2>&1
sleep 10
systemctl enable --now readarrmp3.service >>$log 2>&1

echo_progress_start "Patching panel."
systemctl start readarrmp3.service >>$log 2>&1
#Install Swizzin Panel Profiles
if [[ -f /install/.panel.lock ]]; then
    cat <<EOF >>/opt/swizzin/core/custom/profiles.py
class readarrmp3_meta:
    name = "readarrmp3"
    pretty_name = "ReadarrMP3"
    baseurl = "/readarrmp3"
    systemd = "readarrmp3"
    check_theD = False
    img = "readarr"
class readarr_meta(readarr_meta):
    systemd = "readarr"
    check_theD = False
EOF
fi
touch /install/.readarrmp3.lock >>$log 2>&1
echo_progress_done "Panel patched."
systemctl restart panel >>$log 2>&1
echo_progress_done "Done."
