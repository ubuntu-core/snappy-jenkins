FROM fgimenez/jenkins-ubuntu

USER root

# install ppas
RUN apt-get update && apt-get install -qy \
  python-software-properties \
  software-properties-common
RUN add-apt-repository -y ppa:snappy-dev/tools-proposed
RUN add-apt-repository -y ppa:fgimenez/snappy-cloud-image

# install dependencies
RUN apt-get update && apt-get install -qy \
  snappy-tests-job \
  build-essential \
  sudo subunit \
  snappy-cloud-image ubuntu-core-security-utils \
  ca-certificates && \
  rm -rf /var/lib/apt/lists/*

# make jenkins sudoer
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

# ubuntu-device-flash uses parts of snappy that try to reload udev rules when
# processing oem snaps, which this is not needed at build time; udev is not
# not available in the container, making a symlink solves the dependency without
# affecting the build process
RUN ln -s /bin/true /usr/local/bin/udevadm

# copy scripts
COPY scripts/authentication.groovy \
  scripts/jobs.groovy \
  scripts/executors.groovy \
  /usr/share/jenkins/ref/init.groovy.d/

USER jenkins

# install plugins
COPY plugins/active.txt /usr/share/jenkins/ref/
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/active.txt

# copy job definitions
RUN mkdir /usr/share/jenkins/ref/job-definitions

COPY config/jobs/snappy-daily-1504-openstack/config.xml \
  /usr/share/jenkins/ref/job-definitions/snappy-daily-1504-openstack.xml
COPY config/jobs/snappy-daily-rolling-openstack/config.xml \
  /usr/share/jenkins/ref/job-definitions/snappy-daily-rolling-openstack.xml
COPY config/jobs/snappy-daily-rolling-bbb/config.xml \
  /usr/share/jenkins/ref/job-definitions/snappy-daily-rolling-bbb.xml

COPY config/jobs/github-snappy-integration-tests-cloud/config.xml \
  /usr/share/jenkins/ref/job-definitions/github-snappy-integration-tests-cloud.xml

COPY config/jobs/cleanup-cloud-image/config.xml \
  /usr/share/jenkins/ref/job-definitions/cleanup-cloud-image.xml

COPY config/jobs/create-cloud-image/config.xml \
  /usr/share/jenkins/ref/job-definitions/create-cloud-image.xml
COPY config/jobs/create-cloud-image-1504-alpha/config.xml \
  /usr/share/jenkins/ref/job-definitions/create-cloud-image-1504-alpha.xml
COPY config/jobs/create-cloud-image-1504-edge/config.xml \
  /usr/share/jenkins/ref/job-definitions/create-cloud-image-1504-edge.xml
COPY config/jobs/create-cloud-image-1504-stable/config.xml \
  /usr/share/jenkins/ref/job-definitions/create-cloud-image-1504-stable.xml
COPY config/jobs/create-cloud-image-rolling-edge/config.xml \
  /usr/share/jenkins/ref/job-definitions/create-cloud-image-rolling-edge.xml

COPY config/jobs/delete-cloud-image/config.xml \
  /usr/share/jenkins/ref/job-definitions/delete-cloud-image.xml

COPY config/jobs/snappy-cloud-test/config.xml \
  /usr/share/jenkins/ref/job-definitions/snappy-cloud-test.xml

# ghprb plugin config
COPY config/ghprb/org.jenkinsci.plugins.ghprb.GhprbTrigger.xml \
  /usr/share/jenkins/ref/org.jenkinsci.plugins.ghprb.GhprbTrigger.xml

# ssh config
RUN mkdir -p /usr/share/jenkins/ref/.ssh
COPY config/ssh /usr/share/jenkins/ref/.ssh/config

# postStart script
COPY config/scripts/postStart.sh /usr/share/jenkins/ref/postStart.sh
