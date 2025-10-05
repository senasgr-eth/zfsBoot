# Architecture Overview

NSBoot follows a modern, layered architecture designed for scalability and maintainability.

## High-Level Architecture

```mermaid
graph TB
    subgraph "Client Layer"
        C1[Client 1]
        C2[Client 2]
        C3[Client N]
    end
    
    subgraph "Network Layer"
        DHCP[DHCP Server]
        TFTP[TFTP Server]
        PXE[PXE/iPXE]
    end
    
    subgraph "Application Layer"
        WEB[Web UI<br/>Vue.js 3]
        API[REST API<br/>OpenResty/Lua]
        WS[WebSocket<br/>Real-time]
    end
    
    subgraph "Storage Layer"
        ISCSI[iSCSI Target]
        ZFS[ZFS Pool]
        SNAP[Snapshots]
    end
    
    subgraph "Monitoring Layer"
        PROM[Prometheus]
        GRAF[Grafana]
        ALERT[Alertmanager]
    end
    
    C1 & C2 & C3 --> DHCP
    C1 & C2 & C3 --> TFTP
    C1 & C2 & C3 --> ISCSI
    
    DHCP --> PXE
    TFTP --> PXE
    
    WEB --> API
    WEB --> WS
    API --> ZFS
    API --> ISCSI
    WS --> API
    
    ISCSI --> ZFS
    ZFS --> SNAP
    
    API --> PROM
    PROM --> GRAF
    PROM --> ALERT
    
    style WEB fill:#3b82f6
    style API fill:#10b981
    style ZFS fill:#f59e0b
    style PROM fill:#ef4444
```

## Component Architecture

```mermaid
graph LR
    subgraph "Frontend"
        V[Vue.js 3]
        TS[TypeScript]
        TW[Tailwind CSS]
        P[Pinia]
        VR[Vue Router]
    end
    
    subgraph "Backend"
        OR[OpenResty]
        L[Lua 5.3]
        JWT[JWT Auth]
        WSS[WebSocket]
    end
    
    subgraph "Storage"
        ZP[ZFS Pool]
        DS[Datasets]
        SN[Snapshots]
    end
    
    V --> TS
    V --> TW
    V --> P
    V --> VR
    
    OR --> L
    L --> JWT
    L --> WSS
    
    ZP --> DS
    DS --> SN
    
    V -.HTTP/WS.-> OR
    OR -.ZFS CLI.-> ZP
    
    style V fill:#42b883
    style OR fill:#00758f
    style ZP fill:#f59e0b
```

## Data Flow

```mermaid
sequenceDiagram
    participant C as Client
    participant W as Web UI
    participant A as API
    participant Z as ZFS
    participant I as iSCSI
    
    C->>W: Access Dashboard
    W->>A: GET /api/system/info
    A->>Z: zfs list
    Z-->>A: Dataset info
    A-->>W: JSON response
    W-->>C: Render UI
    
    C->>W: Upload Image
    W->>A: POST /api/images/upload
    A->>Z: zfs receive
    Z-->>A: Success
    A-->>W: Upload complete
    
    C->>W: Boot Client
    W->>A: POST /api/clients/boot
    A->>I: Create iSCSI target
    I->>Z: Map ZFS volume
    A-->>W: Target created
    W-->>C: Boot initiated
```

## Boot Process Flow

```mermaid
graph TD
    START[Client Power On] --> BIOS[BIOS/UEFI]
    BIOS --> NET[Network Boot]
    NET --> DHCP[DHCP Request]
    DHCP --> IP[Get IP + Boot Server]
    IP --> TFTP[TFTP Download iPXE]
    TFTP --> IPXE[iPXE Execution]
    IPXE --> ISCSI[Connect iSCSI Target]
    ISCSI --> ZFS[Mount ZFS Volume]
    ZFS --> BOOT[Boot OS]
    BOOT --> ONLINE[Client Online]
    
    style START fill:#3b82f6
    style ONLINE fill:#10b981
```

## Deployment Architecture

### Docker Deployment

```mermaid
graph TB
    subgraph "Docker Host"
        subgraph "NSBoot Container"
            NGINX[Nginx + OpenResty]
            LUA[Lua API]
            FRONT[Frontend Static]
        end
        
        subgraph "Monitoring"
            PROM[Prometheus]
            GRAF[Grafana]
        end
        
        VOL1[Volume: Images]
        VOL2[Volume: Config]
    end
    
    NGINX --> LUA
    NGINX --> FRONT
    LUA --> VOL1
    LUA --> VOL2
    
    LUA -.metrics.-> PROM
    PROM --> GRAF
```

### Kubernetes Deployment

```mermaid
graph TB
    subgraph "Kubernetes Cluster"
        ING[Ingress]
        
        subgraph "NSBoot Namespace"
            SVC[Service]
            POD1[Pod 1]
            POD2[Pod 2]
            PVC1[PVC: Images]
            PVC2[PVC: Config]
        end
        
        subgraph "Monitoring"
            PROM[Prometheus]
            GRAF[Grafana]
        end
    end
    
    ING --> SVC
    SVC --> POD1
    SVC --> POD2
    POD1 --> PVC1
    POD2 --> PVC1
    POD1 --> PVC2
    
    POD1 -.metrics.-> PROM
    POD2 -.metrics.-> PROM
    PROM --> GRAF
```

## Security Architecture

