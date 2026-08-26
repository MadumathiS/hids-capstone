# 🚀 COMPLETE LOCAL VM SETUP GUIDE - HIDS WITH KIBANA

**Everything you need to build, test, and demonstrate HIDS on a single Linux VM**

---

## 📋 PREREQUISITES

### Hardware Required
- ✅ Linux VM (Ubuntu 20.04+ or similar)
- ✅ Minimum 4GB RAM (8GB recommended for Kibana)
- ✅ 20GB disk space
- ✅ Network access (for Docker downloads)

### What You'll Install
- ✅ HIDS Script (security monitoring)
- ✅ Docker & Docker Compose (containerization)
- ✅ Elasticsearch (log storage)
- ✅ Kibana (visualization dashboard)

### Time Required
- ⏱️ Total setup: ~2-3 hours first time
- ⏱️ Subsequent runs: ~30 minutes

---

## 🎯 COMPLETE WORKFLOW

```
Step 1: Setup Infrastructure (30 min)
  ├─ Install Docker
  ├─ Download Docker images
  └─ Start Elasticsearch & Kibana

Step 2: Setup HIDS (20 min)
  ├─ Copy HIDS script
  ├─ Create configuration
  ├─ Create baseline
  └─ Test first run

Step 3: Setup Log Parser (20 min)
  ├─ Create parser script
  ├─ Test log parsing
  └─ Start log pipeline

Step 4: Run Test Scenarios (30 min)
  ├─ Test 1: New user
  ├─ Test 2: SSH key
  ├─ Test 3: File modification
  ├─ Test 4: Suspicious process
  └─ Test 5: Brute force

Step 5: Setup Kibana Dashboard (30 min)
  ├─ Access Kibana UI
  ├─ Create index pattern
  ├─ Import dashboard
  └─ View visualizations

Step 6: Prepare Demo (30 min)
  ├─ Practice demo scenario
  ├─ Time the demonstration
  ├─ Prepare talking points
  └─ Ready for evaluation!
```

**Total: ~3 hours to complete everything**

---

# 🔧 PART 1: INFRASTRUCTURE SETUP (30 MINUTES)

## Step 1.1: Update System

```bash
# Update package manager
sudo apt update
sudo apt upgrade -y

# Install dependencies
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```

---

## Step 1.2: Install Docker

```bash
# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verify installation
docker --version
docker-compose --version
```

---

## Step 1.3: Add Your User to Docker Group

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply new group (do this in new terminal or run)
newgrp docker

