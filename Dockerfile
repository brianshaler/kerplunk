FROM node:4.4-slim

RUN apt-get update && \
  apt-get install -y python build-essential && \
  apt-get clean
  # UGHHHHHH

# RUN cd /usr/local/lib/node_modules/npm && \
#     npm install --save fs-extra && \
#     sed -i -e s/graceful-fs/fs-extra/ \
#       -e s/fs\.move/fs.rename/ \
#       ./lib/utils/rename.js

RUN npm i -g \
  forever \
  gulp@3.9.1 \
  nodemon

WORKDIR /usr/src/app

ADD package.json /usr/src/app/

RUN npm install

ADD . /usr/src/app/

RUN mkdir -p /usr/src/app/cache/ && \
  gulp

EXPOSE 80

CMD ["npm", "start"]
