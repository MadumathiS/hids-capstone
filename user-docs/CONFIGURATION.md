# COMPLETE HIDS REPOSITORY SETUP - STEP BY STEP

**Timeline:** ~30 minutes total  
**Difficulty:** Easy (just following commands)  
**Result:** Fully functional GitHub repository ready for team collaboration

---

## PART 1: INITIAL SETUP (10 Minutes)

### Step 1.1: Create Local Directory Structure

Open your terminal and run these commands:

```bash
# Create main project directory
mkdir hids-capstone
cd hids-capstone

# Initialize git
git init

# Create all directories
mkdir -p docs
mkdir -p src/config
mkdir -p src/lib
mkdir -p tests
mkdir -p demo
mkdir -p user-docs
mkdir -p deployment
mkdir -p team
mkdir -p .github

# Verify structure
ls -la
# Should show all the directories you created
```

### Step 1.2: Create Core Configuration Files

#### Create .gitignore File

```bash
cat > .gitignore << 'EOF'
# HIDS runtime and logs
/var/lib/hids/
/var/log/hids*
*.log
*.log.*
*.gz

# System and editor files
.DS_Store
.swp
*~
*.bak
*.swp
.vscode/
.idea/
*.sublime-project
*.sublime-workspace

# Local testing
test_output/
temp/
sandbox/
*.tmp

# Credentials - NEVER commit these!
*.key
*.pem
*.ppk
*password*
*secret*
*credentials*
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.iml

# OS
Thumbs.db
.DS_Store
EOF

echo "✅ .gitignore created"
```

#### Create LICENSE File (MIT)

```bash
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2024 HIDS Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

echo "✅ LICENSE created"
```

#### Create CONTRIBUTING.md

```bash
cat > CONTRIBUTING.md << 'EOF'
# Contributing to HIDS

This is a capstone project. Contributions are limited to assigned team members.

## Workflow

1. **Create a branch** for your work
   ```bash
   git checkout -b person-a-system-module
   ```

2. **Make your changes**
   - Work on your assigned module
   - Test thoroughly
   - Update documentation

3. **Commit with clear messages**
   ```bash
   git add docs/research.md
   git commit -m "Complete system health module documentation"
   ```

4. **Push to GitHub**
   ```bash
   git push origin person-a-system-module
   ```

5. **Create Pull Request** (optional, for review)

## Team Members

- Person A: System/Network Module
- Person B: User & File Integrity
- Person C: Alerting & Automation
- Person D: Documentation & Demo

## Questions?

Contact your team lead or instructor.
EOF

echo "✅ CONTRIBUTING.md created"
```

---

## PART 2: COPY YOUR HIDS SCRIPTS (5 Minutes)

### Step 2.1: Copy Main HIDS Script

```bash
# Copy the main HIDS script
cp /path/to/hids_scanner.sh src/hids

# Make it executable
chmod 755 src/hids

# Verify
ls -la src/hids
# Should show: -rwxr-xr-x
```

### Step 2.2: Create Configuration File Template

```bash
cat > src/config/hids.conf << 'EOF'
# HIDS Configuration File
# Customize thresholds for your environment

## System Health Thresholds
# CPU load relative to number of cores
CPU_LOAD_WARNING=2.0
CPU_LOAD_CRITICAL=4.0

# Memory usage percentage
MEMORY_USED_WARNING=80
MEMORY_USED_CRITICAL=95

# Disk usage percentage
DISK_USED_WARNING=80
DISK_USED_CRITICAL=95

# I/O wait percentage
IOWAIT_WARNING=40
IOWAIT_CRITICAL=70

## User Activity Thresholds
# Failed login attempts before alerting
FAILED_LOGIN_THRESHOLD=5

# Time window for failed login counting (minutes)
FAILED_LOGIN_WINDOW_MINUTES=5

## Network Monitoring
# Known backdoor/suspicious ports
SUSPICIOUS_PORTS="4444 5555 6666 7777 8888 31337"

# Suspicious process locations
SUSPICIOUS_LOCATIONS="/tmp /var/tmp /dev/shm"

## Files to Monitor for Integrity
# Critical files that should never change
MONITORED_FILES="/etc/passwd /etc/shadow /etc/sudoers /etc/ssh/sshd_config /root/.ssh/authorized_keys /bin/bash /usr/bin/sudo"

## Alerting Settings
ALERT_LOG="/var/lib/hids/alerts.log"
SCAN_LOG="/var/lib/hids/scans.log"
BASELINE_DIR="/var/lib/hids/baselines"

# Log level: DEBUG, INFO, WARNING, CRITICAL
LOG_LEVEL="INFO"

## Email Alerts (Optional)
ENABLE_EMAIL_ALERTS="no"
EMAIL_RECIPIENT="admin@example.com"

## Advanced Settings
# Keep only last N scans
SCAN_HISTORY_DAYS=30

# Enable performance metrics
COLLECT_METRICS="yes"
EOF

echo "✅ Configuration template created"
```

