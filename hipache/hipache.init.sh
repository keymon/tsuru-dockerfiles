#!/bin/sh

### BEGIN INIT INFO
# Provides:   hipache
# Required-Start:    $local_fs $remote_fs $network $syslog $named
# Required-Stop:     $local_fs $remote_fs $network $syslog $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the hipache web server
# Description:       starts hipache using start-stop-daemon
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
NAME=hipache
DESC=hipache
PID=/var/run/hipache.pid
NODEJS=$(command -v nodejs || command -v node)

if [ -x /usr/bin/hipache ]; then
    DAEMON=/usr/bin/hipache
elif [ -x /usr/local/bin/hipache ]; then
    DAEMON=/usr/local/bin/hipache
else
    exit 0
fi

# Include hipache defaults if available
if [ -r /etc/default/hipache ]; then
    . /etc/default/hipache
fi

. /lib/init/vars.sh
. /lib/lsb/init-functions

# Check if the ULIMIT is set in /etc/default/hipache
if [ -n "$ULIMIT" ]; then
    # Set the ulimits
    ulimit $ULIMIT
fi


#
# Configures hipache from the environment variables
#
do_config()
{
        mkdir -p /var/log/hipache
        REDIS_HOST=$(echo ${REDIS_PORT##tcp://} | cut -f 1 -d :)
        REDIS_PORT=$(echo ${REDIS_PORT##tcp://} | cut -f 2 -d :)
        cat <<EOF > /etc/hipache.conf
{
    "server": {
        "debug": true,
        "accessLog": "/var/log/hipache/access.log",
        "address": ["0.0.0.0"],
        "address6": [],
        "port": 8080,
        "workers": 5,
        "maxSockets": 100,
        "deadBackendTTL": 30,
        "tcpTimeout": 5,
        "retryOnError": 0,
        "deadBackendOn500": true,
        "httpKeepAlive": false
    },
    "redisHost": "$REDIS_HOST",
    "redisPort": "$REDIS_PORT"
}
EOF
}


#
# Function that starts the daemon/service
#
do_start()
{
	do_config
    # Return
    #   0 if daemon has been started
    #   1 if daemon was already running
    #   2 if daemon could not be started
    start-stop-daemon --start --quiet --pidfile $PID --make-pidfile \
        --exec $NODEJS --test || return 1
    start-stop-daemon --start --quiet --pidfile $PID --make-pidfile \
        --exec $DAEMON -- $DAEMON_OPTS || return 2
}

#
# Function that stops the daemon/service
#
do_stop()
{
    # Return
    #   0 if daemon has been stopped
    #   1 if daemon was already stopped
    #   2 if daemon could not be stopped
    #   other if a failure occurred
    start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PID --make-pidfile
    RETVAL="$?"

    sleep 1
    return "$RETVAL"
}

case "$1" in
    start)
        [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
        do_start
        case "$?" in
            0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
            2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
        esac
        ;;
    stop)
        [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
        do_stop
        case "$?" in
            0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
            2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
        esac
        ;;
    restart)
        log_daemon_msg "Restarting $DESC" "$NAME"

        do_stop
        case "$?" in
            0|1)
                do_start
                case "$?" in
                    0) log_end_msg 0 ;;
                    1) log_end_msg 1 ;; # Old process is still running
                    *) log_end_msg 1 ;; # Failed to start
                esac
                ;;
            *)
                # Failed to stop
                log_end_msg 1
                ;;
        esac
        ;;
    *)
        echo "Usage: $NAME {start|stop|restart}" >&2
        exit 3
        ;;
esac

:
