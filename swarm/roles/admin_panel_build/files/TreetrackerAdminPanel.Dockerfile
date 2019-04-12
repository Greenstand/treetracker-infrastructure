FROM nginx:1.15.10

ENV DIR /var/www/

RUN mkdir -p $DIR
COPY client/build $DIR
COPY nginx.conf /etc/nginx/nginx.conf
