#!/bin/bash

# Download latest kernel and initramfs from Ubuntu servers
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img -O ubuntu.img
wget https://cloud-images.ubuntu.com/focal/current/unpacked/focal-server-cloudimg-amd64-initrd-generic -O ubuntu-initrd
wget https://cloud-images.ubuntu.com/focal/current/unpacked/focal-server-cloudimg-amd64-vmlinuz-generic -O ubuntu-kernel

# Check if initramfs download was successful
if ! file ubuntu-initrd; then
  echo "Failed to download initramfs file."
  exit 1
fi


rm -rf initrd-root
mkdir initrd-root
cd initrd-root
lz4 -dc ../ubuntu-initrd | cpio -id
echo "blacklist floppy" >> ./etc/modprobe.d/blacklist.conf

# printf '#!/bin/sh\n\nprintf '\''\n\nBoot Complete!\n\tHello World!'\''\nexec /bin/sh' >> scripts/init
printf '#!/bin/sh\n\nprintf "########################################\n#\n#\tBoot Complete!\n#\tHello World!\n#\n########################################\n"\n/bin/sh' >> scripts/init
chmod +x scripts/init
cp scripts/init ./init

find . | cpio -H newc -o | gzip -9 > ../ubuntu-initrd-new
cd ..

# Run the Linux image using QEMU

# qemu-system-x86_64 -m 1024M -kernel ubuntu-kernel -initrd ubuntu-initrd-new -drive file=ubuntu.img,format=raw
qemu-system-x86_64 -m 1024M -nographic -monitor none -serial stdio -kernel ubuntu-kernel -initrd ubuntu-initrd-new -drive file=ubuntu.img,format=raw -append "root=/dev/sda console=ttyS0" -no-reboot
