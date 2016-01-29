#!/bin/sh
ORIGIN_DIR=/var/jenkins_home
TARGET_DIR=/home/jenkins-slave
cp $ORIGIN_DIR/ssh-key/id-rsa $TARGET_DIR/.ssh/id_rsa
cp $ORIGIN_DIR/ssh-key/id-rsa.pub $TARGET_DIR/.ssh/id_rsa.pub