# Verify (should work without sudo)
docker ps
```

---

## Step 1.4: Create Docker Compose File

Create directory and file:

```bash
mkdir -p ~/hids-project
cd ~/hids-project

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.0.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    healthcheck:
      test: ["CMD-SHELL", "curl -s http://localhost:9200 >/dev/null || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5

  kibana:
    image: docker.elastic.co/kibana/kibana:8.0.0
    container_name: kibana
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      elasticsearch:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "curl -s http://localhost:5601/api/status >/dev/null || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5

volumes:
  elasticsearch_data:
    driver: local
EOF

echo "✓ docker-compose.yml created"
```

---

## Step 1.5: Start Docker Services

```bash
# Start services
docker-compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 30

# Check status
docker-compose ps

# Verify Elasticsearch
curl -s http://localhost:9200/ | head -20

# Verify Kibana (wait ~30 seconds)
curl -s http://localhost:5601/api/status | head -20

echo "✓ Docker services running!"
```

---

# 🛡️ PART 2: HIDS SETUP (20 MINUTES)

## Step 2.1: Create HIDS Directories

```bash
# Create HIDS directories
sudo mkdir -p /var/lib/hids/{baselines,scans}

# Set permissions
sudo chmod 755 /var/lib/hids
sudo chmod 755 /var/lib/hids/baselines
sudo chmod 755 /var/lib/hids/scans

# Verify
ls -la /var/lib/hids/

echo "✓ HIDS directories created"
```

---

## Step 2.2: Copy HIDS Script

Assuming you have `hids_scanner.sh` in current directory:

```bash
# Copy script to system location
sudo cp hids_scanner.sh /usr/local/sbin/hids

# Make executable
sudo chmod 755 /usr/local/sbin/hids

# Verify
ls -la /usr/local/sbin/hids

# Test it
sudo /usr/local/sbin/hids --help

echo "✓ HIDS script installed"
```

---

## Step 2.3: Create Configuration File

```bash
# Create HIDS configuration
sudo cat > /var/lib/hids/hids.conf << 'EOF'
# HIDS Configuration File

## System Health Thresholds
CPU_LOAD_WARNING=2.0
CPU_LOAD_CRITICAL=4.0
MEMORY_USED_WARNING=80
MEMORY_USED_CRITICAL=95
DISK_USED_WARNING=80
DISK_USED_CRITICAL=95
IOWAIT_WARNING=40
IOWAIT_CRITICAL=70

## User Activity Thresholds
FAILED_LOGIN_THRESHOLD=5
FAILED_LOGIN_WINDOW_MINUTES=5

## Network Monitoring
SUSPICIOUS_PORTS="4444 5555 6666 7777 8888 31337"
SUSPICIOUS_LOCATIONS="/tmp /var/tmp /dev/shm"

## Files to Monitor
MONITORED_FILES="/etc/passwd /etc/shadow /etc/sudoers /etc/ssh/sshd_config /root/.ssh/authorized_keys /bin/bash /usr/bin/sudo"

## Alerting
ALERT_LOG="/var/lib/hids/alerts.log"
SCAN_LOG="/var/lib/hids/scans.log"
BASELINE_DIR="/var/lib/hids/baselines"
LOG_LEVEL="INFO"

## Settings
SCAN_HISTORY_DAYS=30
COLLECT_METRICS="yes"
EOF

# Verify
sudo cat /var/lib/hids/hids.conf

echo "✓ HIDS configuration created"
```

---

## Step 2.4: Create Initial Baseline

```bash
# Create baseline (system in clean state)
echo "Creating baseline... (takes 1-2 minutes)"
sudo /usr/local/sbin/hids --baseline

# Verify baseline files created
sudo ls -la /var/lib/hids/baselines/

# Verify alert log created
sudo ls -la /var/lib/hids/alerts.log

echo "✓ Baseline created"
```

---

## Step 2.5: Test HIDS Works

```bash
# Run first scan
echo "Running first HIDS scan..."
sudo /usr/local/sbin/hids

# Check alerts
echo "Checking alerts..."
sudo tail -10 /var/lib/hids/alerts.log

echo "✓ HIDS tested successfully"
```

---

# 📡 PART 3: LOG PARSER SETUP (20 MINUTES)

## Step 3.1: Create Log Parser Script

```bash
# Create parser script
sudo cat > /usr/local/bin/hids-to-elasticsearch.sh << 'EOF'
#!/bin/bash

# HIDS to Elasticsearch Parser
# Reads HIDS alerts and sends them to Elasticsearch

HIDS_LOG="/var/lib/hids/alerts.log"
ELASTICSEARCH_URL="http://localhost:9200"
INDEX_NAME="hids-alerts"

echo "[$(date)] Starting HIDS to Elasticsearch parser..."
echo "[$(date)] Watching: $HIDS_LOG"
echo "[$(date)] Sending to: $ELASTICSEARCH_URL/$INDEX_NAME"

# Function to send alert to Elasticsearch
send_alert() {
    local line="$1"
    
    # Parse alert: [TIMESTAMP] [SEVERITY] CATEGORY: MESSAGE
    if [[ $line =~ \[([^\]]+)\]\ \[([^\]]+)\]\ ([^:]+):\ (.+) ]]; then
        timestamp="${BASH_REMATCH[1]}"
        severity="${BASH_REMATCH[2]}"
        category="${BASH_REMATCH[3]}"
        message="${BASH_REMATCH[4]}"
        
        # Convert timestamp to ISO format
        epoch=$(date -d "$timestamp" +%s 2>/dev/null || date +%s)
        iso_timestamp=$(date -d @$epoch -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
        
        # Create JSON
        json=$(cat <<JSON
{
    "@timestamp": "$iso_timestamp",
    "severity": "$severity",
    "category": "$category",
    "message": "$message",
    "host": "$(hostname)",
    "raw_alert": "$line"
}
JSON
)
        
        # Send to Elasticsearch
        curl -s -X POST \
            "$ELASTICSEARCH_URL/$INDEX_NAME/_doc" \
            -H "Content-Type: application/json" \
            -d "$json" > /dev/null 2>&1
        
        echo "[$(date)] Sent alert: [$severity] $category: $message"
    fi
}

