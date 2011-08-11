#
# Name: stopesxdaemon.sh
#
# Description:
# This script stops ESXi server daemon remotely.
# For more details, reference Filebench QA system wiki pages;
# https://avatar.fsl.cs.sunysb.edu/groups/filebench/wiki/3b6b6/Filebench_QA_system.html
#
# Authors: Gyumin Sim, Vasily Tarasov
#
# Usage:
# stopesxdaemon.sh <esxi server host name>
#

host=$1

if [ "$host" == "" ]; then
	echo "Usage: $0 hostname"
	exit 1
fi

ssh root@$host "/vmfs/volumes/auto-test/esx_scripts/stopdaemon.sh"

