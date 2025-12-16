#!/bin/bash
# Zivpn UDP Auto Install Script - Enhanced Version
# Creator: Enhanced by SuperNinja
# Based on original work by Zahid Islam

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/zivpn-install.log"
ZIVPN_VERSION="1.4.9"
DEFAULT_PASSWORD="zi"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}"
    echo "======================================"
    echo "    Zivpn UDP Auto Installer v2.0"
    echo "======================================"
    echo -e "${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        exit 1
    fi
}

# Detect system architecture
detect_architecture() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ZIVPN_ARCH="amd64"
            print_status "Detected AMD64 architecture"
            ;;
        aarch64|arm64)
            ZIVPN_ARCH="arm64"
            print_status "Detected ARM64 architecture"
            ;;
        armv7l)
            print_error "ARMv7 is not supported. Please use ARM64."
            exit 1
            ;;
        *)
            print_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
}

# Check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check if systemd is available
    if ! command -v systemctl &> /dev/null; then
        print_error "systemd is required but not found"
        exit 1
    fi
    
    # Check if wget is available
    if ! command -v wget &> /dev/null; then
        print_status "Installing wget..."
        apt-get update && apt-get install -y wget
    fi
    
    # Check if openssl is available
    if ! command -v openssl &> /dev/null; then
        print_status "Installing openssl..."
        apt-get update && apt-get install -y openssl
    fi
    
    # Check available disk space (need at least 100MB)
    AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
    if [[ $AVAILABLE_SPACE -lt 102400 ]]; then
        print_warning "Low disk space detected. Ensure you have at least 100MB free."
    fi
    
    print_status "System requirements check completed"
}

# Backup existing configuration
backup_config() {
    if [[ -d "/etc/zivpn" ]]; then
        BACKUP_DIR="/etc/zivpn.backup.$(date +%Y%m%d_%H%M%S)"
        print_status "Backing up existing configuration to $BACKUP_DIR"
        cp -r /etc/zivpn "$BACKUP_DIR"
    fi
}

# Stop existing service
stop_existing_service() {
    if systemctl is-active --quiet zivpn.service; then
        print_status "Stopping existing Zivpn service..."
        systemctl stop zivpn.service
    fi
    
    if systemctl is-enabled --quiet zivpn.service; then
        systemctl disable zivpn.service
    fi
}

# Update system packages
update_system() {
    print_status "Updating system packages..."
    apt-get update && apt-get upgrade -y
}

# Download Zivpn binary
download_zivpn() {
    print_status "Downloading Zivpn UDP binary for $ZIVPN_ARCH..."
    
    BINARY_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_${ZIVPN_VERSION}/udp-zivpn-linux-${ZIVPN_ARCH}"
    
    if ! wget -O /usr/local/bin/zivpn "$BINARY_URL"; then
        print_error "Failed to download Zivpn binary"
        exit 1
    fi
    
    chmod +x /usr/local/bin/zivpn
    print_status "Zivpn binary downloaded and made executable"
}

# Create configuration directory
create_config_dir() {
    print_status "Creating configuration directory..."
    mkdir -p /etc/zivpn
    
    # Download base configuration
    if ! wget -O /etc/zivpn/config.json "https://raw.githubusercontent.com/zahidbd2/udp-zivpn/main/config.json"; then
        print_error "Failed to download configuration file"
        exit 1
    fi
    
    print_status "Configuration directory created"
}

# Generate SSL certificates
generate_certificates() {
    print_status "Generating SSL certificates..."
    
    # Generate RSA 4096 certificates
    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
        -subj "/C=US/ST=California/L=Los Angeles/O=Zivpn/OU=IT Department/CN=zivpn" \
        -keyout "/etc/zivpn/zivpn.key" \
        -out "/etc/zivpn/zivpn.crt"
    
    # Set proper permissions
    chmod 600 /etc/zivpn/zivpn.key
    chmod 644 /etc/zivpn/zivpn.crt
    
    print_status "SSL certificates generated successfully"
}

# Optimize system settings
optimize_system() {
    print_status "Optimizing system settings for UDP performance..."
    
    # Set UDP buffer sizes
    sysctl -w net.core.rmem_max=16777216
    sysctl -w net.core.wmem_max=16777216
    
    # Make settings persistent
    cat >> /etc/sysctl.conf << EOF
# Zivpn UDP optimization
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
EOF
    
    print_status "System optimization completed"
}

# Create systemd service
create_service() {
    print_status "Creating systemd service..."
    
    cat > /etc/systemd/system/zivpn.service << 'EOF'
[Unit]
Description=Zivpn UDP VPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd
    systemctl daemon-reload
    
    print_status "Systemd service created successfully"
}

