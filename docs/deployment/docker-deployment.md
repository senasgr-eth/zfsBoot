# Docker Deployment Guide

This guide covers deploying NSBoot using Docker and Docker Compose.

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- 16GB RAM minimum
- 100GB disk space

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/vkornilyev1988/NSBoot-.git
cd NSBoot-
```

### 2. Build Docker Image

```bash
# Using build script
chmod +x scripts/build-docker.sh
./scripts/build-docker.sh

# Or manually
docker build -t nsboot:4.1.0 .
```

### 3. Start with Docker Compose

```bash
docker-compose up -d
```

### 4. Access Web Interface

Open your browser to:
```
http://localhost
```

## Docker Compose Configuration

The `docker-compose.yml` includes:

- **nsboot**: Main application server
- **prometheus**: Metrics collection
- **grafana**: Monitoring dashboards
- **keycloak**: Authentication (optional)

### Basic Setup

```yaml
version: '3.8'

services:
  nsboot:
    image: nsboot:4.1.0
    container_name: nsboot
    privileged: true
    network_mode: host
    volumes:
      - nsboot-data:/srv/images
      - nsboot-config:/srv/nsboot/cfg
    environment:
      - TZ=UTC
    restart: unless-stopped
```

### With Monitoring

```bash
# Start with monitoring
docker-compose up -d

# Access services
# Web UI:     http://localhost
# Grafana:    http://localhost:3000
# Prometheus: http://localhost:9090
```

## Environment Variables

Configure NSBoot with environment variables:

```bash
# Server configuration
NSBOOT_HOSTNAME=nsboot-server
NSBOOT_SERVER_IP=192.168.1.100

# DHCP configuration
NSBOOT_DHCP_ENABLED=true
NSBOOT_DHCP_RANGE_START=192.168.1.150
NSBOOT_DHCP_RANGE_END=192.168.1.200

# ZFS configuration
NSBOOT_ZFS_POOL=nsboot0
NSBOOT_ZFS_COMPRESSION=lz4

# Authentication
NSBOOT_AUTH_ENABLED=false
```

## Volume Management

### Data Volumes

```bash
# List volumes
docker volume ls | grep nsboot

# Backup volumes
docker run --rm -v nsboot-data:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/nsboot-data-backup.tar.gz /data

# Restore volumes
docker run --rm -v nsboot-data:/data -v $(pwd):/backup \
  ubuntu tar xzf /backup/nsboot-data-backup.tar.gz -C /
```

### Persistent Storage

For production, use bind mounts:

```yaml
services:
  nsboot:
    volumes:
      - /srv/nsboot/images:/srv/images
      - /srv/nsboot/config:/srv/nsboot/cfg
```

## Network Configuration

### Host Network Mode

For PXE/DHCP to work, use host network mode:

```yaml
services:
  nsboot:
    network_mode: host
```

### Bridge Network Mode

For isolated testing:

```yaml
services:
  nsboot:
    ports:
      - "80:80"
      - "443:443"
    networks:
      - nsboot-net

networks:
  nsboot-net:
    driver: bridge
```

## Security

### Run as Non-Root

```dockerfile
USER www-data
```

### Read-Only Root Filesystem

```yaml
services:
  nsboot:
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
```

### Resource Limits

```yaml
services:
  nsboot:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 16G
        reservations:
          cpus: '2'
          memory: 8G
```

## Health Checks

```yaml
services:
  nsboot:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

## Logging

### Configure Logging Driver

```yaml
services:
  nsboot:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### View Logs

```bash
# View all logs
docker-compose logs -f

# View specific service
docker-compose logs -f nsboot

# Last 100 lines
docker-compose logs --tail=100 nsboot
```

## Updating

### Update to New Version

```bash
# Pull new image
docker pull nsboot:4.1.1

# Update docker-compose.yml
# Change image: nsboot:4.1.1

# Restart services
docker-compose up -d
```

### Rolling Update

```bash
# Build new image
docker build -t nsboot:4.1.1 .

# Update with zero downtime
docker-compose up -d --no-deps --build nsboot
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs nsboot

# Check container status
docker-compose ps

# Inspect container
docker inspect nsboot
```

### Network Issues

```bash
# Check network
docker network ls
docker network inspect nsboot_default

# Test connectivity
docker exec nsboot ping -c 3 8.8.8.8
```

### Permission Issues

```bash
# Fix permissions
docker exec nsboot chown -R www-data:www-data /srv/images
```

### ZFS Not Available

```bash
# Install ZFS on host
sudo apt install zfsutils-linux

# Load ZFS module
sudo modprobe zfs

# Create pool
sudo zpool create -m /srv nsboot0 /dev/sdX
```

## Performance Tuning

### Optimize Docker

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1

# Use layer caching
docker build --cache-from nsboot:latest -t nsboot:4.1.0 .
```

### Optimize ZFS

```bash
# Run inside container
docker exec nsboot /opt/nsboot/scripts/zfs-tune.sh
```

## Production Checklist

- [ ] Use specific image tags (not `latest`)
- [ ] Configure resource limits
- [ ] Set up health checks
- [ ] Configure logging
- [ ] Use persistent volumes
- [ ] Enable monitoring
- [ ] Set up backups
- [ ] Configure SSL/TLS
- [ ] Enable authentication
- [ ] Set up firewall rules

## Docker Registry

### Push to Docker Hub

```bash
# Login
docker login

# Tag image
docker tag nsboot:4.1.0 username/nsboot:4.1.0

# Push
docker push username/nsboot:4.1.0
```

### Private Registry

```bash
# Tag for private registry
docker tag nsboot:4.1.0 registry.example.com/nsboot:4.1.0

# Push
docker push registry.example.com/nsboot:4.1.0
```

## Multi-Architecture Builds

```bash
# Create builder
docker buildx create --name nsboot-builder --use

# Build for multiple architectures
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t nsboot:4.1.0 \
  --push \
  .
```

## Next Steps

- [Kubernetes Deployment](kubernetes-deployment.md)
- [Bare Metal Deployment](bare-metal-deployment.md)
- [Performance Tuning](../admin/performance.md)
- [Security Hardening](../admin/security.md)
