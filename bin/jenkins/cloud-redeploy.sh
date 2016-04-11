#!/bin/bash

set -x

. ./bin/jenkins/common.sh
. ./bin/jenkins/cloud-common.sh

eval $(docker-machine env "$NAME_REMOTE")
docker-compose -f ./config/jenkins/cluster.yml pull

. ./bin/jenkins/backup.sh

docker-compose -f ./config/jenkins/cluster.yml down

docker-compose -f ./config/jenkins/cluster.yml up -d

. ./bin/jenkins/restore.sh backup.tar.gz

. ./bin/secrets/inject.sh

# remove non-running containers (if they are running this command gives an error)
# --no-trunc prevents id collisions by showing the complete field. -a shows all
# containers, not only running ones. -q only outputs the numeric id field
docker rm $(docker ps --no-trunc -aq)
docker rmi $(docker images --filter dangling=true --quiet)
docker volume rm $(docker volume ls -qf dangling=true)
