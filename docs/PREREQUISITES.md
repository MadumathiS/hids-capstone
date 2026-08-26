# 📋 HIDS PROJECT PREREQUISITES & REQUIREMENTS

**Everything you need to install on your Linux VM before starting**

---

## 🖥️ SYSTEM REQUIREMENTS

### Minimum Hardware
- **OS:** Ubuntu 20.04 LTS (or similar Linux distribution)
- **RAM:** 4 GB (8 GB recommended for Kibana)
- **Disk Space:** 20 GB (10 GB minimum)
- **CPU:** 2 cores minimum
- **Network:** Internet connection (for Docker image downloads)

### Recommended Setup
- **OS:** Ubuntu 22.04 LTS
- **RAM:** 8 GB
- **Disk Space:** 30 GB
- **CPU:** 4 cores
- **Type:** Virtual Machine (VirtualBox, VMware, KVM, etc.)

---

## ✅ PREREQUISITES TO INSTALL

### **Category 1: Essential (MUST HAVE)**

These are absolutely required for the project to work:

#### 1. **Linux Shell & Basic Tools** ✅
**Usually pre-installed**

```bash
# Check if bash is available
bash --version

# Check if you have basic utilities
which sudo curl wget git tar
```

**If missing:**
```bash
sudo apt update
sudo apt install -y bash curl wget git tar gzip
```

---

#### 2. **Docker & Docker Compose** ✅ CRITICAL
**Required for Elasticsearch & Kibana**

```bash
# Check if Docker is installed
docker --version

# Check if Docker Compose is installed
docker-compose --version
```

**If NOT installed (complete installation):**

```bash
# Update system
sudo apt update
sudo apt upgrade -y

# Install Docker
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker packages
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group (so you don't need sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker-compose --version
docker ps
```

**Verification:**
```bash
# Test Docker
docker run hello-world

# Should show: "Hello from Docker!"
```

---

#### 3. **Basic Development Tools** ✅

```bash
# Check if you have essential build tools
which gcc make

# If missing, install
sudo apt install -y build-essential
```

**Includes:**
- GCC compiler
- Make utility
- Other build tools

---

### **Category 2: Strongly Recommended**

These are highly recommended but not absolutely critical:

#### 4. **Git** ✅ (For version control)

```bash
# Check if Git is installed
git --version

# If missing, install
sudo apt install -y git

# Configure Git (optional but recommended)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

#### 5. **curl** ✅ (For testing APIs)

```bash
# Check if curl is installed
curl --version

# If missing, install
sudo apt install -y curl

# This is essential for testing Elasticsearch and Kibana
```

---

#### 6. **Text Editors** ✅ (For editing files)

Choose at least one:

**Option A: nano (easiest)**
```bash
sudo apt install -y nano
# Usage: nano filename.txt
```

**Option B: vim (powerful)**
```bash
sudo apt install -y vim
# Usage: vim filename.txt
```

**Option C: VS Code (if using GUI)**
```bash
# Download from https://code.visualstudio.com/
# Or: sudo snap install code --classic
```

---

#### 7. **SSH Client** ✅ (For remote access)

```bash
# Check if SSH is available
ssh -V

# Install if missing
sudo apt install -y openssh-client openssh-server

# Start SSH service
sudo systemctl start ssh
sudo systemctl enable ssh
```

---

### **Category 3: Optional (Nice to have)**

#### 8. **Web Browser** (For accessing Kibana dashboard)
- Firefox (pre-installed on most Linux desktop)
- Chromium
- Google Chrome

```bash
# Install Chromium (if not installed)
sudo apt install -y chromium-browser
```

---

#### 9. **Network Tools** (For testing & debugging)

```bash
# Install networking utilities
sudo apt install -y \
    net-tools \
    netcat-openbsd \
    nmap \
    telnet \
    tcpdump

