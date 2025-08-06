#!/bin/bash

NEXUS_URL="${NEXUS_URL:-https://reformers-dev.ait.ac.at}"
NEXUS_PASSWORD="${NEXUS_PASSWORD:?new admin password for repository is required}"

# Retrieve initial password
INITIAL_PASSWORD_FILE=/nexus-data/admin.password
if [[ ! -e "${INITIAL_PASSWORD_FILE}" ]]; then
  echo '[INFO] password file not found'
  exit 0
fi
INITIAL_PASSWORD=$(cat ${INITIAL_PASSWORD_FILE})

# Set new password
HTTP_RESPONSE=$( \
  curl -k -s -w "%{http_code}" -u admin:${INITIAL_PASSWORD} -X PUT "${NEXUS_URL}/service/rest/v1/security/users/admin/change-password" \
  -H 'Content-Type: text/plain' \
  -d "${NEXUS_PASSWORD}" \
)

if [[ ${HTTP_RESPONSE} != "204" ]]; then
    echo '[ERROR] failed to set new password' >&2
    exit 1
else
    echo '[INFO] set new password'
fi

# Enable anonymous access
HTTP_RESPONSE=$( \
  curl -k -s -w "%{http_code}" -o "security-anonymous.json" -u admin:${NEXUS_PASSWORD} \
  -X PUT "${NEXUS_URL}/service/rest/v1/security/anonymous" \
  -H 'Content-Type: application/json' \
  -d '{"enabled": true}' \
)

if [[ ${HTTP_RESPONSE} != "200" ]]; then
    echo '[ERROR] failed to enable anonymous access' >&2
    exit 1
else
    echo '[INFO] enabled anonymous access'
fi

# Get active security realms
CURRENT_REALMS=$(curl -k -s -u admin:${NEXUS_PASSWORD} -X GET "${NEXUS_URL}/service/rest/v1/security/realms/active" \
  -H 'accept: application/json' )

# Add Docker Bearer Token Realm
REALMS_TO_ADD=("DockerToken")
UPDATED_REALMS=$(echo "$CURRENT_REALMS" | jq --argjson to_add "$(printf '%s\n' "${REALMS_TO_ADD[@]}" | jq -R . | jq -s .)" ' . + $to_add | unique')

HTTP_RESPONSE=$( \
  curl -k -s -w "%{http_code}" -u admin:${NEXUS_PASSWORD} \
  -X PUT "${NEXUS_URL}/service/rest/v1/security/realms/active" \
  -H 'Content-Type: application/json' \
  -d "${UPDATED_REALMS}" \
)

if [[ ${HTTP_RESPONSE} != "204" ]]; then
    echo "[ERROR] failed to add new realms: ${REALMS_TO_ADD}" >&2
    exit 1
else
    echo "[INFO] added new realms: ${REALMS_TO_ADD}"
fi

# Delete default repositories
DEFAULT_REPOS=$(curl -s -k -u admin:${NEXUS_PASSWORD} "${NEXUS_URL}/service/rest/v1/repositories" | jq -r '.[].name')
for REPO in ${DEFAULT_REPOS}; do
  HTTP_RESPONSE=$(curl -s -k -w "%{http_code}" -u admin:${NEXUS_PASSWORD} -X DELETE "${NEXUS_URL}/service/rest/v1/repositories/${REPO}")

  if [[ ${HTTP_RESPONSE} != "204" ]]; then
      echo "[ERROR] failed to delete repository: ${REPO}" >&2
      exit 1
  else
      echo "[INFO] deleted repository: ${REPO}"
  fi
done

# Add Docker registry for model generators
HTTP_RESPONSE=$( \
  curl -k -s -w "%{http_code}" -u admin:${NEXUS_PASSWORD} \
  -X POST "${NEXUS_URL}/service/rest/v1/repositories/docker/hosted" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "model-generators",
    "online": true,
    "storage": {
      "blobStoreName": "default",
      "strictContentTypeValidation": true,
      "writePolicy": "allow_once"
    },
    "docker": {
      "v1Enabled": true,
      "forceBasicAuth": true,
      "httpPort": 8082
    },
    "cleanup": {
      "policyNames": []
    },
    "component": {
      "proprietaryComponents": false
    }
  }' \
)

if [[ ${HTTP_RESPONSE} != "201" ]]; then
    echo '[ERROR] failed to add registry for model generators' >&2
    exit 1
else
    echo '[INFO] added registry for model generators'
fi

# Add Docker registry for models
HTTP_RESPONSE=$( \
curl -k -s -w "%{http_code}" -u admin:${NEXUS_PASSWORD} \
  -X POST "${NEXUS_URL}/service/rest/v1/repositories/docker/hosted" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "model-images",
    "online": true,
    "storage": {
      "blobStoreName": "default",
      "strictContentTypeValidation": true,
      "writePolicy": "allow_once"
    },
    "docker": {
      "v1Enabled": true,
      "forceBasicAuth": true,
      "httpPort": 8083
    },
    "cleanup": {
      "policyNames": []
    },
    "component": {
      "proprietaryComponents": false
    }
  }' \
)

if [[ ${HTTP_RESPONSE} != "201" ]]; then
    echo '[ERROR] failed to add registry for model images' >&2
    exit 1
else
    echo '[INFO] added registry for model images'
fi
