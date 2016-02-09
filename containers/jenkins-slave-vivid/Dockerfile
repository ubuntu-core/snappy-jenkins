FROM ubuntucore/jenkins-swarm-slave-ubuntu:vivid

USER root

# ubuntu-device-flash uses parts of snappy that try to reload udev rules when
# processing oem snaps, which this is not needed at build time; udev is not
# not available in the container, making a symlink solves the dependency without
# affecting the build process
RUN ln -s /bin/true /usr/local/bin/udevadm

# install ppas
RUN apt-get update && apt-get install --no-install-recommends -qy \
  python-software-properties \
  software-properties-common && rm -rf /var/lib/apt/lists/*
RUN add-apt-repository -y ppa:snappy-dev/tools-proposed

# install dependencies
RUN echo "deb http://archive.ubuntu.com/ubuntu/ vivid-backports main restricted" >> /etc/apt/sources.list && \
  apt-get update && apt-get install -qy --no-install-recommends \
  autopkgtest/vivid-backports \
  snappy-tests-job \
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
RUN sed -i 's@ssh-key/id-rsa@.ssh/id_rsa@' /home/jenkins-slave/.ssh/config
RUN chown -R jenkins-slave:jenkins-slave /home/jenkins-slave/.ssh

# postStart script
COPY config/scripts/postStart.sh /home/jenkins-slave/postStart.sh

# Patch ubuntu-device-flash to make it work on vivid.
RUN wget http://people.ubuntu.com/~elopio/snappy/vivid/ubuntu-device-flash && \
  chmod +x ubuntu-device-flash && \
  mv ubuntu-device-flash /usr/bin/ubuntu-device-flash
