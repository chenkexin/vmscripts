#!/bin/bash

function format_result()
{
  #$1 should be the directory which store the results files
  #$2 : specific argument 1
  #$3 : specific argument 2
  result=`ls $1|grep summary`
  if [ $result = "summary.txt" ]; then 
    echo resutl:"$result"
    `python trim.py $result $2 $3`
    str="result_"$2"_"$3".dat"
    plot $str
  fi
}

#this function is used to draw graphics
function plot()
{
  #$1 should be the formatted result file
  filename=${1%%.*}".pdf"
  echo " 
    set style data histogram
    set style histogram clustered gap 1
    set style fill solid 0.4 border
    set term pdfcairo lw 2 font \"Times New Roman,8\"
    set output \"$filename\"
    plot \"$1\" using 2:xticlabels(1) title columnheader(2), '' using 3:xticlabels(1) title columnheader(3), '' using 4:xticlabels(1) title columnheader(4) 
   set output"|gnuplot
   `rm $1`
}

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
      `echo -en "$filetype\t\t$varread\t\t$iops\n">>$2//summary.txt`
   fi
   if [ "$mode" = "write" ]; then
      varwrite=`grep "WRITE" "$2//$1"|awk '{print $3}'`
      iopsw=`grep "iops" "$2//$1"|awk '{print $4}'`
      `echo -en "$filetype\t\t$varwrite\t\t$iopsw\n">>$2//summary.txt`
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
   `echo "test begin" > $1//summary.txt`
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

#first parameter must be directory on which fio runs.
#check if there is a summary file under that dir, if so, generate results according to that summary file.
#if not, run base test suit.
if [ $# -ne 3 ]; then
    echo "enter 3"
    #echo "current support changing one parameter"
    #echo "for comparison to base"
else
    if [ -d $1 ]; then
        echo $1
        #ran_base_suite $1
        format_result $1 $2 $3
    else echo "input correct dir"
    fi
fi

