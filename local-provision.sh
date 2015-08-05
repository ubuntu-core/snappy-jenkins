#!/bin/sh
set -x
if [ -z "$1" ]
then
    echo "No Openstack credentials path given as first argument, exiting"
    exit 1
fi

OPENSTACK_CREDENTIALS_PATH=$1
JENKINS_HOME=/tmp/jenkins

# instance provision: create JENKINS_HOME
rm -rf $JENKINS_HOME && mkdir -p $JENKINS_HOME && chmod a+w $JENKINS_HOME

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

# instance provision: launch container
sudo docker pull fgimenez/snappy-jenkins
sudo docker run -p 8080:8080 -v $JENKINS_HOME:/var/jenkins_home -t fgimenez/snappy-jenkins > /dev/null 2>&1 &
