#!/bin/bash
# the usage and help messages:
script="single_monitor.sh"
help="Description: $0 will call '$script' for each .cfg file that has been passed to it and then drop to background. Created by Svilen Savov (svilen@svilen.org)"
usage="Usage: $0 {start|stop|restart|help} {.cfg|all} ; possible .cfg files found: $(echo *.cfg), or use all"

# Check what must be done and execute it:

# Basic input checks:
if [ "$1" == "help" ]; then
	echo $help
	echo $usage
	exit 1;
elif [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
	echo $usage
	exit 1;
elif [ ! -z "$1" ] && [ -z "$2" ]; then
	echo "Error: you should specify a config file !"
	echo $usage
	exit 1;
elif [ -d "$2" ]; then
	echo "Error: $2 is a directory and cannot be started !"
	echo $usage
	exit 1;
elif [ "$2" == "all" ]; then
	cameras=`ls config/*.cfg`
elif [ -r "$2" ]; then
	cameras=$2
elif [ ! -r "$2" ]; then
	echo "Error: $2 does not exist and cannot be started !"
	echo $usage
	exit 1;
fi

case $1 in
	restart)
		# Create logs folder
		if [ ! -d logs ]; then
			mkdir logs
		fi;
		for i in $cameras; do
			cfg_name="$(basename $i)"
			echo "Stopping the monitoring for $i..."
			echo "$(date)|$i|Stopping the monitoring script for $i" >> logs/$cfg_name.log
			pkill -f "/bin/bash $script $i"
		done;
		;&
	start)
		# Create logs folder
		if [ ! -d logs ]; then
			mkdir logs
		fi;
		for i in $cameras; do
			cfg_name="$(basename $i)"
			echo "Starting the monitoring for $cfg_name ($i)..."
			echo "$(date)|$cfg_name|Starting the monitoring script for $cfg_name" >> logs/$cfg_name.log
			/bin/bash $script $i >> logs/foshi.log 2>&1 &
			echo "Monitoring started for $cfg_name ($i)"
		done;
		;;
	stop)
		# Create logs folder
		if [ ! -d logs ]; then
			mkdir logs
		fi;
		for i in $cameras; do
			cfg_name="$(basename $i)"
			echo "Stopping the monitoring for $cfg_name..."
			echo "$(date)|$cfg_name|Stopping the monitoring script for $cfg_name" >> logs/$cfg_name.log
			pkill -f "/bin/bash $script $i"
		done;
		;;
	*)
		echo $help
		echo $usage
		exit 1;
		;;
esac;