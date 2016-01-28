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
    sudo systemctl enable docker
}

setup_ssh(){
    mkdir -p $JENKINS_HOME/ssh-key && ssh-keygen -q -t rsa -N '' -f $JENKINS_HOME/ssh-key/id-rsa
}

pull_container(){
    CONTAINER_NAME=$1
    sudo docker pull $CONTAINER_NAME
}

. $JENKINS_HOME/common.sh
install_docker

setup_ssh

for container in "$JENKINS_CONTAINER_NAME" "$PROXY_CONTAINER_NAME"; do
    pull_container "$container"
done
