#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 -H jenkins_host -U jenkins_user -P jenkins_pass -D jenkins_path -O csv_out_path"
  exit 1
}

export_csv() {
    tmp_file="/tmp/disk_usage.csv"
    if [ -d $home ]; then
        touch $tmp_file
        for job in `ls -ltr $home | grep ^d | awk '{print $9}'`;do
            resp=$(curl -w "%{http_code}" --output /dev/null -s --user $user:$pass https://$host/job/$job/api/json?pretty=true)
            if [ "$resp" -eq "200" ]; then
                status=$(curl -s --user $user:$token https://$host/job/$job/api/json?pretty=true | python -c "import sys, json; print json.load(sys.stdin)['buildable']")
                usage=$(du -sh $home/$job --block-size=KB| grep -v total | awk '{print $1}')
                echo $job,$status,$usage >> $tmp_file
            fi
        done
        echo JobName,JobStatus,Usage > $out
        cat  $tmp_file | sort -rt, -nk3 >> $out
        rm -rf $tmp_file
    else
        echo "Unable to find jenkis_home"
        exit 1
    fi
}
## Main Function ##
if [ "$#" -ne 10 ]; then
    usage
else
    while getopts ":H:U:P:D:O:" opt; do
        case $opt in
            H) 
                host=$OPTARG
                ;;
            U) 
                user=$OPTARG
                ;;
            P) 
                pass=$OPTARG
                ;;
            D) 
                home=$OPTARG
                ;;
            O) 
                out=$OPTARG
                ;;
            *) 
                usage
                ;;
        esac
    done
    echo $host, $user, $pass, $home, $out
    export_csv
fi