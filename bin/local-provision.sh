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

OPENSTACK_CREDENTIALS_PATH=$1
SPI_CREDENTIALS_PATH=$2
JENKINS_HOME=/tmp/jenkins
CONTAINER_NAME=fgimenez/snappy-jenkins

# instance provision: create JENKINS_HOME
sudo rm -rf $JENKINS_HOME && mkdir -p $JENKINS_HOME && chmod a+w $JENKINS_HOME

# instance provision: copy canonistack credentials
cp -r $OPENSTACK_CREDENTIALS_PATH $JENKINS_HOME

# instance provision: setup ssh
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

# instance provision: copy the spi credentials
if [ ! -z "$SPI_CREDENTIALS_PATH" ]
then
    cp $SPI_CREDENTIALS_PATH $JENKINS_HOME/.spi.ini
fi

# instance provision: launch container
sudo docker build --no-cache -t $CONTAINER_NAME .
sudo docker rm -f snappy-jenkins
sudo docker run -p 8080:8080 -d -v $JENKINS_HOME:/var/jenkins_home --name snappy-jenkins -t $CONTAINER_NAME
