#!/bin/sh

export NAME=snappy-jenkins
export SECGROUP=$NAME
export JENKINS_HOME="/var/jenkins_home"

get_base_image_name(){
    local DIST=$1
    echo "snappy-qa-$DIST"
}

create_security_group() {
    local SECGROUP=$1
    openstack security group delete $SECGROUP
    openstack security group create --description "snappy-jenkins secgroup" $SECGROUP
    # ports 22, 8080 and 2376 only accessible from the vpn, port 8081
    # (jenkins reverse proxy) open to all
    openstack security group rule create --proto tcp --dst-port 22 --src-ip 10.0.0.0/8 $SECGROUP
    openstack security group rule create --proto tcp --dst-port 8080 --src-ip 10.0.0.0/8 $SECGROUP
    # 2376 is the port used by the docker daemon to server the REST API in ssl mode
    # https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml?search=docker
    openstack security group rule create --proto tcp --dst-port 2376 --src-ip 10.0.0.0/8 $SECGROUP
    openstack security group rule create --proto tcp --dst-port 8081 --src-ip 0.0.0.0/0 $SECGROUP
}

safe_restart(){
    local env=$1

    . ./bin/secrets/common.sh

    machine_name=$(vault_machine_name "$env")

    setup_vault_addr "$machine_name"

    token=$(vault read -field=value "secret/jenkins/config/admin_token")
    master_ip=$(docker-machine ip "snappy-jenkins-${env}")

    echo "Restarting Jenkins after all the current jobs have finished..."
    curl -u admin:"$token" -X POST "http://${master_ip}:8080/safeRestart" --data token="$token"
}
