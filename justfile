compile:
    dub build

copy:
    cp build/bootx64.efi.exe diskimg/efi/boot/bootx64.efi

run: compile copy
    qemu-system-x86_64 \
        -drive if=pflash,format=raw,file=ovmf/OVMF_CODE.fd,readonly=on \
        -drive if=pflash,format=raw,file=ovmf/OVMF_VARS.fd \
        -drive format=raw,file=fat:rw:diskimg \
        -machine q35 \
        -net none
