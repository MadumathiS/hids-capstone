# HIDS Quick Start Guide

## 🎯 The Philosophy in 30 Seconds

**Scenario**: Your front door has locks, alarms, and security cameras (Network Security). But what if someone already got in through a stolen key? 

**Our HIDS Role**: Act like a silent security guard INSIDE the house who:
- Notices if someone opened your safe
- Detects weird sounds coming from the basement
- Sees footprints on the floor that shouldn't be there
- Alerts you BEFORE the intruder steals everything

---

## ⚡ Quick Setup (5 minutes)

### Step 1: Prepare the Script
```bash
# Make the script executable
chmod +x /mnt/user-data/outputs/hids_scanner.sh

# Copy to your system
sudo cp /mnt/user-data/outputs/hids_scanner.sh /usr/local/sbin/hids-scan
```

### Step 2: Create a Baseline (IMPORTANT!)
This is your "clean state" snapshot - do this BEFORE any suspicious activity:

```bash
# Run as root
sudo /usr/local/sbin/hids-scan --baseline

# What it does:
# - Records SHA256 hashes of critical files
# - Creates baseline in /var/lib/hids/baselines/
```

### Step 3: Run Your First Scan
```bash
# Full scan
sudo /usr/local/sbin/hids-scan

# Output goes to:
# - /var/lib/hids/alerts.log    (threats detected)
# - /var/lib/hids/scans.log     (detailed scan info)
```

### Step 4: Review Results
```bash
# Check alerts
sudo tail -50 /var/lib/hids/alerts.log

# Or in real-time
sudo tail -f /var/lib/hids/alerts.log
```

---

## 🔧 Automation (Optional)

### Option A: Run Every Hour via Cron
```bash
# Edit crontab
sudo crontab -e

# Add this line (runs every hour)
0 * * * * /usr/local/sbin/hids-scan >> /var/log/hids-cron.log 2>&1

# Or every 5 minutes (for high-security)
*/5 * * * * /usr/local/sbin/hids-scan >> /var/log/hids-cron.log 2>&1
```

### Option B: Setup Systemd Timer (Recommended)
```bash
# Create service file
sudo tee /etc/systemd/system/hids.service > /dev/null <<'EOF'
[Unit]
Description=HIDS Intrusion Detection Scanner
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/hids-scan
User=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create timer (runs every 5 minutes)
sudo tee /etc/systemd/system/hids.timer > /dev/null <<'EOF'
[Unit]
Description=HIDS scan every 5 minutes
Requires=hids.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
AccuracySec=1min

[Install]
WantedBy=timers.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable hids.timer
sudo systemctl start hids.timer

# Check status
sudo systemctl status hids.timer
sudo systemctl list-timers hids.timer
```

---

## 🕵️ What It's Actually Checking

### 1. **Process Monitoring** - Is something running that shouldn't be?
Detects:
- Programs running from /tmp (classic malware location)
- Processes with hidden names
- Programs making unexpected network connections

### 2. **File Integrity** - Has someone modified critical files?
Monitors:
- `/etc/passwd` (user accounts)
- `/etc/shadow` (password hashes)
- `/etc/sudoers` (privilege escalation)
- `/root/.ssh/authorized_keys` (remote access)
- System binaries (`/bin/bash`, `/usr/bin/sudo`)

### 3. **User & Access** - Who's accessing the system?
Checks:
- Currently logged-in users
- Recent login attempts
- Failed login tries
- SSH keys for each user
- Suspicious privilege escalation

### 4. **Network Connections** - Where is data flowing?
Identifies:
- Ports listening for connections
- Active network connections
- Suspicious outbound traffic
- Known backdoor ports (4444, 5555, 8888, etc.)

### 5. **Cron Jobs** - What's running automatically?
Finds:
- Scheduled tasks that might execute malware
- Persistence mechanisms
- Hidden automation

### 6. **Rootkits** - Is the kernel compromised?
Detects:
- Suspicious kernel modules
- Orphaned processes
- Modified system binaries

### 7. **Logs** - What does the system say happened?
Analyzes:
- Authentication logs
- Privilege escalation attempts
- Failed login patterns

---

## 🚨 Alert Severity Levels

When you see alerts, they're color-coded:

| Level | Meaning | Action |
|-------|---------|--------|
| **CRITICAL** | 🔴 Immediate threat detected | Stop what you're doing and investigate NOW |
| **HIGH** | 🟠 Suspicious activity | Investigate within hours |
| **MEDIUM** | 🔵 Unusual pattern | Monitor and investigate when you have time |

Example alerts you might see:
```
[2026-08-28 14:23:45] [CRITICAL] FILE INTEGRITY VIOLATION: /etc/passwd
[2026-08-2814:24:12] [HIGH] Process running from /tmp: /tmp/suspicious_binary
[2026-08-28 14:25:00] [HIGH] New home directory detected: /home/attacker
[2026-08-28 14:26:33] [MEDIUM] Backgrounded process detected: PID=5421
```

---

## 📊 Reading the Logs

### Alert Log (`/var/lib/hids/alerts.log`)
```
Shows only threats and suspicious activity:
[2026-08-28 14:23:45] [CRITICAL] FILE INTEGRITY VIOLATION: /etc/passwd
[2026-08-28 14:24:12] [HIGH] Process running from /tmp: /tmp/bot
```

