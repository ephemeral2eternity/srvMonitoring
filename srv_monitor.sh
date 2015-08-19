#!/bin/bash

# outfile=$HOME/monitor/$HOSTNAME.csv

today=$(date +"%m%d%H%M")

outfile="$HOME/monitor/$HOSTNAME-$today.csv"
#oldfile=$HOME/monitor/$HOSTNAME.old

localip=`/sbin/ifconfig -a|grep "10.*" |grep "inet " | awk '{print $2}' |tr -d "addr:"`
eth=$(ifconfig | grep -B1 $localip | grep -v $localip | awk '{print $1}')
echo $eth


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
echo "time_stamp, ip, cpu(%), mem(%), i/o(tps), net_in(bytes/s), net_out(bytes/s)" >>$outfile

ip=`curl -s ident.me`
echo $ip

while [ $(date "+%s") -lt $end_ts ];
	sleep $intvl &

	#-------------cpu----------------
	idlecpu=`vmstat 1 $intvl |grep -v "procs" |grep -v "free" |awk '{print $15}'` &

	wait
	echo $idlecpu
	ave_idle_cpu = `echo $idlecpu | awk 'BEGIN {FS=' '}
		{
			sum=0; n=0
			for(i=1;i<=NF;i++)
				{sum+=$i; ++n}
				print sum/n
		}'`
	echo $ave_idle_cpu

	cpu=`echo "scale=2;a=100-$ave_idle_cpu; if(a<1) print 0; print a" | bc`
	echo "CPU Utilization: $cpu" 
done
