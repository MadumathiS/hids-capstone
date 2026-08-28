# Email Alerts Setup Guide - Complete

This guide walks you through setting up automated email alerts for HIDS from scratch.

## Prerequisites

- Ubuntu/Debian Linux system
- HIDS system installed and running
- Gmail account with 2-Factor Authentication enabled
- Sudo access

## Step 1: Install Postfix & Mailutils

```bash
# Update package list
sudo apt-get update

# Install mailutils (which includes postfix)
sudo apt-get install -y mailutils

# When prompted for Postfix configuration:
# - Select: "Internet Site"
# - Confirm your system mail name
```

## Step 2: Get Gmail App Password

Gmail app passwords are different from your regular password. Follow these steps:

1. Go to: https://myaccount.google.com/security
2. Ensure "2-Step Verification" is **ON** (enable if needed)
3. Go to: https://myaccount.google.com/apppasswords
4. Select:
   - **App:** Mail
   - **Device:** Linux
5. Click **Generate**
6. Copy the 16-character password shown
   - Format: `xxxx xxxx xxxx xxxx`
   - Example: `abcd1234efgh5678`

**IMPORTANT:** Save this password - you'll need it in the next step!

## Step 3: Configure Postfix for Gmail Relay

### Step 3.1: Edit Main Configuration

```bash
# Open Postfix main configuration
sudo nano /etc/postfix/main.cf
```

**Add these lines at the END of the file:**

```
# Gmail Relay Configuration
relayhost = [smtp.gmail.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
```

**Save:** Press `Ctrl+X`, then `Y`, then `Enter`

### Step 3.2: Create Credentials File

Replace `YOUR-APP-PASSWORD` with your actual 16-character app password:

```bash
sudo tee /etc/postfix/sasl_passwd > /dev/null << 'EOF'
[smtp.gmail.com]:587 your@gmail.com:YOUR-APP-PASSWORD
EOF
```

**Example (DO NOT USE - make your own):**
```bash
# Wrong - just for reference:
# [smtp.gmail.com]:587 yourgmail:16-digit app password without space
```

### Step 3.3: Secure the Credentials File

```bash
# Restrict permissions (Postfix requirement)
sudo chmod 600 /etc/postfix/sasl_passwd

# Create database hash
sudo postmap /etc/postfix/sasl_passwd

# Verify it was created
sudo ls -la /etc/postfix/sasl_passwd*
# Should show both files with 600 permissions
```

### Step 3.4: Restart Postfix

```bash
# Check configuration is valid
sudo postfix check
# Should return nothing (no errors)

# Restart Postfix
sudo systemctl restart postfix

# Verify it's running
sudo systemctl status postfix | grep "active (running)"
```

## Step 4: Test Email Delivery

### Step 4.1: Send Test Email

```bash
# Send a test email to your Gmail
echo "HIDS Test Email - Configuration successful!" | \
  mail -s "🚨 HIDS Test Alert" your@gmail.com

# Wait 10-30 seconds for delivery
sleep 30

# Check mail queue (should be empty if sent)
mailq

# Check Postfix logs
sudo tail -20 /var/log/mail.log | grep -E "gmail|sent|status=sent"
```

### Step 4.2: Verify Email Arrived

1. Go to your Gmail inbox
2. Look for email from `vm-hostname` (or your hostname)
3. Subject: `🚨 HIDS Test Alert`

**If email arrived:** ✅ Email relay is working!
**If email didn't arrive:** ❌ Check troubleshooting section below

## Step 5: Create Email Alert Script

### Step 5.1: Create the Script

