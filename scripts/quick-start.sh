#!/bin/bash
# NSBoot Quick Start Script
# Automated setup for development and testing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "NSBoot Quick Start"
echo "========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "ℹ $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_error "Please do not run as root. Use sudo when needed."
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
else
    print_error "Cannot detect OS. This script supports Ubuntu/Debian."
    exit 1
fi

print_info "Detected OS: $OS $OS_VERSION"
echo ""

# Check prerequisites
echo "Step 1: Checking prerequisites..."
echo "-----------------------------------"

check_command() {
    if command -v $1 &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_warning "$1 is not installed"
        return 1
    fi
}

DOCKER_INSTALLED=$(check_command docker && echo 1 || echo 0)
COMPOSE_INSTALLED=$(check_command docker-compose && echo 1 || echo 0)
NODE_INSTALLED=$(check_command node && echo 1 || echo 0)

echo ""

# Install Docker if needed
if [ "$DOCKER_INSTALLED" -eq 0 ]; then
    echo "Step 2: Installing Docker..."
    echo "-----------------------------------"
    
    read -p "Install Docker? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        print_success "Docker installed"
        print_warning "Please log out and back in for group changes to take effect"
    fi
    echo ""
fi

# Install Docker Compose if needed
if [ "$COMPOSE_INSTALLED" -eq 0 ]; then
    echo "Step 3: Installing Docker Compose..."
    echo "-----------------------------------"
    
    read -p "Install Docker Compose? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo apt-get update
        sudo apt-get install -y docker-compose-plugin
        print_success "Docker Compose installed"
    fi
    echo ""
fi

# Choose installation method
echo "Step 4: Choose installation method"
echo "-----------------------------------"
echo "1) Docker (Recommended - Easy setup)"
echo "2) Bare Metal (Advanced - Full control)"
echo "3) Development Mode (Frontend + Backend)"
echo ""
read -p "Select option (1-3): " INSTALL_METHOD

case $INSTALL_METHOD in
    1)
        echo ""
        echo "Starting Docker installation..."
        echo "-----------------------------------"
        
        cd "$PROJECT_DIR"
        
        # Check if docker-compose.yml exists
        if [ ! -f "docker-compose.yml" ]; then
            print_error "docker-compose.yml not found"
            exit 1
        fi
        
        # Start services
        print_info "Starting NSBoot services..."
        docker-compose up -d
        
        # Wait for services to start
        print_info "Waiting for services to start..."
        sleep 10
        
        # Check status
        docker-compose ps
        
        echo ""
        print_success "NSBoot is running!"
        echo ""
        echo "Access the web interface at:"
        echo "  http://localhost"
        echo ""
        echo "Monitoring:"
        echo "  Grafana:    http://localhost:3000 (admin/nsboot_admin)"
        echo "  Prometheus: http://localhost:9090"
        echo ""
        echo "Useful commands:"
        echo "  docker-compose logs -f     # View logs"
        echo "  docker-compose stop        # Stop services"
        echo "  docker-compose restart     # Restart services"
        echo ""
        ;;
        
    2)
        echo ""
        echo "Starting bare metal installation..."
        echo "-----------------------------------"
        
        print_warning "This will install system packages and configure services."
        read -p "Continue? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
        
        # Install dependencies
        print_info "Installing dependencies..."
        sudo apt-get update
        sudo apt-get install -y \
            zfsutils-linux \
            nginx-extras \
            lua5.3 \
            lua-json \
            lua-socket \
            lua-posix \
            luarocks \
            isc-dhcp-server \
            tftpd-hpa \
            tgt \
            etherwake \
            shellinabox \
            qemu-utils
        
        print_success "Dependencies installed"
        
        # Setup ZFS
        echo ""
        print_info "ZFS Setup"
        read -p "Do you want to create a ZFS pool? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "Enter disk device (e.g., /dev/sdb): " DISK
            
            if [ ! -b "$DISK" ]; then
                print_error "Device $DISK not found"
                exit 1
            fi
            
            print_warning "This will DESTROY all data on $DISK!"
            read -p "Are you sure? (yes/no) " CONFIRM
            
            if [ "$CONFIRM" = "yes" ]; then
                sudo zpool create -m /srv nsboot0 "$DISK"
                sudo zfs create -o mountpoint=/srv/images nsboot0/images
                sudo zfs create -o mountpoint=/srv/images/boot nsboot0/images/boot
                sudo zfs create -o mountpoint=/srv/images/storages nsboot0/images/storages
                sudo zfs set compression=lz4 nsboot0/images
                sudo chown -R www-data:www-data /srv/images
                print_success "ZFS pool created"
            fi
        fi
        
        # Configure Nginx
        print_info "Configuring Nginx..."
        sudo cp "$PROJECT_DIR/nginx/nsboot.conf" /etc/nginx/sites-available/nsboot
        sudo ln -sf /etc/nginx/sites-available/nsboot /etc/nginx/sites-enabled/
        sudo rm -f /etc/nginx/sites-enabled/default
        sudo nginx -t && sudo systemctl restart nginx
        print_success "Nginx configured"
        
        echo ""
        print_success "Bare metal installation complete!"
        echo ""
        echo "Next steps:"
        echo "1. Configure DHCP: /etc/dhcp/dhcpd.conf"
        echo "2. Configure TFTP: /etc/default/tftpd-hpa"
        echo "3. Start NSBoot daemon: sudo systemctl start nsbootd"
        echo "4. Access web interface: http://localhost"
        echo ""
        ;;
        
    3)
        echo ""
        echo "Starting development mode..."
        echo "-----------------------------------"
        
        # Install Node.js if needed
        if [ "$NODE_INSTALLED" -eq 0 ]; then
            print_info "Installing Node.js..."
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            sudo apt-get install -y nodejs
            print_success "Node.js installed"
        fi
        
        # Install frontend dependencies
        print_info "Installing frontend dependencies..."
        cd "$PROJECT_DIR/frontend"
        npm install
        print_success "Frontend dependencies installed"
        
        # Create .env file
        if [ ! -f ".env" ]; then
            cp .env.example .env
            print_success "Created .env file"
        fi
        
        echo ""
        print_success "Development environment ready!"
        echo ""
        echo "To start development:"
        echo "  cd frontend && npm run dev"
        echo ""
        echo "Frontend will be available at:"
        echo "  http://localhost:5173"
        echo ""
        echo "Make sure the backend API is running:"
        echo "  docker-compose up -d nsboot"
        echo ""
        ;;
        
    *)
        print_error "Invalid option"
        exit 1
        ;;
esac

echo "========================================="
echo "Setup complete! 🚀"
echo "========================================="
