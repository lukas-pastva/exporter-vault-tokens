#!/bin/bash

# Configuration
VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}" # Default Vault address if not set
VAULT_TOKEN=$(cat "/vault/secrets/vault-token")
ACCESSORS_FILE="/vault/secrets/vault-accessors"
METRICS_FILE="/tmp/vault_token_expiration.prom"
PORT=9100

# Function to query Vault for a token's expiration using its accessor and write to the metrics file
query_token_expiration() {
    local description=$1
    local accessor=$2
    local response=$(curl -s \
        --header "X-Vault-Token: $VAULT_TOKEN" \
        --request POST \
        --data "{\"accessor\":\"$accessor\"}" \
        "$VAULT_ADDR/v1/auth/token/lookup-accessor")

    local expire_time=$(echo $response | jq -r '.data.expire_time')

    if [ "$expire_time" != "null" ]; then
        # Convert expiration time to epoch and calculate remaining seconds
        local expiration_epoch=$(date --date="$expire_time" +%s)
        local current_epoch=$(date +%s)
        local remaining_seconds=$((expiration_epoch - current_epoch))

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

# Serve the metrics using nc
while true; do
    { echo -ne "HTTP/1.1 200 OK\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n"; cat $METRICS_FILE; } | nc -l -p $PORT -q 1
done
