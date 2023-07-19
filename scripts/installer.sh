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
echo "Which device do you wish to install on? "
read -r DEVICE

DEV=${DEVICES[$((DEVICE + 1))]}

echo "--------------------------------------------------------------------------------"

echo "How much space do you need in MiB for the EFI partition?"
read -r EFI

echo "How much space do you need in MiB for the root partition? "
read -r  ROOT

echo "How much swap space do you need in MiB ?"
read -r  SWAP

echo "Will now partition ${DEV} with :"
echo "- EFI size ${EFI}MiB."
echo "- Root size ${ROOT}MiB."
echo "- Swap size ${SWAP}MiB."

echo "Processing to the partitioning ? Yes"
read -r ANSWER

if [ "$ANSWER" != "Yes" ]; then
    echo "Operation cancelled."
    exit
fi

echo "Zapping disk"
sudo sgdisk --zap-all "${DEV}"

echo "Creating gpt label"
sudo parted "${DEV}" -s mklabel gpt

echo "Creating EFI partition"
sudo parted "${DEV}" -s mkpart efi fat32 1MiB "${EFI}"MiB
sudo parted "${DEV}" -s set 1 esp on

echo "Creating root partition"
sudo parted "${DEV}" -s mkpart root ext4 "${EFI}"MiB $(("${EFI}" + "${ROOT}"))MiB

echo "Creating swap partition"
sudo parted "${DEV}" -s mkpart swap linux-swap $(("${EFI}" + "${ROOT}"))MiB $(("${EFI}" + "${ROOT}" + "${SWAP}"))MiB

echo "--------------------------------------------------------------------------------"

echo "Getting created partition names..."

i=1
for part in $(sudo fdisk -l | grep "$DEV" | grep -v "," | awk '{print $1}'); do
    echo "[$i] $part"
    PARTITIONS[$i]=$part
    i=$((i+1))
done

P1=${PARTITIONS[1]}
P2=${PARTITIONS[2]}
P3=${PARTITIONS[3]}

echo "--------------------------------------------------------------------------------"
echo "Formatting partitions"

echo "Formatting ${P1} to fat32"

sudo mkfs.fat -F 32 -n boot "${P1}"

echo "Formatting ${P2} to ext4"

sudo mkfs.ext4 -L nixos "${P2}"

echo "Enabling swap on ${P3}"

sudo mkswap -L swap "${P3}"
sudo swapon "${P3}"

echo "Mounting filesystems..."

sudo mount "${P2}" /mnt
sudo mount --mkdir "${P1}" /mnt/efi

echo "--------------------------------------------------------------------------------"

echo "Generation hardware configuration file"

sudo nixos-generate-config --root /mnt

sudo nano /mnt/etc/nixos/hardware-configuration.nix

echo "Press enter to proceed to the installation"
read -r

sudo sh -c 'cd /mnt && nixos-install --flake "github:ArthurDelbarre/Nix#router" -I hardware-config=/mnt/etc/nixos/hardware-configuration.nix --no-write-lock-file'
