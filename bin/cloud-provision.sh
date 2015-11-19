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

OPENSTACK_CREDENTIALS_PATH=$1
SPI_CREDENTIALS_PATH=$2
SECGROUP=$NAME
FLAVOR=m1.large

create_security_group() {
    nova secgroup-delete $SECGROUP
    nova secgroup-create $SECGROUP "snappy-jenkins secgroup"
    # ports 22 and 8080 only accessible from the vpn, port 8081
    # (jenkins reverse proxy) open to all
    nova secgroup-add-rule $SECGROUP tcp 22 22 10.0.0.0/8
    nova secgroup-add-rule $SECGROUP tcp 8080 8080 10.0.0.0/8
    nova secgroup-add-rule $SECGROUP tcp 8081 8081 0.0.0.0/0
}

launch_instance(){
    IMAGE_ID=$(nova image-list | grep wily-daily-amd64 | head -1 | awk '{print $4}')

    INSTANCE_ID=$(nova boot --key-name ${OS_USERNAME}_${OS_REGION_NAME} --security-groups $SECGROUP --flavor $FLAVOR --image $IMAGE_ID $NAME --poll | grep '| id ' | awk '{print $4}')

    INSTANCE_IP=$(nova show $INSTANCE_ID | grep 'canonistack network' | awk '{print $5}')

    if [ -z "$INSTANCE_IP" ]
    then
        echo "Couldn't get instance IP, retrying"
        sleep 20
        INSTANCE_IP=$(nova show $INSTANCE_ID | grep 'canonistack network' | awk '{print $5}')
        if [ -z "$INSTANCE_IP" ]
        then
            echo "Couldn't get instance IP, exiting"
            exit 1
        fi
    fi

}

send_and_execute(){
    scp ./bin/remote/provision.sh ubuntu@$INSTANCE_IP:$JENKINS_HOME
    execute_remote_command "sh $JENKINS_HOME/provision.sh"
}

copy_credentials() {
    scp -r $OPENSTACK_CREDENTIALS_PATH ubuntu@$INSTANCE_IP:$JENKINS_HOME
    if [ ! -z "$SPI_CREDENTIALS_PATH" ]
    then
        scp $SPI_CREDENTIALS_PATH ubuntu@$INSTANCE_IP:$JENKINS_HOME/.spi.ini
    fi
}

copy_proxy_conf(){
    scp ./config/proxy/proxy.conf ubuntu@$INSTANCE_IP:$JENKINS_HOME
}

copy_ghprb_conf(){
    scp ./config/ghprb/org.jenkinsci.plugins.ghprb.GhprbTrigger.xml ubuntu@$INSTANCE_IP:$JENKINS_HOME
}

setup_jenkins_home(){
    execute_remote_command "sudo umount /mnt && sudo rm -rf $JENKINS_HOME && sudo mkdir -p $JENKINS_HOME && sudo mount /dev/vdb $JENKINS_HOME && sudo chmod a+rwx $JENKINS_HOME"
}

create_security_group

launch_instance

wait_for_ssh

setup_jenkins_home

copy_proxy_conf

copy_ghprb_conf

send_and_execute

copy_credentials

exit 0
