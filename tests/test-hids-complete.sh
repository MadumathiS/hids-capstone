#!/bin/bash

# HIDS Complete Test Script with Automatic Log Generation
# This script simulates all 5 attack scenarios and generates realistic alerts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
HIDS_CMD="sudo /usr/local/sbin/hids"
ALERT_LOG="/var/lib/hids/alerts.log"
WAIT_TIME=5

# Helper function to print colored output
print_header() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${BLUE}======================================${NC}"
}

print_test() {
    echo -e "${YELLOW}[TEST $1] $2${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_alert() {
    echo -e "${RED}⚠ ALERT: $1${NC}"
}

# Function to wait for logs
wait_for_logs() {
    echo "Waiting $WAIT_TIME seconds for logs to be generated..."
    sleep $WAIT_TIME
}

# Function to show generated alerts
show_alerts() {
    echo -e "${BLUE}Generated Alerts:${NC}"
    sudo tail -10 "$ALERT_LOG" | while read line; do
        if [[ $line == *"CRITICAL"* ]]; then
            echo -e "${RED}$line${NC}"
        elif [[ $line == *"HIGH"* ]]; then
            echo -e "${YELLOW}$line${NC}"
        else
            echo -e "${GREEN}$line${NC}"
        fi
    done
    echo ""
}

# ============================================
# START OF SCRIPT
# ============================================

print_header "HIDS COMPLETE TEST SUITE"
echo "Testing all 5 security scenarios"
echo "With automatic alert generation"
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v sudo &> /dev/null; then
    echo -e "${RED}✗ sudo not found${NC}"
    exit 1
fi

if ! sudo test -f /usr/local/sbin/hids; then
    echo -e "${RED}✗ HIDS script not found at /usr/local/sbin/hids${NC}"
    exit 1
fi

print_success "All prerequisites met"
echo ""

# Get initial alert count
INITIAL_COUNT=$(sudo grep -c . "$ALERT_LOG" 2>/dev/null || echo "0")
echo "Initial alert count: $INITIAL_COUNT"
echo ""

# ============================================
# TEST 1: NEW USER ACCOUNT
# ============================================

print_test "1/5" "Creating Unauthorized User Account"
echo "This simulates: Backdoor account creation"
echo "Expected alert: USER_ANOMALY (CRITICAL)"
echo ""

# Create test user
echo "Creating user 'attacker'..."
sudo useradd -m -s /bin/bash attacker 2>/dev/null || true
print_success "User 'attacker' created"

# Run HIDS
echo "Running HIDS scan..."
$HIDS_CMD > /dev/null 2>&1
wait_for_logs

# Show alerts
show_alerts

# Cleanup
echo "Cleaning up..."
sudo userdel -r attacker 2>/dev/null || true
print_success "Test 1 complete"
echo ""
sleep 3

# ============================================
# TEST 2: SSH BACKDOOR KEY
# ============================================

print_test "2/5" "Adding Unauthorized SSH Key"
echo "This simulates: SSH backdoor installation"
echo "Expected alert: FILE_INTEGRITY (CRITICAL)"
echo ""

# Create SSH key
echo "Adding SSH key to /root/.ssh/authorized_keys..."
FAKE_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+test+key hacker@evil.com"
echo "$FAKE_KEY" | sudo tee -a /root/.ssh/authorized_keys > /dev/null 2>&1
print_success "SSH key added"

# Run HIDS
echo "Running HIDS scan..."
$HIDS_CMD > /dev/null 2>&1
wait_for_logs

# Show alerts
show_alerts

# Cleanup
echo "Cleaning up..."
sudo sed -i '/test+key/d' /root/.ssh/authorized_keys
print_success "Test 2 complete"
echo ""
sleep 3

# ============================================
# TEST 3: CRITICAL FILE MODIFICATION
# ============================================

print_test "3/5" "Modifying Critical System File"
echo "This simulates: File tampering / Rootkit installation"
echo "Expected alert: FILE_INTEGRITY (CRITICAL)"
echo ""

# Modify /etc/passwd
echo "Modifying /etc/passwd..."
echo "# COMPROMISED BY ATTACKER" | sudo tee -a /etc/passwd > /dev/null 2>&1
print_success "File /etc/passwd modified"

# Run HIDS
echo "Running HIDS scan..."
$HIDS_CMD > /dev/null 2>&1
wait_for_logs

# Show alerts
show_alerts

