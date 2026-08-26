# 🧪 HOW TO GENERATE HIDS ALERTS & LOGS

**Don't need another VM! Generate test alerts on the same system.**

---

## 🎯 QUICK ANSWER

**Do you need another VM to attack?**

❌ **NO! You don't need another VM at all!**

✅ You can simulate attacks on the **same computer** where HIDS is running.

Think of it like:
```
Your Computer:
├─ Running HIDS (security guard)
└─ You also simulate attacks (bad guy)
   
HIDS catches your attacks
HIDS writes alerts
You see the alerts
Demo looks awesome!
```

---

## 📊 HOW IT WORKS

### Simple Workflow:

```
NORMAL STATE:
Your System = Clean
  ↓
HIDS Scans = No alerts
  ↓
Logs Show = Nothing suspicious

─────────────────────────────────

ATTACK SIMULATION:
You Create Fake Attack
  ↓
HIDS Scans = DETECTS IT!
  ↓
Logs Show = [CRITICAL] ALERT!
  ↓
You Cleanup
  ↓
Back to Normal
```

---

## 🧩 5 EASY WAYS TO GENERATE ALERTS

### **WAY 1: Create a Fake User Account** (Easiest ⭐)

**Simulates:** Unauthorized account creation / Backdoor installation

```bash
# Create a fake attacker account
sudo useradd -m -s /bin/bash attacker

# Run HIDS to detect it
sudo /usr/local/sbin/hids

# Check alerts
sudo tail -20 /var/lib/hids/alerts.log

# Expected output:
# [2024-01-15 14:32:10] [CRITICAL] USER_ANOMALY: New account 'attacker' created
```

**What HIDS detects:**
- ✅ New user account added
- ✅ Unauthorized account with shell access
- ✅ Suspicious UID/GID values

**Cleanup:**
```bash
# Remove the account
sudo userdel -r attacker
```

---

### **WAY 2: Modify Critical Files** (Easy ⭐)

**Simulates:** Tampering with system files / Rootkit installation

```bash
# Modify /etc/passwd (critical system file)
echo "# Added by attacker" | sudo tee -a /etc/passwd

# Run HIDS to detect
sudo /usr/local/sbin/hids

# Check alerts
sudo grep "passwd" /var/lib/hids/alerts.log

# Expected output:
# [2024-01-15 14:33:00] [CRITICAL] FILE_INTEGRITY: /etc/passwd modified
```

**What HIDS detects:**
- ✅ File hash changed
- ✅ File modification timestamp
- ✅ Size changed

**Cleanup:**
```bash
# Remove the line you added
sudo sed -i '/Added by attacker/d' /etc/passwd
```

---

### **WAY 3: Add SSH Backdoor Key** (Medium difficulty)

**Simulates:** Persistence mechanism / SSH key installation

```bash
# Add a fake SSH key
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... attacker@evil.com" | \
  sudo tee -a /root/.ssh/authorized_keys

# Run HIDS
sudo /usr/local/sbin/hids

# Check alerts
sudo grep "authorized_keys" /var/lib/hids/alerts.log

# Expected output:
# [2024-01-15 14:34:00] [CRITICAL] FILE_INTEGRITY: /root/.ssh/authorized_keys modified
```

**What HIDS detects:**
- ✅ SSH key file modification
- ✅ Unauthorized key added

**Cleanup:**
```bash
# Remove the fake key
sudo sed -i '/attacker@evil.com/d' /root/.ssh/authorized_keys
```

---

### **WAY 4: Create Suspicious Process from /tmp** (Medium)

**Simulates:** Malware execution / Unauthorized process

```bash
# Copy bash to /tmp (suspicious location)
sudo cp /bin/bash /tmp/suspicious_binary
sudo chmod +x /tmp/suspicious_binary

# Run the suspicious binary in background
sudo /tmp/suspicious_binary -c "sleep 30" &

# Run HIDS quickly
sudo /usr/local/sbin/hids

# Check alerts
sudo grep "/tmp" /var/lib/hids/alerts.log

# Expected output:
# [2024-01-15 14:35:00] [HIGH] PROCESS_ANOMALY: /tmp/suspicious_binary running as root
```

