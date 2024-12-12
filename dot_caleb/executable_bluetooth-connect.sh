#!/bin/bash
# This expects env var DEVICE_ADDRESSES to be set. Example:
#   DEVICE_ADDRESSES="00-14-22-01-23-45 00-14-22-01-23-46"

IFS=' ' read -r -a ADDRESSES_ARRAY <<< "$DEVICE_ADDRESSES"

for DEVICE_ADDRESS in "${ADDRESSES_ARRAY[@]}"; do
  echo "Connecting to ${DEVICE_ADDRESS}"
  blueutil --connect "${DEVICE_ADDRESS}"
  echo "Connection attempt finished"
done

