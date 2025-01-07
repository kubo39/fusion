module uefi;

extern (C):

__gshared EfiSystemTable* sysTable;

void consoleClear()
{
    cast(void)sysTable.conOut.clearScreen(sysTable.conOut);
}

void consoleOut(inout(wchar)[] s)
{
    cast(void)sysTable.conOut.outputString(sysTable.conOut, s.ptr);
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
    EfiBootServices* bootServices;
    uint numTableEntries;
    void* configTable;
}

struct SimpleTextOutput
{
    void* reset;
    EfiStatus function(SimpleTextOutput*, inout(wchar)*) outputString;
    void* testString;
    void* queryMode;
    EfiStatus function(SimpleTextOutput*, uint) setMode;
    EfiStatus function(SimpleTextOutput*, uint) setAttribute;
    EfiStatus function(SimpleTextOutput*) clearScreen;
    void* setCursorPos;
    void* enableCursor;
    void** mode;
}

enum
{
    EFI_BLACK = 0,
    EFI_BLUE = 1,
    EFI_GREEN = 2,
    EFI_RED = 4,
    EFI_YELLOW = 14,
    EFI_WHITE = 15,
}

enum : EfiStatus
{
    EfiSuccess = 0,
    EfiLoadError = 1
}

struct EfiLoadedImageProtocol
{
    uint revision;
    EfiHandle parentHandle;
    EfiSystemTable* systemTable;
    // Source location of the image
    EfiHandle deviceHandle;
    void* filePath;
    void* reserved;
    // Image's load options
    uint loadOptionsSize;
    void* loadOptions;
    // Location where image was loaded
    void* imageBase;
    ulong imageSize;
    EfiMemoryType imageCodeType;
    EfiMemoryType imageDataType;
    void* unload;
}

 enum EfiMemoryType
 {
    EfiReservedMemory,
    EfiLoaderCode,
    EfiLoaderData,
    EfiBootServicesCode,
    EfiBootServicesData,
    EfiRuntimeServicesCode,
    EfiRuntimeServicesData,
    EfiConventionalMemory,
    EfiUnusableMemory,
    EfiACPIReclaimMemory,
    EfiACPIMemoryNVS,
    EfiMemoryMappedIO,
    EfiMemoryMappedIOPortSpace,
    EfiPalCode,
    EfiPersistentMemory,
    EfiUnacceptedMemory,
    OsvKernelCode = 0x80000000,
    OsvKernelData = 0x80000001,
    OsvKernelStack = 0x80000002,
    EfiMaxMemoryType,
 }

struct EfiBootServices
{
    EfiTableHeader hdr;
    // task priority services
    void* raiseTpl;
    void* restoreTpl;
    // memory services
    EfiStatus function(
        EfiAllocateType, EfiMemoryType, uint, EfiPhysicalAddress*
    ) allocatePages;
    void* freePages;
    EfiStatus function(
        uint*,
        EfiMemoryDescriptor*,
        uint*,
        uint*,
        uint*
    ) getMemoryMap;
    EfiStatus function(
        EfiMemoryType, uint, void*
    ) allocatePool;
    void* freePool;
    // event & timer services
    void* createEvent;
    void* setTimer;
    void* waitForEvent;
    void* signalEvent;
    void* closeEvent;
    void* checkEvent;
    // protocol handler services
    void* installProtocolInterface;
    void* reinstallProtocolInterface;
    void* uninstallProtocolInterface;
    EfiStatus function(EfiHandle, EfiGuid, void*) handleProtocol;
    void* reserved;
    void* registerProtocolNotify;
    void* locateHandle;
    void* locateDevicePath;
    void* installConfigurationTable;
    // image services
    void* loadImage;
    void* startImage;
    void* exit;
    void* unloadImage;
    EfiStatus function(
        EfiHandle, uint
    ) exitBootServices;
    // misc services
    void* getNextMonotonicCount;
    void* stall;
    void* setWatchdogTimer;
    // driver support services
    void* connectController;
    void* disconnectController;
    // open and close protocol services
    void* openProtocol;
    void* closeProtocol;
    void* openProtocolInformation;
    // library services
    void* protocolsPerHandle;
    void* locateHandleBuffer;
    void* locateProtocol;
    void* installMultipleProtocolInterfaces;
    void* uninstallMultipleProtocolInterfaces;
    // 32-bit CRC services
    void* calculateCrc32;
    // misc services
    void* copyMem;
    void* setMem;
    void* createEventEx;
}

struct EfiMemoryDescriptor
{
    EfiMemoryType type;
    EfiPhysicalAddress physicalStart;
    EfiVirtualAddress virtualStart;
    ulong numberOfPages;
    ulong attribute;
}

enum EfiAllocateType
{
    AllocateAnyPages,
    AllocateMaxAddress,
    AllocateAddress,
    MaxAllocateType    
}

alias EfiPhysicalAddress = ulong;
alias EfiVirtualAddress = ulong;

struct EfiGuid
{
    uint data1;
    ushort data2;
    ushort data3;
    ubyte[8] data4;
}

immutable EfiGuid EfiLoadedImageProtocolGuid = {
    data1: 0x5B1B31A1, data2: 0x9562, data3: 0x11d2,
    data4: [0x8e, 0x3f, 0x00, 0xa0, 0xc9, 0x69, 0x72, 0x3b]
};

struct EfiSimpleFileSystemProtocol
{
    ulong revision;
    EfiStatus function(EfiSimpleFileSystemProtocol*, EfiFileProtocol**) openVolume;
}

immutable EfiGuid EfiSimpleFileSystemProtocolGuid = {
    data1: 0x964e5b22, data2: 0x6459, data3: 0x11d2,
    data4: [0x8e, 0x39, 0x00, 0xa0, 0xc9, 0x69, 0x72, 0x3b]
};

struct EfiFileInfo
{
    ulong size;
    ulong fileSize;
    ulong physicalSize;
    EfiTime createTime;
    EfiTime lastAccessTime;
    EfiTime modificationTime;
    ulong attribute;
    wchar[256] fileName;
}

struct EfiTime
{
    ushort year;
    ubyte month;
    ubyte day;
    ubyte hour;
    ubyte minute;
    ubyte second;
    ubyte pad1;
    uint nanosecond;
    ushort timeZone;
    ubyte daylight;
    ubyte pad2;
}

struct EfiFileProtocol
{
    ulong revision;
    EfiStatus function(
        EfiFileProtocol*, EfiFileProtocol**, inout(wchar)*, ulong, ulong
    ) open;
    EfiStatus function(
        EfiFileProtocol*
    ) close;
    void* delete_;
    EfiStatus function(
        EfiFileProtocol*, uint*, void*
    ) read;
    void* write;
    void* getPosition;
    void* setPosition;
    EfiStatus function(
        EfiFileProtocol*, EfiGuid*, uint*, void*
    ) getInfo;
    void* setInfo;
    void* flush;
    void* openEx;
    void* readEx;
    void* writeEx;
    void* flushEx;
}

__gshared EfiGuid EfiFileInfoGuid = {
    data1: 0x09576e92, data2: 0x6d3f, data3: 0x11d2,
    data4: [0x8e, 0x39, 0x00, 0xa0, 0xc9, 0x69, 0x72, 0x3b]
};