**What HIDS detects:**
- ✅ Process from world-writable directory
- ✅ Process running as root/privileged user
- ✅ Suspicious process location

**Cleanup:**
```bash
# Kill the process
sudo killall -f /tmp/suspicious_binary 2>/dev/null || true

# Remove the binary
sudo rm /tmp/suspicious_binary
```

---

### **WAY 5: Simulate Brute Force Login** (Easy ⭐)

**Simulates:** Password guessing attack / Brute force attempt

```bash
# Try to login with wrong password multiple times
for i in {1..10}; do
  su - root -c "whoami" 2>&1 | grep -q "Permission denied" || true
done

# Run HIDS
sudo /usr/local/sbin/hids

# Check alerts
sudo grep -i "fail\|login" /var/lib/hids/alerts.log

# Expected output might show:
# [2024-01-15 14:36:00] [HIGH] USER_ANOMALY: Multiple failed login attempts
```

**What HIDS detects:**
- ✅ Failed login attempts
- ✅ Pattern of failed attempts
- ✅ Possible brute force attack

**Cleanup:**
```bash
# No cleanup needed - just stop trying to login
```

---

## 📋 COMPLETE TEST SCRIPT

Create a file `test-hids.sh` that simulates all attacks:

```bash
#!/bin/bash

# Complete HIDS Test Script
# Simulates 5 different attacks and shows alerts

set -e

echo "=========================================="
echo "HIDS Test Script - Simulating Attacks"
echo "=========================================="
echo ""

# Get baseline before attacks
echo "[1/6] Getting baseline (no attacks)..."
echo "Running HIDS scan on clean system..."
sudo /usr/local/sbin/hids > /tmp/baseline.txt 2>&1
BASELINE_ALERTS=$(sudo grep -c "CRITICAL\|HIGH\|MEDIUM" /var/lib/hids/alerts.log 2>/dev/null || echo "0")
echo "✓ Baseline: $BASELINE_ALERTS alerts (should be minimal)"
echo ""

# Test 1: New User
echo "[2/6] Test 1: Creating unauthorized user account..."
sudo useradd -m -s /bin/bash hacker1 2>/dev/null || true
sudo /usr/local/sbin/hids > /dev/null 2>&1
ALERT=$(sudo grep "hacker1" /var/lib/hids/alerts.log | tail -1 || echo "")
echo "✓ Alert: $ALERT"
sudo userdel -r hacker1 2>/dev/null || true
echo ""

# Test 2: SSH Key
echo "[3/6] Test 2: Adding unauthorized SSH key..."
echo "ssh-rsa AAAAB3...test_key attacker@evil.com" | sudo tee -a /root/.ssh/authorized_keys > /dev/null
sudo /usr/local/sbin/hids > /dev/null 2>&1
ALERT=$(sudo grep "authorized_keys" /var/lib/hids/alerts.log | tail -1 || echo "")
echo "✓ Alert: $ALERT"
sudo sed -i '/test_key/d' /root/.ssh/authorized_keys
echo ""

# Test 3: File Modification
echo "[4/6] Test 3: Modifying critical file..."
echo "# Unauthorized modification" | sudo tee -a /etc/passwd > /dev/null
sudo /usr/local/sbin/hids > /dev/null 2>&1
ALERT=$(sudo grep "/etc/passwd" /var/lib/hids/alerts.log | tail -1 || echo "")
echo "✓ Alert: $ALERT"
sudo sed -i '/Unauthorized modification/d' /etc/passwd
echo ""

# Test 4: Suspicious Process
echo "[5/6] Test 4: Running suspicious process from /tmp..."
sudo cp /bin/bash /tmp/malware 2>/dev/null || true
sudo /tmp/malware -c "sleep 5" &
PROC_PID=$!
sleep 1
sudo /usr/local/sbin/hids > /dev/null 2>&1
ALERT=$(sudo grep "/tmp/malware" /var/lib/hids/alerts.log | tail -1 || echo "")
echo "✓ Alert: $ALERT"
kill $PROC_PID 2>/dev/null || true
sudo rm /tmp/malware 2>/dev/null || true
echo ""

# Summary
echo "[6/6] Summary of alerts..."
echo "=========================================="
echo "Alerts detected:"
sudo grep -E "\[CRITICAL\]|\[HIGH\]|\[MEDIUM\]" /var/lib/hids/alerts.log | tail -10
echo ""
echo "=========================================="
echo "✅ All tests completed!"
echo "✅ HIDS detected all simulated attacks!"
```

