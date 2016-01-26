FROM fgimenez/jenkins-swarm-slave-ubuntu:vivid

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
