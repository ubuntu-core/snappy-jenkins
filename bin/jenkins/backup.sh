#!/bin/bash

set -x

. ./bin/jenkins/common.sh

machine_name=$(swarm_master_name)

eval $(docker-machine env --swarm "$machine_name")

docker-machine ssh "$machine_name" sudo docker run --rm --volumes-from jenkins_jenkins-master-service_1 -v /tmp:/backup ubuntu:xenial tar cvfz /backup/backup.tar.gz $JENKINS_HOME/jobs --exclude='*config.xml' --exclude='*coverage*.xml'
docker-machine scp "$machine_name":/tmp/backup.tar.gz .
