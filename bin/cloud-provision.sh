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
OPENSTACK_CREDENTIALS_DIR="$JENKINS_HOME/.openstack"

copy_credentials() {
    local NOVARC_PATH=$1
    local INSTANCE_IP=$2
    local OPENSTACK_CREDENTIALS_DIR=$3
    local SPI_CREDENTIALS_PATH=$4
    local JENKINS_HOME=$5
    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "$NOVARC_PATH" ubuntu@"$INSTANCE_IP":"$OPENSTACK_CREDENTIALS_DIR"/novarc

    if [ ! -z "$SPI_CREDENTIALS_PATH" ]
    then
        scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "$SPI_CREDENTIALS_PATH" ubuntu@"$INSTANCE_IP":"$JENKINS_HOME"/.spi.ini
    fi
}

create_security_group "$SECGROUP"

IMAGE_NAME=$(get_base_image_name "$DIST")

INSTANCE_ID=$(launch_instance "$IMAGE_NAME")

INSTANCE_IP=$(wait_for_ip "$INSTANCE_ID")

wait_for_ssh "$INSTANCE_IP"

copy_credentials "$NOVARC_PATH" "$INSTANCE_IP" "$OPENSTACK_CREDENTIALS_DIR" "$SPI_CREDENTIALS_PATH" "$JENKINS_HOME"

update_containers

exit 0
