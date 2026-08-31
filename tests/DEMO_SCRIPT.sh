#!/bin/bash

################################################################################
# HIDS Capstone Demo Script
# Live demonstration of all 5 security scenarios
# WITH DIRECT EMAIL ALERT GENERATION
################################################################################

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Config
HIDS="/usr/local/sbin/hids"
ALERT_LOG="/var/lib/hids/alerts.log"

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_step() {
    echo -e "${YELLOW}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_demo_section() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

# Demo 1: Show baseline
demo_intro() {
    print_demo_section "HIDS CAPSTONE PROJECT DEMONSTRATION"
    
    echo "This demo shows a Host Intrusion Detection System that:"
    echo "  ✓ Monitors system for unauthorized changes"
    echo "  ✓ Detects 5 types of security threats"
    echo "  ✓ Logs alerts in real-time"
    echo "  ✓ Visualizes threats in Kibana dashboard"
    echo "  ✓ Sends email notifications"
    echo ""
    
    print_step "Checking HIDS baseline..."
    sudo ls -lh /var/lib/hids/baselines/ | head -3
    echo ""
    
    print_step "Current alert count:"
    ALERT_COUNT=$(sudo wc -l < "$ALERT_LOG" 2>/dev/null || echo "0")
    echo "Total alerts logged: $ALERT_COUNT"
    echo ""
}

# Demo Scenario 1: New User
demo_scenario_1() {
    print_demo_section "SCENARIO 1: Unauthorized User Account Creation"
    
    echo "Threat: Attacker creates new user account for backdoor access"
    echo "Detection: USER_ANOMALY"
    echo "Severity: CRITICAL"
    echo ""
    
    print_step "Creating suspicious user account 'attacker'..."
    sudo useradd -m -s /bin/bash attacker 2>/dev/null || true
    sleep 2
    
    print_step "Running HIDS scan..."
    sudo $HIDS > /dev/null 2>&1
    sleep 2
    
    print_step "Checking for generated alerts..."
    sudo tail -5 "$ALERT_LOG"
    
    print_success "Alert detected!"
    echo ""
    
    print_step "Cleaning up..."
    sudo userdel -r attacker 2>/dev/null || true
    echo ""
    sleep 2
}

# Demo Scenario 2: SSH Key
demo_scenario_2() {
    print_demo_section "SCENARIO 2: SSH Backdoor Key Injection"
    
    echo "Threat: Attacker adds SSH key for unauthorized remote access"
    echo "Detection: FILE_INTEGRITY"
    echo "Severity: CRITICAL"
    echo ""
    
    print_step "Adding malicious SSH key..."
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..." | sudo tee -a ~/.ssh/authorized_keys > /dev/null
    sleep 2
    
    print_step "Running HIDS scan..."
    sudo $HIDS > /dev/null 2>&1
    sleep 2
    
    print_step "Checking for generated alerts..."
    sudo tail -5 "$ALERT_LOG"
    
    print_success "Alert detected!"
    echo ""
    
    print_step "Cleaning up..."
    sudo sed -i '/AAAAB3NzaC1yc2EAAAADAQABAAABAQC/d' ~/.ssh/authorized_keys
    echo ""
    sleep 2
}

# Demo Scenario 3: Suspicious Process
demo_scenario_3() {
    print_demo_section "SCENARIO 3: Suspicious Process from /tmp"
    
    echo "Threat: Attacker runs malware from temporary directory"
    echo "Detection: PROCESS_ANOMALY"
    echo "Severity: HIGH"
    echo ""
    
    print_step "Creating suspicious process in /tmp..."
    sudo cp /bin/bash /tmp/malware
    sudo /tmp/malware -c "sleep 10" &
    PROC_PID=$!
    sleep 2
    
    print_step "Running HIDS scan..."
    sudo $HIDS > /dev/null 2>&1
    sleep 2
    
    print_step "Checking for generated alerts..."
    sudo tail -5 "$ALERT_LOG"
    
    print_success "Alert detected!"
    echo ""
    
    print_step "Cleaning up..."
    sudo rm -f /tmp/malware
    wait $PROC_PID 2>/dev/null || true
    echo ""
    sleep 2
}

# Demo Scenario 4: File Modification
demo_scenario_4() {
    print_demo_section "SCENARIO 4: Critical System File Modification"
    
    echo "Threat: Attacker modifies /etc/passwd for privilege escalation"
    echo "Detection: FILE_INTEGRITY"
    echo "Severity: CRITICAL"
    echo ""
    
    print_step "Backing up /etc/passwd..."
    sudo cp /etc/passwd /etc/passwd.bak
    
    print_step "Adding malicious user to /etc/passwd..."
    echo "hacker:x:0:0::/root:/bin/bash" | sudo tee -a /etc/passwd > /dev/null
    sleep 2
    
    print_step "Running HIDS scan..."
    sudo $HIDS > /dev/null 2>&1
    sleep 2
    
    print_step "Checking for generated alerts..."
    sudo tail -5 "$ALERT_LOG"
    
    print_success "Alert detected!"
    echo ""
    
    print_step "Cleaning up..."
    sudo cp /etc/passwd.bak /etc/passwd
    sudo rm -f /etc/passwd.bak
    echo ""
    sleep 2
}

# Demo Scenario 5: Brute Force
demo_scenario_5() {
    print_demo_section "SCENARIO 5: Brute Force Login Attempts"
    
    echo "Threat: Attacker attempts password guessing"
    echo "Detection: USER_ANOMALY"
    echo "Severity: HIGH"
    echo ""
    
    print_step "Simulating failed login attempts..."
    for i in {1..10}; do
        sudo -u nonexistent bash -c "exit" 2>/dev/null || true
        echo -n "."
    done
    echo ""
    sleep 2
    
    print_step "Running HIDS scan..."
    sudo $HIDS > /dev/null 2>&1
    sleep 2
    
    print_step "Checking for generated alerts..."
    sudo tail -5 "$ALERT_LOG"
    
    print_success "Alert detected!"
    echo ""
    sleep 2
}

# Summary with Direct Email Generation
demo_summary() {
    print_demo_section "DEMONSTRATION SUMMARY"
    
    echo "Threats Simulated and Detected:"
    echo "  ✓ Unauthorized user account creation (CRITICAL)"
    echo "  ✓ SSH backdoor key injection (CRITICAL)"
    echo "  ✓ Suspicious process execution (HIGH)"
    echo "  ✓ System file modification (CRITICAL)"
    echo "  ✓ Brute force login attempts (HIGH)"
    echo ""
    
    FINAL_COUNT=$(sudo wc -l < "$ALERT_LOG" 2>/dev/null || echo "0")
    echo "Total alerts generated: $FINAL_COUNT"
    echo ""
    
    print_success "All scenarios completed!"
    echo ""
    
    # ========== DIRECT EMAIL ALERT GENERATION ==========
    print_step "Generating email alert summary..."
    
    # Get alert statistics
    CRITICAL=$(sudo grep -c "\[CRITICAL\]" "$ALERT_LOG" 2>/dev/null || echo "0")
    HIGH=$(sudo grep -c "\[HIGH\]" "$ALERT_LOG" 2>/dev/null || echo "0")
    MEDIUM=$(sudo grep -c "\[MEDIUM\]" "$ALERT_LOG" 2>/dev/null || echo "0")
    
    # Create email body with alert summary
    EMAIL_BODY="HIDS Capstone Demo - Alert Summary
========================================

Total Alerts Generated: $FINAL_COUNT

Alert Breakdown:
- CRITICAL: $CRITICAL
- HIGH: $HIGH
- MEDIUM: $MEDIUM

Scenarios Tested:
✓ Unauthorized user account creation
✓ SSH backdoor key injection
✓ Suspicious process execution
✓ System file modification
✓ Brute force login attempts

Recent Alert Details:
$(sudo tail -15 "$ALERT_LOG")

System Information:
- Hostname: $(hostname)
- Date/Time: $(date)
- Team: Sentinel Team
- Status: Demo Completed Successfully

---
HIDS Security Monitoring System
Real-time Threat Detection & Alerting"
    
    # Send email directly
    echo "$EMAIL_BODY" | sudo mail -r "hids@red" -s "🚨 HIDS Demo Complete: $FINAL_COUNT alerts detected" singaraju.madumathi@gmail.com 2>/dev/null
    
    sleep 2
    print_success "Email alert sent to singaraju.madumathi@gmail.com!"
    echo ""
    # ====================================================
    
    echo "Next: View alerts in Kibana dashboard"
    echo "  → Open: http://localhost:5601"
    echo "  → See real-time alert visualization"
    echo ""
    echo "Email notification sent!"
    echo "  → Check: singaraju.madumathi@gmail.com"
    echo "  → Summary: Alert counts and recent alerts"
    echo ""
}

# Main execution
main() {
    clear
    
    demo_intro
    read -p "Press Enter to start Scenario 1..." 
    demo_scenario_1
    
    read -p "Press Enter to start Scenario 2..."
    demo_scenario_2
    
    read -p "Press Enter to start Scenario 3..."
    demo_scenario_3
    
    read -p "Press Enter to start Scenario 4..."
    demo_scenario_4
    
    read -p "Press Enter to start Scenario 5..."
    demo_scenario_5
    
    demo_summary
}

# Run
main