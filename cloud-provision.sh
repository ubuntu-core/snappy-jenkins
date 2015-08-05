#!/bin/sh
set -x
if [ -z "$1" ]
then
    echo "No Openstack credentials path given as first argument, exiting"
    exit 1
fi

OPENSTACK_CREDENTIALS_PATH=$1
JENKINS_HOME=/home/ubuntu/jenkins
CONTAINER_NAME=fgimenez/snappy-jenkins
CONTAINER_INIT_COMMAND="sudo docker run -p 8080:8080 -v $JENKINS_HOME:/var/jenkins_home -t $CONTAINER_NAME > /dev/null 2>&1 &"
NAME=snappy-jenkins
SECGROUP=$NAME
FLAVOR=m1.large

execute_remote_command(){
    ssh ubuntu@$INSTANCE_IP "$@"
}

create_security_group() {
    nova secgroup-delete $SECGROUP
    nova secgroup-create $SECGROUP "snappy-jenkins secgroup"
    nova secgroup-add-rule $SECGROUP tcp 22 22 0.0.0.0/0
    nova secgroup-add-rule $SECGROUP tcp 8080 8080 0.0.0.0/0
}

launch_instance(){
    IMAGE_ID=$(nova image-list | grep wily-daily-amd64 | head -1 | awk '{print $4}')

    INSTANCE_ID=$(nova boot --key-name ${OS_USERNAME}_${OS_REGION_NAME} --security-groups $SECGROUP --flavor $FLAVOR --image $IMAGE_ID $NAME --poll | grep '| id ' | awk '{print $4}')
    INSTANCE_IP=$(nova show $INSTANCE_ID | grep 'canonistack network' | awk '{print $5}')
}

remote_install_docker(){
    execute_remote_command "sudo apt-get install -y docker.io"
}

remote_setup_init_script(){
    execute_remote_command "sudo chmod a+w /etc/rc.local && sudo echo $CONTAINER_INIT_COMMAND >> /etc/rc.local && sudo chmod 0700 /etc/rc.local"
}

remote_setup_jenkins_home() {
    execute_remote_command "rm -rf $JENKINS_HOME && mkdir -p $JENKINS_HOME && chmod a+w $JENKINS_HOME"
}

remote_copy_openstack_credentials() {
    scp -r $OPENSTACK_CREDENTIALS_PATH ubuntu@$INSTANCE_IP:$JENKINS_HOME
}

remote_setup_ssh(){
    execute_remote_command "mkdir -p $JENKINS_HOME/.ssh && ssh-keygen -q -t rsa -N '' -f $JENKINS_HOME/.ssh/id_rsa"

    execute_remote_command "cat <<EOT >> $JENKINS_HOME/.ssh/config
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
EOT"
}

remote_launch_container(){
    execute_remote_command "sudo docker pull $CONTAINER_NAME"
    execute_remote_command $CONTAINER_INIT_COMMAND
}

create_security_group

launch_instance

echo "Waiting for instance to settle..."
sleep 120

remote_install_docker

remote_setup_init_script

remote_setup_jenkins_home

remote_copy_openstack_credentials

remote_setup_ssh

remote_launch_container

exit 0
