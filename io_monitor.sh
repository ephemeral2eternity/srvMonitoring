intvl=5

if [ $# -ge 1 ]; then
	intvl=$1
fi

#-------------i/o----------------#
io_tps=`iostat 1 $intvl |grep "sda" |awk '{print $2}'`
ave_io_tps=`echo $io_tps | awk '{sum=0; for(i=1;i<=NF;i++){sum+=$i}; print sum/NF }'`
echo $ave_io_tps
