FROM node:20-alpine AS frontend-builder

# Build frontend
WORKDIR /build
COPY frontend/package*.json ./
RUN npm ci --only=production

COPY frontend/ ./
RUN npm run build

# Main image
FROM ubuntu:22.04

LABEL maintainer="NSBoot Modernization Team"
LABEL description="NSBoot - Modern Diskless Boot System"
LABEL version="4.1.0"

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Core dependencies
    zfsutils-linux \
    nginx-extras \
    lua5.3 \
    lua-json \
    lua-socket \
    lua-posix \
    luarocks \
    # Network boot components
    isc-dhcp-server \
    tftpd-hpa \
    tgt \
    # Utilities
    etherwake \
    shellinabox \
    qemu-utils \
    # Build tools
    git \
    curl \
    wget \
    # Monitoring
    prometheus-node-exporter \
    # Additional Lua libraries
    liblua5.3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install LuaRocks packages for modern API
RUN luarocks install lua-resty-http && \
    luarocks install lua-resty-jwt && \
    luarocks install lua-resty-session && \
    luarocks install lua-cjson && \
    luarocks install luafilesystem

# Create application directories
RUN mkdir -p /opt/nsboot \
    /opt/nsboot/frontend/dist \
    /srv/images \
    /srv/images/boot \
    /srv/images/boot/snap \
    /srv/images/games \
    /srv/images/snap \
    /srv/images/storages \
    /srv/tftp \
    /srv/nsboot/cfg \
    /var/log/nsboot \
    /run/nsboot

# Copy application files
COPY bin/ /opt/nsboot/bin/
COPY src/ /opt/nsboot/src/
COPY api/ /opt/nsboot/api/
COPY srv/ /srv/nsboot/
COPY scripts/ /opt/nsboot/scripts/

# Copy frontend build from builder stage
COPY --from=frontend-builder /build/dist /opt/nsboot/frontend/dist

# Copy nginx configuration
COPY nginx/frontend.conf /etc/nginx/sites-available/nsboot
RUN ln -sf /etc/nginx/sites-available/nsboot /etc/nginx/sites-enabled/default

# Copy DHCP example
COPY examples/etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.example

# Set permissions
RUN chown -R www-data:www-data /srv/images && \
    chown -R www-data:www-data /var/log/nsboot && \
    chown -R www-data:www-data /opt/nsboot/frontend && \
    chmod +x /opt/nsboot/bin/*.lua && \
    chmod +x /opt/nsboot/scripts/*.sh

# Create nginx symlink
RUN ln -sf /etc/nginx/sites-available/nsboot /etc/nginx/sites-enabled/nsboot && \
    rm -f /etc/nginx/sites-enabled/default

# Expose ports
# 80: HTTP Web UI
# 443: HTTPS Web UI
# 67/udp: DHCP
# 69/udp: TFTP
# 3260: iSCSI
# 9100: Prometheus node exporter
EXPOSE 80 443 67/udp 69/udp 3260 9100

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Volume for persistent data
VOLUME ["/srv/images", "/srv/tftp", "/var/log/nsboot"]

# Entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
