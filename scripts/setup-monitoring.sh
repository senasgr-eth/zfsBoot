#!/bin/bash
# NSBoot Monitoring Setup Script
# Installs and configures Prometheus exporters

set -e

echo "========================================="
echo "NSBoot Monitoring Setup"
echo "========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

echo ""
echo "Installing monitoring components..."

# Install Prometheus Node Exporter
if ! command -v prometheus-node-exporter &> /dev/null; then
    echo "Installing Prometheus Node Exporter..."
    apt-get update
    apt-get install -y prometheus-node-exporter
    systemctl enable prometheus-node-exporter
    systemctl start prometheus-node-exporter
    echo "✓ Node Exporter installed"
else
    echo "✓ Node Exporter already installed"
fi

# Install ZFS Exporter
if ! command -v zfs_exporter &> /dev/null; then
    echo "Installing ZFS Exporter..."
    
    # Download and install
    ZFS_EXPORTER_VERSION="2.2.5"
    wget -q "https://github.com/pdf/zfs_exporter/releases/download/v${ZFS_EXPORTER_VERSION}/zfs_exporter-${ZFS_EXPORTER_VERSION}.linux-amd64.tar.gz"
    tar xzf "zfs_exporter-${ZFS_EXPORTER_VERSION}.linux-amd64.tar.gz"
    mv zfs_exporter /usr/local/bin/
    rm "zfs_exporter-${ZFS_EXPORTER_VERSION}.linux-amd64.tar.gz"
    
    # Create systemd service
    cat > /etc/systemd/system/zfs-exporter.service <<EOF
[Unit]
Description=ZFS Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/zfs_exporter
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable zfs-exporter
    systemctl start zfs-exporter
    echo "✓ ZFS Exporter installed"
else
    echo "✓ ZFS Exporter already installed"
fi

# Install Nginx Prometheus Exporter
if ! command -v nginx-prometheus-exporter &> /dev/null; then
    echo "Installing Nginx Prometheus Exporter..."
    
    NGINX_EXPORTER_VERSION="0.11.0"
    wget -q "https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v${NGINX_EXPORTER_VERSION}/nginx-prometheus-exporter_${NGINX_EXPORTER_VERSION}_linux_amd64.tar.gz"
    tar xzf "nginx-prometheus-exporter_${NGINX_EXPORTER_VERSION}_linux_amd64.tar.gz"
    mv nginx-prometheus-exporter /usr/local/bin/
    rm "nginx-prometheus-exporter_${NGINX_EXPORTER_VERSION}_linux_amd64.tar.gz"
    
    # Enable Nginx stub_status
    cat > /etc/nginx/conf.d/stub_status.conf <<EOF
server {
    listen 127.0.0.1:8080;
    location /stub_status {
        stub_status on;
        access_log off;
    }
}
EOF
    
    nginx -t && systemctl reload nginx
    
    # Create systemd service
    cat > /etc/systemd/system/nginx-exporter.service <<EOF
[Unit]
Description=Nginx Prometheus Exporter
After=network.target nginx.service

[Service]
Type=simple
ExecStart=/usr/local/bin/nginx-prometheus-exporter -nginx.scrape-uri=http://127.0.0.1:8080/stub_status
Restart=always
User=nobody

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable nginx-exporter
    systemctl start nginx-exporter
    echo "✓ Nginx Exporter installed"
else
    echo "✓ Nginx Exporter already installed"
fi

# Create custom NSBoot metrics exporter
echo "Creating NSBoot custom metrics exporter..."
cat > /usr/local/bin/nsboot-exporter.sh <<'EOF'
#!/bin/bash
# NSBoot Custom Metrics Exporter

PORT=9260

while true; do
    {
        echo "HTTP/1.1 200 OK"
        echo "Content-Type: text/plain"
        echo ""
        
        # iSCSI target metrics
        ACTIVE_TARGETS=$(tgtadm --lld iscsi --op show --mode target 2>/dev/null | grep -c "Target [0-9]:" || echo 0)
        echo "nsboot_iscsi_active_targets $ACTIVE_TARGETS"
        
        # Active connections
        ACTIVE_CONNS=$(tgtadm --lld iscsi --op show --mode target 2>/dev/null | grep -c "I_T nexus:" || echo 0)
        echo "nsboot_iscsi_active_connections $ACTIVE_CONNS"
        
        # NBD devices in use
        NBD_ACTIVE=$(lsof /dev/nbd* 2>/dev/null | grep -c qemu-nbd || echo 0)
        echo "nsboot_nbd_active_devices $NBD_ACTIVE"
        
        # Image count
        IMAGE_COUNT=$(find /srv/images/storages -type f \( -name "*.qcow2" -o -name "*.vhd" -o -name "*.vhdx" -o -name "*.vmdk" \) 2>/dev/null | wc -l)
        echo "nsboot_total_images $IMAGE_COUNT"
        
        # Snapshot count
        SNAPSHOT_COUNT=$(zfs list -t snapshot -H 2>/dev/null | wc -l)
        echo "nsboot_total_snapshots $SNAPSHOT_COUNT"
        
    } | nc -l -p $PORT -q 1
done
EOF

chmod +x /usr/local/bin/nsboot-exporter.sh

# Create systemd service for custom exporter
cat > /etc/systemd/system/nsboot-exporter.service <<EOF
[Unit]
Description=NSBoot Custom Metrics Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/nsboot-exporter.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nsboot-exporter
systemctl start nsboot-exporter
echo "✓ NSBoot Exporter installed"

echo ""
echo "========================================="
echo "Monitoring Setup Complete!"
echo "========================================="
echo ""
echo "Exporters running on:"
echo "  Node Exporter:   http://localhost:9100/metrics"
echo "  ZFS Exporter:    http://localhost:9134/metrics"
echo "  Nginx Exporter:  http://localhost:9113/metrics"
echo "  NSBoot Exporter: http://localhost:9260/metrics"
echo ""
echo "Add these to your Prometheus configuration:"
echo ""
cat <<'PROMETHEUS'
scrape_configs:
  - job_name: 'nsboot-node'
    static_configs:
      - targets: ['localhost:9100']
  
  - job_name: 'nsboot-zfs'
    static_configs:
      - targets: ['localhost:9134']
  
  - job_name: 'nsboot-nginx'
    static_configs:
      - targets: ['localhost:9113']
  
  - job_name: 'nsboot-custom'
    static_configs:
      - targets: ['localhost:9260']
PROMETHEUS

echo ""
echo "To view metrics:"
echo "  curl http://localhost:9100/metrics"
echo ""
echo "Start Prometheus and Grafana with:"
echo "  docker-compose --profile monitoring up -d"
