#!/bin/bash
# QEMU default: 
#	cache:none 
#	virtio:on 
#	mem:2048 
#	smp:4 
#	glusterfs:integrated 
#	format:raw 
#	aio:threads

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

function setup()
{
#size in bytes. range 4194304(4096 * 1024) to 34359738368
sudo gluster volume set image performance.cache-size 33554432
sudo gluster volume set image performance.write-behind-window-size 1048576
sudo gluster volume set image performance.cache-refresh-timeout 1
#sudo gluster volume set image cluster.stripe-block-size 128
sudo gluster volume set image performance.io-thread-count 16
}

#$1: volumne path and volumn name
# if remote: $1=192.168.13.131/image(4.22.2014)
#$2: image name.raw
#$3: image name.qcow2
if [ $# -ne 3 ];then 
    echo "usage: enter volume path, image name"
    exit
fi 

setup

#baseline
echo "baseline"
#echo "qemu-system-x86_64 --enable-kvm -m 2048 -smp 4 -drive file=gluster://$1/$2,if=virtio,format=raw,cache=none,aio=threads -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device e1000,netdev=user.0 &"|bash -x
sleep 15
ssh -p 2222 root@localhost "./filebench.sh baseline"
sleep 5
kill_qemu
sleep 5
sleep 10
#off virtio

#echo "qemu-system-x86_64 --enable-kvm -m 2048 -smp 4 -drive file=gluster://$1/$2,if=none,format=raw,cache=none,aio=threads -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device e1000,netdev=user.0 &"|bash -x
sleep 15
ssh -p 2222 root@localhost "./filebench.sh off_virtio"
sleep 10
#run_workload "off_virtio"
kill_qemu
sleep 5
sleep 10
#cache=writeback|writethrough|unsafe|none
echo "qemu-system-x86_64 --enable-kvm -m 2048 -smp 4 -drive file=gluster://$1/$2,if=virtio,format=raw,cache=writeback,aio=threads -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device e1000,netdev=user.0 &"|bash -x
sleep 15
ssh -p 2222 root@localhost "./filebench.sh cache_writeback"
#sleep 5
kill_qemu
sleep 5
sleep 10

echo "qemu-system-x86_64 --enable-kvm -m 2048 -smp 4 -drive file=gluster://$1/$2,if=virtio,format=raw,cache=writethrough,aio=threads -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device e1000,netdev=user.0 &"|bash -x
sleep 15
ssh -p 2222 root@localhost "./filebench.sh cache_writethrough"
sleep 5
kill_qemu
sleep 5
sleep 10
echo "unsafe"
echo "qemu-system-x86_64 --enable-kvm -m 2048 -smp 4 -drive file=gluster://$1/$2,if=virtio,format=raw,cache=unsafe,aio=threads -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device e1000,netdev=user.0 &"|bash -x
sleep 15
ssh -p 2222 root@localhost "./filebench.sh cache_unsafe"
kill_qemu
sleep 10
sleep 5

#format=qcow2
#`qemu-system-x86_64 --enable-kvm -m 2048 -smp 4 -drive file=gluster://$1/$3,if=virtio,format=qcow2,cache=none,aio=threads -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device e1000,netdev=user.0`
#sleep 10

#aio=none
echo "aio=none"
echo "qemu-system-x86_64 --enable-kvm -m 2048 -smp 4 -drive file=gluster://$1/$2,if=virtio,format=raw,cache=none,aio=none -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device e1000,netdev=user.0 &"|bash -x
sleep 15
ssh -p 2222 root@localhost "./filebench.sh aio_none"
sleep 5
kill_qemu
sleep 5
sleep 10


#Integrated settings
#protocol:tcp(assumed)|unix|rdma
echo "qemu-system-x86_64 --enable-kvm -m 2048 -smp 4 -drive file=gluster+rdma://$1/$2,if=virtio,format=raw,cache=none,aio=threads -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device e1000,netdev=user.0 &"|bash -x
sleep 15
ssh -p 2222 root@localhost "./filebench.sh rdma "
sleep 10
kill_qemu
sleep 5
sleep 10

#echo "qemu-system-x86_64 --enable-kvm -m 2048 -smp 4 -drive file=gluster+unix://$2/$3,if=virtio,format=raw,cache=none,aio=threads -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device e1000,netdev=user.0 &"|bash -x
#sleep 15
#ssh -p 2222 root@localhost "./filebench.sh unix"
#sleep 10

