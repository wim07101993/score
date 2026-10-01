# The web build is done by the workflow, not here: building Flutter inside the
# image would mean shipping the whole SDK to fetch it. This packages what
# `flutter build web` and tool/precache.dart already produced, so `build/web`
# must exist in the context before this is built.
FROM nginx:1.29-otel AS package

COPY frontend/web.nginx.conf /etc/nginx/conf.d/default.conf
COPY --chmod=755 frontend/web.nginx-listen-on-ipv6.sh /docker-entrypoint.d/30-listen-on-ipv6-when-available.sh
COPY frontend/build/web/ /usr/share/nginx/html/
# A build that tool/precache.dart was not run on ships a service worker that
# keeps nothing, and at each device's next visit throws away the copy of the
# app it kept for gigs. Refused here rather than found out at one.
RUN if grep -q "^const VERSION = '';" /usr/share/nginx/html/service-worker.js; then \
      echo 'build/web was not run through tool/precache.dart' >&2; exit 1; \
    fi
