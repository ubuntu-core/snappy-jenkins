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
    execute_remote_command "$IP" "sudo rm -rf $JENKINS_HOME && \
sudo mkdir -p $JENKINS_HOME && \
sudo chmod a+rwx $JENKINS_HOME && \
sudo chown ubuntu:ubuntu $JENKINS_HOME && \
mkdir -p $OPENSTACK_CREDENTIALS_DIR"
}

create_snapshot(){
    local id="$1"
    local dist="$2"

    image_name=$(get_base_image_name "$dist")
    prev_image_name="$image_name"-prev
    new_image_name="$image_name"-new

    openstack image delete "$prev_image_name"
    openstack server image create --name "$new_image_name" --wait "$id"
    openstack image set --name "$prev_image_name" "$image_name"
    openstack image set --name "$image_name" "$new_image_name"
}

create_security_group "$SECGROUP"

IMAGE_NAME=$(get_image_name "$DIST")

INSTANCE_ID=$(launch_instance "$IMAGE_NAME")

INSTANCE_IP=$(wait_for_ip "$INSTANCE_ID")

wait_for_ssh "$INSTANCE_IP" "$INSTANCE_ID"

setup_jenkins_home "$INSTANCE_IP" "$JENKINS_HOME" "$OPENSTACK_CREDENTIALS_DIR"

send_and_execute "$INSTANCE_IP" "$JENKINS_HOME" "./bin/remote/provision.sh"

if [ "$?" -eq 0 ]; then
    create_snapshot "$INSTANCE_ID" "$DIST"
else
    echo "Error provisioning seed instance"
fi

openstack server delete "$INSTANCE_ID"

exit