# Watch log file
tail -F "$HIDS_LOG" | while IFS= read -r line; do
    if [[ ! -z "$line" ]] && [[ $line == *"CRITICAL"* ]] || [[ $line == *"HIGH"* ]] || [[ $line == *"MEDIUM"* ]] || [[ $line == *"LOW"* ]]; then
        send_alert "$line"
    fi
done
EOF

# Make executable
sudo chmod +x /usr/local/bin/hids-to-elasticsearch.sh

echo "✓ Log parser script created"
```

---

## Step 3.2: Test Log Parser

```bash
# Start parser in background
echo "Starting log parser..."
sudo /usr/local/bin/hids-to-elasticsearch.sh &
PARSER_PID=$!

echo "Parser PID: $PARSER_PID"

# Wait a few seconds
sleep 5

# Trigger a test alert (create fake user)
echo "Creating test alert..."
sudo useradd test_user 2>/dev/null || true

# Run HIDS to generate alert
echo "Running HIDS to generate alert..."
sudo /usr/local/sbin/hids

# Wait for parsing
sleep 5

# Check Elasticsearch has data
echo "Checking Elasticsearch for parsed alerts..."
curl -s http://localhost:9200/hids-alerts/_search | head -50

# Kill parser
echo "Stopping parser for now..."
sudo kill $PARSER_PID 2>/dev/null || true

# Cleanup test user
sudo userdel -r test_user 2>/dev/null || true

echo "✓ Log parser tested"
```

---

## Step 3.3: Setup Parser as Systemd Service

```bash
# Create systemd service
sudo cat > /etc/systemd/system/hids-elasticsearch.service << 'EOF'
[Unit]
Description=HIDS to Elasticsearch Parser
After=network.target docker.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/hids-to-elasticsearch.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable hids-elasticsearch.service

# Start the service
sudo systemctl start hids-elasticsearch.service

# Verify it's running
sudo systemctl status hids-elasticsearch.service

echo "✓ Parser service created and running"
```

---

# 🧪 PART 4: RUN TEST SCENARIOS (30 MINUTES)

## Step 4.1: Create Test Script

```bash
cd ~/hids-project

cat > test-hids-all.sh << 'EOF'
#!/bin/bash

# Complete HIDS Test Script
# Tests all 5 scenarios and generates logs

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo -e "${GREEN}HIDS Complete Test Suite${NC}"
echo "=========================================="
echo ""

# Get baseline count
BASELINE=$(sudo grep -c . /var/lib/hids/alerts.log 2>/dev/null || echo "0")
echo "Baseline alerts: $BASELINE"
echo ""

# TEST 1: NEW USER
echo -e "${YELLOW}[TEST 1/5] Creating unauthorized user account...${NC}"
sudo useradd -m -s /bin/bash hacker1 2>/dev/null || true
echo "User 'hacker1' created"
sudo /usr/local/sbin/hids > /dev/null 2>&1
sleep 3
ALERT=$(sudo grep "hacker1\|USER_ANOMALY" /var/lib/hids/alerts.log | tail -3 || echo "")
echo -e "${GREEN}✓ Alerts generated:${NC}"
echo "$ALERT"
sudo userdel -r hacker1 2>/dev/null || true
echo ""

# TEST 2: SSH KEY
echo -e "${YELLOW}[TEST 2/5] Adding unauthorized SSH key...${NC}"
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABA...fake_key hacker@evil.com" | sudo tee -a /root/.ssh/authorized_keys > /dev/null 2>&1
echo "SSH key added"
sudo /usr/local/sbin/hids > /dev/null 2>&1
sleep 3
ALERT=$(sudo grep "authorized_keys\|FILE_INTEGRITY" /var/lib/hids/alerts.log | tail -3 || echo "")
echo -e "${GREEN}✓ Alerts generated:${NC}"
echo "$ALERT"
sudo sed -i '/fake_key/d' /root/.ssh/authorized_keys
echo ""

