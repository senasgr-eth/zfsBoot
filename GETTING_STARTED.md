# Getting Started with NSBoot

Welcome to NSBoot! This guide will help you get up and running quickly.

## 🚀 Quick Start (5 Minutes)

The fastest way to try NSBoot:

```bash
# Clone and start
git clone https://github.com/vkornilyev1988/NSBoot-.git
cd NSBoot-
docker-compose up -d

# Access the web interface
open http://localhost
```

That's it! NSBoot is now running.

## 📋 What You Need

### Minimum Requirements
- **Server**: 4 CPU cores, 16GB RAM, 100GB SSD
- **Network**: Gigabit Ethernet
- **Software**: Docker 20.10+ and Docker Compose 2.0+

### Recommended for Production
- **Server**: 8+ CPU cores, 32GB+ RAM, NVMe SSD
- **Network**: 10 Gigabit Ethernet
- **Clients**: 100+ workstations

## 🎯 Choose Your Path

### Path 1: Just Exploring? (Docker)

Perfect for testing and evaluation:

```bash
# Start with monitoring
docker-compose up -d

# Access services
Web UI:     http://localhost
Grafana:    http://localhost:3000
Prometheus: http://localhost:9090
```

**What you get:**
- Full NSBoot stack
- Monitoring dashboards
- Sample configuration
- No permanent changes to your system

### Path 2: Setting Up a Lab? (Bare Metal)

For permanent installations:

```bash
# Run the quick start script
chmod +x scripts/quick-start.sh
./scripts/quick-start.sh

# Choose option 2 (Bare Metal)
# Follow the prompts
```

**What you get:**
- Native performance
- Direct ZFS access
- Full control over configuration
- Production-ready setup

### Path 3: Developing/Contributing? (Development Mode)

For developers:

```bash
# Install frontend dependencies
cd frontend
npm install

# Start development server
npm run dev

# In another terminal, start backend
docker-compose up -d nsboot
```

**What you get:**
- Hot reload for frontend
- Easy debugging
- Access to all source code
- Ability to make changes

## 📚 First Steps After Installation

### 1. Access the Dashboard

Open your browser to `http://localhost` (or your server IP).

You'll see:
- **System Overview**: Server stats, client count, storage usage
- **Active Clients**: Currently booted workstations
- **Recent Activity**: Latest events

### 2. Upload Your First Image

1. Click **Images** in the navigation
2. Click **Upload Image**
3. Select an OS image (VHD, QCOW2, ISO, etc.)
4. Wait for upload to complete

**Supported Formats:**
- VHD/VHDX (Windows)
- QCOW2 (Linux, universal)
- VMDK (VMware)
- ISO (Direct boot)

### 3. Configure a Client

1. Click **Clients** in the navigation
2. Click **Add Client**
3. Enter details:
   - Hostname: `workstation-01`
   - MAC Address: Your client's MAC
   - IP Address: Static IP for the client
   - Image: Select uploaded image
4. Click **Save**

### 4. Boot Your First Client

On the client machine:

1. **Enter BIOS/UEFI** (usually F2, F12, or Del)
2. **Enable Network Boot** (PXE or UEFI Network Boot)
3. **Set Boot Order**: Network first
4. **Save and Reboot**

The client will:
1. Get IP from DHCP
2. Download iPXE bootloader
3. Connect to iSCSI target
4. Boot the OS image

### 5. Create a Snapshot

After successful boot:

1. Go to **Snapshots**
2. Click **Create Snapshot**
3. Select the image
4. Name it: `clean-install`
5. Click **Create**

Now you can always revert to this state!

## 🎓 Learning Resources

### Tutorials
- [Quick Start Guide](docs/getting-started/quick-start.md) - 15-minute walkthrough
- [Installation Guide](INSTALL.md) - Detailed installation
- [User Guide](docs/user-guide/) - Using all features

### Videos (Coming Soon)
- Introduction to NSBoot
- Setting up your first diskless lab
- Advanced ZFS tuning
- Troubleshooting common issues

### Community
- [GitHub Discussions](https://github.com/vkornilyev1988/NSBoot-/discussions) - Ask questions
- [Discord Server](#) - Chat with community (coming soon)
- [Reddit r/NSBoot](#) - Share your setup (coming soon)

## 🔧 Common Tasks

### Add More Clients

```bash
# Via Web UI
1. Click Clients → Add Client
2. Fill in details
3. Save

# Via API
curl -X POST http://localhost/api/clients \
  -H "Content-Type: application/json" \
  -d '{
    "hostname": "workstation-02",
    "mac_address": "00:11:22:33:44:56",
    "ip_address": "192.168.1.151",
    "image": "windows10.vhdx"
  }'
```

### Wake Clients Remotely

```bash
# Via Web UI
1. Go to Clients
2. Click power icon next to client

# Via API
curl -X POST http://localhost/api/clients/00:11:22:33:44:55/wake
```

### Monitor Performance

```bash
# Via Web UI
1. Click Monitoring in navigation
2. View real-time metrics

# Via Grafana
1. Open http://localhost:3000
2. Login: admin/nsboot_admin
3. Browse dashboards

# Via Command Line
zpool iostat -v nsboot0 1
```

### Tune Performance

```bash
# Run tuning script
sudo ./scripts/zfs-tune.sh

# Run benchmark
sudo ./scripts/benchmark.sh

# Add L2ARC cache (SSD)
sudo zpool add nsboot0 cache /dev/sdc

# Add ZIL (NVMe)
sudo zpool add nsboot0 log /dev/nvme0n1
```

## 🆘 Getting Help

### Something Not Working?

1. **Check the logs:**
   ```bash
   # Docker
   docker-compose logs -f nsboot
   
   # Bare metal
   sudo journalctl -u nsbootd -f
   ```

2. **Check service status:**
   ```bash
   # Docker
   docker-compose ps
   
   # Bare metal
   sudo systemctl status nsbootd nginx isc-dhcp-server
   ```

3. **Common issues:**
   - [Troubleshooting Guide](docs/troubleshooting/common-issues.md)
   - [FAQ](docs/troubleshooting/faq.md)

### Still Stuck?

- [Open an Issue](https://github.com/vkornilyev1988/NSBoot-/issues)
- [Ask in Discussions](https://github.com/vkornilyev1988/NSBoot-/discussions)
- Check existing issues for solutions

## 🎯 Next Steps

Now that you're up and running:

1. **Explore the UI** - Familiarize yourself with all features
2. **Read the Docs** - Deep dive into specific topics
3. **Optimize Performance** - Tune ZFS for your workload
4. **Set Up Monitoring** - Configure alerts and dashboards
5. **Join the Community** - Share your experience

## 📖 Documentation Structure

```
docs/
├── getting-started/     # Installation and setup
├── user-guide/          # Using NSBoot features
├── admin/               # Administration and tuning
├── api/                 # API reference
├── deployment/          # Docker, K8s, bare metal
└── troubleshooting/     # Common issues and fixes
```

## 🚀 Ready for More?

- **[User Guide](docs/user-guide/)** - Master all features
- **[API Reference](docs/api/)** - Integrate with your tools
- **[Performance Tuning](docs/admin/performance.md)** - Optimize for your workload
- **[Contributing](CONTRIBUTING.md)** - Help improve NSBoot

---

**Welcome to the NSBoot community! 🎉**

If you find NSBoot useful, please ⭐ star the repository on GitHub!
