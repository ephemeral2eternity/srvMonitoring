#!/bin/bash

intvl=1
period=5

if [ $# -ge 1 ]; then
	intvl=$1
fi

if [ $# -ge 2 ]; then
	period=$2
fi

cur_dir=$(dirname $0)
io_var="$cur_dir/var/io"

cat /dev/null > $io_var

iter=$((period/intvl))

#-------------i/o----------------#
iostat $intvl $iter |grep "sda" |awk '{print $2, $3, $4, $5, $6}' > $io_var
