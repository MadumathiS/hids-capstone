#!/bin/bash
# Scenario 2: SSH key injection (unauthorized remote access)

echo "[SCENARIO 2] Adding SSH backdoor key..."
echo "This tests: FILE_INTEGRITY detection"

# Add fake SSH key
echo "ssh-rsa AAAAB3NzaC1yc2EAAA... attacker@backdoor" | sudo tee -a ~/.ssh/authorized_keys > /dev/null

echo "✓ SSH key added to ~/.ssh/authorized_keys"
echo "Waiting 5 seconds for HIDS to detect..."
sleep 5

# Run HIDS to detect the change
sudo /usr/local/sbin/hids

echo "✓ Check alerts.log for FILE_INTEGRITY alerts"
echo ""
echo "Cleaning up..."
sudo sed -i '/attacker@backdoor/d' ~/.ssh/authorized_keys

echo "✓ Scenario 2 complete"
