#!/bin/bash
set -x

BACKUP_FOLDER="/home/ubuntu/jenkins_backup"

stop_service(){
    sudo systemctl stop snappy-jenkins
}

remove_backup(){
    rm -rf $BACKUP_FOLDER
}

create_backup(){
    cp -r $JENKINS_HOME $BACKUP_FOLDER
}

erase_jenkins_home(){
    rm -rf $JENKINS_HOME/*
}

copy_credentials(){
    CREDENTIALS[0]=".canonistack"
    CREDENTIALS[1]=".ssh"
    CREDENTIALS[2]=".launchpad.credentials"
    for i in "${CREDENTIALS[@]}"
    do
        cp -r $BACKUP_FOLDER/$i $JENKINS_HOME
    done
}

pull_container(){
    sudo docker pull $CONTAINER_NAME
}

start_service(){
    sudo systemctl start snappy-jenkins
}

stop_service

remove_backup

create_backup

erase_jenkins_home

copy_credentials

pull_container

start_service