# Configure passwords
configure_passwords() {
    print_status "Configuring Zivpn UDP passwords..."
    
    echo -e "${BLUE}Enter passwords separated by commas, example: pass1,pass2,pass3${NC}"
    echo -e "${BLUE}Press enter for default password '$DEFAULT_PASSWORD'${NC}"
    
    read -p "Password(s): " input_config
    
    if [[ -n "$input_config" ]]; then
        IFS=',' read -r -a config <<< "$input_config"
        # Ensure at least 2 passwords
        if [[ ${#config[@]} -eq 1 ]]; then
            config+=("${config[0]}")
        fi
    else
        config=("$DEFAULT_PASSWORD")
        print_status "Using default password: $DEFAULT_PASSWORD"
    fi
    
    # Update configuration file with passwords
    new_config_str="&quot;config&quot;: [$(printf "&quot;%s&quot;," "${config[@]}" | sed 's/,$//')]"
    sed -i -E "s/&quot;config&quot;: ?\[[[:space:]]*&quot;zi&quot;[[:space:]]*\]/${new_config_str}/g" /etc/zivpn/config.json
    
    print_status "Passwords configured successfully"
    print_warning "Save these passwords for client connection: ${config[*]}"
}

# Configure firewall
configure_firewall() {
    print_status "Configuring firewall rules..."
    
    # Get default network interface
    DEFAULT_INTERFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    
    # Configure iptables for port forwarding
    iptables -t nat -A PREROUTING -i "$DEFAULT_INTERFACE" -p udp --dport 6000:19999 -j DNAT --to-destination :5667
    
    # Save iptables rules ( Debian/Ubuntu )
    if command -v iptables-save &> /dev/null; then
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || echo "iptables-save failed - rules may not persist after reboot"
    fi
    
    # Configure UFW if available
    if command -v ufw &> /dev/null; then
        ufw allow 6000:19999/udp
        ufw allow 5667/udp
        print_status "UFW firewall configured"
    else
        print_warning "UFW not found. Please manually configure your firewall to allow UDP ports 5667 and 6000-19999"
    fi
    
    print_status "Firewall configuration completed"
}

# Start service
start_service() {
    print_status "Starting Zivpn service..."
    
    systemctl enable zivpn.service
    systemctl start zivpn.service
    
    # Wait a moment for service to start
    sleep 3
    
    if systemctl is-active --quiet zivpn.service; then
        print_status "Zivpn service started successfully"
    else
        print_error "Failed to start Zivpn service"
        systemctl status zivpn.service
        exit 1
    fi
}

# Verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    # Check if binary exists
    if [[ ! -f "/usr/local/bin/zivpn" ]]; then
        print_error "Zivpn binary not found"
        return 1
    fi
    
    # Check if service is running
    if ! systemctl is-active --quiet zivpn.service; then
        print_error "Zivpn service is not running"
        return 1
    fi
    
    # Check if configuration exists
    if [[ ! -f "/etc/zivpn/config.json" ]]; then
        print_error "Configuration file not found"
        return 1
    fi
    
    # Check if certificates exist
    if [[ ! -f "/etc/zivpn/zivpn.crt" ]] || [[ ! -f "/etc/zivpn/zivpn.key" ]]; then
        print_error "SSL certificates not found"
        return 1
    fi
    
    print_status "Installation verification completed successfully"
    return 0
}

# Show connection info
show_connection_info() {
    SERVER_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || echo "YOUR_SERVER_IP")
    
    echo -e "${GREEN}"
    echo "======================================"
    echo "      Installation Complete!"
    echo "======================================"
    echo -e "${NC}"
    echo -e "${BLUE}Server Information:${NC}"
    echo -e "  Server IP: ${GREEN}$SERVER_IP${NC}"
    echo -e "  Main Port: ${GREEN}5667${NC}"
    echo -e "  Port Range: ${GREEN}6000-19999${NC}"
    echo -e "  Protocol: ${GREEN}UDP${NC}"
    echo ""
    
    echo -e "${BLUE}Connection Configuration:${NC}"
    echo -e "  Server: ${GREEN}$SERVER_IP:5667${NC}"
    echo -e "  Password: ${GREEN}Check your configured passwords${NC}"
    echo -e "  OBFS: ${GREEN}zivpn${NC}"
    echo ""
    
    echo -e "${BLUE}Service Status:${NC}"
    echo -e "  Status: $(systemctl is-active zivpn.service)"
    echo -e "  Enabled: $(systemctl is-enabled zivpn.service)"
    echo ""
    
    echo -e "${BLUE}Useful Commands:${NC}"
    echo -e "  Check status: ${YELLOW}systemctl status zivpn.service${NC}"
    echo -e "  Restart service: ${YELLOW}systemctl restart zivpn.service${NC}"
    echo -e "  View logs: ${YELLOW}journalctl -u zivpn.service -f${NC}"
    echo -e "  Stop service: ${YELLOW}systemctl stop zivpn.service${NC}"
    echo ""
    
    echo -e "${YELLOW}Download Zivpn client app from Google Play Store${NC}"
    echo -e "Search: ${GREEN}Zivpn${NC}"
}

# Cleanup
cleanup() {
    print_status "Cleaning up temporary files..."
    rm -f zi.sh zi2.sh zivpn-auto-install.sh 2>/dev/null || true
    print_status "Cleanup completed"
}

# Main installation function
main() {
    print_header
    
    # Check log directory and create log file
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    
    log "Starting Zivpn UDP installation process"
    
    # Run installation steps
    check_root
    detect_architecture
    check_requirements
    backup_config
    stop_existing_service
    update_system
    download_zivpn
    create_config_dir
    generate_certificates
    optimize_system
    create_service
    configure_passwords
    configure_firewall
    start_service
    
    # Verify installation
    if verify_installation; then
        show_connection_info
        cleanup
        log "Zivpn UDP installation completed successfully"
        print_status "Installation completed successfully!"
    else
        print_error "Installation verification failed"
        log "Zivpn UDP installation failed"
        exit 1
    fi
}

# Run main function
main "$@"