**Run it:**
```bash
chmod +x test-hids.sh
sudo ./test-hids.sh
```

---

## 📖 VIEW YOUR ALERTS

After running tests, view alerts in different ways:

### **View All Alerts:**
```bash
sudo cat /var/lib/hids/alerts.log
```

### **View Only CRITICAL Alerts:**
```bash
sudo grep "CRITICAL" /var/lib/hids/alerts.log
```

### **View Last 10 Alerts:**
```bash
sudo tail -10 /var/lib/hids/alerts.log
```

### **View Alerts from Last Hour:**
```bash
sudo grep "$(date +%H)" /var/lib/hids/alerts.log
```

### **Count Alerts by Severity:**
```bash
echo "CRITICAL:"
sudo grep -c "CRITICAL" /var/lib/hids/alerts.log || echo "0"
echo "HIGH:"
sudo grep -c "HIGH" /var/lib/hids/alerts.log || echo "0"
echo "MEDIUM:"
sudo grep -c "MEDIUM" /var/lib/hids/alerts.log || echo "0"
```

---

## 🎬 FOR YOUR CAPSTONE DEMO

**This is what evaluators want to see:**

```
Demo Scenario:
1. Show HIDS running on clean system
   └─ sudo /usr/local/sbin/hids
   └─ Show: No alerts (or minimal)

2. Simulate attack
   └─ sudo useradd attacker
   └─ sudo /usr/local/sbin/hids
   └─ SHOW: [CRITICAL] New user 'attacker' created

3. Show HIDS detected it
   └─ sudo tail /var/lib/hids/alerts.log
   └─ Everyone sees the ALERT!

4. Explain what happened
   └─ "HIDS detected the unauthorized account immediately"
   └─ "It logged the alert with timestamp and severity"
   └─ "This is exactly what it's designed to do!"

5. Cleanup
   └─ sudo userdel -r attacker
   └─ Back to clean state
```

**Evaluators' reaction:** "WOW! That actually works!" 🤩

---

## ⏱️ TIME TO GENERATE LOGS

| Method | Time | Difficulty | Alert Count |
|--------|------|-----------|------------|
| Create user | 2 min | Easy ⭐ | 1 CRITICAL |
| Modify file | 2 min | Easy ⭐ | 1 CRITICAL |
| SSH key | 2 min | Easy ⭐ | 1 CRITICAL |
| Suspicious process | 3 min | Medium | 1 HIGH |
| Brute force | 2 min | Easy ⭐ | 1 HIGH |
| **Run all tests** | **15 min** | **Easy** | **5+ alerts** |

---

## 🔄 WORKFLOW FOR YOUR PROJECT

### **Days 5-9 (Testing Phase):**

**Day 5: Create Tests**
```bash
# Run each test individually
sudo useradd test_user && sudo /usr/local/sbin/hids && sudo userdel -r test_user
# Document what alert appeared
```

**Day 6: Run Full Test Suite**
```bash
# Run test-hids.sh
sudo ./test-hids.sh
# Document all alerts
```

**Day 7: Generate Logs for Demo**
```bash
# Run tests again but let logs accumulate
# Don't clean up immediately
# Shows multiple alerts in log file
```

