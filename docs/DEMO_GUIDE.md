# HIDS Team Demo & Testing Guide
## Capstone Project Live Demonstration

---

## OVERVIEW

Team must deliver a live demo showing:
1. HIDS running on a VM
2. At least one alert being triggered with a simulated scenario
3. Clear explanation of what was detected and why

This document gives you:
- How to prepare your demo environment
- Attack scenarios to simulate (easy to medium difficulty)
- What to demonstrate
- Questions you'll be asked and how to answer

---

## PREPARATION (Do This Week Before Demo)

### 1. Set Up Demo Environment

**You need:**
- VM or spare Linux system
- Fresh, clean baseline created
- HIDS installed and running
- Automation configured (cron/systemd)
- Alert log ready to show
- Planned attack scenario selected

**Environment checklist:**
```bash
□ HIDS script installed at /usr/local/sbin/hids
□ /var/lib/hids/ directory exists and is readable
□ Baseline created with --baseline flag
□ Cron or systemd timer running
□ First test scan completed successfully
□ Alert log has at least one entry
□ README.md is current and accurate
□ research.md is complete
□ All 5 modules are implemented
```

### 2. Baseline Your System

```bash
# Verify system is clean
echo "=== Checking for suspicious activity ==="
ps aux | grep -i tmp  # Should be empty
netstat -tulnp | grep LISTEN  # Should only show expected services
cut -d: -f1 /etc/passwd  # Should only show legitimate users

# Create clean baseline
sudo /usr/local/sbin/hids --baseline

# Note: This is your reference point for the demo
```

### 3. Document Your Design Decisions

Before the demo, be ready to explain:
- Why did you choose the 5 modules you're monitoring?
- How do you distinguish normal from abnormal?
- Why are your thresholds set where they are?
- What was the hardest design decision?

Example answers you should prepare:

**Q: Why monitor file integrity?**
A: Because critical files like /etc/passwd and /etc/sudoers are targets for privilege escalation and backdoors. Any unexpected change is a red flag.

**Q: How do you avoid alert fatigue?**
A: We establish a baseline of normal behavior first, then only alert on deviations. We also tune thresholds based on the server's capacity, not hardcoded values.

**Q: What's the difference between your HIDS and others?**
A: [Your specific design choices - baseline model vs. thresholds, modular vs. monolithic, etc.]

---

## DEMO SCENARIO SELECTION

Choose one of these scenarios (or design your own):

### ⭐ EASY SCENARIO 1: New User Account (Recommended for First Demo)

**What it simulates:** Attacker adding a backdoor account

**Demo steps:**

```bash
# Before demo, run normal scan
sudo /usr/local/sbin/hids

# Show: No CRITICAL alerts

# During demo, create a fake "attacker" account
sudo useradd -m -s /bin/bash attacker

# Immediately run HIDS again
sudo /usr/local/sbin/hids

# Show: CRITICAL alert detected new user
sudo tail -20 /var/lib/hids/alerts.log
# Should show: [CRITICAL] NEW_USER_ACCOUNT: attacker

# Explain:
# "This alert would catch an attacker adding a backdoor account.
#  The baseline didn't have this user, so any addition is flagged."

# Cleanup (don't forget!)
sudo userdel -r attacker
```

**Why this is good:**
- Simple to demonstrate
- Clear cause and effect
- Mimics real attack
- Easy to explain

### ⭐ EASY SCENARIO 2: SSH Key Addition (Also Recommended)

**What it simulates:** Attacker adding remote access key

**Demo steps:**

```bash
# Before: Verify baseline
sudo cat /root/.ssh/authorized_keys  # Show current state

# During: Add a fake SSH key
sudo bash -c 'echo "ssh-rsa AAAA... attacker@evil.com" >> /root/.ssh/authorized_keys'

# Run HIDS
sudo /usr/local/sbin/hids

# Show alert
sudo grep "SSH\|authorized" /var/lib/hids/alerts.log

# Explain:
# "Our file integrity module detected the SSH authorized_keys file changed.
#  This is exactly what an attacker would do to maintain access."

# Cleanup
sudo bash -c 'echo "" > /root/.ssh/authorized_keys'  # Remove the line you added
```

**Why this is good:**
- File integrity detection in action
- Real persistence mechanism
- Shows baseline comparison working
- Clear alert message

