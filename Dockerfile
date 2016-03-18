FROM node:5.7-slim

RUN apt-get update
RUN apt-get install -y python build-essential

RUN npm i -g gulp@3.9.1
RUN npm i -g forever nodemon

WORKDIR /usr/src/app

ADD package.json /usr/src/app/

RUN npm install

ADD . /usr/src/app/

RUN mkdir -p /usr/src/app/cache/

RUN gulp

CMD ["npm", "start"]
