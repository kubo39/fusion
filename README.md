# Writing OS in D, porting from FusionOS

This is D uefi-based OS porting from [Writing OS in Nim](https://github.com/khaledh/khaledh.github.io/tree/main/docs/osdev) by [Fusion OS][fusionos], which is written in Nim.

## prerequiresites

- LDC - LLVM D Compiler
- QEMU
- UEFI BIOS image

```console
apt install ovmf
cp /usr/share/OVMF/OVMF_CODE.fd ovmf/
cp /usr/share/OVMF/OVMF_VARS.fd ovmf/
```

[fusionos]: https://github.com/khaledh/fusion
