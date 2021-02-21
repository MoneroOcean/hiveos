#!/usr/bin/env bash

. $MINER_DIR/$CUSTOM_MINER/h-manifest.conf

API_TIMEOUT=2
stats_raw=`curl --connect-timeout 2 --max-time $API_TIMEOUT --silent --noproxy '*' http://127.0.0.1:$MINER_API_PORT/stat`

if [[ $? -ne 0  || -z $stats_raw ]]; then
  echo -e "${YELLOW}Failed to read $miner stats_raw from localhost:${MINER_API_PORT}${NOCOLOR}"
  khs=0
  stats="null"
  exit 1
fi

khs=`echo $stats_raw | jq -r '.devices[].speed' | awk '{s+=$1} END {printf("%.4f",s/1000)}'` #sum up and convert to khs
local ac=$(jq '[.devices[].accepted_shares] | add' <<< "$stats_raw")
local rj=$(jq '[.devices[].rejected_shares] | add' <<< "$stats_raw")
local inv=$(jq '[.devices[].invalid_shares] | add' <<< "$stats_raw")

#All fans speed array
local fan=$(jq -r ".fan | .[]" <<< $gpu_stats)
#All temp array
local temp=$(jq -r ".temp | .[]" <<< $gpu_stats)

#All busid array
local all_bus_ids_array=(`echo "$gpu_detect_json" | jq -r '[ . | to_entries[] | select(.value) | .value.busid [0:2] ] | .[]'`)
#Formating arrays

#gminer's busid array
local bus_id_array=(`jq -r '.devices[].bus_id[5:7]' <<< "$stats_raw"`)
local bus_numbers=()
local idx=0
for gpu in ${bus_id_array[@]}; do
   bus_numbers[idx]=$((16#$gpu))
   idx=$((idx+1))
done

fan=`tr '\n' ' ' <<< $fan`
temp=`tr '\n' ' ' <<< $temp`
#IFS=' ' read -r -a bus_id_array <<< "$bus_id_array"
IFS=' ' read -r -a fan <<< "$fan"
IFS=' ' read -r -a temp <<< "$temp"

#busid equality
local fans_array=
local temp_array=
for ((i = 0; i < ${#all_bus_ids_array[@]}; i++)); do
  for ((j = 0; j < ${#bus_id_array[@]}; j++)); do
    if [[ "$(( 0x${all_bus_ids_array[$i]} ))" -eq "$(( 0x${bus_id_array[$j]} ))" ]]; then
      fans_array+=("${fan[$i]}")
      temp_array+=("${temp[$i]}")
    fi
  done
done

stats=$(jq -c \
    --argjson temp "`echo "${temp_array[@]}" | jq -s . | jq -c .`" \
    --argjson fan "`echo "${fans_array[@]}" | jq -s . | jq -c .`" \
    --arg ac "$ac" --arg rj "$rj" --arg iv "$inv" \
    --arg inv_gpu "$(echo $stats_raw | jq -r '.devices[].invalid_shares' | tr '\n' ';')" \
    --argjson bus_numbers "`echo "${bus_numbers[@]}" | jq -sc .`" \
    --arg algo `echo $stats_raw | jq -r '.algorithm'`  \
    --arg ver `echo $stats_raw | jq -r '.miner' | awk '{ print $2 }'` \
    '{hs: [.devices[].speed], hs_units: "hs", ar: [$ac, $rj, $iv, $inv_gpu], $algo,
      $bus_numbers, $temp, $fan, uptime: .uptime, $ver}' <<< "$stats_raw")

[[ -z $khs ]] && khs=0
[[ -z $stats ]] && stats="null"
