import ldc.attributes : naked;
import ldc.llvmasm : __asm;

import bootinfo;
import debugcon;

extern(C):
nothrow:
@nogc:

@naked noreturn exit(int status)
{
    __asm(`
    .loop:
        cli
        hlt
        jmp .loop
    `, "");
    while (true) {}
}

void KernelMain(BootInfo* bootInfo)
{
    dbg("kernel: Fusion Kernel\n");
    dbg("kernel: Memory map length: %d\n", bootInfo.physicalMemoryMap.len);
    exit(0);
}
