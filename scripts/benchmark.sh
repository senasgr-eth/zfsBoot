#!/bin/bash
# NSBoot Performance Benchmark Script
# Tests ZFS I/O performance and network throughput

set -e

echo "========================================="
echo "NSBoot Performance Benchmark"
echo "========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Configuration
POOL_NAME="${POOL_NAME:-nsboot0}"
TEST_DIR="/srv/images/storages"
TEST_FILE="$TEST_DIR/benchmark_test.dat"
TEST_SIZE="${TEST_SIZE:-1G}"

# Install fio if not present
if ! command -v fio &> /dev/null; then
    echo "Installing fio..."
    apt-get update && apt-get install -y fio
fi

echo ""
echo "Test Configuration:"
echo "  Pool: $POOL_NAME"
echo "  Test Directory: $TEST_DIR"
echo "  Test Size: $TEST_SIZE"
echo ""

# Test 1: Sequential Read/Write
echo "========================================="
echo "Test 1: Sequential Read/Write"
echo "========================================="
fio --name=seq-rw \
    --directory=$TEST_DIR \
    --size=$TEST_SIZE \
    --rw=rw \
    --bs=1M \
    --direct=1 \
    --numjobs=1 \
    --time_based \
    --runtime=30 \
    --group_reporting

echo ""

# Test 2: Random Read/Write (simulates boot workload)
echo "========================================="
echo "Test 2: Random Read/Write (Boot Simulation)"
echo "========================================="
fio --name=rand-rw \
    --directory=$TEST_DIR \
    --size=$TEST_SIZE \
    --rw=randrw \
    --bs=4k \
    --direct=1 \
    --numjobs=4 \
    --time_based \
    --runtime=30 \
    --group_reporting

echo ""

# Test 3: Random Read (simulates multiple clients booting)
echo "========================================="
echo "Test 3: Multi-Client Boot Simulation"
echo "========================================="
fio --name=multi-client \
    --directory=$TEST_DIR \
    --size=$TEST_SIZE \
    --rw=randread \
    --bs=128k \
    --direct=1 \
    --numjobs=10 \
    --time_based \
    --runtime=30 \
    --group_reporting

echo ""

# Test 4: ZFS-specific tests
echo "========================================="
echo "Test 4: ZFS Pool I/O Statistics"
echo "========================================="
echo "Collecting 10 seconds of I/O data..."
zpool iostat -v "$POOL_NAME" 1 10

echo ""

# Test 5: ARC Statistics
echo "========================================="
echo "Test 5: ARC Cache Performance"
echo "========================================="
arc_summary | grep -A 20 "ARC Size"

echo ""

# Test 6: Network throughput (if iperf3 available)
if command -v iperf3 &> /dev/null; then
    echo "========================================="
    echo "Test 6: Network Throughput"
    echo "========================================="
    echo "Run on client: iperf3 -c <server-ip>"
    echo "Starting iperf3 server for 30 seconds..."
    timeout 30 iperf3 -s || true
else
    echo "========================================="
    echo "Test 6: Network Throughput (Skipped)"
    echo "========================================="
    echo "Install iperf3 to test network performance"
    echo "  apt-get install iperf3"
fi

echo ""

# Cleanup
echo "Cleaning up test files..."
rm -f $TEST_DIR/benchmark_test.dat.*

echo ""
echo "========================================="
echo "Benchmark Complete!"
echo "========================================="
echo ""
echo "Performance Targets for 100 Clients:"
echo "  Sequential Read: >1000 MB/s"
echo "  Random Read IOPS: >10,000"
echo "  ARC Hit Rate: >80%"
echo "  Network: 1 Gbps minimum (10 Gbps recommended)"
echo ""
echo "If performance is below targets:"
echo "1. Run: ./scripts/zfs-tune.sh"
echo "2. Add more RAM for ARC"
echo "3. Add SSD for L2ARC cache"
echo "4. Upgrade to 10GbE network"
echo "5. Use NVMe storage for pool"
