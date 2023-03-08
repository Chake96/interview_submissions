#!/bin/bash

set -e

# Define variables
UBUNTU_CORE_IMG="ubuntu-core-20-amd64.img"
KERNEL_URL="https://cloud-images.ubuntu.com/focal/current/unpacked/focal-server-cloudimg-amd64-vmlinuz-generic"
INITRD_URL="https://cloud-images.ubuntu.com/focal/current/unpacked/focal-server-cloudimg-amd64-initrd-generic"
INIT_SCRIPT="scripts/init"
INITRD_DIR="initrd-root"
INITRD_NEW="ubuntu-initrd-new"

# Define function to gracefully shut down QEMU on SIGINT
function cleanup {
  echo "Shutting down QEMU..."
  kill "${QEMU_PID}" 2>/dev/null
}

# Set trap for SIGINT signal
trap cleanup SIGINT

# Download Ubuntu Core image if not already downloaded
if [ ! -f "${UBUNTU_CORE_IMG}" ]; then
  wget "https://cdimage.ubuntu.com/ubuntu-core/20/stable/current/${UBUNTU_CORE_IMG}.xz"
  unxz "${UBUNTU_CORE_IMG}.xz"
fi

# Download kernel and initramfs from Ubuntu servers if not already downloaded
if [ ! -f "ubuntu-kernel" ]; then
  wget "${KERNEL_URL}" -O ubuntu-kernel
fi

if [ ! -f "ubuntu-initrd" ]; then
  wget "${INITRD_URL}" -O ubuntu-initrd
fi

# Check if initramfs download was successful
if ! file ubuntu-initrd; then
  echo "Failed to download initramfs file."
  exit 1
fi

# Prepare initrd-root directory and add Hello World message
# if [ ! -d "${INITRD_DIR}" ]; then
  rm -rf "${INITRD_DIR}"
  mkdir "${INITRD_DIR}"
  lz4 -dc ubuntu-initrd | (cd "${INITRD_DIR}" && cpio -id)
  printf '#!/bin/sh\n\nprintf "########################################\n#\n#\tBoot Complete!\n#\tHello World!\n#\n########################################\n"\nexec /bin/sh\n' >> "${INITRD_DIR}/${INIT_SCRIPT}"
  chmod +x "${INITRD_DIR}/${INIT_SCRIPT}"
# fi

# Create new initrd if not already created
# if [ ! -f "${INITRD_NEW}" ]; then
  (cd "${INITRD_DIR}" && find . | cpio -H newc -o | gzip -9 > "../${INITRD_NEW}")
# fi

# Boot Ubuntu Core using QEMU
qemu-system-x86_64 \
  -m 1024M \
  -nographic \
  -kernel ubuntu-kernel \
  -initrd "${INITRD_NEW}" \
  -drive "file=${UBUNTU_CORE_IMG},format=raw" \
  -append "console=ttyS0 root=/dev/sda"

# Clean up
cleanup
