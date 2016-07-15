#!/bin/sh
set -x

NAME_LOCAL="snappy-jenkins-local"

docker-machine rm -f "$NAME_LOCAL"
docker-machine create -d kvm "$NAME_LOCAL"
eval $(docker-machine env "$NAME_LOCAL")
docker-compose -f ./config/jenkins/cluster.yml -f ./config/jenkins/cluster.dev.yml up -d
