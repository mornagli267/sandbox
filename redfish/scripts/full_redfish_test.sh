#!/bin/bash
set -e

# BMCIP="192.168.17.111"
BMCIP="${1:-${LAVA_DEVICE_INFO_0_bmc_ip:-192.168.17.110}}"


echo "========================================="
echo "Redfish Complete Validation Test"
echo "BMC IP: ${BMCIP}"
echo "========================================="

# Step 1: Authenticate and get token
echo ""
echo "Step 1: Authenticating to BMC..."

RESPONSE=$(curl --max-time 10 -s -k -i -X POST \
  "https://${BMCIP}/redfish/v1/SessionService/Sessions" \
  -H "Content-Type: application/json" \
  -d '{ "UserName": "root", "Password": "0penBmc" }')

TOKEN=$(echo "$RESPONSE" | grep -i "X-Auth-Token:" | awk '{print $2}' | tr -d '\r')

if [ -z "$TOKEN" ]; then
  echo "ERROR: Failed to obtain authentication token"
  lava-test-case redfish-authentication --result fail
  lava-test-raise "Authentication failed - no token received"
fi

echo "✓ Authentication successful!"
echo "Token: ${TOKEN:0:20}..."
lava-test-case redfish-authentication --result pass

# Step 2: Get system information
echo ""
echo "Step 2: Getting system information..."

SYSTEM_INFO=$(curl --max-time 10 -s -k \
  -H "X-Auth-Token: ${TOKEN}" \
  -H "Content-Type: application/json" \
  -X GET "https://${BMCIP}/redfish/v1/Systems/system")

if [ -z "$SYSTEM_INFO" ]; then
  echo "ERROR: No response from /redfish/v1/Systems/system endpoint"
  lava-test-case redfish-system-info --result fail
  lava-test-raise "Failed to retrieve system information"
fi

echo "✓ System information retrieved successfully"
lava-test-case redfish-system-info --result pass

# Step 3: Validate PowerRestorePolicy
echo ""
echo "Step 3: Validating PowerRestorePolicy..."

POWER_RESTORE_POLICY=$(echo "$SYSTEM_INFO" | grep -oP '"PowerRestorePolicy"\s*:\s*"\K[^"]+' || echo "UNKNOWN")
echo "Current PowerRestorePolicy: ${POWER_RESTORE_POLICY}"

if [ "$POWER_RESTORE_POLICY" != "AlwaysOn" ]; then
  echo "ERROR: PowerRestorePolicy is '${POWER_RESTORE_POLICY}', expected 'AlwaysOn'"
  lava-test-case power-restore-policy --result fail
  lava-test-raise "PowerRestorePolicy validation failed"
fi

echo "✓ PowerRestorePolicy is 'AlwaysOn'"
lava-test-case power-restore-policy --result pass

# Step 4: Validate PowerState
echo ""
echo "Step 4: Validating PowerState..."

POWER_STATE=$(echo "$SYSTEM_INFO" | grep -oP '"PowerState"\s*:\s*"\K[^"]+' || echo "UNKNOWN")
echo "Current PowerState: ${POWER_STATE}"

if [ "$POWER_STATE" != "On" ]; then
  echo "ERROR: PowerState is '${POWER_STATE}', expected 'On'"
  lava-test-case power-state --result fail
  lava-test-raise "PowerState validation failed"
fi

echo "✓ PowerState is 'On'"
lava-test-case power-state --result pass

# Success Summary
echo ""
echo "========================================="
echo "All validations PASSED!"
echo "  ✓ Authentication successful"
echo "  ✓ System information retrieved"
echo "  ✓ PowerRestorePolicy: AlwaysOn"
echo "  ✓ PowerState: On"
echo "========================================="

exit 0