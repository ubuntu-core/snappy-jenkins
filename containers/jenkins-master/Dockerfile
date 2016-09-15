FROM ubuntucore/jenkins-ubuntu

USER jenkins

# copy scripts
COPY scripts/authentication.groovy \
  scripts/jobs.groovy \
  scripts/executors.groovy \
  /usr/share/jenkins/ref/init.groovy.d/

# install plugins
COPY plugins/active.txt /usr/share/jenkins/ref/
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/active.txt

# copy job definitions
RUN mkdir /usr/share/jenkins/ref/job-definitions

COPY config/jobs/provision-cloud-server/config.xml \
   /usr/share/jenkins/ref/job-definitions/provision-cloud-server.xml

COPY config/jobs/github-snapcraft-autopkgtest-cloud/config.xml \
  /usr/share/jenkins/ref/job-definitions/github-snapcraft-autopkgtest-cloud.xml
COPY config/jobs/github-snapcraft-examples-tests-cloud/config.xml \
  /usr/share/jenkins/ref/job-definitions/github-snapcraft-examples-tests-cloud.xml

COPY config/jobs/scalingstack-cleanup/config.xml \
  /usr/share/jenkins/ref/job-definitions/scalingstack-cleanup.xml

COPY config/jobs/cleanup-cloud-image/config.xml \
  /usr/share/jenkins/ref/job-definitions/cleanup-cloud-image.xml

# ghprb plugin config
COPY config/ghprb/org.jenkinsci.plugins.ghprb.GhprbTrigger.xml \
  /usr/share/jenkins/ref/org.jenkinsci.plugins.ghprb.GhprbTrigger.xml
