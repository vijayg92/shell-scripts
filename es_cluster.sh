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
        if ps -p `cat $es_log/node$ID/$pidfile` > /dev/null 2>&1
    		then
        		echo "ElasticSearch Node$ID is Already Running-(`cat $es_log/node$ID/$pidfile`) \t[FAILED]!!!"
    		else
         	    nohup /appl/elastic/node$ID/bin/elasticsearch  > $es_log/node$ID/startup.log 2>&1 &
				RETVAL=$?
			    [ $RETVAL -eq "0" ] && echo -e "ElasticSearch Node$ID \tStarted:::[OK] !!!"
				echo $! > $es_log/node$ID/$pidfile
				return $RETVAL
    		fi
}

stop() {
		pid_stat=`cat $es_log/node$ID/$pidfile`
		ps -p `cat $es_log/node$ID/$pidfile` > /dev/null 2>&1
		if [ "$?" -eq "0" ]; then
			killps=`kill -9 $pid_stat`
			#[ $RETVAL = 0 ] &&	
			echo -e "Elasticsearch Instance Node$ID \tStopped:::[OK] !!!"
		else
			echo -e "Elasticsearch Instance Node$ID NotRunning \tStopped:::[FAILED] !!!"
		fi
        return $RETVAL	
}

startall() {
        setting_variables
        for i in `seq $es_ins`;do
			if ps -p `cat $es_log/node$i/$pidfile` > /dev/null 2>&1
    		then
        		echo -e "ElasticSearch Node$i is Already Running-(`cat $es_log/node$i/$pidfile`) \tStart:::[FAILED]!!!"
    		else
         	    nohup /appl/elastic/node$i/bin/elasticsearch  > $es_log/node$i/startup.log 2>&1 &
				RETVAL=$?
			    [ $RETVAL -eq "0" ] && echo -e "ElasticSearch Node$i \tStarted:::[OK] !!!"
				echo $! > $es_log/node$i/$pidfile
			fi
        done
		return $RETVAL
}

stopall() {
        for i in `seq $es_ins`; do
        pid_stat=`cat $es_log/node$i/$pidfile`
		ps -p `cat $es_log/node$i/$pidfile` > /dev/null 2>&1
		if [ "$?" -eq "0" ]; then
			killps=`kill -9 $pid_stat`
			#[ $RETVAL = 0 ] &&	
			echo -e "Elasticsearch Instance Node$i \tStopped:::[OK] !!!"
		else
			echo -e "Elasticsearch Instance Node$ID NotRunning \tStopped:::[FAILED] !!!"
		fi
		done
    return $RETVAL
}
status() {
        setting_variables
        for i in `seq $es_ins`;do
        pid_stat=`cat $es_log/node$i/$pidfile`
		ps -p `cat $es_log/node$i/$pidfile` > /dev/null 2>&1
		if [ "$?" -eq "0" ]; then
			echo -e "Elasticsearch Instance Node$i PID:$pid_stat \tRunning:::[OK] !!!"
		else
			echo -e "Elasticsearch Instance Node$i NotRunning \tStatus:::[FAILED] !!!" 
        fi
		done
}

case "$1" in
            start | stop)
            command="$1"
            ID="$2"

        if [[ "$1" == start && [ [ $ID -eq 1 ] || [ $ID -eq 2 ] || [ $ID -eq 3 ] ]  ]] ; then
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
