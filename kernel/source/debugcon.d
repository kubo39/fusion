module debugcon;

import ldc.llvmasm;

extern (C):
nothrow:
@nogc:

enum ushort DebugConPort = 0xE9;

private void portOut8(ushort port, ubyte data)
{
    __asm("outb %al, %dx", "{dx},{al}", port, data);
}

void dbg(string msg)
{
    foreach (ch; msg)
    {
        portOut8(DebugConPort, ch);
    }
}

void dbgln(string msg)
{
    dbg(msg);
    dbg("\r\n");
}
