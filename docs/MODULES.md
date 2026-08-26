# HIDS Complete Step-by-Step Guide
## Host Intrusion Detection System - Full Implementation

**Philosophy:** "Find them before they find you"  
**Assumption:** The intruder is ALREADY INSIDE your system  
**Goal:** Detect compromise before the attacker achieves their objectives

---

## TABLE OF CONTENTS

1. [Understanding HIDS](#understanding-hids)
2. [Prerequisites](#prerequisites)
3. [Phase 1: Installation (30 minutes)](#phase-1-installation)
4. [Phase 2: Create Baseline (15 minutes)](#phase-2-create-baseline)
5. [Phase 3: First Scan & Analysis (20 minutes)](#phase-3-first-scan--analysis)
6. [Phase 4: Automation Setup (30 minutes)](#phase-4-automation-setup)
7. [Phase 5: Daily Operations (Ongoing)](#phase-5-daily-operations)
8. [Phase 6: Threat Response (When Needed)](#phase-6-threat-response)
9. [Troubleshooting & Maintenance](#troubleshooting--maintenance)

---

# PART 1: UNDERSTANDING HIDS

## What is HIDS?

**HIDS (Host Intrusion Detection System)** is a security tool that lives INSIDE your system and hunts for intruders who have already penetrated your defenses.

### The House Analogy

```
Your Home Security:
┌─────────────────────────────────────┐
│  FRONT DOOR (Network Security)      │
│  - Locks (Firewall)                 │
│  - Security cameras (Network IDS)   │
│  - Guard at entrance (DLP)          │
└─────────────────────────────────────┘
           ↓ (Someone slips past)
┌─────────────────────────────────────┐
│  INSIDE THE HOUSE (Your Server)     │
│  - HIDS = Silent security guard     │
│  - Notices opened safes             │
│  - Detects footprints in dust       │
│  - Hears suspicious sounds          │
│  - Alerts you IMMEDIATELY           │
└─────────────────────────────────────┘
```

### What HIDS is NOT

- ❌ Not a firewall (doesn't block traffic at network edge)
- ❌ Not antivirus (doesn't scan for known signatures)
- ❌ Not a Web Application Firewall (doesn't protect apps)
- ❌ Not a replacement for patching (doesn't fix vulnerabilities)

### What HIDS IS

- ✅ A detective, not a preventative measure
- ✅ Assumes breach has already happened
- ✅ Hunts for signs of intrusion inside the system
- ✅ Alerts you before attacker achieves goals
- ✅ Essential layer in defense-in-depth strategy

---

## How HIDS Works: The Detection Layers

### Layer 1: What's Running? (Process Monitoring)
Answers: "Is there a program here that shouldn't be?"
- Checks for executables in /tmp
- Detects suspicious process names
- Identifies programs making network connections

### Layer 2: What Changed? (File Integrity)
Answers: "Have critical files been modified?"
- Compares SHA256 hashes to baseline
- Detects: backdoor accounts, modified passwords, sudoers changes
- Alerts on permission changes

### Layer 3: Who's Here? (User Monitoring)
Answers: "Who is accessing the system and how?"
- Tracks login attempts
- Detects new user accounts
- Identifies unauthorized SSH keys
- Monitors privilege escalation

### Layer 4: Where's the Data Going? (Network Monitoring)
Answers: "What connections are active?"
- Lists listening ports
- Shows established connections
- Detects suspicious ports (backdoor indicators)
- Identifies unusual outbound traffic

### Layer 5: What's Scheduled? (Task Monitoring)
Answers: "What runs automatically?"
- Checks all cron jobs
- Reviews systemd timers
- Detects persistence mechanisms

### Layer 6: Is Kernel Compromised? (Rootkit Detection)
Answers: "Is this compromise deep in the system?"
- Scans kernel modules
- Detects orphaned processes
- Checks binary integrity

---

## Detection Timeline

```
Time →
├─── DAY 1: Attacker breaches (steals credentials)
│    - Network IDS: Not triggered (uses legitimate login)
│    - Firewall: Allows it (encrypted SSH)
│    - HIDS: Doesn't know yet (not her job to prevent)
│
├─── DAY 2: Attacker installs backdoor
│    - Modifies: /etc/passwd, adds SSH key, creates cron job
│    - Network IDS: Traffic looks normal (encrypted)
│    - Firewall: Can't see inside (encrypted)
│    - HIDS: [ALERT] "File /etc/passwd changed!"
│              [ALERT] "New SSH key added!"
│              [ALERT] "Unknown cron job detected!"
│
├─── DAY 3: You get alerts (BEFORE attacker can do damage)
│    - You: Kill processes, block attacker, patch vulnerability
│    - Attacker: Defeated before exfiltrating data
│
└─── What if HIDS wasn't there?
     [Day 10]: Attacker exfiltrates customer database
     [Day 20]: Attacker mines crypto
     [Day 45]: You finally notice
```

**HIDS buys you TIME - the most critical resource in incident response.**

---

# PART 2: PREREQUISITES

## Step 0.1: Check System Requirements

### Required

- **OS:** Linux (Debian/Ubuntu, RHEL/CentOS, etc.)
- **Permissions:** Root access (to read sensitive files)
- **Disk Space:** ~500MB for logs (adjust as needed)
- **Network:** Optional (for alerting, not required for detection)

### Check Your System
```bash
# Verify you're on Linux
uname -a

# Check available disk space
df -h /var/lib

# Verify root access
sudo whoami  # Should output: root
```

### Output Example
```
Linux myserver 5.10.0-8-amd64 #1 SMP Debian 5.10.46-5 x86_64 GNU/Linux
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       100G   45G   50G  50% /

root
```

✅ **If all above work, you're ready to proceed**

---

## Step 0.2: Understand the Directory Structure

The HIDS will create and use these locations:

```
/var/lib/hids/                    ← Main HIDS directory
├── alerts.log                    ← Threats detected (READ THIS DAILY)
├── scans.log                     ← Detailed scan output
└── baselines/                    ← Your "clean state" snapshot
    ├── passwd.sha256            ← Hash of /etc/passwd
    ├── shadow.sha256            ← Hash of /etc/shadow
    ├── sudoers.sha256           ← Hash of /etc/sudoers
    └── ... (more file hashes)

/usr/local/sbin/hids-scan        ← The HIDS script itself

/var/log/hids-cron.log           ← If running from cron (optional)
```

---

## Step 0.3: Verify Required Tools

HIDS uses standard Linux tools. Check if they're installed:

```bash
# Check for required tools
echo "Checking required tools..."

tools=("ps" "netstat" "grep" "awk" "sha256sum" "systemctl")

for tool in "${tools[@]}"; do
    if command -v $tool &> /dev/null; then
        echo "✓ $tool found"
    else
        echo "✗ $tool NOT found - please install"
    fi
done
```

### If Tools Are Missing

```bash
# For Debian/Ubuntu
sudo apt update
sudo apt install net-tools coreutils grep gawk

# For RHEL/CentOS
sudo yum install net-tools coreutils grep gawk
```

✅ **You're ready for installation**

---

# PART 3: PHASE 1 - INSTALLATION (30 minutes)

## Step 1.1: Verify System is Clean

⚠️ **CRITICAL:** You MUST baseline a clean, uncompromised system. If you're unsure, skip to Phase 6 first and check for intrusions.

```bash
# Quick sanity checks
echo "=== Quick Security Checks ==="

# Are there suspicious users?
echo "Current users:"
cut -d: -f1 /etc/passwd | grep -v "^root$\|^systemd\|^syslog"

# Are there unexpected processes?
echo "Running processes:"
ps aux | wc -l

# Any listening ports you don't recognize?
echo "Listening ports:"
sudo netstat -tulnp 2>/dev/null | grep LISTEN | awk '{print $4}'
```

**If you see anything suspicious, investigate FIRST before baselining.**

---

## Step 1.2: Create HIDS Directory Structure

```bash
# Create the directory that will hold all HIDS data
sudo mkdir -p /var/lib/hids/baselines

# Set appropriate permissions (root only)
sudo chmod 700 /var/lib/hids
sudo chmod 700 /var/lib/hids/baselines

# Verify
ls -la /var/lib/hids
```

**Expected Output:**
```
drwx------ 3 root root 4096 Jan 15 10:00 .
drwx------ 2 root root 4096 Jan 15 10:00 baselines
```

✅ **Directory structure created**

---

## Step 1.3: Download and Place HIDS Script

The HIDS scanner script needs to be in a system location.

```bash
# Option A: If you already have the script file
# Copy it from wherever you downloaded it:
sudo cp ./hids_scanner.sh /usr/local/sbin/hids-scan

# Option B: Create it manually (copy-paste the full script)
# The script is in the file "hids_scanner.sh"
# Copy its entire contents and paste into:
sudo nano /usr/local/sbin/hids-scan
# Then save (Ctrl+O, Enter, Ctrl+X)

# Make it executable
sudo chmod 755 /usr/local/sbin/hids-scan

# Verify it's there and executable
ls -la /usr/local/sbin/hids-scan
```

**Expected Output:**
```
-rwxr-xr-x 1 root root 28495 Jan 15 10:15 /usr/local/sbin/hids-scan
```

✅ **Script installed and ready**

---

## Step 1.4: Test the Script Works

Before doing anything real, test that the script runs without errors:

```bash
# Run in "test mode" - just prints help
sudo /usr/local/sbin/hids-scan --help

# Expected output:
# Usage: /usr/local/sbin/hids-scan [OPTION]
#   (no args)   Run full HIDS scan
#   --baseline  Create file integrity baseline
#   --help      Show this message
```

**If you get an error, check:**
1. Is the file readable? `sudo test -r /usr/local/sbin/hids-scan && echo "OK"`
2. Is bash available? `which bash`
3. Are there syntax errors? `bash -n /usr/local/sbin/hids-scan`

✅ **Script is functional**

---

# PART 4: PHASE 2 - CREATE BASELINE (15 minutes)

## What is a Baseline?

A **baseline** is a snapshot of your clean system. It's your reference point for "this is what normal looks like."

The baseline records:
- SHA256 hashes of critical files
- The "good state" you compare everything against
- Your security starting point

### Why This Matters

```
Day 1 (Baseline):  /etc/passwd hash = A1B2C3D4E5F6
Day 5 (After hack): /etc/passwd hash = X9Y8Z7W6V5U4
Day 5 (HIDS detects): "Hash mismatch! File was modified!"
Result: You catch the intrusion on day 5, not day 50
```

---

## Step 2.1: Ensure System is TRULY Clean

Before baselining, verify the system has no active intrusions.

```bash
# IMPORTANT: Run a quick security check first
echo "=== PRE-BASELINE SECURITY CHECK ==="

# 1. Check for suspicious processes
echo "1. Checking for processes in /tmp:"
ps aux | grep -v grep | grep '/tmp'
echo "   (Should be empty)"

# 2. Check /tmp for executables
echo -e "\n2. Checking /tmp for executables:"
find /tmp -type f -executable 2>/dev/null
echo "   (Should be empty or only expected files)"

# 3. Check for recent cron additions
echo -e "\n3. Checking recent cron jobs:"
grep -r "CRON" /var/log/syslog 2>/dev/null | tail -5
echo "   (Should be only legitimate jobs)"

# 4. Check recent SSH logins
echo -e "\n4. Recent SSH connections:"
lastlog -t 7  # Last 7 days
echo "   (Should match your actual usage)"

# 5. List all users
echo -e "\n5. All users on system:"
cut -d: -f1 /etc/passwd
echo "   (Should all be legitimate)"
```

**If you see anything suspicious, STOP here and investigate first.**

### If You Find Something Suspicious

See **Phase 6: Threat Response** - follow the playbook before proceeding.

---

## Step 2.2: Create the Baseline

Once you've confirmed the system is clean:

```bash
# Create baseline
echo "Creating baseline of clean system..."
sudo /usr/local/sbin/hids-scan --baseline

# Expected output:
# [2024-01-15 14:30:00] [INFO] Creating file integrity baseline...
# [2024-01-15 14:30:05] [INFO] Baseline created for critical files
```

---

## Step 2.3: Verify Baseline Was Created

```bash
# Check that baseline files exist
echo "Verifying baseline files..."
ls -la /var/lib/hids/baselines/

# You should see files like:
# - passwd.sha256
# - shadow.sha256
# - sudoers.sha256
# - bash.sha256
# - sh.sha256
# - sudo.sha256
```

**Expected Output:**
```
-rw-r--r-- 1 root root 65 Jan 15 14:30 passwd.sha256
-rw-r--r-- 1 root root 65 Jan 15 14:30 shadow.sha256
-rw-r--r-- 1 root root 65 Jan 15 14:30 sudoers.sha256
(... more files ...)
```

### Verify the Hash Format

```bash
# Look at what's in a baseline file
cat /var/lib/hids/baselines/passwd.sha256

# Expected format:
# a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0  /etc/passwd
```

✅ **Baseline successfully created - this is your clean state reference**

---

## Step 2.4: Document Your Baseline

Create a record of when and why you created this baseline:

```bash
# Record baseline information
sudo bash -c 'cat > /var/lib/hids/baseline_info.txt << EOF
HIDS Baseline Information
========================

Created: $(date)
System: $(hostname)
Kernel: $(uname -r)
User: $(whoami)
Reason: Initial system baseline - clean state

Current Users:
$(cut -d: -f1 /etc/passwd)

Current SSH Keys:
$(for user in $(cut -d: -f1 /etc/passwd); do
    ssh_keys="/home/$user/.ssh/authorized_keys"
    if [[ -f "$ssh_keys" ]]; then
        echo "User $user: $(wc -l < $ssh_keys) keys"
    fi
done)

Network Listening Ports:
$(netstat -tulnp 2>/dev/null | grep LISTEN | awk '{print $4}')

EOF'

# Verify it was created
sudo cat /var/lib/hids/baseline_info.txt
```

**This document helps you understand what was normal at baseline time.**

✅ **Baseline phase complete - you have your clean state snapshot**

---

# PART 5: PHASE 3 - FIRST SCAN & ANALYSIS (20 minutes)

## Step 3.1: Run Your First Scan

Now that you have a baseline, run the HIDS scanner and see what it detects:

```bash
# Run the full HIDS scan
echo "Starting first HIDS scan..."
sudo /usr/local/sbin/hids-scan

# This will take 2-5 minutes depending on system size
# You'll see output like:
# ╔═══════════════════════════════════╗
# ║     BASH HIDS - Scanning...       ║
# ╚═══════════════════════════════════╝
# === PROCESS MONITORING ===
# === FILE INTEGRITY CHECK ===
# ... more output ...
```

**This is normal - it's checking everything.**

---

## Step 3.2: Wait for Completion

The scan will complete and show a summary:

```
╔════════════════════════════════════════════════════════════╗
║                     SCAN SUMMARY                            ║
╚════════════════════════════════════════════════════════════╝
Total Alerts: 0
Alert Log: /var/lib/hids/alerts.log
Scan Log: /var/lib/hids/scans.log
[✓] No alerts detected in this scan.
```

**Explanation of output:**
- **Total Alerts:** Number of security concerns found
- **Alert Log:** File containing just the threats
- **Scan Log:** Detailed output of everything scanned

---

## Step 3.3: Review the Alert Log

The alert log is THE MOST IMPORTANT FILE - check it after every scan:

```bash
# View alerts from this scan
sudo cat /var/lib/hids/alerts.log

# If there are many lines, view just the recent ones
sudo tail -50 /var/lib/hids/alerts.log

# Or watch it in real-time if running a scan
sudo tail -f /var/lib/hids/alerts.log
```

### Understanding Alert Output

Each line in alerts.log looks like:
```
[2024-01-15 14:35:22] [CRITICAL] FILE INTEGRITY VIOLATION: /etc/passwd
[2024-01-15 14:35:23] [HIGH] Process running from /tmp: /tmp/bot
[2024-01-15 14:35:24] [MEDIUM] Backgrounded process detected: PID=5432
```

**Format breakdown:**
- `[2024-01-15 14:35:22]` = When it was detected
- `[CRITICAL]` = Severity level (CRITICAL > HIGH > MEDIUM)
- `FILE INTEGRITY VIOLATION: /etc/passwd` = What happened

---

## Step 3.4: Interpret the Results

### Scenario A: Zero Alerts (Most Likely)
```
Total Alerts: 0
[✓] No alerts detected in this scan.
```

**Meaning:** System appears clean. Good baseline created.  
**Action:** Continue to Phase 4 (Setup Automation)

### Scenario B: File Integrity Alerts

```
[CRITICAL] FILE INTEGRITY VIOLATION: /etc/passwd
```

**Meaning:** A critical file was modified since your baseline.  
**Possible Causes:**
1. ✅ Normal (you just updated something) → Update baseline
2. ⚠️ Suspicious (you didn't make changes) → Investigate

**How to investigate:**
```bash
# See what changed
diff <(cat /var/lib/hids/baselines/passwd.sha256) <(sha256sum /etc/passwd)

# If it really changed and you made the change:
sudo /usr/local/sbin/hids-scan --baseline  # Re-baseline

# If you don't know what changed:
# See Phase 6: Threat Response
```

### Scenario C: Process Alerts

```
[HIGH] Process running from /tmp: /tmp/suspicious_binary
```

**Meaning:** An executable in /tmp is running.  
**This is SUSPICIOUS** → See Phase 6: Threat Response

### Scenario D: Many Alerts (Something Wrong)

If you see dozens of alerts, something is likely wrong:

```bash
# See what processes triggered alerts
sudo grep "HIGH\|CRITICAL" /var/lib/hids/alerts.log | wc -l

# If more than 10 alerts, investigate
# Most likely causes:
# 1. System clock is wrong (affects timestamps)
# 2. Recent updates (files changed legitimately)
# 3. System is compromised (stop and investigate)
```

---

## Step 3.5: Document First Scan Results

Keep a record of your baseline scan:

```bash
# Save scan results for reference
sudo cp /var/lib/hids/alerts.log /var/lib/hids/baseline_scan_$(date +%Y%m%d).log
sudo cp /var/lib/hids/scans.log /var/lib/hids/baseline_detail_$(date +%Y%m%d).log

# View the record
ls -la /var/lib/hids/*baseline*
```

✅ **First scan complete - you know what "normal" looks like**

---

# PART 6: PHASE 4 - AUTOMATION SETUP (30 minutes)

Without automation, HIDS is just a manual tool. To be effective, it needs to run regularly.

## Choice: Cron vs Systemd Timer

### Option A: Simple Cron (Easier)
### Option B: Systemd Timer (Recommended)

Let's do Option B (systemd timer) as it's more modern and reliable.

---

## Step 4.1: Create Systemd Service File

The systemd service defines WHAT to run:

```bash
# Create the service file
sudo tee /etc/systemd/system/hids.service > /dev/null <<'EOF'
[Unit]
Description=HIDS Intrusion Detection Scanner
After=network.target
Documentation=man:systemd.service(5)

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/hids-scan
StandardOutput=journal
StandardError=journal
User=root

[Install]
WantedBy=multi-user.target
EOF

# Verify it was created
sudo cat /etc/systemd/system/hids.service
```

**What this does:**
- `Type=oneshot` = Run once and exit
- `ExecStart=/usr/local/sbin/hids-scan` = Run our HIDS script
- `StandardOutput=journal` = Log output to systemd journal
- `User=root` = Run as root (needed for system access)

---

## Step 4.2: Create Systemd Timer

The systemd timer defines WHEN to run:

```bash
# Create the timer file
sudo tee /etc/systemd/system/hids.timer > /dev/null <<'EOF'
[Unit]
Description=Run HIDS Intrusion Detection Scanner
Documentation=man:systemd.timer(5)

[Timer]
# Run 1 minute after boot
OnBootSec=1min

# Then every 5 minutes
OnUnitActiveSec=5min

# Spread execution randomly up to 1 minute
# (so multiple servers don't all scan at once)
AccuracySec=1min

[Install]
WantedBy=timers.target
EOF

# Verify it was created
sudo cat /etc/systemd/system/hids.timer
```

**What this does:**
- `OnBootSec=1min` = First scan 1 minute after system boots
- `OnUnitActiveSec=5min` = Then every 5 minutes
- `AccuracySec=1min` = Small random delay (okay to be off by 1 min)

### Scan Frequency Options

```
Every 5 minutes:   OnUnitActiveSec=5min      (High security, more logs)
Every 30 minutes:  OnUnitActiveSec=30min     (Balanced)
Every hour:        OnUnitActiveSec=1h        (Low overhead)
Every 4 hours:     OnUnitActiveSec=4h        (Minimal alerts)
Daily:             OnUnitActiveSec=1d        (Very light)
```

**Recommendation:** Start with every 5 minutes. Adjust if too noisy.

---

## Step 4.3: Enable and Start the Timer

```bash
# Tell systemd about the new service/timer
sudo systemctl daemon-reload

# Enable timer to run at boot
sudo systemctl enable hids.timer

# Start the timer now
sudo systemctl start hids.timer

# Check status
sudo systemctl status hids.timer
```

**Expected Output:**
```
● hids.timer - Run HIDS Intrusion Detection Scanner
   Loaded: loaded (/etc/systemd/system/hids.timer; enabled; vendor preset: enabled)
   Active: active (waiting) since Mon 2024-01-15 14:45:00 UTC
  Trigger: Mon 2024-01-15 14:50:00 UTC

Jan 15 14:45:00 myserver systemd[1]: Started HIDS timer.
```

✅ **Timer is active and will run automatically**

---

## Step 4.4: Verify Timer is Running

Check that the timer is actually executing:

```bash
# List all systemd timers
sudo systemctl list-timers

# Should show your HIDS timer:
# NEXT                         LEFT          LAST           PASSED UNIT
# Mon 2024-01-15 14:50:00 UTC  4min 30s      Mon 2024-01-15 14:45:00 UTC (n/a) hids.timer
```

Wait a few minutes, then check the logs:

```bash
# View HIDS timer logs
sudo journalctl -u hids.timer -n 20

# View HIDS service logs (the actual scan output)
sudo journalctl -u hids.service -n 50

# Follow logs in real-time
sudo journalctl -u hids.service -f
```

---

## Step 4.5: Alternative - Cron Setup (If You Prefer)

If you prefer cron instead of systemd timer:

```bash
# Edit root's crontab
sudo crontab -e

# Add one of these lines:

# Run every 5 minutes (high security)
*/5 * * * * /usr/local/sbin/hids-scan >> /var/log/hids-cron.log 2>&1

# Run every hour (moderate)
0 * * * * /usr/local/sbin/hids-scan >> /var/log/hids-cron.log 2>&1

# Run every 4 hours (light)
0 */4 * * * /usr/local/sbin/hids-scan >> /var/log/hids-cron.log 2>&1

# Save and exit (Ctrl+O, Enter, Ctrl+X if using nano)
```

**Check if cron job is set:**
```bash
sudo crontab -l
```

---

## Step 4.6: Verify Automation is Working

Wait for the next scheduled scan and verify it ran:

```bash
# Check if alerts.log was updated recently
ls -la /var/lib/hids/alerts.log

# The timestamp should be recent (within your scan interval)
# Example - if scanning every 5 minutes, timestamp should be < 5 min old

# View recent alert log
sudo tail -10 /var/lib/hids/alerts.log

# Check systemd logs
sudo journalctl -u hids.service --since "5 minutes ago"
```

✅ **Automation is working - HIDS now runs automatically**

---

# PART 7: PHASE 5 - DAILY OPERATIONS (ONGOING)

Now that HIDS is set up and automated, here's how to operate it day-to-day.

## Step 5.1: Daily Alert Review (2 minutes)

**Every morning, check for alerts:**

```bash
# View all alerts since yesterday
sudo tail -100 /var/lib/hids/alerts.log

# Or see just the new ones since last check
sudo tail -20 /var/lib/hids/alerts.log

# Count alerts
sudo wc -l /var/lib/hids/alerts.log
```

### Alert Severity Guide

| Level | Color | Meaning | Action |
|-------|-------|---------|--------|
| **CRITICAL** | 🔴 Red | IMMEDIATE THREAT | Stop everything, investigate NOW |
| **HIGH** | 🟠 Orange | Likely threat | Investigate within hours |
| **MEDIUM** | 🔵 Blue | Unusual activity | Monitor, investigate when time permits |

**Example:**
```
[2024-01-15 06:23:45] [CRITICAL] FILE INTEGRITY VIOLATION: /etc/passwd
→ IMMEDIATE: Stop and investigate

[2024-01-15 06:24:12] [HIGH] Process running from /tmp: /tmp/bot
→ URGENT: Investigate within an hour

[2024-01-15 06:25:00] [MEDIUM] Backgrounded process detected
→ NORMAL: Check when you have time
```

---

## Step 5.2: Handle Legitimate Changes

Systems change. When you make legitimate changes (updates, configuration changes), HIDS will alert. Mark these as "OK":

### Scenario: You Updated System Packages

```bash
# HIDS alerts: File integrity violations
# You: "I just ran apt update/upgrade"
# Action: Re-baseline

sudo /usr/local/sbin/hids-scan --baseline

# HIDS will re-record new file hashes
# Next scan won't alert on those files
```

### Scenario: You Changed Password Policy

```bash
# HIDS alerts: /etc/shadow changed
# You: "I changed password expiration"
# Action: Re-baseline

sudo /usr/local/sbin/hids-scan --baseline

# New baseline is created with updated /etc/shadow
```

**Remember:** Always re-baseline after legitimate system changes.

---

## Step 5.3: Keep Alert Logs

Archive old logs so they don't grow too large:

```bash
# Archive logs older than 30 days
find /var/lib/hids -name "alerts.log" -mtime +30 -exec gzip {} \;

# Verify archive
ls -la /var/lib/hids/

# View archived logs if needed
gunzip /var/lib/hids/alerts.log.gz
cat /var/lib/hids/alerts.log.gz  # won't work until unzipped
```

Or set up automatic rotation:

```bash
# Create logrotate config
sudo tee /etc/logrotate.d/hids > /dev/null <<EOF
/var/lib/hids/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0600 root root
}
EOF

# Test logrotate
sudo logrotate -d /etc/logrotate.d/hids
```

---

## Step 5.4: Monitor HIDS Itself

Ensure HIDS keeps running:

```bash
# Check if timer is still active
sudo systemctl is-active hids.timer
# Should output: active

# Check if service ran recently
sudo systemctl status hids.service

# See if timer has upcoming executions
sudo systemctl list-timers hids.timer
```

If timer stops running, restart it:

```bash
# Restart the timer
sudo systemctl restart hids.timer

# Re-enable if needed
sudo systemctl enable hids.timer
```

---

## Step 5.5: Weekly Review (30 minutes)

Once a week, do a deeper analysis:

```bash
# This week's alerts
echo "=== This Week's Alerts ===" 
sudo journalctl -u hids.service --since "7 days ago" > /tmp/weekly_hids.txt
sudo cat /tmp/weekly_hids.txt

# Count by severity
echo "=== CRITICAL alerts ===" 
sudo grep CRITICAL /var/lib/hids/alerts.log | wc -l

echo "=== HIGH alerts ===" 
sudo grep HIGH /var/lib/hids/alerts.log | wc -l

echo "=== MEDIUM alerts ===" 
sudo grep MEDIUM /var/lib/hids/alerts.log | wc -l

# Patterns to look for
echo "=== Process violations ===" 
sudo grep "Process running\|running from /tmp" /var/lib/hids/alerts.log | wc -l

echo "=== File violations ===" 
sudo grep "FILE INTEGRITY VIOLATION" /var/lib/hids/alerts.log | wc -l

echo "=== User violations ===" 
sudo grep "New.*account\|New home directory\|SSH key" /var/lib/hids/alerts.log | wc -l
```

**What to look for:**
- 🚨 Same alert repeating = Misconfiguration or persistent threat
- 🚨 New pattern of alerts = New activity
- ✅ Decreasing alerts = System stabilizing
- ✅ Only expected alerts = All good

---

## Step 5.6: Performance Check

HIDS shouldn't slow down your system. Check overhead:

```bash
# Monitor system during a scan
watch -n 1 'ps aux | grep hids'

# Check disk usage
du -sh /var/lib/hids

# If logs are too large, archive them
du -sh /var/lib/hids/scans.log
# If > 100MB, it's too large, reduce scan frequency or increase rotation
```

---

# PART 8: PHASE 6 - THREAT RESPONSE (WHEN NEEDED)

When HIDS detects something, you need to respond appropriately.

## Decision Matrix: Is This a Real Threat?

```
Alert Type          Suspicious?         Action
────────────────────────────────────────────────────
File mod            Did YOU change it?  NO → Investigate
                                        YES → Re-baseline

New user            Is this expected?   NO → THREAT!
                                        YES → Re-baseline

SSH key added       Did YOU add it?     NO → THREAT!
                                        YES → Re-baseline

Process in /tmp     Do you recognize?   NO → THREAT!
                                        YES → Monitor

Rootkit detected    Almost always       CRITICAL THREAT!
                    malicious           Emergency response

Port listening      Is it yours?        NO → Investigate
                                        YES → OK
```

---

## Alert Type 1: File Integrity Violation

### Alert Example
```
[CRITICAL] FILE INTEGRITY VIOLATION: /etc/passwd
```

### Investigation Steps

```bash
# Step 1: What changed?
sudo diff <(cat /var/lib/hids/baselines/passwd.sha256) <(sha256sum /etc/passwd)

# Step 2: Look at the file
sudo head -20 /etc/passwd

# Step 3: Are there new users?
sudo getent passwd | tail -5

# Step 4: Check when it changed
sudo stat /etc/passwd | grep Modify

# Step 5: Who has root privileges?
sudo awk -F: '$3 == 0 {print $1}' /etc/passwd

# Step 6: Check logs for user additions
sudo grep "useradd\|usermod" /var/log/auth.log | tail -10
```

### Decision

- ✅ **You made the change** → Re-baseline
  ```bash
  sudo /usr/local/sbin/hids-scan --baseline
  ```

- ❌ **You didn't make changes + unknown user found** → INTRUSION DETECTED
  ```bash
  # See "Responding to Active Intrusion" below
  ```

---

## Alert Type 2: Suspicious Process from /tmp

### Alert Example
```
[HIGH] Process running from /tmp: /tmp/bot
```

### Investigation Steps

```bash
# Step 1: Find the process
ps aux | grep '/tmp'

# Step 2: Get the full process info
ps -p <PID> -o pid,user,cmd,etime

# Step 3: What files is it accessing?
sudo lsof -p <PID> 2>/dev/null | head -20

# Step 4: What network connections?
sudo netstat -tulnp 2>/dev/null | grep <PID>

# Step 5: When did it start?
stat /proc/<PID>

# Step 6: What files are in /tmp?
ls -la /tmp | grep -v "^d"

# Step 7: Is it malicious? (check hash if you can)
file /tmp/<suspicious_file>
strings /tmp/<suspicious_file> | head -20
```

### Decision

- ✅ **It's something you ran** → Monitor, no action needed
- ❌ **Unknown executable from /tmp** → INTRUSION DETECTED
  ```bash
  # See "Responding to Active Intrusion" below
  ```

---

## Alert Type 3: New User Account

### Alert Example
```
[HIGH] New home directory detected: /home/attacker
```

### Investigation Steps

```bash
# Step 1: List all users
sudo cut -d: -f1 /etc/passwd

# Step 2: Check new user details
sudo getent passwd attacker

# Step 3: Check when it was added
sudo stat /home/attacker

# Step 4: What shell does it have?
sudo grep "^attacker" /etc/passwd

# Step 5: Has anyone logged in as this user?
sudo last | grep attacker

# Step 6: What's in their home directory?
sudo ls -la /home/attacker
```

### Decision

- ✅ **You created this user** → Re-baseline
- ❌ **You didn't create this + no legitimate reason** → INTRUSION DETECTED
  ```bash
  # See "Responding to Active Intrusion" below
  ```

---

## Alert Type 4: Rootkit Detected

### Alert Example
```
[CRITICAL] POSSIBLE ROOTKIT DETECTED: diamorphine
```

### This is IMMEDIATE Emergency

Rootkit = Kernel-level compromise = System is deeply compromised

```bash
# Step 1: Verify the module
sudo lsmod | grep diamorphine

# Step 2: Do NOT try to unload (rootkit will protect itself)
# rootkit typically blocks removal with:
sudo rmmod diamorphine
# (This will likely fail or cause system issues)

# Step 3: Document everything
sudo journalctl > /tmp/logs_before_cleanup.txt
cp /var/lib/hids /tmp/hids_backup

# Step 4: IMMEDIATE ACTIONS REQUIRED:
# - Isolate system from network: unplug ethernet
# - Do not trust any data on this system
# - This system needs to be rebuilt

# Step 5: Get expert help
# Contact your incident response team - this is beyond self-help
```

**⚠️ DO NOT try to clean this yourself - seek professional help.**

---

## Responding to Active Intrusion

If HIDS detected an actual intrusion, follow this playbook:

### Phase 1: Containment (First 5 minutes)

```bash
# Step 1: Isolate the system
# PHYSICAL: Unplug ethernet cable (disconnect from network)
# This prevents attacker from escaping with data or attacking other systems

echo "System isolated from network - continue investigation"

# Step 2: Kill suspicious processes
# Example: Process found in /tmp
ps aux | grep '/tmp'
sudo kill -9 <PID>  # Kill it

# Example: Unknown SSH session
who  # See who's logged in
# Note: Attacker may have a hidden session, killing may not help

# Step 3: Block suspicious ports
sudo ufw deny 4444  # Block backdoor port
sudo ufw deny 5555
sudo firewall-cmd --add-rich-rule='rule port port=4444 protocol=tcp drop'

# Step 4: Document what you found
cat /var/lib/hids/alerts.log > /tmp/incident_alerts.txt
```

### Phase 2: Investigation (Next hour)

```bash
# Step 5: Preserve logs
sudo cp -r /var/lib/hids /tmp/hids_incident_backup
sudo cp /var/log/auth.log /tmp/auth.log.backup
sudo cp /var/log/syslog /tmp/syslog.backup

# Step 6: Find all suspicious artifacts
find / -name "*<attacker_name>*" 2>/dev/null > /tmp/attacker_files.txt
find / -type f -newermt "2 hours ago" ! -path "/proc/*" 2>/dev/null > /tmp/recent_files.txt

# Step 7: Check what was accessed
sudo lastb  # Failed logins
sudo last   # All logins
sudo grep "sudo" /var/log/auth.log | tail -20

# Step 8: List all persistence mechanisms
sudo crontab -l
sudo systemctl list-unit-files | grep enabled
ls -la /etc/init.d/

# Step 9: Check system integrity
sudo dpkg -V  # Debian - check if packages modified
rpm -V       # RHEL - check if packages modified
```

### Phase 3: Decision - Clean or Rebuild?

```
Two options:

Option A: Attempt Cleanup (Risky)
├─ Remove malicious users, cron jobs, binaries
├─ Requires expert forensics knowledge
├─ Risk: Might miss persistence, attacker returns
└─ Time: Days of investigation

Option B: Rebuild from Scratch (Safest)
├─ Back up legitimate data
├─ Wipe OS and reinstall clean
├─ Restore only necessary data
├─ Risk: Low - everything is fresh
└─ Time: Hours to days
```

**Recommendation: REBUILD (Option B) for compromise involving:**
- Rootkits
- Modified system binaries
- Root-level access
- Persistence mechanisms

---

### Phase 4: Recovery

If you choose cleanup:

```bash
# Remove the compromised user
sudo userdel -r attacker

# Remove suspicious cron jobs
sudo crontab -e
# (Remove any suspicious lines)

# Remove SSH keys
sudo rm /root/.ssh/authorized_keys  # Remove any unknown keys
for user in $(cut -d: -f1 /etc/passwd); do
    sudo rm /home/$user/.ssh/authorized_keys 2>/dev/null
done

# Stop suspicious services
sudo systemctl disable <malicious_service>
sudo systemctl stop <malicious_service>

# Remove temporary files
sudo rm /tmp/bot 2>/dev/null
sudo rm /tmp/malware 2>/dev/null

# Create new baseline after cleanup
sudo /usr/local/sbin/hids-scan --baseline

# Continue monitoring
sudo /usr/local/sbin/hids-scan
```

---

## If You Choose to Rebuild

```bash
# Step 1: Backup legitimate data
# Copy only what you need (documents, configs, not binaries)
sudo tar czf /external/backup.tar.gz /home /etc/myapp/config

# Step 2: Boot from installation media
# Insert Ubuntu/Debian/CentOS install USB

# Step 3: Wipe the disk
# During installation, choose "Erase disk"

# Step 4: Fresh installation
# Follow normal installation steps

# Step 5: Install HIDS again on clean system
# Follow Phase 1-4 from this guide

# Step 6: Restore only legitimate data
sudo tar xzf /external/backup.tar.gz -C /

# Step 7: Close the vulnerability
# Apply patches, update software, secure configuration
```

---

# PART 9: TROUBLESHOOTING & MAINTENANCE

## Common Issues and Solutions

### Issue 1: "Too Many Alerts"

**Symptom:**
```
Total Alerts: 847
[Alert] ... [Alert] ... [Alert] ...
```

**Cause:**
- System just updated (files changed)
- Scan frequency too high
- System is actually compromised

**Solution:**

```bash
# If you just updated:
sudo apt update && sudo apt upgrade
sudo /usr/local/sbin/hids-scan --baseline

# If alerts keep coming, reduce scan frequency
sudo systemctl edit hids.timer
# Change: OnUnitActiveSec=5min → OnUnitActiveSec=1h
sudo systemctl daemon-reload
sudo systemctl restart hids.timer

# If this is a real intrusion:
# Review Phase 6: Threat Response
```

---

### Issue 2: "HIDS Scanner Not Running"

**Symptom:**
```
Total Alerts: 0 (for several hours - no scans happening)
```

**Check:**
```bash
# Is the timer active?
sudo systemctl status hids.timer

# When is the next run?
sudo systemctl list-timers hids.timer

# Are there errors?
sudo journalctl -u hids.service -n 50
```

**Fix:**
```bash
# Restart the timer
sudo systemctl restart hids.timer

# Or if completely broken, recreate it
sudo systemctl stop hids.timer
sudo rm /etc/systemd/system/hids.*
# Then follow Step 4.1-4.3 again
```

---

### Issue 3: "Permission Denied"

**Symptom:**
```
/usr/local/sbin/hids-scan: Permission denied
```

**Fix:**
```bash
# Make the script executable
sudo chmod 755 /usr/local/sbin/hids-scan

# Verify
ls -la /usr/local/sbin/hids-scan
# Should show: -rwxr-xr-x
```

---

### Issue 4: "Disk Space Error"

**Symptom:**
```
/var/lib/hids: No space left on device
```

**Fix:**
```bash
# See how much space logs are using
du -sh /var/lib/hids

# Archive old logs
sudo journalctl -u hids.service --rotate
sudo journalctl -u hids.service --vacuum-time=7d

# Or delete manually
sudo rm /var/lib/hids/scans.log
sudo touch /var/lib/hids/scans.log
sudo chmod 600 /var/lib/hids/scans.log

# Reduce log verbosity
# Edit hids.service to use /dev/null for output
```

---

### Issue 5: "Script Has Syntax Error"

**Symptom:**
```
/usr/local/sbin/hids-scan: line 42: syntax error near unexpected token
```

**Fix:**
```bash
# Check the script for errors
bash -n /usr/local/sbin/hids-scan

# If error found, verify the entire script is intact
wc -l /usr/local/sbin/hids-scan
# Should be ~500+ lines

# If too short, the script got corrupted during copy
# Download and reinstall it
```

---

## Maintenance Schedule

### Daily
- ✅ Review alerts log
- ✅ Check for CRITICAL/HIGH alerts
- ✅ Respond to any threats

### Weekly
- ✅ Review alert patterns
- ✅ Check system performance impact
- ✅ Verify timer is still running

### Monthly
- ✅ Archive old logs
- ✅ Review HIDS configuration
- ✅ Test alert response procedures
- ✅ Update baseline if major changes made

### Quarterly
- ✅ Review effectiveness (are we catching real threats?)
- ✅ Tune alert sensitivity if needed
- ✅ Update HIDS script if new version available
- ✅ Audit who has access to logs

### Yearly
- ✅ Full security review
- ✅ Rebuild/update HIDS configuration
- ✅ Re-baseline clean system
- ✅ Train team on threat response

---

## Monitoring HIDS Health

Create a simple health check:

```bash
# Create health check script
sudo tee /usr/local/bin/check-hids.sh > /dev/null <<'EOF'
#!/bin/bash

echo "=== HIDS Health Check ==="

# Check 1: Timer running?
if sudo systemctl is-active hids.timer &>/dev/null; then
    echo "✓ Timer is active"
else
    echo "✗ Timer is NOT running - restarting..."
    sudo systemctl start hids.timer
fi

# Check 2: Script exists?
if [[ -x /usr/local/sbin/hids-scan ]]; then
    echo "✓ Script exists and is executable"
else
    echo "✗ Script missing or not executable"
fi

# Check 3: Logs being created?
if [[ -f /var/lib/hids/alerts.log ]]; then
    last_modified=$(stat -c%Y /var/lib/hids/alerts.log)
    now=$(date +%s)
    age=$((now - last_modified))
    
    if [[ $age -lt 600 ]]; then  # Less than 10 minutes old
        echo "✓ Scans are running (last run $age seconds ago)"
    else
        echo "✗ Scans haven't run in $age seconds"
    fi
else
    echo "✗ Alert log doesn't exist"
fi

# Check 4: Recent alerts?
alert_count=$(sudo grep -c "CRITICAL\|HIGH" /var/lib/hids/alerts.log 2>/dev/null || echo 0)
echo "✓ Total alerts: $alert_count"

echo "=== Health Check Complete ==="
EOF

sudo chmod +x /usr/local/bin/check-hids.sh

# Run the health check
sudo /usr/local/bin/check-hids.sh
```

---

## Backup Your Configuration

```bash
# Backup HIDS configuration
sudo tar czf /root/hids_backup_$(date +%Y%m%d).tar.gz \
    /var/lib/hids \
    /usr/local/sbin/hids-scan \
    /etc/systemd/system/hids.*

# Keep backups for 90 days
find /root -name "hids_backup_*.tar.gz" -mtime +90 -delete
```

---

# FINAL CHECKLIST

Before you declare HIDS ready for production:

## Pre-Deployment Checklist
- ☐ System is clean (verified in Phase 2)
- ☐ HIDS script installed and executable
- ☐ Baseline created (`/var/lib/hids/baselines/*` exists)
- ☐ First scan ran successfully
- ☐ Systemd timer or cron configured
- ☐ Automation verified running

## Day 1 After Deployment
- ☐ Check alerts every hour
- ☐ Verify timer/cron is running
- ☐ Review alert log
- ☐ Re-baseline any legitimate changes
- ☐ Test response procedure with test alert

## Week 1
- ☐ Daily alert reviews (no major issues)
- ☐ System performing normally
- ☐ Logs are being created regularly
- ☐ Team trained on how to respond
- ☐ Documentation complete

## Month 1
- ☐ Pattern of "normal" established
- ☐ Any legitimate false alarms handled
- ☐ Confidence in baseline high
- ☐ Logs archived and rotated
- ☐ Considered additional hardening

## Ready for Production
- ☐ HIDS running smoothly
- ☐ Team confident in alerts
- ☐ Response procedures tested
- ☐ Logging verified
- ☐ Backup strategy in place

---

# CONCLUSION

You now have a complete, automated Host Intrusion Detection System that:

✅ **Runs continuously** - Scans every 5 minutes automatically  
✅ **Detects intruders** - Inside your system before they cause damage  
✅ **Alerts you** - To suspicious activity with clear severity levels  
✅ **Helps you respond** - With playbooks for different threat types  
✅ **Is maintainable** - Simple bash scripts, standard Linux tools  

## Remember

**HIDS is not perfect**, but it's essential:
- ✅ Catches obvious intrusions quickly
- ✅ Detects persistence mechanisms
- ✅ Finds compromised accounts and files
- ❌ Can't prevent breaches from happening
- ❌ Can't stop determined attackers who disable it
- ❌ Works best as part of defense-in-depth

## The Key to Success

**Daily monitoring.** 5 minutes a day checking your alerts.

That's it. If you commit to reviewing `/var/lib/hids/alerts.log` every morning, you will catch intrusions that would otherwise go undetected for months.

---

## Questions to Ask Yourself

- 🤔 "Do I understand what my baseline contains?"
- 🤔 "Can I interpret HIDS alerts correctly?"
- 🤔 "Do I know what to do if I find a real threat?"
- 🤔 "Is my automation running?"
- 🤔 "Have I practiced responding to a fake intrusion?"

If you answered YES to all, you're ready.

**Now go find them before they find you. 🛡️**

---

# QUICK REFERENCE CARD

Print this and keep it by your desk:

```
┌─────────────────────────────────────────────────┐
│           HIDS QUICK REFERENCE                  │
├─────────────────────────────────────────────────┤
│ CHECK ALERTS                                    │
│ $ sudo tail -20 /var/lib/hids/alerts.log       │
│                                                 │
│ VERIFY AUTOMATION                               │
│ $ sudo systemctl list-timers hids.timer         │
│                                                 │
│ RUN MANUAL SCAN                                │
│ $ sudo /usr/local/sbin/hids-scan               │
│                                                 │
│ CREATE NEW BASELINE                            │
│ $ sudo /usr/local/sbin/hids-scan --baseline    │
│                                                 │
│ VIEW SYSTEM LOGS                               │
│ $ sudo journalctl -u hids.service -n 50        │
│                                                 │
│ RESTART AUTOMATION                             │
│ $ sudo systemctl restart hids.timer            │
│                                                 │
│ ALERT SEVERITY                                  │
│ CRITICAL = Stop everything, investigate NOW    │
│ HIGH = Investigate within hours                │
│ MEDIUM = Monitor, check when time permits      │
└─────────────────────────────────────────────────┘
```

---

**Version:** 1.0  
**Last Updated:** January 2024  
**Status:** Ready for Production  

**For questions or issues, refer back to the relevant Phase section of this guide.**
