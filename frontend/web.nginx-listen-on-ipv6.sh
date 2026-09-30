#!/bin/sh
# Listens on IPv6 as well when the host has it (see web.nginx.conf).
#
# Run by the nginx image's entrypoint, like the stock
# 10-listen-on-ipv6-by-default.sh, which does this for the image's own
# default.conf and leaves a replaced one alone.
set -eu

conf=/etc/nginx/conf.d/default.conf

if [ ! -f /proc/net/if_inet6 ]; then
    echo "$0: info: IPv6 is not available on this host; listening on IPv4 only"
    exit 0
fi

# Like the stock script: a root file system mounted read-only (as Kubernetes'
# readOnlyRootFilesystem does) is no reason not to start, only to stay on IPv4.
# sed -i writes a new file next to the config, so that is what is tried.
if ! touch "$conf.writable" 2>/dev/null; then
    echo "$0: info: $conf is not writable; listening on IPv4 only"
    exit 0
fi
rm -f "$conf.writable"

sed -i 's/^\(\s*\)#ipv6 /\1/' "$conf"
echo "$0: info: listening on IPv6 as well in $conf"
