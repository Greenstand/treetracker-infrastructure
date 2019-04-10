FROM node:8.12-slim

ENV DIR /opt/build

RUN mkdir -p $DIR
COPY client/ $DIR

WORKDIR $DIR

RUN npm install \
  && npm run build

FROM nginx:1.15.10

ENV DIR /var/www/admin

RUN mkdir -p $DIR
COPY --from=0 /opt/build $DIR
