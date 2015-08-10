FROM fgimenez/jenkins-ubuntu

USER root

# install ppas
RUN apt-get update && apt-get install -qy \
  python-software-properties \
  software-properties-common
RUN add-apt-repository -y ppa:fgimenez/snappy-tests-job && \
  add-apt-repository -y ppa:fgimenez/jenkins-launchpad-plugin

# install dependencies
RUN apt-get update && apt-get install -qy \
  autopkgtest \
  bzr \
  cloud-utils \
  golang-check.v1-dev \
  golang-go \
  jenkins-launchpad-plugin \
  mercurial \
  python-novaclient \
  snappy-tests-job && \
  rm -rf /var/lib/apt/lists/*

# copy scripts
COPY scripts/*.groovy /usr/share/jenkins/ref/init.groovy.d/

USER jenkins

# install plugins
COPY plugins/active.txt /usr/share/jenkins/ref/
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/active.txt

# copy job definitions
RUN mkdir /usr/share/jenkins/ref/jobs
COPY jobs/* /usr/share/jenkins/ref/jobs/

# copy jenkins-launchpad-plugin config
RUN mkdir /usr/share/jenkins/ref/.jlp
COPY jlp.config /usr/share/jenkins/ref/.jlp/
