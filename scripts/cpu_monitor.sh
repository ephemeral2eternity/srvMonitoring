intvl=1
period=5

cur_dir=$(dirname $0)
cpu_var="$cur_dir/var/cpu"

cat /dev/null > $cpu_var

if [ $# -ge 1 ]; then
	intvl=$1
fi

if [ $# -ge 2 ]; then
	period=$2
fi

iter=$((period/intvl))

#------------- cpu utilization monitoring ----------------
vmstat $intvl $iter |grep -v "procs" |grep -v "free" |awk '{ print 100 - $15 }' > $cpu_var
