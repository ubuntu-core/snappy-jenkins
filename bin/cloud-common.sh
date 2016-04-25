#!/bin/sh

export FLAVOR=cpu8-ram10-disk100-ephemeral20
export KEYPAIR_NAME=${OS_USERNAME}_${OS_REGION_NAME}
export DEFAULT_PRIVATE_KEY_PATH="${HOME}/.canonistack/${OS_USERNAME}_${OS_REGION_NAME}.key"
export COMPOSE_HTTP_TIMEOUT=180
export DIST="trusty"
export SWARM_PUBLIC_INDEX="1"

create_keypair(){
    local private_key=$1
    local keypair_name=$2

    local tmpdir=$(mktemp -d)
    trap "rm -rf $tmpdir" EXIT
    local public_key=$tmpdir/$keypair_name

    openstack keypair delete $keypair_name
    ssh-keygen -y -f $private_key > $public_key
    openstack keypair create --public-key $public_key $keypair_name
}

swarm_master_name(){
    echo "swarm-master-${OS_USERNAME}-${OS_REGION_NAME}"
}

swarm_public_name(){
    echo "swarm-node-${OS_USERNAME}-${OS_REGION_NAME}-${SWARM_PUBLIC_INDEX}"
}

safe_restart(){
    local env=${1:-remote}

    . ./bin/secrets/common.sh

    vault_machine_name=$(vault_machine_name "$env")

    setup_vault_addr "$vault_machine_name"

    token=$(vault read -field=value "secret/jenkins/config/admin_token")

    machine_name=$(swarm_public_name)
    master_ip=$(docker-machine ip "${machine_name}")

    echo "Restarting Jenkins after all the current jobs have finished..."
    curl -u admin:"$token" -X POST "http://${master_ip}:8080/safeRestart" --data token="$token"
}
