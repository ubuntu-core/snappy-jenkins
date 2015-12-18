#!/bin/bash
OPENSTACK_CREDENTIALS_PATH=$1
SPI_CREDENTIALS_PATH=$2

get_secret_object(){
    local NAME=$1
    local DATA=$2
    cat <<EOF
{
  "kind": "Secret",
  "apiVersion": "v1",
  "metadata": {
    "name": "$NAME"
  },
  "data": {
     $DATA
  }
}
EOF
}

get_data_from_path(){
    cat $1 | base64 | awk 'BEGIN{ORS="";} {print}'
}

OPENSTACK_CREDENTIALS_SECRET=$(get_secret_object novarc \
                                                 "\"novarc\": \"$(get_data_from_path $OPENSTACK_CREDENTIALS_PATH)\"")
SPI_CREDENTIALS_SECRET=$(get_secret_object spi.ini \
                                           "\"spi.ini\": \"$(get_data_from_path $SPI_CREDENTIALS_PATH)\"")
SSH_KEY_PATH=$(mktemp -d)
ssh-keygen -q -t rsa -N '' -f $SSH_KEY_PATH/id_rsa
SSH_KEY_SECRET=$(get_secret_object ssh-key \
                                   "\"id-rsa\": \"$(get_data_from_path $SSH_KEY_PATH/id_rsa)\", \
                                    \"id-rsa.pub\": \"$(get_data_from_path $SSH_KEY_PATH/id_rsa.pub)\"")
rm -rf $SSH_KEY_PATH

kubectl delete secret novarc
kubectl delete secret spi.ini
kubectl delete secret ssh-key
echo $OPENSTACK_CREDENTIALS_SECRET | kubectl create -f -
echo $SPI_CREDENTIALS_SECRET | kubectl create -f -
echo $SSH_KEY_SECRET | kubectl create -f -
