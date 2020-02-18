#!/bin/bash
set -euo pipefail

sudo rm -f /tmp/key
curl -L -o /tmp/key https://raw.githubusercontent.com/flatcar-linux/coreos-overlay/flatcar-master/coreos-base/coreos-au-key/files/official-v2.pub.pem
sudo umount /usr/share/update_engine/update-payload-key.pub.pem || true
sudo mount --bind /tmp/key /usr/share/update_engine/update-payload-key.pub.pem
sudo sed -i "/SERVER=.*/d" /etc/coreos/update.conf
echo "SERVER=https://public.update.flatcar-linux.net/v1/update/" | sudo tee -a /etc/coreos/update.conf
sudo rm -f /tmp/release
sudo umount /usr/share/coreos/release || true
cp /usr/share/coreos/release /tmp/release
sed -E -i "s/(COREOS_RELEASE_VERSION=)(.*)/\10.0.0/" /tmp/release
sudo mount --bind /tmp/release /usr/share/coreos/release
sudo systemctl restart update-engine
update_engine_client -update
echo "Done, please reboot now"
