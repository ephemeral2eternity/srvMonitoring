#!/bin/bash
localip=`/sbin/ifconfig -a|grep "10.*" |grep "inet " | awk '{print $2}' |tr -d "addr:"`
eth=$(ifconfig | grep -B1 $localip | grep -v $localip | awk '{print $1}')

# Initialize the interval and the duration of the monitoring
intvl=1
period=5

# Setup the bw var location
cur_dir=$(dirname $0)
bw_var="$cur_dir/var/bw"
mem_var="$cur_dir/var/mem"

# initialization variables
cat /dev/null > $bw_var
cat /dev/null > $mem_var

# Read the interval and duration from the arguments
if [ $# -ge 1 ]; then
	intvl=$1
fi

if [ $# -ge 2 ]; then
	period=$2
fi

in_first=$(cat /proc/net/dev | grep $eth -m 1 | awk '{print $2}')
out_first=$(cat /proc/net/dev | grep $eth -m 1 | awk '{print $10}')

# Count when the monitoring will be stopped.
iter=$((period/intvl))

# Iterate iter times
i=0
while [ $i -lt $iter ];
do
	#-------------mem----------------
	totalmem=`top -b -n 1 | grep -E 'Mem:' | cut -d "," -f 1 | cut -d ":" -f 2 | awk '{print $1}'` 
	#echo $totalmem
	usedmem=`top -b -n 1 | grep -E 'Mem:' | cut -d "," -f 2 | awk '{print $1}'` 
	#echo $usedmem
	mem=`echo "scale=2;a=$usedmem/$totalmem*100; if(a<1) print 0; print a" | bc`
	echo $mem >> $mem_var

	sleep $intvl
	#------------net-----------------
	in_end=$(cat /proc/net/dev | grep $eth -m 1 | awk '{print $2}')
	out_end=$(cat /proc/net/dev | grep $eth -m 1 | awk '{print $10}')

	sum_rx=`echo "scale=2;$in_end-$in_first" | bc`
	sum_tx=`echo "scale=2;$out_end-$out_first" | bc`
	aver_rx=`echo "scale=2;a=$sum_rx/$intvl; if(a<1) print 0; print a" | bc`
	aver_tx=`echo "scale=2;a=$sum_tx/$intvl; if(a<1) print 0; print a" | bc`

	echo "$aver_rx	 $aver_tx   $in_end    $out_end" >> $bw_var

	#--------------------remember the last sample----------------------------------#
	in_first=$in_end
	out_first=$out_end
	i=$((i+1))
done
