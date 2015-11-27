#!/bin/bash

set -x

if [ -z "$1" ]
then
    echo "No instance IP given, exiting"
    exit 1
fi

INSTANCE_IP=$1

. ./bin/common.sh
. ./bin/cloud-common.sh

send_and_execute(){
    scp ./bin/remote/redeploy.sh ubuntu@$INSTANCE_IP:$JENKINS_HOME
    execute_remote_command ". $JENKINS_HOME/redeploy.sh"
}

send_and_execute