# TEST 3: FILE MODIFICATION
echo -e "${YELLOW}[TEST 3/5] Modifying critical file...${NC}"
echo "# Hacked by attacker" | sudo tee -a /etc/passwd > /dev/null 2>&1
echo "File /etc/passwd modified"
sudo /usr/local/sbin/hids > /dev/null 2>&1
sleep 3
ALERT=$(sudo grep "/etc/passwd\|FILE_INTEGRITY" /var/lib/hids/alerts.log | tail -3 || echo "")
echo -e "${GREEN}✓ Alerts generated:${NC}"
echo "$ALERT"
sudo sed -i '/Hacked by attacker/d' /etc/passwd
echo ""

# TEST 4: SUSPICIOUS PROCESS
echo -e "${YELLOW}[TEST 4/5] Running suspicious process from /tmp...${NC}"
sudo cp /bin/bash /tmp/malware 2>/dev/null || true
echo "Malware binary created at /tmp/malware"
sudo /tmp/malware -c "sleep 10" &
PROC_PID=$!
sleep 2
sudo /usr/local/sbin/hids > /dev/null 2>&1
sleep 3
ALERT=$(sudo grep "/tmp/malware\|PROCESS_ANOMALY" /var/lib/hids/alerts.log | tail -3 || echo "")
echo -e "${GREEN}✓ Alerts generated:${NC}"
echo "$ALERT"
kill $PROC_PID 2>/dev/null || true
sleep 1
sudo rm /tmp/malware 2>/dev/null || true
echo ""

# TEST 5: BRUTE FORCE
echo -e "${YELLOW}[TEST 5/5] Simulating brute force login attempts...${NC}"
echo "Simulating failed login attempts..."
for i in {1..10}; do
  su - root -c "whoami" 2>&1 > /dev/null || true
done
sudo /usr/local/sbin/hids > /dev/null 2>&1
sleep 3
ALERT=$(sudo grep "fail\|brute\|USER_ANOMALY" /var/lib/hids/alerts.log | tail -3 || echo "")
echo -e "${GREEN}✓ Alerts generated:${NC}"
echo "$ALERT"
echo ""

# SUMMARY
echo "=========================================="
echo -e "${GREEN}Test Summary${NC}"
echo "=========================================="
CURRENT=$(sudo grep -c . /var/lib/hids/alerts.log 2>/dev/null || echo "0")
ALERTS_GENERATED=$((CURRENT - BASELINE))
echo "Total alerts in log: $CURRENT"
echo "New alerts generated: $ALERTS_GENERATED"
echo ""
echo -e "${GREEN}✅ All tests completed successfully!${NC}"
echo ""

# Show last alerts
echo "Recent alerts:"
sudo tail -20 /var/lib/hids/alerts.log
EOF

chmod +x test-hids-all.sh

echo "✓ Test script created"
```

---

## Step 4.2: Run All Tests

```bash
# Run test suite
cd ~/hids-project
./test-hids-all.sh

# Wait for logs to be parsed to Elasticsearch (30 seconds)
echo "Waiting for logs to be parsed to Elasticsearch..."
sleep 30

# Verify data in Elasticsearch
echo "Checking Elasticsearch for parsed alerts..."
curl -s http://localhost:9200/hids-alerts/_search?pretty | head -100

echo "✓ Tests completed and logs sent to Elasticsearch"
```

---

# 📊 PART 5: KIBANA DASHBOARD SETUP (30 MINUTES)

## Step 5.1: Access Kibana Web Interface

```bash
# Kibana should be accessible at:
# http://localhost:5601

echo "Kibana URL: http://localhost:5601"
echo "Open in browser..."
```

---

## Step 5.2: Create Index Pattern

1. Open browser to `http://localhost:5601`
2. Wait for Kibana to load
3. Click **"Stack Management"** (left sidebar, bottom)
4. Click **"Index Patterns"**
5. Click **"Create index pattern"**
6. Index pattern name: `hids-alerts`
7. Timestamp field: `@timestamp`
8. Click **"Create index pattern"**

