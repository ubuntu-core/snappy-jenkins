#!/bin/sh

JENKINS_HOME=/home/ubuntu/jenkins
CONTAINER_NAME=fgimenez/snappy-jenkins
NAME=snappy-jenkins

execute_remote_command(){
    ssh ubuntu@$INSTANCE_IP "$@"
}
