FROM node:0.10.39-slim

RUN apt-get update
RUN apt-get install -y python build-essential

RUN npm i -g gulp@3.8.8
RUN npm i -g forever nodemon

WORKDIR /usr/src/app

ADD package.json /usr/src/app/

RUN npm install

ADD . /usr/src/app/

RUN gulp

CMD ["npm", "start"]
