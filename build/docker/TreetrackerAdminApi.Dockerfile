FROM node:8.12-slim

ENV DIR /opt/server/
RUN mkdir -p $DIR

COPY server/ $DIR/server
COPY common/ $DIR/common
COPY package*.json $DIR

WORKDIR $DIR
RUN npm install

ENTRYPOINT while true; do sleep 2; date; done
