#
# Name: runesxdaemon.sh
#
# Description:
# This script starts ESXi server daemon remotely.
# For more details, reference Filebench QA system wiki pages;
# https://avatar.fsl.cs.sunysb.edu/groups/filebench/wiki/3b6b6/Filebench_QA_system.html
#
# Authors: Gyumin Sim, Vasily Tarasov
#
# Usage:
# runesxdaemon.sh <esxi server host name>
#

host=$1

if [ "$host" == "" ]; then
	echo "Usage: $0 hostname"
	exit 1
fi

ssh root@$host "nohup /vmfs/volumes/auto-test/esx_scripts/rundaemon.sh &"

