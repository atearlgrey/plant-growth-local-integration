#!/bin/sh
set -e

# =============================
# ⚙️ ENVIRONMENT VARIABLES
# =============================
REALM="${REALM:-plant-growth}"
ADMIN_USER="${KEYCLOAK_ADMIN:-admin}"
ADMIN_PASS="${KEYCLOAK_ADMIN_PASSWORD:-admin}"
KEYCLOAK_URL="${KEYCLOAK_URL:-http://keycloak:8080}"

IMPORT_DIR="/opt/keycloak/data/import"

# =============================
# ⏳ WAIT FOR KEYCLOAK READY
# =============================
echo "⏳ Waiting for Keycloak to be ready at ${KEYCLOAK_URL}..."
until curl -s "${KEYCLOAK_URL}/realms/master/.well-known/openid-configuration" > /dev/null; do
  sleep 5
  echo "⏳ Still waiting..."
done

# =============================
# 🔐 GET ADMIN TOKEN
# =============================
echo "🔐 Getting admin token for user '${ADMIN_USER}'..."
TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -d "client_id=admin-cli" \
  -d "username=${ADMIN_USER}" \
  -d "password=${ADMIN_PASS}" \
  -d "grant_type=password" | jq -r .access_token)

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "❌ Failed to get admin token. Check credentials or Keycloak status."
  exit 1
fi

echo "✅ Got admin token. Starting import into realm '${REALM}'..."

# =============================
# 📦 IMPORT HELPERS
# =============================

import_dir_files() {
  local endpoint="$1"
  local path="$2"

  if [ -d "${path}" ]; then
    for file in "${path}"/*.json; do
      [ -e "$file" ] || continue
      echo "📥 Importing $(basename "$file") → ${endpoint}"
      curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/${endpoint}" \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" \
        -d @"${file}" \
        || echo "⚠️ Failed or already exists: $(basename "$file")"
    done
  else
    echo "⚠️ Directory ${path} not found, skipping."
  fi
}

# =============================
# 🚀 IMPORT SECTIONS
# =============================

# Client Scopes
import_dir_files "client-scopes" "${IMPORT_DIR}/client-scopes"

# Resource Servers
import_dir_files "clients" "${IMPORT_DIR}/resources"

# Clients
import_dir_files "clients" "${IMPORT_DIR}/clients"

# Users
import_dir_files "users" "${IMPORT_DIR}/users"

# Roles (optional)
import_dir_files "roles" "${IMPORT_DIR}/roles"

echo "✅ All imports completed successfully for realm '${REALM}'!"
