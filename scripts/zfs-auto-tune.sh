#!/bin/bash
# NSBoot Automated ZFS Tuning
# Analyzes workload and automatically tunes ZFS parameters

set -e

echo "========================================="
echo "NSBoot Automated ZFS Tuning"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# Configuration
ZFS_POOL="${ZFS_POOL:-nsboot0}"
WORKLOAD_TYPE="${WORKLOAD_TYPE:-auto}"  # auto, read-heavy, write-heavy, balanced

echo "Analyzing system and workload..."
echo ""

# Get system information
TOTAL_RAM=$(free -b | awk '/^Mem:/{print $2}')
TOTAL_RAM_GB=$((TOTAL_RAM / 1024 / 1024 / 1024))
CPU_CORES=$(nproc)

print_success "System: ${TOTAL_RAM_GB}GB RAM, ${CPU_CORES} CPU cores"

# Check if pool exists
if ! zpool list "$ZFS_POOL" &>/dev/null; then
    print_error "ZFS pool '$ZFS_POOL' not found"
    exit 1
fi

print_success "ZFS pool '$ZFS_POOL' found"

# Analyze workload if auto
if [ "$WORKLOAD_TYPE" = "auto" ]; then
    echo ""
    echo "Analyzing workload pattern..."
    
    # Get I/O stats
    IOSTAT=$(zpool iostat -v "$ZFS_POOL" 1 2 | tail -1)
    READ_OPS=$(echo "$IOSTAT" | awk '{print $5}')
    WRITE_OPS=$(echo "$IOSTAT" | awk '{print $6}')
    
    # Determine workload type
    if (( $(echo "$READ_OPS > $WRITE_OPS * 2" | bc -l) )); then
        WORKLOAD_TYPE="read-heavy"
    elif (( $(echo "$WRITE_OPS > $READ_OPS * 2" | bc -l) )); then
        WORKLOAD_TYPE="write-heavy"
    else
        WORKLOAD_TYPE="balanced"
    fi
    
    print_success "Detected workload: $WORKLOAD_TYPE"
fi

echo ""
echo "Applying optimizations for $WORKLOAD_TYPE workload..."
echo ""

# 1. ARC Size (50-75% of RAM)
ARC_MAX=$((TOTAL_RAM * 60 / 100))
echo "$ARC_MAX" > /sys/module/zfs/parameters/zfs_arc_max
print_success "ARC max set to $(($ARC_MAX / 1024 / 1024 / 1024))GB (60% of RAM)"

# 2. ARC Min (25% of max)
ARC_MIN=$((ARC_MAX * 25 / 100))
echo "$ARC_MIN" > /sys/module/zfs/parameters/zfs_arc_min
print_success "ARC min set to $(($ARC_MIN / 1024 / 1024 / 1024))GB"

# 3. Prefetch
if [ "$WORKLOAD_TYPE" = "read-heavy" ]; then
    echo "1" > /sys/module/zfs/parameters/zfs_prefetch_disable
    print_success "Prefetch enabled for read-heavy workload"
else
    echo "0" > /sys/module/zfs/parameters/zfs_prefetch_disable
    print_success "Prefetch disabled for write-heavy workload"
fi

# 4. Compression
if [ "$WORKLOAD_TYPE" = "write-heavy" ]; then
    zfs set compression=lz4 "$ZFS_POOL/images"
    print_success "Compression set to LZ4 (fast)"
else
    zfs set compression=zstd "$ZFS_POOL/images"
    print_success "Compression set to ZSTD (better ratio)"
fi

# 5. Record size based on workload
if [ "$WORKLOAD_TYPE" = "read-heavy" ]; then
    zfs set recordsize=1M "$ZFS_POOL/images"
    print_success "Record size set to 1M (large sequential reads)"
elif [ "$WORKLOAD_TYPE" = "write-heavy" ]; then
    zfs set recordsize=128K "$ZFS_POOL/images"
    print_success "Record size set to 128K (better for writes)"
else
    zfs set recordsize=256K "$ZFS_POOL/images"
    print_success "Record size set to 256K (balanced)"
fi

