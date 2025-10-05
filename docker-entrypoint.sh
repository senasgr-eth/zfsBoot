#!/bin/bash
set -e

echo "========================================="
echo "NSBoot v4.1.0 - Starting..."
echo "========================================="

# Initialize ZFS if not already initialized
if ! zpool list nsboot0 &>/dev/null; then
    echo "Warning: ZFS pool 'nsboot0' not found."
    echo "Please create ZFS pool manually or mount host ZFS."
    echo "Example: zpool create -m /srv nsboot0 <disk>"
fi

# Create necessary directories
mkdir -p /srv/images/boot/snap
mkdir -p /srv/images/games
mkdir -p /srv/images/snap
mkdir -p /srv/images/storages
mkdir -p /srv/tftp
mkdir -p /var/log/nsboot
mkdir -p /run/nsboot

# Set permissions
chown -R www-data:www-data /srv/images
chown -R www-data:www-data /var/log/nsboot

# Initialize configuration if not exists
if [ ! -f /srv/nsboot/cfg/nsboot.json ]; then
    echo "Creating default configuration..."
    cat > /srv/nsboot/cfg/nsboot.json <<EOF
{
    "version": "4.1.0",
    "server": {
        "hostname": "nsboot-server",
        "ip": "192.168.1.100",
        "gateway": "192.168.1.1",
        "dns": ["8.8.8.8", "8.8.4.4"]
    },
    "zfs": {
        "pool": "nsboot0",
        "compression": "lz4",
        "arc_max": "8G"
    },
    "dhcp": {
        "enabled": true,
        "range_start": "192.168.1.150",
        "range_end": "192.168.1.200"
    },
    "iscsi": {
        "enabled": true,
        "port": 3260
    },
    "web": {
        "port": 80,
        "ssl_port": 443,
        "auth_enabled": false
    },
    "monitoring": {
        "prometheus_enabled": true,
        "prometheus_port": 9100
    }
}
EOF
fi

# Start Prometheus Node Exporter if enabled
if [ "${NSBOOT_MONITORING:-true}" = "true" ]; then
    echo "Starting Prometheus Node Exporter..."
    /usr/bin/prometheus-node-exporter &
fi

# Start NSBoot daemon
if [ -f /opt/nsboot/bin/server.lua ]; then
    echo "Starting NSBoot daemon..."
    /opt/nsboot/bin/server.lua &
fi

# Configure and test OpenResty
echo "Configuring OpenResty..."
/usr/local/openresty/bin/openresty -t

# Start iSCSI target daemon
echo "Starting iSCSI target daemon..."
/usr/sbin/tgtd &
sleep 2

# Log startup completion
echo "========================================="
echo "NSBoot started successfully!"
echo "Web UI: http://localhost"
echo "Prometheus: http://localhost:9100/metrics"
echo "========================================="

# Execute the main command (OpenResty)
exec /usr/local/openresty/bin/openresty -g "daemon off;"
