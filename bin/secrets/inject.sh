#!/bin/bash
set -x

. ./bin/secrets/common.sh
. ./bin/secrets/metadata.sh

environment=${1:-remote}

vault_read(){
    local path="$1"
    local value=$(vault read -field=value "$path")

    if [ "$value" != "No value found at $path" ]; then
        echo "$value"
    else
        echo ""
    fi
}

remote_copy(){
    local value="$1"
    local path="$2"
    local nodes="$3"

    local dir=$(mktemp -d)
    local file="$dir/value"
    echo "$value" > "$file"

    for node in $nodes; do
        docker cp "$file" "$node":"$path"
    done

    rm -rf "$dir"
}

remote_execute(){
    local script="$1"
    local nodes="${2:-$all_nodes}"

    for node in $nodes; do
        docker exec -u root -t "$node" bash -c "$script"
    done
}

inject(){
    local base_path="$1"

    local before_script="${before_scripts_map[$base_path]}"
    local after_script="${after_scripts_map[$base_path]}"
    local nodes="${nodes_map[$base_path]}"

    remote_execute "$before_script" "$nodes"

    vault list "$base_path" | while read line; do
        if [ "${line: -1}" = "/" ]; then
            echo "directory $source_dir$line"
            inject "$base_path$line"
        else
            if [ "$line" != "Keys" ]; then
                local vault_path="$base_path$line"
                local value=$(vault_read "$vault_path")
                local file_path="${paths_map[$vault_path]}"
                if [ "$file_path" != "" ]; then
                    remote_copy "$value" "$file_path" "$nodes"
                fi
            fi
        fi
    done

    remote_execute "$after_script" "$nodes"
}

machine_name=$(vault_machine_name "$environment")
setup_vault_addr "$machine_name"

echo "Access to Vault is required for retrieving secrets"

eval $(docker-machine env "snappy-jenkins-${environment}")

inject secret/

docker-machine ssh "snappy-jenkins-${environment}" sync

docker restart $master