### Scan Log (`/var/lib/hids/scans.log`)
```
Shows detailed scan output (larger file):
=== PROCESS MONITORING ===
[INFO] Scanning for suspicious processes...
Checking for processes in /tmp...
Checking for processes without terminal...
... (lots of details)
```

---

## 🔍 Common Findings & What They Mean

### ✅ Safe (Normal System Behavior)
```
=== Current logged-in users ===
user1 pts/0 ... (some activity)

=== Recent login history ===
user1 pts/0 ... (normal daily usage)
```

### 🚨 Dangerous (Possible Intrusion)
```
[CRITICAL] FILE INTEGRITY VIOLATION: /etc/passwd
→ Someone modified the user file - they may have added backdoor accounts

[HIGH] Process running from /tmp: /tmp/malware_bot
→ Executable in /tmp is running - likely malicious

[CRITICAL] POSSIBLE ROOTKIT DETECTED: diamorphine
→ A rootkit module is loaded - system is deeply compromised

[HIGH] Suspicious port listening: 4444
→ Known backdoor port is active - attacker has remote access
```

---

## 🧹 Maintenance

### Check logs daily
```bash
sudo tail -30 /var/lib/hids/alerts.log
```

### Re-baseline after security updates
```bash
# After applying patches
sudo /usr/local/sbin/hids-scan --baseline
```

### Archive logs periodically
```bash
# Keep last 30 days of logs
find /var/lib/hids -name "*.log" -mtime +30 -delete
```

---

## 🛡️ Integration with Response

When you detect something suspicious:

1. **CRITICAL alert** → Isolate the system immediately
2. **Review the logs** → What changed and when?
3. **Check what's running** → `ps aux | grep <suspicious_process>`
4. **Kill suspicious process** → `kill -9 <PID>`
5. **Preserve evidence** → Copy logs before cleanup
6. **Patch/reinstall** → Don't just remove the malware

Example response to a detected intrusion:
```bash
# 1. See what's listening
sudo netstat -tulnp | grep 4444

# 2. Find the process
sudo ps aux | grep <PID>

# 3. Kill it
sudo kill -9 <PID>

# 4. See what it created
sudo find / -newer /var/lib/hids -type f 2>/dev/null

# 5. Block the ports
sudo ufw deny 4444
```

---

## 💡 Tips & Tricks

### Dry run (don't actually change anything)
```bash
# Just scan, don't create baseline
sudo /usr/local/sbin/hids-scan | head -50
```

### Compare current vs. baseline
```bash
# Manually check a specific file
sha256sum /etc/passwd
cat /var/lib/hids/baselines/passwd.sha256
# Should match if not modified
```

### Monitor specific user
```bash
# Check all SSH keys for suspicious additions
find /home -name "authorized_keys" -exec cat {} \; -exec echo "^---^" \;
```

### Export logs for analysis
```bash
# Copy to external drive
sudo cp /var/lib/hids /external/backup/hids_logs_$(date +%Y%m%d)
```

---

## ❓ Troubleshooting

### Script requires root
```bash
# Always use sudo
sudo /usr/local/sbin/hids-scan
```

### Can't find ss or netstat
```bash
# Install net-tools
sudo apt install net-tools
# Or use ss (usually pre-installed)
```

### Baseline files missing
```bash
# Create them
sudo /usr/local/sbin/hids-scan --baseline
```

### Too many false alarms
```bash
# Exclude certain users/processes in the script
# Edit /usr/local/sbin/hids-scan and modify grep patterns
```

---

## 🎓 Understanding HIDS vs. Other Security

| Tool | What It Does | What It Doesn't |
|------|-------------|-----------------|
| **Firewall (HNS)** | Blocks bad stuff from entering | Can't detect what's already inside |
| **Antivirus** | Scans for known malware signatures | Misses zero-days and custom threats |
| **HIDS** | Detects unusual activity INSIDE | Won't help if the attacker is still outside |
| **Log Analyzer** | Reviews what happened | Can't act in real-time |

**Best practice**: Use ALL of them together!

---

## 📞 What To Do If You Find An Intrusion

### Immediate (First Hour)
1. ✅ Don't panic - you found it before it found you
2. ✅ Document everything - take screenshots
3. ✅ Isolate the system - disconnect from network
4. ✅ Preserve logs - copy the entire `/var/lib/hids` directory

### Investigation (Next 24 Hours)
1. ✅ Analyze what changed and when
2. ✅ Find entry point - how did they get in?
3. ✅ Identify what they accessed - which files?
4. ✅ Check for persistence - did they install backdoors?

### Remediation (Decision Point)
- **Option A**: Remove the intruder and harden (risky - might miss persistence)
- **Option B**: Wipe and rebuild (safest - but time-consuming)
- **Option C**: Deep forensics (most thorough - requires expertise)

---

## ✨ Next Steps

1. **Today**: Set up and run baseline
2. **This Week**: Configure automated scanning (cron/timer)
3. **This Month**: Review logs, tune alert thresholds
4. **Ongoing**: Monitor `/var/lib/hids/alerts.log` daily

---

**Remember**: The goal isn't perfect prevention—it's early detection. By the time an intruder gets inside your system, you want to know BEFORE they achieve their objectives.

**"Find them before they find you."**
