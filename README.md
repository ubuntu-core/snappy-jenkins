# Snappy Jenkins CI

This repo helps setting up the CI environment used for executing Snappy integration tests [1]. It contains Dockerfiles which define the required containers (Jenkins master and slaves and a Nginx proxy) and several shell scripts for bringing them to live both in a cloud provider (only OpenStack supported at the moment) and locally.

The testing jenkins jobs use the binary from this project [2] for launching the tests, it takes care of determining the most recent Snappy cloud image for a given channel and release (see below for the required name patterns), instantiating a cloud instance of that image and getting its ip, executing the integration suite in the instance and shutting it down when finished or in case of errors.

There are also jobs configured for accessing the Snappy Product Integration environment. This gives a lot more flexibility when executing the tests not being only limited to cloud instances, however you must provide credentials for this service.

## Provision

There are provision scripts for creating the CI environment locally and in the cloud. In both cases you need to have OpenStack credentials loaded, for example by sourcing a novarc file:

    $ source path/to/openstack/credentials/novarc

Before Executing the provision script you should have at least the ```$OS_USERNAME``` and ```$OS_REGION_NAME``` environment variables set.

### Local Provision

You can setup the enviroment locally by executing this command:

    $ ./bin/local-provision <cloud_credentials_path>

The ```<cloud_credentials_path>``` required by the command indicates a path to a novarc file with the OpenStack credentials that will be used by the Jenkins slave instances to spin up Snappy instances. The scripts copies it to the Jenkins container and the jobs use it to access to the cloud provider API.

Once the scripts finish you can access the jenkins master instance from the browser at ```http://localhost:8080```

### Cloud provision

There are additional requirements for the cloud provision besides having loaded OpenStack credentials. In this case the setup is done in a cloud instance and you should be able to spin it up. The needed packages can be installed in Ubuntu with:

    $ sudo apt-get install cloud-utils python-novaclient

To setup the CI instance in the cloud just execute:

    $ ./bin/cloud-provision.sh <cloud_credentials_path>

being, as in the local case, `<cloud_credentials_path>` the location of an OpeStack novarc file. This command creates a new VM with two containers in it, as described in this image:

![Block Diagram](/img/snappy-jenkins.png?raw=true)

* Reverse proxy instance: it has an Nginx process listening on port 8081 that forwards requests to path ```/ghprbhook``` to the jenkins master instance

* Jenkins master instance: the same as in the local provision case.

It also setups a security group that allows access to port 8081 from everywhere and ports 8080 and 22 from a local range (by default 10.0.0.0/8). All this configuration is done this way in order to facilitate a secure connection from the GitHub webhook, as detailed in the next section.

## GitHub integration

The Jenkins master container has the GitHub Pull Request Builder Plugin installed [3] to allow the triggering of jobs in response to events from GitHub. The default configuration in the container leaves almost all setup, there are only a few things left to do:

* First of all, you should assign a floating IP to your VM instance so that it can be reached from GitHub. The container infrastructure and security group assigned make it secure to expose it to the wild, as explained earlier.

* The ```github-snappy-integration-tests-cloud``` job is configured to receive payloads from GitHub in response to events. It points to the ubuntu-core/snappy repository, you can change this to access one of your own repos to try the hook.

* In the settings page of the repository configured in ```github-snappy-integration-tests-cloud``` you should setup the webhook to notify Jenkins of changes in the repository, the URL should be ```http://<floating_ip>:8081/ghprbhook/``` and the events to trigger the webhook "Pull Request" and "Issue Comment"

* In order to be able to respond to comments in the pull request and update the status of the tests once they are triggered you should setup a bot user to be managed by Jenkins (a regular user works too). This user should be added as a collaborator in the repo and its credentials must be added in the jenkins general configuration (Manage Jenkins -> Configure System -> GitHub Pull Request Builder -> GitHub Auth -> Credentials -> Add).

## Required images

With cloud provision, in order to spin up the jenkins host an image with a name of the form "wily-daily-amd64" should be accessible for the current user.

With both kinds of provision, for the jobs to be able to run your openstack user should be able to access snappy images with a name of the form ```ubuntu-core/custom/ubuntu-rolling-snappy-core-amd64-edge*``` for the rolling release tests and ```ubuntu-core/custom/ubuntu-1504-snappy-core-amd64-edge*``` for the 15.04 release tests. This kind of images can be created with the snappy-cloud-image tool [4]. The configuration can be changed with the release and channel switches in the respective jobs.

[1] https://github.com/ubuntu-core/snappy

[2] https://launchpad.net/snappy-tests-job

[3] https://wiki.jenkins-ci.org/display/JENKINS/GitHub+pull+request+builder+plugin

[4] https://github.com/ubuntu-core/snappy-cloud-image