---

## PART 3: CREATE DOCUMENTATION FILES (10 Minutes)

### Step 3.1: Copy Research Document

```bash
# Copy your research.md to docs/
cat > docs/research.md << 'EOF'
[Paste the entire contents of research_FINAL.md here]

# Team: [Your Team Name]
# Date: [Today's Date]
EOF

echo "✅ docs/research.md created"
```

**IMPORTANT:** Replace `[Paste the entire contents...]` with the actual research.md content from earlier.

### Step 3.2: Create Main README.md

This is your repository's main file - visitors see this first:

```bash
cat > README.md << 'EOF'
# HIDS - Host Intrusion Detection System

**Team Capstone Project: Monitor, detect, and respond to intrusions on Linux systems**

![Status](https://img.shields.io/badge/status-complete-brightgreen)
![Team Size](https://img.shields.io/badge/team-4%20people-blue)
![Timeline](https://img.shields.io/badge/timeline-1%20week-orange)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## 📋 Quick Overview

This is a **Host Intrusion Detection System (HIDS)** - a security tool that monitors Linux systems for threats. Think of it as a security guard inside your system watching for suspicious activity.

### The Five Monitoring Modules

1. **System Health** - CPU, memory, disk usage
2. **User Activity** - Login attempts, new accounts
3. **Processes & Network** - Running processes, open ports
4. **File Integrity** - Detect file modifications
5. **Alerting** - Log all findings with severity levels

---

## 🚀 Quick Start (5 minutes)

### Install

```bash
# Clone repository
git clone https://github.com/USERNAME/hids-capstone.git
cd hids-capstone

# Install HIDS
sudo cp src/hids /usr/local/sbin/hids
sudo chmod 755 /usr/local/sbin/hids

# Create baseline
sudo /usr/local/sbin/hids --baseline

# Run first scan
sudo /usr/local/sbin/hids

# View alerts
sudo tail -20 /var/lib/hids/alerts.log
```

### Automate (runs every 5 minutes)

```bash
sudo crontab -e
# Add: */5 * * * * /usr/local/sbin/hids >> /var/log/hids.log 2>&1
```

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [docs/research.md](docs/research.md) | Research findings & design decisions |
| [user-docs/USER_README.md](user-docs/USER_README.md) | How to use HIDS |
| [user-docs/QUICKSTART.md](user-docs/QUICKSTART.md) | 5-minute setup guide |
| [demo/DEMO_GUIDE.md](demo/DEMO_GUIDE.md) | Demo preparation |
| [team/SPRINT_PLAN.md](team/SPRINT_PLAN.md) | Project timeline |

---

## ✅ Features

✅ All 5 monitoring modules  
✅ Professional alerting system  
✅ Persistent logging  
✅ Configurable thresholds  
✅ Automatic baseline learning  
✅ Cron/systemd automation  

---

## 👥 Team

| Person | Role | Module |
|--------|------|--------|
| Person A | Lead + System/Network | System health, network monitoring |
| Person B | User & File Integrity | User activity, file integrity |
| Person C | Alerting & Automation | Alert system, automation setup |
| Person D | Documentation & Demo | Documentation, demo preparation |

---

## 📅 Timeline

- **Day 1:** Setup & research
- **Day 2:** Module testing
- **Day 3:** Bug fixes & tuning
- **Day 4:** First demo rehearsal
- **Day 5:** Final testing
- **Day 6:** Polish & practice
- **Day 7:** DEMO DAY! 🎬

---

## 📋 Repository Structure

```
hids-capstone/
├── src/
│   ├── hids                    Main HIDS script
│   └── config/hids.conf        Configuration
├── docs/
│   └── research.md             Research findings
├── user-docs/
│   ├── USER_README.md          User guide
│   ├── QUICKSTART.md           5-min setup
│   ├── CONFIGURATION.md        Config guide
│   └── TROUBLESHOOTING.md      Troubleshooting
├── tests/
│   ├── scenario_*.sh           Test scenarios
│   └── TEST_RESULTS.md         Test results
├── demo/
│   ├── DEMO_GUIDE.md           Demo guide
│   └── demo_script.sh          Demo commands
├── team/
│   ├── SPRINT_PLAN.md          Project plan
│   ├── TEAM_ROLES.md           Role assignments
│   └── MEETING_NOTES.md        Daily notes
└── deployment/
    ├── install.sh              Installation
    └── setup-cron.sh           Cron setup
