# Increase disk size on EC2 instance

## Usage of LVM and device mapper
See detail [here](./LVM.md)

This is the mechanism used on our Linux instance with the SSD disk.

## Resize general way

**Steps resizing a Linux/Windows system**
- Switch off instance
- Detach each volume, make a note of the used device (p.e. /dev/sda1, /dev/zxdc, etc)
- Make a snapshot of each volume
- Create a new volume for each snapshot, specify the new desired size
- Attach each volume using same device as the recorded
- Switch machine on
- Log in to the instance and resize the filesystem

**Steps using AWS Console**


## Extend Linux filesystem after resizing a Volume

Reference,
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/recognize-expanded-volume-linux.html

Steps
- Verify each filesystem
- Check volumes must be extended using "lsblk", as example
  The root volume, /dev/nvme0n1, has a partition, /dev/nvme0n1p1. While the size of the root volume reflects the new size, 16 GB, the size of the partition reflects the original size, 8 GB, and must be extended before you can extend the file system.

  The volume /dev/nvme1n1 has no partitions. The size of the volume reflects the new size, 30 GB.
- Increase volumes with partition using "growpart" and the partition number in this case "1"
- Verify increased size

```js
%> df -hT
Filesystem      Type  Size  Used Avail Use% Mounted on
/dev/nvme0n1p1  xfs   8.0G  1.6G  6.5G  20% /
/dev/nvme1n1    xfs   8.0G   33M  8.0G   1% /data

%> lsblk
NAME          MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
nvme1n1       259:0    0  30G  0 disk /data
nvme0n1       259:1    0  16G  0 disk
└─nvme0n1p1   259:2    0   8G  0 part /
└─nvme0n1p128 259:3    0   1M  0 part

%> sudo growpart /dev/nvme0n1p1 1

%> lsblk
NAME          MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
nvme1n1       259:0    0  30G  0 disk /data
nvme0n1       259:1    0  16G  0 disk
└─nvme0n1p1   259:2    0  16G  0 part /
└─nvme0n1p128 259:3    0   1M  0 part

%> fdisk -l
...
Disk /dev/sda: 223.58 GiB, 240057409536 bytes, 468862128 sectors
Disk model: KINGSTON SA400S3
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: C67C9DFE-8AE0-4575-9BA7-AFB5A7744858

Device       Start       End   Sectors   Size Type
/dev/sda1     2048      4095      2048     1M BIOS boot
/dev/sda2     4096   2101247   2097152     1G Linux filesystem
/dev/sda3  2101248 468858879 466757632 222.6G Linux filesystem
...
```
