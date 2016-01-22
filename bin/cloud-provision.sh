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
. ./bin/cloud-common.sh

NOVARC_PATH=$1
SPI_CREDENTIALS_PATH=$2
SECGROUP=$NAME
FLAVOR=m1.large
OPENSTACK_CREDENTIALS_DIR="$JENKINS_HOME/.openstack"

create_security_group() {
    openstack security group delete $SECGROUP
    openstack security group create --description "snappy-jenkins secgroup" $SECGROUP
    # ports 22 and 8080 only accessible from the vpn, port 8081
    # (jenkins reverse proxy) open to all
    openstack security group rule create --proto tcp --dst-port 22 --src-ip 10.0.0.0/8 $SECGROUP
    openstack security group rule create --proto tcp --dst-port 8080 --src-ip 10.0.0.0/8 $SECGROUP
    openstack security group rule create --proto tcp --dst-port 8081 --src-ip 0.0.0.0/0 $SECGROUP
}

wait_for_ip(){
    local INSTANCE_ID=$1
    retry=60
    INSTANCE_IP=$(openstack server show $INSTANCE_ID | grep 'addresses' | awk '{print $4}' | cut -d= -f2)
    # when the instance hasn't came up yet the addresses line reads:
    #   | addresses |            |
    # so print $4 would be '|', this value will be returned until we have an IP assigned
    while [ -z "$INSTANCE_IP" -o "$INSTANCE_IP" = "|" ]; do
        retry=$(( retry - 1 ))
        if [ $retry -le 0 ]; then
            echo "Timed out waiting for instance IP. Aborting!"
            exit 1
        fi
        sleep 20
        INSTANCE_IP=$(openstack server show $INSTANCE_ID | grep 'addresses' | awk '{print $4}' | cut -d= -f2)
    done
}


launch_instance(){
    IMAGE_ID=$(openstack image list | grep "$DIST"-daily-amd64 | head -1 | awk '{print $4}')

    INSTANCE_ID=$(openstack server create --key-name ${OS_USERNAME}_${OS_REGION_NAME} --security-group $SECGROUP --flavor $FLAVOR --image $IMAGE_ID $NAME | grep '| id ' | awk '{print $4}')

    INSTANCE_IP=""
    wait_for_ip $INSTANCE_ID
}

send_and_execute(){
    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ./bin/common.sh ubuntu@$INSTANCE_IP:$JENKINS_HOME
    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ./bin/remote/provision.sh ubuntu@$INSTANCE_IP:$JENKINS_HOME
    execute_remote_command "sh $JENKINS_HOME/provision.sh"
}

copy_credentials() {
    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $NOVARC_PATH ubuntu@$INSTANCE_IP:$OPENSTACK_CREDENTIALS_DIR/novarc

    if [ ! -z "$SPI_CREDENTIALS_PATH" ]
    then
        scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $SPI_CREDENTIALS_PATH ubuntu@$INSTANCE_IP:$JENKINS_HOME/.spi.ini
    fi
}

setup_jenkins_home(){
    execute_remote_command "sudo umount /mnt && \
sudo rm -rf $JENKINS_HOME && \
sudo mkdir -p $JENKINS_HOME && \
sudo mount /dev/vdb $JENKINS_HOME && \
sudo chmod a+rwx $JENKINS_HOME && \
mkdir -p $OPENSTACK_CREDENTIALS_DIR"
}

create_security_group

launch_instance

wait_for_ssh

setup_jenkins_home

copy_credentials

send_and_execute

exit 0
