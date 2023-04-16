[root@test-01 naveen]# pwd
/root/naveen
[root@test-01 naveen]# ll
total 28
drwx------ 2 root root 4096 May 23 14:25 config
drwx------ 2 root root 4096 May 23 10:43 diffFileLog
drwx------ 2 root root 4096 May 23 10:44 postCheckLog
-rw------- 1 root root  333 May 23 16:12 post_Check.sh
drwx------ 2 root root 4096 May 23 10:34 preCheckLog
-rw------- 1 root root  398 May 23 16:41 pre_Check.sh
drwx------ 2 root root 4096 May 23 17:08 src
[root@test-01 naveen]#

[root@test-01 naveen]# cat post_Check.sh
#!/bin/bash
green='\033[0;32m'
endColor=':\e[0m'
red='\033[0;31m'

postCheck() {
#sh $PWD/src/check.sh
source /root/naveen/src/check.sh
serviceCheckere
selinucCheck
network
osCompSource
#fsCheckSource

}
postCheck > $postLogDir/postCheck_Output-`date +%F`.log

diffChk() {
source /root/naveen/src/diffCheck.sh
diffChecking
}
diffChk
[root@test-01 naveen]#


[root@test-01 naveen]# cat pre_Check.sh
#!/bin/bash
green='\033[0;32m'
endColor=':\e[0m'
red='\033[0;31m'
preCheck() {
#sh $PWD/src/check.sh
source /root/naveen/src/check.sh

#echo "-------"

serviceCheckere
selinucCheck
network
osCompSource
fsCheck
#fsCheckSource
}
preLogDir=$PWD/preCheckLog
        if [ -d $preLogDir ]
        then
                echo ""
        else
                mkdir -p $preLogDir
        fi

preCheck > $preLogDir/preCheck_Output-`date +%F`.log
echo " Completed "
[root@test-01 naveen]#


[root@test-01 naveen]# cd src/
[root@test-01 src]# pwd
/root/naveen/src
[root@test-01 src]# ll
total 16
-rw------- 1 root root 2505 May 23 17:06 check.sh
-rw------- 1 root root 1033 May 23 16:32 diffCheck.sh
-rwx------ 1 root root 1022 May 23 17:07 fileSysCheck.sh
-rw------- 1 root root  766 May 23 17:08 osComponets.sh
[root@test-01 src]#


[root@test-01 src]# cat check.sh
#!/bin/bash
#green='\033[0;32m'
#endColor=':\e[0m'
#red='\033[0;31m'
red=`tput setaf 1`
green=`tput setaf 2`
endColor=`tput sgr0`

hostname=$(hostname -f)
kernel=$(uname -r)
diskSpace=$(df -Ph)
cpuTotal=$(cat /proc/cpuinfo |grep -i processor |wc -l)
echo -e "${green}Green ${endColor} ${red}Red ${endColor}"
NOW=$(date +"%F")
#LOGFILE=$PWD/log_Precheck-$NOW.log
configDir=$PWD/config
#logDir=$PWD/precheckLog
dirType=($configDir )
for DirType in "${dirType[@]}"
do
        if [ -d $DirType ]
        then
                echo ""
        else
                mkdir -p $DirType
        fi
done
intfNames=$(ip a s |awk '{print $2}' |grep -i '^[b|e]'|awk -F ':' '{print $1}')
intfNamesLog=$configDir/intfNames-$NOW.log
gwIps=$(route -n |awk '{print $2}' |grep -v [A-Z]|grep -v ^0|sort -u)
gwIpLog=$configDir/gwIP-$NOW.log
gwIpPingLog=$configDir/gatewayIPPing-$NOW.log
echo $gwIps > $gwIpLog
echo $intfNames > $intfNamesLog

#osCheck() {
#echo -e "${green} Hostname: $hostname ${endColor}"
#echo -e "${green} kernel: $kernel ${endColor}"
#echo -e "${green} Disk Space: $diskSpace ${endColor}"
#}

selinucCheck()
{
sestatTemp=$(sestatus |awk '{print $3}')
seConfig=$(cat /etc/selinux/config |egrep -w SELINUX|egrep -v '#' |awk -F '=' '{print $2}')
if [ "$sestatTemp" =  "$seConfig" ]
then
        echo -e "${green}Selinux is enabled ${endColor}"
else
        echo -e "${red}Selinux is disabled ${endColor}"
fi
}

network()
{
for ipping in `cat $gwIpLog`
do
        ping -c2 $ipping >>$gwIpPingLog      #gatewayIPPing-$NOW.log
        if [ $? -eq 0 ]
        then
                echo -e "${green}Gateway IP is pinging:$ipping ${endColor}"
        else
                echo -e "${red}Gateway IP not pinging: $ipping ${endColor}"
        fi
done

linkStat=yes
for linkDetect in `cat $intfNamesLog`
do
        ethStatus=$(ethtool $linkDetect|grep detected |awk '{print $3}')
        if [ "$ethStatus" = "$linkStat" ]
        then
                echo -e "${green}Link is detected for : $linkDetect ${endColor}"
        else
                echo -e "${red}Link is not detected for : $linkDetect ${endColor}"
        fi
done
}


