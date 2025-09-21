#!/usr/bin/env bash
# Onboard GCP project into Microsoft Defender for Cloud
# Requires: az CLI

set -euo pipefail

# ====== CONFIG ======
PROJECT="sbx-sentinel-mde-dev-920788"
FOLDER_ID="93604753456"
AZ_SUBSCRIPTION="f2e26c0b-8b27-4edd-b6f4-73edc39a4186"
AZ_RG="kpmg-testing"
AZ_LOCATION="eastus"

# Service Accounts
CSPM_SA="microsoft-defender-cspm@$PROJECT.iam.gserviceaccount.com"
DEFENDER_SA="microsoft-defender-for-servers@$PROJECT.iam.gserviceaccount.com"

# Workload Identity Provider IDs (short names only — NOT full resource paths)
CSPM_PROVIDER_ID="cspm"
DEFENDER_PROVIDER_ID="defender-for-servers"

# ====== STEP: Create Defender connector in Azure ======
CONNECTOR_NAME="gcp-${PROJECT}"

# Get Azure auth token
AZ_TOKEN=$(az account get-access-token --resource https://management.azure.com \
  --query accessToken -o tsv)

# JSON body for connector
read -r -d '' BODY <<EOF
{
  "location": "$AZ_LOCATION",
  "properties": {
    "hierarchyIdentifier": "$FOLDER_ID",
    "environmentName": "GCP",
    "environmentData": {
      "environmentType": "GcpProject",
      "projectDetails": {
        "projectId": "$PROJECT",
        "serviceAccountEmailAddress": "$DEFENDER_SA"
      }
    },
    "offerings": [
      {
        "offeringType": "CspmMonitorGcp",
        "nativeCloudConnection": {
          "serviceAccountEmailAddress": "$CSPM_SA",
          "workloadIdentityProviderId": "$CSPM_PROVIDER_ID"
        }
      },
      {
        "offeringType": "DefenderForServersGcp",
        "defenderForServers": {
          "serviceAccountEmailAddress": "$DEFENDER_SA",
          "workloadIdentityProviderId": "$DEFENDER_PROVIDER_ID"
        },
        "mdeAutoProvisioning": {
          "enabled": true,
          "configuration": {}
        },
        "arcAutoProvisioning": {
          "enabled": true,
          "configuration": {}
        },
        "subPlan": "P2"
      }
    ]
  }
}
EOF

# Call Azure REST API
echo "Creating connector $CONNECTOR_NAME in Azure ..."
curl -s -X PUT \
  -H "Authorization: Bearer $AZ_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$BODY" \
  "https://management.azure.com/subscriptions/$AZ_SUBSCRIPTION/resourceGroups/$AZ_RG/providers/Microsoft.Security/securityConnectors/$CONNECTOR_NAME?api-version=2023-10-01-preview"

echo "✅ Connector created for project $PROJECT"
