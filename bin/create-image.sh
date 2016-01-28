#!/bin/sh
set -x

. ./bin/common.sh
. ./bin/cloud-common.sh

get_image_name(){
    DIST=$1
    echo "$DIST-daily-amd64"
}

setup_jenkins_home(){
    local IP=$1
    local JENKINS_HOME=$2
    local OPENSTACK_CREDENTIALS_DIR=$3
    execute_remote_command "$IP" "sudo umount /mnt && \
sudo rm -rf $JENKINS_HOME && \
sudo mkdir -p $JENKINS_HOME && \
sudo mount /dev/vdb $JENKINS_HOME && \
sudo chmod a+rwx $JENKINS_HOME && \
mkdir -p $OPENSTACK_CREDENTIALS_DIR"
}

send_and_execute(){
    local INSTANCE_IP=$1
    local JENKINS_HOME=$2
    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ./bin/common.sh ubuntu@"$INSTANCE_IP":"$JENKINS_HOME"
    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ./bin/remote/provision.sh ubuntu@"$INSTANCE_IP":"$JENKINS_HOME"
    execute_remote_command "$INSTANCE_IP" "sh $JENKINS_HOME/provision.sh"
}

IMAGE_NAME=$(get_image_name "$DIST")

INSTANCE_IP=$(launch_instance "$IMAGE_NAME")

wait_for_ssh "$INSTANCE_IP"

setup_jenkins_home "$INSTANCE_IP" "$JENKINS_HOME" "$OPENSTACK_CREDENTIALS_DIR"

send_and_execute "$INSTANCE_IP" "$JENKINS_HOME"

# TODO: snapshot
