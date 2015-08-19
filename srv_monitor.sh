#!/bin/bash

# outfile=$HOME/monitor/$HOSTNAME.csv

today=$(date +"%m%d%H%M")

outfile="$HOME/monitor/$HOSTNAME-$today.csv"
#oldfile=$HOME/monitor/$HOSTNAME.old

localip=`/sbin/ifconfig -a|grep "10.*" |grep "inet " | awk '{print $2}' |tr -d "addr:"`
eth=$(ifconfig | grep -B1 $localip | grep -v $localip | awk '{print $1}')
#echo $eth


# Initialize the interval and the duration of the monitoring
intvl=5
duration=600

# Read the interval and duration from the arguments
if [ $# -ge 1 ]; then
	intvl=$1
fi

if [ $# -ge 2 ]; then
	duration=$2
fi

in_first=$(cat /proc/net/dev | grep $eth -m 1 | awk '{print $2}')
out_first=$(cat /proc/net/dev | grep $eth -m 1 | awk '{print $10}')

# Count when the monitoring will be stopped.
cur_ts=$(date "+%s")
end_ts=$((cur_ts+duration))

#initialization
#cp $outfile $oldfile
cat /dev/null > $outfile
echo "time_stamp, ip, cpu(%), mem(%), i/o(tps), net_in(bytes/s), net_out(bytes/s)"
echo "time_stamp, ip, cpu(%), mem(%), i/o(tps), net_in(bytes/s), net_out(bytes/s)" >>$outfile

ip=`curl -s ident.me`
#echo $ip

while [ $(date "+%s") -lt $end_ts ];
do
	`./cpu_monitor.sh >$PWD/tmp/cpu` &
	`./io_monitor.sh >$PWD/io_tps` &
	sleep $intvl &
	wait

	#-------------mem----------------
	totalmem=`top -b -n 1 | grep -E 'Mem:' | cut -d "," -f 1 | cut -d ":" -f 2 | awk '{print $1}'` 
	#echo $totalmem
	usedmem=`top -b -n 1 | grep -E 'Mem:' | cut -d "," -f 2 | awk '{print $1}'` 
	#echo $usedmem
	mem=`echo "scale=2;a=$usedmem/$totalmem*100; if(a<1) print 0; print a" | bc`

	#-------------cpu----------------
	cpu=$(cat ./tmp/cpu)

	#------------i/o----------------
	io=$(cat ./tmp/io_tps)
	# echo $cur_ts, $ip, $cpu, $io

	#------------net-----------------
	in_end=$(cat /proc/net/dev | grep $eth -m 1 | awk '{print $2}')
	out_end=$(cat /proc/net/dev | grep $eth -m 1 | awk '{print $10}')
	cur_ts=$(date "+%s")
	#echo "Current Timestamp: $cur_ts. $(date -d @$cur_ts)"

	sum_rx=`echo "scale=2;$in_end-$in_first" | bc`
	sum_tx=`echo "scale=2;$out_end-$out_first" | bc`
	#echo $sum_rx
	#echo $sum_tx
	aver_rx=`echo "scale=2;a=$sum_rx/$intvl; if(a<1) print 0; print a" | bc`
	aver_tx=`echo "scale=2;a=$sum_tx/$intvl; if(a<1) print 0; print a" | bc`
	#echo "Average inbound traffic: $aver_rx"
	# echo "Average outbound traffic: $aver_tx"

	echo $cur_ts, $ip, $cpu, $mem, $io, $aver_rx, $aver_tx
	echo $cur_ts, $ip, $cpu, $mem, $io, $aver_rx, $aver_tx >> $outfile

	#--------------------remember the last sample----------------------------------#
	in_first=$in_end
	out_first=$out_end
done
