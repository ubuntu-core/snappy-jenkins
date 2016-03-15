#!/bin/sh
set -x

if [ -z "$1" ]
then
    echo "Source IP not provided, exiting"
    exit 1
fi
if [ -z "$2" ]
then
    echo "Target IP not provided, exiting"
    exit 1
fi

SOURCE_IP="$1"
TARGET_IP="$2"
basedir=$(mktemp -d)

. ./bin/common.sh
. ./bin/cloud-common.sh

sync_job_history(){
    local dir="$basedir"/jobs
    mkdir $dir

    rsync -avzL -e "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" --exclude config.xml $SOURCE_IP:$JENKINS_HOME/jobs/* $dir
    rsync -avz -e "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" $dir $TARGET_IP:$JENKINS_HOME
}

eval $(docker-machine env snappy-jenkins-remote)

docker stop compose_jenkins-master-service_1
sync_job_history
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$TARGET_IP \
    sync
docker start compose_jenkins-master-service_1
