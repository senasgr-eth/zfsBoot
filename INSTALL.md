# NSBoot Installation Guide

This guide provides step-by-step instructions for installing NSBoot.

## Quick Install (Recommended)

The fastest way to get started:

```bash
# Clone the repository
git clone https://github.com/vkornilyev1988/NSBoot-.git
cd NSBoot-

# Run quick start script
chmod +x scripts/quick-start.sh
./scripts/quick-start.sh
```

The script will guide you through:
1. Checking prerequisites
2. Installing Docker (if needed)
3. Choosing installation method
4. Setting up the environment

## Installation Methods

### Method 1: Docker (Easiest)

**Requirements:**
- Docker 20.10+
- Docker Compose 2.0+
- 16GB RAM
- 100GB disk space

**Steps:**

```bash
# Start all services
docker-compose up -d

# Verify services are running
docker-compose ps

# View logs
docker-compose logs -f nsboot

# Access web interface
open http://localhost
```

**With Monitoring:**

```bash
# Start with Prometheus and Grafana
docker-compose up -d

# Access services
# Web UI:     http://localhost
# Grafana:    http://localhost:3000 (admin/nsboot_admin)
# Prometheus: http://localhost:9090
```

**With Authentication:**

```bash
# Start with Keycloak
docker-compose --profile auth up -d

# Configure Keycloak at http://localhost:8080
```

### Method 2: Bare Metal (Advanced)

**Requirements:**
- Ubuntu 20.04+ or Debian 11+
- Root access
- ZFS-compatible storage

**Step 1: Install Dependencies**

```bash
sudo apt update
sudo apt install -y \
    zfsutils-linux \
    nginx-extras \
    lua5.3 \
    lua-json \
    lua-socket \
    lua-posix \
    luarocks \
    isc-dhcp-server \
    tftpd-hpa \
    tgt \
    etherwake \
    shellinabox \
    qemu-utils \
    git

# Install Lua dependencies
sudo luarocks install lua-resty-http
sudo luarocks install lua-resty-jwt
sudo luarocks install lua-cjson
sudo luarocks install luafilesystem
```

**Step 2: Clone Repository**

```bash
cd /opt
sudo git clone https://github.com/vkornilyev1988/NSBoot-.git nsboot
cd nsboot
sudo chown -R $USER:$USER .
```

**Step 3: Create ZFS Pool**

```bash
# List available disks
lsblk

# Create pool (REPLACE /dev/sdX with your disk!)
sudo zpool create -m /srv nsboot0 /dev/sdX

# Create datasets
sudo zfs create -o mountpoint=/srv/images nsboot0/images
sudo zfs create -o mountpoint=/srv/images/boot nsboot0/images/boot
sudo zfs create -o mountpoint=/srv/images/boot/snap nsboot0/images/boot/snap
sudo zfs create -o mountpoint=/srv/images/games nsboot0/images/games
sudo zfs create -o mountpoint=/srv/images/snap nsboot0/images/snap
sudo zfs create -o mountpoint=/srv/images/storages nsboot0/images/storages
sudo zfs create nsboot0/writeback

# Enable compression
sudo zfs set compression=lz4 nsboot0/images

# Set permissions
sudo chown -R www-data:www-data /srv/images

# Verify
zpool status
zfs list
```

**Step 4: Configure Nginx**

```bash
# Copy configuration
sudo cp nginx/nsboot.conf /etc/nginx/sites-available/nsboot
sudo ln -s /etc/nginx/sites-available/nsboot /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

**Step 5: Configure DHCP**

```bash
# Backup original config
sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.backup

# Copy example
sudo cp examples/etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf

# Edit for your network
sudo nano /etc/dhcp/dhcpd.conf
```

Update these settings:
```conf
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.150 192.168.1.200;
    option routers 192.168.1.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
    next-server 192.168.1.100;  # Your server IP
    filename "ipxe.efi";
}
```

```bash
# Restart DHCP
sudo systemctl restart isc-dhcp-server
sudo systemctl enable isc-dhcp-server
```

**Step 6: Configure TFTP**

```bash
# Create directory
sudo mkdir -p /srv/tftp

