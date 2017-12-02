#!/bin/bash
#################################################################
#######  Author :- Vijay Singh Gosai		#################
#######  Date :- 06-Feb-2015	                #################
#######  Purpose :-Backup of Internal Search Prod ###############
#################################################################

backup_date=`date +%F`
src_node="cihcispapp925.corporate.ge.com"
dest_node="cihcispapp926.corporate.ge.com"
MailTO="vijay.gosai@ge.com"
src_dir="/search_data0/data/data_fixml"
dest_dir="/search_data0/archive/data_fixml_backup"
logfile="/home/search/backup.log"
user="search"
prc_cr=`nctrl status | grep -v grep | grep "crawler" | awk '{print $5}'`
prc_cd=`nctrl status | grep -v grep | grep "contentdistributor" | awk '{print $5}'`
pid_cr=`su -search -c 'nctrl status | grep crawler | grep -v grep |awk '{print $4}''`
pid_cd=`su -search -c 'nctrl status | grep contentdistributor | grep -v grep |awk '{print $4}''`


echo "\n----------------------------------------------------------------------------------------------------------------\n"
echo "###############################    $backup_date  #############################################################\n" >> $logfile
echo "\n----------------------------------------------------------------------------------------------------------------\n"
echo "\n CRON PROCESS"
echo "\nTaking backup of cron on $dest_node.\n" >> $logfile
ssh $user@$dest_node 'crontab -l > /home/search/cron_backup_$backtup_date'
if [ "$?" -eq "0" ];then
	echo "Cron backup completed on $dest_node." >> $logfile
{
	ssh $user@$dest_node 'crontab -r' 
	if [ "$?" -eq "0" ];then
	echo "Cron deleted for $user user." >> $logfile
	else
	echo "Cron not cleared.. Error.. Stopping script" >> $logfile
	exit 1
	fi
}
else
	echo "Destination node $dest_node not accessible. Error stoped." >> $logfile
	exit 1
fi


echo "\n----------------------------------------------------------------------------------------------------------------\n" >> $log_file
echo " Creating Backup Directory \n" >> $log_file
echo "\n----------------------------------------------------------------------------------------------------------------\n" >> $log_file

echo "\nCreating backup directory on $dest_node.\m" >> $logfile
ssh $user@$dest_node 'mkdir $dest_dir/$backtup_date'
if [ "$?" -eq "0" ];then
echo "\nDirecoty created successfully on $dest_node.\n" >> $logfile
else
echo "\nError. Script stoped.\n" >> $logfile
exit 1
fi

echo "\n------------------------------------------------------------------------------------------------------\n" >> $log_file
echo " QR Server and Indexer Process stopping. " >> $log_file
echo "\n------------------------------------------------------------------------------------------------------\n" >> $log_file
su - $user -c 'nctrl stop crawler && nctrl stop contentdistributor'
sleep 30

if [ $prc_cr -eq "Stopped" && $prc_cd -eq "Stopped" ] ;then
echo "Crawlaer and Content Distributer process has been stopped. " >> $log_file
else
echo "Manually Killed Crawlaer and Content Distributer ID" >> $log_file
kill -9 `pid_cr`
echo " Killed Crawlaer Process using PID $prc_cr . " >> $log_file
kill -9 `pid_cd`
echo " Killed Content Distributer porcess PID $pcr_cd. " >> $log_file
fi
sleep 30

echo "\n------------------------------------------------------------------------------------------------------\n" >> $log_file
echo " RSYNC Backup from $src_node to $dest_node.\n " >> $log_file
echo "\n------------------------------------------------------------------------------------------------------\n" >> $log_file
echo "\nStarting backup process on $src_node." >> $logfile
#scp -pr $src_dir $user@$dest_node:$dest_dir/$backup_date &
rsync -aP $src_dir $user@$dest_node:$dest_dir/$backup_date 
if [ "$?" -eq "0" ];then
echo "\nBackup completed on $dest_node successfully on $dest_node.\n" >> $logfile
else
echo "\nBackup couldn't compleded..Error script stoped.\n" >> $logfile
exit 1
fi

echo "\n------------------------------------------------------------------------------------------------------\n" >> $log_file
echo "\n Comparing data size on both the nodes.\n" >> $logfile
echo "\n------------------------------------------------------------------------------------------------------\n" >> $log_file
src_dir_size=`du -csh $src_dir`
echo " $src_node :  $src_dir   Size: $src_dir_size" >> $logfile
dest_dir_size=`ssh $user@$dest_node 'du -csh $dest_dir/$backtup_date'`
echo " $dest_node :  $dest_dir/$backup_date   Size: $src_dir_size" >> $logfile
if [ $src_dir_siz -eq $dest_dir_size ]; then
echo "Backup completed successfully" >> $logfile
echo "$src_dir_size and $dest_dir_size" >> $logfile
else
echo "Something went Wrong... Please check .. Data size is not equal." >> $logfile
exit 1
fi

sleep 5
echo "\n------------------------------------------------------------------------------------------------------\n" >> $log_file
echo " Cron Restore for $user user." >> $log_file
echo "\n------------------------------------------------------------------------------------------------------\n" >> $log_file
ssh $user@$dest_node 'crontab < /home/search/cron_backup_$backtup_date'
if [ "$?" -eq "0" ] ;then
echo "Cron Restored for $user user." >> $log_file
else
echo "Cron Error.. Unable to restore the data." >> $log_file
exit 1
fi

echo "\n------------------------------------------------------------------------------------------------------\n" >> $log_file
echo " Crawler and Conten Dristributer Starting.... " $log_file
echo "\n------------------------------------------------------------------------------------------------------\n" >> $log_file
su - $user -c 'nctrl start crawler && nctrl start contentdistributor'
sleep 30

if [ $prc_cr -eq "Running" && $prc_cd -eq "Running" ] ;then
echo "Crawlaer and Content Distributer process has been started. " >> $log_file
else
echo " Unable to statrt the processess.. Error Need to check..." >> $log_file
exit 1
fi
sleep 10
echo "\n------------------------------------------------------------------------------------------------------\n" >> $log_file
echo " ######################################################   DONE ########################################" >> $log_file







GE SDG-Internal






