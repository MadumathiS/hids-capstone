#!/bin/bash
# Scenario 4: Modification of critical system file

echo "[SCENARIO 4] Modifying critical system file..."
echo "This tests: FILE_INTEGRITY detection"

# Backup /etc/passwd
sudo cp /etc/passwd /etc/passwd.bak

# Add a line to /etc/passwd (simulating tampering)
echo "hacker:x:0:0::/root:/bin/bash" | sudo tee -a /etc/passwd > /dev/null

echo "✓ Critical file /etc/passwd modified"
echo "Waiting 5 seconds for HIDS to detect..."
sleep 5

# Run HIDS to detect
sudo /usr/local/sbin/hids

echo "✓ Check alerts.log for FILE_INTEGRITY alerts"
echo ""
echo "Cleaning up..."
sudo cp /etc/passwd.bak /etc/passwd
sudo rm -f /etc/passwd.bak

echo "✓ Scenario 4 complete"
