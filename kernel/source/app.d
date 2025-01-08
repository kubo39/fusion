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
    dbgln("kernel: Fusion Kernel");
    dbgln("kernel: Memory map length");
    exit(0);
}
