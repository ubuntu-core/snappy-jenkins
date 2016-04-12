#!/bin/bash
set -x

. ./bin/secrets/common.sh
. ./bin/secrets/metadata.sh

environment=${1:-remote}

remote_copy(){
    local vault_path="$1"
    local file_path="$2"
    local nodes="$3"

    local file=$(mktemp)
    vault_read_to_file "$vault_path" "$file"

    for node in $nodes; do
        docker cp "$file" "$node":"$file_path"
    done

    rm -rf "$file"
}

remote_execute(){
    local script="$1"
    local nodes="${2:-$all_nodes}"

    if [ "$script" != "" ]; then
        for node in $nodes; do
            docker exec -u root -t "$node" bash -c "$script"
        done
    fi
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
                local file_path="${paths_map[$vault_path]}"
                if [ "$file_path" != "" ]; then
                    remote_copy "$vault_path" "$file_path" "$nodes"
                fi
                rm -rf "$file"
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
