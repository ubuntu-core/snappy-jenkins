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
    sudo docker exec -t $container_name /home/jenkins-slave/postStart.sh
    sudo docker exec -t $container_name cp -R /var/jenkins_home/.openstack /home/jenkins-slave
}

purge_images(){
    # remove the images created with previous credentials, they won't be accessible
    sudo docker exec -t $JENKINS_CONTAINER_NAME 'source ~/.openstack/novarc && snappy-cloud-image -action purge'
}

get_slave_name(){
    local count=$1
    echo "$SLAVE_BASE_NAME-$count"
}

get_slave_init_command(){
    local name=$1
    echo "sudo docker run -d -v $JENKINS_HOME:/var/jenkins_home --link $NAME:jenkins --privileged=true --name $name $JENKINS_SLAVE_CONTAINER_NAME -username admin -password snappy -executors 2"
}


install_docker

setup_ssh

launch_container "$JENKINS_CONTAINER_NAME" "$JENKINS_CONTAINER_INIT_COMMAND"
launch_container "$PROXY_CONTAINER_NAME" "$PROXY_CONTAINER_INIT_COMMAND"

for count in 1 2 3 4
do
    name=$(get_slave_name $count)
    init_command=$(get_slave_init_command $name)
    launch_container "$JENKINS_SLAVE_CONTAINER_NAME" "$init_command"
    post_start_actions "$name"
done

purge_images
