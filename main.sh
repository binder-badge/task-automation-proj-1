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

    adapter=$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^ens' | head -n 1)
    if [ -z "$adapter" ]; then adapter="ens192"; fi

    # kill previous ifstat instances + remove their sockets
    pkill -f ifstat 2>/dev/null
    rm -f /tmp/.ifstat.u*

    # i have no idea why but we gotta run ifstat in the background to get it to update stats in 1 second interval,
    # which we then read with another background process to read it in 5 second intervals, it honestly makes no
    # sense but its in the rubric so
    ifstat $adapter --scan=1 

    while true;
    do
        # read the last sample from the temp
        # for some reason the log file just stays the same over the time i tested this 
        # and i dont know why and at this point im just going to use the standalone version
        # network_stats=$(grep $adapter /tmp/.ifstat.u$UID | sed 's/^[ \t0-9]*//' | tr -s " ")
        network_stats=$(ifstat $adapter | grep $adapter | tr -s " " | cut -d " " -f 6,8)

        # RX Rate - column 7. convert K, M, and G to num in kbps
        download=$(echo "$network_stats" | cut -d " " -f 2 | awk '{
            if (/K$/) { sub(/K$/, ""); printf "%.2f", $1 }
            else if (/M$/) { sub(/M$/, ""); printf "%.2f", $1 * 1024 }
            else if (/G$/) { sub(/G$/, ""); printf "%.2f", $1 * 1024 * 1024 }
            else { printf "%.2f", $1 / 1024 }
        }')

        # TX Rate - column 9. convert K, M, and G to num in kbps
        upload=$(echo "$network_stats" | cut -d " " -f 1 | awk '{
            if (/K$/) { sub(/K$/, ""); printf "%.2f", $1 }
            else if (/M$/) { sub(/M$/, ""); printf "%.2f", $1 * 1024 }
            else if (/G$/) { sub(/G$/, ""); printf "%.2f", $1 * 1024 * 1024 }
            else { printf "%.2f", $1 / 1024 }
        }')

        network_stats="$download,$upload"

        drive="sda"
        drive_writes=$(iostat /dev/$drive | grep $drive | tr -s " " | cut -d " " -f 4)
        drive_usage=$(df / | tail -n 1 | tr -s " " | cut -d " " -f 4)
        drive_usage=$(awk -v val="$drive_usage" 'BEGIN {printf "%.2f", val / 1024}')

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
