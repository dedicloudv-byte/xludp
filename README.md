
### 🔧 Fitur Tambahan
- **Backup Configuration** - Backup otomatis config lama
- **System Optimization** - Optimasi UDP buffer size
- **SSL Certificate Generation** - Generate SSL certificate otomatis
- **Multi-Password Support** - Support multiple passwords
- **Port Range Configuration** - Port 6000-19999 untuk load balancing
- **Uninstall Script** - Uninstall bersih dan lengkap

## 📋 Persyaratan Sistem

### Sistem Operasi
- Ubuntu 18.04+ / Debian 10+
- CentOS 7+ / RHEL 7+ (dengan penyesuaian)
- Server dengan akses root

### Arsitektur
- **AMD64 (x86_64)** - Server standar
- **ARM64 (aarch64)** - ARM server, Raspberry Pi 4+

### Minimum Requirements
- **RAM**: 512MB
- **Disk Space**: 100MB
- **Network**: Koneksi internet
- **Port**: 5667, 6000-19999 (UDP)

## 🛠️ Cara Install

### Metode 1: Direct Download (Recommended)

```bash
# Install dengan satu command
wget -O install.sh https://raw.githubusercontent.com/your-repo/zivpn-auto-install/main/zivpn-auto-install.sh
sudo chmod +x install.sh
sudo ./install.sh
```

### Metode 2: Auto Install

```bash
# Auto install untuk AMD64
bash <(curl -fsSL https://raw.githubusercontent.com/your-repo/zivpn-auto-install/main/zivpn-auto-install.sh)
```

### Metode 3: Manual

1. Download script:
```bash
wget https://raw.githubusercontent.com/your-repo/zivpn-auto-install/main/zivpn-auto-install.sh
```

2. Berikan permission:
```bash
chmod +x zivpn-auto-install.sh
```

3. Jalankan sebagai root:
```bash
sudo ./zivpn-auto-install.sh
```

## 🔐 Konfigurasi Password

Selama instalasi, script akan meminta password configuration:

```bash
Enter passwords separated by commas, example: pass1,pass2,pass3
Press enter for default password 'zi'
Password(s): password123,password456,password789
```

### Format Password
- **Single Password**: `password123`
- **Multiple Passwords**: `pass1,pass2,pass3`
- **Default**: `zi` (jika tekan Enter)

## 📊 Service Management

### Check Status
```bash
systemctl status zivpn.service
```

### Restart Service
```bash
systemctl restart zivpn.service
```

### Stop Service
```bash
systemctl stop zivpn.service
```

### View Logs
```bash
# Real-time logs
journalctl -u zivpn.service -f

# Full logs
journalctl -u zivpn.service --no-pager
```

## 🔥 Firewall Configuration

### UFW Firewall (Ubuntu/Debian)
Script otomatis mengkonfigurasi UFW:
```bash
# Allow ports
ufw allow 5667/udp
ufw allow 6000:19999/udp
```

### Manual Firewall Rules
Jika menggunakan firewall lain:

```bash
# iptables
iptables -A INPUT -p udp --dport 5667 -j ACCEPT
iptables -A INPUT -p udp --dport 6000:19999 -j ACCEPT

# firewalld (CentOS/RHEL)
firewall-cmd --add-port=5667/udp --permanent
firewall-cmd --add-port=6000-19999/udp --permanent
firewall-cmd --reload
```

## 📱 Client Configuration

### Connection Settings
```
Server: YOUR_SERVER_IP:5667
Password: (password yang dikonfigurasi)
Protocol: UDP
OBFS: zivpn
```

### Port Load Balancing
Client otomatis menggunakan port dalam range 6000-19999 untuk load balancing.

### Android Client
Download Zivpn dari Google Play Store:
1. Buka Play Store
2. Search: "Zivpn"
3. Install aplikasi
4. Konfigurasi dengan server settings

## 🗂️ File Locations

### Configuration Files
```
/etc/zivpn/
├── config.json          # Main configuration
├── zivpn.crt           # SSL certificate
└── zivpn.key           # SSL private key
```

### Service Files
```
/etc/systemd/system/zivpn.service    # Systemd service
/usr/local/bin/zivpn               # Zivpn binary
```

### Log Files
```
/var/log/zivpn-install.log         # Installation log
/var/log/syslog                    # System logs
```

