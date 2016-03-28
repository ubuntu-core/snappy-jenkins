#!/bin/sh
set -x

. ./bin/common.sh

NAME_LOCAL="$NAME-local"

docker-machine rm -f "$NAME_LOCAL"
docker-machine create -d kvm "$NAME_LOCAL"
eval $(docker-machine env "$NAME_LOCAL")
docker-compose -f ./config/jenkins/cluster.yml -f ./config/jenkins/cluster.dev.yml up -d
