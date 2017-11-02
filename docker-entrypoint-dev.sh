#!/bin/sh
set -e

# run default entrypoint
#/usr/local/bin/docker-php-entrypoint

# cleanup old pid file if bind-mounting source locally
[ -f ./tmp/pids/server.pid ] && rm ./tmp/pids/server.pid

# pass execution to the CMD value
exec "$@"