serviceCheckere()
{
serviceType=(ntpd firewalld)
for srvc in "${serviceType[@]}"
do
        srv_Count=$(ps -ef |grep -i $srvc|grep -v grep |wc -l)
                if [ $srv_Count -gt 0 ]
                then
                        echo -e "${green}Service is running: $srvc ${endColor}"
        else
                echo -e "${red}Service is not running:: $srvc ${endColor}"
        fi
done
}

fsCheckSource() {
source $PWD/src/fileSysCheck.sh
echo "-------"
fileSysteCheck
}

osCompSource() {
source $PWD/src/osComponets.sh
osComponents
}

fsCheck() {
source $PWD/src/fileSysCheck.sh
fileSysteCheck
}




#serviceCheckere
#selinucCheck
#network
#fsCheckSource
[root@test-01 src]#

[root@test-01 src]# cat diffCheck.sh
#!/bin/bash
diffChecking() {
preLogDir=$PWD/./preCheckLog
postLogDir=$PWD/./postCheckLog
diffFileDir=$PWD/./diffFileLog

logDirType=($postLogDir $diffFileDir)
for LogDirType in "${logDirType[@]}"
do
if [ -d $LogDirType ]
        then
                echo ""
        else
                mkdir -p $LogDirType
        fi
done

postCheck > $postLogDir/postCheck_Output-`date +%F`.log
echo " Checking the differences"
#diffFileDir=$PWD/diffFileLog
diffFile=$diffFileDir/diff_File-`date +%F`
#diffFile="/root/naveen/diff_File-`date +%F`"
diff -y $preLogDir/preCheck_Output-`date +%F`.log  $postLogDir/postCheck_Output-`date +%F`.log |grep -v  /dev/ |grep '|' > $diffFile
#diff -y preCheckLog/preCheck_Output-2019-05-23.log postCheckLog/postCheck_Output-2019-05-23.log |grep -v  /dev/ |grep '|'
if [ -f $diffFile ]
then
        if [ -s $diffFile ]
        then
                echo "Difference found"
                cat $diffFile
        else
                echo "Difference not found"
        fi
else
        echo "File not found"
fi
}
[root@test-01 src]#


[root@test-01 src]# cat fileSysCheck.sh
#!/bin/bash

fileSysteCheck() {
configDir=$PWD/./config
diffFileDir=$PWD/./diffFileLog

dirType=($configDir $diffFileDir)
for DirType in "${dirType[@]}"
do
        if [ -d $DirType ]
        then
                echo ""
        else
                mkdir -p $DirType
        fi
done

dfH=$(cat /etc/fstab |egrep -i ext3 |awk '{print $2}'|egrep -v dev |sort )
fstabEn=$(df -h  |awk '{print $5 $6}'|sed 's/[0-9|%]//g'|egrep -v dev|sed '/^$/d'|sed  '1d' |sort )

dfhLog=$configDir/dfhLog-`date +%F`
fstbLog=$configDir/fstbLog-`date +%F`
#diffFs=$diffFileDir/diff_FileSys_Log-`date +%F`

echo "File system :$dfH"
echo "File system in fstab :$fstabEn"
#echo $dfH >$dfhLog
#echo $fstabEn >$fstbLog

#diff -y $dfhLog $fstbLog |grep -v  /dev/ |grep '|' > $diffFs
#if [ -f $diffFs ]
#then
 #       if [ -s $diffFs  ]
  #      then
   #             echo "Difference found"
    #            cat $diffFs
     #   else
      #          echo "Difference not found"
       # fi
#else
 #       echo "File not found"
#fi
}
#fileSysteCheck
[root@test-01 src]#

[root@test-01 src]# cat osComponets.sh
#!/bin/bash
osComponents()
{
red=`tput setaf 1`
green=`tput setaf 2`
endColor=`tput sgr0`
hostname=$(hostname -f)
kernel=$(uname -r)
#diskSpace=$(df -Ph)
cpuTotal=$(cat /proc/cpuinfo |grep -i processor |wc -l)
serUptime=$(uptime |awk '{print $3$4$5$6}')
swapDisk=$(swapon -s |tail -1 |cut -f1|awk '{print $1}')
swapSpace=$(free -g |tail -1 |awk '{print $1$2}'|awk -F ":" '{print $2}')
memInfo=$(free -g |head -2 |awk '{print $1$2}' |tail -1|awk -F ":" '{print $2}')


osComp=($hostname $kernel $cpuTotal $serUptime $swapDisk $swapSpace $memInfo)
compName=(HostName Kernel CPU-Total Uptime Swap-Disk Swap-Space Memory)

length=${#compName[@]}
for ((i=0;i<$length;i++)); do
        echo -e "${green} ${compName[$i]} : ${osComp[$i]} ${endColor}"
done
}

#osComponents
[root@test-01 src]#


