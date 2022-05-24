#!/bin/bash
# the usage and help messages:
usage="-Single instance: $0 {config_file.cfg} ; possible .cfg files found: $(echo *.cfg)"
help="-Better run ./foshi.csh help ..."
debug="-Print debug information: $0 {config_file.cfg} debug"
# Basic input checks:
if [ "$1" == "help" ]; then
        echo $usage
	echo "or"
	echo $debug
        exit 1;
############################
# EXECUTE THE DEBUG LOGIC
############################
elif [ "$2" == "debug" ]; then
        set -o noglob
        source "$1"
        set +o noglob
        cam_alarm_total="$cam_alarm1 $cam_alarm2"
        echo "Printing debug information (no record triggering):"
        echo
        echo "Camera cam_alarm_total is: $cam_alarm_total"
        echo
        echo "Manual $cam_alarm1 check URL is: curl -s -m 2 \"$cam_ip/cgi-bin/CGIProxy.fcgi?cmd=getDevState&usr=$cam_usr&pwd=$cam_pwd\" | grep $cam_alarm1 | sed 's/[^0-9]//g'"
        echo "Current $cam_alarm1 check is: $( curl -s -m 2 "$cam_ip/cgi-bin/CGIProxy.fcgi?cmd=getDevState&usr=$cam_usr&pwd=$cam_pwd" | grep $cam_alarm1 | sed 's/[^0-9]//g' ) /// (1=no alarm, 2=alarm)"
        echo "Camera $cam_alarm2 check URL is: curl -s -m 2 \"$cam_ip/cgi-bin/CGIProxy.fcgi?cmd=getDevState&usr=$cam_usr&pwd=$cam_pwd\" | grep $cam_alarm2 | sed 's/[^0-9]//g'"
        echo "Current $cam_alarm2 check is: $( curl -s -m 2 "$cam_ip/cgi-bin/CGIProxy.fcgi?cmd=getDevState&usr=$cam_usr&pwd=$cam_pwd" | grep $cam_alarm2 | sed 's/[^0-9]//g' ) /// (1=no alarm, 2=alarm)"
        echo "Motioneye manual trigger URL is: curl -s --user $meye_auth \"$meye_host/$meye_cam/config/set?emulate_motion=1 && sleep 1 && curl -s --user $meye_auth \"$meye_host/$meye_cam/config/set?emulate_motion=0\""
        echo
        while true; do
                if [ "$(curl -s -m 2 "$cam_ip/cgi-bin/CGIProxy.fcgi?cmd=getDevState&usr=$cam_usr&pwd=$cam_pwd" | grep \<result\> | sed 's/[^0-9]//g')" == "0" ]; then
                        echo "$(date)|$1|Connection to $meye_cam ($cam_ip) has been established, checking for new alarms every 1 second..."
                        while [ "$(curl -s -m 2 "$cam_ip/cgi-bin/CGIProxy.fcgi?cmd=getDevState&usr=$cam_usr&pwd=$cam_pwd" | grep \<result\> | sed 's/[^0-9]//g')" == "0" ]; do
                                alarm_check=$(curl -s -m 2 "$cam_ip/cgi-bin/CGIProxy.fcgi?cmd=getDevState&usr=$cam_usr&pwd=$cam_pwd")
                                for i in $cam_alarm_total; do
                                        alarm_result=$(grep $i <<< $alarm_check | sed 's/[^0-9]//g')
                                        echo "$(date)|$1|Current $i check is: $alarm_result /// (1=no alarm, 2=alarm)"
                                        if [ $alarm_result == "2" ]; then
                                                echo "$(date)|$1|$i event on $meye_cam ($cam_ip), triggering Motioneye ($meye_host) alarm !"
                                                sleep $cam_alarm_timer
                                        else
                                                sleep $cam_alarm_timer
                                        fi;
                                done;
                        done;
                else
                        echo "$(date)|$1|Connection to $meye_cam ($cam_ip) has been lost, retrying in 60 seconds..."
                        sleep 60
                fi;
        done;
        exit 1;
elif [ "$#" != "1" ]; then
	echo "Error: only 1 config file can be chosen (except of you want to enter debug mode): "
        echo $usage
	echo "or"
        echo $debug
        exit 1;
elif [ -r "$1" ]; then
        camera=$1
elif [ -d "$1" ]; then
        echo "Error: $1 is a directory and cannot be started !"
        echo $usage
        exit 1;
else
        echo "Error: configuration file '$1' not found !"
        echo $usage
        exit 1;
fi;

############################
# EXECUTE THE MAIN LOGIC
############################
# Load the variables from the .cfg file:
set -o noglob
source "$1"
set +o noglob
cam_alarm_total="$cam_alarm1 $cam_alarm2"
cfg_name="$(basename $1)"
# Create logs folder
if [ ! -d logs ]; then
    mkdir logs
fi;
# Create a startup entries
echo "$(date)|$cfg_name|Initiating monitoring for $meye_cam ($cam_ip) via Motioneye ($meye_host), appending to log file: logs/$cfg_name.log"
echo "$(date)|$cfg_name|Initiating monitoring for $meye_cam ($cam_ip) via Motioneye ($meye_host), verifying the connection..." >> "logs/$cfg_name.log"
# Cycle the main loop endlessly, checking for events every 1 second:
while true; do
        if [ "$(curl -s -m 2 "$cam_ip/cgi-bin/CGIProxy.fcgi?cmd=getDevState&usr=$cam_usr&pwd=$cam_pwd" | grep \<result\> | sed 's/[^0-9]//g')" == "0" ]; then
                echo "$(date)|$cfg_name|Connection to $meye_cam ($cam_ip) has been established, checking for new alarms every 1 second..." >> "logs/$cfg_name.log"
                while [ "$(curl -s -m 2 "$cam_ip/cgi-bin/CGIProxy.fcgi?cmd=getDevState&usr=$cam_usr&pwd=$cam_pwd" | grep \<result\> | sed 's/[^0-9]//g')" == "0" ]; do
                        alarm_check=$(curl -s -m 2 "$cam_ip/cgi-bin/CGIProxy.fcgi?cmd=getDevState&usr=$cam_usr&pwd=$cam_pwd")
                        for i in $cam_alarm_total; do
                                alarm_result=$(grep $i <<< $alarm_check | sed 's/[^0-9]//g')
                                if [ $alarm_result == "2" ]; then
                                        echo "$(date)|$cfg_name|$i event on $meye_cam ($cam_ip), triggering Motioneye ($meye_host) alarm !" >> "logs/$cfg_name.log"
                                        curl -s --user $meye_auth "$meye_host/$meye_cam/config/set?emulate_motion=1" -o /dev/null && sleep 1 && curl -s --user $meye_auth "$meye_host/$meye_cam/config/set?emulate_motion=0" -o /dev/null
                                        sleep $cam_alarm_timer
                                else
                                        sleep $cam_alarm_timer
                                fi;
                        done
                done
        else
                echo "$(date)|$cfg_name|Connection to $meye_cam ($cam_ip) has been lost, retrying in 60 seconds..." >> "logs/$cfg_name.log"
                sleep 60
        fi;
done;
exit 0