intvl=5

if [ $# -ge 1 ]; then
	intvl=$1
fi

#-------------cpu----------------
idlecpu=`vmstat 1 $intvl |grep -v "procs" |grep -v "free" |awk '{print $15}'`
ave_idle_cpu=`echo $idlecpu | awk '{sum=0; for(i=1;i<=NF;i++){sum+=$i}; print sum/NF }'`
cpu=`echo "scale=2;a=100-$ave_idle_cpu; if(a<1) print 0; print a" | bc`
echo $cpu