### MEDIUM SCENARIO 3: Suspicious Process from /tmp

**What it simulates:** Malware or backdoor executable running from /tmp

**Demo steps:**

```bash
# Create a fake malicious executable
sudo bash -c 'cat > /tmp/malware.sh << "EOF"
#!/bin/bash
echo "This is a simulated malware"
sleep 1000
EOF
chmod +x /tmp/malware.sh'

# Run it in background
sudo /tmp/malware.sh &

# Capture PID
malware_pid=$!
echo "Malware PID: $malware_pid"

# Run HIDS
sudo /usr/local/sbin/hids

# Show alert
sudo grep "tmp\|malware" /var/lib/hids/alerts.log

# Explain:
# "HIDS detected a process running from /tmp. This is suspicious because:
#  1. /tmp is world-writable (anyone can put files there)
#  2. Legitimate apps shouldn't run from /tmp
#  3. Malware commonly uses /tmp as a staging area"

# Cleanup
sudo kill -9 $malware_pid
sudo rm /tmp/malware.sh
```

**Why this is good:**
- Shows process anomaly detection
- Real malware behavior
- Demonstrates location-based detection
- High-severity alert

### MEDIUM SCENARIO 4: Failed Login Brute Force

**What it simulates:** Attacker trying to guess your password

**Demo steps:**

```bash
# Generate multiple failed login attempts
for i in {1..6}; do
    ssh baduser@localhost 2>&1 | grep -i "refused\|denied" || true
done

# Wait for HIDS to run (or run manually)
sudo /usr/local/sbin/hids

# Show alert
sudo grep -i "brute\|failed.*login" /var/lib/hids/alerts.log

# Explain:
# "We're configured to alert after 5 failed login attempts in 5 minutes.
#  This catches brute force attacks automatically."

# Show the matching auth.log entries
sudo grep "Failed password" /var/log/auth.log | tail -5
```

**Why this is good:**
- Temporal correlation (multiple events in time window)
- Real attack pattern
- Shows log analysis capability
- Different alert type (activity vs. integrity)

### ADVANCED SCENARIO 5: File Modification (/etc/passwd)

**What it simulates:** Attacker modifying password file (very dangerous)

**Demo steps:**

```bash
# WARNING: Be extremely careful with /etc/passwd
# Only do this if you're confident in system administration

# Create a backup first
sudo cp /etc/passwd /etc/passwd.backup

# Simulate modification (add a comment, don't change actual user data)
sudo sed -i '$ a \\n# TEST: This line was added' /etc/passwd

# Run HIDS
sudo /usr/local/sbin/hids

# Show CRITICAL alert
sudo grep "passwd\|CRITICAL" /var/lib/hids/alerts.log

# Explain:
# "File integrity checking is our most powerful detection mechanism.
#  Even a single byte change in a critical file triggers an alert.
#  This catches any modification, intentional or malicious."

# Restore
sudo cp /etc/passwd.backup /etc/passwd
sudo rm /etc/passwd.backup
```

**Why this is good:**
- Demonstrates cryptographic integrity (SHA256 hashes)
- Highest severity alert
- Shows hash comparison
- Very hard to evade

---

## DEMO CHECKLIST

### Before You Start

```bash
□ VM is powered on and accessible
□ Network is working (if needed for demo)
□ HIDS is installed and permissions are correct
□ Baseline was created on a clean system
□ At least one successful baseline scan completed
□ Alert log exists and has previous entries
□ Console is zoomed in (text is readable by audience)
□ Terminal has dark background (better contrast)
□ Scripts are not running other tasks
```

### Opening (Explain the Project)

```
"We built a Host Intrusion Detection System in Bash that monitors
a Linux system for security threats.

Our HIDS checks five critical areas:
1. System Health     - Is the server overloaded or under attack?
2. User Activity     - Who's accessing the system?
3. Processes         - What's running that shouldn't be?
4. Network Activity  - What ports are open? Where are connections going?
5. File Integrity    - Have critical files been modified?

Unlike firewalls that stop attacks at the network edge, HIDS assumes
the attacker is already inside and hunts for signs of compromise.

Today we're going to simulate an attack and show you how HIDS detects it."
```

### During Demo