```

---

## 🧪 Testing

```bash
# Run attack scenarios
bash tests/scenario_1_new_user.sh
bash tests/scenario_2_ssh_key.sh
bash tests/scenario_3_process.sh
bash tests/scenario_4_file_modify.sh
bash tests/scenario_5_brute_force.sh
```

---

## 📞 Questions?

- **How to install?** → [user-docs/QUICKSTART.md](user-docs/QUICKSTART.md)
- **How to use?** → [user-docs/USER_README.md](user-docs/USER_README.md)
- **Having issues?** → [user-docs/TROUBLESHOOTING.md](user-docs/TROUBLESHOOTING.md)
- **Project info?** → [team/SPRINT_PLAN.md](team/SPRINT_PLAN.md)

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file

---

**Version:** 1.0 | **Status:** Complete | **Team:** [Your Team Names]
EOF

echo "✅ README.md created"
```

### Step 3.3: Create Additional Documentation

```bash
# Create user-docs files (placeholders for your content)
touch user-docs/USER_README.md
touch user-docs/QUICKSTART.md
touch user-docs/CONFIGURATION.md
touch user-docs/TROUBLESHOOTING.md
touch user-docs/ALERTS_REFERENCE.md

# Create test files (placeholders)
touch tests/TEST_RESULTS.md
touch tests/scenario_1_new_user.sh
touch tests/scenario_2_ssh_key.sh
touch tests/scenario_3_process.sh
touch tests/scenario_4_file_modify.sh
touch tests/scenario_5_brute_force.sh

# Create demo files (placeholders)
touch demo/DEMO_GUIDE.md
touch demo/demo_script.sh
touch demo/demo_checklist.md

# Create team collaboration files (placeholders)
touch team/SPRINT_PLAN.md
touch team/TEAM_ROLES.md
touch team/MEETING_NOTES.md

# Create deployment scripts (placeholders)
touch deployment/install.sh
touch deployment/setup-cron.sh
touch deployment/setup-systemd.sh
touch deployment/uninstall.sh

echo "✅ All documentation files created"
```

---

## PART 4: COPY YOUR EXISTING DOCUMENTS (5 Minutes)

Replace the placeholder files with your actual documents:

```bash
# Copy documents you've already created
cp /path/to/SPRINT_PLAN_1WEEK_4PEOPLE.md team/SPRINT_PLAN.md
cp /path/to/DEMO_GUIDE.md demo/DEMO_GUIDE.md
cp /path/to/HIDS_Complete_Step_by_Step_Guide.md docs/IMPLEMENTATION.md

# Copy user documentation
cp /path/to/user-readme.md user-docs/USER_README.md
cp /path/to/quickstart.md user-docs/QUICKSTART.md

# Verify all files are in place
ls -R
```

---

## PART 5: CREATE INITIAL GIT COMMIT (5 Minutes)

### Step 5.1: Stage All Files

```bash
# Check what will be committed
git status

# Stage all files
git add -A

# Verify everything is staged
git status
# Should show: "Changes to be committed"
```

### Step 5.2: Create Initial Commit

```bash
# Create the commit
git commit -m "Initial commit: HIDS capstone project structure and documentation

- Add complete directory structure
- Add main HIDS script (src/hids)
- Add configuration template (src/config/hids.conf)
- Add research documentation
- Add user documentation placeholders
- Add test scenarios
- Add demo materials
- Add team collaboration files
- Add deployment scripts
- Add MIT license and git configuration"

# Verify commit
git log --oneline
# Should show your commit
```

---

## PART 6: PUSH TO GITHUB (5 Minutes)

### Step 6.1: Create GitHub Repository

1. Go to **https://github.com/new**
2. Fill in:
   - **Repository name:** `hids-capstone`
   - **Description:** `Host Intrusion Detection System - Team Capstone Project`
   - **Visibility:** Choose `Public` (or `Private` if preferred)
   - **Initialize with:** Leave UNCHECKED (you have files)
