#!/bin/sh

NAME=snappy-jenkins
JENKINS_HOME=/home/ubuntu/jenkins
CONTAINER_NAME="fgimenez/$NAME"
CONTAINER_INIT_COMMAND="sudo docker run -p 8080:8080 -d -v $JENKINS_HOME:/var/jenkins_home --name $NAME -t $CONTAINER_NAME"

execute_remote_command(){
    ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP 'export JENKINS_HOME='"'$JENKINS_HOME'"'; export OS_USERNAME='"'$OS_USERNAME'"';export OS_REGION_NAME='"'$OS_REGION_NAME'"';export CONTAINER_NAME='"'$CONTAINER_NAME'"';export CONTAINER_INIT_COMMAND='"'$CONTAINER_INIT_COMMAND'"';export NAME='"'$NAME'"'; '"$@"''
}

wait_for_ssh(){
    retry=60
    while ! execute_remote_command true; do
        retry=$(( retry - 1 ))
        if [ $retry -le 0 ]; then
            echo "Timed out waiting for ssh. Aborting!"
            exit 1
        fi
        sleep 5
    done
}
