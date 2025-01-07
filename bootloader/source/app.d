import ldc.attributes : naked;
import ldc.llvmasm;

import uefi;

extern (C):

enum PageSize = 4096;
enum KernelPhysicalBase = 0x100000;
enum ulong KernelStackSize = 128 * 1024;

@naked void exit(int status)
{
    __asm(`
    .loop:
        cli
        hlt
        jmp .loop
    `, "");
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

void EfiMainInner(EfiHandle imgHandle, EfiSystemTable* sysTable)
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

    consoleOut("boot: Allocating memory for kernel stack (16 KiB) "w);
    ulong kernelStackBase;
    auto kernelStackPages = cast(uint) KernelStackSize / PageSize;
    checkStatus(uefi.sysTable.bootServices.allocatePages(
        EfiAllocateType.AllocateAnyPages,
        EfiMemoryType.OsvKernelStack,
        kernelStackPages,
        &kernelStackBase
    ));

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
        EfiMemoryType.EfiLoaderData, memoryMapSize, cast(void*) &memoryMap
    ));

    // now get the memory map
    consoleOut("boot: Getting memory map and exiting boot services"w);
    status = uefi.sysTable.bootServices.getMemoryMap(
        &memoryMapSize,
        cast(EfiMemoryDescriptor*) memoryMap,
        &memoryMapKey,
        &memoryMapDescriptorSize,
        &memoryMapDescriptorVersion
    );

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
}

void Dmain() {}

EfiStatus efi_main(EfiHandle imgHandle, EfiSystemTable* sysTable)
{
    Dmain();

    EfiMainInner(imgHandle, sysTable);

    // String literals have a '\0' appended.
    // https://dlang.org/spec/expression.html#string_literals
    exit(0);
    return EfiLoadError;
}
