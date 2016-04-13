#!/bin/bash

setup_vault_addr(){
    machine_name=$1

    export VAULT_ADDR=http://$(docker-machine ip "$machine_name"):8200
}

vault_machine_name(){
    environment=$1
    os_username=${2:-${OS_USERNAME}}
    os_region_name=${3:-${OS_REGION_NAME}}

    echo "vault-${environment}-${os_username}-${os_region_name}"
}

vault_read_to_file(){
    local vault_path="$1"
    local file_path="$2"
    local value=$(vault read -field=value "$vault_path")

    if [ "$value" != "No value found at $vault_path" ]; then
        echo -n "$value" | uudecode -o /dev/stdout > "$file_path"
    else
        echo ""
    fi
}

vault_write_from_file(){
    local file_path="$1"
    local vault_path="$2"

    uuencode -m "$file_path" /dev/stdout | vault write "$vault_path" value=-
}

setup_vault(){
    machine_name=$1
    deploy_env=$2
    credentials_dir=$3

    # vault client should be installed locally!
    setup_vault_addr "$machine_name"
    echo "Waiting for the vault server to settle"
    sleep 10

    echo "Keep the following keys and root token in a safe place! They are unique for this deployment and will be saved in a vault-${deploy_env}.txt file in the current directory"
    init_output=$(vault init)
    echo "$init_output" > "./vault-${deploy_env}.txt"

    echo "The keys will be used next to unseal the server"
    for index in $(seq 3); do
        key=$(echo "$init_output" | grep "Key ${index}:" | awk '{ print $3 }')
        vault unseal "$key"
    done
    echo "The root token will be used for authorizing the client"
    root_token=$(echo "$init_output" | grep "Initial Root Token:" | awk '{ print $4 }')
    echo "Waiting for the vault server to settle"
    sleep 3

    if [ ! -z "$credentials_dir" ]; then
        vault auth "$root_token"
        . ./bin/secrets/restore.sh "$credentials_dir"
    fi
}
