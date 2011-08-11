#!/bin/sh
#
# Name: stopdaemon.sh
#
# Description:
# This script stops server daemon.
# For more details, reference Filebench QA system wiki pages;
# https://avatar.fsl.cs.sunysb.edu/groups/filebench/wiki/3b6b6/Filebench_QA_system.html
#
# Authors: Gyumin Sim, Vasily Tarasov
#

daemonscript=rundaemon.sh
jobscript=dojob.sh

lc=`ps -c | grep $jobscript | grep -v grep | wc -l`
while [ $lc -gt 0 ]
do
	pid=`ps -c | grep $jobscript | grep -v grep | head -1 | awk '{ print ''$1'' }'`
	kill -9 $pid
	lc=`ps -c | grep $jobscript | grep -v grep | wc -l`
done

lc=`ps -c | grep $daemonscript | grep -v grep | wc -l`
while [ $lc -gt 0 ]
do
	pid=`ps -c | grep $daemonscript | grep -v grep | head -1 | awk '{ print ''$1'' }'`
	kill -9 $pid
	lc=`ps -c | grep $daemonscript | grep -v grep | wc -l`
done

