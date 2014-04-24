#!/bin/bash

#Kernel default:
#	cache size:
#	dirty_ratio:10
#	drop_cache:3
#	read_ahead_kb:128
#	scheduler: deadline

function setup()
{
echo -e "sudo /sbin/sysctl -w vm.dirty_ratio=10
sudo /sbin/sysctl -w vm.drop_caches=3
"|bash -x
sudo echo 128>/sys/block/sda/queue/read_ahead_kb
sudo echo deadline>/sys/block/sda/queue/scheduler
}

function kill_qemu()
{
  result=`netstat -lnp|grep 2222|awk '{print $7}'`
  #echo " $result"
  for val in $result; do
      #if [ ${val#*_} == "Sl" ];then
    echo "
    sudo kill ${val%%/*}"|bash -x
      #fi
  done
}

function run_workload()
{
#$1 vm path and volume name
#$2 image name
#$3 workload name
echo "running $3"
echo "qemu-system-x86_64 --enable-kvm -m 2048 -smp 4 -drive file=gluster://$1/$2,if=virtio,format=raw,cache=none,aio=threads -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device e1000,netdev=user.0 &"|bash -x
sleep 15
ssh -p 2222 root@localhost "./filebench.sh $3"
sleep 5
kill_qemu
}

if [ $# -ne 2 ];then 
	echo "enter path and image name"
	exit
fi

kill_qemu
setup
`sudo echo cfq>/sys/block/sda/queue/scheduler`
run_workload $1 $2 "cfq"

setup
echo "sudo /sbin/sysctl -w vm.dirty_ratio=20"|bash -x
run_workload $1 $2 "dirty_ratio_20"

setup 
echo "sudo /sbin/sysctl -w vm.dirty_ratio=40"|bash -x
run_workload $1 $2 "dirty_ratio_40"

setup 
echo "sudo sysctl -w vm.drop_caches=2"|bash -x
run_workload $1 $2 "drop_cache_2"

setup
echo "sudo sysctl -w vm.drop_caches=1"|bash -x
run_workload $1 $2 "drop_cache_1"


setup
`sudo echo noop>/sys/block/sda/queue/scheduler`
run_workload $1 $2 "noop"

setup
`sudo echo 256>/sys/block/sda/queue/read_ahead_kb`
run_workload $1 $2 "readahead_256"
