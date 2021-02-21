#!/usr/bin/env bash

conf=$(cat $MINER_DIR/$CUSTOM_MINER/config_global.json | envsubst)

# enable miner http api to use it in h-stats.sh
http=$(cat <<EOF
	{
		"http": {
			"enabled": true,
			"host": "127.0.0.1",
			"port": $MINER_API_PORT,
			"access-token": null,
			"restricted": true
		},
		"log-file": "$CUSTOM_LOG_BASENAME.log"
	}
EOF
)

conf=$(jq -s '.[0] * .[1]' <<< "$conf $http")

# merge user config options into main config
if [[ ! -z $CUSTOM_USER_CONFIG ]]; then
	while read -r line; do
		[[ -z $line ]] && continue
		conf=$(jq -s '.[0] * .[1]' <<< "$conf {$line}")
	done <<< "$CUSTOM_USER_CONFIG"
fi

# merge pools into main config
local pools='[]'

for url in $CUSTOM_URL; do
	pool=$(cat <<EOF
		{
			"algo": null,
			"coin": null,
			"url": "$url",
			"user": "$CUSTOM_TEMPLATE",
			"pass": "$CUSTOM_PASS",
			"rig-id": "$WORKER_NAME",
			"nicehash": false,
			"keepalive": true,
			"enabled": true,
			"tls": false,
			"tls-fingerprint": null,
			"daemon": false,
			"self-select": false
		}
EOF
	)
	pools=`jq --null-input --argjson pools "$pools" --argjson pool "$pool" '$pools + [$pool]'`
done

if [[ -z $pools || $pools == '[]' || $pools == 'null' ]]; then
	echo -e "${RED}No pools configured, using default${NOCOLOR}"
else
	pools=`jq --null-input --argjson pools "$pools" '{"pools": $pools}'`
	conf=$(jq -s '.[0] * .[1]' <<< "$conf $pools")
fi

mkfile_from_symlink $CUSTOM_CONFIG_FILENAME
echo "$conf" | jq . > $CUSTOM_CONFIG_FILENAME