FROM node:8.12-slim

ENV DIR /opt/server/
RUN mkdir -p $DIR

COPY lib/ $DIR/lib
COPY package*.json index.js $DIR

WORKDIR $DIR
RUN npm install

ENTRYPOINT node index.js
