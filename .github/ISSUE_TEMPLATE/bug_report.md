---
name: Bug Report
about: Create a report to help us improve NSBoot
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description

A clear and concise description of what the bug is.

## Steps to Reproduce

1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

## Expected Behavior

A clear and concise description of what you expected to happen.

## Actual Behavior

A clear and concise description of what actually happened.

## Screenshots

If applicable, add screenshots to help explain your problem.

## Environment

**Server:**
- OS: [e.g., Ubuntu 22.04]
- NSBoot Version: [e.g., 4.1.0]
- Installation Method: [Docker/Bare Metal/Kubernetes]
- Docker Version (if applicable): [e.g., 24.0.0]

**Client (if applicable):**
- OS: [e.g., Windows 10]
- Boot Method: [PXE/UEFI]
- Network: [Gigabit/10GbE]

**ZFS:**
- Pool Version: [run `zpool get version`]
- Compression: [lz4/gzip/off]
- ARC Size: [run `arc_summary | grep "ARC size"`]

## Logs

Please provide relevant logs:

```
# NSBoot daemon logs
sudo journalctl -u nsbootd -n 50

# Nginx logs
sudo tail -n 50 /var/log/nginx/error.log

# Docker logs (if using Docker)
docker-compose logs --tail=50 nsboot

# ZFS status
zpool status
```

## Additional Context

Add any other context about the problem here.

## Possible Solution

If you have ideas on how to fix the issue, please describe them here.
