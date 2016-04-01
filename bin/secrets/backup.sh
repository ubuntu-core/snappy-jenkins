#!/bin/bash
set +x

if [ -z "$1" ]
then
    echo "Secrets tree path not given as first argument, exiting"
    exit 1
fi

SECRETS_TREE_PATH="$1"
ENVIRONMENT=${2:-remote}

. ./bin/secrets/common.sh

backup_dir(){
    local source_dir="$1"
    local base_target_dir="$2"

    vault list "$source_dir" | while read line; do
        if [ "${line: -1}" = "/" ]; then
            echo "directory $source_dir$line"
            backup_dir "$source_dir$line" "$base_target_dir"
        else
            if [ "$line" != "Keys" ]; then
                local dir="$base_target_dir/$source_dir"
                mkdir -p "$dir"
                vault read -field=value "$source_dir$line" > "$dir/$line"
            fi
        fi
    done
}

machine_name=$(vault_machine_name "$ENVIRONMENT")
setup_vault_addr "$machine_name"

backup_dir secret/ "$SECRETS_TREE_PATH"
