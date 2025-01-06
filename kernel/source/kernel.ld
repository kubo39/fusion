SECTIONS
{
  . = 0x100000;
  .text     : {
    *kernel*.o(.text.KernelMain)
    *kernel*.o(.text.*)
    *(.text.*)
  }
  .rodata   : { *(.rodata*) }
  .data     : { *(.data) }
  .bss      : { *(.bss) }
  .shstrtab : { *(.shstrtab) }

  /DISCARD/ : { *(*) }
}
