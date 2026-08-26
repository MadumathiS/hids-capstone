# HIDS Architecture & Decision Flow

## 🏗️ HIDS System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       SYSTEM TO PROTECT                          │
│  (Your Linux Server - Assume Breach Has Already Occurred)        │
└─────────────────────────────────────────────────────────────────┘

                              ↓

┌─────────────────────────────────────────────────────────────────┐
│                    HIDS SCANNER (Runs Periodically)              │
│                   (Every 5 mins, hourly, daily)                  │
└─────────────────────────────────────────────────────────────────┘

    ├─→ [PROCESS MONITOR] → Are bad processes running?
    │       ├─ Check /tmp for executables
    │       ├─ Find backgrounded processes
    │       └─ Detect hidden process names
    │
    ├─→ [FILE INTEGRITY] → Have critical files changed?
    │       ├─ /etc/passwd
    │       ├─ /etc/shadow
    │       ├─ /root/.ssh/authorized_keys
    │       ├─ /etc/sudoers
    │       └─ System binaries
    │
    ├─→ [USER MONITOR] → Who's accessing the system?
    │       ├─ Currently logged-in users
    │       ├─ Recent login attempts
    │       ├─ Failed login tries
    │       └─ New user accounts
    │
    ├─→ [NETWORK MONITOR] → What connections are active?
    │       ├─ Listening ports
    │       ├─ Established connections
    │       ├─ Suspicious ports (4444, 5555, etc.)
    │       └─ Unusual outbound traffic
    │
    ├─→ [CRON/TASKS] → What's scheduled to run?
    │       ├─ System crontab
    │       ├─ User crontabs
    │       └─ Systemd timers
    │
    ├─→ [PERSISTENCE] → Are backdoors installed?
    │       ├─ Init.d scripts
    │       ├─ Systemd services
    │       └─ Shell startup files
    │
    ├─→ [ROOTKIT CHECK] → Is kernel compromised?
    │       ├─ Kernel modules
    │       ├─ Orphaned processes
    │       └─ Binary integrity
    │
    └─→ [LOG ANALYSIS] → What happened?
            ├─ Auth logs
            ├─ Privilege escalation
            └─ Failed attempts

                              ↓

            ┌───────────────────────────────┐
            │  DETECTION DECISION ENGINE    │
            │  (Compare to Baseline)        │
            └───────────────────────────────┘
                        ↓
         ┌──────────────┬──────────────┐
         │              │              │
         ↓              ↓              ↓
    MATCH FOUND    NO MATCH      SUSPICIOUS
    (All clear)    (Nothing new)  (Possible threat)
         │              │              │
         └──────────────┼──────────────┘
                        ↓
            ┌───────────────────────────┐
            │    GENERATE ALERTS        │
            │  - CRITICAL               │
            │  - HIGH                   │
            │  - MEDIUM                 │
            └───────────────────────────┘
                        ↓
            ┌───────────────────────────┐
            │   WRITE TO LOGS           │
            │  - /var/lib/hids/         │
            │    alerts.log             │
            │  - /var/lib/hids/         │
            │    scans.log              │
            └───────────────────────────┘
                        ↓
            ┌───────────────────────────┐
            │   NOTIFY ADMINISTRATOR    │
            │  (Optional: Email/Slack)  │
            └───────────────────────────┘
