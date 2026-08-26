# HIDS - Host Intrusion Detection System
## A Bash-Based Security Monitoring Tool

**What is HIDS?**

HIDS is a Host Intrusion Detection System that monitors your Linux server for security threats and anomalies. It continuously watches for signs of intrusion, unauthorized access, and system compromise — then alerts you immediately when something suspicious happens.

Think of it as a security guard inside your system that never sleeps and never misses details.

---

## Table of Contents

1. [Quick Start (5 minutes)](#quick-start)
2. [What It Monitors](#what-it-monitors)
3. [Installation](#installation)
4. [Running HIDS](#running-hids)
5. [Understanding Alerts](#understanding-alerts)
6. [Configuration](#configuration)
7. [Daily Operations](#daily-operations)
8. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Prerequisites
- Linux system (Debian, Ubuntu, CentOS, RHEL, etc.)
- Root access
- 500MB disk space for logs

### Install (One command)

```bash
# Download and install
sudo bash -c 'cp hids /usr/local/sbin/hids && chmod 755 /usr/local/sbin/hids && mkdir -p /var/lib/hids'

# Create baseline of your clean system
sudo hids --baseline

# Run first scan
sudo hids

# View alerts
sudo tail -20 /var/lib/hids/alerts.log
```

### Set Up Automatic Scanning

```bash
# Add to root's crontab (runs every 5 minutes)
sudo crontab -e

# Paste this line:
*/5 * * * * /usr/local/sbin/hids >> /var/log/hids.log 2>&1
```

That's it. HIDS is now running and monitoring your system automatically.

---

## What It Monitors

### 1. **System Health**
Is your server healthy, or is it under attack/overloaded?

Checks:
- CPU load average (is the system overworked?)
- Memory usage (is RAM exhausted?)
- Disk usage (is storage full?)
- Process count (normal or fork bomb?)
- Open files/network connections (DOS attack?)

Alert Triggers:
- 🔴 CRITICAL: CPU load >4x cores, memory >95% full, disk >95% full
- 🟠 HIGH: CPU load >2x cores, memory >80% full, disk >80% full
- 🔵 MEDIUM: High resource usage

### 2. **User Activity**
Who's accessing your system and is it suspicious?

Checks:
- Currently logged-in users
- Recent login history
- Failed login attempts (brute force?)
- New user accounts created
- Unexpected SSH keys added
- Privilege escalation attempts (sudo)

Alert Triggers:
- 🔴 CRITICAL: New root-level account created
- 🔴 CRITICAL: SSH key added to authorized_keys
- 🟠 HIGH: 5+ failed logins in 5 minutes (brute force)
- 🟠 HIGH: Login from unusual IP/time
- 🔵 MEDIUM: Sudo usage outside normal hours

### 3. **Processes & Network**
What's running on your system and where is it connecting?

Checks:
- All running processes
- Parent-child process relationships
- Listening ports and network connections
- Process location (is it in /tmp? Suspicious!)
- Process owner (is httpd running as root? Suspicious!)
- Open network connections and destinations

Alert Triggers:
- 🔴 CRITICAL: Process running from /tmp
- 🔴 CRITICAL: Rootkit module detected
- 🟠 HIGH: Listening on backdoor port (4444, 5555, etc.)
- 🟠 HIGH: Process with suspicious name
- 🔵 MEDIUM: High network connection count

### 4. **File Integrity**
Have critical system files been modified?

Checks:
- `/etc/passwd` (user accounts)
- `/etc/shadow` (password hashes)
- `/etc/sudoers` (who can use sudo?)
- `/root/.ssh/authorized_keys` (SSH access)
- System binaries (`/bin/bash`, `/usr/bin/sudo`)
- File permissions (are they dangerous?)

Alert Triggers:
- 🔴 CRITICAL: Password file modified
- 🔴 CRITICAL: System binary modified
- 🟠 HIGH: Permissions changed on critical file
- 🟠 HIGH: SSH key added

### 5. **Alerting System**
All alerts are logged persistently with severity levels and timestamps.

Output Format:
```
[2024-01-15 14:32:10] [CRITICAL] FILE_INTEGRITY: /etc/passwd modified (hash mismatch)
[2024-01-15 14:33:45] [HIGH] PROCESS_ANOMALY: Process /tmp/bot running as root
[2024-01-15 14:34:22] [MEDIUM] SYSTEM_HEALTH: Memory usage 85%
```

---

## Installation

### Step 1: Verify Your System

```bash
# Check you're on Linux
uname -a

# Check disk space
df -h /

# Verify root access
sudo whoami  # Should output: root
```

### Step 2: Copy HIDS Script

```bash
# If you have the script file:
sudo cp hids /usr/local/sbin/hids
sudo chmod 755 /usr/local/sbin/hids

# Verify it's installed
ls -la /usr/local/sbin/hids
```

### Step 3: Create Directory Structure

```bash
# HIDS will create these directories, but you can pre-create them:
sudo mkdir -p /var/lib/hids/baseline
sudo chmod 700 /var/lib/hids
sudo mkdir -p /var/log
```

### Step 4: Test It Works

```bash
# Try running HIDS
sudo /usr/local/sbin/hids --help

# You should see:
# Usage: /usr/local/sbin/hids [OPTION]
#   (no args)   Run full HIDS scan
#   --baseline  Create file integrity baseline
#   --help      Show this message
```

✅ **Installation complete**

---

## Running HIDS

### Manual Scan

```bash
# Run a full scan once
sudo /usr/local/sbin/hids

# Takes 1-5 minutes depending on system size
# Outputs alerts to: /var/lib/hids/alerts.log
```

### Automatic Scanning (Recommended)

#### Option A: Cron Job (Simple)

```bash
# Edit root's crontab
sudo crontab -e

# Add one of these lines:

# Every 5 minutes (high security)
*/5 * * * * /usr/local/sbin/hids >> /var/log/hids-cron.log 2>&1

# Every hour (moderate)
0 * * * * /usr/local/sbin/hids >> /var/log/hids-cron.log 2>&1

# Every 4 hours (low overhead)
0 */4 * * * /usr/local/sbin/hids >> /var/log/hids-cron.log 2>&1

# Save and exit (Ctrl+O, Enter, Ctrl+X in nano)
```

Verify it's set:
```bash
sudo crontab -l
# Should show your cron job
```

#### Option B: Systemd Timer (Modern)

```bash
# Create service file
sudo tee /etc/systemd/system/hids.service > /dev/null <<'EOF'
[Unit]
Description=HIDS Intrusion Detection Scanner
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/hids
User=root

[Install]
WantedBy=multi-user.target
EOF

# Create timer (runs every 5 minutes)
sudo tee /etc/systemd/system/hids.timer > /dev/null <<'EOF'
[Unit]
Description=HIDS Scanner Timer
Requires=hids.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable hids.timer
sudo systemctl start hids.timer

# Verify it's running
sudo systemctl list-timers hids.timer
```

### Creating Initial Baseline

⚠️ **IMPORTANT:** Baseline on a clean system before anything is compromised.

```bash
# Before creating baseline, verify system is clean:
echo "Checking for suspicious activity..."
ps aux | grep -E '/tmp|suspicious'  # Should be empty
sudo netstat -tulnp | grep LISTEN   # Should only show expected ports
sudo cut -d: -f1 /etc/passwd        # Should only show expected users

# If all looks good, create baseline:
sudo /usr/local/sbin/hids --baseline

# This records:
# - Hashes of critical files
# - Current users and groups
# - Current processes and ports
# - File permissions
# - System health metrics

# Later scans will compare against this baseline
```

---

## Understanding Alerts

### Alert Severity Levels

| Level | Color | Meaning | Action |
|-------|-------|---------|--------|
| **CRITICAL** | 🔴 Red | Immediate threat | Stop everything and investigate NOW |
| **HIGH** | 🟠 Orange | Likely threat | Investigate within an hour |
| **MEDIUM** | 🔵 Blue | Unusual activity | Monitor and investigate when possible |
| **INFO** | ⚪ Gray | Informational | FYI, no action usually needed |

### Reading the Alert Log

```bash
# View all alerts since installation
sudo cat /var/lib/hids/alerts.log

# View just the latest alerts
sudo tail -50 /var/lib/hids/alerts.log

# View only CRITICAL alerts
sudo grep CRITICAL /var/lib/hids/alerts.log

# View alerts from the last hour
sudo tail -f /var/lib/hids/alerts.log  # Follow in real-time
```

### Alert Examples

**CRITICAL Alert - File Integrity Violation**
```
[2024-01-15 10:23:45] [CRITICAL] FILE_INTEGRITY_VIOLATION: /etc/passwd
Baseline hash: a1b2c3d4e5f6...
Current hash:  x9y8z7w6v5u4...
Status: FILE WAS MODIFIED - INVESTIGATE IMMEDIATELY
```
**What it means:** Someone modified the user accounts file. Could be a backdoor account.  
**What to do:** Check `/etc/passwd` for new users, look in auth logs for who made the change.

**HIGH Alert - Suspicious Process**
```
[2024-01-15 10:25:12] [HIGH] PROCESS_ANOMALY: Process running from /tmp
Process: /tmp/malware
PID: 5432
Owner: root
Status: UNUSUAL - processes shouldn't run from /tmp
```
**What it means:** Executable in /tmp is running. Malware typically hides here.  
**What to do:** Kill the process, investigate what it is, remove the file, check logs for how it got there.

**HIGH Alert - Failed Login Attempts**
```
[2024-01-15 10:27:33] [HIGH] LOGIN_ANOMALY: Brute force attempt detected
Failed attempts: 15 in 5 minutes
Source IP: 203.0.113.50
Target user: root
Status: ATTACK IN PROGRESS
```
**What it means:** Someone is trying to guess your password.  
**What to do:** Block that IP, force password change, enable SSH key-only auth.

**MEDIUM Alert - High Resource Usage**
```
[2024-01-15 10:29:01] [MEDIUM] SYSTEM_HEALTH: High memory usage
Memory usage: 87% (normal: <80%)
Free memory: 2.1GB
Status: INVESTIGATING
```
**What it means:** System is low on RAM. Could be attack or just heavy usage.  
**What to do:** Check what's using memory with `top`, see if it's normal or an app misbehaving.

### False Positives (Alerts You Can Ignore)

Sometimes HIDS alerts on things you intentionally changed:

```bash
# You just installed updates → files modified
# Solution: Re-baseline
sudo /usr/local/sbin/hids --baseline

# You just added a new user account → new user detected
# Solution: Re-baseline after making legitimate changes

# You're running backups → high disk I/O
# Solution: Ignore or add to whitelist
```

---

## Configuration

### Config File Location

```
/var/lib/hids/hids.conf
```

### Editable Settings

```bash
# System Health Thresholds
CPU_LOAD_WARNING=2.0          # Relative to number of cores
CPU_LOAD_CRITICAL=4.0
MEMORY_USED_WARNING=80        # Percentage
MEMORY_USED_CRITICAL=95
DISK_USED_WARNING=80
DISK_USED_CRITICAL=95

# User Activity
FAILED_LOGIN_THRESHOLD=5      # Failed attempts before alert
FAILED_LOGIN_WINDOW_MINUTES=5 # Within this time window

# Network Monitoring
SUSPICIOUS_PORTS="4444 5555 6666 7777 8888 31337"
SUSPICIOUS_PROCESS_LOCATIONS="/tmp /var/tmp /dev/shm"

# Files to Monitor for Integrity
MONITORED_FILES="/etc/passwd /etc/shadow /etc/sudoers /root/.ssh/authorized_keys /bin/bash /usr/bin/sudo"

# Alert Settings
ALERT_LOG="/var/lib/hids/alerts.log"
SCAN_LOG="/var/lib/hids/scans.log"
BASELINE_DIR="/var/lib/hids/baseline"
LOG_LEVEL="INFO"  # INFO, WARNING, CRITICAL

# Email Alerts (optional)
ENABLE_EMAIL_ALERTS="no"
EMAIL_RECIPIENT="admin@example.com"
```

### How to Change Configuration

```bash
# Edit the config file
sudo nano /var/lib/hids/hids.conf

# Make changes (increase thresholds, add files to monitor, etc.)

# Save (Ctrl+O, Enter, Ctrl+X in nano)

# Restart HIDS for changes to take effect
sudo crontab -e  # If using cron
# or
sudo systemctl restart hids.timer  # If using systemd
```

### Example: Adjusting Thresholds

If you're getting too many "high memory" alerts:

```bash
# Original threshold
MEMORY_USED_WARNING=80
MEMORY_USED_CRITICAL=95

# Change to (if your server normally uses 85% memory)
MEMORY_USED_WARNING=90
MEMORY_USED_CRITICAL=98
```

---

## Daily Operations

### Morning Routine (5 minutes)

```bash
# Check for alerts
sudo tail -20 /var/lib/hids/alerts.log

# Any CRITICAL or HIGH alerts?
# If YES → investigate (see "What To Do If..." section)
# If NO → all clear, continue work
```

### Responding to Alerts

**If you see CRITICAL alerts:**
1. Stop normal work
2. Note the alert details
3. Investigate the target file/process
4. Isolate the system if needed
5. Take corrective action

**If you see HIGH alerts:**
1. Investigate within the hour
2. Determine if it's a real threat or false positive
3. Take action or re-baseline if legitimate

**If you see MEDIUM/INFO alerts:**
1. Review when you have time
2. Not urgent

### Weekly Maintenance

```bash
# Archive old alerts (if needed)
sudo gzip /var/lib/hids/alerts.log.old

# Check HIDS is still running
sudo /usr/local/sbin/hids --help

# Verify automation still active
sudo crontab -l  # or sudo systemctl status hids.timer

# Review patterns in alerts
sudo grep "CRITICAL\|HIGH" /var/lib/hids/alerts.log | tail -20
```

### Re-baselining After Legitimate Changes

```bash
# After system update, new user creation, etc.
# Re-create baseline to prevent false positives

sudo /usr/local/sbin/hids --baseline

# Then normal scan
sudo /usr/local/sbin/hids
```

---

## Troubleshooting

### "Script won't run" / "Permission denied"

```bash
# Fix permissions
sudo chmod 755 /usr/local/sbin/hids

# Verify
ls -la /usr/local/sbin/hids
# Should show: -rwxr-xr-x
```

### "Cron job not running"

```bash
# Check if cron is installed and running
sudo service cron status  # Debian/Ubuntu
sudo service crond status # RHEL/CentOS

# Check if your job is in crontab
sudo crontab -l

# Check cron logs
sudo tail -50 /var/log/syslog | grep CRON  # Debian
sudo tail -50 /var/log/cron | grep CRON     # RHEL

# Try running manually to see errors
sudo /usr/local/sbin/hids
```

### "Too many alerts / Alert fatigue"

```bash
# Increase thresholds in config
sudo nano /var/lib/hids/hids.conf

# Increase warning levels
MEMORY_USED_WARNING=90  # Was 80
CPU_LOAD_WARNING=3.0    # Was 2.0

# Re-baseline to set new normal
sudo /usr/local/sbin/hids --baseline
```

### "Disk space full"

```bash
# Check log size
du -sh /var/lib/hids/

# Archive old logs
sudo gzip /var/lib/hids/alerts.log.old 2>/dev/null

# Keep only recent alerts (keep last 30 days)
sudo find /var/lib/hids -name "*.log" -mtime +30 -delete
```

### "Script has errors"

```bash
# Check for syntax errors
bash -n /usr/local/sbin/hids

# Run with debug output
bash -x /usr/local/sbin/hids 2>&1 | head -50
```

### Still having issues?

```bash
# Collect debugging information
echo "=== System Info ==="
uname -a

echo "=== HIDS Script Info ==="
ls -la /usr/local/sbin/hids

echo "=== HIDS Directory ==="
ls -la /var/lib/hids/

echo "=== Recent Errors ==="
sudo tail -50 /var/log/syslog | grep -i hids

# Share this output with your team for help
```

---

## What HIDS CAN and CANNOT Do

### ✅ HIDS Can Detect:

- New user accounts (backdoor accounts)
- Modified critical files (tampered configs)
- Unexpected processes (malware)
- Suspicious ports opening (backdoors)
- Failed login floods (brute force)
- SSH key additions (unauthorized access)
- High resource usage (DOS attacks, miners)
- File permission changes (privilege escalation)
- Process running from /tmp (classic malware)
- Unusual login times/sources (account compromise)

### ❌ HIDS CANNOT Prevent:

- Network attacks (that's the firewall's job)
- Vulnerability exploitation (that's patching's job)
- Social engineering (that's security training's job)
- Zero-day attacks (no one can prevent unknown exploits)

### ℹ️ HIDS Works Best When:

- Baseline is created on a clean system
- Alerts are reviewed daily
- False positives are handled promptly
- Configuration is tuned to your environment
- Used alongside other security tools

---

## Support & Questions

### Documentation

- **How to interpret alerts?** → See "Understanding Alerts" section
- **Why is HIDS alerting on X?** → Check configuration thresholds
- **How do I customize it?** → See "Configuration" section
- **What if the system is compromised?** → See "Responding to Alerts"

### Getting Help

1. Check the Troubleshooting section
2. Review alert logs to understand what triggered
3. Check if baseline is up-to-date
4. Ask your team lead or security officer

---

## Key Takeaways

1. **HIDS is not perfect**, but it's essential for visibility
2. **Daily reviews** take 5 minutes and catch most threats
3. **Fast response** turns alerts into action
4. **Baseline matters** — the tool is only as good as your baseline
5. **Trust the alerts** — when properly tuned, false positives are rare

---

## Disclaimer

This tool is designed for monitoring and detection, not automatic response. Always investigate alerts before taking action. Some alerts may require manual review to confirm they are real threats.

This is a component of a defense-in-depth security strategy. Use alongside:
- Firewall
- Regular patching
- Access controls
- Security training
- Incident response plan

---

**HIDS Version:** 1.0  
**Last Updated:** January 2024  
**Status:** Ready for Production Use

For technical questions, refer to the research.md documentation.
