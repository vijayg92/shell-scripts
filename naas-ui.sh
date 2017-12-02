#!/bin/bash

### Global Variables Declaration ###
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
app="${2}"
app_name=${app}.js
node_env=dev
log_dir=/logs/${app}
log_file=${log_dir}/${app_name}.log
error_log=${log_dir}/${app}-error.log
app_path=/appl/${app}
app_bin=${app_path}/${app_name}
pidfile=${log_dir}/${app}.pid
nvm_path=/usr/local/nvm
args="${app_bin}"
prog=node

#########################################################

export NODE_ENV
export PATH=${PATH}:${NPM_BIN_PATH}

if test ! -d ${log_dir}
then
    mkdir ${log_dir}
fi

############# Checking NodeJS Configuration #############
check_app() {
    if test ! -f ${app_path}/${app_name}
    then
        echo "${red}Application ${app_name} doesn't exists !!!${reset}"
        exit 1
    fi
}

############# Checking NodeJS Instance #############
node_instance() {
  version=`cat ${nvm_path}/alias/${app}`
    if test ! -d ${nvm_path}/${version}/etc
    then
        mkdir ${nvm_path}/${version}/etc
    fi
  cp /usr/etc/npmrc ${nvm_path}/${version}/etc/
  source ${nvm_path}/nvm.sh
}

############# Starting NodeJS Instance #############
start() {
        if ps -p `cat ${pidfile}` > /dev/null 2>&1; then
            echo -e "Process ${app_name} is already running at `cat ${pidfile}`. !!! \tStarted:[${red}FAILED${reset}]"
        else
            echo -e "Starting Node ${app_name} process...."
            node_instance && nvm use ${app}
            cd ${app_path} && NPM_ENV=nohup npm start > ${log_file} 2>&1 &
            rc=$?
            echo $! > ${pidfile}
              if [ ${rc} -eq 0 ]; then
                    echo -e "Process ${app_name} has been started. !!! \tStarted:[${green}OK${reset}]"
                    exit ${rc}
              fi
        fi
}

############# Stopping NodeJS Instance #############
stop() {
  if ps -p `cat ${pidfile}` > /dev/null 2>&1; then
      kill -9 `cat ${pidfile}`
      echo -e "Node Process ${app_name} has been stopped !!! \tStopped:[${red}OK${reset}]"
  else
      echo -e "Node Process ${app_name} is not running !!! \tStopped:[${red}FAILED${reset}]"
  fi
}

############# Status NodeJS Instance #############
status() {
  if ps -p `cat ${pidfile}` > /dev/null 2>&1; then
      echo -e "Node Process ${app_name} is running at `cat ${pidfile}` !!! \tStatus:[${green}OK${reset}]"
  else
      echo -e "Node Process ${app_name} is not running !!! \tStatus:[${red}FAILED${reset}]"
  fi
}

############# Usages of Script #############
usage() {
      echo "${red}Usage: $prog (start||stop||status||restart) (AppName)${reset}"
}

############# Main Program #############

if [ "$#" -ne 2 ]; then
      usage
else
  check_app
      case "$1" in
        start)
              start;
              ;;
        stop)
              stop;
              ;;
        status)
              status;
              ;;
        restart)
              stop;
              start;
              ;;
        *)
              usage
              exit 1
      esac
fi
exit
