#!/bin/bash
set +x

if [ -z "$1" ]; then
    echo "Secrets tree path not given as first argument, exiting"
    exit 1

fi

if [ "${1: -1}" = "/" ]; then
    SECRETS_TREE_PATH="${1::-1}"
else
    SECRETS_TREE_PATH="${1}"
fi
ENVIRONMENT=${2:-remote}

. ./bin/secrets/common.sh

strip_base_dir(){
    target_dir="$1"
    echo ${target_dir#${SECRETS_TREE_PATH}/secret}
}

restore_dir(){
    local base_dir="$1"

    for dir in $(find "$base_dir" -type d); do
        for completefile in $(find "$dir" -maxdepth 1 -type f); do
            echo "writing file $file"
            file=$(strip_base_dir "$completefile")
            vault write "secret$file" value=@"$completefile"
        done
    done
}

machine_name=$(vault_machine_name "$ENVIRONMENT")
setup_vault_addr "$machine_name"

restore_dir "$SECRETS_TREE_PATH"
