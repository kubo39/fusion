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
    dbg("\n\nkernel: Fusion Kernel\n");
    dbg("\n");

    dbg("Memory map (%d entries)\n", bootInfo.physicalMemoryMap.len);
    foreach (i; 0 .. bootInfo.physicalMemoryMap.len)
    {
        const entry = (*bootInfo.physicalMemoryMap.entries)[i];
        dbg("   %d: type=%d start=0x%x nframes=%d\n", i, entry.type, entry.start, entry.nframes);
    }
    exit(0);
}
