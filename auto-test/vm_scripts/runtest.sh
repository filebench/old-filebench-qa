#!/bin/bash
#
# Name: runtest.sh
#
# Description:
# Main testing script for VMs.
# For more details, reference Filebench QA system wiki pages;
# https://avatar.fsl.cs.sunysb.edu/groups/filebench/wiki/3b6b6/Filebench_QA_system.html
#
# Authors: Gyumin Sim, Vasily Tarasov
#

FBSRCDIR="/fbsource"
INSTDIR="/fbinst"
TESTDIR="/fbtest"
SCRIPTDIR=$FBSRCDIR/vm_scripts
JOB_PROC=$FBSRCDIR/job_processing.txt
TOVMFILE=$FBSRCDIR/.tovm.txt

FBFILE=`cat $JOB_PROC | grep -v "#" | grep "fbfile=" | cut -f 2 -d =`
FBWORKLOAD=`cat $JOB_PROC | grep -v "#" | grep "fbworkload=" | cut -f 2 -d =`
RUNTIME=`cat $JOB_PROC | grep -v "#" | grep "runtime=" | cut -f 2 -d =`
if [ "$RUNTIME" == "" ]; then
	RUNTIME=30
fi
EPOCH=`cat $JOB_PROC | grep -v "#" | grep "epoch=" | cut -f 2 -d =`
if [ "$EPOCH" == "" ]; then
	EPOCH=1
fi

RESDIRNAME=`cat $TOVMFILE | grep -v "#" | grep "resdir=" | cut -f 2 -d =`
if [ "$RESDIRNAME" == "" ]; then
	RESDIRNAME=results
fi
RESDIR=$FBSRCDIR/$RESDIRNAME

HOST=`hostname | cut -f 1 -d .`

OUTFILE_PROC=$RESDIR/${HOST}_proc.out
OUTFILE_DONE=$RESDIR/${HOST}.out

SUMFILE_PROC=$RESDIR/${HOST}_proc.summary
SUMFILE_DONE=$RESDIR/${HOST}.summary

###########################################################

. $SCRIPTDIR/$HOST.inc

###########################################################
log_msg() {
	while [ "$1" ]
	do
		echo $1 >> $SUMFILE_PROC
		shift
	done
}

log_ok() {
	while [ "$1" ]
	do
		echo "$1 ... OK" >> $SUMFILE_PROC
		shift
	done
}

log_failed() {
	while [ "$1" ]
	do
		echo "$1 ... failed" >> $SUMFILE_PROC
		shift
	done
}

out_seperator() {
	echo
	echo "######################################################################"
	while [ "$1" ]
	do
		echo "### $1"
		shift
	done
	echo "######################################################################"
}

fbuninstall() {
	fbfile=$1
	instdir=$2

	log_msg "### Uninstalling Filebench ###"

	cd $instdir || return $?

	fbdir=`echo $fbfile | awk '{print substr(''$0'', 1, index(''$0'', ".tar")-1)}'`
	cd $fbdir || return $?

	out_seperator "make uninstall"

	make uninstall
	if [ $? -ne 0 ]; then
		log_failed "make uninstall"
		return 1
	fi
	log_ok "make uninstall"

	cd $instdir
	rm -rf *

	return 0;
}

tumount() {
	testdir=$1

	out_seperator "umount $testdir"
	umount $testdir || return $?
	return 0
}

fbcheck_keyword() {
	fbout=$1
	word=$2

	lc=`cat $fbout | grep -i "$word" | wc -l`
	if [ $lc -gt 0 ]; then
		log_msg "FileBench Output - Keyword [$word] detected"
		cat $fbout | grep -i "$word" >> $SUMFILE_PROC
		return 1
	fi
	return 0
}

fbverify_output() {
	fbout=$1

	if [ ! -f $fbout ]; then
		log_msg "FileBench Malfunctions - No output"
		return 1
	fi

	ret=0
	fbcheck_keyword $fbout "fail" || ret=1
	fbcheck_keyword $fbout "fault" || ret=1
	fbcheck_keyword $fbout "cannot " || ret=1
	fbcheck_keyword $fbout "no " || ret=1

	neg=0
	cat $fbout | grep [0-9]ops | grep [0-9]mb | while read line
	do
		for field in 2 3 4 5
		do
			statsign=`echo $line | awk '{ print substr($'"$field"',1,1) }'`
			if [ "-" == "$statsign" ]; then
				log_msg "FileBench Stats - Negative number"
				echo $line >> $SUMFILE_PROC
				neg=1
				break;
			fi
		done
		if [ $neg -ne 0 ]; then
			ret=1
			break;
		fi
	done

	lc=`cat $fbout | grep -i "IO Summary" | wc -l`
	if [ $lc -eq 0 ]; then
		log_msg "FileBench Malfunctions - No IO summary"
		ret=1
	else
		summary=`cat $fbout | grep -i "IO Summary" | tail -1`
		total_ops=`echo $summary | awk '{ print ''$5'' }'`
		if [ $total_ops -eq 0 ]; then
			log_msg "FileBench Malfunctions - 0 Total Ops"
			ret=1
		fi
	fi

	return $ret
}

fbverify_monitor() {
	fbmon=$1

	if [ -f $fbmon ]; then
		lcnt=`cat $fbmon | wc -l`
		if [ $lcnt -gt 0 ]; then
			log_msg "FileBench Malfunction"
			cat $fbmon >> $SUMFILE_PROC
			return 1
		fi
	fi
	return 0
}

