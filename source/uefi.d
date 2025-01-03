module uefi;

extern (C):

__gshared EfiSystemTable* sysTable;

void consoleClear()
{
    cast(void)sysTable.conOut.clearScreen(sysTable.conOut);
}

void consoleOut(wchar* s)
{
    cast(void)sysTable.conOut.outputString(sysTable.conOut, s);
}

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
