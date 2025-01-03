import ldc.attributes : naked;
import ldc.llvmasm;

import uefi;

extern (C):

@naked void exit(int status)
{
    __asm(`
    .loop:
        cli
        hlt
        jmp .loop
    `, "");
}

void EfiMainInner()
{
    uefi.sysTable = sysTable;
    consoleClear();
}

void Dmain() {}

EfiStatus efi_main(EfiHandle imgHandle, EfiSystemTable* sysTable)
{
    Dmain();

    EfiMainInner();

    // String literals have a '\0' appended.
    // https://dlang.org/spec/expression.html#string_literals
    wchar* msg = cast(wchar*) "Hello, World!"w.ptr;
    consoleOut(msg);
    exit(0);
    return EfiLoadError;
}
