# Boot Issues Troubleshooting

Common boot problems and solutions.

## Client Won't Boot

### Symptom
Client doesn't receive IP or boot from network.

### Diagnosis
```bash
# Check DHCP server
sudo systemctl status isc-dhcp-server
sudo journalctl -u isc-dhcp-server -n 50

# Check DHCP leases
cat /var/lib/dhcp/dhcpd.leases

# Monitor DHCP traffic
sudo tcpdump -i eth0 port 67 or port 68
```

### Solutions

**1. DHCP Not Running**
```bash
sudo systemctl start isc-dhcp-server
sudo systemctl enable isc-dhcp-server
```

**2. Wrong Network Interface**
```bash
# Edit /etc/default/isc-dhcp-server
INTERFACES="eth0"  # Change to your interface
sudo systemctl restart isc-dhcp-server
```

**3. Firewall Blocking**
```bash
sudo ufw allow 67/udp
sudo ufw allow 68/udp
sudo ufw allow 69/udp
sudo ufw allow 3260/tcp
```

## TFTP Download Fails

### Symptom
Client gets IP but fails to download boot files.

### Diagnosis
```bash
# Check TFTP server
sudo systemctl status tftpd-hpa

# Test TFTP locally
tftp localhost -c get ipxe.efi

# Monitor TFTP traffic
sudo tcpdump -i eth0 port 69
```

### Solutions

**1. TFTP Not Running**
```bash
sudo systemctl start tftpd-hpa
sudo systemctl enable tftpd-hpa
```

**2. Missing Boot Files**
```bash
# Check files exist
ls -la /srv/tftp/

# Download iPXE if missing
cd /srv/tftp
wget http://boot.ipxe.org/ipxe.efi
wget http://boot.ipxe.org/undionly.kpxe
```

**3. Permission Issues**
```bash
sudo chown -R tftp:tftp /srv/tftp
sudo chmod -R 755 /srv/tftp
```

## iSCSI Connection Fails

### Symptom
Client downloads boot files but can't connect to iSCSI.

### Diagnosis
```bash
# Check iSCSI targets
sudo tgtadm --lld iscsi --op show --mode target

# Check connections
sudo tgtadm --lld iscsi --op show --mode conn --tid 1

# Monitor iSCSI traffic
sudo tcpdump -i eth0 port 3260
```

### Solutions

**1. No iSCSI Target**
```bash
# Create target
sudo tgtadm --lld iscsi --op new --mode target --tid 1 \
  -T iqn.2025-01.com.nsboot:target1

# Add LUN
sudo tgtadm --lld iscsi --op new --mode logicalunit --tid 1 --lun 1 \
  -b /dev/zvol/nsboot0/images/storages/win10

# Allow all initiators
sudo tgtadm --lld iscsi --op bind --mode target --tid 1 -I ALL
```

**2. Target Service Not Running**
```bash
sudo systemctl start tgt
sudo systemctl enable tgt
```

**3. ZFS Volume Not Available**
```bash
# Check ZFS volumes
zfs list -t volume

# Create volume if missing
zfs create -V 50G nsboot0/images/storages/win10
```

## Slow Boot Performance

### Symptom
Boot takes longer than expected.

### Diagnosis
```bash
# Check ZFS performance
zpool iostat -v nsboot0 1

# Check ARC hit rate
arc_summary | grep "Hit Rate"

# Check network speed
iperf3 -s  # On server
iperf3 -c <server-ip>  # On client
```

### Solutions

**1. Tune ZFS**
```bash
sudo /opt/nsboot/scripts/zfs-tune.sh
```

**2. Add L2ARC Cache**
```bash
# Add SSD as L2ARC
sudo zpool add nsboot0 cache /dev/sdc
```

**3. Increase ARC Size**
```bash
# Set ARC max to 8GB
echo 8589934592 | sudo tee /sys/module/zfs/parameters/zfs_arc_max
```

**4. Use 10GbE Network**
- Upgrade to 10 Gigabit Ethernet
- Use quality network switches
- Check cable quality

## Image Corruption

### Symptom
OS boots but crashes or has errors.

### Diagnosis
```bash
# Check ZFS integrity
zpool scrub nsboot0
zpool status -v nsboot0

# Check for errors
zpool status | grep errors
```

### Solutions

**1. Restore from Snapshot**
```bash
# List snapshots
zfs list -t snapshot

# Rollback to snapshot
zfs rollback nsboot0/images/storages/win10@clean
```

**2. Verify Image Integrity**
```bash
# Check image file
qemu-img check /srv/images/storages/win10.qcow2

# Repair if needed
qemu-img check -r all /srv/images/storages/win10.qcow2
```

