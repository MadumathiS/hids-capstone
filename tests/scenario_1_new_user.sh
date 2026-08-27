#!/bin/bash
# Scenario 1: New user account creation (backdoor method)

echo "[SCENARIO 1] Creating unauthorized user account..."
echo "This tests: USER_ANOMALY detection"

# Create new user
sudo useradd -m -s /bin/bash attacker

echo "✓ User 'attacker' created"
echo "Waiting 5 seconds for HIDS to detect..."
sleep 5

# Run HIDS to detect the change
sudo /usr/local/sbin/hids

echo "✓ Check alerts.log for USER_ANOMALY alerts"
echo ""
echo "Cleaning up..."
sudo userdel -r attacker

echo "✓ Scenario 1 complete"
