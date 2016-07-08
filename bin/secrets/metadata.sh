#!/bin/bash

get_slaves_ids(){
    echo "$(docker ps -f name='slave' --format '{{.ID}}' | tr '\n' ' ')"
}

master="jenkins_jenkins-master-service_1"
slaves=$(get_slaves_ids)
all_nodes="$master $slaves"

declare -A before_scripts_map after_scripts_map paths_map nodes_map

nodes_map["secret/jenkins/config/"]="$master"
paths_map["secret/jenkins/config/credentials.xml"]="/var/jenkins_home/credentials.xml"
paths_map["secret/jenkins/config/org.jenkinsci.plugins.ghprb.GhprbTrigger.xml"]="/var/jenkins_home/org.jenkinsci.plugins.ghprb.GhprbTrigger.xml"
paths_map["secret/jenkins/config/secret.key"]="/var/jenkins_home/secret.key"

nodes_map["secret/jenkins/config/secrets/"]="$master"
paths_map["secret/jenkins/config/secrets/master.key"]="/var/jenkins_home/secrets/master.key"
paths_map["secret/jenkins/config/secrets/hudson.util.Secret"]="/var/jenkins_home/secrets/hudson.util.Secret"
paths_map["secret/jenkins/config/users/admin/config.xml"]="/var/jenkins_home/users/admin/config.xml"

nodes_map["secret/jenkins/tests/gpg/"]="$slaves"
paths_map["secret/jenkins/tests/gpg/password"]="/home/jenkins-slave/.gnupg/snappy-m-o-password"
paths_map["secret/jenkins/tests/gpg/private.key"]="/home/jenkins-slave/.gnupg/snappy-m-o-private.key"
before_scripts_map["secret/jenkins/tests/gpg/"]="rm -rf /home/jenkins-slave/.gnupg && mkdir -p /home/jenkins-slave/.gnupg"
after_scripts_map["secret/jenkins/tests/gpg/"]="chown -R jenkins-slave:jenkins-slave /home/jenkins-slave/.gnupg && su - jenkins-slave -c 'gpg --import /home/jenkins-slave/.gnupg/snappy-m-o-private.key'"

nodes_map["secret/jenkins/tests/openstack/"]="$slaves"
# credentials for region lcy01
paths_map["secret/jenkins/tests/openstack/novarc-lcy01"]="/home/jenkins-slave/.openstack/novarc-lcy01"
# credentials for region bos01
paths_map["secret/jenkins/tests/openstack/novarc-bos01"]="/home/jenkins-slave/.openstack/novarc-bos01"
# credentials for region lgw01
paths_map["secret/jenkins/tests/openstack/novarc-lgw01"]="/home/jenkins-slave/.openstack/novarc-lgw01"
before_scripts_map["secret/jenkins/tests/openstack/"]="rm -rf /home/jenkins-slave/.openstack && mkdir -p /home/jenkins-slave/.openstack"
after_scripts_map["secret/jenkins/tests/openstack/"]="chown -R jenkins-slave:jenkins-slave /home/jenkins-slave/.openstack"

nodes_map["secret/jenkins/tests/spi/"]="$slaves"
paths_map["secret/jenkins/tests/spi/spi.ini"]="/home/jenkins-slave/spi.ini"
after_scripts_map["secret/jenkins/tests/spi/"]="chown jenkins-slave:jenkins-slave /home/jenkins-slave/spi.ini"

nodes_map["secret/jenkins/tests/ssh/"]="$slaves"
paths_map["secret/jenkins/tests/ssh/id_rsa"]="/home/jenkins-slave/.ssh/id_rsa"
after_scripts_map["secret/jenkins/tests/ssh/"]="chmod 0600 /home/jenkins-slave/.ssh/id_rsa && ssh-keygen -y -f /home/jenkins-slave/.ssh/id_rsa > /home/jenkins-slave/.ssh/id_rsa.pub && chown -R jenkins-slave:jenkins-slave /home/jenkins-slave/.ssh"

nodes_map["secret/jenkins/tests/practitest/"]="$slaves"
paths_map["secret/jenkins/tests/practitest/config.ini"]="/home/jenkins-slave/.practitest/config.ini"
before_scripts_map["secret/jenkins/tests/practitest/"]="rm -rf /home/jenkins-slave/.practitest && mkdir -p /home/jenkins-slave/.practitest"
after_scripts_map["secret/jenkins/tests/practitest/"]="chown -R jenkins-slave:jenkins-slave /home/jenkins-slave/.practitest"

nodes_map["secret/jenkins/tests/snapcraft/"]="$slaves"
paths_map["secret/jenkins/tests/snapcraft/snapcraft.cfg"]="/home/jenkins-slave/.config/snapcraft/snapcraft.cfg"
before_scripts_map["secret/jenkins/tests/snapcraft/"]="rm -rf /home/jenkins-slave/.config/snapcraft && mkdir -p /home/jenkins-slave/.config/snapcraft/"
after_scripts_map["secret/jenkins/tests/snapcraft/"]="chown -R jenkins-slave:jenkins-slave /home/jenkins-slave/.config/snapcraft"