**3. Re-upload Image**
- Delete corrupted image
- Upload fresh copy
- Create new snapshot

## Memory Issues

### Symptom
Server runs out of memory or becomes slow.

### Diagnosis
```bash
# Check memory usage
free -h
top

# Check ZFS ARC usage
arc_summary | grep "ARC size"
```

### Solutions

**1. Limit ARC Size**
```bash
# Set ARC max to 50% of RAM
TOTAL_RAM=$(free -b | awk '/^Mem:/{print $2}')
ARC_MAX=$((TOTAL_RAM / 2))
echo $ARC_MAX | sudo tee /sys/module/zfs/parameters/zfs_arc_max
```

**2. Add Swap**
```bash
# Create 8GB swap
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

**3. Upgrade RAM**
- Minimum: 16GB
- Recommended: 32GB+
- For 100+ clients: 64GB+

## Network Issues

### Symptom
Intermittent connectivity or packet loss.

### Diagnosis
```bash
# Check network errors
ip -s link show eth0

# Test connectivity
ping -c 100 <client-ip>

# Check for packet loss
mtr <client-ip>
```

### Solutions

**1. Check Network Configuration**
```bash
# Verify IP configuration
ip addr show

# Check routing
ip route show

# Test DNS
nslookup google.com
```

**2. Disable Network Offloading**
```bash
# Disable TCP offload
sudo ethtool -K eth0 tso off gso off gro off
```

**3. Update Network Drivers**
```bash
sudo apt update
sudo apt upgrade
```

## Permission Errors

### Symptom
"Permission denied" errors in logs.

### Diagnosis
```bash
# Check file permissions
ls -la /srv/images/
ls -la /srv/tftp/

# Check process user
ps aux | grep nginx
ps aux | grep tgtd
```

### Solutions

**1. Fix Ownership**
```bash
sudo chown -R www-data:www-data /srv/images
sudo chown -R tftp:tftp /srv/tftp
```

**2. Fix Permissions**
```bash
sudo chmod -R 755 /srv/images
sudo chmod -R 755 /srv/tftp
```

**3. SELinux Issues**
```bash
# Check SELinux status
sestatus

# Set to permissive (temporary)
sudo setenforce 0

# Disable permanently
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
```

## Docker Issues

### Symptom
Container won't start or crashes.

### Diagnosis
```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs nsboot

# Check resources
docker stats
```

### Solutions

**1. Restart Container**
```bash
docker-compose restart nsboot
```

**2. Rebuild Image**
```bash
docker-compose build --no-cache nsboot
docker-compose up -d
```

**3. Check Volumes**
```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect nsboot_nsboot-data
```

**4. Increase Resources**
```yaml
# In docker-compose.yml
services:
  nsboot:
    deploy:
      resources:
        limits:
          memory: 16G
          cpus: '4'
```

## Common Error Messages

### "No bootable device"
- BIOS boot order incorrect
- Network boot not enabled
- DHCP not providing boot server

### "PXE-E53: No boot filename received"
- DHCP configuration missing filename
- TFTP server not accessible

### "Connection refused (iSCSI)"
- iSCSI target not created
- Firewall blocking port 3260
- Wrong initiator IQN

### "Input/output error"
- ZFS volume corruption
- Network connectivity issues
- Disk failure

### "Out of memory"
- ZFS ARC too large
- Insufficient RAM
- Memory leak

## Getting Help

If you're still stuck:

1. **Check Logs**
   ```bash
   sudo journalctl -xe
   docker-compose logs -f
   ```

2. **Enable Debug Mode**
   ```bash
   # In nginx config
   error_log /var/log/nginx/error.log debug;
   ```

3. **Ask for Help**
   - [GitHub Issues](https://github.com/vkornilyev1988/NSBoot-/issues)
   - [Discussions](https://github.com/vkornilyev1988/NSBoot-/discussions)
   - Include: logs, configuration, error messages

## Prevention

### Regular Maintenance
```bash
# Weekly
zpool scrub nsboot0
apt update && apt upgrade

# Monthly
zfs list -t snapshot  # Review snapshots
df -h  # Check disk space

# Quarterly
./scripts/benchmark.sh  # Performance test
```

### Monitoring
- Set up Grafana alerts
- Monitor disk space
- Track boot success rate
- Review logs regularly

### Backups
```bash
# Backup configuration
tar czf nsboot-config-$(date +%Y%m%d).tar.gz /srv/nsboot/cfg

# Backup ZFS
zfs snapshot nsboot0/images@backup-$(date +%Y%m%d)
zfs send nsboot0/images@backup-$(date +%Y%m%d) | gzip > backup.gz
```
