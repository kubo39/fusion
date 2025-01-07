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

void checkStatus(EfiStatus status)
{
    if (status != EfiSuccess)
    {
        consoleOut(cast(wchar*) " [failed]"w.ptr);
        exit(0);
    }
    consoleOut(cast(wchar*) " [success]\r\n"w.ptr);
}

void EfiMainInner(EfiHandle imgHandle, EfiSystemTable* sysTable)
{
    uefi.sysTable = sysTable;
    consoleClear();

    consoleOut(cast(wchar*) "Fusion OS Bootloader\r\n");

    EfiStatus status;
    EfiLoadedImageProtocol* loadedImage;

    consoleOut(cast(wchar*) "boot: Acquiring LoadedImage protocol"w.ptr);
    checkStatus(uefi.sysTable.bootServices.handleProtocol(
        imgHandle, EfiLoadedImageProtocolGuid, &loadedImage
    ));

    EfiSimpleFileSystemProtocol* fileSystem;
    consoleOut(cast(wchar*) "boot: Acquiring SimpleFileSystem protocol"w.ptr);
    checkStatus(uefi.sysTable.bootServices.handleProtocol(
        loadedImage.deviceHandle, EfiSimpleFileSystemProtocolGuid, &fileSystem
    ));

    EfiFileProtocol* rootDir;
    consoleOut(cast(wchar*) "boot: Opening directory"w.ptr);
    checkStatus(fileSystem.openVolume(fileSystem, &rootDir));

    // open the kernel file
    EfiFileProtocol* kernelFile;
    auto kernelPath = cast(wchar*) r"efi\fusion\kernel.bin"w.ptr;

    consoleOut(cast(wchar*) "boot: Opening kernel file: "w.ptr);
    consoleOut(kernelPath);
    checkStatus(rootDir.open(rootDir, &kernelFile, kernelPath, 1, 1));

    // get kernel file size
    EfiFileInfo kernelInfo = void;
    uint kernelInfoSize = EfiFileInfo.sizeof;

    consoleOut(cast(wchar*) "boot: Getting kernel file info"w.ptr);
    checkStatus(kernelFile.getInfo(kernelFile, &EfiFileInfoGuid, &kernelInfoSize, &kernelInfo));
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
