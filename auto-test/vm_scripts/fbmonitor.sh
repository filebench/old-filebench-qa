#
# Name: fbmonitor.sh
#
# Description:
# This script watches output of filebench and detects any failure.
# For more details, reference Filebench QA system wiki pages;
# https://avatar.fsl.cs.sunysb.edu/groups/filebench/wiki/3b6b6/Filebench_QA_system.html
#
# Authors: Gyumin Sim, Vasily Tarasov
#

fbout=$1
monitorout=$2

MONITOR_INTERVAL=1
TIMEOUT_HANG=600

##############################

stopfb() {
	ps -Ao pid,args | grep "filebench" | grep -v grep | while read line
	do
		pid=`echo $line | awk '{ print $1 }'`
		kill -9 $pid
		sleep 5
	done
}

##############################

hang=0
prev=0

while true
do
	if [ -f $fbout ]; then
		cnt=`echo $fbout | wc -l`
		if [ $prev -eq $cnt ]; then
			if [ $hang -ge $TIMEOUT_HANG ]; then
				echo "Hanging" >> $monitorout
				tail -3 $fbout >> $monitorout
				stopfb
				break
			fi
			hang=`expr $hang + $MONITOR_INTERVAL`
		else
			prev=$cnt
			hang=0
		fi
	fi

	sleep $MONITOR_INTERVAL
done

