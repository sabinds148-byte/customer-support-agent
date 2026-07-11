#!/bin/bash
#
# Customer Support Agent - Deployment Setup Script
# This script automates the deployment on Ubuntu 24.04 LTS
#
# Usage: sudo ./setup.sh
#

set -e  # Exit on error

echo "=========================================="
echo "Customer Support Agent - Ubuntu VM Setup"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (use sudo)"
    exit 1
fi

print_info "Starting deployment setup..."

# Update system
print_info "Updating system packages..."
apt update && apt upgrade -y
print_success "System updated"

# Install dependencies
print_info "Installing system dependencies..."
apt install -y \
    git \
    curl # \
    # nginx \
    # ufw \
    # certbot \
    # python3-certbot-nginx
print_success "Dependencies installed"

# Create application directory
# eg. "/home/username/.../customer-support-agent"
APP_DIR="$(pwd)"
print_info "Setting up application directory: $APP_DIR"

if [ ! -d "$APP_DIR" ]; then
    print_info "Application directory not found. Please clone the repository first."
    print_info "Run: git clone <your-repo-url> $APP_DIR"
    exit 1
fi

cd "$APP_DIR"

# Install uv, which fetches a standalone Python 3.12 interpreter
# regardless of what python3 the OS ships (needed since requirements.txt
# pins packages, e.g. onnxruntime, without wheels for newer Pythons)
print_info "Installing uv (Python version manager)..."
if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi
print_success "uv installed"

print_info "Installing Python 3.12..."
uv python install 3.12
print_success "Python 3.12 installed"

# Create virtual environment
print_info "Creating Python virtual environment..."
uv venv --python 3.12 "$APP_DIR/venv"
print_success "Virtual environment created"

# Install dependencies into the virtual environment
print_info "Installing Python packages..."
uv pip install --python "$APP_DIR/venv/bin/python" -r backend/requirements.txt
print_success "Python packages installed"

# Create .env file if it doesn't exist
ENV_FILE="$APP_DIR/backend/.env"
if [ ! -f "$ENV_FILE" ]; then
    print_info "Creating .env file..."
    cp backend/.env.example "$ENV_FILE"
    print_info "Please edit $ENV_FILE and add your OPENAI_API_KEY"
    print_info "Run: sudo nano $ENV_FILE"
else
    print_success ".env file already exists"
fi

# Initialize ChromaDB
print_info "Initializing ChromaDB vector store..."
cd backend
"$APP_DIR/venv/bin/python" -c "from app.database.vectordb import initialize_vectordb; initialize_vectordb()" 2>/dev/null || print_info "Note: ChromaDB will initialize on first run"
cd ..
print_success "Vector store initialized"

# # Setup systemd service
# print_info "Setting up systemd service..."
# cp deployment/ec2/systemd/support-agent.service /etc/systemd/system/
# systemctl daemon-reload
# systemctl enable support-agent
# print_success "Systemd service configured"

# # Start the service
# print_info "Starting support agent service..."
# systemctl start support-agent
# print_success "Service started"

# # Configure NGINX
# print_info "Configuring NGINX..."
# cp deployment/ec2/nginx/sites-available/support-agent /etc/nginx/sites-available/
# ln -sf /etc/nginx/sites-available/support-agent /etc/nginx/sites-enabled/
# rm -f /etc/nginx/sites-enabled/default
# nginx -t && systemctl reload nginx
# print_success "NGINX configured"

# # Configure firewall
# print_info "Configuring UFW firewall..."
# ufw allow 22/tcp
# ufw allow 80/tcp
# ufw allow 443/tcp
# ufw --force enable
# print_success "Firewall configured"

echo ""
echo "=========================================="
echo "✓ Deployment Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Edit .env file: nano $APP_DIR/backend/.env"
echo "2. Add your OPENAI_API_KEY"
# echo "3. Restart service: sudo systemctl restart support-agent"
# echo "4. Check status: sudo systemctl status support-agent"
# echo "5. View logs: sudo journalctl -u support-agent -f"
echo "3. Activate the virtual environment:"
echo "   source $APP_DIR/venv/bin/activate"
echo "4. Start the backend:"
echo "   cd $APP_DIR/backend && uvicorn app.main:app --reload"
echo "5. Open in your browser:"
echo "   http://localhost:8000/docs"
echo ""
echo ""
