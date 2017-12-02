#!/bin/bash
#############################################################################################
# Author:- Vijay Singh Gosai															    #
# Created Date:- 2015-30-04																    #
# Purpose:- TO Take MYSQL Backup & COPY to remote location								    #
#																						    #									
#############################################################################################

host_name=`hostname`
src_host="Calendar MySQL Server"
rm_host=cihcissweb826v.corporate.ge.com
rm_bkup_dir=/appl/cihcispapp900v_mysql_backup
rm_user=root
mysql_host=localhost
mysql_user=root
mysql_pass=pa55w0rd
time_stamp=`date +%F`
mysql_bckupdir=/appl/mysqlbackup/backup/$time_stamp
mysql_log=$mysql_bckupdir/$time_stamp.txt
mailto=vijay.gosai@ge.com
mailcc=vikrant.telkar@ge.com


############################ Don't Need to Edit Below this ###############################

mysql_dump(){
	
	check_ps=`netstat -ntlup | grep mysql | awk '{print $6}'`
		
		if [ "$check_ps" -ne "LISTEN" ]
			then
				echo "MySQL is not running. Please check" >> $mysql_log
				error_mail
				exit 1
		else
		{
			echo -e	"\n=============================================== $time_stamp ====================================================================\n" >> $mysql_log
			{
				if [ ! -d ${mysql_bckupdir} ]
					then
						mkdir ${mysql_bckupdir}
					echo "Backup Directory Created at $time_stamp." >> $mysql_log
				fi
			}
			echo "Starting MySQL Backup $time_stamp." >> $mysql_log
				dball=`mysql --user=$mysql_user --password=$mysql_pass -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`
					echo " "
					for db in $dball
						do
						echo -e "\nStart dumping database: $db" >> $mysql_log
						mysqldump --force --opt --user=$mysql_user --password=$mysql_pass --skip-lock-tables --databases $db > $mysql_bckupdir/$time_stamp_$db.sql
								if [ "$?" -ne "0" ]
									then	
									echo "MySQL Dump Cannot Perform. Kindly check." >> $mysql_log
									error_mail
									exit 1
								fi
						echo -e "$db backup completed $time_stamp." >> $mysql_log
						gzip $mysql_bckupdir/$time_stamp_$db.sql
						echo -e "Compressed $db.sql database.\n" >> $mysql_log
					done
					echo " "
				echo -e "\nMySQL Backup is Completed.";
			send_data
		  echo -e "\n===========================================================================================================================\n" >> $mysql_log
	send_mail	
	}
	fi
}		

send_data(){
	rsync -aP $mysql_bckupdir $rm_user@$rm_host:$rm_bkup_dir;
	if [ "$?" -eq "0" ];then
		echo -e "RSYNC from $dest_host to $rm_host done sucessfully on $time_stamp." >> $mysql_log 
	else
		echo -e "Rsync Copy Data not performed. Remote Host $rm_host unable to connect." >> $mysql_log
		exit 1
	fi
}	

send_mail(){
              echo -e "\nServerDesc: $src_host.\nHostName: $host_name.\nMySQL Backup Completed $time_stamp.\nRsync Status: Done from $src_host to $rm_host on $time_stamp." | mail -s "$host_desc Success MySQL Backup" $mailto -c $mailcc
}

error_mail(){
			  echo -e "\nServerDesc: $src_host\nHostName: $host_name\nMySQL Bakcup Couldn't perfromed $time_stamp.\nMySQL Error." | mail -s "Error MySQL Backup" $mailto -c $mailcc
}

mysql_dump

find $mysql_bckupdir -mtime +5 -name '*.sql.gz'|xargs rm -f {}\;

