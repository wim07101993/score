# The web build is done by the workflow, not here: building Flutter inside the
# image would mean shipping the whole SDK to fetch it. This packages what
# `flutter build web` already produced, so `build/web` must exist in the
# context before this is built.
FROM nginx:1.29-otel AS package

COPY frontend/web.nginx.conf /etc/nginx/conf.d/default.conf
COPY frontend/build/web/ /usr/share/nginx/html/
