#!/bin/sh

DIST="trusty"

NAME=jenkins-master-service
PROXY_NAME=snappy-proxy
JENKINS_CONTAINER_NAME=ubuntucore/snappy-jenkins-master
JENKINS_CONTAINER_INIT_COMMAND="sudo docker run -p 8080:8080 -d -v $JENKINS_HOME:/var/jenkins_home --restart always --name $NAME -t $JENKINS_CONTAINER_NAME"
JENKINS_MASTER_CONTAINER_DIR="./containers/jenkins-master"

PROXY_CONTAINER_NAME="ubuntucore/snappy-jenkins-proxy"
PROXY_CONTAINER_INIT_COMMAND="sudo docker run -d -p 8081:80 --link $NAME:$NAME --restart always --name $PROXY_NAME $PROXY_CONTAINER_NAME"
PROXY_CONTAINER_DIR="./containers/jenkins-proxy"

SLAVE_BASE_NAME=jenkins-slave
JENKINS_SLAVE_CONTAINER_NAME=ubuntucore/snappy-jenkins-slave
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

    post_start_actions $SLAVE_NAME
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

execute_remote_command(){
    local INSTANCE_IP=$1
    shift
    ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@"$INSTANCE_IP" 'export JENKINS_HOME='"'$JENKINS_HOME'"';
export OS_USERNAME='"'$OS_USERNAME'"';
export OS_REGION_NAME='"'$OS_REGION_NAME'"';
export JENKINS_CONTAINER_NAME='"'$JENKINS_CONTAINER_NAME'"';
export JENKINS_CONTAINER_INIT_COMMAND='"'$JENKINS_CONTAINER_INIT_COMMAND'"';
export NAME='"'$NAME'"';
export SLAVE_BASE_NAME='"'$SLAVE_BASE_NAME'"';
export JENKINS_SLAVE_CONTAINER_NAME='"'$JENKINS_SLAVE_CONTAINER_NAME'"';
export PROXY_CONTAINER_NAME='"'$PROXY_CONTAINER_NAME'"';
export PROXY_CONTAINER_INIT_COMMAND='"'$PROXY_CONTAINER_INIT_COMMAND'"'; '"$*"''
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

get_base_image_name(){
    local DIST=$1
    echo "snappy-qa-$DIST"
}

wait_for_ip(){
    local INSTANCE_ID=$1
    local retry=60
    local INSTANCE_IP=""
    INSTANCE_IP=$(openstack server show $INSTANCE_ID | grep 'addresses' | awk '{print $4}' | cut -d= -f2)
    # when the instance hasn't came up yet the addresses line reads:
    #   | addresses |            |
    # so print $4 would be '|', this value will be returned until we have an IP assigned
    while [ -z "$INSTANCE_IP" -o "$INSTANCE_IP" = "|" ]; do
        retry=$(( retry - 1 ))
        if [ $retry -le 0 ]; then
            echo "Timed out waiting for instance IP. Aborting!"
            exit 1
        fi
        sleep 20
        INSTANCE_IP=$(openstack server show $INSTANCE_ID | grep 'addresses' | awk '{print $4}' | cut -d= -f2)
    done
    echo "$INSTANCE_IP"
}

launch_instance(){
    local IMAGE_NAME=$1

    IMAGE_ID=$(openstack image list | grep "$IMAGE_NAME" | head -1 | awk '{print $4}')

    INSTANCE_ID=$(openstack server create --key-name ${OS_USERNAME}_${OS_REGION_NAME} --security-group $SECGROUP --flavor $FLAVOR --image $IMAGE_ID $NAME | grep '| id ' | awk '{print $4}')

    INSTANCE_IP=$(wait_for_ip "$INSTANCE_ID")
    echo "$INSTANCE_IP"
}

update_container(){
    local name="$2"
    local image="$3"

    sudo docker stop "$name"
    sudo docker pull "$image"
    sudo docker start "$name"
}

update_containers(){
    update_container "$NAME" "$JENKINS_CONTAINER_NAME"
    update_container "$PROXY_NAME" "$PROXY_CONTAINER_NAME"

    slave_name=$(get_slave_name 1 vivid)
    slave_container=$(get_container_slave_name vivid)
    update_container "$slave_name" "$slave_container"

    for index in 1 2 3
    do
        slave_name=$(get_slave_name $index xenial)
        slave_container=$(get_container_slave_name xenial)
        update_container "$slave_name" "$slave_container"
    done
}

post_start_actions(){
    local container_name=$1
    sudo docker exec -t $container_name /home/jenkins-slave/postStart.sh
    sudo docker exec -t $container_name cp -R /var/jenkins_home/.openstack /home/jenkins-slave
    sudo docker exec -t $container_name chmod -R a+r /home/jenkins-slave/.openstack
}

run_containers(){

}
