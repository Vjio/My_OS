#include "stdint.h"
#include "stdio.h"

void _cdecl cstart_(uint16_t bootDrive) {
	const char far* far_str = "far string";

	puts("Hello world from C!\r\n");
	printf("Fromatted negative numbers %i %i\r\n", -2, -1234);
	printf("Formatted %% %c %s %ls\r\n", 'a', "string", far_str);
    printf("Formatted hexa %x %p\r\n", 0xdead, 0xbeef);
	printf("Formatted octal %o\r\n", 012345);
	printf("Formatted signed %hd\r\n", (short)27);
	printf("Formatted signed %hi\r\n", (short)-42);
	printf("Formatted signed %hd %hi %hhu %hhd\r\n", (short)27, (short)-42, (unsigned char)20, (signed char)-10);

    printf("Formatted %d %i %x %p %o %hd %hi %hhu %hhd\r\n", 1234, -5678, 0xdead, 0xbeef, 012345, (short)27, (short)-42, (unsigned char)20, (signed char)-10);

    printf("Formatted %ld %lx %lld %llx\r\n", -100000000l, 
		0xdeadbeeful, 10200300400ll, 
		0xdeadbeeffeebdaedull);

	printf("Formatted ll %lld", 10200300400ll);
	for (;;);
}
