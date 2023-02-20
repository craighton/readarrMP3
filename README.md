# Readarr MP3 Installer
### For Swizzin installs
Second Readarr Installation on Swizzin based systems

> Source script by [ComputerByte](https://github.com/ComputerByte) and modified for second Readarr install


Uses existing install as a base. you must ``sudo box install readarr`` prior to running this script. 

Run install.sh as sudo
```bash
sudo su -
wget "https://raw.githubusercontent.com/craighton/readarrMP3/main/readarrMP3install.sh"
chmod +x ~/readarrMP3install.sh
~/readarrMP3install.sh
```
Sometimes Readarr won't start due to another Readarr existing, use the panel to stop Readarr and ReadarrMP3, enable Readarr and wait a second before starting ReadarrMP3 or

```bash
sudo systemctl stop readarr && sudo systemctl stop readarrmp3
sudo systemctl start readarr
sudo systemctl start readarrmp3
```

The log file should be located at ``/root/log/swizzin.log``.

# Uninstaller: 

```bash
sudo su -
wget "https://raw.githubusercontent.com/craighton/readarrMP3/main/readarrMP3uninstall.sh"
chmod +x ~/readarrMP3uninstall.sh
~/readarrMP3uninstall.sh
```