```

---

## 🔍 Detection Decision Tree

```
                        START SCAN
                           ↓
                    ┌──────────────┐
                    │ Process      │
                    │ Monitoring   │
                    └──────┬───────┘
                           ↓
          ┌────────────────────────────────┐
          │ Is process in /tmp? OR         │
          │ suspicious name? OR            │
          │ unusual behavior?              │
          └────┬───────────────────────┬───┘
               │                       │
              YES                      NO
               │                       │
               ↓                       ↓
         [ALERT HIGH]          [CONTINUE]
         "Suspicious            │
          Process"              │
               │                │
               └────────┬───────┘
                        ↓
                 ┌──────────────────┐
                 │ File Integrity   │
                 │ Check            │
                 └────────┬─────────┘
                          ↓
         ┌────────────────────────────────┐
         │ SHA256 hash matches baseline?   │
         └────┬───────────────────────┬───┘
              │                       │
             YES                      NO
              │                       │
              ↓                       ↓
        [CONTINUE]             [ALERT CRITICAL]
        File unchanged         "File Modified"
              │                (MAJOR RED FLAG)
              │                       │
              └────────────┬──────────┘
                           ↓
                    ┌─────────────────┐
                    │ User & Access   │
                    │ Monitoring      │
                    └─────────┬───────┘
                              ↓
        ┌─────────────────────────────────┐
        │ New user accounts? OR            │
        │ unusual SSH keys? OR             │
        │ failed login attempts?           │
        └────┬──────────────────────┬──────┘
             │                      │
            YES                     NO
             │                      │
             ↓                      ↓
       [ALERT HIGH]          [CONTINUE]
       "User Activity"             │
             │                     │
             └────────┬────────────┘
                      ↓
               ┌──────────────────┐
               │ Network          │
               │ Monitoring       │
               └────────┬─────────┘
                        ↓
      ┌─────────────────────────────────┐
      │ Suspicious ports? OR             │
      │ unusual outbound? OR             │
      │ unknown connections?             │
      └────┬──────────────────────┬──────┘
           │                      │
          YES                     NO
           │                      │
           ↓                      ↓
     [ALERT HIGH]          [CONTINUE]
     "Network Activity"           │
           │                      │
           └────────┬─────────────┘
                    ↓
             ┌─────────────────┐
             │ Rootkit & Kernel│
             │ Check           │
             └─────────┬───────┘
                       ↓
    ┌──────────────────────────────────┐
    │ Suspicious kernel modules? OR    │
    │ orphaned processes? OR           │
    │ binary integrity issues?         │
    └────┬──────────────────────┬──────┘
         │                      │
        YES                     NO
         │                      │
         ↓                      ↓
   [ALERT CRITICAL]       [CONTINUE]
   "Rootkit/Kernel        │
    Compromise"                │
         │                     │
         └────────┬────────────┘
                  ↓
        ┌──────────────────┐
        │ Generate Report  │
        │ & Log Results    │
        └────────┬─────────┘
                 ↓
        ┌──────────────────┐
        │ SCAN COMPLETE    │
        └──────────────────┘
```

---

## 🎯 Detection Methodology

### Layer 1: Behavioral Monitoring
```
What it detects: WHAT IS HAPPENING RIGHT NOW
├─ Running processes
├─ Network connections
├─ Logged-in users
└─ Open file handles

Speed: REAL-TIME (or near-real-time if scanned frequently)
False Positives: MEDIUM (many legitimate processes)
Effectiveness: HIGH (catches active threats)
```

### Layer 2: Integrity Monitoring
```
What it detects: WHAT HAS CHANGED
├─ Modified files
├─ New files created
├─ Permission changes
└─ Deleted files

Speed: FAST (only checks critical files)
False Positives: LOW (only legitimate updates)
Effectiveness: VERY HIGH (catches modifications)
```

### Layer 3: Persistence Detection
```
What it detects: HOW WILL THIS KEEP RUNNING
├─ Cron jobs
├─ Systemd services
├─ Init scripts
└─ Shell startup files

Speed: SLOW (must parse all configs)
False Positives: LOW (persistence mechanisms are tracked)
Effectiveness: VERY HIGH (catches backdoors)
```

### Layer 4: Anomaly Detection
```
What it detects: WHAT'S UNUSUAL
├─ Unexpected login attempts
├─ Privilege escalation
├─ Suspicious process names
└─ Unknown network ports

Speed: MEDIUM (requires comparison)
False Positives: HIGH (depends on baseline)
Effectiveness: MEDIUM (needs good baseline)
```

---

## 📊 Threat Hunting Workflow

```
┌────────────────────────────────────────────┐
│ 1. RUN BASELINE (Day 1 - Clean System)     │
│                                             │
│ Command: hids_scanner.sh --baseline        │
│ Creates: /var/lib/hids/baselines/          │
│ Purpose: Snapshot of "good state"          │
│                                             │
│ Baseline contains:                         │
│ ├─ SHA256 hashes of critical files         │
│ ├─ File sizes                              │
│ ├─ User lists                              │
│ └─ Current cron configurations             │
└────────────────────────────────────────────┘
                     ↓
