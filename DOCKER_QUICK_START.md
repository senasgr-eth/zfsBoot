# Docker Quick Start Guide

## Prerequisites
- Docker installed
- Docker Compose installed
- User in docker group (to avoid sudo)

## Add User to Docker Group (One-time)
```bash
sudo usermod -aG docker $USER
newgrp docker
# Or logout and login again
```

## Build & Run

### Option 1: Without sudo (Recommended)
```bash
# Make sure you're in the project directory
cd /home/sena/Documents/project/zfsBoot

# Build image
docker build -t nsboot:4.1.0 .

# Run with docker-compose
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f nsboot
```

### Option 2: With sudo (If needed)
```bash
# Build
sudo docker build -t nsboot:4.1.0 .

# Run
sudo docker-compose up -d

# Check
sudo docker-compose ps
```

## Access Application
- **Web UI**: http://localhost
- **API**: http://localhost/api
- **Grafana**: http://localhost:3000
- **Prometheus**: http://localhost:9090

## Default Credentials
- **Username**: admin
- **Password**: admin

⚠️ **Change in production!**

## Common Commands

### View Logs
```bash
docker-compose logs -f nsboot
```

### Restart Service
```bash
docker-compose restart nsboot
```

### Stop Service
```bash
docker-compose down
```

### Rebuild
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Clean Everything
```bash
docker-compose down -v
docker system prune -a
```

## Troubleshooting

### Permission Denied on docker-compose.yml
**Problem**: `permission denied` error

**Solution 1**: Add user to docker group
```bash
sudo usermod -aG docker $USER
newgrp docker
```

**Solution 2**: Use sudo
```bash
sudo docker-compose up -d
```

**Solution 3**: Fix file permissions
```bash
chmod 644 docker-compose.yml
```

### Port Already in Use
**Problem**: Port 80 already in use

**Solution**: Stop conflicting service or change port
```bash
# Check what's using port 80
sudo lsof -i :80

# Stop nginx if running
sudo systemctl stop nginx

# Or change port in docker-compose.yml
ports:
  - "8080:80"  # Use port 8080 instead
```

### Build Fails
**Problem**: Docker build fails

**Solution**: Clear cache and rebuild
```bash
docker build --no-cache -t nsboot:4.1.0 .
```

### Container Exits Immediately
**Problem**: Container starts then exits

**Solution**: Check logs
```bash
docker-compose logs nsboot
```

Common causes:
- Port conflict
- Missing volumes
- Configuration error

## Volume Management

### List Volumes
```bash
docker volume ls
```

### Inspect Volume
```bash
docker volume inspect nsboot_nsboot-data
```

### Backup Volume
```bash
docker run --rm -v nsboot_nsboot-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/nsboot-backup.tar.gz /data
```

### Restore Volume
```bash
docker run --rm -v nsboot_nsboot-data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/nsboot-backup.tar.gz -C /
```

## Health Check

### Check Container Health
```bash
docker-compose ps
docker inspect nsboot | grep -A 10 Health
```

### Test API
```bash
curl http://localhost/api/health
curl http://localhost/api/system/info
```

### Test Frontend
```bash
curl -I http://localhost
```

## Performance Monitoring

### Resource Usage
```bash
docker stats nsboot
```

### Container Logs
```bash
docker-compose logs --tail=100 -f nsboot
```

## Production Deployment

### Use Production Compose File
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### Set Environment Variables
```bash
export JWT_SECRET="your-secret-key"
export ZFS_POOL="nsboot0"
docker-compose up -d
```

### Enable HTTPS
```bash
# Add SSL certificates
mkdir -p ssl
# Copy your certificates
cp /path/to/cert.pem ssl/
cp /path/to/key.pem ssl/

# Update docker-compose.yml
volumes:
  - ./ssl:/etc/ssl/nsboot:ro
```

## Next Steps

1. ✅ Build image: `docker build -t nsboot:4.1.0 .`
2. ✅ Start services: `docker-compose up -d`
3. ✅ Access UI: http://localhost
4. ✅ Login with admin/admin
5. ✅ Change default password
6. ✅ Configure ZFS pool
7. ✅ Upload first image
8. ✅ Boot first client

## Support

- **Documentation**: See `docs/` directory
- **Issues**: https://github.com/senasgr-eth/zfsBoot/issues
- **Logs**: `docker-compose logs -f`

---

**Quick Command Summary**:
```bash
# Build
docker build -t nsboot:4.1.0 .

# Run
docker-compose up -d

# Access
open http://localhost

# Logs
docker-compose logs -f

# Stop
docker-compose down
```
