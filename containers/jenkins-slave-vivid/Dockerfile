FROM ubuntucore/jenkins-swarm-slave-ubuntu:vivid

USER root

# install ppas
RUN apt-get update && apt-get install --no-install-recommends -qy \
  python-software-properties \
  software-properties-common && rm -rf /var/lib/apt/lists/*
RUN add-apt-repository -y ppa:snappy-dev/tools-proposed

# install dependencies
RUN echo "deb http://archive.ubuntu.com/ubuntu/ vivid-backports main restricted" >> /etc/apt/sources.list && \
  apt-get update && apt-get install -qy --no-install-recommends \
  autopkgtest/vivid-backports \
  build-essential \
  ca-certificates \
  python-junitxml \
  snappy-cloud-image \
  snappy-tests-job \
  squashfs-tools \
  openssh-client \
  sudo \
  subunit \
  ubuntu-core-security-utils && \
  rm -rf /var/lib/apt/lists/*

# make jenkins-slave sudoer
RUN echo "jenkins-slave ALL=NOPASSWD: ALL" >> /etc/sudoers

# ssh config
RUN mkdir -p /home/jenkins-slave/.ssh
COPY config/ssh /home/jenkins-slave/.ssh/config
RUN chown -R jenkins-slave:jenkins-slave /home/jenkins-slave/.ssh