```mermaid
graph LR
    subgraph "External"
        USER[User]
        CLIENT[Client]
    end
    
    subgraph "Security Layer"
        FW[Firewall]
        TLS[TLS/HTTPS]
        JWT[JWT Auth]
        RBAC[RBAC]
    end
    
    subgraph "Application"
        API[API]
        DATA[Data]
    end
    
    USER --> FW
    FW --> TLS
    TLS --> JWT
    JWT --> RBAC
    RBAC --> API
    API --> DATA
    
    CLIENT --> FW
    
    style FW fill:#ef4444
    style JWT fill:#f59e0b
    style RBAC fill:#10b981
```

## Storage Architecture

```mermaid
graph TB
    subgraph "ZFS Pool"
        ROOT[nsboot0]
        
        subgraph "Datasets"
            IMG[images/]
            STOR[storages/]
            BOOT[boot/]
            SNAP[snapshots/]
        end
    end
    
    ROOT --> IMG
    ROOT --> STOR
    ROOT --> BOOT
    ROOT --> SNAP
    
    STOR -.snapshot.-> SNAP
    
    subgraph "Features"
        COMP[Compression: LZ4]
        DEDUP[Deduplication]
        ARC[ARC Cache]
    end
    
    ROOT --> COMP
    ROOT --> DEDUP
    ROOT --> ARC
    
    style ROOT fill:#f59e0b
    style SNAP fill:#3b82f6
```

## API Architecture

```mermaid
graph TB
    subgraph "API Layer"
        ROUTER[Router]
        
        subgraph "Modules"
            AUTH[Auth Module]
            SYS[System Module]
            IMG[Images Module]
            CLI[Clients Module]
            SNAP[Snapshots Module]
            SET[Settings Module]
        end
        
        subgraph "Middleware"
            JWT[JWT Verify]
            CORS[CORS]
            RATE[Rate Limit]
            LOG[Logging]
        end
    end
    
    ROUTER --> JWT
    JWT --> CORS
    CORS --> RATE
    RATE --> LOG
    
    LOG --> AUTH
    LOG --> SYS
    LOG --> IMG
    LOG --> CLI
    LOG --> SNAP
    LOG --> SET
    
    style ROUTER fill:#3b82f6
    style JWT fill:#f59e0b
```

## Monitoring Architecture

```mermaid
graph LR
    subgraph "Metrics Sources"
        APP[Application]
        NODE[Node Exporter]
        ZFS[ZFS Exporter]
        NGINX[Nginx Exporter]
    end
    
    subgraph "Collection"
        PROM[Prometheus]
    end
    
    subgraph "Visualization"
        GRAF[Grafana]
    end
    
    subgraph "Alerting"
        ALERT[Alertmanager]
        EMAIL[Email]
        SLACK[Slack]
    end
    
    APP --> PROM
    NODE --> PROM
    ZFS --> PROM
    NGINX --> PROM
    
    PROM --> GRAF
    PROM --> ALERT
    
    ALERT --> EMAIL
    ALERT --> SLACK
    
    style PROM fill:#ef4444
    style GRAF fill:#f59e0b
```

## Technology Stack

### Frontend
- **Framework**: Vue.js 3.4 (Composition API)
- **Language**: TypeScript 5.4
- **Styling**: Tailwind CSS 3.4
- **State**: Pinia 2.1
- **Router**: Vue Router 4.x
- **Charts**: Chart.js 4.4
- **Build**: Vite 5.1

### Backend
- **Server**: OpenResty (Nginx + LuaJIT)
- **Language**: Lua 5.3
- **JSON**: lua-cjson
- **HTTP**: lua-resty-http
- **JWT**: lua-resty-jwt
- **WebSocket**: lua-resty-websocket

### Storage
- **Filesystem**: ZFS 2.1+
- **Block Storage**: iSCSI (tgt), NBD
- **Compression**: LZ4, GZIP, ZSTD
- **Snapshots**: ZFS native

### Network
- **Boot**: PXE, iPXE, UEFI
- **DHCP**: isc-dhcp-server
- **TFTP**: tftpd-hpa
- **Protocol**: iSCSI, NBD

### Monitoring
- **Metrics**: Prometheus 2.x
- **Visualization**: Grafana 10.x
- **Alerting**: Alertmanager
- **Exporters**: Node, ZFS, Nginx

### DevOps
- **Container**: Docker 24.0+
- **Orchestration**: Kubernetes 1.24+
- **Package**: Helm 3.0+
- **CI/CD**: GitHub Actions

## Design Principles

### 1. Separation of Concerns
- Frontend handles UI/UX
- Backend handles business logic
- Storage handles data persistence

### 2. API-First Design
- RESTful API for all operations
- WebSocket for real-time updates
- OpenAPI documentation

### 3. Scalability
- Horizontal scaling via Kubernetes
- Stateless API design
- Distributed storage with ZFS

### 4. Security
- JWT authentication
- HTTPS/TLS encryption
- Role-based access control
- Security headers

### 5. Observability
- Prometheus metrics
- Structured logging
- Distributed tracing (future)
- Health checks

### 6. Developer Experience
- TypeScript for type safety
- Hot reload in development
- Comprehensive documentation
- Easy local setup

## Performance Characteristics

### Latency
- API response: <100ms (p95)
- Page load: <2s
- WebSocket latency: <50ms
- Boot time: <30s per client

### Throughput
- API requests: 1000 req/s
- Concurrent boots: 100 clients
- ZFS IOPS: >10,000
- Network: 10 Gbps

### Scalability
- Clients: 1000+ per server
- Images: Unlimited (storage limited)
- Concurrent users: 100+
- Kubernetes pods: Auto-scale

## Next Steps

- [Component Details](components.md)
- [Data Models](data-models.md)
- [API Design](../api/overview.md)
- [Deployment](../deployment/)
