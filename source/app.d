import ldc.attributes : naked;
import ldc.llvmasm;

extern (C):

alias EfiStatus = uint;
alias EfiHandle = void*;

struct EfiTableHeader
{
	ulong signature;
	uint revision;
	uint headerSize;
	uint crc32;
	uint reserved;
}

struct EfiSystemTable
{
	EfiTableHeader header;
	wchar* firmwareVendor;
	uint firmwareRevision;
	EfiHandle consoleInHandle;
	void* conIn;
	EfiHandle consoleOutHandle;
	SimpleTextOutput* conOut;
	EfiHandle standardErrorHandle;
	void* stdErr;
	void* runtimeServices;
	void* bootServices;
	uint numTableEntries;
	void* configTable;
}

struct SimpleTextOutput
{
	void* reset;
	EfiStatus function(SimpleTextOutput*, wchar*) outputString;
	void* testString;
	void* queryMode;
	EfiStatus function(SimpleTextOutput*, uint) setMode;
	void* setAttribute;
	EfiStatus function(SimpleTextOutput*) clearScreen;
	void* setCursorPos;
	void* enableCursor;
	void** mode;
}

enum : EfiStatus
{
	EfiSuccess = 0,
	EfiLoadError = 1
}

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
