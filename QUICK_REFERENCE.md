# NSBoot Quick Reference

Quick commands and references for NSBoot development and administration.

## 🚀 Quick Commands

### Docker

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f nsboot

# Restart a service
docker-compose restart nsboot

# Rebuild image
docker-compose build --no-cache

# Clean everything
docker-compose down -v
docker system prune -a
```

### Makefile

```bash
make help              # Show all available commands
make build             # Build Docker image
make run               # Start services
make stop              # Stop services
make logs              # Show logs
make clean             # Clean up
make dev-frontend      # Start frontend dev server
make test              # Run tests
make lint              # Run linters
make docs              # Build documentation
make docs-serve        # Serve docs locally
make benchmark         # Run benchmarks
make tune-zfs          # Tune ZFS performance
```

### Frontend Development

```bash
cd frontend

npm install            # Install dependencies
npm run dev            # Start dev server
npm run build          # Build for production
npm run preview        # Preview production build
npm run test:unit      # Run unit tests
npm run test:e2e       # Run E2E tests
npm run lint           # Lint code
npm run format         # Format code
npm run type-check     # TypeScript type checking
```

### ZFS Management

```bash
# Pool status
zpool status nsboot0
zpool list nsboot0
zpool iostat -v nsboot0 1

# Dataset management
zfs list
zfs get all nsboot0/images
zfs set compression=lz4 nsboot0/images

# Snapshots
zfs snapshot nsboot0/images/storages/win10@backup
zfs list -t snapshot
zfs rollback nsboot0/images/storages/win10@backup
zfs destroy nsboot0/images/storages/win10@backup

# Performance
arc_summary
arc_summary | grep "Hit Rate"
```

### Service Management

```bash
# Systemd services
sudo systemctl status nsbootd
sudo systemctl start nsbootd
sudo systemctl stop nsbootd
sudo systemctl restart nsbootd
sudo systemctl enable nsbootd

# View logs
sudo journalctl -u nsbootd -f
sudo journalctl -u nginx -f
sudo journalctl -u isc-dhcp-server -f

# Nginx
sudo nginx -t                    # Test config
sudo systemctl reload nginx      # Reload config
sudo tail -f /var/log/nginx/error.log
```

### iSCSI Management

```bash
# Show targets
sudo tgtadm --lld iscsi --op show --mode target

# Create target
sudo tgtadm --lld iscsi --op new --mode target --tid 1 -T iqn.2025-01.com.nsboot:target1

# Add LUN
sudo tgtadm --lld iscsi --op new --mode logicalunit --tid 1 --lun 1 -b /dev/nbd0

# Delete target
sudo tgtadm --lld iscsi --op delete --mode target --tid 1

# Show connections
sudo tgtadm --lld iscsi --op show --mode conn --tid 1
```

### Network Debugging

```bash
# Monitor DHCP
sudo tcpdump -i eth0 port 67 or port 68

# Monitor TFTP
sudo tcpdump -i eth0 port 69

# Monitor iSCSI
sudo tcpdump -i eth0 port 3260

# Check listening ports
sudo netstat -tulpn | grep -E '(80|67|69|3260)'
sudo ss -tulpn | grep -E '(80|67|69|3260)'
```

## 📁 Important Paths

### Docker Installation
```
/var/lib/docker/volumes/       # Docker volumes
```

### Bare Metal Installation
```
/opt/nsboot/                   # Application directory
/srv/images/                   # ZFS mount point
/srv/images/storages/          # OS images
/srv/tftp/                     # TFTP boot files
/etc/nginx/sites-available/    # Nginx configs
/etc/dhcp/dhcpd.conf          # DHCP config
/var/log/nginx/               # Nginx logs
/var/log/nsboot/              # NSBoot logs
```

## 🔧 Configuration Files

### Main Configuration
```
/srv/nsboot/cfg/nsboot.json    # Main config
```

### Network Configuration
```
/etc/dhcp/dhcpd.conf          # DHCP server
/etc/default/tftpd-hpa        # TFTP server
/etc/netplan/                 # Network config (Ubuntu)
```

### Web Server
```
/etc/nginx/sites-available/nsboot  # Nginx config
/opt/nsboot/frontend/dist/         # Frontend files
```

## 🌐 API Endpoints

### System
```
GET  /api/system/info          # System information
GET  /api/health               # Health check
GET  /api/metrics              # Prometheus metrics
```

### Images
```
GET  /api/images               # List images
POST /api/images/upload        # Upload image
GET  /api/images/:id           # Get image details
DELETE /api/images/:id         # Delete image
POST /api/images/:id/snapshot  # Create snapshot
```

### Clients
```
GET  /api/clients              # List clients
POST /api/clients              # Add client
GET  /api/clients/:id          # Get client details
PUT  /api/clients/:id          # Update client
DELETE /api/clients/:id        # Delete client
POST /api/clients/:mac/wake    # Wake on LAN
```

### Snapshots
```
GET  /api/snapshots            # List snapshots
POST /api/snapshots            # Create snapshot
DELETE /api/snapshots/:id      # Delete snapshot
POST /api/snapshots/:id/rollback  # Rollback to snapshot
```

## 🔍 Troubleshooting Commands

### Check Service Status
```bash
# All services
docker-compose ps                           # Docker
sudo systemctl status nsbootd nginx isc-dhcp-server  # Bare metal