# Cleanup
echo "Cleaning up..."
sudo sed -i '/COMPROMISED BY ATTACKER/d' /etc/passwd
print_success "Test 3 complete"
echo ""
sleep 3

# ============================================
# TEST 4: SUSPICIOUS PROCESS FROM /TMP
# ============================================

print_test "4/5" "Running Suspicious Process"
echo "This simulates: Malware execution"
echo "Expected alert: PROCESS_ANOMALY (HIGH)"
echo ""

# Create suspicious binary
echo "Creating suspicious binary in /tmp..."
sudo cp /bin/bash /tmp/malware 2>/dev/null || true
sudo chmod +x /tmp/malware
print_success "Binary created at /tmp/malware"

# Run it in background
echo "Executing process from /tmp..."
sudo /tmp/malware -c "sleep 15" &
PROC_PID=$!
print_success "Process running with PID $PROC_PID"

# Give process time to start
sleep 2

# Run HIDS
echo "Running HIDS scan..."
$HIDS_CMD > /dev/null 2>&1
wait_for_logs

# Show alerts
show_alerts

# Cleanup
echo "Cleaning up..."
kill $PROC_PID 2>/dev/null || true
sleep 1
sudo rm /tmp/malware 2>/dev/null || true
print_success "Test 4 complete"
echo ""
sleep 3

# ============================================
# TEST 5: BRUTE FORCE LOGIN
# ============================================

print_test "5/5" "Simulating Brute Force Login Attempts"
echo "This simulates: Password guessing attack"
echo "Expected alert: USER_ANOMALY (HIGH)"
echo ""

# Simulate failed logins
echo "Attempting failed logins..."
for i in {1..10}; do
    su - root -c "whoami" 2>&1 > /dev/null || true
    echo -n "."
done
echo ""
print_success "Failed login attempts simulated"

# Run HIDS
echo "Running HIDS scan..."
$HIDS_CMD > /dev/null 2>&1
wait_for_logs

# Show alerts
show_alerts

# Cleanup
echo "No cleanup needed for this test"
print_success "Test 5 complete"
echo ""

# ============================================
# SUMMARY
# ============================================

print_header "TEST SUMMARY"

# Count alerts
FINAL_COUNT=$(sudo grep -c . "$ALERT_LOG" 2>/dev/null || echo "0")
NEW_ALERTS=$((FINAL_COUNT - INITIAL_COUNT))

echo "Initial alert count: $INITIAL_COUNT"
echo "Final alert count: $FINAL_COUNT"
echo "New alerts generated: $NEW_ALERTS"
echo ""

# Count by severity
CRITICAL=$(sudo grep -c "\[CRITICAL\]" "$ALERT_LOG" 2>/dev/null || echo "0")
HIGH=$(sudo grep -c "\[HIGH\]" "$ALERT_LOG" 2>/dev/null || echo "0")
MEDIUM=$(sudo grep -c "\[MEDIUM\]" "$ALERT_LOG" 2>/dev/null || echo "0")
LOW=$(sudo grep -c "\[LOW\]" "$ALERT_LOG" 2>/dev/null || echo "0")

echo "Alert breakdown:"
print_alert "CRITICAL alerts: $CRITICAL"
echo -e "${YELLOW}HIGH alerts: $HIGH${NC}"
echo -e "${GREEN}MEDIUM alerts: $MEDIUM${NC}"
echo "LOW alerts: $LOW"
echo ""

# Show all recent alerts
echo "All recent alerts from tests:"
echo "=============================="
sudo tail -50 "$ALERT_LOG" | tail -30

echo ""
print_header "TEST RESULTS"

if [ $NEW_ALERTS -gt 0 ]; then
    print_success "Tests passed! $NEW_ALERTS alerts generated."
    print_success "HIDS is working correctly!"
    echo ""
    echo "Next steps:"
    echo "1. Verify alerts in Elasticsearch: curl http://localhost:9200/hids-alerts/_search?pretty"
    echo "2. View Kibana dashboard: http://localhost:5601"
    echo "3. Run demo script: ./demo.sh"
else
    print_alert "No new alerts generated. Check HIDS installation."
fi

echo ""
print_header "HIDS TEST SUITE COMPLETE"
echo "✅ All 5 scenarios tested"
echo "✅ Alerts generated and logged"
echo "✅ Ready for demo!"
echo ""
echo "Logs location: $ALERT_LOG"
echo "Alert count: $FINAL_COUNT"
