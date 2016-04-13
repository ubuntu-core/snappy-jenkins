#!/bin/sh

export NAME_REMOTE="$NAME-remote"
export NAME_REMOTE_SEED="${NAME_REMOTE}-seed"
export FLAVOR=cpu8-ram10-disk100-ephemeral20
export KEYPAIR_NAME=${OS_USERNAME}_${OS_REGION_NAME}
export DEFAULT_PRIVATE_KEY_PATH="${HOME}/.canonistack/${OS_USERNAME}_${OS_REGION_NAME}.key"
export COMPOSE_HTTP_TIMEOUT=180
export DIST="trusty"

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
