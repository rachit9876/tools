### localhost fastest
```
busybox httpd -f -p 8000 -h ~/share
```
### Tunneling
```
export TUNNEL_DISABLE_QUIC=1
cloudflared tunnel --protocol http2 --url http://localhost:8000
```
