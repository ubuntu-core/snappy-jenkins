#!/bin/sh
set -x

if [ -z "$1" ]
then
    echo "Source IP provided, exiting"
    exit 1
fi
if [ -z "$2" ]
then
    echo "Target IP provided, exiting"
    exit 1
fi

SOURCE_IP="$1"
TARGET_IP="$2"

. ./bin/cloud-common.sh

sync_ssh_keys(){
    dir=`mktemp -d`

    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$SOURCE_IP:$JENKINS_HOME/ssh-key/* $dir
    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $dir/* ubuntu@$TARGET_IP:$JENKINS_HOME/ssh-key

    for slave in vivid-1 xenial-1 xenial-2 xenial-3
    do
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$TARGET_IP \
            sudo docker exec -t jenkins-slave-$slave bash -c "cp /var/jenkins_home/ssh-key/id_rsa* /home/jenkins-slave/.ssh"
    done

    rm -rf $dir
}

sync_job_history(){
    basedir=`mktemp -d`
    dir="$basedir"/jobs
    mkdir $dir

    rsync -avzL $SOURCE_IP:$JENKINS_HOME/jobs/* $dir
    rsync -avz $dir $TARGET_IP:$JENKINS_HOME

    rm -rv $dir
}

sync_ssh_keys
sync_job_history
