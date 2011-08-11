#!/bin/sh
#
# Name: dojob.sh
#
# Description:
# This is the main testing script.
# For more details, reference Filebench QA system wiki pages;
# https://avatar.fsl.cs.sunysb.edu/groups/filebench/wiki/3b6b6/Filebench_QA_system.html
#
# Authors: Gyumin Sim, Vasily Tarasov
#


jobpath=/vmfs/volumes/auto-test
scriptpath=$jobpath/esx_scripts

jobdate=`date +%F-%H-%M-%S`
resdirname=results-$jobdate
respath=$jobpath/$resdirname

resfile=$respath/esx.out

tovmfile=$jobpath/.tovm.txt

jobdesc=$jobpath/job.txt
jobdesc_proc=$jobpath/job_processing.txt
jobdesc_done=$jobpath/job_done.txt

hosttable=$scriptpath/os-to-host-table.txt

WAITING_INTERVAL=5

TIMEOUT_BOOT=300
TIMEOUT_TEST=7200
TIMEOUT_HALT=40

#################################################
get_vmid() {
	local vm=$1
	local allvms=`vim-cmd vmsvc/getallvms` || return $?
	echo "$allvms" | while read line
	do
		name=`echo "$line" | awk '{ print ''$2'' }'`
		if [ "$name" == "$vm" ]; then
			vmid=`echo "$line" | awk '{ print ''$1'' }'`
			echo $vmid
			return 0
		fi
	done
}

get_power_state() {
	local vmid=$1
	vim-cmd vmsvc/power.getstate $vmid | tail -1 | cut -f 2 -d ' '
}

get_host_name() {
	local vm=$1
	local table=`cat $hosttable` || return $?
	echo "$table" | while read line
	do
		vmname=`echo "$line" | awk '{ print ''$3'' }'`
		if [ "$vmname" == "$vm" ]; then
			host=`echo "$line" | awk '{ print ''$2'' }'`
			echo $host
			return 0
		fi
	done
}

execvm() {
	local vm=$1
	local vmid=`get_vmid $vm`
	local host=`get_host_name $vm`

	if [ "$vmid" == "" ]; then
		echo "Unknown VM: $vm"
		return 1;
	fi
	if [ "$host" == "" ]; then
		echo "Unknown Host: $vm"
		return 1;
	fi

	pwrstate=`get_power_state $vmid`
	echo "Starting $vm ($host)"

	if [ "$pwrstate" == "on" ]; then
		vim-cmd vmsvc/power.off $vmid || return $?
		sleep 2
	fi

	vim-cmd vmsvc/power.on $vmid || return $?
	sleep 2
	
	out_proc=$respath/${host}_proc.out
	out_done=$respath/${host}.out

	err=0
	waited=0
	echo "waiting for $vm booting"
	while [ ! -f $out_proc ]
	do
		if [ -f $out_done ]; then
			break
		fi
		if [ $waited -ge $TIMEOUT_BOOT ]; then
			echo "TimeOut... ($waited sec)"
			err=1
			break
		fi
		
		sleep $WAITING_INTERVAL
		waited=`expr $waited + $WAITING_INTERVAL`
	done

	if [ 0 -eq $err ]; then
		waited=0
		echo "waiting for $vm work"
		while [ ! -f $out_done ]
		do
			if [ $waited -ge $TIMEOUT_TEST ]; then
				echo "TimeOut... ($waited sec)"
				err=1
				break
			fi
			
			sleep $WAITING_INTERVAL
			waited=`expr $waited + $WAITING_INTERVAL`
		done
	fi

	if [ 0 -eq $err ]; then
		waited=0
		echo "waiting for $vm halting"
		pwrstate=`get_power_state $vmid`
		while [ "$pwrstate" == "on" ]
		do
			if [ $waited -ge $TIMEOUT_HALT ]; then
				break
			fi

			sleep $WAITING_INTERVAL
			waited=`expr $waited + $WAITING_INTERVAL`
			
			pwrstate=`get_power_state $vmid`
		done
	fi

	pwrstate=`get_power_state $vmid`
	if [ "$pwrstate" == "on" ]; then
		echo "forced shutdown $vm"
		vim-cmd vmsvc/power.off $vmid
		sleep 2
	fi
	echo "Shutdowned $vm"
	echo
}

#################################################

if [ -f $jobdesc ]; then
	mkdir -p $respath || exit $?
	chmod 777 $respath >/dev/null 2>&1

	rm -f $respath/a-*.out
	rm -f $respath/b-*.out
	rm -f $respath/a-*.summary
	rm -f $respath/b-*.summary

	# redirect output
	exec 1>$resfile
	exec 2>&1

	rm -f $tovmfile
	echo "resdir=$resdirname" > $tovmfile || exit $?

	mv $jobdesc $jobdesc_proc || exit $?
	fbfile=`cat $jobdesc_proc | grep -v "#" | grep "fbfile=" | cut -f 2 -d =`
	vms=`cat $jobdesc_proc | grep -v "#" | grep "vms=" | cut -f 2 -d =`

	echo "job found: $fbfile on $vms"

	for vm in $vms
	do
		execvm $vm
	done

	chmod 666 $respath/*.out 1>/dev/null 2>&1
	chmod 666 $respath/*.summary 1>/dev/null 2>&1
	rm -f $tovmfile

	mv $jobdesc_proc $jobdesc_done

fi

