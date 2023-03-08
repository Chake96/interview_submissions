#!/bin/bash

#needed: bison, libssl-dev, flex, libelf-dev, 


if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--version)
      shift
      VERSION="$1"
      ;;
    *)
      echo "Usage: $0 [-v|--version <version>]"
      exit 1
      ;;
  esac
  shift
done

# Set default version if not specified
if [ -z "$VERSION" ]; then
  VERSION="5.16.2"
fi


set -e # Exit immediately if a command exits with a non-zero status.

# Define variables
IMAGE_SIZE="1G"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v${VERSION%%.*}.x/linux-$VERSION.tar.xz"
ROOTFS_URL="http://ftp.debian.org/debian/dists/buster/main/installer-amd64/current/images/netboot/debian-installer/amd64/linux"
ROOTFS_IMAGE="rootfs.img"
KERNEL_IMAGE="bzImage"
# QEMU_ARGS="-nographic -monitor none -serial stdio"
QEMU_ARGS="-serial stdio"


# Create a blank disk image
dd if=/dev/zero of=disk.img bs=1 count=0 seek="$IMAGE_SIZE"

# Create a partition table and a single partition on the disk image
echo -e "o\nn\np\n1\n\n\nw" | fdisk disk.img

# Map the partition as a loop device
DEVICE=$(losetup --show -f -P disk.img)



# # Format the partition with ext4
mkfs.ext4 "${DEVICE}"

#create file directory
mkdir -p /mnt/rootfs
mount "${DEVICE}" /mnt/rootfs

# # Download and extract the Linux kernel source
if [ ! -f linux.tar.xz ]; then
  curl "$KERNEL_URL" -o linux.tar.xz
else
  curl -N -z linux.tar.xz "$KERNEL_URL" -o linux.tar.xz
fi
tar -xf linux.tar.xz

# # Build the kernel
cd $"linux-$VERSION"
make defconfig
make -j$(nproc)

# # Copy the kernel image to the current directory
cp arch/x86/boot/bzImage ../"$KERNEL_IMAGE"
cd ../

if [ ! -d etc/initramfs-tools/hooks ]; then
  mkdir -p etc/initramfs-tools/hooks
fi

# printf "#!/bin/sh\necho \"Hello World\"\n" > etc/initramfs-tools/hooks/helloworld
# printf "#!/bin/sh\nexec >/dev/ttyS0 2>&1\n\nfunction hello_world {echo Hello World;}\n\ntrap hello_world EXIT\n" > etc/initramfs-tools/hooks/helloworld
SCRIPT="#!/bin/sh
exec >/dev/ttyS0 2>&1

hello_world() {
  echo 'Hello World'
}

trap hello_world EXIT
"
mkdir -p etc/initramfs-tools/hooks
# printf "%s" "$SCRIPT" > etc/initramfs-tools/hooks/helloworld

chmod +x etc/initramfs-tools/hooks/helloworld
#generate the initrd for the kernel image
# sudo apt-get install initramfs-tools -y -q #install initramfs-tools
cp -r /etc/initramfs-tools etc/
rm -f initrd.img
sudo mkinitramfs -o initrd.img -d etc/initramfs-tools #generate initrd.img
# Start QEMU with the disk image, kernel image and initrd
qemu-system-x86_64 -m 1024 -initrd initrd.img \
                            -drive file=disk.img -kernel bzImage \
                            -append "root=/dev/sda rw console=ttyS0 nodiratime"\
                            -nographic -monitor none -serial stdio

# printf '\n\nhello world\n\n'
losetup -d "$DEVICE"
# rm -f disk.img
# rm -f "$KERNEL_IMAGE"
# rm -f initrd.gz
# rm -rf linux*
