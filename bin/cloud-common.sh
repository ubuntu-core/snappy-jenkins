#!/bin/sh

NAME=snappy-jenkins
JENKINS_HOME=/home/ubuntu/jenkins
JENKINS_CONTAINER_NAME="fgimenez/$NAME"
JENKINS_CONTAINER_INIT_COMMAND="sudo docker run -e VIRTUAL_HOST=jenkins.local -p 8080:8080 -d -v $JENKINS_HOME:/var/jenkins_home --name $NAME -t $JENKINS_CONTAINER_NAME"
PROXY_CONTAINER_NAME="jwilder/nginx-proxy"
PROXY_CONTAINER_INIT_COMMAND="sudo docker run -d -p 80:8081 -v /var/run/docker.sock:/tmp/docker.sock:ro $PROXY_CONTAINER_NAME"


execute_remote_command(){
    ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP 'export JENKINS_HOME='"'$JENKINS_HOME'"'; export OS_USERNAME='"'$OS_USERNAME'"';export OS_REGION_NAME='"'$OS_REGION_NAME'"';export JENKINS_CONTAINER_NAME='"'$JENKINS_CONTAINER_NAME'"';export JENKINS_CONTAINER_INIT_COMMAND='"'$JENKINS_CONTAINER_INIT_COMMAND'"';export NAME='"'$NAME'"';export PROXY_CONTAINER_NAME='"'$PROXY_CONTAINER_NAME'"'; export PROXY_CONTAINER_INIT_COMMAND='"'$PROXY_CONTAINER_INIT_COMMAND'"'; '"$@"''
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
