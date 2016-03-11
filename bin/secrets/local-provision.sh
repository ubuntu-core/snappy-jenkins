#!/bin/sh
set -x

. ./bin/secrets/common.sh

NAME_LOCAL="vault-local"

docker-machine rm -f "$NAME_LOCAL"
docker-machine create -d kvm "$NAME_LOCAL"
eval $(docker-machine env "$NAME_LOCAL")
docker-compose -f ./config/vault/cluster.yml -f ./config/vault/cluster.dev.yml up -d

setup_vault $NAME_LOCAL local