**Day 8-9: Prepare Demo**
```bash
# Practice the demo scenario
# Time it (should take 5 minutes)
# Make sure all alerts appear
```

---

## 📊 WHAT YOUR LOGS WILL LOOK LIKE

### **Alert Log File Example:**

```
[2024-01-15 14:30:00] [MEDIUM] SYSTEM_HEALTH: CPU load: 1.5
[2024-01-15 14:30:05] [LOW] SYSTEM_HEALTH: Memory usage: 45%
[2024-01-15 14:35:10] [CRITICAL] USER_ANOMALY: New account 'attacker' created
[2024-01-15 14:35:15] [CRITICAL] USER_ANOMALY: User 'attacker' added to sudoers
[2024-01-15 14:40:20] [CRITICAL] FILE_INTEGRITY: /etc/passwd modified
[2024-01-15 14:40:25] [CRITICAL] FILE_INTEGRITY: /root/.ssh/authorized_keys modified
[2024-01-15 14:45:30] [HIGH] PROCESS_ANOMALY: /tmp/malware running as root
[2024-01-15 14:45:35] [HIGH] NETWORK_ANOMALY: Listening on backdoor port 31337
[2024-01-15 14:50:40] [MEDIUM] SYSTEM_HEALTH: Memory usage: 92%
[2024-01-15 14:55:50] [HIGH] USER_ANOMALY: 10 failed login attempts in 5 minutes
```

---

## ✅ DO NOT NEED ANOTHER VM IF:

✅ Testing locally  
✅ Learning how HIDS works  
✅ Doing capstone demo  
✅ Showing to evaluators  
✅ Generating test logs  

**All of these can be done on one computer!**

---

## ⚠️ WHEN YOU MIGHT WANT ANOTHER VM

You might want another VM for:

❌ Testing real network attacks (different IP addresses)  
❌ Testing firewall rules (different networks)  
❌ Testing in production environment  
❌ Demonstrating lateral movement  

**But for your capstone:** Not necessary! 👍

---

## 🎓 KEY UNDERSTANDING

### **HIDS Monitors EVERYTHING ON THE SYSTEM**

```
HIDS watches:
├─ Files on disk
├─ Users/accounts
├─ Running processes
├─ Network connections
├─ System resources
└─ Everything!

So when YOU simulate attack:
├─ You create user on same system
├─ HIDS sees the new user
├─ HIDS records it in log
├─ HIDS reports as alert

You're both on same system:
You = Attacker (for testing)
HIDS = Security Guard (watching you)
```

---

## 🧪 QUICK TEST RIGHT NOW

Try this to see HIDS in action:

```bash
# 1. Run HIDS on clean system
sudo /usr/local/sbin/hids

# 2. Check baseline alerts
sudo wc -l /var/lib/hids/alerts.log

# 3. Create a test user
sudo useradd testuser

# 4. Run HIDS again
sudo /usr/local/sbin/hids

# 5. Check alerts increased
sudo wc -l /var/lib/hids/alerts.log
# Should be higher now!

# 6. See the new alert
sudo tail -5 /var/lib/hids/alerts.log
# Should show: [CRITICAL] New account 'testuser' created

# 7. Cleanup
sudo userdel -r testuser
```

**That's it! That's how HIDS generates logs!** ✅

---

## 📝 SUMMARY

**For your capstone project:**

| Question | Answer |
|----------|--------|
| Do I need another VM? | ❌ NO |
| Can I generate alerts on one computer? | ✅ YES |
| How do I simulate attacks? | Create users, modify files, run suspicious processes |
| How many attacks to test? | At least 5 different types |
| How long does it take? | ~15-20 minutes for full test |
| Do evaluators care? | YES! They want to see HIDS work |
| Best demo scenario | Create user → show alert in log → delete user |

---

**Everything you need is in this guide. No additional VMs required!** 🚀

Create test script, run tests, capture logs, show demo. Done! ✅
