#!/bin/sh

cd `cd $(dirname $0); pwd`/config

tuner_config_file="$1.yml"

if [ -e "tuners/$tuner_config_file" ]; then
  if [ -e "tuners.yml" ]; then
    rm tuners.yml
  fi

  ln -s tuners/$tuner_config_file tuners.yml

  if [ $? = 0 ]; then
    echo "Linked config/tuners.yml to config/tuners/$tuner_config_file"
  else
    echo "Failed to create link."
    exit 1
  fi
else
  echo "There is no file (tuners/$tuner_config_file)"
  exit 1
fi


device_opts=""
device_index=0

for device in `cat tuners.yml | grep command | sed -e "s/.*\-\-device \([0-9a-zA-Z_\/]*\).*/\1/g"`; do
  device_opts="${device_opts}--device ${device}:${device} "

  device_index=$(($device_index + 1))
  if [ $(($device_index % 2)) = 0 ]; then
    device_opts="${device_opts}\\
"
  fi
done

echo
echo '\nYou can start with the following command.'
echo "$ docker run -d -p 40772:40772 -p 9229:9229 --name=mirakurun --restart=unless-stopped \\
-v /etc/localtime:/etc/localtime:ro -v /etc/timezone:/etc/timezone:ro \\
-v mirakurun_data:/data -v `pwd`:/config \\
${device_opts}\
--device /dev/bus:/dev/bus --cap-add=SYS_NICE ureo/tsd-mirakurun"
