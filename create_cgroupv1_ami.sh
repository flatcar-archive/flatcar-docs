#!/bin/bash
set -euo pipefail

CHANNEL=${CHANNEL-stable}
VERSION=${VERSION-current}

[ "$EUID" = "0" ] || { echo "Need to be root" > /dev/stderr ; exit 1 ; }

function end() {
  CODE="${1-1}"
  if [ "${TARGET-}" != "" ]; then
    umount "${TARGET}" 2> /dev/null || true
  fi
  if [ "${LOOP-}" != "" ]; then
    losetup -d "${LOOP}" 2> /dev/null || true
  fi
  if [ "${TARGET-}" != "" ]; then
    rmdir "${TARGET}" || true
  fi
  rm -f flatcar_production_ami_vmdk_image.vmdk.bz2 flatcar_production_ami_vmdk_image.vmdk flatcar_production_ami_vmdk_image.vmdk.img
  exit "${CODE}"
}

trap end INT TERM ERR

rm -f flatcar_production_ami_vmdk_image.vmdk.bz2
wget "https://${CHANNEL}.release.flatcar-linux.net/amd64-usr/${VERSION}/flatcar_production_ami_vmdk_image.vmdk.bz2"
bunzip2 flatcar_production_ami_vmdk_image.vmdk.bz2

PART=6
TARGET=$(mktemp -d -p /tmp --suffix -flatcar)

rm -f flatcar_production_ami_vmdk_image.vmdk.img
qemu-img convert -f vmdk -O raw flatcar_production_ami_vmdk_image.vmdk flatcar_production_ami_vmdk_image.vmdk.img
rm flatcar_production_ami_vmdk_image.vmdk
LOOP=$(losetup --partscan --find --show flatcar_production_ami_vmdk_image.vmdk.img)
mount "${LOOP}p${PART}" "$TARGET"

BASE="${TARGET}/base/base.ign"
mkdir -p "${TARGET}/base"
touch "${BASE}"
CONTENT=$(cat "${BASE}")
if [ "${CONTENT}" = "" ]; then
  CONTENT='{}'
fi
IGN_VERSION=$(echo "${CONTENT}" | { jq -r .ignition.version || true ; })
if [ "${IGN_VERSION}" = "" ]; then
  IGN_VERSION="2.3.0"
fi
echo "${CONTENT}" | jq '.storage.files += [{"filesystem": "root", "path": "/etc/systemd/system/containerd.service.d/10-use-cgroupfs.conf", "contents":{"source":"data:,%5BService%5D%0AEnvironment%3DCONTAINERD_CONFIG%3D%2Fusr%2Fshare%2Fcontainerd%2Fconfig-cgroupfs.toml"}, "mode": 420}]' | jq ".ignition.version = \"${IGN_VERSION}\"" > "${BASE}"
touch "${TARGET}"/grub.cfg
if grep -q systemd.unified_cgroup_hierarchy "${TARGET}"/grub.cfg ; then
  echo "error: found grub.cfg to contain a systemd.unified_cgroup_hierarchy setting already"
  false
fi
tee -a "${TARGET}/grub.cfg" > /dev/null <<EOF

# Customized image to provisiong with cgroup v1.
# Flatcar has migrated to cgroup v2. Your node has been kept on cgroup v1.
# Migrate at your own convenience by changing the value to '=1', or remove this
# line if you don't need to switch back ('systemd.legacy_systemd_cgroup_controller' only has effect for '=0').
# Also remove /etc/systemd/system/containerd.service.d/10-use-cgroupfs.conf when doing it.
# For more details visit:
# https://kinvolk.io/docs/flatcar-container-linux/latest/container-runtimes/switching-to-unified-cgroups
set linux_append="\$linux_append systemd.unified_cgroup_hierarchy=0 systemd.legacy_systemd_cgroup_controller"
EOF

umount "${TARGET}"
losetup -d "${LOOP}"

rm -f flatcar_production_ami_vmdk_image-cgroupv1.vmdk
qemu-img convert -f raw -O vmdk -o subformat=streamOptimized flatcar_production_ami_vmdk_image.vmdk.img flatcar_production_ami_vmdk_image-cgroupv1.vmdk

rm flatcar_production_ami_vmdk_image.vmdk.img
echo "Created flatcar_production_ami_vmdk_image-cgroupv1.vmdk from ${VERSION} ${CHANNEL}"
echo "You can upload it with ore (from https://github.com/flatcar/mantle/):"
echo 'ore --credentials-file=$CREDFILE -d aws upload --bucket=s3://$BUCKETNAME/tmp/$ARCH/$VERSION/ --board="$ARCH" --region=$REGION --ami-name="Flatcar-$CHANNEL-$VERSION cgroupv1" --ami-description="Flatcar $CHANNEL $VERSION$SUFFIX cgroupv1" --file="flatcar_production_ami_vmdk_image-cgroupv1.vmdk"'
end 0
