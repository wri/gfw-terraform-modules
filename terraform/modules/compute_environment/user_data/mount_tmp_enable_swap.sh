MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
########################################
# NOTES
# ECS optimized AMIs come with a second EBS volume used by Docker
# This script is meant to work with ECS optimized AMI
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

exec > >(tee /dev/console) 2>&1
shopt -s nullglob

echo "mount_tmp_enable_swap.sh starting at $(date -u +%FT%TZ)"

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
echo "Found ${#local_nvme_devices[@]} local NVMe instance-store device(s): ${local_nvme_devices[*]:-none}"

#######################################
# Critical path: format and mount the first local device as ephemeral
# storage for /tmp, then signal READY. Failures here are fatal (set -e) --
# if this doesn't succeed, processes waiting on READY should keep waiting
# rather than be told a broken mount is good to use.
#######################################

set -euo pipefail

if [ "${#local_nvme_devices[@]}" -ge 1 ]; then
  data_device="${local_nvme_devices[0]}"

  mkfs.ext4 "$data_device"
  mkdir -p /mnt/ext
  mount -t ext4 "$data_device" /mnt/ext
  mkdir -p /mnt/ext/tmp

  # modify fstab to mount /tmp on the new storage.
  echo '/mnt/ext/tmp  /tmp  none  bind  0 0' >> /etc/fstab
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

set +euo pipefail

#######################################
# Best-effort: preserve whatever was already in /tmp (should be near-empty
# on a fresh instance) by copying it into the new mount before the bind
# mount above shadows it. Not on the critical path -- a failure to install
# or run rsync here is logged and skipped, not fatal.
#######################################

if command -v rsync > /dev/null 2>&1 || yum install -y rsync; then
  rsync -avPHSX /tmp/ /mnt/ext/tmp/ || echo "WARNING: rsync of pre-existing /tmp contents failed; continuing anyway." >&2
else
  echo "WARNING: could not install rsync; skipping copy of pre-existing /tmp contents." >&2
fi

########################################
# Best-effort: create swap space on the second local device, if one exists.
# Not on the critical path.
########################################

if [ "${#local_nvme_devices[@]}" -ge 2 ]; then
  swap_device="${local_nvme_devices[1]}"

  if mkswap "$swap_device" && swapon "$swap_device"; then
    # Edit your /etc/fstab file so that this swap space is automatically enabled at every system boot.
    # (propbably not nessecessary)
    echo "$swap_device  none  swap  sw  0 0" >> /etc/fstab
  else
    echo "WARNING: failed to set up swap on $swap_device; continuing anyway." >&2
  fi
fi

#########################################
# Finishing up
#########################################

# Create 0 byte file "READY" to allow processes to check if new volume is ready for use
touch /mnt/ext/tmp/READY
echo "mount_tmp_enable_swap.sh finished at $(date -u +%FT%TZ), READY touched."

--==MYBOUNDARY==--
