#!/bin/sh

NAME=snappy-jenkins
PROXY_NAME=snappy-proxy
DATA_NAME=snappy-jenkins-data

JENKINS_CONTAINER_NAME="fgimenez/$NAME"
JENKINS_CONTAINER_INIT_COMMAND="sudo docker run -p 8080:8080 -d -v $JENKINS_HOME:/var/jenkins_home --privileged=true --volumes-from=$DATA_NAME --restart always --name $NAME -t $JENKINS_CONTAINER_NAME"
JENKINS_MASTER_CONTAINER_DIR="./containers/jenkins-master"

PROXY_CONTAINER_NAME="nginx"
PROXY_CONTAINER_INIT_COMMAND="sudo docker run -d -p 8081:80 --link $NAME:$NAME --restart always -v $JENKINS_HOME/proxy.conf:/etc/nginx/conf.d/proxy.conf:ro -v /var/run/docker.sock:/tmp/docker.sock:ro --name $PROXY_NAME $PROXY_CONTAINER_NAME"

DATA_CONTAINER_NAME="fgimenez/$DATA_NAME"
DATA_CONTAINER_INIT_COMMAND="sudo docker run -v $JENKINS_HOME:/var/jenkins_home --name $DATA_NAME -t $DATA_CONTAINER_NAME"
DATA_CONTAINER_DIR="./containers/jenkins-data"

GHPRB_CONFIG_FILE="org.jenkinsci.plugins.ghprb.GhprbTrigger.xml"
