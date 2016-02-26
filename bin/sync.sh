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

    for slave in vivid-1 xenial-1 xenial-2 xenial-3
    do
        docker cp $dir/id_rsa compose_jenkins-slave-${slave}_1:/home/jenkins-slave/.ssh
        docker cp $dir/id_rsa.pub compose_jenkins-slave-${slave}_1:/home/jenkins-slave/.ssh
        docker exec -u root -t compose_jenkins-slave-${slave}_1 bash -c "chown -R jenkins-slave:jenkins-slave /home/jenkins-slave/.ssh"
    done
}

sync_openstack_credentials(){
    local dir="$basedir"/.openstack
    mkdir $dir

    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$SOURCE_IP:$JENKINS_HOME/.openstack/novarc $dir

    for slave in vivid-1 xenial-1 xenial-2 xenial-3
    do
        docker exec -u root -t compose_jenkins-slave-${slave}_1 bash -c "rm -rf /home/jenkins-slave/.openstack && mkdir -p /home/jenkins-slave/.openstack"
        docker cp $dir/novarc compose_jenkins-slave-${slave}_1:/home/jenkins-slave/.openstack/novarc
        docker exec -u root -t compose_jenkins-slave-${slave}_1 bash -c "chown jenkins-slave:jenkins-slave /home/jenkins-slave/.openstack/novarc"
    done
}

sync_job_history(){
    local dir="$basedir"/jobs
    mkdir $dir

    rsync -avzL -e "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" --exclude config.xml $SOURCE_IP:$JENKINS_HOME/jobs/* $dir
    rsync -avz -e "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" $dir $TARGET_IP:$JENKINS_HOME
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

eval $(docker-machine env snappy-jenkins-remote)

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$TARGET_IP sudo chmod -R a+w $JENKINS_HOME

sync_ssh_keys
sync_openstack_credentials

docker stop compose_jenkins-master-service_1

sync_job_history
sync_jenkins_credentials

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$TARGET_IP \
    sync

docker start compose_jenkins-master-service_1
