# NSBoot Deployment Guide

Quick deployment guide for NSBoot v4.1.0

## 🚀 Quick Deploy (Docker)

### 1. Prerequisites

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh

# Install Docker Compose
sudo apt install docker-compose-plugin
```

### 2. Clone & Build

```bash
git clone https://github.com/vkornilyev1988/NSBoot-.git
cd NSBoot-

# Build Docker image
./scripts/build-docker.sh
```

### 3. Start Services

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f nsboot
```

### 4. Access

- **Web UI**: http://localhost
- **Grafana**: http://localhost:3000 (admin/nsboot_admin)
- **Prometheus**: http://localhost:9090

## 📦 What's Included

The Docker image includes:

- ✅ Vue.js 3 frontend (built and optimized)
- ✅ OpenResty/Lua REST API
- ✅ ZFS storage backend
- ✅ iSCSI target server
- ✅ DHCP server
- ✅ TFTP server
- ✅ Prometheus metrics
- ✅ All helper scripts

## 🔧 Configuration

### Environment Variables

```bash
# In docker-compose.yml or .env file
NSBOOT_HOSTNAME=nsboot-server
NSBOOT_SERVER_IP=192.168.1.100
NSBOOT_DHCP_ENABLED=true
NSBOOT_DHCP_RANGE_START=192.168.1.150
NSBOOT_DHCP_RANGE_END=192.168.1.200
```

### Volumes

```yaml
volumes:
  - nsboot-data:/srv/images        # OS images and storage
  - nsboot-config:/srv/nsboot/cfg  # Configuration files
```

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│         Docker Container            │
│  ┌──────────────────────────────┐  │
│  │   Nginx + OpenResty          │  │
│  │   ┌──────────┐  ┌─────────┐ │  │
│  │   │ Vue.js   │  │ Lua API │ │  │
│  │   │ Frontend │◄─┤ Backend │ │  │
│  │   └──────────┘  └─────────┘ │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │   ZFS Storage                │  │
│  │   ┌──────────────────────┐   │  │
│  │   │ OS Images & Snapshots│   │  │
│  │   └──────────────────────┘   │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │   Network Services           │  │
│  │   DHCP │ TFTP │ iSCSI       │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
         │
         ▼
   ┌──────────┐
   │ Clients  │
   └──────────┘
```

## 📊 Image Details

- **Base**: Ubuntu 22.04
- **Size**: ~450MB (optimized)
- **Frontend**: Pre-built Vue.js 3
- **Backend**: Lua 5.3 + OpenResty
- **Multi-stage**: Yes (Node.js builder + Ubuntu runtime)

## 🔍 Verification

### Check Services

```bash
# Inside container
docker exec nsboot systemctl status nginx
docker exec nsboot systemctl status isc-dhcp-server

# Check frontend
curl http://localhost

# Check API
curl http://localhost/api/health
```

### Test Build

```bash
# Test Docker build
docker build -t nsboot:test .

# Run test container
docker run --rm -p 8080:80 nsboot:test

# Access at http://localhost:8080
```

## 🐛 Troubleshooting

### Build Fails

```bash
# Clean build cache
docker builder prune

# Rebuild without cache
docker build --no-cache -t nsboot:4.1.0 .
```

### Frontend Not Loading

```bash
# Check if frontend files exist
docker exec nsboot ls -la /opt/nsboot/frontend/dist

# Check nginx config
docker exec nsboot nginx -t

# Check nginx logs
docker exec nsboot tail -f /var/log/nginx/error.log
```

### API Not Working

```bash
# Check Lua modules
docker exec nsboot lua5.3 -e "print(require('cjson'))"

# Check API files
docker exec nsboot ls -la /opt/nsboot/api

# Test API directly
docker exec nsboot curl http://localhost/api/health
```

## 📚 Documentation

- **Full Docs**: [docs/](docs/)
- **Docker Deployment**: [docs/deployment/docker-deployment.md](docs/deployment/docker-deployment.md)
- **API Reference**: [docs/api/](docs/api/)
- **Troubleshooting**: [docs/troubleshooting/](docs/troubleshooting/)

## 🚀 Production Deployment

For production:

1. **Use specific tags**: `nsboot:4.1.0` (not `latest`)
2. **Configure SSL/TLS**: Add certificates
3. **Enable authentication**: Set `NSBOOT_AUTH_ENABLED=true`
4. **Set up monitoring**: Configure alerts
5. **Configure backups**: Regular volume backups
6. **Resource limits**: Set CPU/memory limits
7. **Health checks**: Configure proper health checks

See [Production Checklist](docs/deployment/docker-deployment.md#production-checklist)

## 🆘 Support

- **Issues**: https://github.com/vkornilyev1988/NSBoot-/issues
- **Discussions**: https://github.com/vkornilyev1988/NSBoot-/discussions
- **Documentation**: https://nsboot.github.io

---

**NSBoot v4.1.0** - Modern Diskless Boot System  
Made with ❤️ by the NSBoot community
