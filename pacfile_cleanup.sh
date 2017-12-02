#!/usr/bin/env bash

base_dir=/export/home/cisb23/batch
pacDir_path=${base_dir}/data/autoproxy/pacfiles
pacBackup_path=${base_dir}/data/autoproxy/pacfiles_backup
netData_path=${base_dir}/data/autoproxy/pacfiles/net.data
logfile_path=${base_dir}/log/pacfile_backup.log
dailyBackup_path=${pacBackup_path}/`date +%F`
mailto=setpac.ops@ge.com
egrep_path=/usr/xpg4/bin/egrep
rsync_path=/usr/local/bin/rsync
mailx_path=/bin/mailx
grep_path=/usr/xpg4/bin/grep

rotate_log() {
if [ ! -f ${logfile_path} ]; then
  touch ${logfile_path}
else
  /bin/mv ${logfile_path} ${logfile_path}.`date +%F`
fi
}
check_files() {
  if [ ! -f ${netData_path} ] && [ ! -d ${pacDir_path} ]; then
    echo -e "\n${netData_path} or ${pacDir_path} doesn't seem to be present. !!!" >> ${logfile_path}
    exit 1
  fi
}

check_dirs() {
  if [ ! -d ${pacBackup_path} ]; then
    mkdir ${pacBackup_path} && echo -e "\n${pacBackup_path} directory has been sucessfully created. !!!" >> ${logfile_path}
      if [ ! -d ${dailyBackup_path} ]; then
        mkdir ${dailyBackup_path} && echo -e "\n${dailyBackup_path} directory has been sucessfully created. !!!" >> ${logfile_path}
      fi
  else
      if [ -d ${pacBackup_path} ]; then
          echo -e "\n${pacBackup_path} is already exists !!!" >> ${logfile_path}
            if [ ! -d ${dailyBackup_path} ]; then
                mkdir ${pacBackup_path}/`date +%F` && echo -e "\n${dailyBackup_path} directory has been created !!!" >> ${logfile_path}
            fi
      fi
   fi
}

backup_pacfiles() {
  echo -e "\nStarting Backup of Pacfiles...." >> ${logfile_path}
  ${rsync_path} -aPq ${pacDir_path}/*.pac ${dailyBackup_path}
  rc=$?
    if [ ${rc} == 0 ]; then
      echo -e "\nBackup of pacfiles Completed !!!" >> ${logfile_path}
      echo -e "\nArchiving Backup Files !!!" >> ${logfile_path}
      /bin/zip -qr ${dailyBackup_path}.zip ${dailyBackup_path}
    else
      echo -e "\nError While Taking Backup !!!" >> ${logfile_path}
      errormail
      exit 1
    fi
}
backup_netdata() {
  ${rsync_path} -qaP ${netData_path} ${pacBackup_path}/net.data.`date +%F`
  rc=$?
    if [ ${rc} == 0 ]; then
      echo -e "\nBackup of net.data Completed !!!" >> ${logfile_path}
    else
      echo -e "\nError While Taking Backup !!!" >> ${logfile_path}
      errormail
      exit 1
    fi
}

match_pacfiles(){
/bin/ls -l ${pacDir_path} | ${egrep_path} '([[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\_[[:digit:]]{1,2}\.pac)' | awk '{print $NF}' > /tmp/getpac.txt
pacfile_count=`awk '{print $1}' /tmp/getpac.txt | wc -l`
netdata_count=`cat ${netData_path} | awk -F"=" '{print $2}' | wc -l`
echo -e "\nTotal no of Pacfiles in net.data file: ${netdata_count}" >> ${logfile_path}
echo -e "\nTotal no of Pacfiles in pacfile directory: ${pacfile_count}" >> ${logfile_path}
count=0
for pacfile in `cat /tmp/getpac.txt`; do
  ${grep_path} ${pacfile} ${netData_path} > /dev/null
  if [ $? != 0 ]; then
     /bin/rm ${pacDir_path}/${pacfile}
     echo -e "\nDeleted: ${pacfile}" >> ${logfile_path}
     count=`expr $count + 1`
  fi
done
rm -rf ${dailyBackup_path}
  if [ ${count} == 0 ]; then
    echo -e "\nNo pacfile to delete !!!" >> ${logfile_path}
  else
    echo -e "\nTotal No of Pacfiles Deleted: ${count}" >> ${logfile_path}
  fi
echo -e "\n================================ Cleanup Has Been Completed ==============================================\n" >> ${logfile_path}
}

send_mail(){
${mailx_path} -s "Pacfile Cleanup Completed - `date +%F` !!!" ${mailto} < ${logfile_path}
}

errormail(){
${mailx_path} -s "Pacfile Cleanup Error - `date +%F` !!!" ${mailto} < ${logfile_path}
}

### Main Program ###
rotate_log
echo -e "\n============================ Starting Cleanup Process `date +%F` =======================================\n" >> ${logfile_path}
check_files && check_dirs
if [ $? == 0 ]; then
  backup_pacfiles && backup_netdata
    if [ $? == 0 ]; then
        match_pacfiles
        send_mail
    fi
else
  errormail
fi
### Purging old backup data ###
find ${pacDir_path} -type f -name "*.zip" -mtime +7 -exec rm -rf {} \;
find ${base_dir}/log -type f -name "*.log.*" -mtime +7 -exec rm -rf {} \;
find ${pacDir_path} -type f -name "net.data.*" -mtime +365 -exec rm -rf {} \;
