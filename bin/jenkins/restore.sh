#!/bin/bash

set -x

. ./bin/jenkins/common.sh

if [ -z "$1" ]
then
    echo "Backup file path not provided, exiting"
    exit 1
fi

BACKUP_FILE="$1"
ENV=${2:-remote}

machine_name="$NAME-$ENV"

eval $(docker-machine env "$machine_name")

docker-machine scp "$BACKUP_FILE" "$machine_name":backup.tar.gz
docker-machine ssh "$machine_name" sudo rm -rf /tmp/backup.tar.gz
docker-machine ssh "$machine_name" cp backup.tar.gz /tmp
docker-machine ssh "$machine_name" sudo docker run --rm --volumes-from jenkins_jenkins-master-service_1 -v /tmp:/backup ubuntu:xenial tar xvfz /backup/backup.tar.gz
docker-compose -f ./config/jenkins/cluster.yml restart jenkins-master-service
