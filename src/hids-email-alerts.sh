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
    echo "$EMAIL_BODY" | mail -s ":rotating_light: HIDS Alert: $NEW_ALERTS new alerts" "$EMAIL_TO"
    
    # Log the send
    echo "[$(date)] Sent email with $NEW_ALERTS alerts" >> /var/log/hids-alerts.log
fi

# Update last check line count
echo "$CURRENT_LINE" > "$LAST_CHECK"
EOF