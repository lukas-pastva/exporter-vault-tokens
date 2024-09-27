#!/bin/sh

INCLUDE_SUBSTRING="remp"
EXCLUDE_SUBSTRING="test"

# Parse command-line arguments for custom substrings
while [ "$#" -gt 0 ]; do
    case "$1" in
        --include=*)
            INCLUDE_SUBSTRING="${1#*=}"
            ;;
        --exclude=*)
            EXCLUDE_SUBSTRING="${1#*=}"
            ;;
        *)
            echo "Unknown parameter: $1"
            echo "Usage: $0 [--include=substring] [--exclude=substring]"
            exit 1
            ;;
    esac
    shift
done

accessors=$(vault list auth/token/accessors | sed '/^Keys$/d; /^----$/d')

if [ -z "$accessors" ]; then
    echo "No token accessors found."
    exit 0
fi


for accessor in $accessors; do
    token_info=$(vault token lookup -accessor "$accessor")
    
    # Extract the policies line
    policies_line=$(echo "$token_info" | grep '^policies')
    if [ -z "$policies_line" ]; then
        continue
    fi
    
    # Extract individual policies
    policies=$(echo "$policies_line" | sed 's/policies\s*\[\(.*\)\]/\1/')
    
    include_found=0
    exclude_found=0
    
    # Check each policy for include and exclude substrings
    for policy in $(echo "$policies" | tr ' ' '\n'); do
        echo "$policy" | grep -i "$INCLUDE_SUBSTRING" > /dev/null && include_found=1
        echo "$policy" | grep -i "$EXCLUDE_SUBSTRING" > /dev/null && exclude_found=1
    done

    # If criteria are met, display full token info
    if [ "$include_found" -eq 1 ] && [ "$exclude_found" -eq 0 ]; then
        echo "$token_info"
        echo "----------------------------------------"
    fi
done

echo "Script execution completed."
