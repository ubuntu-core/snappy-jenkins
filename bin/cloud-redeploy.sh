#!/bin/bash

set -x

. ./bin/common.sh
. ./bin/cloud-common.sh

eval $(docker-machine env "$NAME_REMOTE")
docker-compose -f ./config/compose/cluster.yml down
docker-compose -f ./config/compose/cluster.yml pull
docker-compose -f ./config/compose/cluster.yml up -d
