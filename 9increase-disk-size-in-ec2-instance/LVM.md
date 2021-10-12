# Linux LVM (Logical Volume Management)

Reference,
- https://linoxide.com/lvm-configuration-linux/

Extend/Resize LVM partition in linux
- https://linoxide.com/how-extend-resize-lvm-partition-linux/

Mount a Filesystem
- https://linoxide.com/how-to-mount-drive-in-linux/

Remove a LV
- https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/logical_volume_manager_administration/lv_remove

## LVM concepts

- Physical Volume (PV): it is a whole disk or a partition of a disk
- Volume Group (VG): corresponds to one or more PV
- Logical Volume (LV): represents a portion of a VG. A LV can only belong to one VG. It’s on a LV that we can create a file system.

## LVM Commands

### Display
Display the physical volumes

```js
%> sudo pvdisplay
  /dev/sdb: open failed: No medium found
  /dev/sdb: open failed: No medium found
  --- Physical volume ---
  PV Name               /dev/sda3
  VG Name               ubuntu-vg
  PV Size               <222.57 GiB / not usable 0   
  Allocatable           yes 
  PE Size               4.00 MiB
  Total PE              56977
  Free PE               28488
  Allocated PE          28489
  PV UUID               qzH8zZ-Ts8j-WJi1-e9v6-YyTZ-0E5M-kwNLfd

# OR

%> sudo pvs
  /dev/sdb: open failed: No medium found
  /dev/sdb: open failed: No medium found
  PV         VG        Fmt  Attr PSize    PFree  
  /dev/sda3  ubuntu-vg lvm2 a--  <222.57g 111.28g

```

Display Volume groups (VG)

```js
sudo vgdisplay
  /dev/sdb: open failed: No medium found
  /dev/sdb: open failed: No medium found
  --- Volume group ---
  VG Name               ubuntu-vg
  System ID             
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  2
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               1
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <222.57 GiB
  PE Size               4.00 MiB
  Total PE              56977
  Alloc PE / Size       28489 / <111.29 GiB
  Free  PE / Size       28488 / 111.28 GiB
  VG UUID               GMIAyA-EZVb-XTfD-CCa1-4Ywt-dQ1q-3PcmQZ

#OR

%> sudo vgs
  /dev/sdb: open failed: No medium found
  /dev/sdb: open failed: No medium found
  VG        #PV #LV #SN Attr   VSize    VFree  
  ubuntu-vg   1   1   0 wz--n- <222.57g 111.28g
```

Display Logical volumes (LV)

Logical Volume
A volume group (VG) is divided up into logical volumes (LV). So if you have created VG earlier then you can create logical volumes from that VG

```js
%> sudo lvdisplay
  --- Logical volume ---
  LV Path                /dev/ubuntu-vg/ubuntu-lv
  LV Name                ubuntu-lv
  VG Name                ubuntu-vg
  LV UUID                kaM3FD-3Bli-cj5G-h22F-5ZPw-6ahK-IxYNad
  LV Write Access        read/write
  LV Creation host, time ubuntu-server, 2020-09-10 07:44:36 -0500
  LV Status              available
  # open                 1
  LV Size                <111.29 GiB
  Current LE             28489
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:0

```

###  Create LV

```js
#Create a new LV "lv_test" of 10 gigabytes on an existent VG "ubuntu-vg"

%> sudo lvcreate -L 10G -n lv_test ubuntu-vg
  Logical volume "lv_test" created.

# List LV

%> sudo lvdisplay
  --- Logical volume ---
  LV Path                /dev/ubuntu-vg/ubuntu-lv
  LV Name                ubuntu-lv
  VG Name                ubuntu-vg
 ...
   
  --- Logical volume ---
  LV Path                /dev/ubuntu-vg/lv_test
  LV Name                lv_test
  VG Name                ubuntu-vg
  LV UUID                D3LcqJ-vu75-94PP-GVwj-6oJA-ICKJ-YUQCl3
  LV Write Access        read/write
  LV Creation host, time ubuntu, 2021-10-08 07:05:41 -0500
  LV Status              available
  # open                 0
  LV Size                10.00 GiB
  Current LE             2560
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:1

# OR

%> sudo lvs
  LV        VG        Attr       LSize    Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv_test   ubuntu-vg -wi-a-----   10.00g                                                    
  ubuntu-lv ubuntu-vg -wi-ao---- <111.29g  
```

### Activate a LV

For activate a Logical Volume

```js
%> sudo lvchange -ay /dev/ubuntu-vg/lv_test
```

For activate a Volume group

```js
%> sudo vgchange -ay ubuntu-vg
2 logical volume(s) in volume group "ubuntu-vg" now active

%> sudo lvs
  LV        VG        Attr       LSize    Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv_test   ubuntu-vg -wi-a-----   10.00g                                                    
  ubuntu-lv ubuntu-vg -wi-ao---- <111.29g             
```

## Usage of LV

Convert format logical partition to ext3 filesystem

```js
%> sudo mke2fs -j /dev/ubuntu-vg/lv_test
mke2fs 1.45.5 (07-Jan-2020)
Discarding device blocks: done                            
Creating filesystem with 2621440 4k blocks and 655360 inodes
Filesystem UUID: c3560a05-10ac-4958-8afe-c35e921cd40c
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done 
```

