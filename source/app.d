extern (C):

alias EfiStatus = uint;
alias EfiHandle = void*;

struct EfiSystemTable {}

enum : EfiStatus
{
	EfiSuccess = 0,
	EfiLoadError = 1
}

void d_main() {}

EfiStatus efi_main(EfiHandle imgHandle, EfiSystemTable* sysTable)
{
	d_main();
	return EfiLoadError;
}
