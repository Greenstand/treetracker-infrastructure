FROM node:8.12-slim

ENV DIR /opt/server/
RUN mkdir -p $DIR

COPY package*.json server.js $DIR

WORKDIR $DIR
RUN npm install

ENTRYPOINT node server.js
