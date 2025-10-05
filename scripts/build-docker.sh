#!/bin/bash
# NSBoot Docker Build Script
# Builds the complete NSBoot Docker image with frontend

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "NSBoot Docker Build"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Configuration
IMAGE_NAME="${IMAGE_NAME:-nsboot}"
IMAGE_TAG="${IMAGE_TAG:-4.1.0}"
FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

echo "Building: $FULL_IMAGE"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    exit 1
fi

print_success "Docker found: $(docker --version)"

# Check if frontend directory exists
if [ ! -d "$PROJECT_DIR/frontend" ]; then
    print_error "Frontend directory not found"
    exit 1
fi

print_success "Frontend directory found"

# Check if package.json exists
if [ ! -f "$PROJECT_DIR/frontend/package.json" ]; then
    print_error "Frontend package.json not found"
    exit 1
fi

print_success "Frontend package.json found"

echo ""
echo "Step 1: Building Docker image..."
echo "-----------------------------------"

cd "$PROJECT_DIR"

# Build with BuildKit for better caching
export DOCKER_BUILDKIT=1

if docker build \
    --tag "$FULL_IMAGE" \
    --tag "${IMAGE_NAME}:latest" \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    --progress=plain \
    . ; then
    print_success "Docker image built successfully"
else
    print_error "Docker build failed"
    exit 1
fi

echo ""
echo "Step 2: Checking image size..."
echo "-----------------------------------"

IMAGE_SIZE=$(docker images "$FULL_IMAGE" --format "{{.Size}}")
print_success "Image size: $IMAGE_SIZE"

# Check if image is too large
SIZE_BYTES=$(docker images "$FULL_IMAGE" --format "{{.Size}}" | sed 's/[^0-9.]//g')
if [ -n "$SIZE_BYTES" ]; then
    if (( $(echo "$SIZE_BYTES > 1000" | bc -l) )); then
        print_warning "Image size is larger than 1GB"
    fi
fi

echo ""
echo "Step 3: Testing image..."
echo "-----------------------------------"

# Test if image can start
if docker run --rm "$FULL_IMAGE" nginx -t 2>&1 | grep -q "successful"; then
    print_success "Nginx configuration is valid"
else
    print_warning "Nginx configuration test failed"
fi

echo ""
echo "========================================="
echo "Build Complete!"
echo "========================================="
echo ""
echo "Image: $FULL_IMAGE"
echo "Size: $IMAGE_SIZE"
echo ""
echo "To run the image:"
echo "  docker run -d -p 80:80 --name nsboot $FULL_IMAGE"
echo ""
echo "To run with docker-compose:"
echo "  docker-compose up -d"
echo ""
echo "To push to registry:"
echo "  docker push $FULL_IMAGE"
echo ""
