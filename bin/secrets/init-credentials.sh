#!/bin/bash
set -x

. ./bin/secrets/common.sh

basedir=$(mktemp -d)
environment=${1:-remote}

init_ssh_keys(){
    local dir="$basedir"/ssh
    mkdir $dir

    vault read -field=value $TEST_SSH_KEY_SECRET_PATH > $dir/id_rsa
    chmod 0600 $dir/id_rsa
    ssh-keygen -y -f $dir/id_rsa > $dir/id_rsa.pub

    for slave in vivid-1 xenial-1 xenial-2 xenial-3
    do
        docker cp $dir/id_rsa jenkins_jenkins-slave-${slave}_1:/home/jenkins-slave/.ssh
        docker cp $dir/id_rsa.pub jenkins_jenkins-slave-${slave}_1:/home/jenkins-slave/.ssh
        docker exec -u root -t jenkins_jenkins-slave-${slave}_1 bash -c "chown -R jenkins-slave:jenkins-slave /home/jenkins-slave/.ssh"
    done
}

init_openstack_credentials(){
    local dir="$basedir"/.openstack
    mkdir $dir

    vault read -field=value $TEST_OPENSTACK_CREDENTIALS_SECRET_PATH > $dir/novarc

    for slave in vivid-1 xenial-1 xenial-2 xenial-3
    do
        docker exec -u root -t jenkins_jenkins-slave-${slave}_1 bash -c "rm -rf /home/jenkins-slave/.openstack && mkdir -p /home/jenkins-slave/.openstack"
        docker cp $dir/novarc jenkins_jenkins-slave-${slave}_1:/home/jenkins-slave/.openstack/novarc
        docker exec -u root -t jenkins_jenkins-slave-${slave}_1 bash -c "chown jenkins-slave:jenkins-slave /home/jenkins-slave/.openstack/novarc"
    done
}

init_jenkins_credentials(){
    local dir="$basedir"/jenkins-credentials
    mkdir -p $dir/secrets

    for file in org.jenkinsci.plugins.ghprb.GhprbTrigger.xml credentials.xml secret.key secrets/master.key
    do
        vault read -field=value $TEST_JENKINS_CONFIG_SECRET_PATH/$file > $dir/$file
        docker cp $dir/$file jenkins_jenkins-master-service_1:/var/jenkins_home/$file
    done
}

init_spi_credentials(){
    vault read -field=value $TEST_SPI_CREDENTIALS_PATH > $basedir/spi.ini
    for slave in vivid-1 xenial-1 xenial-2 xenial-3
    do
        docker cp $basedir/spi.ini jenkins_jenkins-slave-${slave}_1:/home/jenkins-slave/spi.ini
        docker exec -u root -t jenkins_jenkins-slave-${slave}_1 bash -c "chown -R jenkins-slave:jenkins-slave /home/jenkins-slave/spi.ini"
    done
}

init_credentials(){
    echo "Access to Vault is required for retrieving secrets"

    eval $(docker-machine env "snappy-jenkins-${environment}")

    init_ssh_keys
    init_openstack_credentials
    init_spi_credentials

    target_ip=$(docker-machine ip "snappy-jenkins-${environment}")
    docker stop jenkins_jenkins-master-service_1
    init_jenkins_credentials
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$target_ip \
        sync
    docker start jenkins_jenkins-master-service_1
}

export VAULT_ADDR=http://$(docker-machine ip "vault-$environment-${OS_USERNAME}-${OS_REGION_NAME}"):8200

init_credentials

rm -rf $basedir
