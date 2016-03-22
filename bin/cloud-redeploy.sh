#!/bin/bash

set -x

. ./bin/common.sh
. ./bin/cloud-common.sh

eval $(docker-machine env "$NAME_REMOTE")
docker-compose -f ./config/jenkins/cluster.yml pull
docker-compose -f ./config/jenkins/cluster.yml down
docker-compose -f ./config/jenkins/cluster.yml up -d

. ./bin/secrets/init-credentials.sh

docker rm $(docker ps --no-trunc -aq)
docker rmi $(docker images --filter dangling=true --quiet)
docker volume rm $(docker volume ls -qf dangling=true)
