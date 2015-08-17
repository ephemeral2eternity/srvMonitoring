#!/bin/bash

localip=`/sbin/ifconfig -a|grep "10.*" |grep inet | awk '{print $2}' |tr -d "addr:"`
outfile=$HOME/monitor/$HOSTNAME.csv
outfile2=$HOME/monitor/$HOSTNAME.simple.csv
oldfile=$HOME/monitor/$HOSTNAME.old

eth=$(ifconfig | grep -B1 $localip | grep -v $localip | awk '{print $1}')
echo $eth

sec=5

in_first=$(cat /proc/net/dev | grep $eth -m 1 | awk '{print $2}')
out_first=$(cat /proc/net/dev | grep $eth -m 1 | awk '{print $10}')

#initialization
cat /dev/null > $oldfile

#------------hostname-----------
#name= `hostname`
#echo $HOSTNAME | grep "client"
if echo $HOSTNAME | grep -q "cache"
then
	type="cache_agent"
#fi
else 
	type="client"
fi;

echo $type

#-------------cpu----------------
idlecpu=`top -b -n 1  | grep -E 'Cpu' | awk -F ',' '{print $4}' | awk '{print $1}' | awk -F '%' '{print $1}'`
echo $idlecpu
cpu=`echo "scale=2;a=100-$idlecpu; if(a<1) print 0; print a" | bc`
echo $cpu 

#-------------mem----------------
totalmem=`top -b -n 1 | grep -E 'Mem' | cut -d "," -f 1 | cut -d ":" -f 2 | awk '{print $1}' | awk -F 'k' '{print $1}'` 
echo $totalmem
usedmem=`top -b -n 1 | grep -E 'Mem' | cut -d "," -f 2 | awk '{print $1}' | awk -F 'k' '{print $1}' ` 
echo $usedmem
mem=`echo "scale=2;a=$usedmem/$totalmem*100; if(a<1) print 0; print a" | bc`
echo $mem

#------------disk----------------
totaldisk=`df | grep /dev | awk '{print $2}' | awk 'BEGIN{sum=0} {sum+=$1}END{print sum}'`
useddisk=`df | grep /dev | awk '{print $3}' | awk 'BEGIN{sum=0} {sum+=$1}END{print sum}'`
disk=`echo "scale=2; a=$useddisk/$totaldisk*100; if(a<1) print 0; print a" | bc`
echo $disk

#------------net-----------------
in_end=$(cat /proc/net/dev | grep $eth -m 1 | awk '{print $2}')
out_end=$(cat /proc/net/dev | grep $eth -m 1 | awk '{print $10}')

sum_rx=`echo "scale=2;$in_end-$in_first" | bc`
sum_tx=`echo "scale=2;$out_end-$out_first" | bc`
aver_rx=`echo "scale=2;a=$sum_rx/$sec; if(a<1) print 0; print a" | bc`
aver_tx=`echo "scale=2;a=$sum_tx/$sec; if(a<1) print 0; print a" | bc`
echo $aver_rx
echo $aver_tx

cat /dev/null > $outfile
cat /dev/null > $outfile2

#ip=`/sbin/ifconfig -a|grep "10.1.*" |grep inet | awk '{print $2}' |tr -d "addr:"`
ip=`curl ident.me`
echo $ip
group=1

echo \"ip\",\"group\",\"type\",\"cpu\",\"mem\",\"disk\",\"net_in\",\"net_out\" >>$outfile2
echo \"$ip\",\"$group\",\"$type\",\"$cpu\",\"$mem\",\"$disk\",\"$aver_rx\",\"$aver_tx\" >> $outfile2

echo \"name\",\"value\" >> $outfile
echo \"ip\",\"$ip\" >> $outfile
echo \"group\",\"$group\" >> $outfile
echo \"type\",\"$type\" >> $outfile
echo \"cpu\",\"$cpu\" >> $outfile
echo \"mem\",\"$mem\" >> $outfile
echo \"disk\",\"$disk\" >> $outfile
echo \"net_in\",\"$aver_rx\" >> $outfile
echo \"net_out\",\"$aver_tx\" >> $outfile

#########compare
diff $outfile2 $oldfile > /dev/null
comp_value=$?
echo $comp_value

cp $outfile2 $oldfile

cat $outfile2

