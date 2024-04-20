#!/bin/sh

bcas_atr_prefix='3BF01200FF9181B1'
bcas_fail='true'

for atr in `pcsc_scan -c | grep 'ATR' | cut -d ' ' -f 4-11 | sed -e 's/ //g'`; do
  if [ "${atr}" = "${bcas_atr_prefix}" ]; then
    bcas_fail='false'
    break
  fi
done

if [ "${bcas_fail}" = 'true' ]; then
  exit 1
fi

devices=`cat /config/tuners.yml | grep command | sed -e "s/.*\-\-device \([0-9a-zA-Z_\/]*\).*/\1/g"`

for device in $devices; do
  if [ ! -e ${device} ]; then
    exit 1
  fi
done

exit 0