3. Click **"Create repository"**

### Step 6.2: Connect to GitHub

After creating the repository on GitHub, you'll see instructions. Follow these:

```bash
# Add GitHub as remote (replace USERNAME with your GitHub username)
git remote add origin https://github.com/USERNAME/hids-capstone.git

# Rename branch to main if needed
git branch -M main

# Push to GitHub
git push -u origin main

# Verify connection
git remote -v
# Should show: origin (fetch) and origin (push) URLs
```

### Step 6.3: Verify on GitHub

1. Go to **https://github.com/USERNAME/hids-capstone**
2. You should see:
   - Your README.md displayed
   - All your directories listed
   - Your license and other files

✅ **Your repository is now live!**

---

## PART 7: ADD TEAM MEMBERS (5 Minutes)

### Option A: Add as Collaborators (Easiest)

1. Go to your GitHub repository
2. Click **"Settings"** (top menu)
3. Click **"Collaborators"** (left sidebar)
4. Click **"Add people"**
5. Enter GitHub usernames of your 3 teammates
6. Click **"Add"**
7. They will receive an invitation email and can accept

### Option B: Team Members Clone the Repository

```bash
# Each team member runs this once
git clone https://github.com/USERNAME/hids-capstone.git
cd hids-capstone

# They're now ready to work!
```

---

## PART 8: DAILY TEAM WORKFLOW

### Step 8.1: Start of Day

Each team member:

```bash
# Navigate to repo
cd hids-capstone

# Get latest changes from team
git pull origin main

# Check status
git status
```

### Step 8.2: During Work

```bash
# Make changes to your files
nano docs/research.md

# Check what changed
git status
git diff docs/research.md

# Stage changes
git add docs/research.md

# Commit with meaningful message
git commit -m "Complete system health monitoring section"

# Push to GitHub
git push origin main
```

### Step 8.3: End of Day

```bash
# Make sure all changes are pushed
git status
# Should say "nothing to commit, working tree clean"

# Verify everything is on GitHub
git log -1 --oneline origin/main
```

---

## PART 9: COMPLETE CHECKLIST

Verify your repository is complete:

```bash
# In your hids-capstone directory, verify these exist:

# Core files
ls -la | grep -E 'README|LICENSE|.gitignore|CONTRIBUTING'

# Directories
ls -d src docs tests demo user-docs deployment team .github

# Main script
ls -la src/hids

# Configuration
ls -la src/config/hids.conf

# All subdirectories populated
find . -type d | sort
find . -type f | grep -v .git | sort
```

Should output something like:

```
.
├── .github/
├── .gitignore
├── CONTRIBUTING.md
├── LICENSE
├── README.md
├── demo/
│   ├── DEMO_GUIDE.md
│   ├── demo_checklist.md
│   └── demo_script.sh
├── deployment/
│   ├── install.sh
│   ├── setup-cron.sh
│   ├── setup-systemd.sh
│   └── uninstall.sh
├── docs/
│   └── research.md
├── src/
│   ├── config/
│   │   └── hids.conf
│   ├── hids
│   └── lib/
├── team/
│   ├── MEETING_NOTES.md
│   ├── SPRINT_PLAN.md
│   └── TEAM_ROLES.md
├── tests/
│   ├── TEST_RESULTS.md
│   ├── scenario_1_new_user.sh
│   ├── scenario_2_ssh_key.sh
│   ├── scenario_3_process.sh
│   ├── scenario_4_file_modify.sh
│   └── scenario_5_brute_force.sh
└── user-docs/
    ├── ALERTS_REFERENCE.md
    ├── CONFIGURATION.md
    ├── QUICKSTART.md
    ├── TROUBLESHOOTING.md
    └── USER_README.md
```

---

## PART 10: TEAM FIRST MEETING

Once repository is set up, hold a team meeting:

```
AGENDA (30 minutes):

1. Welcome & Overview (5 min)
   - Project goal: Build a working HIDS
   - Timeline: 1 week, 4 people
   - Deliverables: Working code, docs, demo

2. Repository Walk-through (10 min)
   - Show the GitHub repository
   - Explain each directory
   - Show everyone how to clone and work

3. Role Assignments (5 min)
   - Person A: System/Network
   - Person B: User & File Integrity
   - Person C: Alerting & Automation
   - Person D: Documentation & Demo

4. Timeline Review (5 min)
   - Review team/SPRINT_PLAN.md
   - Discuss daily standups (6 PM)
   - Discuss demo rehearsals

5. First Task (5 min)
   - Everyone clones the repo
   - Everyone reads docs/research.md
   - Everyone reads team/SPRINT_PLAN.md
   - Meet again tomorrow evening for standup
```

