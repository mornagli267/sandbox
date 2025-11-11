#!/bin/bash
set -e

BMCIP="192.168.17.111"

echo "Testing Redfish authentication to ${BMCIP}..."

RESPONSE=$(curl --max-time 10 -s -k -i -X POST \
  "https://${BMCIP}/redfish/v1/SessionService/Sessions" \
  -H "Content-Type: application/json" \
  -d '{ "UserName": "root", "Password": "0penBmc" }')

TOKEN=$(echo "$RESPONSE" | grep -i "X-Auth-Token:" | awk '{print $2}' | tr -d '\r')

if [ -z "$TOKEN" ]; then
  echo "ERROR: Failed to obtain authentication token"
  lava-test-case redfish-authentication --result fail
  lava-test-raise "Authentication failed"
fi

echo "Successfully authenticated to BMC"
echo "Token: ${TOKEN:0:20}..."
lava-test-case redfish-authentication --result pass
