# HIDS - Host Intrusion Detection System

**Team Capstone Project: Monitor, detect, and respond to intrusions on Linux systems**

## 📋 Overview

This is a **Host Intrusion Detection System (HIDS)** built entirely in Bash for a Linux Capstone Project. The tool monitors Linux systems for security threats across five critical monitoring areas.

### What is HIDS?

HIDS (Host Intrusion Detection System) is a security tool that lives **inside** your system and hunts for intruders who have already penetrated your network defenses.

**Key Insight:** Network firewalls stop attackers at the perimeter. HIDS catches them **inside the system** before they steal data or install backdoors.

---

## 🎯 The Five Monitoring Modules

| Module | What It Does | Detects |
|--------|-------------|---------|
| **System Health** | Monitors CPU, memory, disk, processes | Resource exhaustion, DoS attacks, system stress |
| **User Activity** | Tracks logins, accounts, privileges | Unauthorized access, brute force, new backdoor accounts |
| **Processes & Network** | Lists running processes and connections | Malware, backdoors, suspicious network behavior |
| **File Integrity** | Detects file modifications | Tampered configs, modified backdoors, system changes |
| **Alerting System** | Logs all findings persistently | Everything with timestamp and severity level |

---

## 🚀 Quick Start (5 minutes)

### Installation

```bash
# Clone the repository
git clone https://github.com/USERNAME/hids-capstone.git
cd hids-capstone

# Install HIDS to system location
sudo cp src/hids /usr/local/sbin/hids
sudo chmod 755 /usr/local/sbin/hids

# Verify installation
sudo /usr/local/sbin/hids --help
```

### Create Baseline

```bash
# First, verify your system is clean
ps aux | grep '/tmp'     # Should be empty
netstat -tulnp | grep LISTEN  # Only expected services

# Create baseline (snapshot of normal state)
sudo /usr/local/sbin/hids --baseline

# Verify baseline was created
ls -la /var/lib/hids/baselines/
```

### Run Your First Scan

```bash
# Execute HIDS scan
sudo /usr/local/sbin/hids

# Takes 1-2 minutes

# View results
sudo tail -20 /var/lib/hids/alerts.log
```

### Set Up Automation

```bash
# Option A: Cron (runs every 5 minutes)
sudo crontab -e
# Add this line:
*/5 * * * * /usr/local/sbin/hids >> /var/log/hids.log 2>&1

# Option B: Systemd Timer
sudo bash deployment/setup-systemd.sh
```

✅ **Done! HIDS is now running automatically**

---

## 📚 Documentation

| Document | Purpose | For Whom |
|----------|---------|----------|
| [docs/research.md](docs/research.md) | Research findings & design decisions | Team, Evaluators |
| [user-docs/USER_README.md](user-docs/USER_README.md) | Complete user guide | End users |
| [docs/DESIGN.md](docs/DESIGN.md) | Architecture & technical details | Developers |
| [demo/DEMO_GUIDE.md](demo/DEMO_GUIDE.md) | Demo preparation & scenarios | Team |
| [user-docs/TROUBLESHOOTING.md](user-docs/TROUBLESHOOTING.md) | Common issues & fixes | Everyone |

---

## 🧪 Testing HIDS

### Run Attack Scenarios

Test how HIDS detects different threats:

```bash
# Scenario 1: New user account (common backdoor method)
bash tests/scenario_1_new_user.sh

# Scenario 2: SSH key addition (unauthorized remote access)
bash tests/scenario_2_ssh_key.sh

# Scenario 3: Suspicious process from /tmp (malware location)
bash tests/scenario_3_process.sh

# Scenario 4: File modification (tampering with critical files)
bash tests/scenario_4_file_modify.sh

# Scenario 5: Brute force login attempts (password guessing)
bash tests/scenario_5_brute_force.sh
```

Each scenario shows how HIDS detects different attack techniques.

---

## 📊 Project Structure

