#!/usr/bin/env bash
# Onboard all GCP projects under a folder into Microsoft Defender for Cloud
# Requires: gcloud, az CLI
 
set -euo pipefail
 
# ====== CONFIG ======
FOLDER_ID="<YOUR_FOLDER_ID>" # e.g. 123456789012
SA_EMAIL="defender-sa@security-project.iam.gserviceaccount.com"
AZ_SUBSCRIPTION="<AZURE_SUBSCRIPTION_ID>"
AZ_RG="<AZURE_RESOURCE_GROUP>"
AZ_LOCATION="eastus"
 
# APIs required for Defender onboarding
APIS=(
 "compute.googleapis.com"
 "logging.googleapis.com"
 "iam.googleapis.com"
 "serviceusage.googleapis.com"
)
 
# ====== STEP 1: Get projects under folder ======
echo "Fetching all projects under folder $FOLDER_ID ..."
PROJECTS=$(gcloud projects list --filter="parent.id=$FOLDER_ID" --format="value(projectId)")
 
# ====== STEP 2: Loop projects ======
for PROJECT in $PROJECTS; do
 echo "=== Onboarding project: $PROJECT ==="
 
 # Enable required APIs
 for api in "${APIS[@]}"; do
   gcloud services enable "$api" --project "$PROJECT" || true
 done
 
 # ====== STEP 3: Create Defender connector in Azure ======
 CONNECTOR_NAME="gcp-${PROJECT}"
 
 # Get Azure auth token
 AZ_TOKEN=$(az account get-access-token --resource https://management.azure.com \
   --query accessToken -o tsv)
 
 # JSON body for connector
 BODY=$(cat <<EOF
{
 "properties": {
   "environmentName": "GCP",
   "environmentData": {
     "environmentType": "GcpProject",
     "projectDetails": {
       "projectId": "$PROJECT",
       "serviceAccountEmailAddress": "$SA_EMAIL"
     }
   }
 },
 "location": "$AZ_LOCATION"
}
EOF
)
 
 # Call Azure REST API
 echo "Creating connector $CONNECTOR_NAME in Azure ..."
 curl -s -X PUT \
   -H "Authorization: Bearer $AZ_TOKEN" \
   -H "Content-Type: application/json" \
   -d "$BODY" \
   "https://management.azure.com/subscriptions/$AZ_SUBSCRIPTION/resourceGroups/$AZ_RG/providers/Microso…"
 
 echo "✅ Connector created for project $PROJECT"
done
