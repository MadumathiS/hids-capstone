#!/bin/bash
HIDS_LOG="/var/lib/hids/alerts.log"
ES_URL="http://localhost:9200"
grep -v "^$" "$HIDS_LOG" | while IFS= read -r line; do
    if [[ $line == *"["* ]] && [[ $line =~ \[([^\]]+)\]\ \[([^\]]+)\]\ ([^:]+):\ (.+) ]]; then
        ts="${BASH_REMATCH[1]}"
        sev="${BASH_REMATCH[2]}"
        cat="${BASH_REMATCH[3]}"
        msg="${BASH_REMATCH[4]}"
        epoch=$(date -d "$ts" +%s 2>/dev/null || date +%s)
        iso=$(date -d @$epoch -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
        json="{\"@timestamp\":\"$iso\",\"severity\":\"$sev\",\"category\":\"$cat\",\"message\":\"$msg\",\"host\":\"$(hostname)\",\"raw\":\"$line\"}"
        curl -s -X POST "$ES_URL/hids-alerts/_doc" -H "Content-Type: application/json" -d "$json" > /dev/null 2>&1
    fi
done
echo "✅ Alerts sent!"