fbverify_process() {
	nps=`ps -Ao pid,args | grep filebench | grep -v grep | wc -l`
	if [ $nps -eq 0 ]; then
		return 0
	fi

	log_msg "FileBench cleanup failed - $nps processes are alive"
	ps -Ao pid,args | grep filebench | grep -v grep >> $SUMFILE_PROC

	ps -Ao pid,args | grep filebench | grep -v grep | while read line
	do
		pid=`echo $line | awk '{ print $1 }'`
		kill -9 $pid
		sleep 5
	done

	nps=`ps -Ao pid,args | grep filebench | grep -v grep | wc -l`
	return $nps
}

create_workload() {
	fbconfig=$1
	testdir=$2
	workload=$3
	runtime=$4
	stat_interval=10

	dotf="/usr/local/share/filebench/workloads/${workload}.f"
	quitbycond=0
	# case1: set mode quit ...
	lc=`cat $dotf | grep "mode quit" | wc -l`
	if [ $lc -gt 0 ]; then
		quitbycond=1
	fi

	# case2: flowop finishon...
	lc=`cat $dotf | grep "finishon" | wc -l`
	if [ $lc -gt 0 ]; then
		quitbycond=1
	fi

cat <<MARKER > $fbconfig
load $workload
set \$dir=$testdir
MARKER

if [ $quitbycond -eq 0 ]; then

cat <<MARKER >> $fbconfig
create fileset
system "sync"
system "if [ -f /proc/sys/vm/drop_caches ]; then echo 3 > /proc/sys/vm/drop_caches; fi"
create process
stats clear
MARKER

rt=0
while [ $rt -lt $runtime ]; do
cat <<MARKER >> $fbconfig
sleep $stat_interval
stats snap
MARKER
rt=`expr $rt + $stat_interval`
done

cat <<MARKER >> $fbconfig
shutdown process
quit
MARKER

else

cat <<MARKER >> $fbconfig
run
quit
MARKER

fi
}

fbrun() {
	testdir=$1
	workload=$2
	runtime=$3
	epoch=$4

	fbconfig=/tmp/fb.cfg
	fbout=/tmp/fb.out
	fbmon=/tmp/fbmon.out

	# remove temp files
	rm -f $fbconfig
	rm -f $fbout
	rm -f $fbmon
	rm -rf /tmp/fb*
	rm -rf /tmp/filebench*

	# make filebench script file
	create_workload $fbconfig $testdir $workload $runtime
	out_seperator "filebench workload file"
	cat $fbconfig

	# disable virtual address randomization
	if [ -f /proc/sys/kernel/randomize_va_space ]; then
		echo 0 > /proc/sys/kernel/randomize_va_space
	fi

	# start filebench monitor
	$SCRIPTDIR/fbmonitor.sh $fbout $fbmon &
	mon_pid=$!

	# run filebench
	out_seperator "starting filebench $workload ($epoch)"
	/usr/local/bin/filebench -f $fbconfig >$fbout 2>&1
	if [ $? -ne 0 ]; then
		log_fail "filebench"
	else
		log_ok "filebench"
	fi

	cat $fbout

	# stop filebench monitor
	kill -9 $mon_pid
	sleep 2

	rm -f $fbconfig

	# check monitor result
	fbverify_monitor $fbmon
	rm -f $fbmon

	# check filebench result
	fbverify_output $fbout
	rm -f $fbout

	# check remaining processes
	fbverify_process

	# only remaining processes matter
	return $?
}

finalize() {
	mv $OUTFILE_PROC $OUTFILE_DONE
	mv $SUMFILE_PROC $SUMFILE_DONE

	exit 0
}

###########################################################

# prepare results directory
mkdir -p $RESDIR
chmod 777 $RESDIR

# clean up old files
rm -f $OUTFILE_PROC
rm -f $OUTFILE_DONE
rm -f $SUMFILE_PROC
rm -f $SUMFILE_DONE

# redirect output
exec 1>$OUTFILE_PROC
exec 2>&1

# First, print current time and version
date
uname -a

# install
fbinstall $FBFILE $FBSRCDIR $INSTDIR
if [ $? -ne 0 ]; then
	log_failed "Installing filebench"
	finalize
fi
cd $instdir

# run benchmarks
for wkld in $FBWORKLOAD
do
	ep=1
	while [ $ep -le $EPOCH ]
	do
		log_msg " "
		log_msg "### Benchmarking $wkld ($ep) ###"

		# mount
		tmount $TESTDIR $TESTDEV $FS
		if [ $? -ne 0 ]; then
			log_failed "mount"
			break
		fi
		log_ok "mount"

		fbrun $TESTDIR $wkld $RUNTIME $ep
		if [ $? -ne 0 ]; then
			# if there are remaining processes, we can not continue
			log_msg "Test stops because of the remaining processes"
			break
		fi

		# umount
		tumount $TESTDIR
		if [ $? -ne 0 ]; then
			log_failed "umount"
			break
		fi
		log_ok "umount"

		ep=`expr $ep + 1`
	done
done
log_msg " "

# uninstall
fbuninstall $FBFILE $INSTDIR
if [ $? -ne 0 ]; then
	log_failed "Uninstalling filebench"
	finalize
fi

finalize

