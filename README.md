# Snappy Jenkins Docker container

This Docker file creates a container with a jenkins instance with jobs for executing the Snappy integration tests suite [1] in cloud instances. The testing jenkins jobs use use the binary from this project [2] for launching the tests, it takes care of determining the most recent image for a given channel and release (see below for the required name patterns), instantiating an instance of that image and getting its ip, executing the integration suite in the instance and shutting it down when finished or in case of errors.

You can use this container locally or in a cloud instance, there are provision script for either case (see below). In order to use the container properly you need to have set up an openstack environment, with at least the $OS_USERNAME and $OS_REGION variables set. There's also some required packages:

    $ sudo apt-get install cloud-utils python-novaclient

## Provision

There are two provision scripts. Both assume that you have openstack credentials loaded, for instance having sourced a novarc file.

local-provision.sh creates the container locally and shares jenkins home in /tmp/jenkins. Once it finish the app should be accesible from http://localhost:8080.

cloud-provision.sh uses the credentials of the current user to set up a cloud instance that will host the jenkins container.

Both scripts require as a parameter the path to the directory where the openstack credentials are stored. This credentials are used by jenkins to spin up the instances where the tests are run. In the case of cloud provision you can use different credentials for launching the jenkins host (this would be the credentials loaded for the user executing the script) and for jenkins to use while executing the snappy tests.

They can be executed like this:

    $ ./cloud-provision.sh ~/.openstack

## Required images

In order to spin up the jenkins host an image with a name of the form "wily-daily-amd64" should be accessible for the current user. For the jobs to be able to run your openstack user should be able to access snappy images with a name of the form "*rolling-snappy-core-amd64-edge*" for the rolling tests and "*1504-snappy-core-amd64-edge*" for the 1504 tests. The configuration can be changed with the release and channel switches in the respective jobs.

[1] https://launchpad.net/snappy
[2] https://launchpad.net/snappy-tests-job