# Copy iPXE files
sudo cp -r src/ipxe/* /srv/tftp/

# Set permissions
sudo chown -R tftp:tftp /srv/tftp

# Configure TFTP
sudo nano /etc/default/tftpd-hpa
```

Set:
```
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/srv/tftp"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure"
```

```bash
# Restart TFTP
sudo systemctl restart tftpd-hpa
sudo systemctl enable tftpd-hpa
```

**Step 7: Start NSBoot Daemon**

```bash
# Create systemd service
sudo tee /etc/systemd/system/nsbootd.service > /dev/null <<EOF
[Unit]
Description=NSBoot Daemon
After=network.target zfs-mount.service

[Service]
Type=simple
ExecStart=/opt/nsboot/bin/server.lua
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Start and enable service
sudo systemctl start nsbootd
sudo systemctl enable nsbootd

# Check status
sudo systemctl status nsbootd
```

**Step 8: Configure Firewall**

```bash
# Allow required ports
sudo ufw allow 80/tcp     # HTTP
sudo ufw allow 443/tcp    # HTTPS
sudo ufw allow 67/udp     # DHCP
sudo ufw allow 69/udp     # TFTP
sudo ufw allow 3260/tcp   # iSCSI

# Enable firewall
sudo ufw enable
```

### Method 3: Kubernetes

**Requirements:**
- Kubernetes 1.24+
- Helm 3.0+
- Storage class with ZFS support

**Installation:**

```bash
# Add Helm repository
helm repo add nsboot https://nsboot.github.io/helm-charts
helm repo update

# Install NSBoot
helm install nsboot nsboot/nsboot \
    --namespace nsboot \
    --create-namespace \
    --set persistence.enabled=true \
    --set persistence.size=500Gi \
    --set service.type=LoadBalancer

# Check status
kubectl get pods -n nsboot
kubectl get svc -n nsboot

# Get service URL
kubectl get svc nsboot -n nsboot
```

## Post-Installation

### 1. Verify Installation

```bash
# Check services
sudo systemctl status nginx
sudo systemctl status isc-dhcp-server
sudo systemctl status tftpd-hpa
sudo systemctl status nsbootd

# Check ZFS
zpool status
zfs list

# Check iSCSI
sudo tgtadm --lld iscsi --op show --mode target

# Test web interface
curl http://localhost
```

### 2. Performance Tuning

```bash
# Run ZFS tuning script
sudo ./scripts/zfs-tune.sh

# Run benchmark
sudo ./scripts/benchmark.sh
```

### 3. Setup Monitoring

```bash
# Install exporters
sudo ./scripts/setup-monitoring.sh

# Start Prometheus and Grafana (Docker)
docker-compose up -d prometheus grafana
```

### 4. Build Frontend (if not using Docker)

```bash
cd frontend
npm install
npm run build

# Copy to Nginx
sudo cp -r dist/* /opt/nsboot/frontend/dist/
```

## Troubleshooting

### Services won't start

```bash
# Check logs
sudo journalctl -u nsbootd -f
sudo journalctl -u nginx -f
sudo journalctl -u isc-dhcp-server -f

# Check Nginx config
sudo nginx -t

# Check DHCP config
sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf
```

### ZFS pool not found

```bash
# Import pool
sudo zpool import nsboot0

# Set to auto-mount
sudo zpool set cachefile=/etc/zfs/zpool.cache nsboot0
```

### Client can't boot

```bash
# Check DHCP is running
sudo systemctl status isc-dhcp-server

# Check TFTP is accessible
tftp localhost -c get ipxe.efi

# Check iSCSI targets
sudo tgtadm --lld iscsi --op show --mode target

# Check network
sudo tcpdump -i eth0 port 67 or port 69
```

### Web UI not loading

```bash
# Check Nginx
sudo systemctl status nginx
sudo nginx -t

# Check logs
sudo tail -f /var/log/nginx/error.log

# Check permissions
ls -la /opt/nsboot/frontend/dist/
```

## Upgrading

### Docker

```bash
# Pull latest image
docker-compose pull

# Restart services
docker-compose up -d
```

### Bare Metal

```bash
cd /opt/nsboot
git pull
sudo systemctl restart nsbootd
sudo systemctl restart nginx
```

## Uninstallation

### Docker

```bash
# Stop and remove containers
docker-compose down -v

# Remove images
docker rmi nsboot:latest
```

### Bare Metal

```bash
# Stop services
sudo systemctl stop nsbootd nginx isc-dhcp-server tftpd-hpa

# Disable services
sudo systemctl disable nsbootd nginx isc-dhcp-server tftpd-hpa

# Remove files
sudo rm -rf /opt/nsboot
sudo rm /etc/nginx/sites-enabled/nsboot
sudo rm /etc/systemd/system/nsbootd.service

# Optionally destroy ZFS pool
sudo zpool destroy nsboot0
```

## Next Steps

- [Quick Start Guide](docs/getting-started/quick-start.md)
- [Configuration Guide](docs/getting-started/configuration.md)
- [User Guide](docs/user-guide/)

## Support

- **Documentation**: https://nsboot.github.io
- **Issues**: https://github.com/vkornilyev1988/NSBoot-/issues
- **Discussions**: https://github.com/vkornilyev1988/NSBoot-/discussions
