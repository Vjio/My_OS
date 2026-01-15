#pragma once
#include "stdint.h"

void _cdecl x86_Video_WriteCharTeletype(char c, uint8_t page);

void _cdecl x86_div64_32(uint64_t divident, uint32_t divisor, uint32_t* quotientOut, uint32_t* remainderOut);
