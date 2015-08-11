#!/bin/bash

set -x

if [ -z "$1" ]
then
    echo "No instance IP given, exiting"
    exit 1
fi

INSTANCE_IP=$1
BACKUP_FOLDER="/home/ubuntu/jenkins_backup"

. ./bin/cloud-common.sh

send_and_execute(){
    scp ./bin/remote/redeploy.sh ubuntu@$INSTANCE_IP:/home/ubuntu
    execute_remote_command ". /home/ubuntu/redeploy.sh"
}

send_and_execute
