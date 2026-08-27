# HIDS Execution Guide

## System Startup
1. Start Docker: `cd deploy && docker-compose up -d`
2. Create HIDS baseline: `sudo /usr/local/sbin/hids --baseline`
3. Run HIDS scan: `sudo /usr/local/sbin/hids`

## Send Alerts to Elasticsearch
`sudo /usr/local/bin/send-hids-alerts.sh`

## View Dashboard
1. Open: http://localhost:5601
2. Navigate to Dashboards
3. View HIDS Security Monitoring Dashboard

## Run Tests
`sudo /usr/local/sbin/hids && sudo ./tests/test-hids-complete.sh`
