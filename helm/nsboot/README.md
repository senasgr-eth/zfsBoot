# NSBoot Helm Chart

Helm chart for deploying NSBoot on Kubernetes.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.0+
- PersistentVolume provisioner support (for ZFS storage)
- LoadBalancer support (for external access)

## Installing the Chart

```bash
# Add Helm repository (if published)
helm repo add nsboot https://nsboot.github.io/helm-charts
helm repo update

# Install with default values
helm install nsboot nsboot/nsboot

# Install with custom values
helm install nsboot nsboot/nsboot -f values.yaml

# Install from local chart
helm install nsboot ./helm/nsboot
```

## Uninstalling the Chart

```bash
helm uninstall nsboot
```

## Configuration

The following table lists the configurable parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Image repository | `nsboot/nsboot` |
| `image.tag` | Image tag | `4.1.0` |
| `replicaCount` | Number of replicas | `1` |
| `service.type` | Service type | `LoadBalancer` |
| `persistence.enabled` | Enable persistence | `true` |
| `persistence.size` | Storage size | `500Gi` |
| `zfs.enabled` | Enable ZFS | `true` |
| `zfs.poolName` | ZFS pool name | `nsboot0` |
| `dhcp.enabled` | Enable DHCP server | `true` |
| `monitoring.enabled` | Enable monitoring | `true` |

## Examples

### Basic Installation

```bash
helm install nsboot nsboot/nsboot \
  --set persistence.size=1Ti \
  --set resources.limits.memory=32Gi
```

### With Ingress

```bash
helm install nsboot nsboot/nsboot \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=nsboot.example.com \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix
```

### With Custom Storage Class

```bash
helm install nsboot nsboot/nsboot \
  --set persistence.storageClass=fast-ssd \
  --set persistence.size=2Ti
```

### Production Configuration

```bash
helm install nsboot nsboot/nsboot \
  --set replicaCount=3 \
  --set resources.limits.cpu=8000m \
  --set resources.limits.memory=32Gi \
  --set persistence.size=2Ti \
  --set monitoring.enabled=true \
  --set auth.enabled=true
```

## Upgrading

```bash
# Upgrade to new version
helm upgrade nsboot nsboot/nsboot

# Upgrade with new values
helm upgrade nsboot nsboot/nsboot -f new-values.yaml
```

## Values

See [values.yaml](values.yaml) for full configuration options.

## Support

- Documentation: https://nsboot.github.io
- Issues: https://github.com/vkornilyev1988/NSBoot-/issues