```bash
# Step 1: Show HIDS running normally (no alerts)
echo "First, let's run a normal scan..."
sudo /usr/local/sbin/hids
echo ""
echo "Show alerts:"
sudo tail -20 /var/lib/hids/alerts.log
echo "No alerts - system appears normal."
echo ""

# Step 2: Simulate attack
echo "Now we'll simulate an attacker adding a backdoor account..."
sudo useradd -m -s /bin/bash attacker
echo "Attacker account created."
echo ""

# Step 3: Run HIDS again
echo "HIDS runs automatically every 5 minutes. Let's run it manually..."
sudo /usr/local/sbin/hids
echo ""

# Step 4: Show the alert
echo "Check the alert log:"
sudo tail -20 /var/lib/hids/alerts.log
echo ""
echo "See the CRITICAL alert? HIDS detected the new account immediately!"
```

### Explanation (What To Say)

For each alert shown, explain:

**1. WHAT is being alerted on?**
```
"Our file integrity module is alerting on a NEW_USER_ACCOUNT.
We're checking the baseline we created on a clean system.
The baseline showed N users. Now we have N+1 users.
Difference: new account 'attacker' was added."
```

**2. WHY is it suspicious?**
```
"New user accounts are suspicious because:
- Administrators should control who has access
- An unexpected account = unauthorized access
- The attacker is likely to have used this account"
```

**3. WHERE is this information coming from?**
```
"We're checking /etc/passwd, the system user file.
Every time a user is added, /etc/passwd is updated.
Our baseline knows what /etc/passwd should contain.
When it changes, we know about it immediately."
```

**4. HOW does HIDS find this?**
```
"Each HIDS module runs specific checks:
- User module: parses /etc/passwd and compares to baseline
- Uses SHA256 hashing for integrity verification
- Runs every 5 minutes automatically via cron
- Logs any changes to /var/lib/hids/alerts.log"
```

**5. WHAT would an operator do?**
```
"If this alert appeared in production:
1. Operator checks auth logs to see WHO added the account
2. Contacts system admin to confirm if it's authorized
3. If not authorized: account is deleted, investigation begins
4. If authorized: baseline is updated to prevent false positives next time"
```

### Closing

```
"This demo showed how HIDS caught a single attack scenario.
In production, it would be running 24/7, catching:
- New accounts, SSH key additions, privilege escalation
- Suspicious processes, network connections, resource exhaustion
- Modified critical files, permission changes

The key insight: detection through deviation.
We baseline the normal state, then alert on anomalies.
This is exactly what commercial tools like Wazuh and OSSEC do."
```

---

## QUESTIONS YOU'LL BE ASKED

### Technical Questions

**Q: For each piece of information your tool collects: where exactly on the system does it come from?**

A: *(For each module)*
- System Health: `uptime`, `free`, `df`, `/proc/loadavg`, `/proc/meminfo`
- User Activity: `/var/log/auth.log`, `lastlog`, `w`, `/etc/passwd`
- Processes: `ps aux`, `/proc/[pid]/`, `netstat -tulnp`
- Network: `netstat`, `ss`, `/proc/net/tcp`, `lsof`
- File Integrity: Direct file access, `stat`, SHA256 hashing

**Q: What is the difference between a HIDS and a NIDS?**

A: HIDS = Host IDS, runs ON the machine, monitors from inside
   NIDS = Network IDS, runs on network equipment, monitors all traffic
   
   HIDS sees what's actually happening on the system (filesystem, processes)
   NIDS sees what's coming in/out of network
   
   Both are needed: NIDS stops external attacks, HIDS finds what got past NIDS

**Q: A sophisticated attacker knows your tool is running. How might they try to evade it?**

