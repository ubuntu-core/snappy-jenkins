FROM fgimenez/jenkins-ubuntu

USER root

# install ppas
RUN apt-get update && apt-get install -qy \
  python-software-properties \
  software-properties-common
RUN add-apt-repository -y ppa:snappy-dev/tools-proposed && \
  add-apt-repository -y ppa:fgimenez/jenkins-launchpad-plugin

# install dependencies
RUN apt-get update && apt-get install -qy \
  jenkins-launchpad-plugin \
  snappy-tests-job \
  python3-requests-oauthlib \
  sudo subunit && \
  rm -rf /var/lib/apt/lists/*

# make jenkins sudoer
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

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
COPY config/jobs/snappy-daily-1504-canonistack/config.xml \
  /usr/share/jenkins/ref/job-definitions/snappy-daily-1504-canonistack.xml
COPY config/jobs/snappy-daily-rolling-canonistack/config.xml \
  /usr/share/jenkins/ref/job-definitions/snappy-daily-rolling-canonistack.xml
COPY config/jobs/snappy-daily-rolling-bbb/config.xml \
  /usr/share/jenkins/ref/job-definitions/snappy-daily-rolling-bbb.xml
COPY config/jobs/generic-update_mp/config.xml \
  /usr/share/jenkins/ref/job-definitions/generic-update_mp.xml
COPY config/jobs/snappy-1504-ci-canonistack/config.xml \
  /usr/share/jenkins/ref/job-definitions/snappy-1504-ci-canonistack.xml
COPY config/jobs/snappy-rolling-ci-canonistack/config.xml \
  /usr/share/jenkins/ref/job-definitions/snappy-rolling-ci-canonistack.xml
COPY config/jobs/trigger-snappy-1504-ci/config.xml \
  /usr/share/jenkins/ref/job-definitions/trigger-snappy-1504-ci.xml
COPY config/jobs/trigger-snappy-rolling-ci/config.xml \
  /usr/share/jenkins/ref/job-definitions/trigger-snappy-rolling-ci.xml

# copy jenkins-launchpad-plugin config
RUN mkdir /usr/share/jenkins/ref/.jlp
COPY jlp.config /usr/share/jenkins/ref/.jlp/
