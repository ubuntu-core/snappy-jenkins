#!/bin/sh
set -x

. ./bin/jenkins/common.sh
. ./bin/cloud-common.sh

PRIVATE_KEY_PATH=${1:-$DEFAULT_PRIVATE_KEY_PATH}
IMAGE_NAME="uci/cloudimg/$DIST-amd64.img"

create_snapshot(){
    local ip="$1"
    local id="$2"
    local dist="$3"

    image_name=$(get_base_image_name "$dist")
    prev_image_name="$image_name"-prev
    new_image_name="$image_name"-new

    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$ip sync
    openstack image delete "$prev_image_name"
    openstack server image create --name "$new_image_name" --wait "$id"
    openstack image set --name "$prev_image_name" "$image_name"
    openstack image set --name "$image_name" "$new_image_name"
}

create_docker_machine(){
    docker-machine rm -f $NAME_REMOTE_SEED
    docker-machine create --driver openstack \
               --openstack-flavor-name $FLAVOR \
               --openstack-image-name $IMAGE_NAME \
               --openstack-sec-groups $NAME \
               --openstack-ssh-user ubuntu \
               --openstack-keypair-name $KEYPAIR_NAME \
               --openstack-private-key-file $PRIVATE_KEY_PATH \
               $NAME_REMOTE_SEED
}

create_security_group "$SECGROUP"

create_keypair "$PRIVATE_KEY_PATH" "$KEYPAIR_NAME"

create_docker_machine
IP=$(docker-machine ip "$NAME_REMOTE_SEED")
ID=$(openstack server list | grep "$IP" | awk '{ print $2 }')
trap "openstack server delete $ID" EXIT

eval $(docker-machine env "$NAME_REMOTE_SEED")
docker-compose -f ./config/jenkins/cluster.yml up -d

if [ "$?" -eq 0 ]; then
    create_snapshot "$IP" "$ID" "$DIST"
fi
