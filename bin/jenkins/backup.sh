#!/bin/bash

set -x

. ./bin/jenkins/common.sh

ENV=${1:-remote}

machine_name="$NAME-$ENV"

eval $(docker-machine env "$machine_name")

docker-machine ssh "$machine_name" sudo docker run --rm --volumes-from jenkins_jenkins-master-service_1 -v /tmp:/backup ubuntu:xenial tar cvfz /backup/backup.tar.gz $JENKINS_HOME/jobs --exclude='*config.xml'
docker-machine scp "$machine_name":/tmp/backup.tar.gz .
