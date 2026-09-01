MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
########################################
# NOTES
# ECS optimized AMIs come with a second EBS volume used by Docker
# For this script is meant to work with ECS optimized AMI
# and instance types with at least 1 ephemeral storage devices ie r5d, c5d etc.

# For instances with two or more ephemeral storage devices (r5d.4xlarge/
# c5d.12xlarge and up, or any instance type with 2+ local NVMe devices) the
# second device found is used as swap drive; any further devices beyond the
# first two are left unused (this script doesn't stripe/combine multiple
# local devices into one larger volume).

# EBS-backed NVMe devices report model "Amazon Elastic Block Store"; local
# instance-store devices report "Amazon EC2 NVMe Instance Storage" -- this
# is AWS's own documented,
# reliable way to tell them apart regardless of enumeration order (see
# "Identify instance store volumes attached to Amazon EC2 Linux instances"
# on repost.aws).
#########################################

#!/bin/bash
set -euo pipefail
shopt -s nullglob

yum install -y rsync

#######################################
# Find local instance-store NVMe devices (never EBS, including the root
# volume), in whatever order the kernel happened to enumerate them.
#######################################

local_nvme_devices=()
for model_file in /sys/class/nvme/nvme*/model; do
  if grep -q "Instance Storage" "$model_file"; then
    ctrl_name=$(basename "$(dirname "$model_file")")   # e.g. "nvme3"
    dev="/dev/${ctrl_name}n1"                           # one namespace per controller
    if [ -b "$dev" ]; then
      local_nvme_devices+=("$dev")
    fi
  fi
done

#######################################
# Mount the first local device as ephemeral storage for /tmp
#######################################

if [ "${#local_nvme_devices[@]}" -ge 1 ]; then
  data_device="${local_nvme_devices[0]}"

  mkfs.ext4 "$data_device"
  mkdir -p /mnt/ext
  mount -t ext4 "$data_device" /mnt/ext

  # make temp directory for containers usage
  # should be used in the Batch job definition (MountPoints)
  mkdir /mnt/ext/tmp
  rsync -avPHSX /tmp/ /mnt/ext/tmp/

  # modify fstab to mount /tmp on the new storage.
  sed -i '$ a /mnt/ext/tmp  /tmp  none  bind  0 0' /etc/fstab
  mount -a

  # make /tmp usable by everyone
  chmod 777 /mnt/ext/tmp
else
  echo "WARNING: no local NVMe instance-store devices found on this" >&2
  echo "instance -- /tmp will stay on the root volume. This shouldn't" >&2
  echo "happen for any instance type this launch template's instance_types" >&2
  echo "should be set to; if it does, that's worth investigating rather" >&2
  echo "than silently proceeding." >&2
  mkdir -p /mnt/ext/tmp
  chmod 777 /mnt/ext/tmp
fi

########################################
# Create swap space on the second local device, if one exists
########################################

if [ "${#local_nvme_devices[@]}" -ge 2 ]; then
  swap_device="${local_nvme_devices[1]}"

  # Set up a Linux swap area on the device with the mkswap command.
  mkswap "$swap_device"

  # Enable the new swap space.
  swapon "$swap_device"

  # Edit your /etc/fstab file so that this swap space is automatically enabled at every system boot.
  # (propbably not nessecessary)
  sed -i "\$ a $swap_device  none  swap  sw  0 0" /etc/fstab
fi

#########################################
# Finishing up
#########################################

# Create 0 byte file "READY" to allow processes to check if new volume is ready for use
touch /mnt/ext/tmp/READY

--==MYBOUNDARY==--
