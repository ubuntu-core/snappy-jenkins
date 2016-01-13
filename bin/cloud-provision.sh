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
    nova secgroup-delete $SECGROUP
    nova secgroup-create $SECGROUP "snappy-jenkins secgroup"
    # ports 22 and 8080 only accessible from the vpn, port 8081
    # (jenkins reverse proxy) open to all
    nova secgroup-add-rule $SECGROUP tcp 22 22 10.0.0.0/8
    nova secgroup-add-rule $SECGROUP tcp 8080 8080 10.0.0.0/8
    nova secgroup-add-rule $SECGROUP tcp 8081 8081 0.0.0.0/0
}

wait_for_ip(){
    local INSTANCE_ID=$1
    retry=60
    INSTANCE_IP=$(nova show $INSTANCE_ID | grep 'canonistack network' | awk '{print $5}')
    while [ -z "$INSTANCE_IP" ]; do
        retry=$(( retry - 1 ))
        if [ $retry -le 0 ]; then
            echo "Timed out waiting for instance IP. Aborting!"
            exit 1
        fi
        sleep 20
        INSTANCE_IP=$(nova show $INSTANCE_ID | grep 'canonistack network' | awk '{print $5}')
    done
}


launch_instance(){
    IMAGE_ID=$(nova image-list | grep xenial-daily-amd64 | head -1 | awk '{print $4}')

    INSTANCE_ID=$(nova boot --key-name ${OS_USERNAME}_${OS_REGION_NAME} --security-groups $SECGROUP --flavor $FLAVOR --image $IMAGE_ID $NAME --poll | grep '| id ' | awk '{print $4}')

    INSTANCE_IP=""
    wait_for_ip $INSTANCE_ID
}

send_and_execute(){
    scp ./bin/remote/provision.sh ubuntu@$INSTANCE_IP:$JENKINS_HOME
    execute_remote_command "sh $JENKINS_HOME/provision.sh"
}

copy_credentials() {
    scp $NOVARC_PATH ubuntu@$INSTANCE_IP:$OPENSTACK_CREDENTIALS_DIR/novarc

    if [ ! -z "$SPI_CREDENTIALS_PATH" ]
    then
        scp $SPI_CREDENTIALS_PATH ubuntu@$INSTANCE_IP:$JENKINS_HOME/.spi.ini
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

send_and_execute

copy_credentials

exit 0
