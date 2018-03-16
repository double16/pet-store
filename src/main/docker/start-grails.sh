#!/bin/sh

JMX_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=127.0.0.1 -Dcom.sun.management.jmxremote.port=5000"

DEBUG_OPTS="-Xdebug -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n"

#OPTS="${JMX_OPTS}"
[ "${DEBUG:-0}" -gt 0 ] && OPTS="${OPTS} ${DEBUG_OPTS}"

EXECUTABLE="$(find /app -name '*.war' | head -n 1)"

if [ -z "${EXECUTABLE}" ]; then
    echo "Could not find WAR file in /app" >&2
    exit 1
fi

exec java -server ${OPTS} \
    -Dgrails.env=${GRAILS_ENV:-production} -Dgrails.server.port=8080 \
    -jar ${EXECUTABLE}
