#! /bin/bash
LOCAL_IP=$(ip addr show | grep -v '127.0.0.1' | grep -oP 'inet\s\K[\d.]+' | head -n 1)

############################################################
# FUNCTION: start_apm
#
# Launches the 6 APM executables:
#   APM1, APM2, APM3, APM4, APM5, APM6
#
# Each process is started in the background and its PID
# is stored in the arr_pid array for later monitoring
# and cleanup.
############################################################
start_apm(){
    arr_pid=()
    for i in {1..6}
    do
        #start a C executable that has name APM1, APM2, APM3, APM4, APM5, APM6 in ../project1_executables/
        ../project1_executables/APM$i $LOCAL_IP &
        arr_pid+=("$!")
    done
    echo "PIDs: ${arr_pid[@]}"
}

############################################################
# FUNCTION: proc_level_metrics
#
# Continuously collects process metrics every 5 seconds.
#
# Metrics collected:
#   %CPU
#   %MEM
#
# Data source:
#   ps command
#
# Output files:
#   APM1_metrics.csv
#   APM2_metrics.csv
#   ...
#   APM6_metrics.csv
############################################################
proc_level_metrics(){
    while true;
    do
        for index in "${!arr_pid[@]}"
        do
            pid=${arr_pid[$index]}
            process_num=$((index+1))

            data_collected=$(ps -p "$pid" -o %cpu,%mem --no-headers)
            
            echo "$data_collected" >> "APM${process_num}_metrics.csv"
        done
        sleep 5
    done
}

sys_level_metrics(){
    while true;
    do
        # gather raw stats
        network_stats=$(ifstat ens | grep ens | tr -s " " | cut -d " " -f 6,8)
        drive_writes=$(iostat /dev/sda | grep sda | tr -s " " | cut -d " " -f 4)
        drive_usage=$(df / | tail -n 1 | tr -s " " | cut -d " " -f 4)
        
        # parse stats to conform to project specs
        network_stats=network_stats/1000 # 
        drive_usage=drive_usage/1000
        drive_usage=drive_usage/1000
        
        # combine it all
        data_collected=$network_stats + $drive_usage + $drive_writes
        echo "$SECONDS $data_collected" >> "system_metrics.csv"
        sleep 30
    done
}

############################################################
# FUNCTION: cleanup
#
# Called when script is terminated (Ctrl+C).
#
# Responsibilities:
# 1. Kill all APM processes that were spawned
# 2. Kill background monitoring jobs
############################################################
cleanup(){
    echo "Cleaning up..."
    for pid in "${arr_pid[@]}"
    do
        kill "$pid"
    done

    #kills any background jobs
    kill $(jobs -p) 2>/dev/null
    echo terminated "${arr_pid[@]}"
    exit 0
}
#trap cleanup EXIT will call the cleanup function when the script exits
trap cleanup SIGINT

start_apm
#monitoruing should run in background
sys_level_metrics &
proc_level_metrics &

