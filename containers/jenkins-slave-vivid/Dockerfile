FROM fgimenez/jenkins-swarm-slave-ubuntu:vivid

USER root

# install ppas
RUN apt-get update && apt-get install -qy \
  python-software-properties \
  software-properties-common
RUN add-apt-repository -y ppa:snappy-dev/tools-proposed
RUN add-apt-repository -y ppa:fgimenez/snappy-cloud-image

# install dependencies
RUN apt-get update && apt-get install -qy \
  build-essential \
  sudo subunit \
  snappy-cloud-image ubuntu-core-security-utils \
  ca-certificates squashfs-tools && \
  rm -rf /var/lib/apt/lists/*

# make jenkins-slave sudoer
RUN echo "jenkins-slave ALL=NOPASSWD: ALL" >> /etc/sudoers

# ssh config
RUN mkdir -p /home/jenkins-slave/.ssh
COPY config/ssh /home/jenkins-slave/.ssh/config

# postStart script
COPY config/scripts/postStart.sh /home/jenkins-slave/postStart.sh
