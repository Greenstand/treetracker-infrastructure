FROM nginx:1.15.10

COPY nginx-web-map.conf /etc/nginx/nginx.conf
COPY client/ /var/www
