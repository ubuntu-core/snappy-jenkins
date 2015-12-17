#!/bin/bash
OPENSTACK_CREDENTIALS_PATH=$1
SPI_CREDENTIALS_PATH=$2

go get github.com/kelseyhightower/conf2kube

conf2kube -f $OPENSTACK_CREDENTIALS_PATH -n novarc | kubectl create -f -
conf2kube -f $SPI_CREDENTIALS_PATH -n spi.ini | kubectl create -f -
