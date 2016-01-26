#!/bin/sh
set -x

install_docker(){
    # install latest version of docker according to https://docs.docker.com/engine/installation/ubuntulinux/
    sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo "deb https://apt.dockerproject.org/repo ubuntu-$DIST main" | sudo tee /etc/apt/sources.list.d/docker.list
    sudo apt-get update
    sudo apt-get purge -y lxc-docker
    sudo apt-get install -y linux-image-extra-$(uname -r) docker-engine
    sudo service docker stop
    # make docker write to /mnt (where the cloud instances mount the additional disk) to prevent
    # devicemapper to fill the base disk
    sudo mv /var/lib/docker /mnt
    echo 'DOCKER_OPTS="-g /mnt/docker"' | sudo tee /etc/default/docker
    sudo service docker start
    ps -p1 | grep systemd && init=systemd || init=upstart
    if [ "$init" = "systemd" ]; then
        sudo systemctl enable docker
    fi
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
    sudo docker exec -t $container_name /home/jenkins-slave/postStart.sh
    sudo docker exec -t $container_name cp -R /var/jenkins_home/.openstack /home/jenkins-slave
}

purge_images(){
    # remove the images created with previous credentials, they won't be accessible
    sudo docker exec -t $JENKINS_CONTAINER_NAME 'source ~/.openstack/novarc && snappy-cloud-image -action purge'
}

. $JENKINS_HOME/common.sh
install_docker

setup_ssh

launch_container "$JENKINS_CONTAINER_NAME" "$JENKINS_CONTAINER_INIT_COMMAND"
launch_container "$PROXY_CONTAINER_NAME" "$PROXY_CONTAINER_INIT_COMMAND"

purge_images

create_slaves
