FROM fgimenez/jenkins-swarm-slave-ubuntu:xenial

USER root

# ubuntu-device-flash uses parts of snappy that try to reload udev rules when
# processing oem snaps, which this is not needed at build time; udev is not
# not available in the container, making a symlink solves the dependency without
# affecting the build process
RUN ln -s /bin/true /usr/local/bin/udevadm

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
  ca-certificates squashfs-tools grub-common \
  # snapcraft dependencies
  bzr dpkg-dev git mercurial pyflakes python3.4 \
  python3-apt python3-docopt python3-coverage \
  python3-fixtures python3-jsonschema python3-mccabe \
  python3-pep8 python3-pip python3-requests \
  python3-testscenarios python3-testtools python3-yaml \
  python3-lxml squashfs-tools && \
  rm -rf /var/lib/apt/lists/*

# make jenkins-slave sudoer
RUN echo "jenkins-slave ALL=NOPASSWD: ALL" >> /etc/sudoers

# ssh config
RUN mkdir -p /home/jenkins-slave/.ssh
COPY config/ssh /home/jenkins-slave/.ssh/config
RUN sed -i 's@ssh-key/id-rsa@.ssh/id_rsa@' ~/.ssh/config

# postStart script
COPY config/scripts/postStart.sh /home/jenkins-slave/postStart.sh
