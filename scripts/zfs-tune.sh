#!/bin/bash
# NSBoot ZFS Performance Tuning Script
# Optimizes ZFS for diskless boot workloads

set -e

echo "========================================="
echo "NSBoot ZFS Performance Tuning"
echo "========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Configuration
POOL_NAME="${POOL_NAME:-nsboot0}"
ARC_MAX="${ARC_MAX:-8589934592}"  # 8GB default
L2ARC_DEVICE="${L2ARC_DEVICE:-}"
ZIL_DEVICE="${ZIL_DEVICE:-}"

echo "Pool: $POOL_NAME"
echo "ARC Max: $(numfmt --to=iec $ARC_MAX)"

# Check if pool exists
if ! zpool list "$POOL_NAME" &>/dev/null; then
    echo "Error: ZFS pool '$POOL_NAME' not found"
    exit 1
fi

echo ""
echo "Step 1: Setting ARC cache limits..."
echo "$ARC_MAX" > /sys/module/zfs/parameters/zfs_arc_max
echo "ARC min: $(cat /sys/module/zfs/parameters/zfs_arc_min)"
echo "ARC max: $(cat /sys/module/zfs/parameters/zfs_arc_max)"

echo ""
echo "Step 2: Optimizing compression..."
zfs set compression=lz4 "$POOL_NAME/images"
echo "Compression: $(zfs get -H -o value compression $POOL_NAME/images)"

echo ""
echo "Step 3: Setting recordsize for better performance..."
# Larger recordsize for sequential reads (better for boot images)
zfs set recordsize=128k "$POOL_NAME/images/storages"
echo "Recordsize: $(zfs get -H -o value recordsize $POOL_NAME/images/storages)"

echo ""
echo "Step 4: Enabling prefetch..."
zfs set primarycache=all "$POOL_NAME/images"
zfs set secondarycache=all "$POOL_NAME/images"
echo "Primary cache: $(zfs get -H -o value primarycache $POOL_NAME/images)"
echo "Secondary cache: $(zfs get -H -o value secondarycache $POOL_NAME/images)"

echo ""
echo "Step 5: Optimizing for random reads..."
# Disable atime for better performance
zfs set atime=off "$POOL_NAME/images"
echo "Atime: $(zfs get -H -o value atime $POOL_NAME/images)"

# Add L2ARC cache device if specified
if [ -n "$L2ARC_DEVICE" ] && [ -b "$L2ARC_DEVICE" ]; then
    echo ""
    echo "Step 6: Adding L2ARC cache device..."
    if zpool add "$POOL_NAME" cache "$L2ARC_DEVICE"; then
        echo "L2ARC device added: $L2ARC_DEVICE"
    else
        echo "Warning: Failed to add L2ARC device"
    fi
else
    echo ""
    echo "Step 6: Skipping L2ARC (no device specified)"
    echo "Tip: Set L2ARC_DEVICE=/dev/sdX to add SSD cache"
fi

# Add ZIL device if specified
if [ -n "$ZIL_DEVICE" ] && [ -b "$ZIL_DEVICE" ]; then
    echo ""
    echo "Step 7: Adding ZIL (SLOG) device..."
    if zpool add "$POOL_NAME" log "$ZIL_DEVICE"; then
        echo "ZIL device added: $ZIL_DEVICE"
    else
        echo "Warning: Failed to add ZIL device"
    fi
else
    echo ""
    echo "Step 7: Skipping ZIL (no device specified)"
    echo "Tip: Set ZIL_DEVICE=/dev/sdX to add dedicated log device"
fi

echo ""
echo "Step 8: Setting kernel parameters..."
# Increase dirty data limit
echo "536870912" > /sys/module/zfs/parameters/zfs_dirty_data_max
# Optimize for many small files
echo "1" > /sys/module/zfs/parameters/zfs_prefetch_disable

echo ""
echo "Step 9: Creating tuning persistence..."
cat > /etc/modprobe.d/zfs.conf <<EOF
# NSBoot ZFS Tuning
options zfs zfs_arc_max=$ARC_MAX
options zfs zfs_arc_min=$((ARC_MAX / 2))
options zfs zfs_dirty_data_max=536870912
options zfs zfs_txg_timeout=5
EOF

echo ""
echo "========================================="
echo "ZFS Tuning Complete!"
echo "========================================="
echo ""
echo "Current pool status:"
zpool status "$POOL_NAME"

echo ""
echo "ARC statistics:"
arc_summary | head -20

echo ""
echo "Performance tips:"
echo "1. Monitor with: zpool iostat -v $POOL_NAME 1"
echo "2. Check ARC hit rate: arc_summary | grep 'Hit Rate'"
echo "3. Add more RAM for better ARC performance"
echo "4. Use SSD for L2ARC to extend cache"
echo "5. Use NVMe for ZIL to improve write performance"

echo ""
echo "Reboot recommended to apply all changes."
