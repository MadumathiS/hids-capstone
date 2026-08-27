#!/bin/bash
# Scenario 5: Brute force login attempts

echo "[SCENARIO 5] Simulating brute force login attempts..."
echo "This tests: USER_ANOMALY detection"

echo "✓ Attempting failed logins..."

# Simulate failed login attempts
for i in {1..10}; do
    sudo -u nonexistent bash -c "exit" 2>/dev/null || true
    echo -n "."
done

echo ""
echo "✓ Multiple failed login attempts made"
echo "Waiting 5 seconds for HIDS to detect..."
sleep 5

# Run HIDS to detect
sudo /usr/local/sbin/hids

echo "✓ Check alerts.log for USER_ANOMALY alerts"
echo "✓ Scenario 5 complete"
