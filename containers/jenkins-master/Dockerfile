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

COPY config/jobs/snappy-daily-1504-openstack/config.xml \
  /usr/share/jenkins/ref/job-definitions/snappy-daily-1504-openstack.xml
COPY config/jobs/snappy-daily-rolling-openstack/config.xml \
  /usr/share/jenkins/ref/job-definitions/snappy-daily-rolling-openstack.xml
COPY config/jobs/snappy-daily-rolling-bbb/config.xml \
  /usr/share/jenkins/ref/job-definitions/snappy-daily-rolling-bbb.xml

COPY config/jobs/github-snappy-integration-tests-cloud/config.xml \
  /usr/share/jenkins/ref/job-definitions/github-snappy-integration-tests-cloud.xml

COPY config/jobs/github-snapcraft-autopkgtest-cloud/config.xml \
  /usr/share/jenkins/ref/job-definitions/github-snapcraft-autopkgtest-cloud.xml
COPY config/jobs/github-snapcraft-examples-tests-cloud/config.xml \
  /usr/share/jenkins/ref/job-definitions/github-snapcraft-examples-tests-cloud.xml

COPY config/jobs/cleanup-cloud-image/config.xml \
  /usr/share/jenkins/ref/job-definitions/cleanup-cloud-image.xml

COPY config/jobs/create-cloud-image-vivid/config.xml \
  /usr/share/jenkins/ref/job-definitions/create-cloud-image-vivid.xml
COPY config/jobs/create-cloud-image-all-snaps/config.xml \
  /usr/share/jenkins/ref/job-definitions/create-cloud-image-all-snaps.xml
COPY config/jobs/create-cloud-image-1504-alpha/config.xml \
  /usr/share/jenkins/ref/job-definitions/create-cloud-image-1504-alpha.xml
COPY config/jobs/create-cloud-image-1504-edge/config.xml \
  /usr/share/jenkins/ref/job-definitions/create-cloud-image-1504-edge.xml
COPY config/jobs/create-cloud-image-1504-stable/config.xml \
  /usr/share/jenkins/ref/job-definitions/create-cloud-image-1504-stable.xml
COPY config/jobs/create-cloud-image-rolling-edge/config.xml \
  /usr/share/jenkins/ref/job-definitions/create-cloud-image-rolling-edge.xml

COPY config/jobs/check-snap-from-store/config.xml \
  /usr/share/jenkins/ref/job-definitions/check-snap-from-store.xml

COPY config/jobs/delete-cloud-image/config.xml \
  /usr/share/jenkins/ref/job-definitions/delete-cloud-image.xml

# ghprb plugin config
COPY config/ghprb/org.jenkinsci.plugins.ghprb.GhprbTrigger.xml \
  /usr/share/jenkins/ref/org.jenkinsci.plugins.ghprb.GhprbTrigger.xml