```bash
sudo tee /usr/local/bin/hids-email-alerts.sh > /dev/null << 'EOF'
#!/bin/bash

################################################################################
# HIDS Email Alert Script
# Sends alert summary to Gmail every time it's run
# Scheduled to run every 5 minutes via cron
################################################################################

HIDS_LOG="/var/lib/hids/alerts.log"
EMAIL_TO="your@gmail.com"
LAST_CHECK="/tmp/hids-last-check"

# Get last line count
LAST_LINE=$(cat "$LAST_CHECK" 2>/dev/null || echo "0")

# Get current line count
CURRENT_LINE=$(wc -l < "$HIDS_LOG" 2>/dev/null || echo "0")

# Calculate new alerts
NEW_ALERTS=$((CURRENT_LINE - LAST_LINE))

# If there are new alerts, send email
if [ "$NEW_ALERTS" -gt 0 ]; then
    # Get alert details
    ALERT_DETAILS=$(tail -n "$NEW_ALERTS" "$HIDS_LOG")
    
    # Count by severity
    CRITICAL=$(echo "$ALERT_DETAILS" | grep -c "\[CRITICAL\]" || echo "0")
    HIGH=$(echo "$ALERT_DETAILS" | grep -c "\[HIGH\]" || echo "0")
    MEDIUM=$(echo "$ALERT_DETAILS" | grep -c "\[MEDIUM\]" || echo "0")
    
    # Create email body
    EMAIL_BODY="HIDS Alert Summary
====================
New Alerts: $NEW_ALERTS
- CRITICAL: $CRITICAL
- HIGH: $HIGH
- MEDIUM: $MEDIUM

Recent Alert Details:
$(echo "$ALERT_DETAILS" | tail -10)

System Information:
- Hostname: $(hostname)
- Time: $(date)
- Alert Log: /var/lib/hids/alerts.log

---
HIDS Security Monitoring System"
    
    # Send email
    echo "$EMAIL_BODY" | mail -s "🚨 HIDS Alert: $NEW_ALERTS new alerts" "$EMAIL_TO"
    
    # Log the send
    echo "[$(date)] Sent email with $NEW_ALERTS alerts" >> /var/log/hids-alerts.log
fi

# Update last check line count
echo "$CURRENT_LINE" > "$LAST_CHECK"
EOF
```

### Step 5.2: Make Script Executable

```bash
sudo chmod +x /usr/local/bin/hids-email-alerts.sh

# Verify it was created
sudo ls -lh /usr/local/bin/hids-email-alerts.sh
# Should show: -rwxr-xr-x
```

### Step 5.3: Initialize State File

```bash
# Create initial state (current alert count)
sudo bash -c "wc -l < /var/lib/hids/alerts.log > /tmp/hids-last-check"
```

## Step 6: Schedule Automatic Alerts

### Step 6.1: Add Cron Job

```bash
# Schedule script to run every 5 minutes
echo "*/5 * * * * /usr/local/bin/hids-email-alerts.sh" | sudo crontab -
```

### Step 6.2: Verify Cron Job

```bash
# View scheduled jobs
sudo crontab -l | grep hids

# Should show:
# */5 * * * * /usr/local/bin/hids-email-alerts.sh
```

### Step 6.3: Test the Script

```bash
# Run script manually
sudo /usr/local/bin/hids-email-alerts.sh

# Wait and check
sleep 5
mailq

# Should be empty (email sent)
```

## Step 7: Verify Complete Setup

```bash
echo "=== POSTFIX STATUS ==="
sudo systemctl status postfix | grep "active (running)"

echo ""
echo "=== CREDENTIALS FILE ==="
sudo ls -lh /etc/postfix/sasl_passwd*

echo ""
echo "=== EMAIL SCRIPT ==="
sudo ls -lh /usr/local/bin/hids-email-alerts.sh

echo ""
echo "=== CRON JOB ==="
sudo crontab -l | grep hids

echo ""
echo "=== POSTFIX CONFIG ==="
sudo grep "relayhost" /etc/postfix/main.cf

echo ""
echo "✅ Email alerts setup complete!"
```

## Configuration Status: LIVE ✅

Once setup is complete:
- ✅ Postfix installed and running
- ✅ Gmail relay via SMTP configured
- ✅ SASL authentication working
- ✅ Email alerts scheduled every 5 minutes
- ✅ Tested and verified delivery

## What You'll Receive

