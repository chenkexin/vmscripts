#!/bin/bash

#GlusterFS default:
#       performance.cache-size:32M
#       performance.write-behind-window-size:1M
#       performance.cache-refresh-timeout:1s
#       cluster.stripe-block-size:128k
#       performance.io-thread.count:16

function kill_qemu()
{
  result=`netstat -lnp|grep 2222|awk '{print $7}'`
  #echo " $result"
  for val in $result; do
    echo "
      sudo kill ${val%%/*}"|bash -x
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

#GlusterFS setting
#write-behind-window-size: 1M|8M|16M
setup
sudo gluster volume set image performance.write-behind-window-size 8048576 
echo "qemu-system-x86_64 --enable-kvm -m 2048 -smp 4 -drive file=gluster://$1/$2,if=virtio,format=raw,cache=none,aio=threads -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device e1000,netdev=user.0 &"|bash -x
sleep 15
ssh -p 2222 root@localhost "./filebench.sh write_behind_8"
sleep 10
kill_qemu

sleep 5

#setup
sudo gluster volume set image performance.write-behind-window-size 16048676
echo "write behind size 16"
echo "qemu-system-x86_64 --enable-kvm -m 2048 -smp 4 -drive file=gluster://$1/$2,if=virtio,format=raw,cache=none,aio=threads -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device e1000,netdev=user.0 &"|bash -x
sleep 15
ssh -p 2222 root@localhost "./filebench.sh write_behind_16"
sleep 10
kill_qemu
sleep 5


#cache-refresh-timeout:1|8|16
setup
sudo gluster volume set image performance.cache-refresh-timeout 8
echo "cache refresh timeout 8"
echo "qemu-system-x86_64 --enable-kvm -m 2048 -smp 4 -drive file=gluster://$1/$2,if=virtio,format=raw,cache=none,aio=threads -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device e1000,netdev=user.0 &"|bash -x
sleep 15
ssh -p 2222 root@localhost "./filebench.sh refresh_timeout_8"
sleep 10
kill_qemu
sleep 5


setup
sudo gluster volume set image performance.cache-refresh-timeout 16
echo "qemu-system-x86_64 --enable-kvm -m 2048 -smp 4 -drive file=gluster://$1/$2,if=virtio,format=raw,cache=none,aio=threads -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device e1000,netdev=user.0 &"|bash -x
sleep 15
ssh -p 2222 root@localhost "./filebench.sh refresh_timeout_16"
sleep 10
kill_qemu
sleep 5

#cache-size(cache for read):32m|64m
setup
sudo gluster volume set image performance.cache-size 64048676
echo "qemu-system-x86_64 --enable-kvm -m 2048 -smp 4 -drive file=gluster://$1/$2,if=virtio,format=raw,cache=none,aio=threads -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device e1000,netdev=user.0 &"|bash -x
sleep 15
ssh -p 2222 root@localhost "./filebench.sh cache_size_64"
sleep 10
kill_qemu
sleep 5

#io-thread-count:16|32|64
setup
sudo gluster volume set image performance.io-thread-count 32 
echo "qemu-system-x86_64 --enable-kvm -m 2048 -smp 4 -drive file=gluster://$1/$2,if=virtio,format=raw,cache=none,aio=threads -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device e1000,netdev=user.0 &"|bash -x
sleep 15
ssh -p 2222 root@localhost "./filebench.sh io_thread_32"
sleep 10
kill_qemu

sleep 5

setup
sudo gluster volume set image performance.io-thread-count 64 
echo "qemu-system-x86_64 --enable-kvm -m 2048 -smp 4 -drive file=gluster://$1/$2,if=virtio,format=raw,cache=none,aio=threads -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device e1000,netdev=user.0 &"|bash -x
sleep 15
ssh -p 2222 root@localhost "./filebench.sh io_thread_64"
sleep 10
kill_qemu
sleep 5
