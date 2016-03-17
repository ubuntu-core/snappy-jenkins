#!/bin/sh

export TEST_SSH_KEY_SECRET_PATH=secret/jenkins/tests/ssh/id_rsa
export TEST_OPENSTACK_CREDENTIALS_SECRET_PATH=secret/jenkins/tests/openstack/novarc
export TEST_JENKINS_CONFIG_SECRET_PATH=secret/jenkins/config
export TEST_SPI_CREDENTIALS_PATH=secret/jenkins/tests/spi
export TEST_BOT_GPG_PRIVATE_KEY_PATH=secret/jenkins/tests/gpg/private.key
export TEST_BOT_GPG_PASSWORD=secret/jenkins/tests/gpg/password

setup_vault(){
    machine_name=$1
    deploy_env=$2

    # vault client should be installed locally!
    export VAULT_ADDR=http://$(docker-machine ip "$machine_name"):8200
    echo "Waiting for the vault server to settle"
    sleep 10

    echo "Keep the following keys and root token in a safe place! They are unique for this deployment and will be saved in a vault-${deploy_env}.txt file in the current directory"
    init_output=$(vault init)
    echo "The keys will be used next to unseal the server"
    for index in $(seq 3); do
        key=$(echo "$init_output" | grep "Key ${index}:" | awk '{ print $3 }')
        vault unseal "$key"
    done
    echo "The root token will be used for authorizing the client"
    root_token=$(echo "$init_output" | grep "Initial Root Token:" | awk '{ print $4 }')
    echo "Waiting for the vault server to settle"
    sleep 3
    vault auth "$root_token"

    vault write $TEST_SSH_KEY_SECRET_PATH value=@"$SLAVE_SSH_PRIVATE_KEY_PATH"
    vault write $TEST_OPENSTACK_CREDENTIALS_SECRET_PATH value=@"$SLAVE_OPENSTACK_CREDENTIALS_PATH"
    vault write $TEST_SPI_CREDENTIALS_PATH value=@"$SLAVE_SPI_CREDENTIALS_PATH"
    vault write $TEST_BOT_GPG_PRIVATE_KEY_PATH value=@"$SLAVE_BOT_GPG_PRIVATE_KEY_PATH"
    vault write $TEST_BOT_GPG_PASSWORD value="$SLAVE_BOT_GPG_PASSWORD"

    echo "$init_output" > "./vault-${deploy_env}.txt"
}
