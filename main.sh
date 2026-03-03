#! /bin/bash
echo "testing 123"
echo "shriya is testing" 
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
