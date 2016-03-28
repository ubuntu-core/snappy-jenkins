FROM ubuntu:wily

RUN useradd -d "/var/jenkins_home" -u 1000 -m -s /bin/bash jenkins

RUN mkdir -p /var/jenkins_home
RUN chown -R jenkins:jenkins /var/jenkins_home
VOLUME ["/var/jenkins_home"]

USER jenkins

CMD ["echo", "Data container for Jenkins"]
