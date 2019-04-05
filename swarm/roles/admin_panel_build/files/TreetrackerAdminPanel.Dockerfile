FROM node:8.12-slim

ENV DIR /opt/admin-web
RUN mkdir -p ${DIR}/

WORKDIR $DIR

COPY client/ $DIR
RUN npm install

ENTRYPOINT npm start
