#!/bin/bash
# Test script for Zivpn installation scripts

echo "Testing Zivpn scripts..."

# Test shell syntax
echo "Testing zivpn-auto-install.sh syntax..."
if bash -n zivpn-auto-install.sh; then
    echo "✓ zivpn-auto-install.sh syntax OK"
else
    echo "✗ zivpn-auto-install.sh syntax ERROR"
    exit 1
fi

echo "Testing zivpn-uninstall.sh syntax..."
if bash -n zivpn-uninstall.sh; then
    echo "✓ zivpn-uninstall.sh syntax OK"
else
    echo "✗ zivpn-uninstall.sh syntax ERROR"
    exit 1
fi

# Check file permissions
echo "Checking file permissions..."
if [[ -x "zivpn-auto-install.sh" ]]; then
    echo "✓ zivpn-auto-install.sh is executable"
else
    echo "✗ zivpn-auto-install.sh is not executable"
fi

if [[ -x "zivpn-uninstall.sh" ]]; then
    echo "✓ zivpn-uninstall.sh is executable"
else
    echo "✗ zivpn-uninstall.sh is not executable"
fi

# Check required commands
echo "Checking required commands..."
commands=("wget" "curl" "openssl" "systemctl" "iptables" "ufw")
for cmd in "${commands[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        echo "✓ $cmd is available"
    else
        echo "? $cmd not found (may be installed during script execution)"
    fi
done

echo "All tests completed!"