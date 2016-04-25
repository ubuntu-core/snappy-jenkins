#!/bin/bash

set -x

. ./bin/cloud-common.sh

if [ -z "$1" ]
then
    echo "Backup file path not provided, exiting"
    exit 1
fi

BACKUP_FILE="$1"

machine_name=$(swarm_public_name)

eval $(docker-machine env "$machine_name")

# copy to /home/ubuntu, in the local deployments /tmp is a symlink and docker-machine scp
# complains about copying to it
docker-machine ssh "$machine_name" sudo rm -rf /home/ubuntu/backup.tar.gz
docker-machine scp "$BACKUP_FILE" "$machine_name":/home/ubuntu/backup.tar.gz
docker-machine ssh "$machine_name" sudo docker run --rm --volumes-from jenkins_jenkins-master-service_1 -v /home/ubuntu:/backup ubuntu:xenial tar xvfz /backup/backup.tar.gz

safe_restart
