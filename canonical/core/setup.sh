#!/bin/bash

set -e

# Variables
IMG_URL="https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
INITRD_URL="https://cloud-images.ubuntu.com/focal/current/unpacked/focal-server-cloudimg-amd64-initrd-generic"
KERNEL_URL="https://cloud-images.ubuntu.com/focal/current/unpacked/focal-server-cloudimg-amd64-vmlinuz-generic"
IMG_FILE="ubuntu.img"
INITRD_FILE="ubuntu-initrd"
KERNEL_FILE="ubuntu-kernel"
INITRD_NEW_FILE="ubuntu-initrd-new"
BLACKLIST_FILE="etc/modprobe.d/blacklist.conf"
INIT_FILE="init"
INIT_SCRIPT_FILE="scripts/init"
MEMORY="1024M"
ROOT_DEVICE="/dev/sda"

# Download files if necessary
if [[ ! -f "${IMG_FILE}" ]]; then
  wget "${IMG_URL}" -O "${IMG_FILE}"
fi

if [[ ! -f "${INITRD_FILE}" ]]; then
  wget "${INITRD_URL}" -O "${INITRD_FILE}"
fi

if [[ ! -f "${KERNEL_FILE}" ]]; then
  wget "${KERNEL_URL}" -O "${KERNEL_FILE}"
fi

# Check if initrd download was successful
if ! file "${INITRD_FILE}"; then
  printf "Failed to download initramfs file.\n"
  exit 1
fi

# Create temporary directory and extract initrd
if [[ ! -d "initrd-root" ]]; then
  mkdir initrd-root
  cd initrd-root
  lz4 -dc "../${INITRD_FILE}" | cpio -id
else
  cd initrd-root
fi

# Add blacklisted module to initrd
printf 'blacklist floppy\n' >> "${BLACKLIST_FILE}"

# Add custom init script to initrd
mkdir -p "scripts"
printf '#!/bin/sh\n\nprintf "########################################\n#\n#\tBoot Complete!\n#\tHello World!\n#\n########################################\n"\n/bin/sh' >> "${INIT_SCRIPT_FILE}"
chmod +x "${INIT_SCRIPT_FILE}"
cp "${INIT_SCRIPT_FILE}" "${INIT_FILE}"

# Create new initrd
if [[ ! -f "../${INITRD_NEW_FILE}" ]]; then
  find . | cpio -H newc -o | gzip -9 > "../${INITRD_NEW_FILE}"
fi

cd ..

# Check if Ubuntu Core is present in the image
if ! grep -q "Ubuntu Core" "${IMG_FILE}"; then
  printf "Ubuntu Core not found in ${IMG_FILE}.\n"
  exit 1
fi

# Run QEMU
qemu-system-x86_64 \
  -m "${MEMORY}" \
  -nographic \
  -monitor none \
  -serial stdio \
  -kernel "${KERNEL_FILE}" \
  -initrd "${INITRD_NEW_FILE}" \
  -drive file="${IMG_FILE}",format=raw \
  -append "root=${ROOT_DEVICE} console=ttyS0"
