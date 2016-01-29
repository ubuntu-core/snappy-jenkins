#!/bin/sh
JENKINS_HOME=/home/ubuntu/jenkins

execute_remote_command(){
    ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP 'export JENKINS_HOME='"'$JENKINS_HOME'"'; \
export OS_USERNAME='"'$OS_USERNAME'"'; \
export OS_REGION_NAME='"'$OS_REGION_NAME'"'; \
export JENKINS_CONTAINER_NAME='"'$JENKINS_CONTAINER_NAME'"'; \
export JENKINS_CONTAINER_INIT_COMMAND='"'$JENKINS_CONTAINER_INIT_COMMAND'"'; \
export NAME='"'$NAME'"'; \
export SLAVE_BASE_NAME='"'$SLAVE_BASE_NAME'"'; \
export JENKINS_SLAVE_CONTAINER_NAME='"'$JENKINS_SLAVE_CONTAINER_NAME'"'; \
export PROXY_CONTAINER_NAME='"'$PROXY_CONTAINER_NAME'"'; \
export PROXY_CONTAINER_INIT_COMMAND='"'$PROXY_CONTAINER_INIT_COMMAND'"'; '"$@"''
}

wait_for_ssh(){
    retry=60
    while ! execute_remote_command true; do
        retry=$(( retry - 1 ))
        if [ $retry -le 0 ]; then
            echo "Timed out waiting for ssh. Aborting!"
            exit 1
        fi
        sleep 10
    done
}
