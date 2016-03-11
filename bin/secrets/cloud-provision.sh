#!/bin/sh
set -x

if [ -z "$1" ]
then
    echo "No ssh private key path given as first argument, exiting"
    exit 1
fi
if [ -z "$2" ]
then
    echo "No Openstack credentials path given as second argument, exiting"
    exit 1
fi

. ./bin/common.sh
. ./bin/cloud-common.sh
. ./bin/secrets/common.sh

IMAGE_NAME="uci/cloudimg/$DIST-amd64.img"
VAULT_REMOTE="vault-remote-${OS_USERNAME}-${OS_REGION_NAME}"
VAULT_SECGROUP="vault"

SLAVE_SSH_PRIVATE_KEY_PATH=$1
SLAVE_OPENSTACK_CREDENTIALS_PATH=$2

create_vault_security_group() {
    openstack security group delete $VAULT_SECGROUP
    openstack security group create --description "vault secgroup" $VAULT_SECGROUP
    openstack security group rule create --proto tcp --dst-port 22 --src-ip 10.0.0.0/8 $VAULT_SECGROUP
    # vault port for client access
    openstack security group rule create --proto tcp --dst-port 8200 --src-ip 10.0.0.0/8 $VAULT_SECGROUP
    # consul ui port
    openstack security group rule create --proto tcp --dst-port 8500 --src-ip 10.0.0.0/8 $VAULT_SECGROUP
    # 2376 is the port used by the docker daemon to server the REST API in ssl mode
    # https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml?search=docker
    openstack security group rule create --proto tcp --dst-port 2376 --src-ip 10.0.0.0/8 $VAULT_SECGROUP
}

create_docker_machine(){
    docker-machine rm -f $VAULT_REMOTE
    docker-machine create --driver openstack \
               --openstack-flavor-name m1.medium \
               --openstack-image-name $IMAGE_NAME \
               --openstack-sec-groups $VAULT_SECGROUP \
               --openstack-ssh-user ubuntu \
               --openstack-keypair-name $KEYPAIR_NAME \
               --openstack-private-key-file $DEFAULT_PRIVATE_KEY_PATH \
               $VAULT_REMOTE
}

create_vault_security_group

create_keypair "$DEFAULT_PRIVATE_KEY_PATH" "$KEYPAIR_NAME"

create_docker_machine

eval $(docker-machine env "$VAULT_REMOTE")
docker-compose -f ./config/vault/cluster.yml up -d

setup_vault $VAULT_REMOTE remote
