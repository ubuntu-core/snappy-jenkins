#!/bin/sh
set -x

. ./bin/common.sh

export JENKINS_HOME=/tmp/jenkins
NAME_LOCAL="$NAME-local"

docker-machine rm -f "$NAME_LOCAL"
docker-machine create -d kvm "$NAME_LOCAL"
eval $(docker-machine env "$NAME_LOCAL")
docker-compose -f ./config/compose/cluster.yml -f ./config/compose/cluster.dev.yml up -d
