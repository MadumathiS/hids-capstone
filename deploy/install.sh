#!/bin/bash
# HIDS Installation Script

echo "Installing HIDS..."

# Create directories
sudo mkdir -p /var/lib/hids/{baselines,scans}
sudo chmod 755 /var/lib/hids*

# Copy files
sudo cp ../src/config/hids.conf /var/lib/hids/
sudo cp ../src/hids /usr/local/sbin/hids
sudo chmod 755 /usr/local/sbin/hids

# Create baseline
sudo /usr/local/sbin/hids --baseline

echo "✅ HIDS installed successfully!"
