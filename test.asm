arch n64.cpu
endian msb

include "LIB/N64.INC"
include "LIB/N64_GFX.INC"

insert "boot_stub.bin"

constant FB_width(110)
constant FB_height(120)
constant FB(0xa010'0000)

base 0xa400'0080
include "BOOTCODE.asm"

Start:
  N64_INIT()

  ScreenNTSC(FB_width, FB_height, BPP16, FB)

  la s1,  0x0800'0800
  la s2, -0x0040'0040
  la s0,  0x07c1'07c1

frames:
  WaitScanline(0x200)
  la t0, FB
  la t2, FB+(FB_width*FB_height*2+7)/8*8
  dsll32 t1, s0, 0
  or t1, s0
pixels:
  addi t0, 8
  bne t0,t2, pixels
  sd t1, 0(t0)

  daddu t0, s0, s1
  dsrl32 t1, t0, 0
  beqzl t1, frames
  daddu s0, t0, s2

  neg s2
  j frames
  neg s1

-
  j -
  nop

align_file(512)
