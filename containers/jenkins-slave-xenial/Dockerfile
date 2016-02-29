FROM ubuntucore/jenkins-swarm-slave-ubuntu:xenial

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
RUN apt-get update && apt-get install --no-install-recommends -qy \
  build-essential \
  ca-certificates \
  grub-common \
  python-junitxml \
  sudo subunit \
  snappy-cloud-image \
  snappy-tests-job \
  squashfs-tools  \
  ubuntu-core-security-utils \
  openssh-client \
  # snapcraft dependencies
  bzr dpkg-dev git mercurial pyflakes \
  python3-apt python3-docopt python3-coverage \
  python3-fixtures python3-jsonschema python3-mccabe \
  python3-pep8 python3-petname python3-pip python3-requests \
  python3-testscenarios python3-testtools python3-yaml \
  python3-lxml && rm -rf /var/lib/apt/lists/*

# make jenkins-slave sudoer
RUN echo "jenkins-slave ALL=NOPASSWD: ALL" >> /etc/sudoers

# ssh config
RUN mkdir -p /home/jenkins-slave/.ssh
COPY config/ssh /home/jenkins-slave/.ssh/config
RUN sed -i 's@ssh-key/id-rsa@.ssh/id_rsa@' /home/jenkins-slave/.ssh/config
RUN chown -R jenkins-slave:jenkins-slave /home/jenkins-slave/.ssh

# postStart script
COPY config/scripts/postStart.sh /home/jenkins-slave/postStart.sh

# Patch ubuntu-device-flash to generate all-snaps images.
RUN wget https://people.canonical.com/~mvo/all-snaps/ubuntu-device-flash && \
  chmod +x ubuntu-device-flash && \
  mv ubuntu-device-flash /usr/bin/ubuntu-device-flash