hids-capstone/
├── README.md
├── src/
│   ├── hids
│   └── config/hids.conf
├── docs/
│   ├── research.md
│   ├── DESIGN.md
│   ├── MODULES.md
│   ├── PREREQUISITES.md
│   ├── SETUP.md
│   └── EXECUTION_GUIDE.md
├── user-docs/
│   ├── USER_README.md
│   ├── QUICKSTART.md
│   ├── CONFIGURATION.md
│   └── TROUBLESHOOTING.md
├── tests/
|   ├── test-hids-complete.sh        Combined test runner
|   ├── TEST_RESULTS.md              Test documentation
|   ├── scenario_1_new_user.sh       User account test
|   ├── scenario_2_ssh_key.sh        SSH key test
|   ├── scenario_3_process.sh        Process test
|   ├── scenario_4_file_modify.sh    File modification test
|   └── scenario_5_brute_force.sh    Brute force test
|
├── demo/
│   ├── DEMO_GUIDE.md
│   ├── demo_script.sh
│   └── demo_checklist.md
└── deploy/
    ├── docker-compose.yml
    ├── install.sh
    ├── KIBANA_DASHBOARD_CONFIG.json
    └── KIBANA_DASHBOARD_CONFIG.ndjson
---

## 🎬 Live Demo

### What Gets Demonstrated

1. **Normal System** → Run HIDS on clean system → **No alerts**
2. **Simulated Attack** → Create backdoor account → **System unchanged to user**
3. **Detection** → Run HIDS again → **CRITICAL alerts triggered**
4. **Explanation** → Each team member explains module findings

**Time:** 15-20 minute presentation

---

## 🔧 Configuration

### Edit Thresholds

```bash
# Edit configuration file
sudo nano /var/lib/hids/hids.conf

# Key settings:
CPU_LOAD_WARNING=2.0          # Relative to cores
CPU_LOAD_CRITICAL=4.0
MEMORY_USED_WARNING=80        # Percentage
MEMORY_USED_CRITICAL=95
DISK_USED_WARNING=80
DISK_USED_CRITICAL=95

# Save and restart automation for changes to apply
```

### Re-baseline After Changes

```bash
# After system updates or intentional changes
sudo /usr/local/sbin/hids --baseline

# This prevents false positives on legitimate changes
```

---

## 📋 Daily Operations

### Morning Check (5 minutes)

```bash
# Check for alerts from last night
sudo tail -50 /var/lib/hids/alerts.log

# Any CRITICAL or HIGH alerts? Investigate!
sudo grep "CRITICAL\|HIGH" /var/lib/hids/alerts.log

# System still running normally?
uptime
free -h
df -h /
```

### Respond to Alerts

| Alert Level | What It Means | Action |
|------------|--------------|--------|
| **CRITICAL** | Immediate threat | Stop work, investigate NOW |
| **HIGH** | Likely threat | Investigate within an hour |
| **MEDIUM** | Unusual activity | Monitor and investigate later |

---

## 🐛 Troubleshooting

### "HIDS won't run"

```bash
# Check if installed correctly
ls -la /usr/local/sbin/hids

# Test manually
sudo /usr/local/sbin/hids

# Check for errors
bash -n /usr/local/sbin/hids
```

**[More troubleshooting →](user-docs/TROUBLESHOOTING.md)**

### "Too many alerts"

```bash
# Increase thresholds in config
sudo nano /var/lib/hids/hids.conf

# Example: Change warning threshold
MEMORY_USED_WARNING=90  # Was 80

# Re-baseline to learn new normal
sudo /usr/local/sbin/hids --baseline
```

### "Automation isn't running"

```bash
# Check cron
sudo crontab -l

# Check systemd timer
sudo systemctl list-timers hids.timer

# Check logs
sudo journalctl -u hids.service -n 20
```

---

## ✅ Features

### Core Features

✅ All 5 monitoring modules implemented  
✅ Professional alerting with severity levels  
✅ Persistent logging with timestamps  
✅ Automatic baseline creation  
✅ Configurable thresholds  
✅ Cron or systemd automation  
✅ Color-coded terminal output  

### Code Quality

✅ 500+ lines of clean, commented Bash  
✅ Every function documented  
✅ Modular structure  
✅ No external dependencies  
✅ Production-ready  

### Documentation

✅ Complete research document (all questions answered)  
✅ User guide for non-technical users  
✅ Technical documentation for developers  
✅ Troubleshooting guide with common issues  
✅ Demo scenarios for testing  

