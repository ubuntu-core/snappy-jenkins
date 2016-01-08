#!/bin/sh
set -x

install_docker(){
    sudo apt-get install -y docker.io
}

setup_ssh(){
    mkdir -p $JENKINS_HOME/ssh-key && ssh-keygen -q -t rsa -N '' -f $JENKINS_HOME/ssh-key/id-rsa
}

launch_container(){
    CONTAINER_NAME=$1
    CONTAINER_INIT_COMMAND=$2
    sudo docker pull $CONTAINER_NAME
    eval $CONTAINER_INIT_COMMAND
}

post_start_actions(){
    local container_name=$1
    sudo docker exec -t $container_name /var/jenkins_home/postStart.sh
}

purge_images(){
    # remove the images created with previous credentials, they won't be accessible
    sudo docker exec -t $JENKINS_CONTAINER_NAME 'source ~/.openstack/novarc && snappy-cloud-image -action purge'
}

install_docker

setup_ssh

launch_container "$JENKINS_CONTAINER_NAME" "$JENKINS_CONTAINER_INIT_COMMAND"
launch_container "$PROXY_CONTAINER_NAME" "$PROXY_CONTAINER_INIT_COMMAND"

post_start_actions "$NAME"

purge_images
