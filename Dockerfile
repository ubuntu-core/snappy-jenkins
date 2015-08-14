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
  jenkins-launchpad-plugin \
  snappy-tests-job && \
  rm -rf /var/lib/apt/lists/*

# copy scripts
COPY scripts/authentication.groovy \
  scripts/jobs.groovy \
  /usr/share/jenkins/ref/init.groovy.d/

USER jenkins

# install plugins
COPY plugins/active.txt /usr/share/jenkins/ref/
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/active.txt

# copy job definitions
RUN mkdir /usr/share/jenkins/ref/job-definitions
COPY jobs/daily-1504.xml \
  jobs/daily-rolling.xml \
  jobs/generic-update_mp.xml \
  jobs/snappy-1504-ci.xml \
  jobs/snappy-rolling-ci.xml \
  jobs/trigger-snappy-1504-ci.xml \
  jobs/trigger-snappy-rolling-ci.xml \
  /usr/share/jenkins/ref/job-definitions/

# copy jenkins-launchpad-plugin config
RUN mkdir /usr/share/jenkins/ref/.jlp
COPY jlp.config /usr/share/jenkins/ref/.jlp/
