#!/bin/sh

set -e

ZEPHYR_BINARY=build/zephyr/zephyr.bin

usage(){
    echo "Usage: $1 </dev/sd*> </path/to/zephyrproject/zephyr/>";
    exit 1;
}

if [ -z $1 ]; then
    usage $0
fi

if [ -z $2 ]; then
    usage $0
fi

ZEPHYR_BINARY="$2/${ZEPHYR_BINARY}";

SDDEVICE=$1

# account for partition table etc.
ZEPHYR_SECTORSTART=2048
ZEPHYR_BIN_SECTORS=$(ls -l --block-size=512 $ZEPHYR_BINARY | cut -d " " -f5)
ZEPHYR_BIN_SECTORS=$((ZEPHYR_SECTORSTART + ZEPHYR_BIN_SECTORS))
PART_TWO_START=$((ZEPHYR_BIN_SECTORS + 512))

echo "Creating a partition with zephyr from $ZEPHYR_SECTORSTART to $ZEPHYR_BIN_SECTORS and an empty FAT32 partition from $ZEPHYR_BIN_SECTORS to the device end!"
sgdisk --clear -g --new=1:$ZEPHYR_SECTORSTART:$ZEPHYR_BIN_SECTORS --new=2:$PART_TWO_START:0 --typecode=1:3000 --typecode=2:0700 $SDDEVICE

SDDEVICE_PART1=$(lsblk $SDDEVICE -no PATH | head -2 | tail -1)
SDDEVICE_PART2=$(lsblk $SDDEVICE -no PATH | head -3 | tail -1)

echo "Copying zephyr image"
dd if=$ZEPHYR_BINARY of=$SDDEVICE_PART1 status=progress oflag=sync bs=1M

echo "Creating FAT filesystem on second partition!"
mkfs.vfat -F 32 $SDDEVICE_PART2
