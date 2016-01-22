#!/bin/sh

NAME=jenkins-master-service
PROXY_NAME=snappy-proxy
JENKINS_CONTAINER_NAME=fgimenez/snappy-jenkins
JENKINS_CONTAINER_INIT_COMMAND="sudo docker run -p 8080:8080 -d -v $JENKINS_HOME:/var/jenkins_home --restart always --name $NAME -t $JENKINS_CONTAINER_NAME"
JENKINS_MASTER_CONTAINER_DIR="./containers/jenkins-master"

PROXY_CONTAINER_NAME="fgimenez/snappy-jenkins-proxy"
PROXY_CONTAINER_INIT_COMMAND="sudo docker run -d -p 8081:80 --link $NAME:$NAME --restart always --name $PROXY_NAME $PROXY_CONTAINER_NAME"
PROXY_CONTAINER_DIR="./containers/jenkins-proxy"

SLAVE_BASE_NAME=jenkins-slave
JENKINS_SLAVE_CONTAINER_NAME=fgimenez/snappy-jenkins-slave
JENKINS_SLAVE_CONTAINER_DIR="./containers/jenkins-slave"

get_container_slave_name(){
    local distribution=$1
    echo "$JENKINS_SLAVE_CONTAINER_NAME-$distribution"
}
get_container_slave_dir(){
    local distribution=$1
    echo "$JENKINS_SLAVE_CONTAINER_DIR-$distribution"
}
get_slave_name(){
    local count=$1
    local distribution=$2
    echo "$SLAVE_BASE_NAME-$distribution-$count"
}
get_slave_init_command(){
    local name=$1
    local container_name=$2
    local distribution=$3
    echo "sudo docker run -d -v $JENKINS_HOME:/var/jenkins_home --link $NAME:jenkins --privileged=true --restart always --name $name $container_name -username admin -password snappy -executors 2 -name $name -labels $distribution"
}

create_slave(){
    local count=$1
    local distribution=$2
    local SLAVE_NAME=$(get_slave_name $count $distribution)
    sudo docker stop $SLAVE_NAME
    sudo docker rm -f $SLAVE_NAME

    local CONTAINER_SLAVE_NAME=$(get_container_slave_name $distribution)
    init_command=$(get_slave_init_command $SLAVE_NAME $CONTAINER_SLAVE_NAME $distribution)
    eval $init_command

    sudo docker exec -t $SLAVE_NAME /home/jenkins-slave/postStart.sh
    sudo docker exec -t $SLAVE_NAME cp -R /var/jenkins_home/.openstack /home/jenkins-slave
    sudo docker exec -t $SLAVE_NAME chmod -R a+r /home/jenkins-slave/.openstack
}

create_slaves(){
    for dist in xenial vivid
    do
        container_name=$(get_container_slave_name $dist)
        container_dir=$(get_container_slave_dir $dist)
        if [ -d $container_dir ]; then
            sudo docker build -t $container_name $container_dir
        fi
    done

    for count in 1 2 3
    do
        create_slave $count xenial
    done
    create_slave 1 vivid
}
