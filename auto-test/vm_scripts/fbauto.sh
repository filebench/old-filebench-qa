#!/bin/sh
#
# Name: fbauto.sh
#
# Description:
# Commond init script of VMs.
# For more details, reference Filebench QA system wiki pages;
# https://avatar.fsl.cs.sunysb.edu/groups/filebench/wiki/3b6b6/Filebench_QA_system.html
#
# Authors: Gyumin Sim, Vasily Tarasov
#

nfsmnt="/fbsource"
nfsserv="nap:/home/vass/filebenchqa/auto-test"
jobdesc_proc=$nfsmnt/job_processing.txt
testscript=$nfsmnt/vm_scripts/runtest.sh

#
# Sleep to allow various system variables
# to be set in case of parallel init scripts.
#
sleep 10

mkdir -p $nfsmnt || exit $?
umount $nfsmnt 1>/dev/null 2>&1
mount -t nfs $nfsserv $nfsmnt 1>/dev/null 2>&1
if [ $? -ne 0 ]; then
	# OpenSolaris uses -F option
	mount -F nfs $nfsserv $nfsmnt || exit $?
fi

if [ -f $jobdesc_proc ]; then
	$testscript
	halt
fi

umount $nfsmnt

