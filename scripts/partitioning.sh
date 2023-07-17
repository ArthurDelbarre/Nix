#!/usr/bin/env bash

echo "--------------------------------------------------------------------------------"

sudo fdisk -l | less

echo "--------------------------------------------------------------------------------"
echo "Detected the following devices:"
echo

i=0
for device in $(sudo fdisk -l | grep "^Disk /dev" | awk "{print \$2}" | sed "s/://"); do
    echo "[$i] $device"
    i=$((i+1))
    DEVICES[$i]=$device
done

echo
read -p "Which device do you wish to install on? " DEVICE

DEV=${DEVICES[$(($DEVICE+1))]}

echo "--------------------------------------------------------------------------------"

read -p "How much space do you need in MiB for the EFI partition? " EFI
read -p "How much space do you need in MiB for the root partition? " ROOT
read -p "How much swap space do you need in MiB ? " SWAP

echo "Will now partition ${DEV} with :"
echo "- EFI size ${EFI}MiB."
echo "- Root size ${Root}MiB."
echo "- Swap size ${SWAP}MiB."

read -p "Processing to the partitioning ? Yes" ANSWER

if [ "$ANSWER" != "Yes" ]; then
    echo "Operation cancelled."
    exit
fi

echo "Zapping disk"
sudo sgdisk --zap-all ${DEV}

echo "Creating gpt label"
sudo parted ${DEV} -s mklabel gpt

echo "Creating EFI partition"
sudo parted ${DEV} -s mkpart primary efi fat32 1MiB ${EFI}MiB
sudo parted ${DEV} -s set 1 esp on

echo "Creating root partition"
sudo parted ${DEV} -s mkpart primary root ext4 ${EFI}MiB $((${EFI} + ${ROOT}))MiB

echo "Creating swap partition"
sudo parted ${DEV} -s mkpart primary swap linux-swap $((${EFI} + ${ROOT}))MiB $((${EFI} + ${ROOT} + ${SWAP}))MiB

echo "--------------------------------------------------------------------------------"

echo "Getting created partition names..."

i=1
for part in $(sudo fdisk -l | grep $DEV | grep -v "," | awk '{print $1}'); do
    echo "[$i] $part"
    PARTITIONS[$i]=$part
    i=$((i+1))
done

P1=${PARTITIONS[1]}
P2=${PARTITIONS[2]}

echo "--------------------------------------------------------------------------------"
echo "Formatting partitions"

echo "Formatting ${P1} to fat32"

sudo mkfs.fat -F 32 -n boot ${P1}

echo "Formatting ${P2} to ext4"

sudo mkfs.ext4 -L nixos ${P2}

echo "Enabling swap on ${P3}"

sudo mkswap -L swap ${P3}
sudo swapon ${P3}

echo "Mounting filesystems..."

sudo mount ${P2} /mnt
sudo mount --mkdir ${P1} /mnt/efi

echo "--------------------------------------------------------------------------------"
read -p "Press enter to quit"
