#!/bin/sh
set -x

. $JENKINS_HOME/common.sh

install_docker(){
    # install latest version of docker according to https://docs.docker.com/engine/installation/ubuntulinux/
    sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo "deb https://apt.dockerproject.org/repo ubuntu-$DIST main" | sudo tee /etc/apt/sources.list.d/docker.list
    sudo apt-get update
    sudo apt-get purge -y lxc-docker
    sudo apt-get install -y linux-image-extra-$(uname -r) docker-engine
    sudo service docker start
    ps -p1 | grep systemd && init=systemd || init=upstart
    if [ "$init" = "systemd" ]; then
        sudo systemctl enable docker
    fi
}

setup_ssh(){
    mkdir -p $JENKINS_HOME/ssh-key && ssh-keygen -q -t rsa -N '' -f $JENKINS_HOME/ssh-key/id-rsa
}

install_docker

setup_ssh

create_containers
