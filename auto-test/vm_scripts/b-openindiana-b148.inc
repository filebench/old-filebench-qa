#
# Name: a-openindiana-b148.inc
#
# Description:
# OpenIndiana-b148-x86 specific variables and functions.
# For more details, reference Filebench QA system wiki pages;
# https://avatar.fsl.cs.sunysb.edu/groups/filebench/wiki/3b6b6/Filebench_QA_system.html
#
# Authors: Vasily Tarasov
#


TESTDEV="/dev/rdsk/c2t1d0s0"
FS=ufs

fbinstall() {
	fbfile=$1
	fbsrcdir=$2
	instdir=$3
	tmpout=/tmp/temp.out

	log_msg "### Installing Filebench ###"

	mkdir -p $instdir || return $?
	cd $instdir || return $?
	rm -rf * || return $?

	cp $fbsrcdir/$fbfile . || return $?
	gunzip $fbfile || return $?
	fbtar=`echo $fbfile | awk '{print substr(''$0'', 1, index(''$0'', ".gz")-1)}'`
	tar -xf $fbtar || return $?

	fbdir=`echo $fbfile | awk '{print substr(''$0'', 1, index(''$0'', ".tar")-1)}'`
	cd $fbdir || return $?

	out_seperator "configure"
	./configure
	if [ $? -ne 0 ]; then
		log_failed "configure"
		return 1
	fi
	log_ok "configure"

	out_seperator "make"
	make 1>$tmpout 2>&1
	if [ $? -ne 0 ]; then
		cat $tmpout
		log_failed "make"
		grep "error" $tmpout >> $SUMFILE_PROC
		return 2
	fi
	cat $tmpout

	warning=`grep "warning" $tmpout | wc -l`
	if [ $warning -ne 0 ]; then
		log_msg "make: warning found"
		grep "warning" $tmpout >> $SUMFILE_PROC
	else
		log_ok "make"
	fi

	out_seperator "make install"
	make install
	if [ $? -ne 0 ]; then
		log_failed "make install"
		return 3
	fi
	log_ok "make install"

	cd $instdir

	return 0;
}

tmount() {
	testdir=$1
	testdev=$2
	fs=$3
	test_bdev=`echo $testdev | sed s/rdsk/dsk/`

	umount $testdir 1>/dev/null 2>&1
	mkdir -p $testdir || return $?

	out_seperator "format and mount $testdev"
	echo y | newfs -v $testdev || return $?
	mount $test_bdev $testdir || return $?
	return 0
}
