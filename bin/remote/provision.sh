#!/bin/sh
set -x

install_docker(){
    sudo apt-get install -y docker.io
}

setup_ssh(){
    mkdir -p $JENKINS_HOME/.ssh && ssh-keygen -q -t rsa -N '' -f $JENKINS_HOME/.ssh/id_rsa

    cat <<EOT >> $JENKINS_HOME/.ssh/config
Host 10.55.32.* 10.55.33.* 10.55.34.* 10.55.35.* 10.55.36.* 10.55.37.* 10.55.38.* 10.55.39.* 10.55.40.* 10.55.41.* 10.55.42.* 10.55.43.* 10.55.44.* 10.55.45.* 10.55.46.* 10.55.47.* 10.55.60.* 10.55.61.* *.canonistack 10.42.56.*
    User ubuntu
    ProxyCommand None
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
EOT
}

launch_container(){
    CONTAINER_NAME=$1
    CONTAINER_INIT_COMMAND=$2
    sudo docker pull $CONTAINER_NAME
    eval $CONTAINER_INIT_COMMAND
}

purge_images(){
    # remove the images created with previous credentials, they won't be accessible
    sudo docker exec -t $JENKINS_CONTAINER_NAME 'source ~/.openstack/novarc && snappy-cloud-image -action purge'
}

install_docker

setup_ssh

launch_container "$DATA_CONTAINER_NAME" "$DATA_CONTAINER_INIT_COMMAND"
launch_container "$JENKINS_CONTAINER_NAME" "$JENKINS_CONTAINER_INIT_COMMAND"
launch_container "$PROXY_CONTAINER_NAME" "$PROXY_CONTAINER_INIT_COMMAND"

purge_images
