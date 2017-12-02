#!/bin/bash
# Yolab 1.0.0 Init Script
#
# description: This is used to start stop sentry yolab..

#. /etc/init.d/functions
. /etc/rc.d/init.d/functions

#Default varilabls
prog="yolab"
progdir="/appl/yolab"
logdir="/logs/yolab"
logfile="/logs/yolab/yolab.log"
pidfile="/logs/yolab/yolab.pid"
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
# Check if requirements are met

if [ ! -d ${logdir} ]; then
      mkdir -p ${logdir}
fi

start() {
        if ps -p `cat $pidfile` > /dev/null 2>&1; then
              echo "Process ${prog} is already running (`cat ${pidfile}`). !!! \t${red}Started:::[FAILED]${reset}"
        else
              echo "Starting ${prog}:"
              cd ${progdir} ; ./${prog} > ${logfile} 2>&1 && rc=$?
              echo $! > ${pidfile}
              if [ ${rc} -eq 0 ]; then
                echo -e "Process ${prog} has been started. !!! \t${green}Started:::[OK]${reset}"
                exit ${rc}
              fi
        fi
}

stop() {
        if ps -p `cat ${pidfile}` > /dev/null 2>&1; then
           kill -9 `cat ${pidfile}`
           rc=$?
           if [ ${rc} -eq 0 ]; then
             echo -e "Process ${prog} has been stopped. !!! \t${green}Stopped:::[OK]${reset}"
             exit ${rc}
           fi
        else
           echo -e "Process ${prod} is not running. !!! \t${red}Stopped:::[FAILED]${reset}"
           exit ${rc}
        fi
}

status() {
        if ps -p `cat ${pidfile}` > /dev/null 2>&1; then
           echo -e "Process ${prog} is running PID:`cat ${pidfile}` !!! \t${green}Status:::[OK]${reset}"
           exit 0
        else
           echo -e "Process ${prod} is not running !!! \t${red}Status:::[FAILED]${reset}"
           exit 0
        fi
}
case "$1" in
    start)
        OPTION=start;
        start;
        ;;
  stop)
        OPTION=stop;
        stop;
        ;;
  status)
        OPTION=status;
        status;
        ;;
  restart)
        OPTION=restart;
        stop;
        start;
        ;;
  *)
        echo "${red}Usage: $prog {start|stop|status}${reset}"
        exit 1
esac

exit
