#!/bin/bash
# SS14 Anthropotita 14 - VPS Deployment Script
# Run on fresh Ubuntu 22.04/24.04 VPS as root or sudo user

set -e

echo "=== SS14 Anthropotita 14 Deployment ==="

# 1. Install .NET 9 SDK
echo "Installing .NET 9 SDK..."
wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt update && apt install -y dotnet-sdk-9.0 git tmux ufw

# 2. Create service user
echo "Creating ss14 user..."
id -u ss14 &>/dev/null || useradd -m -s /bin/bash ss14

# 3. Clone repository
echo "Cloning repository..."
sudo -u ss14 bash << 'EOF'
cd /home/ss14
git clone https://github.com/hac0313/_anthropotita14.git
cd _anthropotita14
git submodule update --init --recursive
EOF

# 4. Build release
echo "Building release..."
sudo -u ss14 bash << 'EOF'
cd /home/ss14/_anthropotita14
dotnet publish Content.Server/Content.Server.csproj -c Release -o ./publish
EOF

# 5. Copy config
echo "Copying production config..."
sudo -u ss14 cp /home/ss14/_anthropotita14/Resources/ConfigPresets/Civ/production.toml /home/ss14/_anthropotita14/publish/production.toml

# 6. Configure firewall
echo "Configuring firewall..."
ufw allow 22/tcp    # SSH
ufw allow 1212/tcp  # SS14 game
ufw allow 1212/udp  # SS14 game
ufw --force enable

# 7. Create systemd service
echo "Creating systemd service..."
cat > /etc/systemd/system/ss14.service << 'SVC'
[Unit]
Description=SS14 Anthropotita 14
After=network.target

[Service]
Type=simple
User=ss14
WorkingDirectory=/home/ss14/_anthropotita14/publish
ExecStart=/usr/bin/dotnet Content.Server.dll --config-file production.toml
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ss14

[Install]
WantedBy=multi-user.target
SVC

# 8. Enable and start
systemctl daemon-reload
systemctl enable --now ss14

echo ""
echo "=== Deployment Complete ==="
echo "Server status: systemctl status ss14"
echo "Logs: journalctl -u ss14 -f"
echo ""
echo "IMPORTANT: Edit /home/ss14/_anthropotita14/publish/production.toml"
echo "  - Set server_url = \"ss14://YOUR_VPS_PUBLIC_IP:1212\""
echo "  - Restart: systemctl restart ss14"