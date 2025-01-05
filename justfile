bootloader:
    dub build -b plain :bootloader --arch=x86_64-unknown-windows-msvc

kernel:
    dub build -b plain :kernel --arch=x86_64-unknown-unknown-elf-unknown

copy:
    cp build/bootx64.efi.exe diskimg/efi/boot/bootx64.efi

run: bootloader copy kernel
    qemu-system-x86_64 \
        -drive if=pflash,format=raw,file=ovmf/OVMF_CODE.fd,readonly=on \
        -drive if=pflash,format=raw,file=ovmf/OVMF_VARS.fd \
        -drive format=raw,file=fat:rw:diskimg \
        -machine q35 \
        -net none
