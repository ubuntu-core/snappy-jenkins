#!/bin/bash
set -x

. ./bin/cloud-common.sh
. ./bin/secrets/common.sh

ENV=${1:-remote}
SWARM_SECGROUP="swarm"
IMAGE_NAME="uci/cloudimg/wily-amd64.img"
SWARM_MASTER="swarm-master-${OS_USERNAME}-${OS_REGION_NAME}"
SWARM_NODE="swarm-node-${OS_USERNAME}-${OS_REGION_NAME}"
CONSUL_IP=$(docker-machine ip $(vault_machine_name "$ENV"))
CONSUL_URL="consul://${CONSUL_IP}:8500"

create_swarm_security_group(){
    openstack security group delete $SWARM_SECGROUP
    openstack security group create --description "swarm secgroup" $SWARM_SECGROUP
    openstack security group rule create --proto tcp --dst-port 22 --src-ip 10.0.0.0/8 $SWARM_SECGROUP
    openstack security group rule create --proto tcp --dst-port 8080 --src-ip 10.0.0.0/8 $SWARM_SECGROUP
    openstack security group rule create --proto tcp --dst-port 8081 --src-ip 0.0.0.0/0 $SWARM_SECGROUP
    # 2376 is the port used by the docker daemon to server the REST API in ssl mode
    # https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml?search=docker
    openstack security group rule create --proto tcp --dst-port 2376 --src-ip 10.0.0.0/8 $SWARM_SECGROUP
    # 3376 is the default port used by swarm nodes
    openstack security group rule create --proto tcp --dst-port 3376 --src-ip 10.0.0.0/8 $SWARM_SECGROUP
}

create_options(){
    local node_type="$1"
    local flavor="$2"
    local index="$3"
    local output="create -d openstack \
                   --openstack-flavor-name $flavor \
                   --openstack-image-name $IMAGE_NAME \
                   --openstack-sec-groups $SWARM_SECGROUP \
                   --openstack-ssh-user ubuntu \
                   --openstack-keypair-name $KEYPAIR_NAME \
                   --openstack-private-key-file $DEFAULT_PRIVATE_KEY_PATH \
                   --swarm \
                   --swarm-discovery=$CONSUL_URL \
                   --engine-opt=cluster-store=$CONSUL_URL \
                   --engine-opt=cluster-advertise=eth0:2376 "
    if [ "$node_type" = "master" ]; then
        output="$output --swarm-master "
    elif [ "$index" = "$SWARM_PUBLIC_INDEX" ]; then
        output="$output --engine-label public=yes "
    fi

    echo "$output"
}

create_swarm_master(){
    docker-machine rm -f $SWARM_MASTER
    options=$(create_options "master" "cpu2-ram8-disk100-ephemeral20")

    docker-machine $options $SWARM_MASTER
}

create_swarm_node(){
    local index="$1"
    local node_name="${SWARM_NODE}-${index}"

    docker-machine rm -f $node_name
    options=$(create_options "node" "cpu4-ram8-disk100-ephemeral20" "$index")

    docker-machine $options $node_name
}

create_swarm_security_group

create_keypair "$DEFAULT_PRIVATE_KEY_PATH" "$KEYPAIR_NAME"

create_swarm_master

for index in $(seq 4)
do
    create_swarm_node $index
done

. ./bin/jenkins/cloud-redeploy.sh
