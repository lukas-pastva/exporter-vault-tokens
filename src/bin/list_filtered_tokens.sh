#!/bin/sh

# Default substrings
INCLUDE_SUBSTRING="remp"
EXCLUDE_SUBSTRINGS="test"

# Parse command-line arguments for custom substrings
while [ "$#" -gt 0 ]; do
    case "$1" in
        --include=*)
            INCLUDE_SUBSTRING="${1#*=}"
            ;;
        --exclude=*)
            # Append to EXCLUDE_SUBSTRINGS, allowing multiple --exclude options
            if [ -z "$EXCLUDE_SUBSTRINGS" ]; then
                EXCLUDE_SUBSTRINGS="${1#*=}"
            else
                EXCLUDE_SUBSTRINGS="$EXCLUDE_SUBSTRINGS ${1#*=}"
            fi
            ;;
        *)
            echo "Unknown parameter: $1"
            echo "Usage: $0 [--include=substring] [--exclude=substring ...]"
            exit 1
            ;;
    esac
    shift
done

# Convert EXCLUDE_SUBSTRINGS to lowercase for case-insensitive comparison
EXCLUDE_SUBSTRINGS_LOWER=$(echo "$EXCLUDE_SUBSTRINGS" | tr 'A-Z' 'a-z')
INCLUDE_SUBSTRING_LOWER=$(echo "$INCLUDE_SUBSTRING" | tr 'A-Z' 'a-z')

# Fetch accessors, suppressing error messages
accessors=$(vault list auth/token/accessors 2>/dev/null | sed '/^Keys$/d; /^----$/d')

if [ -z "$accessors" ]; then
    echo "No token accessors found."
    exit 0
fi

for accessor in $accessors; do
    token_info=$(vault token lookup -accessor "$accessor" 2>/dev/null)
    
    # Check if token_info retrieval was successful
    if [ $? -ne 0 ]; then
        echo "Failed to retrieve token info for accessor: $accessor"
        continue
    fi

    # Extract the policies line
    policies_line=$(echo "$token_info" | grep '^policies' || true)
    if [ -z "$policies_line" ]; then
        continue
    fi

    # Extract individual policies (assuming they are comma-separated or space-separated)
    policies=$(echo "$policies_line" | sed 's/policies\s*\[\(.*\)\]/\1/' | tr ',' ' ')

    include_found=0
    exclude_found=0

    # Check each policy for include and exclude substrings
    for policy in $policies; do
        # Convert policy to lowercase for case-insensitive comparison
        policy_lower=$(echo "$policy" | tr 'A-Z' 'a-z')

        # Check for include substring
        if echo "$policy_lower" | grep -Fqi "$INCLUDE_SUBSTRING_LOWER"; then
            include_found=1
        fi

        # Check for any exclude substrings
        for exclude in $EXCLUDE_SUBSTRINGS_LOWER; do
            if echo "$policy_lower" | grep -Fqi "$exclude"; then
                exclude_found=1
                break
            fi
        done

        # If an exclude substring is found, no need to check further
        if [ "$exclude_found" -eq 1 ]; then
            break
        fi
    done

    # If criteria are met, display full token info
    if [ "$include_found" -eq 1 ] && [ "$exclude_found" -eq 0 ]; then
        echo "$token_info"
        echo "----------------------------------------"
    fi
done

echo "Script execution completed."
