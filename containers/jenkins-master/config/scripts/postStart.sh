#!/bin/sh
BASE=/var/jenkins_home
cp $BASE/ssh-key/id-rsa $BASE/.ssh/id_rsa
cp $BASE/ssh-key/id-rsa.pub $BASE/.ssh/id_rsa.pub
