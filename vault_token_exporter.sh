#!/bin/bash

# Configuration
VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"  # Default Vault address if not set
VAULT_TOKEN=$(cat "/vault/secrets/vault-token")
ACCESSORS_FILE="/vault/secrets/vault-accessors"
METRICS_FILE="/tmp/vault_token_expiration.prom"
PORT=9100

# Function to query Vault for a token's expiration using its accessor and write to the metrics file
query_token_expiration() {
    local description=$1
    local accessor=$2

    # Authenticate with Vault using the Kubernetes service account token
    local jwt=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
    local vault_token_response=$(curl -s --request POST --data "{\"jwt\": \"$jwt\", \"role\": \"${ROLE_NAME}sys-vault-token-exporter\"}" $VAULT_ADDR/v1/auth/kubernetes/login)
    local vault_token=$(echo $vault_token_response | jq -r '.auth.client_token')

    # Use the vault_token for the API request
    local response=$(curl -s \
        --header "X-Vault-Token: $vault_token" \
        --request POST \
        --data "{\"accessor\":\"$accessor\"}" \
        "$VAULT_ADDR/v1/auth/token/lookup-accessor")

    local expire_time=$(echo $response | jq -r '.data.expire_time')

    if [[ "$expire_time" != "null" && -n "$expire_time" ]]; then
        # Convert ISO 8601 date to epoch seconds using awk
        local expiration_epoch=$(echo $expire_time | awk -F "[-T:Z]" '{print mktime($1" "$2" "$3" "$4" "$5" "$6)}')
        local current_epoch=$(date -u +%s)
        local remaining_seconds=$((expiration_epoch - current_epoch))

        # Prevent negative remaining time
        if [[ "$remaining_seconds" -lt 0 ]]; then
            remaining_seconds=0
        fi

        # Write the metric
        echo "vault_token_expiration_time_seconds{description=\"$description\", accessor=\"$accessor\"} $remaining_seconds" >> $METRICS_FILE
    else
        echo "vault_token_expiration_time_seconds{description=\"$description\", accessor=\"$accessor\", error=\"lookup_failed\"} -1" >> $METRICS_FILE
    fi
}

# Generate metrics before starting the server
echo "# HELP vault_token_expiration_time_seconds The expiration time of Vault tokens in seconds from now." > $METRICS_FILE
echo "# TYPE vault_token_expiration_time_seconds gauge" >> $METRICS_FILE

while IFS=: read -r description accessor || [[ -n "$description" ]]; do
    query_token_expiration "$description" "$accessor"
done < "$ACCESSORS_FILE"

# Serve the metrics using nc, without -q option, looping to accept one connection at a time
while true; do
    { echo -ne "HTTP/1.1 200 OK\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n"; cat $METRICS_FILE; } | nc -l -p $PORT
done
