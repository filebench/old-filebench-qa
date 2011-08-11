#
# Name: esxdaemonstatus.sh
#
# Description:
# This script showes current status of ESXi server daemon.
# For more details, reference Filebench QA system wiki pages;
# https://avatar.fsl.cs.sunysb.edu/groups/filebench/wiki/3b6b6/Filebench_QA_system.html
#
# Authors: Gyumin Sim, Vasily Tarasov
#
# Usage:
# esxdaemonstatus.sh <esxi server host name>
#

host=$1

if [ "$host" == "" ]; then
	echo "Usage: $0 hostname"
	exit 1
fi

ssh root@$host "/vmfs/volumes/auto-test/esx_scripts/daemonstatus.sh"