┌────────────────────────────────────────────┐
│ 2. CONTINUOUS SCANNING (Daily/Hourly)      │
│                                             │
│ Command: hids_scanner.sh                   │
│ Frequency: Every 5 min - every 24 hours    │
│ Checks: Current state vs. baseline         │
│ Output: Alerts if differences found        │
│                                             │
│ Produces:                                  │
│ ├─ /var/lib/hids/alerts.log (threats)     │
│ └─ /var/lib/hids/scans.log (details)      │
└────────────────────────────────────────────┘
                     ↓
┌────────────────────────────────────────────┐
│ 3. ALERT ANALYSIS (When Alerts Appear)     │
│                                             │
│ Review: /var/lib/hids/alerts.log           │
│ Determine:                                 │
│ ├─ What changed? (WHAT)                    │
│ ├─ When did it change? (WHEN)              │
│ ├─ Why did it change? (WHY)                │
│ └─ Should this change be here? (VALID?)    │
│                                             │
│ Questions to ask:                          │
│ • Did I authorize this change?             │
│ • Do I know what this file/process is?     │
│ • Has the system been compromised?         │
│ • Is this a false alarm?                   │
└────────────────────────────────────────────┘
                     ↓
┌────────────────────────────────────────────┐
│ 4. DECISION: Is it legitimate?             │
│                                             │
│        ┌──────────────┬──────────────┐     │
│        │              │              │     │
│        ↓              ↓              ↓     │
│      YES            NO           MAYBE     │
│    (Legitimate)  (Compromise)  (Unknown)   │
│        │              │              │     │
│        ↓              ↓              ↓     │
│      ACK         INVESTIGATE    MONITOR    │
│    Update       Kill process,   Review     │
│    baseline     block ports,    logs,      │
│    Rerun        preserve logs   run more   │
│    scan                         tests      │
└────────────────────────────────────────────┘
```

---

## 🛡️ Threat Response Playbook

### Scenario 1: "FILE INTEGRITY VIOLATION"
```
Alert: [CRITICAL] FILE INTEGRITY VIOLATION: /etc/passwd

Investigation Steps:
├─ 1. Check WHEN it changed
│    $ stat /etc/passwd | grep Modify
│
├─ 2. See WHAT changed
│    $ diff /var/lib/hids/baselines/passwd.sha256 <(sha256sum /etc/passwd)
│
├─ 3. Look for new users
│    $ tail -n +$(wc -l /var/lib/hids/baselines/passwd.hash) /etc/passwd
│
├─ 4. Check WHO changed it
│    $ grep "usermod\|useradd" /var/log/auth.log | tail -20
│
├─ 5. WHO WAS LOGGED IN?
│    $ last | head -20
│
└─ 6. DECISION
    Is there a new user? → LIKELY COMPROMISED
    Did you make changes? → False alarm, update baseline
    Unknown? → Investigate more
```

### Scenario 2: "SUSPICIOUS PROCESS FROM /tmp"
```
Alert: [HIGH] Process running from /tmp: /tmp/bot

Investigation Steps:
├─ 1. Find the process
│    $ ps aux | grep /tmp
│
├─ 2. What's it doing?
│    $ ls -la /proc/<PID>/
│    $ cat /proc/<PID>/cmdline
│
├─ 3. What files did it create?
│    $ find /tmp -type f -newer /var/lib/hids -name "*bot*"
│
├─ 4. Is it making network connections?
│    $ netstat -tulnp | grep <PID>
│
├─ 5. Kill it
│    $ kill -9 <PID>
│
└─ 6. RESPONSE
    Block incoming connections
    Remove related files
    Patch the vulnerability
    Re-baseline
```

### Scenario 3: "POSSIBLE ROOTKIT DETECTED"
```
Alert: [CRITICAL] POSSIBLE ROOTKIT DETECTED: diamorphine

