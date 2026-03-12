#! /bin/bash
sys_level_metrics(){
    while true;
    do
        # gather raw stats
        adapter="wlp4s0"
        network_stats=$(ifstat $adapter | grep $adapter | tr -s " " | cut -d " " -f 6,8 | sed "s/K/000/g") # ifstat truncates the numbers to ###K if over 6 digits
        drive_writes=$(iostat /dev/sda | grep sda | tr -s " " | cut -d " " -f 4)
        drive_usage=$(df / | tail -n 1 | tr -s " " | cut -d " " -f 4)
        
        # parse stats to conform to project specs
        # eval network_stats=$((network_stats/1000)) # 
        eval drive_writes=$((drive_writes/1000))
        eval drive_usage=$((drive_usage/1000))
        
        # combine it all
        # data_collected=$network_stats + $drive_usage + $drive_writes
        # echo "$SECONDS $data_collected" >> "system_metrics.csv"
        echo "$SECONDS $network_stats $drive_writes $drive_usage"
        # echo ; echo "$network_stats" ; echo "$drive_writes" ; echo "$drive_usage"
        sleep 5
    done
}
sys_level_metrics