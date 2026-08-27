#!/bin/bash
# Scenario 3: Suspicious process execution from /tmp

echo "[SCENARIO 3] Running suspicious process from /tmp..."
echo "This tests: PROCESS_ANOMALY detection"

# Copy bash to /tmp and run it
sudo cp /bin/bash /tmp/malware
sudo /tmp/malware -c "sleep 15" &
PROCESS_PID=$!

echo "✓ Suspicious process started (PID: $PROCESS_PID)"
echo "Waiting for process to run..."
sleep 10

# Run HIDS to detect
sudo /usr/local/sbin/hids

echo "✓ Check alerts.log for PROCESS_ANOMALY alerts"
echo ""
echo "Cleaning up..."
sudo rm -f /tmp/malware
wait $PROCESS_PID 2>/dev/null || true

echo "✓ Scenario 3 complete"