Investigation Steps:
├─ 1. Verify the module is loaded
│    $ lsmod | grep diamorphine
│
├─ 2. Try to unload it
│    $ rmmod diamorphine  (might fail if rootkit protects itself)
│
├─ 3. Find where it came from
│    $ find / -name "*diamorphine*" 2>/dev/null
│
├─ 4. Check system for other indicators
│    $ chkrootkit  (if available)
│    $ rkhunter --check  (if available)
│
├─ 5. Boot into single-user/recovery mode
│    System must be rebooted to safely remove kernel code
│
└─ 6. RESPONSE
    ⚠️  CRITICAL: System is deeply compromised
    ⚠️  This is a full system compromise
    ⚠️  Rebuilding from backup/clean install recommended
    ⚠️  Do not trust any data on this system
```

---

## 📈 HIDS Effectiveness Matrix

```
┌─────────────────────────┬──────────┬──────────┬────────────┐
│ Threat Type             │ Detection│ Speed    │ False Pos. │
├─────────────────────────┼──────────┼──────────┼────────────┤
│ New user account        │ Very Good│ Instant  │ Low        │
│ Unauthorized SSH key    │ Very Good│ Instant  │ Low        │
│ Modified /etc/passwd    │Excellent │ Instant  │ Very Low   │
│ Process in /tmp         │ Very Good│ Instant  │ Medium     │
│ Cron backdoor           │ Very Good│ Instant  │ Low        │
│ Rootkit module          │ Very Good│ Instant  │ Low        │
│ Active network session  │ Good     │ Instant  │ High       │
│ Modified binary         │Excellent │ Instant  │ Very Low   │
│ Privilege escalation    │ Very Good│ Fast     │ Medium     │
│ Data exfiltration       │ Fair     │ Instant  │ High       │
│ Lateral movement        │ Fair     │ Medium   │ High       │
│ Web shell upload        │ Very Good│ Instant  │ Low        │
└─────────────────────────┴──────────┴──────────┴────────────┘

Legend:
- Excellent = Almost never missed, almost never false alarm
- Very Good = Usually catches it, few false alarms
- Good = Usually catches it, some false alarms
- Fair = Catches some, higher false alarm rate
- Low = Not good at detecting this
```

---

## 🔄 Integration with Other Tools

```
                    ┌──────────────────────┐
                    │   HIDS Scanner       │
                    │  (What's inside now) │
                    └──────────┬───────────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
                ↓              ↓              ↓
          ┌─────────────┐  ┌──────────┐  ┌──────────┐
          │   Syslog    │  │ Auditd   │  │ Firewall │
          │ (What went  │  │ (System  │  │ (What    │
          │  wrong)     │  │  calls)  │  │ came in) │
          └──────┬──────┘  └────┬─────┘  └────┬─────┘
                 │              │             │
                 └──────────────┼─────────────┘
                                │
                        ┌───────↓────────┐
                        │  CORRELATION   │
                        │   ENGINE       │
                        │                │
                        │ "So here's     │
                        │  what REALLY   │
                        │  happened"     │
                        └────────┬───────┘
                                 │
                        ┌────────↓──────────┐
                        │ INCIDENT RESPONSE │
                        │ (You fix it)      │
                        └───────────────────┘
```

---

## ✅ HIDS Limitations (Know This!)

HIDS is great at detecting threats AFTER they're inside, but:

```
❌ Can't prevent malware from entering
   → Firewall + Network IDS do this

❌ Can't detect all zero-day exploits
   → Vulnerability scanners + patching needed

❌ Can't protect against sophisticated attackers who disable HIDS
   → Immutable logs + remote syslog needed

❌ Generates false alarms (normal system changes)
   → Good baseline + tuning needed

❌ Can't see encrypted traffic
   → Deep packet inspection needed for that

✅ IS good at detecting: backdoors, persistence, privilege escalation,
                        unauthorized access, file modifications
```

---

**HIDS = The security guard INSIDE the house. Essential, but not your only defense.**
