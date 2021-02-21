#!/usr/bin/env bash

test -z $CUSTOM_PASS && CUSTOM_PASS=x
local conf="--user=\"$CUSTOM_TEMPLATE\" --pass=\"$CUSTOM_PASS\""

# merge user config options into main config
if [[ ! -z $CUSTOM_USER_CONFIG ]]; then
	conf+=" $CUSTOM_USER_CONFIG"
fi

for url in $CUSTOM_URL; do
	conf+=" --pool=$url"
done

export GMINER="./gminer --server localhost:3333 --user \"$CUSTOM_TEMPLATE\" --pass \"$CUSTOM_PASS\" --logfile $CUSTOM_LOG_BASENAME.log --api $MINER_API_PORT"

conf+=" --ethash=\"$GMINER --algo ethash --proto stratum\""
conf+=" --kawpow=\"$GMINER --algo kawpow\""
conf+=" --c29s=\"$GMINER --algo cuckaroo29s\""
conf+=" --c29b=\"$GMINER --algo cuckaroo29b\""

mkfile_from_symlink $CUSTOM_CMDLINE_FILENAME
echo "$conf" > $CUSTOM_CMDLINE_FILENAME