A: Good question. An attacker could:
   - Kill the HIDS process (we'd lose detection, but cron would restart it)
   - Modify the HIDS script (our baseline would catch it if the script itself is monitored)
   - Fill up logs to hide tracks (we'd alert on disk space usage)
   - Use rootkit to hide from /proc (we'd detect orphaned processes)
   - Load kernel module (we'd detect with lsmod)
   
   Real mitigation: send logs to remote syslog server so attacker can't delete them

**Q: What was the hardest design decision your team made, and why?**

A: *(Answer should be specific to your design, examples)*
   - Deciding what constitutes a baseline vs. what to threshold on
   - Choosing alert frequency (every 5 minutes = more detection, more logs)
   - Modularity vs. monolithic design (separate scripts vs. one big script)
   - Deciding which files to integrity-check (monitor everything vs. just critical)
   - Alert format: JSON vs. syslog format (JSON is better for integration)

**Q: How do you distinguish a real alert from a false positive? How did you tune your tool to reduce noise?**

A: Our approach:
   1. Baseline: Record normal state on first run
   2. Deviation detection: Only alert on changes to baseline
   3. Thresholds: System-specific (CPU load relative to core count)
   4. Severity levels: CRITICAL only for obvious threats
   5. Whitelist: Known-good processes, expected cron jobs
   6. Re-baselining: After legitimate changes, update baseline
   
   Result: HIDS alerts only on things worth investigating, not every change

**Q: If you had two more weeks, what would you build next?**

A: *(Think ahead about enhancements)*
   - Integration with ticketing system (auto-create tickets)
   - Rootkit detection with chkrootkit
   - Attack simulation mode (test if HIDS catches simulated attacks)
   - Performance profiling (how much CPU/memory does HIDS use?)
   - Endpoint detection and response (auto-kill suspicious processes)
   - Central logging (aggregate logs from multiple systems)

### Project Management Questions

**Q: How did your team divide the work?**

A: *(Be honest about who did what)*
   - Person A: System health module
   - Person B: User activity + file integrity modules
   - Person C: Process/network modules + alerting
   - All: Research, testing, documentation
   
   Coordination: Daily sync meetings, shared Git repo, code reviews

**Q: What was the biggest challenge your team faced?**

A: *(Examples)*
   - Understanding how to parse /proc filesystem without existing tools
   - Deciding on alert thresholds without production data
   - Testing edge cases (what if there are 10,000 processes?)
   - Making the script robust across different Linux distributions

**Q: How did you test your tool?**

A: We created attack scenarios:
   - Manual account creation to test user detection
   - Created processes from /tmp to test process detection
   - Simulated brute force with failed SSH attempts
   - Modified files to test integrity checking
   - Ran with different resource loads to test health alerts
   - Verified each alert logs correctly

---

## COMMON MISTAKES TO AVOID

❌ **Don't show unclean baseline**
- Baseline should be from a system with no suspicious activity
- If you're unsure, reinstall the OS and create fresh baseline

❌ **Don't run demo on a production system**
- Use a VM or lab environment
- You don't want to accidentally kill a production process

❌ **Don't forget to explain findings**
- Don't just show an alert and move on
- Walk through: WHAT, WHERE, WHY, HOW

❌ **Don't mumble or go too fast**
- Audience is learning this for first time
- Speak clearly, pause between demo steps
- Make sure text on screen is readable

❌ **Don't ad-lib code changes during demo**
- Have your demo scripts prepared and tested
- "Let me run through it again" is ok; "Let me try this..." is not

❌ **Don't forget to cleanup after demo**
- Remove fake accounts, processes, files
- Restore system to clean state
- Reset baseline after demo modifications

---

## DEMO SCRIPT (COPY & PASTE)

Use this exact sequence for a smooth demo:

```bash
#!/bin/bash
# Demo Script - Run this on demo day

clear
echo "====== HIDS Capstone Project Demo ======"
echo ""
echo "Step 1: Show normal system state"
echo "Running HIDS scan on clean baseline..."
sudo /usr/local/sbin/hids
echo ""
echo "Alert log:"
sudo tail -10 /var/lib/hids/alerts.log
echo ""
echo "No alerts = system appears normal"
echo ""
read -p "Press Enter to continue..."
clear

echo "Step 2: Simulate attacker creating backdoor account"
echo "Adding user 'attacker' to system..."
sudo useradd -m -s /bin/bash attacker
echo "User added: "
sudo grep attacker /etc/passwd
echo ""
read -p "Press Enter to continue..."
clear

echo "Step 3: Run HIDS detection"
echo "Running HIDS to detect changes..."
sudo /usr/local/sbin/hids
echo ""
echo "Alert log now shows:"
sudo tail -15 /var/lib/hids/alerts.log
echo ""
echo "See the CRITICAL alert? HIDS caught the unauthorized account!"
echo ""
read -p "Press Enter to continue..."
clear

echo "Step 4: Cleanup"
echo "Removing simulated attacker account..."
sudo userdel -r attacker
echo "System restored to clean state."
echo ""
echo "Demo Complete!"
```

---