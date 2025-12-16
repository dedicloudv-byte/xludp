#!/bin/bash
# Zivpn UDP Uninstall Script - Enhanced Version
# Creator: Enhanced by SuperNinja

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
LOG_FILE="/var/log/zivpn-uninstall.log"
SERVICE_NAME="zivpn"

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
    echo "    Zivpn UDP Uninstaller v2.0"
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

# Confirm uninstallation
confirm_uninstall() {
    echo -e "${YELLOW}WARNING: This will completely remove Zivpn UDP from your system.${NC}"
    echo -e "${YELLOW}All configurations, certificates, and logs will be deleted.${NC}"
    echo ""
    
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        print_status "Uninstallation cancelled"
        exit 0
    fi
}

# Stop Zivpn services
stop_services() {
    print_status "Stopping Zivpn services..."
    
    # Stop main service
    if systemctl is-active --quiet "${SERVICE_NAME}.service" 2>/dev/null; then
        systemctl stop "${SERVICE_NAME}.service"
        print_status "Stopped ${SERVICE_NAME}.service"
    fi
    
    # Stop any additional services
    if systemctl is-active --quiet "${SERVICE_NAME}_backfill.service" 2>/dev/null; then
        systemctl stop "${SERVICE_NAME}_backfill.service"
        print_status "Stopped ${SERVICE_NAME}_backfill.service"
    fi
    
    # Kill any remaining processes
    if pgrep -x "$SERVICE_NAME" >/dev/null 2>&1; then
        print_status "Terminating remaining Zivpn processes..."
        killall -9 "$SERVICE_NAME" 2>/dev/null || true
    fi
}

# Disable services
disable_services() {
    print_status "Disabling Zivpn services..."
    
    systemctl disable "${SERVICE_NAME}.service" 2>/dev/null || true
    systemctl disable "${SERVICE_NAME}_backfill.service" 2>/dev/null || true
}

# Remove service files
remove_services() {
    print_status "Removing service files..."
    
    rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
    rm -f "/etc/systemd/system/${SERVICE_NAME}_backfill.service"
    
    # Reload systemd
    systemctl daemon-reload
    systemctl reset-failed
}

# Remove Zivpn files and directories
remove_files() {
    print_status "Removing Zivpn files and directories..."
    
    # Remove configuration directory
    if [[ -d "/etc/${SERVICE_NAME}" ]]; then
        rm -rf "/etc/${SERVICE_NAME}"
        print_status "Removed /etc/${SERVICE_NAME} directory"
    fi
    
    # Remove binary
    if [[ -f "/usr/local/bin/${SERVICE_NAME}" ]]; then
        rm -f "/usr/local/bin/${SERVICE_NAME}"
        print_status "Removed /usr/local/bin/${SERVICE_NAME}"
    fi
    
    # Remove any backup directories
    find /etc -name "${SERVICE_NAME}.backup.*" -type d -exec rm -rf {} + 2>/dev/null || true
}

# Remove firewall rules
remove_firewall_rules() {
    print_status "Removing firewall rules..."
    
    # Get default network interface
    DEFAULT_INTERFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    
    # Remove iptables rules
    if command -v iptables &> /dev/null; then
        # Remove PREROUTING rules
        iptables -t nat -D PREROUTING -i "$DEFAULT_INTERFACE" -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null || true
        
        # Save iptables rules
        if command -v iptables-save &> /dev/null; then
            iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        fi
    fi
    
    # Remove UFW rules if available
    if command -v ufw &> /dev/null; then
        ufw delete allow 6000:19999/udp 2>/dev/null || true
        ufw delete allow 5667/udp 2>/dev/null || true
        print_status "Removed UFW rules"
    fi
}

# Remove system optimizations
remove_system_optimizations() {
    print_status "Removing system optimizations..."
    
    # Remove Zivpn optimizations from sysctl.conf
    if [[ -f "/etc/sysctl.conf" ]]; then
        sed -i '/# Zivpn UDP optimization/,+2d' /etc/sysctl.conf || true
    fi
    
    # Reset sysctl values
    sysctl -w net.core.rmem_max=212992 2>/dev/null || true
    sysctl -w net.core.wmem_max=212992 2>/dev/null || true
}

# Clean system cache and swap
clean_system() {
    print_status "Cleaning system cache and swap..."
    
    # Clear page cache
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    sysctl -w vm.drop_caches=3 2>/dev/null || true
    
    # Clear swap
    swapoff -a 2>/dev/null || true
    swapon -a 2>/dev/null || true
}

# Verify removal
verify_removal() {
    print_status "Verifying removal..."
    
    local removal_complete=true
    
    # Check if process is still running
    if pgrep -x "$SERVICE_NAME" >/dev/null 2>&1; then
        print_warning "Zivpn process is still running"
        removal_complete=false
    else
        print_status "Zivpn process stopped"
    fi
    
    # Check if binary still exists
    if [[ -f "/usr/local/bin/${SERVICE_NAME}" ]]; then
        print_warning "Zivpn binary still exists"
        removal_complete=false
    else
        print_status "Zivpn binary removed"
    fi
    
    # Check if config directory still exists
    if [[ -d "/etc/${SERVICE_NAME}" ]]; then
        print_warning "Configuration directory still exists"
        removal_complete=false
    else
        print_status "Configuration directory removed"
    fi
    
    if [[ "$removal_complete" == "true" ]]; then
        print_status "Zivpn has been completely removed"
        return 0
    else
        print_error "Some components may still be present"
        return 1
    fi
}

# Show completion message
show_completion() {
    echo -e "${GREEN}"
    echo "======================================"
    echo "      Uninstallation Complete!"
    echo "======================================"
    echo -e "${NC}"
    echo -e "${BLUE}Summary:${NC}"
    echo -e "  ✓ Zivpn service stopped and disabled"
    echo -e "  ✓ Service files removed"
    echo -e "  ✓ Binary and configuration files removed"
    echo -e "  ✓ Firewall rules removed"
    echo -e "  ✓ System optimizations removed"
    echo -e "  ✓ System cache cleaned"
    echo ""
    
    echo -e "${YELLOW}Note: System reboot recommended for complete cleanup${NC}"
    echo ""
    
    echo -e "${BLUE}Log file: ${GREEN}$LOG_FILE${NC}"
}

# Cleanup
cleanup() {
    print_status "Cleaning up uninstall script..."
    rm -f zivpn-uninstall.sh 2>/dev/null || true
}

# Main uninstall function
main() {
    print_header
    
    # Check log directory and create log file
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    
    log "Starting Zivpn UDP uninstallation process"
    
    # Run uninstallation steps
    check_root
    confirm_uninstall
    stop_services
    disable_services
    remove_services
    remove_files
    remove_firewall_rules
    remove_system_optimizations
    clean_system
    
    # Verify removal
    if verify_removal; then
        show_completion
        cleanup
        log "Zivpn UDP uninstallation completed successfully"
    else
        print_error "Uninstallation verification failed"
        log "Zivpn UDP uninstallation failed"
        exit 1
    fi
}

# Run main function
main "$@"