# These include: netstat, ifconfig, nc, nmap, telnet, tcpdump
```

---

#### 10. **System Monitoring Tools** (Optional)

```bash
# Install monitoring tools
sudo apt install -y \
    htop \
    iotop \
    iftop \
    sysstat

# htop: Better top command
# iotop: Monitor disk I/O
# iftop: Monitor network
# sysstat: System statistics
```

---

## 🔍 VERIFICATION CHECKLIST

### Run this to verify everything is installed:

```bash
#!/bin/bash
echo "========== HIDS PROJECT PREREQUISITES CHECK =========="
echo ""

echo "✓ Checking Essential Requirements:"
echo -n "  1. bash: "
bash --version | head -1

echo -n "  2. sudo: "
sudo -V | head -1

echo -n "  3. curl: "
curl --version | head -1

echo -n "  4. git: "
git --version

echo -n "  5. Docker: "
docker --version

echo -n "  6. Docker Compose: "
docker-compose --version || docker compose --version

echo ""
echo "✓ Checking Recommended Requirements:"
echo -n "  7. nano/vim: "
if command -v nano &> /dev/null; then echo "nano ✓"; else echo "not found"; fi
if command -v vim &> /dev/null; then echo "vim ✓"; else echo "not found"; fi

echo -n "  8. wget: "
wget --version | head -1

echo ""
echo "✓ Checking System Info:"
echo -n "  RAM: "
free -h | grep Mem

echo -n "  Disk: "
df -h / | tail -1

echo -n "  CPU: "
nproc
echo " cores"

echo ""
echo "========== VERIFICATION COMPLETE =========="
```

Save as `check-prerequisites.sh` and run:
```bash
chmod +x check-prerequisites.sh
./check-prerequisites.sh
```

---

## 📥 INSTALLATION SCRIPT

Create a **single script to install everything**:

```bash
#!/bin/bash

# HIDS Project - Complete Prerequisites Installation Script

set -e

echo "=========================================="
echo "Installing HIDS Project Prerequisites"
echo "=========================================="
echo ""

# Update system
echo "Step 1: Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install essential tools
echo "Step 2: Installing essential tools..."
sudo apt install -y \
    bash \
    curl \
    wget \
    git \
    tar \
    gzip \
    nano \
    vim \
    build-essential \
    net-tools \
    ssh

# Install Docker
echo "Step 3: Installing Docker..."
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose (if not included)
echo "Step 4: Verifying Docker Compose..."
docker-compose --version || echo "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Install optional tools
echo "Step 5: Installing optional monitoring tools..."
sudo apt install -y \
    htop \
    net-tools \
    netcat-openbsd || true

# Verify installation
echo ""
echo "=========================================="
echo "Verification:"
echo "=========================================="
echo "Docker version:"
docker --version
echo ""
echo "Docker Compose version:"
docker-compose --version
echo ""
echo "✅ All prerequisites installed!"
echo ""
echo "Next steps:"
echo "1. Log out and log in again (or run: newgrp docker)"
echo "2. Test Docker: docker run hello-world"
echo "3. Download HIDS project files"
echo "4. Follow COMPLETE_LOCAL_VM_SETUP_GUIDE.md"
```

Save as `install-prerequisites.sh`:
```bash
chmod +x install-prerequisites.sh
./install-prerequisites.sh
```

---

## 🎯 QUICK START - What to Do Right Now

### **On Your Linux VM (Ubuntu 20.04+), Run:**

```bash
# Step 1: Open terminal

# Step 2: Update system
sudo apt update && sudo apt upgrade -y

# Step 3: Install Docker (all-in-one command)
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh

# Step 4: Add yourself to docker group
sudo usermod -aG docker $USER && newgrp docker

# Step 5: Verify Docker works
docker run hello-world

# Step 6: Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Step 7: Verify Docker Compose
docker-compose --version

# Step 8: Install Git (optional but recommended)
sudo apt install -y git

