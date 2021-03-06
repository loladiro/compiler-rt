/*===-- udivmodsi4.S - 32-bit unsigned integer divide and modulus ---------===//
 *
 *                     The LLVM Compiler Infrastructure
 *
 * This file is dual licensed under the MIT and the University of Illinois Open
 * Source Licenses. See LICENSE.TXT for details.
 *
 *===----------------------------------------------------------------------===//
 *
 * This file implements the __udivmodsi4 (32-bit unsigned integer divide and
 * modulus) function for the ARM architecture.  A naive digit-by-digit
 * computation is employed for simplicity.
 *
 *===----------------------------------------------------------------------===*/

#include "../assembly.h"

#define ESTABLISH_FRAME    \
    push   {r4, r7, lr}   ;\
    add     r7,     sp, #4
#define CLEAR_FRAME_AND_RETURN \
    pop    {r4, r7, pc}
    
#define a r0
#define b r1
#define i r3
#define r r4
#define q ip
#define one lr

.syntax unified
.align 3
DEFINE_COMPILERRT_FUNCTION(__udivmodsi4)
#if __ARM_ARCH_EXT_IDIV__
	tst     r1, r1
	beq     LOCAL_LABEL(divzero)
	mov 	r3, r0
	udiv	r0, r3, r1
	mls 	r1, r0, r1, r3
	str 	r1, [r2]
	bx  	lr
LOCAL_LABEL(divzero):
	mov     r0, #0
	bx      lr
#else
//  We use a simple digit by digit algorithm; before we get into the actual 
//  divide loop, we must calculate the left-shift amount necessary to align
//  the MSB of the divisor with that of the dividend (If this shift is
//  negative, then the result is zero, and we early out). We also conjure a
//  bit mask of 1 to use in constructing the quotient, and initialize the
//  quotient to zero.
    ESTABLISH_FRAME
    clz     r4,     a
    tst     b,      b   // detect divide-by-zero
    clz     r3,     b
    mov     q,      #0
    beq     LOCAL_LABEL(return)    // return 0 if b is zero.
    mov     one,    #1
    subs    i,      r3, r4
    blt     LOCAL_LABEL(return)    // return 0 if MSB(a) < MSB(b)

LOCAL_LABEL(mainLoop):
//  This loop basically implements the following:
//
//  do {
//      if (a >= b << i) {
//          a -= b << i;
//          q |= 1 << i;
//          if (a == 0) break;
//      }
//  } while (--i)
//
//  Note that this does not perform the final iteration (i == 0); by doing it
//  this way, we can merge the two branches which is a substantial win for
//  such a tight loop on current ARM architectures.
    subs    r,      a,  b, lsl i
    itt hs
    orrhs   q,      q,one, lsl i
    movhs   a,      r
    it ne
    subsne  i,      i, #1
    bhi     LOCAL_LABEL(mainLoop)

//  Do the final test subtraction and update of quotient (i == 0), as it is
//  not performed in the main loop.
    subs    r,      a,  b
    itt hs
    orrhs   q,      #1
    movhs   a,      r

LOCAL_LABEL(return):
//  Store the remainder, and move the quotient to r0, then return.
    str     a,     [r2]
    mov     r0,     q
    CLEAR_FRAME_AND_RETURN
#endif
