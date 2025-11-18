#!/bin/bash
set -e

BMCIP="192.168.17.111"

echo "========================================="
echo "Sending PowerOn command to BMC"
echo "BMC IP: ${BMCIP}"
echo "========================================="

# Authenticate
RESPONSE=$(curl --max-time 10 -s -k -i -X POST \
  "https://${BMCIP}/redfish/v1/SessionService/Sessions" \
  -H "Content-Type: application/json" \
  -d '{ "UserName": "root", "Password": "0penBmc" }')

TOKEN=$(echo "$RESPONSE" | grep -i "X-Auth-Token:" | awk '{print $2}' | tr -d '\r')

if [ -z "$TOKEN" ]; then
  echo "ERROR: Failed to obtain authentication token"
  lava-test-case power-on-auth --result fail
  exit 1
fi

echo "✓ Authentication successful"

# Send PowerOn command
POWER_ON_RESPONSE=$(curl --max-time 10 -s -k -w "\n%{http_code}" \
  -H "X-Auth-Token: ${TOKEN}" \
  -H "Content-Type: application/json" \
  -X POST "https://${BMCIP}/redfish/v1/Systems/system/Actions/ComputerSystem.Reset" \
  -d '{"ResetType": "On"}')

HTTP_CODE=$(echo "$POWER_ON_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$POWER_ON_RESPONSE" | sed '$d')

echo "HTTP Response Code: ${HTTP_CODE}"

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "204" ]; then
  echo "✓ PowerOn command sent successfully"
  lava-test-case power-on-command --result pass
else
  echo "ERROR: PowerOn command failed with HTTP ${HTTP_CODE}"
  echo "Response: ${RESPONSE_BODY}"
  lava-test-case power-on-command --result fail
  exit 1
fi

echo "Waiting 15 seconds for system to power up..."
sleep 15

echo "========================================="
echo "PowerOn command completed"
echo "========================================="