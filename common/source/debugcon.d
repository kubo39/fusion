module debugcon;

import ldc.llvmasm;

extern (C):
nothrow:
@nogc:

alias va_list = imported!"core.stdc.stdarg".va_list;
alias va_start = imported!"core.stdc.stdarg".va_start;
alias va_end = imported!"core.stdc.stdarg".va_end;
alias va_arg = imported!"core.stdc.stdarg".va_arg;

enum ushort DebugConPort = 0xE9;

private void portOut8(ushort port, ubyte data)
{
    __asm("outb %al, %dx", "{dx},{al}", port, data);
}

void putchar(char ch)
{
    portOut8(DebugConPort, ch);
}

void dbg(const(char)* fmt, ...)
{
    va_list vargs;
    va_start(vargs, fmt);

    while (*fmt)
    {
        if (*fmt == '%')
        {
            fmt++;
            switch (*fmt)
            {
            case '\0':
                putchar('%');
                goto end;
            case '%':
                putchar('%');
                break;
            case 's':
            {
                const(char)* s = va_arg!(const(char)*)(vargs);
                while (*s)
                {
                    putchar(*s);
                    s++;
                }
                break;
            }
            case 'd':
            {
                int value = va_arg!int(vargs);
                if (value < 0)
                {
                    putchar('-');
                    value = -value;
                }

                int divisor = 1;
                while (value / divisor > 9)
                {
                    divisor *= 10;
                }

                while (divisor > 0)
                {
                    putchar('0' + value / divisor);
                    value %= divisor;
                    divisor /= 10;
                }

                break;
            }
            case 'x':
            {
                int value = va_arg!int(vargs);
                for (int i = 7; i >= 0; i--)
                {
                    int nibble = (value >> (i * 4)) & 0xf;
                    putchar("0123456789abcdef"[nibble]);
                }
                break;
            }
            default:
                break;
            }
        }
        else
        {
            putchar(*fmt);
        }

        fmt++;
    }

end:
    va_end(vargs);
}
