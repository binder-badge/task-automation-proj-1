#! /bin/bash
sys_level_metrics(){
    while true;
    do
        # gather raw stats
        adapter="wlp130s0f0"
        
        network_stats=$(ifstat $adapter --scan=1 | grep $adapter | tr -s " " | cut -d " " -f 6,8 | sed "s/K/000/g") # fetches Rx (Download) + Tx (Upload) stats
        drive_writes=$(iostat /dev/nvme0n1 | grep nvme0n1 | tr -s " " | cut -d " " -f 4) # fetches kbps written to disk 
        drive_usage=$(df / | tail -n 1 | tr -s " " | cut -d " " -f 4) # fetches how muuch free space is left on /
        echo
        echo "raw stats"
        echo "$SECONDS $network_stats $drive_writes $drive_usage"

        # parse stats to conform to project specs
        
        # split the network stats and divide into kbps
        upload=$(echo $network_stats | cut -d " " -f 2)
        # upload=$(($upload/1000))
        upload=$(awk -v val="$upload" 'BEGIN {printf "%.2f", val / 1024}')

        download=$(echo $network_stats | cut -d " " -f 1)
        # download=$(($download/1000))
        download=$(awk -v val="$download" 'BEGIN {printf "%.2f", val / 1024}')

        network_stats=$download,$upload
        
        drive_usage=$(awk -v val="$drive_usage" 'BEGIN {printf "%.2f", val / 1024}')
        
        # combine it all
        echo "final"
        # echo "$SECONDS,$network_stats,$drive_writes,$drive_usage"
        echo "$SECONDS $network_stats $drive_writes $drive_usage"
        sleep 5
    done
}
sys_level_metrics