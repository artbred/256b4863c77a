## XTLS configs

[portal.json](portal.json) - install on ru server

[bridge.json](bridge.json) - install on external server

[client.json](portal.json) - use to connect to a ru server or use wireguard

```
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root

sudo curl -L -o /usr/local/share/xray/geoip.dat \
  "https://raw.githubusercontent.com/runetfreedom/russia-v2ray-rules-dat/release/geoip.dat"

sudo curl -L -o /usr/local/share/xray/geosite.dat \
  "https://raw.githubusercontent.com/runetfreedom/russia-v2ray-rules-dat/release/geosite.dat"
```




