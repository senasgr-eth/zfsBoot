# Installation Guide

This guide covers different installation methods for NSBoot.

## Prerequisites

Before installing NSBoot, ensure you have:

- A server with Ubuntu 20.04+ or Debian 11+
- Root or sudo access
- At least 16GB RAM and 100GB storage
- Network connectivity

## Installation Methods

### Method 1: Docker (Recommended)

The easiest way to get started with NSBoot is using Docker.

#### Install Docker

```bash
# Update package index
sudo apt update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-plugin
```

#### Deploy NSBoot

```bash
# Clone the repository
git clone https://github.com/vkornilyev1988/NSBoot-.git
cd NSBoot-

# Start services
docker compose up -d

# Check status
docker compose ps
```

#### Access the Web Interface

Open your browser and navigate to:
```
http://<server-ip>
```

Default credentials (if authentication is enabled):
- Username: `admin`
- Password: `nsboot_admin`

### Method 2: Bare Metal Installation

For production deployments, you may want to install directly on the host.

#### Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
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

#### Clone and Configure

```bash
# Clone repository
cd /opt
sudo git clone https://github.com/vkornilyev1988/NSBoot-.git nsboot
cd nsboot

# Set permissions
sudo chown -R www-data:www-data /opt/nsboot
```

#### Create ZFS Pool

!!! warning "Important"
    Replace `/dev/sdX` with your actual disk device. This will **destroy all data** on the disk!

```bash
# Create ZFS pool
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
```

#### Configure Nginx

```bash
# Copy Nginx configuration
sudo cp nginx/nsboot.conf /etc/nginx/sites-available/nsboot
sudo ln -s /etc/nginx/sites-available/nsboot /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

#### Configure DHCP

```bash
# Backup original config
sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.backup

# Copy example configuration
sudo cp examples/etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf

# Edit configuration
sudo nano /etc/dhcp/dhcpd.conf
```

Update the following settings:
```conf
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.150 192.168.1.200;
    option routers 192.168.1.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
    next-server 192.168.1.100;  # Your NSBoot server IP
    filename "ipxe.efi";
}
```

```bash
# Restart DHCP server
sudo systemctl restart isc-dhcp-server
```

#### Configure TFTP

```bash
# Create TFTP directory
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
```

#### Start NSBoot Daemon

```bash
# Create systemd service
sudo cat > /etc/systemd/system/nsbootd.service <<EOF
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

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable nsbootd
sudo systemctl start nsbootd
```

### Method 3: Kubernetes

For large-scale deployments, use Kubernetes with Helm.

```bash
# Add NSBoot Helm repository
helm repo add nsboot https://nsboot.github.io/helm-charts
helm repo update

# Install NSBoot
helm install nsboot nsboot/nsboot \
    --namespace nsboot \
    --create-namespace \
    --set persistence.enabled=true \
    --set persistence.size=500Gi

# Check status
kubectl get pods -n nsboot
```

## Post-Installation

### Verify Installation

```bash
# Check services
sudo systemctl status nginx
sudo systemctl status isc-dhcp-server
sudo systemctl status tftpd-hpa
sudo systemctl status nsbootd

# Check ZFS pool
sudo zpool status
sudo zfs list

# Check iSCSI target
sudo tgtadm --lld iscsi --op show --mode target
```

### Access Web Interface

Navigate to `http://<server-ip>` in your browser. You should see the NSBoot dashboard.

### Configure Firewall

```bash
# Allow required ports
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 67/udp    # DHCP
sudo ufw allow 69/udp    # TFTP
sudo ufw allow 3260/tcp  # iSCSI
sudo ufw allow 9100/tcp  # Prometheus metrics

# Enable firewall
sudo ufw enable
```

## Next Steps

- [Quick Start Guide](quick-start.md) - Create your first boot image
- [Configuration](configuration.md) - Customize NSBoot settings
- [Managing Images](../user-guide/images.md) - Upload and manage OS images
- [Managing Clients](../user-guide/clients.md) - Add client workstations

## Troubleshooting

If you encounter issues during installation, see the [Troubleshooting Guide](../troubleshooting/common-issues.md).