Every 5 minutes (when new alerts exist), you'll receive an email with:
- **New Alert Count** - Total new alerts since last check
- **Severity Breakdown** - CRITICAL, HIGH, MEDIUM counts
- **Recent Alerts** - Last 10 alert details
- **System Info** - Hostname and timestamp

## Email Flow Diagram

```
HIDS System
  ↓
  /var/lib/hids/alerts.log (local alert log)
  ↓
  hids-email-alerts.sh (runs every 5 minutes)
  ↓
  Postfix (local mail server)
  ↓
  Gmail SMTP relay (smtp.gmail.com:587)
  ↓
  Your Gmail Inbox (your@gmail.com)
```

## Daily Management

### View Scheduled Alerts

```bash
# Check when script runs
sudo crontab -l

# View alert log
sudo tail -20 /var/lib/hids/alerts.log

# Check emails received
mail

# View email send log
tail -20 /var/log/hids-alerts.log
```

### Temporarily Disable Alerts

```bash
# Remove cron job
sudo crontab -e
# Delete the hids line, save and exit

# Re-enable later
echo "*/5 * * * * /usr/local/bin/hids-email-alerts.sh" | sudo crontab -
```

### Change Email Recipient

```bash
# Edit script
sudo nano /usr/local/bin/hids-email-alerts.sh

# Change EMAIL_TO variable
EMAIL_TO="newemail@gmail.com"

# Save and exit
```

## Troubleshooting

### Problem: Emails not arriving

**Check Postfix configuration:**
```bash
# Verify config has no errors
sudo postfix check

# Check credentials file exists
sudo cat /etc/postfix/sasl_passwd

# Verify Gmail relay is set
sudo grep "relayhost" /etc/postfix/main.cf
```

**Check logs:**
```bash
# View Postfix logs
sudo tail -50 /var/log/mail.log | grep -E "gmail|error|failed"

# Look for "status=sent" or "status=deferred"
```

### Problem: Script not running

```bash
# Verify cron job exists
sudo crontab -l | grep hids

# Check if cron service is running
sudo systemctl status cron

# View cron logs
sudo tail -20 /var/log/syslog | grep CRON
```

### Problem: "SASL authentication failed"

**Solution:** Credentials are wrong
```bash
# Verify app password is correct (from Google account)
# Go to: https://myaccount.google.com/apppasswords
# Generate new app password if needed

# Update credentials
sudo tee /etc/postfix/sasl_passwd > /dev/null << 'EOF'
[smtp.gmail.com]:587 singaraju.madumathi@gmail.com:YOUR-CORRECT-APP-PASSWORD
EOF

# Recreate database
sudo chmod 600 /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd

# Restart
sudo systemctl restart postfix
```

### Problem: Port 587 connection issues

```bash
# Test Gmail SMTP connection
timeout 5 bash -c 'echo "" | openssl s_client -connect smtp.gmail.com:587 -starttls smtp'

# Should show connection successful
```

## Complete Setup Verification Checklist

- [ ] Postfix installed (`sudo systemctl status postfix`)
- [ ] Gmail app password created
- [ ] Credentials file created (`/etc/postfix/sasl_passwd`)
- [ ] Credentials file secured (600 permissions)
- [ ] Database created (`/etc/postfix/sasl_passwd.db`)
- [ ] Main config updated with relay settings
- [ ] Postfix restarted
- [ ] Test email sent and received
- [ ] Email script created (`/usr/local/bin/hids-email-alerts.sh`)
- [ ] Script is executable
- [ ] Cron job scheduled
- [ ] Manual script test successful
- [ ] Email alerts working

## Next Steps

1. **Complete all setup steps** in this guide
2. **Verify email delivery** with test email
3. **Schedule cron job** for automatic alerts
4. **Monitor first few days** to ensure regular delivery
5. **Adjust schedule** if needed (change `*/5` in cron to different interval)

## System Ready ✅

Email alerts are now LIVE and will send automatically every 5 minutes when new alerts are detected!

---

**Need Help?**
- See troubleshooting section above
- Check Postfix logs: `sudo tail -20 /var/log/mail.log`
- Verify configuration: `sudo postfix check`
