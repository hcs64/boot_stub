// Boot stub, loads code from 0x1000 in ROM into RSP DMEM 0x80 and runs it
// from the CPU at 0xa400'0080.
//
// This software is dedicated to the public domain.

// TODO: I'd like to run the copy loop out of cache, or perhaps out of IMEM, so
// that all of DMEM can be used for the load.

arch n64.cpu
endian msb

// CP0 registers
constant Count(9)
constant Compare(11)
constant Cause(16)

// GPRs
constant r0(0)
constant t0(8)
constant t1(9)
constant t2(10)
constant t3(11)
constant t4(12)

constant CART_ROM_ADDR(0xb000'0000)
constant SRC_ROM_OFFSET(0x1000)
constant DST_DMEM_OFFSET(0x80)
constant SP_DMEM(0xa400'0000)
constant DMEM_SIZE(0x1000)

base SP_DMEM

// These are the only essential parts of the ROM header.

// Initial ROM timing info
  db 0x80, 0x37, 0x12, 0x40

// Initial CPU timing
  dw 15

// Pad out to IPL3 entrypoint
origin 0x40

if pc() != 0xa400'0040 {
  error "entrypoint is wrong"
}
Entrypoint:
// Clear pending software interrupts
  mtc0 r0, Cause
// Clear the timer interrupt, and prevent it from hitting until the counter wraps around
  mtc0 r0, Count
  mtc0 r0, Compare

// Load the data into DMEM
  la t0, CART_ROM_ADDR + SRC_ROM_OFFSET
  addi t2, t0, DMEM_SIZE - DST_DMEM_OFFSET
  la t4, SP_DMEM + DST_DMEM_OFFSET
  move t1, t4
-
  lw t3, 0(t0)
  addi t0, 4
  sw t3, 0(t1)
  bne t0, t2,-
  addi t1, 4

// Jump into the new code
  jr t4
  nop

if pc() > SP_DMEM + DST_DMEM_OFFSET {
  print pc() - SP_DMEM, "\n"
  error "stub too large"
}

fill DMEM_SIZE - 12 - origin()

// Padding
dw 0
// Junk for collision with expected 6102 hash, found with awygle's ipl3hasher
dw 0x670F4, 0x44D763CB
