import ldc.attributes : naked;
import ldc.llvmasm : __asm;

import bootinfo;
import debugcon;
import uefi;

extern (C):

enum PageSize = 4096;
enum KernelPhysicalBase = 0x100000;
enum ulong KernelStackSize = 128 * 1024;

alias KernelEntryPoint = void function(BootInfo*);

void __chkstk() {}

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

void checkStatus(EfiStatus status)
{
    if (status != EfiSuccess)
    {
        sysTable.conOut.setAttribute(sysTable.conOut, EFI_RED);
        consoleOut(" [failed]"w);
        exit(0);
    }
    sysTable.conOut.setAttribute(sysTable.conOut, EFI_GREEN);
    consoleOut(" [success]\r\n"w);
    sysTable.conOut.setAttribute(sysTable.conOut, EFI_WHITE);
}

noreturn EfiMainInner(EfiHandle imgHandle, EfiSystemTable* sysTable)
{
    uefi.sysTable = sysTable;
    consoleClear();

    sysTable.conOut.setAttribute(sysTable.conOut, EFI_YELLOW);
    consoleOut("Fusion OS Bootloader\r\n\r\n"w);
    sysTable.conOut.setAttribute(sysTable.conOut, EFI_WHITE);

    EfiStatus status;
    EfiLoadedImageProtocol* loadedImage;

    consoleOut("boot: Acquiring LoadedImage protocol"w);
    checkStatus(uefi.sysTable.bootServices.handleProtocol(
        imgHandle, EfiLoadedImageProtocolGuid, &loadedImage
    ));

    EfiSimpleFileSystemProtocol* fileSystem;
    consoleOut("boot: Acquiring SimpleFileSystem protocol"w);
    checkStatus(uefi.sysTable.bootServices.handleProtocol(
        loadedImage.deviceHandle, EfiSimpleFileSystemProtocolGuid, &fileSystem
    ));

    EfiFileProtocol* rootDir;
    consoleOut("boot: Opening directory"w);
    checkStatus(fileSystem.openVolume(fileSystem, &rootDir));

    // open the kernel file
    EfiFileProtocol* kernelFile;
    auto kernelPath = r"efi\fusion\kernel.bin"w;

    consoleOut("boot: Opening kernel file: "w);
    consoleOut(kernelPath);
    checkStatus(rootDir.open(rootDir, &kernelFile, kernelPath.ptr, 1, 1));

    // get kernel file size
    EfiFileInfo kernelInfo = void;
    uint kernelInfoSize = EfiFileInfo.sizeof;

    consoleOut("boot: Getting kernel file info"w);
    checkStatus(kernelFile.getInfo(kernelFile, &EfiFileInfoGuid, &kernelInfoSize, &kernelInfo));

    consoleOut("boot: Allocating memory for kernel image "w);
    auto kernelImageBase = cast(void*) KernelPhysicalBase;
    uint kernelImagePages = cast(uint) (kernelInfo.fileSize + 0xFFF) / PageSize;
    checkStatus(uefi.sysTable.bootServices.allocatePages(
        EfiAllocateType.AllocateAddress,
        EfiMemoryType.OsvKernelCode,
        kernelImagePages,
        cast(EfiPhysicalAddress*) &kernelImageBase
    ));
    dbg("[debug]: kernel image base: 0x%x\n", kernelImageBase);

    consoleOut("boot: Allocating memory for kernel stack (16 KiB) "w);
    ulong kernelStackBase;
    auto kernelStackPages = cast(uint) KernelStackSize / PageSize;
    checkStatus(uefi.sysTable.bootServices.allocatePages(
        EfiAllocateType.AllocateAnyPages,
        EfiMemoryType.OsvKernelStack,
        kernelStackPages,
        &kernelStackBase
    ));

    consoleOut("boot: Allocating memory for bootinfo"w);
    ulong bootInfoBase;
    checkStatus(uefi.sysTable.bootServices.allocatePages(
        EfiAllocateType.AllocateAnyPages,
        EfiMemoryType.OsvKernelStack,
        1,
        &bootInfoBase
    ));
    dbg("[debug]: bootinfo base: 0x%x\n", bootInfoBase);

    // read the kernel into memory
    consoleOut("boot: Reading kernel into memory"w);
    checkStatus(kernelFile.read(
        kernelFile, cast(uint*) &kernelInfo.fileSize, kernelImageBase
    ));

    // close the kernel file
    consoleOut("boot: Closing kernel file"w);
    checkStatus(kernelFile.close(kernelFile));

    // close the root directory
    consoleOut("boot: Closing root directory"w);
    checkStatus(rootDir.close(rootDir));

    // memory map
    uint memoryMapSize = 0;
    EfiMemoryDescriptor** memoryMap;
    uint memoryMapKey;
    uint memoryMapDescriptorSize;
    uint memoryMapDescriptorVersion;

    ubyte[4096 * 3] memoryMapBuffer = void;

/*
    // get memory map size
    status = uefi.sysTable.bootServices.getMemoryMap(
        &memoryMapSize,
        null,
        null,
        &memoryMapDescriptorSize,
        null
    );
    // increase memory map size to account for the next call to allocatePool
    memoryMapSize += memoryMapDescriptorSize;

    // allocate pool for memory map (this changes the memory map size, hence the previous step)
    consoleOut("boot: Allocating pool for memory map"w);
    checkStatus(uefi.sysTable.bootServices.allocatePool(
        EfiMemoryType.EfiLoaderData,
        memoryMapSize,
        cast(void**) &memoryMap
    ));
    dbg("[debug]: memory map (allocatePool): 0x%x\n", memoryMap);
    dbg("[debug]: memory map size (allocatePool): 0x%x\n", memoryMapSize);
    dbg("[debug]: descriptor size (allocatePool): 0x%x\n", memoryMapDescriptorSize);
*/

    // now get the memory map
    consoleOut("boot: Getting memory map and exiting boot services"w);
    status = uefi.sysTable.bootServices.getMemoryMap(
        &memoryMapSize,
        cast(EfiMemoryDescriptor*) memoryMapBuffer.ptr,
        &memoryMapKey,
        &memoryMapDescriptorSize,
        &memoryMapDescriptorVersion
    );
    dbg("[debug]: memory map (getMemoryMap): 0x%x\n", memoryMapBuffer.ptr);
    dbg("[debug]: memory map key (getMemoryMap): 0x%x\n", memoryMapKey);
    dbg("[debug]: memory map size (getMemoryMap): 0x%x\n", memoryMapSize);
    dbg("[debug]: descriptor size (getMemoryMap): 0x%x\n", memoryMapDescriptorSize);

    // IMPORTANT: After this point we cannot output anything to the console, since doing
    // so may allocate memory and change the memory map, invalidating our map key. We can
    // only output to the console in case of an error (since we quit anyway).
    if (status != EfiSuccess)
    {
        consoleOut("boot: Failed to get memory map"w);
        exit(0);
    }

    status = uefi.sysTable.bootServices.exitBootServices(
        imgHandle, memoryMapKey
    );
    if (status != EfiSuccess)
    {
        consoleOut("boot: Failed to exit boot services"w);
        exit(0);
    }

    // ======= NO MORE UEFI BOOT SERVICES =======

    // we cannot dynamic array here, use static array instead.
    MemoryMapEntry[135] physMemoryMap = void;
    const uefiNumMemoryMapEntries = memoryMapSize / memoryMapDescriptorSize;
    foreach (i; 0 .. uefiNumMemoryMapEntries)
    {
        const uefiEntry = cast(EfiMemoryDescriptor*)(cast(ulong)memoryMapBuffer.ptr + i * memoryMapDescriptorSize);
        MemoryType memoryType;
        switch (uefiEntry.type)
        {
            case EfiMemoryType.EfiConventionalMemory:
            case EfiMemoryType.EfiBootServicesCode:
            case EfiMemoryType.EfiBootServicesData:
            case EfiMemoryType.EfiLoaderCode:
            case EfiMemoryType.EfiLoaderData:
                memoryType = MemoryType.Free;
                break;
            case EfiMemoryType.OsvKernelCode:
                memoryType = MemoryType.KernelCode;
                break;
            case EfiMemoryType.OsvKernelData:
                memoryType = MemoryType.KernelData;
                break;
            case EfiMemoryType.OsvKernelStack:
                memoryType = MemoryType.KernelStack;
                break;
            default:
                memoryType = MemoryType.Reserved;
        }
        physMemoryMap[i] = MemoryMapEntry(
            memoryType,
            uefiEntry.physicalStart,
            uefiEntry.numberOfPages
        );
    }

    auto bootInfo = cast(BootInfo*) bootInfoBase;

    // copy physical memory map entries to boot info
    bootInfo.physicalMemoryMap.len = uefiNumMemoryMapEntries;
    bootInfo.physicalMemoryMap.entries = cast(MemoryMapEntry**) (bootInfoBase + BootInfo.sizeof);

    foreach (i; 0 .. uefiNumMemoryMapEntries)
    {
        *(cast(MemoryMapEntry*)bootInfo.physicalMemoryMap.entries + i * MemoryMapEntry.sizeof) =
            physMemoryMap[i];
    }

    // jump to kernel
    const ulong kernelStackTop = kernelStackBase + KernelStackSize;
    __asm(`
        jmpq *%rdx  # kernel entry point
    `, "{rdi},{rsp},{rdx}",
    bootInfoBase, kernelStackTop, KernelPhysicalBase);

    // we should never get here
    exit(0);
}

EfiStatus efi_main(EfiHandle imgHandle, EfiSystemTable* sysTable)
{
    EfiMainInner(imgHandle, sysTable);
    return EfiLoadError;
}
