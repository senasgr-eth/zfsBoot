# Changelog

All notable changes to NSBoot will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Complete Vue.js components for all views
- JWT authentication implementation
- WebSocket support for real-time updates
- Kubernetes Helm chart
- Integration tests
- E2E tests with Playwright

### Changed
- Improved error handling in API
- Enhanced mobile responsiveness
- Optimized Docker image size

### Fixed
- Dark mode toggle persistence
- ZFS metrics collection
- API CORS configuration

## [4.1.0] - 2025-10-05

### Added - Modernization Phase 1
- **Infrastructure**
  - Docker containerization with multi-stage builds
  - Docker Compose orchestration for full stack
  - Kubernetes support preparation
  - Health checks and proper signal handling

- **CI/CD**
  - GitHub Actions workflow for automated testing
  - Automated Docker image building and publishing
  - Security scanning with Trivy
  - Documentation deployment to GitHub Pages
  - Linting for Lua and JavaScript/TypeScript

- **Frontend**
  - Vue.js 3 with Composition API
  - Tailwind CSS for styling with dark mode support
  - Pinia for state management
  - Vue Router with lazy loading
  - Chart.js integration for visualizations
  - Responsive design for mobile devices
  - Dashboard view with real-time statistics
  - Images management view with upload
  - Clients management view with WoL
  - Snapshots management view
  - Settings view
  - Monitoring view

- **Backend API**
  - OpenResty/Lua REST API layer
  - Route-based request handling
  - JSON response formatting
  - System information endpoints
  - Image management endpoints
  - Client management endpoints
  - Snapshot management endpoints
  - Prometheus metrics endpoint
  - Health check endpoint
  - File upload handling
  - CORS support

- **Monitoring**
  - Prometheus integration
  - Grafana dashboard provisioning
  - Custom NSBoot metrics exporter
  - ZFS metrics exporter
  - Nginx metrics exporter
  - Pre-configured alert rules
  - Performance tracking

- **Documentation**
  - MkDocs documentation site
  - Material theme with dark mode
  - Comprehensive installation guide
  - Quick start guide
  - User guides for all features
  - API reference documentation
  - Administration guides
  - Troubleshooting guides
  - Architecture diagrams with Mermaid

- **Scripts & Automation**
  - ZFS performance tuning script
  - Performance benchmark script
  - Monitoring setup script
  - Quick start installation script
  - Makefile for common tasks

- **Project Management**
  - Updated README with modern formatting
  - Detailed ROADMAP for future development
  - CONTRIBUTING guidelines
  - PROJECT_SUMMARY documentation
  - CHANGELOG (this file)
  - .gitignore and .dockerignore
  - ESLint and TypeScript configuration

### Changed
- Modernized README with badges and better structure
- Improved project organization and file structure
- Enhanced Nginx configuration with OpenResty support
- Updated license information (AGPL-3.0)

### Improved
- Performance optimization for ZFS
- Better error handling and logging
- Security headers in Nginx
- Rate limiting for API endpoints
- Docker image optimization

## [4.0.0] - 2024-XX-XX

### Added
- Base Lua 5.3 implementation
- NBD device process detachment from Nginx
- Init script for start/stop/status/reload
- Support for VHD/QCOW/QCOW2/VMDK/VHDX parent images
- Auto-remove child images on boot if not in super mode
- ZFS storage backend
- iSCSI target support
- PXE boot support
- Basic web interface

### Features
- Diskless boot for Windows/Linux/Mac
- ZFS optimized storage with caching
- Fast I/O performance
- Web-based management interface

## [3.x.x] - Earlier Versions

Previous versions maintained by original author.
See git history for details.

---

## Version Numbering

NSBoot follows Semantic Versioning:
- **MAJOR** version for incompatible API changes
- **MINOR** version for new functionality in a backward compatible manner
- **PATCH** version for backward compatible bug fixes

## Links

- [GitHub Repository](https://github.com/vkornilyev1988/NSBoot-)
- [Documentation](https://nsboot.github.io)
- [Docker Hub](https://hub.docker.com/r/nsboot/nsboot)
- [Issue Tracker](https://github.com/vkornilyev1988/NSBoot-/issues)

[Unreleased]: https://github.com/vkornilyev1988/NSBoot-/compare/v4.1.0...HEAD
[4.1.0]: https://github.com/vkornilyev1988/NSBoot-/compare/v4.0.0...v4.1.0
[4.0.0]: https://github.com/vkornilyev1988/NSBoot-/releases/tag/v4.0.0
