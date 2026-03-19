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
        # generate header for csv
        echo "Seconds,CPU,Memory" > "APM${i}_metrics.csv"
        
        #start a C executable that has name APM1, APM2, APM3, APM4, APM5, APM6 in ./project1_executables/
        ./project1_executables/APM$i $LOCAL_IP &
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

            # data_collected=$(ps -p "$pid" -o %cpu,%mem --no-headers | tr -s " " | sed "s/ +/,/g")
            data_collected=$(ps -p "$pid" -o %cpu,%mem --no-headers | sed "s/ \+/,/g" | sed "s/^,//g")
            
            if [ -n "$data_collected" ]; then
                echo "$SECONDS,$data_collected" >> "APM${process_num}_metrics.csv"
            fi
        done
        sleep 5
    done
}

############################################################
# FUNCTION: sys_level_metrics
#
# Continuously collects system metrics every 5 seconds.
#
# Metrics collected:
#   Rx
#   Tx
#   KBps written to disk
#   MBs left on system
#
# Data sources:
#   ifstat, iostat, df
#
# Output files:
#   system_metrics.csv
############################################################
sys_level_metrics(){
    echo "Seconds,Rx,Tx,Write speed,Available disk capacity" > "system_metrics.csv"
    while true;
    do
        # gather raw stats
        adapter=$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^ens' | head -n 1)
        if [ -z "$adapter" ]; then adapter="ens192"; fi
        drive="sda"

        network_stats=$(ifstat $adapter | grep $adapter | tr -s " " | cut -d " " -f 6,8 | sed "s/K/000/g") # fetches Rx (Download) + Tx (Upload) stats
        drive_writes=$(iostat /dev/$drive | grep $drive | tr -s " " | cut -d " " -f 4) # fetches kbps written to disk 
        drive_usage=$(df / | tail -n 1 | tr -s " " | cut -d " " -f 4) # fetches how muuch free space is left on /

        # parse stats to conform to project specs
        
        # split the network stats and divide into kbps
        upload=$(echo $network_stats | cut -d " " -f 2)
        upload=$(awk -v val="$upload" 'BEGIN {printf "%.2f", val}')

        download=$(echo $network_stats | cut -d " " -f 1)
        download=$(awk -v val="$download" 'BEGIN {printf "%.2f", val}')

        network_stats=$download,$upload

        # drive is in mbps unlike upload and download as per the rubric
        drive_usage=$(awk -v val="$drive_usage" 'BEGIN {printf "%.2f", val / 1024}')
        
        # combine it all
        echo "$SECONDS,$network_stats,$drive_writes,$drive_usage" >> system_metrics.csv
        sleep 5
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
        kill -9 "$pid" 2>/dev/null
        echo terminated $pid
    done

    #kills any background jobs
    for job in $(jobs -p);
    do
        kill "$job" 2>/dev/null
        echo terminated $job
    done
    exit 0
}
#trap cleanup EXIT will call the cleanup function when the script exits
trap cleanup EXIT

start_apm
#monitoruing should run in background
sys_level_metrics &
proc_level_metrics &

wait 
# keep script alive to make sure it receives the sigint to trigger cleanup script
# while [[ true ]] ; do
#     sleep 1
# done
