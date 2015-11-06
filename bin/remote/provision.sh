#!/bin/sh
set -x

install_docker(){
    sudo apt-get install -y docker.io
}

setup_service(){
    service=$1
    sudo cp /home/ubuntu/$service.service /lib/systemd/system/$service.service
    sudo systemctl daemon-reload
    sudo systemctl enable $service
}

setup_jenkins_home(){
    rm -rf $JENKINS_HOME && mkdir -p $JENKINS_HOME && chmod a+w $JENKINS_HOME
}

setup_ssh(){
    mkdir -p $JENKINS_HOME/.ssh && ssh-keygen -q -t rsa -N '' -f $JENKINS_HOME/.ssh/id_rsa

    cat <<EOT >> $JENKINS_HOME/.ssh/config
Host 10.55.32.* 10.55.33.* 10.55.34.* 10.55.35.* 10.55.36.* 10.55.37.* 10.55.38.* 10.55.39.* 10.55.40.* 10.55.41.* 10.55.42.* 10.55.43.* 10.55.44.* 10.55.45.* 10.55.46.* 10.55.47.* 10.55.60.* 10.55.61.* *.canonistack
    User ubuntu
    IdentityFile ~/.canonistack/${OS_USERNAME}_${OS_REGION_NAME}.key
    ProxyCommand None
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null

Host server-*
    User ubuntu
    IdentityFile ~/.canonistack/${OS_USERNAME}_${OS_REGION_NAME}.key
    ProxyCommand None
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null

Host *.cloudapp.net
    IdentityFile ~/.ssh/azure.key
EOT
}

launch_container(){
    sudo docker pull $JENKINS_CONTAINER_NAME
    $JENKINS_CONTAINER_INIT_COMMAND
}

install_docker

setup_service snappy-jenkins
setup_service snappy-proxy

setup_jenkins_home

setup_ssh

launch_container
