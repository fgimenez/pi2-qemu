#!/bin/sh
set -ex

create_image(){
    if [ ! -f pi2.img/pi2.img ]; then
	      sudo snap install --classic --edge ubuntu-image || true
	      snap known --remote model series=16 model=pi2 brand-id=canonical > pi2.model
        sudo /snap/bin/ubuntu-image -c edge -O pi2.img pi2.model
        sudo chown -R $USER:$USER pi2.img
    fi
}

extract_files(){
    if [ ! -f kernel.img ] || [ ! -f bcm2709-rpi-2-b.dtb ]; then
        (
            trap 'sudo umount $tmp && sudo rm -rf $tmp && sudo kpartx -ds pi2.img/pi2.img' EXIT
            loops=$(sudo kpartx -avs pi2.img/pi2.img | cut -d' ' -f 3)

            system_boot=$(echo "$loops" | head -1)

            tmp=$(mktemp -d)
            sudo mount /dev/mapper/$system_boot $tmp

            cp $tmp/pi2-kernel_*.snap/kernel.img .
            cp $tmp/bcm2709-rpi-2-b.dtb .
        )
    fi
}

start_machine(){
    qemu-system-arm -M raspi2 \
                    -cpu arm1176 \
                    -kernel ./kernel.img \
                    -sd ./pi2.img/pi2.img \
                    -append "rw earlyprintk loglevel=8 console=ttyAMA0,115200 dwc_otg.lpm_enable=0 root=/dev/mmcblk0p2" \
                    -dtb ./bcm2709-rpi-2-b.dtb \
                    -nographic \
                    -serial mon:stdio
}

create_image

extract_files

start_machine
