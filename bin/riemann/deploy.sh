#!/bin/sh

set -x

. ./bin/cloud-common.sh

machine_name=$(swarm_master_name)

eval $(docker-machine env --swarm "$machine_name")

docker-compose -f ./config/riemann/cluster.yml pull

docker-compose -f ./config/riemann/cluster.yml up -d

docker-compose -f ./config/riemann/cluster.yml scale riemannhealth=5
