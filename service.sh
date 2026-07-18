#!/system/bin/sh
MODDIR=${0%/*}

sleep 2

cp /vendor/etc/audio_policy_configuration.xml /data/local/tmp/audio_policy_configuration.xml
chcon u:object_r:vendor_configs_file:s0 /data/local/tmp/audio_policy_configuration.xml
chmod 644 /data/local/tmp/audio_policy_configuration.xml
mount --bind /data/local/tmp/audio_policy_configuration.xml /vendor/etc/audio_policy_configuration.xml

sleep 1
killall audioserver
