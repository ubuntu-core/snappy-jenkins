#!/bin/sh
set -x
if [ -z "$1" ]
then
    echo "No Openstack credentials path given as first argument, exiting"
    exit 1
fi
if [ -z "$2" ]
then
    echo "No snappy product integration credentials path given as second argument, won't be able to connect to SPI"
fi

. ./bin/common.sh
. ./bin/cloud-common.sh

NOVARC_PATH=$1
SPI_CREDENTIALS_PATH=$2
PRIVATE_KEY_PATH=${3:-$DEFAULT_PRIVATE_KEY_PATH}
OPENSTACK_CREDENTIALS_DIR="$JENKINS_HOME/.openstack"

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

copy_credentials() {
    local NOVARC_PATH=$1
    local INSTANCE_IP=$2
    local OPENSTACK_CREDENTIALS_DIR=$3
    local SPI_CREDENTIALS_PATH=$4
    local JENKINS_HOME=$5
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@"$INSTANCE_IP" sudo mkdir -p "$OPENSTACK_CREDENTIALS_DIR"
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@"$INSTANCE_IP" sudo chown -R ubuntu:ubuntu "$OPENSTACK_CREDENTIALS_DIR"
    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "$NOVARC_PATH" ubuntu@"$INSTANCE_IP":"$OPENSTACK_CREDENTIALS_DIR"/novarc

    if [ ! -z "$SPI_CREDENTIALS_PATH" ]
    then
        scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "$SPI_CREDENTIALS_PATH" ubuntu@"$INSTANCE_IP":"$JENKINS_HOME"/.spi.ini
    fi
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
copy_credentials "$NOVARC_PATH" "$INSTANCE_IP" "$OPENSTACK_CREDENTIALS_DIR" "$SPI_CREDENTIALS_PATH" "$JENKINS_HOME"

. ./bin/cloud-redeploy.sh
