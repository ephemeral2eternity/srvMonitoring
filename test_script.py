#!/usr/bin/env python
import io
import os
import sys
import csv
import time
import datetime
from subprocess import Popen

intvl = 5
period = 60
cur_path = os.path.dirname(os.path.abspath(__file__))

## read cpu, io, mem, and bw from variables stored in cur_path/scripts/var/
cpu_file = cur_path + '/scripts/var/cpu'
io_file = cur_path + '/scripts/var/io'
bw_file = cur_path + '/scripts/var/bw'
mem_file = cur_path + '/scripts/var/mem'

cmds = [ cur_path + "/scripts/cpu_monitor.sh " + str(intvl) + " " + str(period),
	 cur_path + "/scripts/io_monitor.sh " + str(intvl) + " " + str(period),
	 cur_path + "/scripts/bw_monitor.sh " + str(intvl) + " " + str(period) ]

processes = [Popen(cmd, shell=True) for cmd in cmds]

for p in processes: p.wait()

with open(cpu_file, 'r') as cpu_csv:
	cpu = list(csv.reader(cpu_csv, delimiter=' '))

with open(io_file, 'r') as io_csv:
	io = list(csv.reader(io_csv, delimiter=' '))

with open(bw_file, 'r') as bw_csv:
	bw = list(csv.reader(bw_csv, delimiter=' '))

with open(mem_file, 'r') as mem_csv:
	mem = list(csv.reader(mem_csv, delimiter=' '))

num_rows = len(cpu)

print("timestamp,  CPU Util(%),  Memory Util(%), I/O Transfers (tps), Inbound Traffic (bytes/second), Outbound Traffic (bytes/second), \
	 I/O Reads (kB/s), I/O Writes (kB/s), Total I/O Reads (kB), Total I/O Writes (kB), Total Bytes Sent (kB), Total Bytes Received (kB)" )

for i in range(num_rows):
	cur_ts = time.time()
	ts = cur_ts - (num_rows - i) * intvl
	cur_datetime = datetime.datetime.fromtimestamp(ts)
	cpu_util = float(cpu[i][0])
	mem_util = float(mem[i][0])
	io_tps = float(io[i][0])
	io_reads = float(io[i][1])
	io_writes = float(io[i][2])
	inbound_traffic = float(bw[i][0]) * 8.0 / 1024.0
	outbound_traffic = float(bw[i][1]) * 8.0 / 1024.0
	if i < 1:
		total_io_read = int(io[i][3])
		total_io_write = int(io[i][4])
	else:
		total_io_read = total_io_read + int(io[i][3])
		total_io_write = total_io_write + int(io[i][4])
	tx_bytes = int(bw[i][2])
	rx_bytes = int(bw[i][3])

	print(ts, cpu_util, mem_util, io_tps, inbound_traffic, outbound_traffic, io_reads, io_writes, total_io_read, total_io_write, tx_bytes, rx_bytes)
