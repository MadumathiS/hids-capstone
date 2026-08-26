#!/bin/bash
# HIDS Demo Script - Copy-paste commands

echo "HIDS Live Demo"
echo "=============="
echo ""

echo "Step 1: Show clean baseline"
echo "$ sudo /usr/local/sbin/hids"
echo ""

echo "Step 2: Create attack"
echo "$ sudo useradd attacker"
echo ""

echo "Step 3: Run HIDS detection"
echo "$ sudo /usr/local/sbin/hids"
echo ""

echo "Step 4: Show alerts"
echo "$ sudo tail -20 /var/lib/hids/alerts.log"
echo ""

echo "Step 5: Cleanup"
echo "$ sudo userdel -r attacker"
