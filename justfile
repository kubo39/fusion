bootloader:
    dub build -b plain :bootloader --arch=x86_64-unknown-windows-msvc

kernel:
    dub build -b plain :kernel --arch=x86_64-unknown-unknown-elf-unknown --force

run: bootloader kernel
    mkdir -p diskimg/efi/boot
    mkdir -p diskimg/efi/fusion
    cp build/bootx64.efi.exe diskimg/efi/boot/bootx64.efi
    cp build/kernel.bin diskimg/efi/fusion/kernel.bin
    qemu-system-x86_64 \
        -drive if=pflash,format=raw,file=ovmf/OVMF_CODE.fd,readonly=on \
        -drive if=pflash,format=raw,file=ovmf/OVMF_VARS.fd \
        -drive format=raw,file=fat:rw:diskimg \
        -machine q35 \
        -net none
