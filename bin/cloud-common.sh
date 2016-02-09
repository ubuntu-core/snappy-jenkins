#!/bin/sh

export NAME_REMOTE="$NAME-remote"
export NAME_REMOTE_SEED="${NAME_REMOTE}-seed"
export JENKINS_HOME=/home/ubuntu/jenkins
export FLAVOR=cpu8-ram10-disk100-ephemeral20
export KEYPAIR_NAME=${OS_USERNAME}_${OS_REGION_NAME}
export DEFAULT_PRIVATE_KEY_PATH="${HOME}/.canonistack/${OS_USERNAME}_${OS_REGION_NAME}.key"
export COMPOSE_HTTP_TIMEOUT=180
