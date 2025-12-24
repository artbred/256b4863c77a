## XTLS configurations examples

[portal.json](reverse/portal.json) - install on ru server
[bridge.json](reverse/bridge.json) - install on external server
[client.json](reverse/portal.json) - use to connect to a ru server or use wireguard

[nginx.conf](xhttp+cdn/nginx.conf) - install on freedom server
[client.json](xhttp+cdn/xrayrouter.json) - xtls config for client
[server.json](xhttp+cdn/xrayrouter.json) - xtls config for server


```
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root

sudo curl -L -o /usr/local/share/xray/geoip.dat \
  "https://raw.githubusercontent.com/runetfreedom/russia-v2ray-rules-dat/release/geoip.dat"

sudo curl -L -o /usr/local/share/xray/geosite.dat \
  "https://raw.githubusercontent.com/runetfreedom/russia-v2ray-rules-dat/release/geosite.dat"
```
