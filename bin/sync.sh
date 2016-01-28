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
basedir=`mktemp -d`

. ./bin/common.sh
. ./bin/cloud-common.sh

sync_ssh_keys(){
    local dir="$basedir"/ssh
    mkdir $dir

    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$SOURCE_IP:$JENKINS_HOME/ssh-key/* $dir
    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $dir/* ubuntu@$TARGET_IP:$JENKINS_HOME/ssh-key

    for slave in vivid-1 xenial-1 xenial-2 xenial-3
    do
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$TARGET_IP \
            sudo docker exec -t jenkins-slave-$slave bash -c \"cp /var/jenkins_home/ssh-key/id_rsa* /home/jenkins-slave/.ssh\"
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$TARGET_IP \
            sudo docker exec -t jenkins-slave-$slave bash -c \"chown jenkins-slave:jenkins-slave /home/jenkins-slave/.ssh/*\"
    done
}

sync_job_history(){
    local dir="$basedir"/jobs
    mkdir $dir

    rsync -avzL $SOURCE_IP:$JENKINS_HOME/jobs/* $dir
    rsync -avz $dir $TARGET_IP:$JENKINS_HOME
}

sync_jenkins_credentials(){
    local dir="$basedir"/jenkins-credentials
    mkdir -p $dir/secrets

    for file in org.jenkinsci.plugins.ghprb.GhprbTrigger.xml credentials.xml secret.key
    do
        scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$SOURCE_IP:$JENKINS_HOME/$file $dir
    done
    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$SOURCE_IP:$JENKINS_HOME/secrets/* $dir/secrets

    scp -r -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $dir/* ubuntu@$TARGET_IP:$JENKINS_HOME/
}

sync_ssh_keys

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$TARGET_IP \
    sudo docker stop $NAME

sync_job_history
sync_jenkins_credentials

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$TARGET_IP \
    sudo docker start $NAME
