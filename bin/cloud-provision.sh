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

. ./bin/cloud-common.sh

OPENSTACK_CREDENTIALS_PATH=$1
SPI_CREDENTIALS_PATH=$2
SECGROUP=$NAME
FLAVOR=m1.large

create_security_group() {
    nova secgroup-delete $SECGROUP
    nova secgroup-create $SECGROUP "snappy-jenkins secgroup"
    nova secgroup-add-rule $SECGROUP tcp 22 22 0.0.0.0/0
    nova secgroup-add-rule $SECGROUP tcp 8080 8080 0.0.0.0/0
}

launch_instance(){
    IMAGE_ID=$(nova image-list | grep wily-daily-amd64 | head -1 | awk '{print $4}')

    INSTANCE_ID=$(nova boot --key-name ${OS_USERNAME}_${OS_REGION_NAME} --security-groups $SECGROUP --flavor $FLAVOR --image $IMAGE_ID $NAME --poll | grep '| id ' | awk '{print $4}')

    INSTANCE_IP=$(nova show $INSTANCE_ID | grep 'canonistack network' | awk '{print $5}')

    if [ -z "$INSTANCE_IP" ]
    then
        echo "Couldn't get instance IP, retrying"
        sleep 10
        INSTANCE_IP=$(nova show $INSTANCE_ID | grep 'canonistack network' | awk '{print $5}')
        if [ -z "$INSTANCE_IP" ]
        then
            echo "Couldn't get instance IP, exiting"
            exit 1
        fi
    fi

}

copy_service_definition(){
    scp ./snappy-jenkins.service ubuntu@$INSTANCE_IP:/home/ubuntu
}

send_and_execute(){
    scp ./bin/remote/provision.sh ubuntu@$INSTANCE_IP:/home/ubuntu
    execute_remote_command "sh /home/ubuntu/provision.sh"
}

copy_credentials() {
    scp -r $OPENSTACK_CREDENTIALS_PATH ubuntu@$INSTANCE_IP:$JENKINS_HOME
    if [ ! -z "$SPI_CREDENTIALS_PATH" ]
    then
        scp $SPI_CREDENTIALS_PATH ubuntu@$INSTANCE_IP:$JENKINS_HOME/.spi.ini
    fi
}

create_security_group

launch_instance

wait_for_ssh

copy_service_definition

send_and_execute

copy_credentials

exit 0
