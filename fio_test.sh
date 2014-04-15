#!/bin/bash

#this function is used to grep result file to get useful info and write to a new file
function grep_result_file()
{
   temp=${1%%_*}
   mode=${temp#rand*}
   filetype=${1%%.*}
   if [ "$mode" = "read" ]; then
      varread=`grep "READ" "$2//$1"|awk '{print $3}'`
      iops=`grep "iops" "$2//$1"|awk '{print $5}'`
      #var=$filetype\t$varread\t$iops\n
      `echo -en "$filetype\t\t$varread\t\t$iops\n">>$2//test.txt`
   fi
   if [ "$mode" = "write" ]; then
      varwrite=`grep "WRITE" "$2//$1"|awk '{print $3}'`
      iopsw=`grep "iops" "$2//$1"|awk '{print $4}'`
      `echo -en "$filetype\t\t$varwrite\t\t$iopsw\n">>$2//test.txt`
   fi
   
}

function ran_base_suite()
{
# compare io mode: random read, random write, ...
# compare io scheduler: cfq, deadline, ...
# compare block size: 8k, 16k, 32k, ...
# compare concurrent threads: 1, 4, 8, ...
# compare io engine: psync, libaio, posixaio, ...
# compare io depth: 1, 4, 8, ...
   `echo "test begin" > $1//test.txt`
    for IO_MODE in "randread" "read" "randwrite" "write"; do
	for BLOCK_SIZE in 8k 16k 32k; do
            for IO_ENGINE in sync psync libaio posixaio; do
                for SCHEDULER in noop deadline cfq; do
           echo "running $IO_MODE $BLOCK_SIZE $IO_ENGINE $SCHEDULER"
           #echo "fio -directory=$1 -direct=1 -iodepth 1 -rhread -rw=$IO_MODE -ioengine=$IO_ENGINE -bs=$BLOCK_SIZE -size=0.5G -numjobs=1 -group_reporting -name=mytest -ioscheduler=$SCHEDULER > ${IO_MODE}_${BLOCK_SIZE}_${IO_ENGINE}_${SCHEDULER}.txt"
           `fio -directory=$1 -direct=1 -iodepth 1 -thread -rw=$IO_MODE -ioengine=$IO_ENGINE -bs=$BLOCK_SIZE -size=128m -numjobs=1 -group_reporting -name=mytest -ioscheduler=$SCHEDULER > $1//${IO_MODE}_${BLOCK_SIZE}_${IO_ENGINE}_${SCHEDULER}.txt`
            #`echo "$IO_MODE $BLOCK_SIZE $IO_ENGINE $SCHEDULER" >> $1//test.txt`
	    grep_result_file ${IO_MODE}_${BLOCK_SIZE}_${IO_ENGINE}_${SCHEDULER}.txt $1
            done
    done
 done
done   
echo $1
}

#first parameter must be directory on which fio runs
if [ $# -ne 1 ]; then
    echo "current support changing one parameter"
    echo "for comparison to base"
else
    if [ -d $1 ]; then
        echo $1
        ran_base_suite $1
    else echo "input correct dir"
    fi
fi

