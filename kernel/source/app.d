import ldc.attributes : naked;
import ldc.llvmasm : __asm;

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

void KernelMain()
{
    dbgln("Hello, world!");
    exit(0);
}
