#!/usr/bin/env bash

export GPU_MAX_HEAP_SIZE=100
export GPU_MAX_ALLOC_PERCENT=100
export GPU_SINGLE_ALLOC_PERCENT=100

DEBIAN_FRONTEND=noninteractive apt install -y nodejs
eval ./mm.js /run/hive/miners/custom/mo_gminer_mm.json $(< ./mo_gminer.conf)