# Individual checks
curl http://localhost                       # Web UI
curl http://localhost/api/health           # API health
curl http://localhost:9100/metrics         # Metrics
```

### Debug Boot Issues
```bash
# Check DHCP leases
cat /var/lib/dhcp/dhcpd.leases

# Check TFTP access
tftp localhost -c get ipxe.efi

# Check iSCSI targets
sudo tgtadm --lld iscsi --op show --mode target

# Monitor network traffic
sudo tcpdump -i eth0 -n port 67 or port 69 or port 3260
```

### Performance Checks
```bash
# ZFS performance
zpool iostat -v nsboot0 1
arc_summary | grep "Hit Rate"

# Network performance
iperf3 -s                      # On server
iperf3 -c <server-ip>          # On client

# Disk I/O
sudo iotop
sudo iostat -x 1
```

### Log Analysis
```bash
# Recent errors
sudo journalctl -p err -n 50

# Service-specific logs
sudo journalctl -u nsbootd --since "1 hour ago"
sudo journalctl -u nginx --since "1 hour ago"

# Follow logs
sudo tail -f /var/log/syslog
sudo tail -f /var/log/nginx/error.log
```

## 📊 Monitoring URLs

```
Web UI:        http://localhost
Grafana:       http://localhost:3000 (admin/nsboot_admin)
Prometheus:    http://localhost:9090
Metrics:       http://localhost:9100/metrics
ZFS Metrics:   http://localhost:9134/metrics
Nginx Metrics: http://localhost:9113/metrics
```

## 🔐 Default Credentials

```
Grafana:   admin / nsboot_admin
Keycloak:  admin / admin (if using auth profile)
```

## 🎯 Common Tasks

### Add New Image
```bash
# Copy to storage
sudo cp /path/to/image.qcow2 /srv/images/storages/

# Set permissions
sudo chown www-data:www-data /srv/images/storages/image.qcow2

# Or upload via UI
# Navigate to Images → Upload Image
```

### Create Snapshot
```bash
# Via ZFS
sudo zfs snapshot nsboot0/images/storages/win10@$(date +%Y%m%d)

# Via API
curl -X POST http://localhost/api/images/win10/snapshot \
  -H "Content-Type: application/json" \
  -d '{"name": "backup-20251005"}'
```

### Wake Client
```bash
# Via command line
sudo etherwake 00:11:22:33:44:55

# Via API
curl -X POST http://localhost/api/clients/00:11:22:33:44:55/wake
```

### Backup Configuration
```bash
# Create backup
tar czf nsboot-backup-$(date +%Y%m%d).tar.gz \
  /srv/nsboot/cfg/ \
  /etc/nginx/sites-available/nsboot \
  /etc/dhcp/dhcpd.conf

# Restore backup
tar xzf nsboot-backup-20251005.tar.gz -C /
```

## 🚨 Emergency Commands

### Stop All Clients
```bash
# Remove all iSCSI targets
for tid in $(sudo tgtadm --lld iscsi --op show --mode target | grep "Target" | awk '{print $2}' | tr -d ':'); do
  sudo tgtadm --lld iscsi --op delete --force --mode target --tid $tid
done
```

### Reset ZFS Pool
```bash
# Export pool
sudo zpool export nsboot0

# Re-import pool
sudo zpool import nsboot0

# Or import with different name
sudo zpool import nsboot0 nsboot0-new
```

### Restart Everything
```bash
# Docker
docker-compose restart

# Bare metal
sudo systemctl restart nsbootd nginx isc-dhcp-server tftpd-hpa tgt
```

## 📖 Quick Links

- [Full Documentation](docs/)
- [Installation Guide](INSTALL.md)
- [Getting Started](GETTING_STARTED.md)
- [Contributing](CONTRIBUTING.md)
- [Roadmap](ROADMAP.md)
- [Changelog](CHANGELOG.md)

---

**Tip**: Bookmark this page for quick reference during development and troubleshooting!
