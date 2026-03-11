#! /bin/bash
LOCAL_IP=$(ip addr show | grep -v '127.0.0.1' | grep -oP 'inet\s\K[\d.]+' | head -n 1)

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

sys_level_metrics(){
    echo "collecting sys metrics $1"
}
proc_level_metrics(){
    echo "Collecting proc level metrics $1"
}
cleanup(){
    echo "end APM execs + script"
}
#trap cleanup EXIT will call the cleanup function when the script exits
trap cleanup EXIT

start_apm
sys_level_metrics "wahoo"
proc_level_metrics "awooga"