Mount the volume to a "/tmp/test" directory

```js
%>  sudo mount /dev/ubuntu-vg/lv_test /tmp/test

# Validate device mounted

%> df -k
Filesystem                        1K-blocks     Used Available Use% Mounted on
udev                                3925088        0   3925088   0% /dev
tmpfs                                794540     3604    790936   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv 114333860 94520424  13962508  88% /
...
/dev/mapper/ubuntu--vg-lv_test     10255672    23096   9708288   1% /tmp/test
```

Commands to scan PVs, LVs, VGs

```js
%> sudo lvscan
  ACTIVE            '/dev/ubuntu-vg/ubuntu-lv' [<111.29 GiB] inherit
  ACTIVE            '/dev/ubuntu-vg/lv_test' [10.00 GiB] inherit

%> sudo vgscan  
  Found volume group "ubuntu-vg" using metadata type lvm2

%> sudo pvscan 
  PV /dev/sda3   VG ubuntu-vg       lvm2 [<222.57 GiB / 101.28 GiB free]
  Total: 1 [<222.57 GiB] / in use: 1 [<222.57 GiB] / in no VG: 0 [0   ]
```

## Extend LVM partition

### Extend LVM using existing disk

Steps,
- Show details of Logical Volume, get the name of LV
- Unmount the partition
- Extend LV, suppose we want to add 100Gb
- Resize the filesystem

```js
%> sudo vgdisplay -v

  --- Volume group ---
  VG Name               ubuntu-vg
 ...   
  --- Logical volume ---
  LV Path                /dev/ubuntu-vg/ubuntu-lv
  ...   
  --- Logical volume ---
  LV Path                /dev/ubuntu-vg/lv_test
  ...   
  --- Physical volumes ---
  PV Name               /dev/sda3     
  PV UUID               qzH8zZ-Ts8j-WJi1-e9v6-YyTZ-0E5M-kwNLfd
  PV Status             allocatablev
# If RHEL 3 required to unmount
%> sudo unmount /dev/ubuntu-vg/ubuntu-lv

%> sudo lvextend -L+100G /dev/ubuntu-vg/ubuntu-lv
Size of logical volume ubuntu-vg/ubuntu-lv changed from <111.29 GiB (28489 extents) to <211.29 GiB (54089 extents).
  Logical volume ubuntu-vg/ubuntu-lv successfully resized.

# On RHEL 4, use command ext2online
%> sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
resize2fs 1.45.5 (07-Jan-2020)
Filesystem at /dev/ubuntu-vg/ubuntu-lv is mounted on /; on-line resizing required
old_desc_blocks = 14, new_desc_blocks = 27
The filesystem on /dev/ubuntu-vg/ubuntu-lv is now 55387136 (4k) blocks long.

#If RHEL 3, mount you partition again
%> sudo mount /dev/ubuntu-vg/ubuntu-lv /

%> sudo vgdisplay -v
  --- Volume group ---
  VG Name               ubuntu-vg
 ...
  VG Size               <222.57 GiB
  PE Size               4.00 MiB
  Total PE              56977
  Alloc PE / Size       56957 / <222.49 GiB
  Free  PE / Size       20 / 80.00 MiB
  VG UUID               GMIAyA-EZVb-XTfD-CCa1-4Ywt-dQ1q-3PcmQZ
  --- Logical volume ---
  LV Path                /dev/ubuntu-vg/ubuntu-lv
 ...
  LV Size                <222.49 GiB
  ...
  --- Physical volumes ---
  PV Name               /dev/sda3     
  PV UUID               qzH8zZ-Ts8j-WJi1-e9v6-YyTZ-0E5M-kwNLfd
  PV Status             allocatable
  Total PE / Free PE    56977 / 20

%> df -Ph
Filesystem                         Size  Used Avail Use% Mounted on
...
/dev/mapper/ubuntu--vg-ubuntu--lv  219G   90G  119G  44% /
...
```

### Deleting LV

Steps,
- Identify the LV to delete
- Unmount the filesystem
- Delete the LV

```js
%> df -Ph
%> sudo umount /dev/ubuntu-vg/lv_test
%> sudo lvremove /dev/ubuntu-vg/lv_test
Do you really want to remove and DISCARD active logical volume ubuntu-vg/lv_test? [y/n]: y
  Logical volume "lv_test" successfully removed

%> sudo vgdisplay -v
```

### Mounting existing partition 

Steps,
- Identify LV and if is not mounted
- Validate /tmp/armando not mounted
- Mounting filesystem

```js
# Identify LV and if is not mounted
%> sudo vgdisplay -v
 ...   
  --- Logical volume ---
  LV Path                /dev/ubuntu-vg/lv_test
  ...   
%> df -Ph
#Validate /tmp/armando not mounted

# Mounting filesystem
%> sudo mkdir /tmp/armando
%> sudo chmod armando /tmp/armando
%> sudo mount /dev/ubuntu-vg/lv_test /tmp/armando

#Validate filesystem was mounted
%> df -Ph

```

