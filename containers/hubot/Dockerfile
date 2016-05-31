FROM node:latest

RUN npm install -g yo generator-hubot

ENV PORT 9090

RUN useradd -ms /bin/bash nodeuser
RUN mkdir /home/nodeuser/hubot && chown nodeuser:nodeuser /home/nodeuser/hubot
WORKDIR /home/nodeuser/hubot
USER nodeuser

RUN yo hubot --owner "Snappy Developers" --adapter "telegram" --name "snappy_bot" --description "Snappy m-o"
RUN npm install hubot-diagnostics hubot-help hubot-jenkins hubot-jenkins-notifier --save
ADD external-scripts.json /home/nodeuser/hubot/external-scripts.json

EXPOSE $PORT

CMD ["/home/nodeuser/hubot/bin/hubot", "-a", "telegram"]
