#!/bin/bash

set -x

if [ -z "$1" ]
then
    echo "No instance IP given, exiting"
    exit 1
fi

. ./cloud-common.sh

INSTANCE_IP=$1
BACKUP_FOLDER="/home/ubuntu/jenkins_backup"

stop_service(){
    execute_remote_command "sudo systemctl stop snappy-jenkins"
}

remove_backup(){
    execute_remote_command "rm -rf $BACKUP_FOLDER"
}

create_backup(){
    execute_remote_command "cp -r $JENKINS_HOME $BACKUP_FOLDER"
}

erase_jenkins_home(){
    execute_remote_command "rm -rf $JENKINS_HOME/*"
}

copy_credentials(){
    CREDENTIALS[0]=".canonistack"
    CREDENTIALS[1]=".ssh"
    CREDENTIALS[2]=".launchpad.credentials"
    for i in "${CREDENTIALS[@]}"
    do
        execute_remote_command "cp -r $BACKUP_FOLDER/$i $JENKINS_HOME"
    done
}

pull_container(){
    execute_remote_command "sudo docker pull $CONTAINER_NAME"
}

start_service(){
    execute_remote_command "sudo systemctl start snappy-jenkins"
}


stop_service

remove_backup

create_backup

erase_jenkins_home

copy_credentials

pull_container

start_service
