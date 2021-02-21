#!/usr/bin/env bash

. $MINER_DIR/$CUSTOM_MINER/h-manifest.conf

API_TIMEOUT=2
stats_raw=`curl --connect-timeout 2 --max-time $API_TIMEOUT --silent --noproxy '*' http://127.0.0.1:$MINER_API_PORT/api.json`

if [[ $? -ne 0 || -z $stats_raw ]]; then
  echo -e "${YELLOW}Failed to read $miner from localhost:${MINER_API_PORT}${NOCOLOR}"
  khs=0
  stats="null"
  exit 1
fi
  
[[ `echo $stats_raw | jq -r '.connection.uptime'` -lt 260 ]] && head -n 150 ${CUSTOM_LOG_BASENAME}.log > ${CUSTOM_LOG_BASENAME}_head.log
local cpu_threads=`cat ${CUSTOM_LOG_BASENAME}_head.log | grep "cpu" | grep "READY threads" | tail -1 | awk '{print $6}' | cut -d '/' -f 1`
local bus_ids=
local l_temps=
local l_fans=
local cpu_temp=`cpu-temp`
[[ $cpu_temp = "" ]] && cpu_temp=null
if [[ $cpu_threads -gt 0 ]]; then
  for ((i = 0; i < $cpu_threads; i++)); do
    bus_ids+='null,'
    l_temps+="$cpu_temp,"
    l_fans+='null,'
  done
fi
bus_ids="[${bus_ids%%,}]"
l_temps="[${l_temps%%,}]"
l_fans="[${l_fans%%,}]"

khs=`echo $stats_raw | jq -r '.hashrate.total[0]' | awk '{print $1/1000}'`
local ac=$(jq '.results.shares_good' <<< "$stats_raw")
local rj=$(( $(jq '.results.shares_total' <<< "$stats_raw") - $ac ))
stats=$(jq \
       --argjson temp "$l_temps" --argjson fan "$l_fans" \
       --arg ac "$ac" --arg rj "$rj" \
       --arg hs_units "hs" \
       --arg algo `echo $stats_raw | jq -r '.algo'` \
       --argjson bus_numbers "$bus_ids" \
  '{hs: [.hashrate.threads[][0]], $hs_units, algo: .algo, $temp, $fan, uptime: .connection.uptime,
    ar: [$ac, $rj], $bus_numbers, ver: .version}' <<< "$stats_raw")

[[ -z $khs ]] && khs=0
[[ -z $stats ]] && stats="null"
