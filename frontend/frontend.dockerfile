FROM nginx:1.29-otel
AS package
WORKDIR /frontend/src

COPY / /usr/share/nginx/html/
