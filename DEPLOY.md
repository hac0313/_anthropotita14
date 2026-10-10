# SS14 Anthropotita 14 - Quick Deploy Checklist

## 1. Order VPS
- Provider: Timeweb Cloud / Selectel / AdminVPS (Moscow location)
- Specs: 2-4 GB RAM, 2 vCPU, Ubuntu 22.04/24.04
- Cost: ~200-500₽/mo

## 2. Run Deploy Script
```bash
# On VPS as root:
curl -fsSL https://raw.githubusercontent.com/hac0313/_anthropotita14/main/deploy.sh | bash
# OR copy deploy.sh to VPS and run:
chmod +x deploy.sh && ./deploy.sh
```

## 3. Configure Server URL
```bash
# Edit production.toml with your VPS public IP:
nano /home/ss14/_anthropotita14/publish/production.toml

# Find and uncomment/update:
# server_url = "ss14://YOUR_VPS_PUBLIC_IP:1212"

# Restart:
systemctl restart ss14
```

## 4. Verify
```bash
# Check status:
systemctl status ss14

# Watch logs:
journalctl -u ss14 -f

# Should see:
# [INFO] net: "0.0.0.0": "Socket bound to 0.0.0.0:1212: True"
# [INFO] hub: Server advertised to https://hub.spacestation14.com/
```

## 5. Optional: Domain + HTTPS (reverse proxy)
```bash
# Install nginx:
apt install nginx

# Configure /etc/nginx/sites-available/ss14:
# server {
#     listen 443 ssl;
#     server_name your-domain.com;
#     ssl_certificate /etc/letsencrypt/live/your-domain/fullchain.pem;
#     ssl_certificate_key /etc/letsencrypt/live/your-domain/privkey.pem;
#     
#     location / {
#         proxy_pass http://127.0.0.1:1212;
#         proxy_http_version 1.1;
#         proxy_set_header Upgrade $http_upgrade;
#         proxy_set_header Connection "upgrade";
#         proxy_set_header Host $host;
#     }
# }

# Get SSL cert:
apt install certbot python3-certbot-nginx
certbot --nginx -d your-domain.com

# Update production.toml:
# server_url = "ss14s://your-domain.com"
```

## 6. Updates
```bash
# Pull latest & rebuild:
cd /home/ss14/_anthropotita14
git pull
git submodule update --init --recursive
sudo -u ss14 dotnet publish Content.Server/Content.Server.csproj -c Release -o ./publish
systemctl restart ss14
```

## Files Created
- `deploy.sh` - Run on VPS for full auto-setup
- `.github/workflows/build.yml` - Auto-builds on push to main
- `production.toml` - Fixed (server_url commented, port corrected)