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

JENKINS_HOME=/mnt/jenkins

. ./bin/common.sh

NOVARC_PATH=$1
SPI_CREDENTIALS_PATH=$2
FLAVOR=m1.large
OPENSTACK_CREDENTIALS_DIR="$JENKINS_HOME/.openstack"

create_security_group() {
    local SECGROUP=$1
    openstack security group delete $SECGROUP
    openstack security group create --description "snappy-jenkins secgroup" $SECGROUP
    # ports 22 and 8080 only accessible from the vpn, port 8081
    # (jenkins reverse proxy) open to all
    openstack security group rule create --proto tcp --dst-port 22 --src-ip 10.0.0.0/8 $SECGROUP
    openstack security group rule create --proto tcp --dst-port 8080 --src-ip 10.0.0.0/8 $SECGROUP
    openstack security group rule create --proto tcp --dst-port 8081 --src-ip 0.0.0.0/0 $SECGROUP
}

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


create_security_group "$NAME"

IMAGE_NAME=$(get_base_image_name "$DIST")

INSTANCE_IP=$(launch_instance "$IMAGE_NAME")

wait_for_ssh "$INSTANCE_IP"

copy_credentials "$NOVARC_PATH" "$INSTANCE_IP" "$OPENSTACK_CREDENTIALS_DIR" "$SPI_CREDENTIALS_PATH" "$JENKINS_HOME"

update_containers

exit 0