## 🔄 Update & Upgrade

### Update Zivpn Binary
```bash
# Download latest version
sudo wget -O /usr/local/bin/zivpn https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64

# Make executable
sudo chmod +x /usr/local/bin/zivpn

# Restart service
sudo systemctl restart zivpn.service
```

### Update Configuration
```bash
# Edit config
sudo nano /etc/zivpn/config.json

# Restart to apply changes
sudo systemctl restart zivpn.service
```

## 🗑️ Uninstall

### Easy Uninstall
```bash
# Download uninstall script
wget -O uninstall.sh https://raw.githubusercontent.com/your-repo/zivpn-auto-install/main/zivpn-uninstall.sh

# Make executable
chmod +x uninstall.sh

# Run uninstall
sudo ./uninstall.sh
```

### Manual Uninstall
```bash
# Stop service
sudo systemctl stop zivpn.service
sudo systemctl disable zivpn.service

# Remove files
sudo rm -rf /etc/zivpn
sudo rm /usr/local/bin/zivpn
sudo rm /etc/systemd/system/zivpn.service

# Reload systemd
sudo systemctl daemon-reload

# Remove firewall rules
sudo ufw delete allow 5667/udp
sudo ufw delete allow 6000:19999/udp
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Service Not Starting
```bash
# Check status
sudo systemctl status zivpn.service

# Check logs
sudo journalctl -u zivpn.service -f

# Check configuration
sudo /usr/local/bin/zivpn server -c /etc/zivpn/config.json
```

#### 2. Connection Failed
```bash
# Check if service is running
sudo netstat -ulnp | grep 5667

# Check firewall
sudo ufw status verbose

# Test locally
telnet localhost 5667
```

#### 3. Certificate Issues
```bash
# Regenerate certificates
sudo openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=US/ST=California/L=Los Angeles/O=Zivpn/CN=zivpn" \
    -keyout "/etc/zivpn/zivpn.key" \
    -out "/etc/zivpn/zivpn.crt"

# Restart service
sudo systemctl restart zivpn.service
```

#### 4. Port Already in Use
```bash
# Check what's using port 5667
sudo lsof -i :5667

# Kill process if needed
sudo kill -9 <PID>
```

### Debug Mode
```bash
# Run in debug mode
sudo /usr/local/bin/zivpn server -c /etc/zivpn/config.json --debug
```

### Log Analysis
```bash
# Installation log
tail -f /var/log/zivpn-install.log

# Service logs
sudo journalctl -u zivpn.service --since "1 hour ago"
```

## 📈 Performance Tuning

### System Optimization
Script otomatis mengoptimalkan:
```bash
# UDP buffer sizes
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
```

### Manual Tuning
```bash
# Increase file descriptors
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

# Network optimization
echo "net.ipv4.udp_mem = 102400 873800 16777216" >> /etc/sysctl.conf
sysctl -p
```

## 🔒 Security Best Practices

### SSL Certificates
- RSA 4096 bit untuk keamanan maksimal
- Auto-generate selama instalasi
- Valid 1 tahun, dapat diperpanjang

### Firewall Rules
- Hanya buka port yang diperlukan
- Use UFW untuk manajemen mudah
- Block IP yang mencurigakan

### Password Security
- Gunakan password yang kuat
- Regular password rotation
- Limit concurrent connections

### System Security
```bash
# Update system regularly
sudo apt update && sudo apt upgrade -y

# Use fail2ban for bruteforce protection
sudo apt install fail2ban -y
```

## 📞 Support

### Documentation Links
- [Zivpn Official Website](https://zivpn.com)
- [Original GitHub Repository](https://github.com/zahidbd2/udp-zivpn)
- [Client App - Google Play](https://play.google.com/store/apps/details?id=com.zi.zivpn)

### Community Support
- GitHub Issues untuk bug reports
- Forum untuk diskusi komunitas
- Documentation untuk troubleshooting

## 📄 License

Project ini berdasarkan original work oleh Zahid Islam dengan enhancement tambahan. 
Dilisensikan di bawah MIT License.

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

**Disclaimer**: Use at your own risk. Always backup your system before installation.

---

**Version**: 2.0  
**Last Updated**: 2025  
**Enhanced by**: SuperNinja