# 6. Sync mode
if [ "$WORKLOAD_TYPE" = "write-heavy" ]; then
    zfs set sync=disabled "$ZFS_POOL/images"
    print_warning "Sync disabled for performance (use with caution!)"
else
    zfs set sync=standard "$ZFS_POOL/images"
    print_success "Sync set to standard"
fi

# 7. ATime
zfs set atime=off "$ZFS_POOL/images"
print_success "ATime disabled (reduces writes)"

# 8. Primary cache
if [ "$WORKLOAD_TYPE" = "read-heavy" ]; then
    zfs set primarycache=all "$ZFS_POOL/images"
    print_success "Primary cache set to ALL"
else
    zfs set primarycache=metadata "$ZFS_POOL/images"
    print_success "Primary cache set to metadata only"
fi

# 9. Secondary cache (if L2ARC exists)
if zpool status "$ZFS_POOL" | grep -q "cache"; then
    zfs set secondarycache=all "$ZFS_POOL/images"
    print_success "Secondary cache (L2ARC) enabled"
else
    print_warning "No L2ARC device found (consider adding SSD cache)"
fi

# 10. Deduplication (only if enough RAM)
if [ "$TOTAL_RAM_GB" -gt 64 ]; then
    zfs set dedup=on "$ZFS_POOL/images"
    print_success "Deduplication enabled (sufficient RAM)"
else
    zfs set dedup=off "$ZFS_POOL/images"
    print_warning "Deduplication disabled (insufficient RAM)"
fi

# 11. Tune kernel parameters
cat > /etc/sysctl.d/99-zfs-tuning.conf <<EOF
# ZFS Auto-tuning - Generated $(date)
# Workload type: $WORKLOAD_TYPE

# ARC tuning
vm.swappiness=10
vm.vfs_cache_pressure=50

# Network tuning
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864

# Disk I/O
vm.dirty_ratio=40
vm.dirty_background_ratio=10
EOF

sysctl -p /etc/sysctl.d/99-zfs-tuning.conf >/dev/null 2>&1
print_success "Kernel parameters tuned"

# 12. Create performance report
echo ""
echo "========================================="
echo "Performance Report"
echo "========================================="
echo ""

# Current ARC stats
ARC_SIZE=$(cat /proc/spl/kstat/zfs/arcstats | grep "^size" | awk '{print $3}')
ARC_SIZE_GB=$((ARC_SIZE / 1024 / 1024 / 1024))
echo "ARC Size: ${ARC_SIZE_GB}GB"

# Hit rate
ARC_HITS=$(cat /proc/spl/kstat/zfs/arcstats | grep "^hits" | awk '{print $3}')
ARC_MISSES=$(cat /proc/spl/kstat/zfs/arcstats | grep "^misses" | awk '{print $3}')
if [ "$ARC_HITS" -gt 0 ] && [ "$ARC_MISSES" -gt 0 ]; then
    HIT_RATE=$(echo "scale=2; $ARC_HITS * 100 / ($ARC_HITS + $ARC_MISSES)" | bc)
    echo "ARC Hit Rate: ${HIT_RATE}%"
fi

# Pool stats
echo ""
zpool list "$ZFS_POOL"
echo ""
zpool iostat -v "$ZFS_POOL"

echo ""
echo "========================================="
echo "Tuning Complete!"
echo "========================================="
echo ""
echo "Configuration saved to: /etc/sysctl.d/99-zfs-tuning.conf"
echo ""
echo "Recommendations:"
if [ "$TOTAL_RAM_GB" -lt 32 ]; then
    print_warning "Consider upgrading to 32GB+ RAM for better performance"
fi

if ! zpool status "$ZFS_POOL" | grep -q "cache"; then
    print_warning "Add SSD as L2ARC cache: zpool add $ZFS_POOL cache /dev/sdX"
fi

if ! zpool status "$ZFS_POOL" | grep -q "log"; then
    print_warning "Add NVMe as ZIL: zpool add $ZFS_POOL log /dev/nvmeXn1"
fi

echo ""
echo "Run './scripts/benchmark.sh' to test performance"
echo ""