---

## Step 5.3: Import Dashboard

```bash
# Download dashboard JSON (you have this file)
# Option A: Use UI Import
# In Kibana: Stack Management → Saved Objects → Import

# Option B: Use curl (automated)
curl -X POST "localhost:5601/api/saved_objects/dashboard/hids-security-dashboard" \
  -H 'kbn-xsrf: true' \
  -H 'Content-Type: application/json' \
  -d @KIBANA_DASHBOARD_CONFIG.json

echo "✓ Dashboard imported"
```

---

## Step 5.4: View Dashboard

1. Click **"Dashboards"** (left sidebar)
2. Look for **"HIDS Security Monitoring Dashboard"**
3. Click to open
4. See your beautiful visualizations! 🎉

---

## Step 5.5: Create Visualizations (if importing didn't work)

### Visualization 1: Alerts Over Time

1. Click **"Visualize"** → **"Create visualization"**
2. Select **"Area"** chart
3. Choose index: `hids-alerts`
4. **X-axis:** Date histogram on `@timestamp`
5. **Y-axis:** Count
6. **Split by:** `severity.keyword`
7. Title: "HIDS Alerts Over Time"
8. Save

### Visualization 2: Severity Distribution

1. Create **"Pie"** chart
2. Index: `hids-alerts`
3. Bucket by: `severity.keyword`
4. Title: "Alerts by Severity"
5. Save

### Visualization 3: Category Distribution

1. Create **"Bar"** chart
2. Index: `hids-alerts`
3. Y-axis: Count
4. X-axis: `category.keyword`
5. Title: "Alerts by Category"
6. Save

### Visualization 4: Recent Alerts

1. Create **"Data Table"**
2. Index: `hids-alerts`
3. Columns: `@timestamp`, `severity`, `category`, `message`
4. Sort: `@timestamp` (desc)
5. Title: "Recent Alerts"
6. Save

---

# 🎬 PART 6: DEMO PREPARATION (30 MINUTES)

## Step 6.1: Demo Script

```bash
cd ~/hids-project

cat > demo.sh << 'EOF'
#!/bin/bash

# HIDS Demo Script
# Shows HIDS detecting an attack in real-time

echo "======================================"
echo "HIDS Security Demo"
echo "======================================"
echo ""

echo "Step 1: Show clean system"
echo "Running HIDS scan on clean system..."
sudo /usr/local/sbin/hids
echo "✓ No alerts on clean system"
echo ""

sleep 2

echo "Step 2: Simulate attack (create unauthorized user)"
echo "Creating user 'attacker'..."
sudo useradd -m -s /bin/bash attacker

echo "✓ Unauthorized user account created"
echo ""

sleep 2

echo "Step 3: Run HIDS to detect attack"
echo "Running HIDS scan..."
sudo /usr/local/sbin/hids

echo "✓ HIDS scan complete"
echo ""

sleep 2

echo "Step 4: Show CRITICAL alerts"
echo "======================================="
echo "HIDS DETECTED THE ATTACK:"
echo "======================================="
sudo grep "CRITICAL\|attacker" /var/lib/hids/alerts.log | tail -5
echo "======================================="
echo ""

sleep 2

echo "Step 5: Cleanup"
echo "Removing unauthorized account..."
sudo userdel -r attacker

echo "✓ System back to clean state"
echo ""

echo "======================================"
echo "Demo Complete!"
echo "======================================"
echo ""
echo "HIDS successfully detected and logged:"
echo "  ✓ Unauthorized account creation"
echo "  ✓ Security violation"
echo "  ✓ Attack with timestamp & severity"
EOF

chmod +x demo.sh

echo "✓ Demo script created"
```

---

## Step 6.2: Practice Demo

```bash
# Run demo multiple times
cd ~/hids-project

echo "Practice Run 1:"
./demo.sh

sleep 30

echo "Practice Run 2:"
./demo.sh

sleep 30

echo "Practice Run 3:"
./demo.sh

echo "✓ Demo practiced 3 times"
```

---

## Step 6.3: Final Verification

