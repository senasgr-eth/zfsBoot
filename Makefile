.PHONY: help build run stop clean test lint docs

# Default target
.DEFAULT_GOAL := help

# Variables
DOCKER_IMAGE := nsboot:latest
DOCKER_COMPOSE := docker-compose

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build Docker image
	docker build -t $(DOCKER_IMAGE) .

run: ## Start all services with Docker Compose
	$(DOCKER_COMPOSE) up -d

stop: ## Stop all services
	$(DOCKER_COMPOSE) down

restart: stop run ## Restart all services

logs: ## Show logs
	$(DOCKER_COMPOSE) logs -f

clean: ## Clean up containers, volumes, and images
	$(DOCKER_COMPOSE) down -v
	docker rmi $(DOCKER_IMAGE) || true

dev-frontend: ## Start frontend development server
	cd frontend && npm install && npm run dev

build-frontend: ## Build frontend for production
	cd frontend && npm install && npm run build

test: ## Run tests
	cd frontend && npm run test:unit

lint: ## Run linters
	cd frontend && npm run lint
	luacheck bin/ src/ api/

docs: ## Build documentation
	mkdocs build

docs-serve: ## Serve documentation locally
	mkdocs serve

docs-deploy: ## Deploy documentation to GitHub Pages
	mkdocs gh-deploy

install-deps: ## Install system dependencies (Ubuntu/Debian)
	sudo apt update
	sudo apt install -y zfsutils-linux nginx-extras lua5.3 lua-json \
		lua-socket lua-posix luarocks isc-dhcp-server tftpd-hpa tgt \
		etherwake shellinabox qemu-utils

setup-zfs: ## Create ZFS pool and datasets
	@echo "Creating ZFS pool (requires sudo)..."
	@read -p "Enter disk device (e.g., /dev/sdb): " disk; \
	sudo zpool create -m /srv nsboot0 $$disk && \
	sudo zfs create -o mountpoint=/srv/images nsboot0/images && \
	sudo zfs create -o mountpoint=/srv/images/boot nsboot0/images/boot && \
	sudo zfs create -o mountpoint=/srv/images/storages nsboot0/images/storages && \
	sudo zfs set compression=lz4 nsboot0/images && \
	sudo chown -R www-data:www-data /srv/images

tune-zfs: ## Run ZFS performance tuning
	sudo ./scripts/zfs-tune.sh

benchmark: ## Run performance benchmarks
	sudo ./scripts/benchmark.sh

setup-monitoring: ## Install monitoring exporters
	sudo ./scripts/setup-monitoring.sh

status: ## Show service status
	$(DOCKER_COMPOSE) ps
	@echo ""
	@echo "ZFS Status:"
	@zpool status nsboot0 2>/dev/null || echo "ZFS pool not found"

backup: ## Create backup of configuration
	@mkdir -p backups
	@tar czf backups/nsboot-backup-$$(date +%Y%m%d-%H%M%S).tar.gz \
		srv/nsboot/cfg/ examples/ || true
	@echo "Backup created in backups/"

restore: ## Restore configuration from backup
	@echo "Available backups:"
	@ls -1 backups/*.tar.gz 2>/dev/null || echo "No backups found"
	@read -p "Enter backup filename: " backup; \
	tar xzf backups/$$backup

version: ## Show version information
	@echo "NSBoot v4.1.0"
	@echo "Docker: $$(docker --version)"
	@echo "Docker Compose: $$(docker-compose --version)"
	@echo "Node: $$(node --version 2>/dev/null || echo 'not installed')"
	@echo "Lua: $$(lua -v 2>/dev/null || echo 'not installed')"

check: ## Check system requirements
	@echo "Checking system requirements..."
	@command -v docker >/dev/null 2>&1 && echo "✓ Docker installed" || echo "✗ Docker not found"
	@command -v docker-compose >/dev/null 2>&1 && echo "✓ Docker Compose installed" || echo "✗ Docker Compose not found"
	@command -v node >/dev/null 2>&1 && echo "✓ Node.js installed" || echo "✗ Node.js not found"
	@command -v lua >/dev/null 2>&1 && echo "✓ Lua installed" || echo "✗ Lua not found"
	@command -v zpool >/dev/null 2>&1 && echo "✓ ZFS installed" || echo "✗ ZFS not found"
	@echo ""
	@echo "Memory: $$(free -h | awk '/^Mem:/ {print $$2}')"
	@echo "Disk: $$(df -h / | awk 'NR==2 {print $$4}') available"

.PHONY: all
all: build run ## Build and run everything
