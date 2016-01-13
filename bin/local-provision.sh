#!/bin/sh
set -x
if [ -z "$1" ]
then
    echo "No Openstack credentials path given as first argument, exiting"
    exit 1
fi
if [ -z "$2" ]
then
    echo "No snappy product integration credentials path given as second argument, won't be able to connect to SPI"
fi

get_slave_name(){
    local count=$1
    echo "$SLAVE_BASE_NAME-$count"
}
get_slave_init_command(){
    local name=$1
    echo "sudo docker run -d -v $JENKINS_HOME:/var/jenkins_home --link $NAME:jenkins --privileged=true --name $name $JENKINS_SLAVE_CONTAINER_NAME -username admin -password snappy -executors 2"
}

JENKINS_HOME=/tmp/jenkins

. ./bin/common.sh

OPENSTACK_CREDENTIALS_PATH=$1
SPI_CREDENTIALS_PATH=$2

# instance provision: create JENKINS_HOME
sudo rm -rf $JENKINS_HOME && mkdir -p $JENKINS_HOME && chmod a+w $JENKINS_HOME

# instance provision: copy openstack credentials
mkdir -p $JENKINS_HOME/.openstack && cp -r $OPENSTACK_CREDENTIALS_PATH $JENKINS_HOME/.openstack

# instance provision: setup ssh
mkdir -p $JENKINS_HOME/ssh-key && ssh-keygen -q -t rsa -N '' -f $JENKINS_HOME/ssh-key/id-rsa

# instance provision: copy the spi credentials
if [ ! -z "$SPI_CREDENTIALS_PATH" ]
then
    cp $SPI_CREDENTIALS_PATH $JENKINS_HOME/.spi.ini
fi

# instance provision: launch container
sudo docker build -t $JENKINS_CONTAINER_NAME $JENKINS_MASTER_CONTAINER_DIR
sudo docker build -t $PROXY_CONTAINER_NAME $PROXY_CONTAINER_DIR
sudo docker build -t $JENKINS_SLAVE_CONTAINER_NAME $JENKINS_SLAVE_CONTAINER_DIR

sudo docker stop $NAME $PROXY_NAME $SLAVE_BASE_NAME
sudo docker rm -f $NAME $PROXY_NAME $SLAVE_BASE_NAME
eval $JENKINS_CONTAINER_INIT_COMMAND
eval $PROXY_CONTAINER_INIT_COMMAND

for count in 1 2 3 4
do
    SLAVE_NAME=$(get_slave_name $count)
    sudo docker stop $SLAVE_NAME
    sudo docker rm -f $SLAVE_NAME

    init_command=$(get_slave_init_command $SLAVE_NAME)
    eval $init_command

    sudo docker exec -t $SLAVE_NAME /home/jenkins-slave/postStart.sh
    sudo docker exec -t $SLAVE_NAME cp -R /var/jenkins_home/.openstack /home/jenkins-slave
done