---

## PART 11: FIRST WEEK ACTIVITIES

### Day 1: Setup & Research
```bash
✅ Clone repository
✅ Read research.md
✅ Read SPRINT_PLAN.md
✅ Install HIDS on VM
✅ Create baseline
✅ Run first scan
✅ 6 PM: First team standup
```

### Day 2: Module Testing
```bash
✅ Each person tests their module
✅ Document findings in tests/TEST_RESULTS.md
✅ Commit progress to git
✅ 6 PM: Daily standup
```

### Day 3: Bug Fixes
```bash
✅ Fix any issues found
✅ Tune thresholds
✅ Update documentation
✅ 6 PM: Daily standup
```

### Day 4: Demo Prep
```bash
✅ First full demo rehearsal
✅ Time the demo (should be 15-20 min)
✅ Refine what doesn't work
✅ 6 PM: Daily standup
```

### Day 5-7: Polish & Demo
```bash
✅ Final testing
✅ Practice demos
✅ Demo day!
```

---

## TROUBLESHOOTING

### "git command not found"
```bash
# Install Git
# macOS:
brew install git

# Ubuntu/Debian:
sudo apt install git

# CentOS/RHEL:
sudo yum install git
```

### "Can't push to GitHub"
```bash
# Add SSH key or use HTTPS
# Option 1: Use HTTPS (easier)
git remote set-url origin https://github.com/USERNAME/hids-capstone.git

# Option 2: Configure SSH
ssh-keygen -t ed25519 -C "your_email@example.com"
# Add public key to GitHub → Settings → SSH and GPG keys
```

### "Merge conflicts"
```bash
# When pulling conflicts:
git status  # See conflicting files
nano filename.md  # Edit and fix conflicts
git add filename.md
git commit -m "Resolved merge conflict"
```

### "Lost changes"
```bash
# See all commits ever made
git reflog

# Recover deleted commit
git reset --hard abc1234
```

---

## ✅ FINAL VERIFICATION

Before team meeting, verify:

```bash
# Repository is created and pushed
git remote -v
# Should show GitHub URL

# All files are committed
git status
# Should say "nothing to commit"

# You can see it on GitHub
open https://github.com/USERNAME/hids-capstone

# Team members can clone it
git clone https://github.com/USERNAME/hids-capstone.git test-clone
ls test-clone
# Should show all files
rm -rf test-clone
```

---

## 🎯 YOU'RE READY!

Your repository is now:

✅ **Complete** - All directories and files in place  
✅ **Documented** - Research, user docs, demo guides  
✅ **Live** - Available on GitHub for the team  
✅ **Collaborative** - Ready for 4-person team  
✅ **Professional** - Proper structure and organization  

---

## 📞 NEXT STEPS

1. **Share repository link** with your team
   - Tell them: https://github.com/USERNAME/hids-capstone

2. **Each team member clones it:**
   ```bash
   git clone https://github.com/USERNAME/hids-capstone.git
   cd hids-capstone
   cat README.md
   ```

3. **Hold first team meeting** (30 minutes)
   - Review structure
   - Assign roles
   - Set timeline
   - Start coding tomorrow!

---

**Your HIDS repository is ready. Your team is ready. Let's build something awesome! 🚀**

---

## QUICK REFERENCE CHECKLIST

```
SETUP COMPLETE:
✅ Local repo created with git init
✅ Directory structure created
✅ Core files created (.gitignore, LICENSE, README.md)
✅ HIDS script copied to src/hids
✅ Configuration template created
✅ Research document added
✅ Documentation placeholders created
✅ Initial git commit made
✅ GitHub repository created
✅ Code pushed to GitHub
✅ Team members added as collaborators
✅ Repository verified on GitHub

READY FOR TEAM:
✅ Everyone has access to repository
✅ Everyone can clone and work
✅ Daily workflow documented
✅ Team roles assigned
✅ Timeline established
✅ First standup scheduled

READY TO BUILD:
✅ HIDS script is ready
✅ All documentation organized
✅ Test scenarios prepared
✅ Demo materials organized
✅ Team coordination in place
```

---

**Total time to complete:** ~30 minutes  
**Result:** Production-ready repository for 4-person team  
**Status:** 🟢 READY TO GO
