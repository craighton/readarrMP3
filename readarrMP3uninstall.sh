#!/bin/bash

# Script by @ComputerByte
# Modified for Readarr by @Craighton
# For ReadarrMP3 Uninstalls

# Log to Swizzin.log
export log=/root/logs/swizzin.log
touch $log

systemctl disable --now -q readarrmp3
rm /etc/systemd/system/readarrmp3.service
systemctl daemon-reload -q

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/readarrmp3.conf
    systemctl reload nginx
fi

rm /install/.readarrmp3.lock

sed -e "s/class readarrmp3_meta://g" -i /opt/swizzin/core/custom/profiles.py
sed -e "s/    name = \"readarrmp3\"//g" -i /opt/swizzin/core/custom/profiles.py
sed -e "s/    pretty_name = \"Readarr MP3\"//g" -i /opt/swizzin/core/custom/profiles.py
sed -e "s/    baseurl = \"\/readarrmp3\"//g" -i /opt/swizzin/core/custom/profiles.py
sed -e "s/    systemd = \"readarrmp3\"//g" -i /opt/swizzin/core/custom/profiles.py
sed -e "s/    check_theD = True//g" -i /opt/swizzin/core/custom/profiles.py
sed -e "s/    img = \"readarr\"//g" -i /opt/swizzin/core/custom/profiles.py
sed -e "s/class readarr_meta(readarr_meta)://g" -i /opt/swizzin/core/custom/profiles.py
