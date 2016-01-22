#!/bin/sh
ORIGIN_DIR=/var/jenkins_home
TARGET_DIR=/home/jenkins-slave
cp $ORIGIN_DIR/ssh-key/id-rsa $TARGET_DIR/.ssh/id_rsa
cp $ORIGIN_DIR/ssh-key/id-rsa.pub $TARGET_DIR/.ssh/id_rsa.pub

# Patch ubuntu-device-flash to generate all-snaps images.
wget https://people.canonical.com/~mvo/all-snaps/ubuntu-device-flash
chmod +x ubuntu-device-flash
mv ubuntu-device-flash /usr/bin/ubuntu-device-flash
