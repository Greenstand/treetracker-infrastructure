FROM node:8.12-slim

ENV DIR /opt/map-api-server
RUN mkdir -p $DIR

COPY server/ $DIR/server

WORKDIR $DIR
RUN npm install supervisor -g
RUN npm install

ENTRYPOINT supervisor server.js