echo "✅ All prerequisites installed!"
```

---

## ✅ COMPLETE PREREQUISITES CHECKLIST

Before starting HIDS project, verify you have:

### **Essential (MUST HAVE)**
```
[ ] Linux OS (Ubuntu 20.04+)
[ ] Minimum 4GB RAM
[ ] Minimum 20GB disk space
[ ] Docker installed and working
[ ] Docker Compose installed and working
[ ] sudo access (for administrative commands)
[ ] bash shell
[ ] curl (for testing APIs)
[ ] Internet connection (for Docker images)
```

### **Strongly Recommended**
```
[ ] Git installed (for version control)
[ ] nano or vim (for editing files)
[ ] SSH client/server (for remote access)
[ ] Web browser (for Kibana dashboard)
[ ] 8GB RAM (for better performance)
```

### **Optional**
```
[ ] VS Code (for editing)
[ ] Network tools (netcat, telnet)
[ ] Monitoring tools (htop, iotop)
[ ] Additional text editors
```

---

## 🔧 TROUBLESHOOTING

### **Problem: Docker not found**
```bash
# Solution: Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

### **Problem: Permission denied for docker**
```bash
# Solution: Add to docker group
sudo usermod -aG docker $USER
newgrp docker
# Then log out and back in
```

### **Problem: Not enough disk space**
```bash
# Check disk space
df -h /

# Need at least 20GB free for Docker images and data
# If full, delete unused files or expand disk
```

### **Problem: Docker Compose not found**
```bash
# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

### **Problem: Can't access Kibana on localhost:5601**
```bash
# Verify Docker containers are running
docker ps

# Check if Kibana is running
docker logs kibana

# Check firewall
sudo ufw allow 5601

# Test connection
curl http://localhost:5601/api/status
```

---

## 📊 SYSTEM REQUIREMENTS SUMMARY

| Component | Minimum | Recommended | Essential |
|-----------|---------|-------------|-----------|
| OS | Ubuntu 18.04 | Ubuntu 22.04 LTS | ✅ |
| RAM | 4 GB | 8 GB | ✅ |
| Disk | 20 GB | 30 GB | ✅ |
| CPU Cores | 2 | 4 | ✅ |
| Docker | 20.10+ | Latest | ✅ |
| Docker Compose | 1.29+ | Latest | ✅ |
| Internet | Required | Required | ✅ |

---

## 🚀 NEXT STEPS AFTER INSTALLATION

Once all prerequisites are installed:

1. ✅ Verify with `docker ps` (should show no errors)
2. ✅ Download all 33 HIDS project files
3. ✅ Follow `COMPLETE_LOCAL_VM_SETUP_GUIDE.md`
4. ✅ Place `docker-compose.yml` in project folder
5. ✅ Run: `docker-compose up -d`
6. ✅ Install HIDS using `hids_scanner.sh` and `hids.conf`
7. ✅ Run: `./test-hids-complete.sh`
8. ✅ Access Kibana: `http://localhost:5601`
9. ✅ Success! 🎉

---

## 💡 KEY POINTS

- **Docker & Docker Compose are CRITICAL** - Without these, Elasticsearch & Kibana won't run
- **4GB RAM minimum** - Less than that will cause performance issues
- **20GB disk space** - For Docker images and data storage
- **Linux/Ubuntu** - The HIDS script is designed for Linux
- **Internet connection** - To download Docker images (only once)
- **sudo access** - Required for installing and running HIDS

---

## ✨ SUMMARY

**Absolute Minimum to Install:**
```
1. Linux OS (Ubuntu 20.04+)
2. Docker
3. Docker Compose
4. curl
5. sudo access
```

**That's it! Everything else can be done with these 5 things.**

**Recommended Additional:**
- Git (for version control)
- nano/vim (for editing)
- Web browser (for Kibana)

---

**Run the prerequisites and you're ready to start the HIDS project!** ✅
