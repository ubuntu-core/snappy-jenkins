#!/bin/sh
set -x

. ./bin/common.sh
. ./bin/cloud-common.sh

PRIVATE_KEY_PATH=${1:-$DEFAULT_PRIVATE_KEY_PATH}

wait_for_ip(){
    local INSTANCE_ID=$1
    local retry=30
    local INSTANCE_IP=""
    INSTANCE_IP=$(openstack server show -c addresses -f value "$INSTANCE_ID" | cut -d= -f2)
    # when the instance hasn't came up yet the addresses line reads:
    #   | addresses |            |
    # so print $4 would be '|', this value will be returned until we have an IP assigned
    while [ -z "$INSTANCE_IP" -o "$INSTANCE_IP" = "|" ]; do
        retry=$(( retry - 1 ))
        if [ $retry -le 0 ]; then
            echo "Timed out waiting for instance IP. Aborting!"
            openstack server delete "$INSTANCE_ID"
            exit 1
        fi
        sleep 20
        INSTANCE_IP=$(openstack server show -c addresses -f value "$INSTANCE_ID" | cut -d= -f2)
    done
    echo "$INSTANCE_IP"
}

launch_instance(){
    local IMAGE_NAME=$1

    echo $(openstack server create --key-name ${OS_USERNAME}_${OS_REGION_NAME} --security-group $SECGROUP --flavor $FLAVOR --image $IMAGE_NAME -c id -f value $NAME_REMOTE)
}

add_instance_to_docker_machine(){
    local name="$1"
    local ip="$2"
    local ssh_key="$3"
    docker-machine rm -f "$name"
    docker-machine create -d generic \
                   --generic-ip-address "$ip" \
                   --generic-ssh-key "$ssh_key" \
                   --generic-ssh-user ubuntu \
                   "$name"
}

create_security_group "$SECGROUP"
create_keypair "$PRIVATE_KEY_PATH" "$KEYPAIR_NAME"

IMAGE_NAME=$(get_base_image_name "$DIST")
INSTANCE_ID=$(launch_instance "$IMAGE_NAME")
INSTANCE_IP=$(wait_for_ip "$INSTANCE_ID")

add_instance_to_docker_machine "$NAME_REMOTE" "$INSTANCE_IP" "$PRIVATE_KEY_PATH"

. ./bin/cloud-redeploy.sh
