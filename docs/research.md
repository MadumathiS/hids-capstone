# Research.md - HIDS Capstone Project

**Team:** [Your Team Name]  
**Date Started:** [Start Date]  
**Date Completed:** [Completion Date]  
**Project:** Host Intrusion Detection System (HIDS) - Linux Capstone  
**Institution:** [Your School/Organization]  

---

## TABLE OF CONTENTS

1. [Executive Summary](#executive-summary)
2. [What Separates Good HIDS from Bad](#what-separates-good-hids-from-bad)
3. [System Health Monitoring](#system-health-monitoring)
4. [Users and Activity](#users-and-activity)
5. [Processes](#processes)
6. [Network Monitoring](#network-monitoring)
7. [File Integrity](#file-integrity)
8. [Logging and Alerting](#logging-and-alerting)
9. [Design Decisions](#design-decisions)
10. [References](#references)

---

## EXECUTIVE SUMMARY

### Project Goal

Build a Host Intrusion Detection System (HIDS) that monitors a Linux system across five critical areas: system health, user activity, processes and network, file integrity, and alerting. The tool must distinguish between normal and suspicious behavior using only native Linux tools and Bash scripting.

### Key Insight: The Detection Problem

A good HIDS solves a fundamental problem: **systems are noisy.** A server running normally generates thousands of log entries, process changes, and network connections daily. An attacker hides in that noise.

The challenge is not collecting data — the challenge is knowing what matters.

### Commercial HIDS Tools Analyzed

We researched and analyzed three leading HIDS solutions:

- **Wazuh:** Centralized logging, rule-based detection, multi-agent architecture
- **OSSEC:** File integrity monitoring, log analysis, rootkit detection  
- **Auditd:** Kernel-level audit logging, system call tracing

### What They Have in Common

1. **Baseline + Deviation Model** - Record normal state, alert on changes
2. **Thresholds Over Absolutes** - "50% CPU" matters more than "exactly 52%"
3. **Context Correlation** - Don't just see "failed login," see "10 failed logins in 2 minutes from unknown IP"
4. **Severity Levels** - Not every anomaly is equally important
5. **Persistent Alerting** - Logs don't disappear; they accumulate for investigation
6. **Automation** - Runs without human intervention; triggers are scheduled

Our HIDS implements all six principles using only Bash and native Linux tools.

---

## WHAT SEPARATES GOOD HIDS FROM BAD

### Characteristics of Poor HIDS

**❌ Alert Fatigue**
- Alerts on every configuration change
- No thresholds — alerts on first deviation
- Logs deleted automatically
- Result: Operators stop reading alerts

**❌ Missing Context**
- Reports isolated facts without correlation
- Doesn't distinguish malicious vs. legitimate
- No timeline or pattern analysis
- Result: Can't tell real threat from normal operation

**❌ Manual Overhead**
- Requires daily tuning and whitelist updates
- Needs operator to remember what is normal
- No baseline — hardcoded thresholds
- Result: Hours of maintenance for minimal value

**❌ Poor Design**
- All-or-nothing output (binary pass/fail)
- Ignores severity differences
- Logs in incompatible formats
- Can't be integrated with other tools
- Result: Information is useless

### Characteristics of Good HIDS

**✅ Signal-to-Noise Ratio**
- Establishes baseline of normal behavior
- Only alerts when deviation exceeds threshold
- Whitelists known-good activity
- Result: Operators trust the tool

**✅ Rich Context**
- Correlates data from multiple sources
- Shows timeline of related events
- Distinguishes severity of findings
- Result: Operators understand what they're looking at

**✅ Minimal Maintenance**
- Self-baselining on first run
- Adapts to legitimate changes
- Configuration file for thresholds
- Result: Runs hands-free

**✅ Professional Design**
- Structured log format (parseable by other tools)
- Severity levels and clear categorization
- Persistent, organized storage
- Integration hooks for automation
- Result: Becomes part of the monitoring ecosystem

---

## SYSTEM HEALTH MONITORING

### Research Questions Answered

#### Q: What aspects of a running Linux system tell you whether it is healthy or under stress?

**Key Metrics:**

**1. CPU Usage**
- `load average` (1-min, 5-min, 15-min): Most important indicator
- `%CPU` per process: Identifies resource hogs
- Context: "50% CPU on idle server" = problem; "90% CPU on build server" = normal

**2. Memory Usage**
- `free`: Available RAM in KB
- `available`: RAM usable by applications (includes cache that can be freed)
- `%used`: Memory pressure indicator
- Context: "60% used RAM" = likely fine; "95% used RAM" = problem

**3. Disk Usage**
- `df`: Filesystem fullness
- `du`: Directory size trends
- Context: "90% full" = urgent; "45% full" = normal

**4. I/O Performance**
- `iostat`: Disk I/O wait time
- `iowait` in top: Processes blocked waiting for disk
- Context: >50% iowait = bottleneck

**5. Process Count**
- Total running processes
- Zombie processes (dead but not reaped)
- Context: 200 processes = normal server; 5000 = problem

**6. Network Saturation**
- `netstat`: Active connections count
- `ss`: Network socket statistics
- Context: 1000 connections = can be normal; 50,000 = DoS

**7. Uptime & Kernel Panic**
- System uptime via `uptime`
- Unexpected reboots (check logs)
- Context: Frequent reboots = hardware problem or crash

#### Q: Where does Linux expose this information?

**Command Sources:**

| Metric | Command | File | Realtime? |
|--------|---------|------|-----------|
| Load average | `uptime`, `top` | `/proc/loadavg` | Yes |
| CPU usage | `top`, `ps` | `/proc/stat` | Yes |
| Memory | `free`, `top` | `/proc/meminfo` | Yes |
| Disk | `df`, `du` | `/proc/mounts` | Yes |
| I/O performance | `iostat` | `/proc/diskstats` | Yes |
| Process info | `ps`, `top` | `/proc/[pid]/stat` | Yes |
| Network | `netstat`, `ss` | `/proc/net/tcp` | Yes |
| Uptime | `uptime` | `/proc/uptime` | Yes |

**Why /proc matters:**
- `/proc` is a virtual filesystem that exposes kernel data in real-time
- No delay, no caching, no special privileges needed (mostly)
- Format is consistent and machine-readable
- Can parse with `grep` and `awk` without external tools

#### Q: What values or thresholds would indicate a problem worth alerting on?

**Recommended Alert Thresholds:**

| Metric | Warning | Critical | Reasoning |
|--------|---------|----------|-----------|
| Load Average (5-min) | >2x CPU cores | >4x CPU cores | Can't sustain performance |
| Memory Free | <20% available | <10% available | System swapping, apps failing |
| Disk Usage | >80% | >95% | Fills unexpectedly, no room for logs |
| Iowait | >40% | >70% | Disk becoming bottleneck |
| Zombie Processes | >5 | >20 | Resource leak, app not cleaning up |
| Open Files | >5000 | >10000 | FD exhaustion = DOS |
| Uptime change | Unexpected reboot | System crashed | Indicates crash or emergency reboot |

**Design Decision:** Thresholds should be:
- Configurable (different servers need different limits)
- Per-metric (CPU threshold ≠ memory threshold)
- Contextual (load of 4.0 on 16-core = fine; on 2-core = critical)

---

## USERS AND ACTIVITY

### Research Questions Answered

#### Q: How does Linux record who has logged in, when, and from where?

**Login Records (Historical):**

1. **`/var/log/auth.log` (Debian/Ubuntu)**
   - Every SSH login attempt (success and failure)
   - `sudo` usage
   - Format: Text-based, parseable with grep
   - Example: `Jan 15 10:23:45 server sshd[1234]: Accepted password for user from 192.168.1.100 port 55432`

2. **`/var/log/secure` (RHEL/CentOS)**
   - Same as auth.log on Red Hat systems
   - Same format and content

3. **`lastlog` command**
   - Shows last login time for each user
   - Format: User, Port, From, Last login
   - Updates in real-time

4. **`last` command**
   - Reads `/var/log/wtmp`
   - Shows all login/logout history
   - Format: User, Terminal, IP, Login time, Duration

5. **`lastb` command**
   - Reads `/var/log/btmp`
   - Shows **failed** login attempts
   - Red flag: Multiple failed attempts = brute force attempt

6. **`w` command**
   - Shows users currently logged in
   - Which TTY/SSH session
   - Current command/idle time
   - Real-time view of active sessions

7. **`who` command**
   - Similar to `w` but simpler format
   - Just shows who, where, when

8. **`utmp` / `wtmp`**
   - Binary files (not text)
   - Read by `w`, `last`, `lastlog`
   - Contain login/logout records

#### Q: What user activity would look suspicious on a production server?

**Red Flags:**

**1. Unexpected Login Sources**
- SSH from unknown IP
- Multiple failed login attempts before success (brute force)
- Login from geographical impossible location (e.g., US then China in 10 minutes)
- Context: `lastlog` shows someone logged in you didn't approve

**2. Privilege Escalation**
- User running `sudo` commands when normally they don't
- `sudo` to root without approval
- Repeated failed sudo attempts = permissions testing
- Context: Check `/var/log/auth.log` for `sudo COMMAND` entries

**3. New User Accounts**
- New entries in `/etc/passwd`
- Backdoor accounts (often with UID 0 or UID 1000+)
- Hidden accounts (names starting with ".")
- Context: Compare current `/etc/passwd` to baseline

**4. Unusual Login Times**
- Logins during off-hours on a business system
- Logins from non-standard users (app shouldn't need login)
- Context: Normal = business hours from expected IP

**5. Orphaned SSH Keys**
- Unexpected keys in `~/.ssh/authorized_keys`
- Keys with foreign comments
- Context: Attacker maintains access without password

**6. TTY Hijacking**
- Multiple sessions from same user doing different things
- Command history showing unexpected actions
- Context: Attacker using stolen session

#### Q: Where are these records stored? Which commands let you read them?

**Complete Reference:**

| Activity | File | Command | Realtime? |
|----------|------|---------|-----------|
| All logins | `/var/log/wtmp` | `last` | No (historical) |
| Failed logins | `/var/log/btmp` | `lastb` | No (historical) |
| Current sessions | `/var/run/utmp` | `w`, `who` | Yes |
| Auth events | `/var/log/auth.log` | `grep`, `tail` | No (delayed) |
| Last user logins | Binary in `/var` | `lastlog` | No (cached) |
| SSH specifics | `/var/log/auth.log` | `grep sshd` | No (delayed) |
| User accounts | `/etc/passwd` | `getent passwd` | Yes (live) |
| User groups | `/etc/group` | `getent group` | Yes (live) |
| Sudo logs | `/var/log/auth.log` | `grep sudo` | No (delayed) |

---

## PROCESSES

### Research Questions Answered

#### Q: How do you get a full picture of what is running on a system?

**Process Inspection Sources:**

1. **`ps` command**
   - Snapshots process state
   - Can show all processes with `ps aux`
   - Shows owner, PID, CPU%, memory%, command
   - Can see parent-child relationships with `-H` or `-f`
   - Output is static (one-time snapshot)

2. **`top` command**
   - Shows processes sorted by resource usage
   - Real-time updates
   - Shows load average, memory stats
   - Can filter by user with `-u`
   - Harder to parse programmatically (human-readable format)

3. **`/proc` filesystem**
   - `/proc/[pid]/cmdline` = full command line
   - `/proc/[pid]/stat` = resource usage
   - `/proc/[pid]/status` = detailed process info
   - `/proc/[pid]/cwd` = current working directory
   - `/proc/[pid]/exe` = symlink to executable
   - `/proc/[pid]/fd/` = open files/sockets
   - Real-time, machine-readable, no special tools needed

4. **`pstree` command**
   - Shows parent-child process hierarchy
   - Helps identify rogue process spawned by what
   - Useful for identifying injection or fork bombs

5. **`lsof` command**
   - "List open files"
   - Shows what files a process has open
   - Shows network sockets per process
   - Useful for finding what a process is communicating with

#### Q: What would make a process look suspicious?

**Suspicious Indicators:**

| Indicator | Why Suspicious | Detection Method |
|-----------|-----------------|------------------|
| **Location** | `/tmp` is world-writable; legitimate apps shouldn't run there | `ps aux \| grep /tmp` |
| **Ownership** | Root running from user dir; user running system binary | Compare owner to expected |
| **Name** | Misspelled names (e.g., "sshd " with space); hidden names | Character inspection |
| **Parent** | Spawned by unusual parent (e.g., httpd spawning bash) | Check `ppid` in `/proc/[pid]/status` |
| **Resource Usage** | Using 90% CPU/memory on idle system | Compare to baseline |
| **Network** | Opening unexpected ports or making external connections | `netstat -tulnp` filter by PID |
| **No TTY** | Backgrounded (daemon) but not expected | Check `tty` column in `ps` output |
| **Working Directory** | Running from `/dev/shm` or other unusual location | `readlink /proc/[pid]/cwd` |
| **Executable Changed** | File at `/proc/[pid]/exe` modified or deleted | Hash integrity check |

#### Q: Where does Linux store live process information?

**Answer:** `/proc/[pid]/` directory

```
Key files:
/proc/[pid]/cmdline     → Original command line arguments
/proc/[pid]/stat        → CPU/memory/timing statistics
/proc/[pid]/status      → Human-readable process info (ppid, uid, vmsize, etc.)
/proc/[pid]/cwd         → Symlink to working directory
/proc/[pid]/exe         → Symlink to executable binary
/proc/[pid]/fd/         → Symlinks to open files and sockets
/proc/[pid]/limits      → Resource limits
/proc/[pid]/maps        → Memory mapping information
```

**Why this matters:** No special tools needed, just `cat`, `ls`, `readlink`.

---

## NETWORK MONITORING

### Research Questions Answered

#### Q: How do you see what ports a machine is listening on?

**Tools:**

1. **`netstat -tulnp`**
   - `-t` = TCP
   - `-u` = UDP
   - `-l` = Listening
   - `-n` = Numeric (don't resolve DNS)
   - `-p` = Show process/PID for each connection
   - Output: Proto, Local Address, Process Name/PID

2. **`ss -tulnp`** (Modern replacement for netstat)
   - Faster and more powerful than netstat
   - Same flags, similar output
   - Parses `/proc/net/tcp` more efficiently
   - Preferred on modern systems

3. **`/proc/net/tcp` and `/proc/net/udp`**
   - Raw kernel data
   - Format: hex addresses (must convert from hex)
   - Parseable but requires parsing hex
   - No special tools needed

4. **`lsof -i -P -n`**
   - Lists all open files (including network sockets)
   - `-i` = internet connections
   - `-P` = port numbers (not names)
   - `-n` = no DNS resolution
   - Slower than netstat but more comprehensive

#### Q: How do you see active connections and which process is responsible?

**Answer:** Combine netstat/ss with process information:

```bash
# Show which process owns each connection
netstat -tulnp 2>/dev/null | grep ESTABLISHED

# Output example:
# tcp  0  0  192.168.1.1:22  203.0.113.50:58234  ESTABLISHED  23456/sshd
#
# Parse: Process sshd (PID 23456) has connection to 203.0.113.50:58234
```

**Information Available:**
- Source IP/port
- Destination IP/port
- Connection state (ESTABLISHED, LISTEN, TIME_WAIT, etc.)
- Process name and PID

#### Q: What kind of network activity would be a red flag?

**Suspicious Network Patterns:**

| Pattern | Why Suspicious | Detection |
|---------|-----------------|-----------|
| **Unusual port listening** | Port 4444, 5555, 8888, 31337 = backdoor ports | Hardcoded list of known backdoor ports |
| **Process shouldn't have network** | Apache connecting to port 3306 (MySQL) on foreign IP | Baseline: know which processes should be networked |
| **Reverse shell** | Process connecting OUT to attacker IP | High-port outbound connections, monitor `netstat -tan` state |
| **Port hopping** | Port opened briefly then closed, repeating | Monitor netstat output for ephemeral port patterns |
| **High connection count** | 10,000+ connections from one process | DDoS bot; connection count threshold alert |
| **Connection to suspicious IP** | Trying to reach known malware C2 domain | Cross-reference with threat intel |
| **Raw socket creation** | Process using RAW protocol (packet crafting) | Monitor `/proc/net/raw` for unusual activity |

---

## FILE INTEGRITY

### Research Questions Answered

#### Q: Which files on a Linux system are critical enough that any unexpected change should trigger an alert?

**Critical Files by Category:**

**1. User & Authentication**
```
/etc/passwd         → User accounts, UIDs, home dirs
/etc/shadow         → Password hashes (root only)
/etc/group          → Group definitions
/etc/gshadow        → Group passwords
/etc/sudoers        → Sudo permissions
/root/.ssh/authorized_keys     → Root SSH keys
```
Why: Any change = potential backdoor/privesc

**2. System Binaries**
```
/bin/bash           → Shell (attacker modifies for backdoor)
/bin/sh             → Root shell
/usr/bin/sudo       → Privilege escalation tool
/bin/ls             → If modified, can hide files
/bin/ps             → If modified, can hide processes
```
Why: Modified binaries = persistent access

**3. System Configuration**
```
/etc/ssh/sshd_config    → SSH settings
/etc/hostname           → Machine identity
/etc/hosts              → DNS resolution
/etc/fstab              → Filesystem mounting
/etc/crontab            → Scheduled tasks
```
Why: Modifications enable or disable access

**4. Kernel & Boot**
```
/boot/grub/grub.cfg     → Boot configuration
/boot/vmlinuz-*         → Kernel image
/lib/modules/*/         → Kernel modules (rootkits)
```
Why: Modifications persist across reboots

**5. Logging**
```
/var/log/auth.log       → Login records
/var/log/syslog         → System events
/var/log/wtmp           → Login history
```
Why: Attacker deletes logs to hide activity

#### Q: What file attributes or permissions settings are known to be dangerous if misconfigured?

**Permission Red Flags:**

| File | Dangerous Permission | Normal Permission | Why |
|------|----------------------|------------------|-----|
| `/etc/passwd` | Writable by non-root (666) | 644 (rw-r--r--) | Attacker adds user |
| `/etc/shadow` | Readable by non-root (644) | 600 (-rw-------) | Password hashes exposed |
| `/etc/sudoers` | Writable by non-root (644) | 440 (-r--r-----) | Attacker gets sudo |
| `/root/.ssh` | World-readable (755) | 700 (drwx------) | SSH keys exposed |
| SUID binaries | Setuid on unusual files | Only on `/bin/sudo`, `/bin/passwd`, etc. | Privilege escalation |
| World-writable | `/tmp` and `/var/tmp` is OK; others not | 777 only on /tmp | Malicious code injection |
| Symlinks in sensitive dirs | Symlink pointing to important files | Should not exist in /etc | Privilege escalation |

**SUID Binaries:**
```
Legitimate: /bin/passwd, /usr/bin/sudo, /bin/mount
Suspicious: Any SUID on /home, /opt, /tmp, /var
Detection: find / -perm -4000 2>/dev/null (finds SUID files)
```

#### Q: How do you detect whether a file was modified recently?

**Detection Methods:**

**1. Timestamp Comparison**
```bash
stat /etc/passwd | grep Modify
# Shows: Modify: 2024-01-15 14:32:10.123456789 -0500

# Compare to baseline:
baseline_time=$(stat -c %Y /var/lib/hids/baseline/passwd.time)
current_time=$(stat -c %Y /etc/passwd)
if [[ $current_time -ne $baseline_time ]]; then
    echo "FILE MODIFIED"
fi
```

**2. Hash-Based Integrity (Better)**
```bash
# Create baseline
sha256sum /etc/passwd > /var/lib/hids/baseline/passwd.sha256
# Later, check
sha256sum -c /var/lib/hids/baseline/passwd.sha256
# If output says "FAILED", file was modified
```

**3. Permission Comparison**
```bash
stat -c "%a %u:%g" /etc/passwd
# Compare to baseline
```

**4. Find by Modification Time**
```bash
# Find files modified in last hour
find /etc -type f -mmin -60 -ls

# Find files modified after a specific time
find /etc -type f -newermt "2024-01-15 14:00:00"
```

**Why Hash-Based is Better:**
- Timestamp can be forged
- Hash detects any change (byte-level)
- Can't be bypassed by attacker setting mtime back

---

## LOGGING AND ALERTING

### Research Questions Answered

#### Q: Where do Linux systems store their logs by default? What does each log file record?

**Standard Log Locations:**

| Log File | Content | Severity | Parseable |
|----------|---------|----------|-----------|
| `/var/log/auth.log` | Login, sudo, authentication events | High | Yes (grep-friendly) |
| `/var/log/syslog` | General system messages | Medium | Yes |
| `/var/log/kernel.log` | Kernel messages | High | Yes |
| `/var/log/dmesg` | Kernel ring buffer (boot messages) | Medium | Yes |
| `/var/log/wtmp` | Login/logout history | High | Binary (use `last`) |
| `/var/log/btmp` | Failed login attempts | High | Binary (use `lastb`) |
| `/var/log/secure` | RHEL/CentOS auth log | High | Yes |
| `/var/log/messages` | RHEL/CentOS general log | Medium | Yes |
| `/var/log/audit/audit.log` | Auditd system call logs | Very High | Yes (complex) |
| Application logs | Varies by app | Medium-High | App-specific |

**Log Rotation:**
```
Managed by /etc/logrotate.d/
Default: Daily rotation, 4 week retention
Compressed: .gz, .bz2 formats
Archived: Old logs moved to .1, .2, etc.
```

#### Q: What format do professional security tools use for structured alerts? Why does format matter?

**Alert Format Options:**

**1. Human-Readable (Not Ideal)**
```
[INFO] System check complete
[ALERT] High CPU usage: 85%
```
Problems: Hard to parse, inconsistent, can't correlate automatically

**2. Structured (Log4j/Syslog Format)**
```
[2024-01-15 14:32:10] [HIDS] [CRITICAL] FILE_INTEGRITY: /etc/passwd modified
```
Better: Timestamp, source, severity, category, message. Can be parsed.

**3. JSON (Best for Integration)**
```json
{
  "timestamp": "2024-01-15T14:32:10Z",
  "source": "HIDS",
  "severity": "CRITICAL",
  "alert_type": "FILE_INTEGRITY",
  "target": "/etc/passwd",
  "message": "File integrity violation detected",
  "baseline_hash": "abc123...",
  "current_hash": "xyz789...",
  "recommendation": "Investigate file modifications"
}
```
Best: Machine-readable, hierarchical, integrates with SIEM, dashboards, alerting systems.

**4. CSV (For Data Analysis)**
```
timestamp,severity,type,target,process_id,message
2024-01-15T14:32:10Z,CRITICAL,FILE_INTEGRITY,/etc/passwd,0,File modified
```
Good: Importable to Excel, databases, graphing tools

**Why Format Matters:**

1. **Parseable by Other Tools**
   - SIEM systems expect JSON or syslog format
   - Can't integrate if format is custom

2. **Consistent Structure**
   - Every alert has timestamp, severity, type
   - Allows correlation ("find all CRITICAL alerts in past hour")

3. **Non-Ambiguous**
   - Dates must be ISO 8601 (2024-01-15, not 01/15/2024)
   - Severity must be consistent (CRITICAL, HIGH, MEDIUM, LOW)
   - Field order predictable

4. **Filterable**
   - Can grep/jq for alerts of specific type
   - Can redirect different severities to different logs

5. **Traceable**
   - Timestamp allows correlation with other logs
   - Can reconstruct attack timeline

#### Q: What is the difference between a tool that floods you with alerts and one you can actually trust?

**Alert Fatigue Problem:**

Bad Tool:
```
[ALERT] New process detected: /usr/bin/python
[ALERT] User logged in: root
[ALERT] Memory usage: 45%
[ALERT] New file created: /var/log/apt/history.log
... 1000 more alerts ...
```
Result: Operator reads 5 alerts, then stops opening alerts at all.

Good Tool:
```
[CRITICAL] FILE_INTEGRITY: /etc/passwd - hash mismatch
[HIGH] PROCESS_ANOMALY: /tmp/suspicious_binary spawned as root
[HIGH] USER_ANOMALY: New account 'attacker' added to system
```
Result: 3 alerts, all actionable, operator investigates every one.

**How to Achieve This:**

1. **Establish Baseline**
   - Normal = what the tool records on first run
   - Only alert on deviation from baseline
   - Example: "New user" alert only if user wasn't there before

2. **Thresholds Over Absolutes**
   - Don't alert on "any process"
   - Alert on "process from /tmp" (baseline: none should be there)
   - Alert on "5+ failed logins in 5 minutes" (baseline: 0-1 per day)

3. **Whitelisting**
   - Known-good processes, users, files
   - Expected cron jobs
   - Legitimate system changes
   - Example: `sudo` creating temp files is OK; random binary in /tmp is not

4. **Severity Tuning**
   - CRITICAL: Immediate threat (new root account, modified /etc/passwd)
   - HIGH: Likely threat (process from /tmp, unexpected open port)
   - MEDIUM: Worth investigating (high resource usage, unusual login time)
   - LOW/INFO: FYI (system updated, backup ran)

5. **Correlation** (Advanced)
   - 1 failed login = INFO
   - 10 failed logins from same IP in 2 minutes = HIGH (brute force)
   - 1 new user account = MEDIUM
   - New user account + SSH key added + open unusual port = CRITICAL (coordinated attack)

---

## DESIGN DECISIONS

### Decision 1: Baseline Model vs. Hardcoded Thresholds

**Option A: Hardcoded Thresholds**
```bash
if [ $cpu_usage -gt 80 ]; then
    alert "CPU high"
fi
```
Pros: Simple, immediate  
Cons: Wrong threshold for every different server

**Decision: Use Baseline Model**

On first run: Record normal state (load, memory, users, processes, files)  
On subsequent runs: Compare to baseline, alert on anomalies

**Reasoning:**
- Adapts to any server size/configuration
- Reduces false positives
- Enables meaningful "deviation" detection
- Professional tools (Wazuh, OSSEC) all use this approach

### Decision 2: What to Log and At What Severity

**Our Alert Taxonomy:**

```
CRITICAL (immediate threat, take action now):
├─ File integrity violation on critical file
├─ New user account created
├─ SSH key added to authorized_keys
├─ Process running from /tmp
├─ Rootkit/suspicious kernel module detected
└─ Sudoers file modified

HIGH (likely threat, investigate in hours):
├─ Unexpected open port
├─ Process with unusual parent
├─ Many failed login attempts
├─ Unusual privilege escalation attempt
└─ Permission change on critical file

MEDIUM (unusual but not necessarily malicious):
├─ High resource usage (CPU/memory/disk)
├─ User login at unusual time
├─ New cron job created
└─ System configuration change

LOW (informational, FYI):
├─ System update detected
├─ Backup completed
└─ Scheduled maintenance
```

**Reasoning:**
- Operators only investigate CRITICAL/HIGH alerts
- False positives sink tool credibility
- Severity scaled to urgency

### Decision 3: Modular vs. Monolithic Architecture

**Option A: Single Script**
- All logic in one file
- Pros: Simple, single entry point
- Cons: Hard to maintain, functions get lost

**Option B: Modular Scripts**
- Separate script per module
- Pros: Can run modules independently, easy to maintain
- Cons: More coordination needed

**Decision: Modular with Coordinator Script**

Structure allows:
- Testing each module independently
- Easy understanding by new team members
- Parallel execution potential
- Clear code organization

### Decision 4: Configuration

**Approach: Config File + Defaults**

```bash
# /var/lib/hids/hids.conf
CPU_LOAD_WARNING=2.0
CPU_LOAD_CRITICAL=4.0
MEMORY_USED_WARNING=80
MEMORY_USED_CRITICAL=95
DISK_USED_WARNING=80
DISK_USED_CRITICAL=95
FAILED_LOGIN_THRESHOLD=5
FAILED_LOGIN_WINDOW_MINUTES=5
SUSPICIOUS_PORTS="4444 5555 6666 7777 8888 31337"
MONITORED_FILES="/etc/passwd /etc/shadow /etc/sudoers /root/.ssh/authorized_keys"
```

**Reasoning:**
- No need to edit scripts
- Different environments can have different configs
- Professional tools all use this pattern
- Easy to version control

### Decision 5: Automation Mechanism

**Option A: Cron**
- Simple, reliable, industry standard
- Can set any interval
- Logs to syslog/mail

**Option B: Systemd Timer**
- Modern, more powerful
- Can run on boot, at specific times, intervals
- Better integration with system startup

**Decision: Both (make configurable)**

Default to cron for portability:
```bash
*/5 * * * * /usr/local/sbin/hids 2>&1 | logger -t hids
```

Can optionally use systemd timer if systemd is available.

**Reasoning:**
- Works on all Linux systems
- Can easily switch between methods
- Professional tools support both

### Decision 6: Data Persistence and Retention

**Alert Log:**
- Location: `/var/lib/hids/alerts.log`
- Format: Structured (JSON or tab-delimited)
- Retention: Infinite (append-only)
- Rotation: External tool (logrotate) after 30 days

**Baseline:**
- Location: `/var/lib/hids/baseline/`
- Format: Per-file (one hash per file)
- Updated: Manually with `hids --reset-baseline`
- Versioning: Old baselines archived with timestamp

**Scan Output:**
- Location: `/var/lib/hids/scan.log`
- Rotation: Daily, keep 7 days
- Format: Human-readable (not used for alerts, just audit trail)

**Reasoning:**
- Alerts are immutable (can't be altered)
- Baselines controlled by operator
- Scan logs for debugging only
- Professional retention = years not weeks

---

## IMPLEMENTATION RECOMMENDATIONS

### Phase 2 Build Order

1. **Start with Alerting Module**
   - Build alert function first
   - All modules depend on it
   - Test alert output format

2. **Then System Health**
   - Easiest module
   - Good for testing baseline/thresholds
   - Validates alert mechanism

3. **Then User Activity**
   - Foundation for understanding baselines
   - Helps with later modules

4. **Then Processes & Network**
   - Most complex module
   - Requires good baseline system
   - Needs rigorous thresholds

5. **Finally File Integrity**
   - Most powerful detection
   - Depends on baseline system working well
   - Highest confidence alerts

6. **Throughout: Testing**
   - Build alert trigger scenarios
   - Validate false positives
   - Tune thresholds

---

## TOOLS & COMMANDS REFERENCE

**System Health:**
```bash
uptime                  # Load average
free -h                 # Memory usage
df -h                   # Disk usage
top -b -n1              # Full system overview
ps aux                  # All processes
```

**User Activity:**
```bash
w                       # Current users
last -n 20              # Login history
lastb                   # Failed logins
lastlog                 # Most recent login per user
getent passwd           # Current users
grep sshd /var/log/auth.log
```

**Processes & Network:**
```bash
ps aux                  # Running processes
netstat -tulnp          # Listening ports + processes
ss -tulnp               # Modern version of netstat
lsof -i -n              # Open internet connections
```

**File Integrity:**
```bash
sha256sum /etc/passwd   # Create hash
stat /etc/passwd        # File metadata
find / -perm -4000      # SUID files
```

---

## CONCLUSION

### Key Takeaways

1. **Baseline is Everything** - Normal behavior detection is more valuable than hardcoded thresholds

2. **Context Matters** - Same metric means different things on different servers

3. **Signal Over Noise** - Alert fatigue is worse than missing alerts; trust comes from accuracy

4. **Structured Data** - Well-formatted logs can be parsed, correlated, and integrated

5. **Automation is Non-Negotiable** - Manual monitoring fails; automation must run unattended

6. **Severity is Actionability** - CRITICAL = stop everything; MEDIUM = keep working; make clear distinctions

### Design Principle

**"Detection through deviation."**

Record what normal looks like. Alert when reality deviates. Make the deviation intelligible. Repeat.

This is the principle behind every professional monitoring tool. It's also achievable with Bash, native Linux tools, and careful design.

---

## REFERENCES

### Commercial HIDS Tools
- [Wazuh](https://wazuh.com/) - File integrity, log analysis, multi-agent
- [OSSEC](https://www.ossec.net/) - Pioneering HIDS, file monitoring, log parsing
- [Auditd](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/security_guide/chap-system_auditing) - Kernel-level system call auditing
- [Tripwire](https://www.tripwire.com/) - File integrity focused

### Linux Monitoring Tools
- [sysstat](https://github.com/sysstat/sysstat) - System statistics collection
- [fail2ban](https://www.fail2ban.org/) - Log-based intrusion prevention
- [logwatch](https://sourceforge.net/projects/logwatch/) - Log analysis and summarization

### Linux Documentation
- [Linux man pages](https://man7.org/linux/man-pages/) - Official command documentation
- [/proc filesystem](https://man7.org/linux/man-pages/man5/proc.5.html) - Virtual filesystem reference
- [Linux Foundation](https://www.linuxfoundation.org/) - General Linux resources

### Security Concepts
- [CIS Benchmarks](https://www.cisecurity.org/) - Security configuration standards
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework/) - Federal security guidelines
- [OWASP Top 10](https://owasp.org/www-project-top-ten/) - Security vulnerabilities

---

## TEAM INFORMATION

**Project:** Linux Capstone - Host Intrusion Detection System  
**Team Size:** 4 people  
**Timeline:** 1 week  
**Date Completed:** [Completion Date]  
**Institution:** [Your School/Organization]  

---

## DOCUMENT INFORMATION

**Document Version:** 1.0  
**Last Updated:** [Date]  
**Status:** Complete  
**Total Words:** 3500+  
**Pages:** 12+  

This research document was completed BEFORE coding began. All design decisions reference and are justified by this document.

---

**Ready to build. All questions answered. Design decisions documented.** 🚀
