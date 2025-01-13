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

    dbg("bootInfo 0x%x\n", bootInfo);
    dbg("bootInfo.physicalMemoryMap 0x%x\n", &bootInfo.physicalMemoryMap);
    dbg("&bootInfo.physicalMemoryMap.entries 0x%x\n", &bootInfo.physicalMemoryMap.entries);
    dbg("bootInfo.physicalMemoryMap.entries 0x%x\n", bootInfo.physicalMemoryMap.entries);

    dbg("Memory map (%d entries)\n", bootInfo.physicalMemoryMap.len);
    dbg("   Entry");
    dbg("   Type");
    dbg("   Start");
    dbg("\n");

    foreach (i; 0 .. bootInfo.physicalMemoryMap.len)
    {
        const entry = *(cast(MemoryMapEntry*)bootInfo.physicalMemoryMap.entries + i * MemoryMapEntry.sizeof);
        dbg("   0x%x", (bootInfo.physicalMemoryMap.entries + i * MemoryMapEntry.sizeof));
        dbg("   %d", entry.type);
        dbg("   0x%x", entry.start);

        dbg("\n");
    }

    exit(0);
}
