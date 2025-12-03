#!/bin/bash
# Haley Production Image Build Script
# This script builds a custom Docker image with frappe, erpnext, and enhanced_kanban_view

set -e

# Configuration
IMAGE_NAME="${IMAGE_NAME:-ghcr.io/arkangellabs/haley}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
FRAPPE_BRANCH="${FRAPPE_BRANCH:-version-16}"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Building Haley Production Image ==="
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Frappe Branch: ${FRAPPE_BRANCH}"

# Generate base64 encoded apps.json
APPS_JSON_BASE64=$(base64 -w 0 apps.json)

echo "=== Building Docker Image ==="
docker build \
  --build-arg APPS_JSON_BASE64="${APPS_JSON_BASE64}" \
  --build-arg FRAPPE_BRANCH="${FRAPPE_BRANCH}" \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" \
  -f Dockerfile \
  .

echo "=== Build Complete ==="
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "To push to registry:"
echo "  docker push ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "To run locally:"
echo "  cp .env.example .env"
echo "  # Edit .env with your configuration"
echo "  docker compose up -d"
