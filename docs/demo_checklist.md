# HIDS Demo Checklist

## Pre-Demo Setup
- [ ] Docker running (`docker-compose ps` shows both UP)
- [ ] Alerts sent to Elasticsearch
- [ ] Kibana accessible (http://localhost:5601)
- [ ] Dashboard created with visualizations

## Demo Flow

### Step 1: Show HIDS System
- [ ] Run: `sudo /usr/local/sbin/hids --help`
- [ ] Show: HIDS is installed and working

### Step 2: Show Baseline
- [ ] Run: `sudo ls /var/lib/hids/baselines/`
- [ ] Explain: Baseline captures clean system state

### Step 3: Show Alerts
- [ ] Run: `sudo tail -20 /var/lib/hids/alerts.log`
- [ ] Highlight: 667 total alerts generated

### Step 4: Show Kibana Dashboard
- [ ] Open: http://localhost:5601
- [ ] Show: Alerts Over Time visualization
- [ ] Show: Severity Distribution (pie chart)
- [ ] Show: Alerts by Category (bar chart)
- [ ] Show: Recent Alerts table

### Step 5: Explain Attack Scenarios
- [ ] User account creation (CRITICAL)
- [ ] SSH backdoor injection (CRITICAL)
- [ ] File modification (CRITICAL)
- [ ] Suspicious process (HIGH)
- [ ] Brute force login (HIGH)

## Post-Demo
- [ ] Answer questions
- [ ] Show GitHub repository
- [ ] Discuss future improvements
