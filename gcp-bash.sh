#!/usr/bin/env bash
# Onboard all GCP projects under a folder into Microsoft Defender for Cloud
# Requires: az CLI

set -euo pipefail

# ====== CONFIG ======
FOLDER_ID="93604753456" # Dummy folder ID for testing
SA_EMAIL="microsoft-defender-for-servers@sbx-sentinel-mde-dev-920788.iam.gserviceaccount.com"
AZ_SUBSCRIPTION="f2e26c0b-8b27-4edd-b6f4-73edc39a4186"
AZ_RG="kpmg-testing"
AZ_LOCATION="eastus"

# Dummy projects for testing
PROJECTS="dummy-project-1 dummy-project-2"

# ====== STEP 2: Loop projects ======
for PROJECT in $PROJECTS; do
  echo "=== Onboarding project: $PROJECT ==="

  # Skipping GCP API enablement for testing
  # for api in "${APIS[@]}"; do
  #   gcloud services enable "$api" --project "$PROJECT" || true
  # done

  # ====== STEP 3: Create Defender connector in Azure ======
  CONNECTOR_NAME="gcp-${PROJECT}"

  # Get Azure auth token
  AZ_TOKEN=$(az account get-access-token --resource https://management.azure.com \
    --query accessToken -o tsv)

  # JSON body for connector
  BODY=$(cat <<EOF
{
  "location": "$AZ_LOCATION",
  "properties": {
    "hierarchyIdentifier": "$FOLDER_ID",
    "environmentName": "GCP",
    "environmentData": {
      "environmentType": "GcpProject",
      "projectDetails": {
        "projectId": "$PROJECT",
        "serviceAccountEmailAddress": "$SA_EMAIL"
      }
    }
  }
}
EOF
)

  # Call Azure REST API
  echo "Creating connector $CONNECTOR_NAME in Azure ..."
  curl -s -X PUT \
    -H "Authorization: Bearer $AZ_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$BODY" \
    "https://management.azure.com/subscriptions/$AZ_SUBSCRIPTION/resourceGroups/$AZ_RG/providers/Microsoft.Security/securityConnectors/$CONNECTOR_NAME?api-version=2023-10-01-preview"

  echo "✅ Connector created for project $PROJECT"
done
