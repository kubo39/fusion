module bootinfo;

enum MemoryType : uint
{
    Free,
    KernelCode,
    KernelData,
    KernelStack,
    Reserved    
}

struct MemoryMapEntry
{
    MemoryType type;
    ulong start;
    ulong nframes;
}

struct MemoryMap
{
    uint len;
    MemoryMapEntry** entries;
}

struct BootInfo
{
    MemoryMap physicalMemoryMap;
}
