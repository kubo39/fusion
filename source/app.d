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

void d_main() {}

EfiStatus efi_main(EfiHandle imgHandle, EfiSystemTable* sysTable)
{
	d_main();
	wchar* msg = cast(wchar*) "Hello, World\0"w.ptr;
	sysTable.conOut.clearScreen(sysTable.conOut);
	sysTable.conOut.outputString(sysTable.conOut, msg);
	exit(0);
	return EfiLoadError;
}
