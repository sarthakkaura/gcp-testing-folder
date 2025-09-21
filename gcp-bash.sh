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
         
