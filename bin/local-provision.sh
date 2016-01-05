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

JENKINS_HOME=/tmp/jenkins

. ./bin/common.sh

OPENSTACK_CREDENTIALS_PATH=$1
SPI_CREDENTIALS_PATH=$2

# instance provision: create JENKINS_HOME
sudo rm -rf $JENKINS_HOME && mkdir -p $JENKINS_HOME && chmod a+w $JENKINS_HOME

# instance provision: copy canonistack credentials
cp -r $OPENSTACK_CREDENTIALS_PATH $JENKINS_HOME

# instance provision: setup ssh
mkdir -p $JENKINS_HOME/ssh-key && ssh-keygen -q -t rsa -N '' -f $JENKINS_HOME/ssh-key/id-rsa

# instance provision: copy the spi credentials
if [ ! -z "$SPI_CREDENTIALS_PATH" ]
then
    cp $SPI_CREDENTIALS_PATH $JENKINS_HOME/.spi.ini
fi

# instance provision: launch container
sudo docker build --no-cache -t $JENKINS_CONTAINER_NAME $JENKINS_MASTER_CONTAINER_DIR
sudo docker build --no-cache -t $PROXY_CONTAINER_NAME $PROXY_CONTAINER_DIR
sudo docker stop $NAME $PROXY_NAME
sudo docker rm -f $NAME $PROXY_NAME
eval $JENKINS_CONTAINER_INIT_COMMAND
eval $PROXY_CONTAINER_INIT_COMMAND
