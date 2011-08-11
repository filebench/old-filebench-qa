#!/bin/sh
#
# Name: daemonstatus.sh
#
# Description:
# This script showes status of server deamon.
# For more details, reference Filebench QA system wiki pages;
# https://avatar.fsl.cs.sunysb.edu/groups/filebench/wiki/3b6b6/Filebench_QA_system.html
#
# Authors: Gyumin Sim, Vasily Tarasov
#

daemonscript=rundaemon.sh
jobscript=dojob.sh

lc=`ps -c | grep $daemonscript | grep -v grep | wc -l`
if [ $lc -gt 0 ]; then
	lc=`ps -c | grep $jobscript | grep -v grep | wc -l`
	if [ $lc -gt 0 ]; then
		status="Processing"
	else
		status="Waiting for work"
	fi
else
	status="Stopped"
fi
echo "$status"
