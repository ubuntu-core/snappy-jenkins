#!/bin/bash

set -x

. ./bin/jenkins/common.sh
. ./bin/cloud-common.sh

machine_name=$(swarm_master_name)

eval $(docker-machine env --swarm "$machine_name")

docker-compose -f ./config/jenkins/cluster.yml pull

. ./bin/jenkins/backup.sh

docker-compose -f ./config/jenkins/cluster.yml down

docker-compose -f ./config/jenkins/cluster.yml up -d

docker-compose -f ./config/jenkins/cluster.yml scale jenkins-slave-xenial=5

. ./bin/jenkins/restore.sh backup.tar.gz

. ./bin/secrets/inject.sh

# remove non-running containers (if they are running this command gives an error)
# --no-trunc prevents id collisions by showing the complete field. -a shows all
# containers, not only running ones. -q only outputs the numeric id field
docker rm $(docker ps --no-trunc -aq)
docker rmi $(docker images --filter dangling=true --quiet)
docker volume rm $(docker volume ls -qf dangling=true)
