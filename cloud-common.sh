#!/bin/sh

JENKINS_HOME=/home/ubuntu/jenkins
NAME=snappy-jenkins

execute_remote_command(){
    ssh ubuntu@$INSTANCE_IP "$@"
}
