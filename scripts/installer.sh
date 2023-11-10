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

echo "How much space do you need in MiB for the boot partition?"
read -r EFI

echo "How much space do you need in MiB for the nix partition? "
read -r  ROOT

echo "How much swap space do you need in MiB ?"
read -r  SWAP

echo "Will now partition ${DEV} with :"
echo "- Boot size ${EFI}MiB."
echo "- Nix size ${ROOT}MiB."
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

echo "Creating boot partition"
sudo parted "${DEV}" -s mkpart ESP fat32 1MiB "${EFI}"MiB
sudo parted "${DEV}" -s set 1 boot on

echo "Creating nix partition"
sudo parted "${DEV}" -s mkpart Nix ext4 "${EFI}"MiB $(("${EFI}" + "${ROOT}"))MiB

echo "Creating swap partition"
sudo parted "${DEV}" -s mkpart Swap linux-swap $(("${EFI}" + "${ROOT}"))MiB $(("${EFI}" + "${ROOT}" + "${SWAP}"))MiB

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

sudo mount --mkdir "${P1}" /mnt/boot
sudo mount --mkdir "${P2}" /mnt/nix

echo "--------------------------------------------------------------------------------"

# echo "Generation hardware configuration file"

# sudo nixos-generate-config --root /mnt --show-hardware-config | sudo tee ./config/nixos/router/hardware-configuration.nix > /dev/null

# sudo nano ./nixos/router/hardware-configuration.nix

echo "Press enter to proceed to the installation"
read -r

sudo nixos-install --flake "github:ArthurDelbarre/Nix#router" --no-write-lock-file --show-trace
