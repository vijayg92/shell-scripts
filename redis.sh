#!/bin/bash

# Source function library.
. /etc/rc.d/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

# Check that networking is up.
[ "${NETWORKING}" = "no" ] && exit 0

# Define Redis binary as per project requirment
redis="/appl/solr/redis-stable/src/redis-server"
prog=$(basename $redis)

### Define configuration file as per project requirment
REDIS_CONF_FILE="/appl/redis/${instance}/conf/redis.conf"
PIDFILE="/var/run/redis/${instance}.pid"

[ -f /appl/redis/${instance}/conf/redis.conf ]

lockfile=/var/lock/subsys/${instance}

start() {
    [ -x $redis ] || exit 5
    [ -f $REDIS_CONF_FILE ] || exit 6
    echo -n $"Starting $prog: "
    daemon --pidfile=$PIDFILE $redis $REDIS_CONF_FILE
    retval=$?
    echo
    [ $retval -eq 0 ] && touch $lockfile
    return $retval
}

stop() {
    echo -n $"Stopping $prog: "
    killproc -p $PIDFILE $prog -QUIT
    retval=$?
    echo
    [ $retval -eq 0 ] && rm -f $lockfile $PIDFILE
    return $retval
}

restart() {
    stop
    start
}

reload() {
    echo -n $"Reloading $prog: "
    killproc -p $PIDFILE $redis -HUP
    RETVAL=$?
    echo
}

force_reload() {
    restart
}

rh_status() {
    status -p $PIDFILE $redis
}

rh_status_q() {
    rh_status >/dev/null 2>&1
}
usage() {
  echo $"Usage: $0 {start|stop|status|restart|condrestart|try-restart|reload|force-reload} {master|slave1|slave2}"
  }
case "$1" in
    start)
        instance=$2
        rh_status_q && exit 0
        $1
        ;;
    stop)
        #rh_status_q || exit 0
        instance=$2
        $1
        ;;
    restart|configtest)
        instance=$2
        $1
        ;;
    reload)
        instance=$2
        rh_status_q || exit 7
        $1
        ;;
    force-reload)
        instance=$2
        force_reload
        ;;
    status)
        instance=$2
        rh_status
        ;;
    condrestart|try-restart)
        instance=$2
        rh_status_q || exit 0
	    ;;
    *)
        usage
        exit 2
esac
