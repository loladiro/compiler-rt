/* ===-- clear_cache.c - Implement __clear_cache ---------------------------===
 *
 *                     The LLVM Compiler Infrastructure
 *
 * This file is dual licensed under the MIT and the University of Illinois Open
 * Source Licenses. See LICENSE.TXT for details.
 *
 * ===----------------------------------------------------------------------===
 */

#include "int_lib.h"

#if __APPLE__
  #include <libkern/OSCacheControl.h>
#endif
#if defined(__NetBSD__) && defined(__arm__)
  #include <machine/sysarch.h>
#endif

/*
 * The compiler generates calls to __clear_cache() when creating 
 * trampoline functions on the stack for use with nested functions.
 * It is expected to invalidate the instruction cache for the 
 * specified range.
 */

void __clear_cache(void* start, void* end)
{
#if __i386__ || __x86_64__
/*
 * Intel processors have a unified instruction and data cache
 * so there is nothing to do
 */
#elif defined(__NetBSD__) && defined(__arm__)
  struct arm_sync_icache_args arg;

  arg.addr = (uintptr_t)start;
  arg.len = (uintptr_t)end - (uintptr_t)start;

  sysarch(ARM_SYNC_ICACHE, &arg);
#else
    #if __APPLE__
        /* On Darwin, sys_icache_invalidate() provides this functionality */
        sys_icache_invalidate(start, end-start);
    #else
        compilerrt_abort();
    #endif
#endif
}

