FROM nginx:1.29-otel AS package

COPY /frontend/src/ /usr/share/nginx/html/
