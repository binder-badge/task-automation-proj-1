#! /bin/bash
LOCAL_IP=$(ip addr show | grep -v '127.0.0.1' | grep -oP 'inet\s\K[\d.]+' | head -n 1)

start_apm(){
    echo "start APM execs"
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
start_apm
sys_level_metrics "wahoo"
proc_level_metrics "awooga"
cleanup
