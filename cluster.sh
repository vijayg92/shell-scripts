#!/bin/bash
####################################
### Author:- Vijay Singh Gosai  ####
### Date:- 15-Jun-2015          ####
### Purpose:- Elasticsearch cluster#
####################################

setting_variables()
{
        es_root=/appl/elasitc
        es_bin=bin/elasticsearch
        es_name="ElasticSearch Instance"
        es_log=/logs/elastic
        pidfile=elasticsearch.pid
        es_ins=3
        if [ ! -d ${es_log} ]
        then
            mkdir ${es_log}
        fi
}

start() {
        check_ps=`netstat -ntlup | grep 930$ID`
        RETVAL=$?
        if [ $RETVAL -ne "0" ];then
            nohup /appl/elastic/node$ID/bin/elasticsearch  > $es_log/node$ID/startup.log 2>&1 &
            RETVAL=$?
            [ $RETVAL = 0 ] && echo -e "Elasticsearch Instance Node$ID Started:::[OK] !!!"
            echo $! > $es_log/node$ID/$pidfile
        else
           echo -e "Elasticsearch Instance Node$ID Already Running:::[FAILED] !!!"
           status
           return $RETVAL
                   #exit 1
        fi
}

stop() {
        pid=`netstat -ntlup | grep 930$ID | awk '{print $7}' | awk -F "/" '{print $1}'`
                if [ ! -z "${pid}" ]
                then
                        killps=`kill -9 $pid`
                        RETVAL=$?
                        [ $RETVAL = 0 ] && echo -e "Elasticsearch Instance Node$ID Stopped:::[OK] !!!"
                else
                        echo -e "Elasticsearch Instance Node$ID Already Running:::[OK] !!!"
                fi
                return $RETVAL
}

startall() {
                setting_variables
        for i in `seq $es_ins`;do
            check_ps=`netstat -ntlup | grep 930$i`
            RETVAL=$?
            if [ $RETVAL -ne "0" ]; then
                nohup /appl/elastic/node$i/bin/elasticsearch  > $es_log/node$i/startup.log 2>&1 &
                RETVAL=$?
                [ $RETVAL = 0 ] && echo -e "Elasticsearch Instance Node$i Started:::[OK] !!!"
                echo $! > $es_log/node$i/$pidfile
            else
                echo -e "Elasticsearch Instance Node$i Already Running:::[FAILED] !!!"
                return $RETVAL
            #exit 1
            fi
        done
}

stopall() {
        for i in `seq $es_ins`; do
        pid=`netstat -ntlup | grep 930$i | awk '{print $7}' | awk -F "/" '{print $1}'`
        if [ ! -z "${pid}" ];then
            killps=`kill -9 $pid`
            RETVAL=$?
            [ $RETVAL = 0 ] && echo -e "Elasticsearch Instance Node$i Stopped:::[OK] !!!"
        else
            echo -e "Elasticsearch Instance Node$i Already Running:::[OK] !!!"
        fi
        done
    return $RETVAL
}
status() {
        setting_variables
        for i in `seq $es_ins`;do
                pid=`netstat -ntlup | grep 930$i | awk '{print $7}' | awk -F "/" '{print $1}'`
        if [ ! -z "${pid}" ];then
            echo -e "Elasticsearch Instance Node$i PID:$pid Running:::[OK] !!!"
        else
            echo -e "Elasticsearch Instance Node$i Stopped:::[OK] !!!"
        fi
        done
}

case "$1" in
            start | stop)
            command="$1"
            ID="$2"

        if [[ "$1" == start ]] ; then
                        setting_variables
                        start $ID
            exit 0
        elif [[ "$1" == stop ]] ; then
            setting_variables
            stop $ID
            exit 0
        else
                echo "Please use valid argument. !!!"
                exit 1
        fi
        ;;
    startall)
        command="$1"
        if [[ "$1" == startall ]] ; then
            setting_variables
            startall
        else
            echo "Invalid Command!!! Please use appropriate argument."
            exit 1
        fi
    ;;
    stopall)
        command="$1"
        if [[ "$1" == stopall ]] ; then
                        setting_variables
                        stopall
        else
                        echo "Invalid Command!!! Please use appropriate argument."
                        exit 1
        fi
        ;;

    status)
        setting_variables
        status
        ;;
    *)
        echo "Usage:::{ start NODE_ID || stop NODE_ID || status || startall || stopall}"
        exit 1
        ;;
esac
exit 0
