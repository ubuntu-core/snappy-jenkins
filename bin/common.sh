#!/bin/sh

NAME=snappy-jenkins
PROXY_NAME=snappy-proxy
JENKINS_CONTAINER_NAME="fgimenez/$NAME"
JENKINS_CONTAINER_INIT_COMMAND="sudo docker run -p 8080:8080 -d -v $JENKINS_HOME:/var/jenkins_home --privileged=true --restart always --name $NAME -t $JENKINS_CONTAINER_NAME"
JENKINS_MASTER_CONTAINER_DIR="./containers/jenkins-master"

PROXY_CONTAINER_NAME="fgimenez/snappy-jenkins-proxy"
PROXY_CONTAINER_INIT_COMMAND="sudo docker run -d -p 8081:80 --link $NAME:$NAME --restart always -v /var/run/docker.sock:/tmp/docker.sock:ro --name $PROXY_NAME $PROXY_CONTAINER_NAME"
PROXY_CONTAINER_DIR="./containers/jenkins-proxy"

PROXY_CONTAINER_NAME="fgimenez/snappy-jenkins-proxy"
PROXY_CONTAINER_INIT_COMMAND="sudo docker run -d -p 8081:80 --link $NAME:$NAME --restart always -v /var/run/docker.sock:/tmp/docker.sock:ro --name $PROXY_NAME $PROXY_CONTAINER_NAME"
PROXY_CONTAINER_DIR="./containers/jenkins-proxy"

JENKINS_MASTER_CONTAINER_DIR="./containers/jenkins-master"
