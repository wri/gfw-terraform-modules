MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
yum install -y rsync

# mount the ephemeral storage
# ECS optimized AMIs come with a second EBS volume used by Docker
# These volumes are mounted on /dev/nvme1n1 but don't show up in the launch template
# Ephemeral storage is mounted on dev/nvme2n1 and up
mkfs.ext4 /dev/nvme2n1
mkdir -p /mnt/ext
mount -t ext4 /dev/nvme2n1 /mnt/ext

# make temp directory for containers usage
# should be used in the Batch job definition (MountPoints)
mkdir /mnt/ext/tmp
rsync -avPHSX /tmp/ /mnt/ext/tmp/

# modify fstab to mount /tmp on the new storage.
sed -i '$ a /mnt/ext/tmp  /tmp  none bind 0 0' /etc/fstab
mount -a

# Create 0 byte file "READY" to allow processes to check if new volume is ready for use
touch /mnt/ext/tmp/READY

# make /tmp usable by everyone
chmod 777 /mnt/ext/tmp

--==MYBOUNDARY==--