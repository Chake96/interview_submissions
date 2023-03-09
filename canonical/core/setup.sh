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
INIT_CONTENT='#!/bin/sh\n\nprintf "########################################\n#\n#\tBoot Complete! Use Cntrl-C to Quit\n#\tHello World!\n#\n########################################\n"\nexec /bin/sh\n'

# Functions
download_file() {
  local url=$1
  local file=$2
  if [[ ! -f "$file" ]]; then
    wget "$url" -O "$file"
  fi
}

extract_initrd() {
  if [[ ! -d "initrd-root" ]]; then
    mkdir initrd-root
    cd initrd-root
    lz4 -dc "../$INITRD_FILE" | cpio -id
  else
    cd initrd-root
  fi
}

add_blacklisted_module() {
  printf 'blacklist floppy\n' >> "$BLACKLIST_FILE"
}

add_custom_init_script() {
  mkdir -p "scripts"
  printf "${INIT_CONTENT}" > "$INIT_SCRIPT_FILE"

  chmod +x "$INIT_SCRIPT_FILE"
  cp "$INIT_SCRIPT_FILE" "$INIT_FILE"
}

create_new_initrd() {
    find . | cpio -H newc -o | gzip -9 > "../$INITRD_NEW_FILE"
}

check_ubuntu_core_presence() {
  if ! grep -q "Ubuntu Core" "$IMG_FILE"; then
    printf "Ubuntu Core not found in $IMG_FILE.\n"
    exit 1
  fi
}

cleanup() {
  echo "Cleaning up and exiting QEMU"
  pkill qemu-system-x86_64
}

# Set up trap to gracefully exit QEMU on script exit
trap cleanup EXIT

# Download files if necessary
download_file "$IMG_URL" "$IMG_FILE"
download_file "$INITRD_URL" "$INITRD_FILE"
download_file "$KERNEL_URL" "$KERNEL_FILE"

# Check if initrd download was successful
if ! file "$INITRD_FILE"; then
  printf "Failed to download initramfs file.\n"
  exit 1
fi

# Create temporary directory and extract initrd
extract_initrd

# Add blacklisted module to initrd
add_blacklisted_module

# Add custom init script to initrd
add_custom_init_script

# Create new initrd
create_new_initrd

cd ..

# Check if Ubuntu Core is present in the image
check_ubuntu_core_presence


# Run QEMU
qemu-system-x86_64 \
  -m "$MEMORY" \
  -nographic \
  -monitor none \
  -serial stdio \
  -kernel "$KERNEL_FILE" \
  -initrd "$INITRD_NEW_FILE" \
  -drive file="$IMG_FILE",format=raw \
  -append "root=$ROOT_DEVICE console=ttyS0"