---

## 🎯 Requirements Met

### Must-Haves

- ✅ Coverage of all 5 modules
- ✅ Working alert system with timestamps and severity
- ✅ Persistent log file
- ✅ Automatic execution (cron/systemd)
- ✅ Clean, commented code
- ✅ Complete research.md
- ✅ User documentation
- ✅ Live demo with alert scenario

### Nice-to-Haves

- ✅ Baseline system (learns what's normal)
- ✅ Configurable thresholds via config file
- ✅ Summary report generation
- ✅ Color-coded output
- ✅ Severity levels
- ✅ Whitelisting for false positives
- ✅ Attack simulation scenarios
- ✅ Comprehensive documentation

---

## 🚀 Performance

| Metric | Value |
|--------|-------|
| Scan Duration | 1-2 minutes |
| CPU Usage | <5% during scan |
| Memory Usage | <50MB |
| Log Size | ~100KB per day |
| Baseline Size | ~100KB |

---

## 🎓 What You'll Learn

By using this project, you'll understand:

✅ How professional HIDS tools work  
✅ Linux system monitoring techniques  
✅ Baseline-based threat detection  
✅ Alert system design  
✅ Security tool best practices  
✅ Bash scripting at production scale  

---

## 📊 Comparison: Our HIDS vs Commercial Tools

| Feature | Our HIDS | Wazuh | OSSEC |
|---------|----------|-------|-------|
| File Integrity | ✅ | ✅ | ✅ |
| Process Monitoring | ✅ | ✅ | ✅ |
| User Activity | ✅ | ✅ | ✅ |
| Alerting | ✅ | ✅ | ✅ |
| Network Monitoring | ✅ | ✅ | ✅ |
| Multi-agent | ❌ | ✅ | ✅ |
| Web Dashboard | ❌ | ✅ | ❌ |
| Learning curve | Easy | Hard | Medium |

---

## 🔒 Security Notes

### What HIDS Protects Against

✅ Unauthorized user accounts  
✅ Unauthorized SSH key additions  
✅ Modified critical system files  
✅ Suspicious processes (from /tmp, etc.)  
✅ Unexpected network connections  
✅ High resource usage (DoS)  
✅ Privilege escalation attempts  

### What HIDS Doesn't Protect Against

❌ Network attacks (pre-compromise)  
❌ Unpatched vulnerabilities  
❌ Social engineering  
❌ Zero-day exploits  

**Use HIDS as part of defense-in-depth, not as your only security layer.**

---

## 🤝 Team

| Role | Person | Responsibility |
|------|--------|-----------------|
| System/Network | Umrah Javed |  system monitoring |
| User & File Integrity | Sajjad Shahpoor | User activity, file changes |
| Lead + Alerting & Automation | Hanah M | Project coordination,Alert system, automation setup |
| Documentation & Demo | Madumathi Singaraju | Docs, demo preparation |


---

## 📝 License

MIT License - See LICENSE file for details

This means you can:
✅ Use this commercially  
✅ Modify the code  
✅ Distribute it  
✅ Use privately  

As long as you include the license and don't hold us liable.

---

## 🔗 Related Reading

**Commercial HIDS Tools:**
- [Wazuh Documentation](https://documentation.wazuh.com/)
- [OSSEC Project](https://www.ossec.net/)
- [Auditd (Linux Auditing)](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/security_guide/chap-system_auditing)

**Linux Security:**
- [Linux Foundation Security](https://www.linuxfoundation.org/resources/topics/security/)
- [CIS Benchmarks](https://www.cisecurity.org/)

---

## 📞 Questions?

- **How do I use HIDS?** → See [user-docs/USER_README.md](user-docs/USER_README.md)
- **How does it work?** → See [docs/DESIGN.md](docs/DESIGN.md)
- **Having issues?** → See [user-docs/TROUBLESHOOTING.md](user-docs/TROUBLESHOOTING.md)

---

## 🏆 Project Success

This project successfully demonstrates:

✅ Understanding of security principles  
✅ Bash scripting capability  
✅ System administration knowledge  
✅ Documentation and communication skills  
✅ Team coordination and project management  
✅ Ability to deliver under deadline  

---