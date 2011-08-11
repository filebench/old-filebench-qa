#!/bin/sh
#
# Name: rundaemon.sh
#
# Description:
# This script starts server daemon.
# For more details, reference Filebench QA system wiki pages;
# https://avatar.fsl.cs.sunysb.edu/groups/filebench/wiki/3b6b6/Filebench_QA_system.html
#
# Authors: Gyumin Sim, Vasily Tarasov
#

jobpath=/vmfs/volumes/auto-test
scriptpath=$jobpath/esx_scripts

jobdesc=$jobpath/job.txt
jobscript=$scriptpath/dojob.sh

while true
do
	if [ -f $jobdesc ]; then
		$jobscript
	else
		sleep 5
	fi
done