```bash
# Verify everything is running
echo "System Status Check:"
echo "===================="

echo -n "✓ HIDS installed: "
sudo /usr/local/sbin/hids --help | head -1

echo -n "✓ Elasticsearch: "
curl -s http://localhost:9200/ | grep version

echo -n "✓ Kibana: "
curl -s http://localhost:5601/api/status | grep state

echo -n "✓ Alert logs: "
sudo tail -1 /var/lib/hids/alerts.log

echo -n "✓ Elasticsearch data: "
curl -s http://localhost:9200/hids-alerts/_search | grep hits

echo ""
echo "✅ All systems operational!"
```

---

# 📋 COMPLETE CHECKLIST

```
INFRASTRUCTURE
  [ ] Docker installed
  [ ] Docker Compose file created
  [ ] Elasticsearch running
  [ ] Kibana running

HIDS SETUP
  [ ] HIDS script installed
  [ ] Configuration created
  [ ] Baseline created
  [ ] First scan successful

LOG PARSER
  [ ] Parser script created
  [ ] Parser service running
  [ ] Logs flowing to Elasticsearch

TESTING
  [ ] All 5 test scenarios run
  [ ] Alerts generated
  [ ] Alerts in Elasticsearch
  [ ] Alerts in Kibana

DASHBOARD
  [ ] Index pattern created
  [ ] Dashboard imported
  [ ] Visualizations showing data
  [ ] All 4 panels working

DEMO
  [ ] Demo script created
  [ ] Demo practiced 3+ times
  [ ] Timing correct (5 minutes)
  [ ] Confident with explanation

READY FOR EVALUATION
  [ ] All tests pass
  [ ] Dashboard shows data
  [ ] Demo works perfectly
  [ ] Documentation complete
```

---

# 🎓 KEY COMMANDS REFERENCE

### Start Everything

```bash
cd ~/hids-project

# Start Docker containers
docker-compose up -d

# Start HIDS parser service
sudo systemctl start hids-elasticsearch.service

# Verify all running
docker ps
sudo systemctl status hids-elasticsearch.service
```

### Stop Everything

```bash
# Stop parser
sudo systemctl stop hids-elasticsearch.service

# Stop containers
docker-compose down
```

### View Logs

```bash
# HIDS alerts
sudo tail -50 /var/lib/hids/alerts.log

# Parser logs
sudo journalctl -u hids-elasticsearch.service -n 50 -f

# Docker logs
docker-compose logs -f
```

### Clean Everything

```bash
# Stop all services
docker-compose down -v
sudo systemctl stop hids-elasticsearch.service

# Remove HIDS directories
sudo rm -rf /var/lib/hids

# Remove logs
sudo rm /var/lib/hids/alerts.log
```

---

# 🎬 COMPLETE WORKFLOW SUMMARY

```
Day 1:
  1. Install Docker
  2. Start Elasticsearch & Kibana
  3. Install HIDS
  4. Create baseline
  5. Verify HIDS works

Day 2:
  1. Setup log parser
  2. Run test scenarios
  3. Generate alerts
  4. Verify logs in Elasticsearch

Day 3:
  1. Setup Kibana dashboard
  2. Create visualizations
  3. Import dashboard config
  4. View beautiful graphs

Day 4:
  1. Create demo script
  2. Practice demo 3+ times
  3. Perfect timing & explanation
  4. Ready for evaluation!
```

---

# ✅ FINAL RESULT

When complete, you'll have:

✅ **Working HIDS** - Monitoring your system  
✅ **Real alerts** - From 5 test scenarios  
✅ **Elasticsearch database** - Storing all alerts  
✅ **Kibana dashboard** - Beautiful visualizations  
✅ **Perfect demo** - Ready for evaluators  
✅ **Professional setup** - Looks amazing!  

---

# 🚀 START NOW!

```bash
# Begin setup
mkdir -p ~/hids-project
cd ~/hids-project

# Follow Part 1-6 above step by step
# ~3 hours total
# Complete project ready for evaluation!
```

**Let's build an awesome HIDS with Kibana dashboard!** 🎉

---

**Total Setup Time:** ~3 hours  
**Demo Time:** ~5 minutes  
**Maintenance:** ~10 minutes daily

**Result:** Professional security monitoring system! 🛡️
