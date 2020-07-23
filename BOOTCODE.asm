// N64 'Bare Metal' NUS-CIC-6102 Boot Code by krom (Peter Lemon)
// hcs added some notes, removed everything but RDRAM and cache init

//============================
// N64 NUS-CIC-6102 Boot Code
//============================

lui t0,RI_BASE // T0 = RI_BASE ($A4700000)
addiu t0,0 // T0 = RI_BASE ($A4700000)
lw t1,RI_SELECT(t0) // T1 = RI_SELECT WORD[$A470000C]

// GUESS: Handle reset, when RDRAM is already inited?
bnez t1,A4000410 // IF (RI_SELECT != 0) A4000410
nop // Delay Slot

// Store S3..S7 Passed From PIF ROM To STACK
subiu sp,24 // Decrement STACK 6 WORDS
sw s3,$00(sp)
sw s4,$04(sp)
sw s5,$08(sp)
sw s6,$0C(sp)
sw s7,$10(sp)

lui t0,RI_BASE // T0 = RI_BASE ($A4700000)
addiu t0,0 // T0 = RI_BASE ($A4700000)
lui t2,$A3F8 // T2 = $A3F80000
lui t3,RDRAM_BASE // T3 = RDRAM_BASE ($A3F00000)
lui t4,MI_BASE // T4 = MI_BASE ($A4300000)
addiu t4,0 // T4 = MI_BASE ($A4300000)
ori t1,r0,$40 // T1 = $40
sw t1,RI_CONFIG(t0) // WORD[$A4700004] RI_CONFIG = $40

// Delay 24000 Cycles
addiu s1,r0,$1F40 // S1 = $1F40
A400009C:
  nop // Delay
  subi s1,1 // S1--
  bnez s1,A400009C // IF (S1 != 0) A400009C
  nop // Delay Slot

sw r0,RI_CURRENT_LOAD(t0) // WORD[$A4700008] RI_CURRENT_LOAD = 0
ori t1,r0,$14 // T1 = $14
sw t1,RI_SELECT(t0) // WORD[$A470000C] RI_SELECT = $14
sw r0,RI_MODE(t0) // WORD[$A4700000] RI_MODE = $00

// Delay 12 Cycles
addiu s1,r0,4 // S1 = 4
A40000C0:
  nop // Delay
  subi s1,1 // S1--
  bnez s1,A40000C0 // IF (S1 != 0) A40000C0
  nop // Delay Slot

ori t1,r0,$0E // T1 = $0E
sw t1,RI_MODE(t0) // WORD[$A4700000] RI_MODE = $0E (Stop T Active, Stop R Active, Operating Mode 2)

// Delay 64 Cycles
addiu s1,r0,$20 // S1 = $20
A40000DC:
  subi s1,1 // S1--
  bnez s1,A40000DC // IF (S1 != 0) A40000DC
  ori t1,r0,$010F // T1 = $010F (Delay Slot)

sw t1,MI_INIT_MODE(t4) // WORD[$A4300000] MI_INIT_MODE = $010F
lui t1,$1808 // T1 = $18080000
ori t1,$2838 // T1 = $18082838
sw t1,RDRAM_DELAY(t2) // WORD[$A3F80008] RDRAM_DELAY = $18082838
sw r0,RDRAM_REF_ROW(t2) // WORD[$A3F80014] RDRAM_REF_ROW = 0
lui t1,$8000 // T1 = $80000000
sw t1,RDRAM_DEVICE_ID(t2) // WORD[$A3F80004] RDRAM_DEVICE_ID = $80000000

or t5,r0,r0 // T5 = 0
or t6,r0,r0 // T6 = 0
lui t7,RDRAM_BASE // T7 = RDRAM_BASE ($A3F00000)
or t8,r0,r0 // T8 = 0
lui t9,RDRAM_BASE // T9 = RDRAM_BASE ($A3F00000)
lui s6,RDRAM // S6 = RDRAM $A0000000
or s7,r0,r0 // S7 = 0
lui a2,RDRAM_BASE // A2 = RDRAM_BASE ($A3F00000)
lui a3,RDRAM // A3 = RDRAM $A0000000
or s2,r0,r0 // S2 = 0
lui s4,RDRAM // S4 = RDRAM $A0000000

// FP = SP
subiu sp,72 // Decrement STACK 18 WORDS
or s8,sp,r0

lui s0,MI_BASE // S0 = MI_BASE ($A4300000)
lw s0,MI_VERSION(s0) // S0 = MI_VERSION WORD[$A4300004]
lui s1,$0101 // S1 = $01010000
addiu s1,$0101 // S1 = $01010101
bne s0,s1,A4000160 // IF (MI_VERSION != $01010101) Version >= 2 RCP 
nop // Delay Slot

  // ELSE Version 1 RCP
  addiu s0,r0,$0200 // S0 = $0200
  ori s1,t3,$4000 // S1 = $A3F04000
  b A4000168 // GOTO $168
  nop // Delay Slot

  A4000160: // Version >=2 RCP
    addiu s0,r0,$0400 // S0 = $0400
    ori s1,t3,$8000 // S1 = $A3F08000

// FOR (T5 = 0; T5 < 8; T5++)
A4000168:
  sw t6,4(s1) // WORD[$A3F04004/$A3F08004 Depending On Version] = 0
  addiu s5,t7,RDRAM_MODE // S5 = RDRAM_MODE ($A3F0000C)
// What does this do/detect?
  jal A4000778 // CALL($778)
  nop // Delay Slot

// BREAK
  beqz v0,A400025C // IF (CALL($778) V0 == 0) GOTO $25C
  nop // Delay Slot

  // ELSE (CALL($778) V0 != 0)
  sw v0,$00(sp) // STACK WORD[$00] = V0 (TMP1 = RET)
  addiu t1,r0,$2000 // T1 = $2000
  sw t1,MI_INIT_MODE(t4) // WORD[$A4300000] MI_INIT_MODE = $2000 (RDRAM REG MODE)
  lw t3,RDRAM_DEVICE_TYPE(t7) // T3 = RDRAM_DEVICE_TYPE WORD[$A3F00000]
  lui t0,$F0FF // T0 = $F0FF0000
  and t3,t0 // T3 = RDRAM_DEVICE_TYPE & $F0FF0000
  sw t3,$04(sp) // STACK WORD[$04] = T3 (TMP2 = T3)
  addi sp,8 // Increment STACK 2 WORDS

  addiu t1,r0,$1000 // T1 = $1000
  sw t1,MI_INIT_MODE(t4) // WORD[$A4300000] MI_INIT_MODE = $1000 (CLEAR RDRAM REG MODE)
  lui t0,$B019 // T0 = $B0190000
  bne t3,t0,A40001E0 // IF (TMP2 != $B0190000) GOTO $1E0
  nop // Delay Slot

  // ELSE (TMP2 == $B0190000)
  lui t0,$0800 // T0 = $08000000
  add t8,t0 // T8 += $08000000
  add t9,s0 // T9 += S0*2 ($200/$400 Depending On Version)
  add t9,s0
  lui t0,$0020 // T0 = $00200000
  add s6,t0 // S6 = A0200000 (2MB RAM)
  add s4,t0 // S4 = A0200000 (2MB RAM)
  sll s2,1 // S2 <<= 1
  addi s2,1 // S2 = 1
  b A40001E8 // GOTO $1E8
  nop // Delay Slot

  A40001E0:
    lui t0,$0010 // T0 = $00100000
    add s4,t0 // S4 = A0100000 (1MB RAM)

// RDRAM CONFIG
A40001E8:
  addiu t0,r0,$2000 // T0 = $2000
  sw t0,MI_INIT_MODE(t4) // WORD[$A4300000] MI_INIT_MODE = $2000 (RDRAM REG MODE)
  lw t1,RDRAM_DEVICE_MANUF(t7) // T1 = RDRAM_DEVICE_MANUF WORD[$A3F00024]
  lw k0,RDRAM_DEVICE_TYPE(t7) // K0 = RDRAM_DEVICE_TYPE WORD[$A3F00000]
  addiu t0,r0,$1000 // T0 = $1000
  sw t0,MI_INIT_MODE(t4) // WORD[$A4300000] MI_INIT_MODE = $1000 (CLEAR RDRAM REG MODE)
  andi t1,$FFFF // T1 = RDRAM_DEVICE_MANUF & $FFFF
  addiu t0,r0,$0500 // T0 = $0500
  bne t1,t0,A4000230 // IF (T1 != $0500) GOTO $230
  nop // Delay Slot

  lui k1,$0100 // K1 = $01000000
  and k0,k1 // K0 &= $01000000
  bnez k0,A4000230 // IF ((K0 & $01000000) != 0) GOTO $230
  nop // Delay Slot

  lui t0,$101C // T0 = $101C0000
  ori t0,$0A04 // T0 = $101C0A04
  sw t0,RDRAM_RAS_INTERVAL(t7) // WORD[$A3F00018] RDRAM_RAS_INTERVAL = $101C0A04
  b A400023C // GOTO $23C

  // ELSE ((T1 == $0500) && (K0 & $01000000) == 0))
  A4000230:
    lui t0,$080C // T0 = $080C0000 (Delay Slot)
    ori t0,$1204 // T0 = $080C1204
    sw t0,RDRAM_RAS_INTERVAL(t7) // WORD[$A3F00018] RDRAM_RAS_INTERVAL = $080C1204

A400023C:
  lui t0,$0800 // T0 = $08000000
  add t6,t0 // T6 += $08000000 
  add t7,s0 // T7 += S0*2 ($200/$400 Depending On Version)
  add t7,s0
  addiu t5,1 // T5++
  sltiu	t0,t5,8
  bnez t0,A4000168 // IF (++T5 < 8) GOTO $168
  nop // Delay Slot

A400025C:
  lui t0,$C400 // T0 = $C4000000
  sw t0,RDRAM_MODE(t2) // WORD[$A3F8000C] RDRAM_MODE = $C4000000
  lui t0,$8000 // T0 = $80000000
  sw t0,RDRAM_DEVICE_ID(t2) // WORD[$A3F80004] RDRAM_DEVICE_ID = $80000000

or sp,s8,r0 // SP = FP
or v1,r0,r0 // V1 = 0
A4000274:
  lw t1,4(sp) // T1 = TMP2
  lui t0,$B009 // T0 = B0090000
  bne t1,t0,A40002D8 // IF (TMP2 != $B0090000) GOTO $2D8
  nop // Delay Slot

  // ELSE (TMP2 == $B0090000)
  sw t8,4(s1) // WORD[$A3F04004/$A3F08004 Depending On Version] = $08000000
  addiu s5,t9,$C // S5 = T9 + $C
  lw a0,0(sp) // A0 = TMP1
  addi sp,8 // Increment STACK 2 WORDS
  addiu a1,r0,1 // A1 = 1
  jal UnpackAndWriteBits // CALL($A40)(TMP1, 1)
  nop // Delay Slot

  lw t0,0(s6) // T0 = WORD[$A0200000]
  lui t0,$0008 // T0 = $00080000
  add t0,s6 // T0 = $A0280000
  lw t1,0(t0) // T1 = WORD[$A0280000]
  lw t0,0(s6) // T0 = WORD[$A0200000]
  lui t0,$0008 // T0 = $00080000 
  add t0,s6 // T0 = $A0280000
  lw t1,0(t0) // T1 = WORD[$A0280000]
  lui t0,$0400 // T0 = $04000000
  add t6,t0 // T6 += $04000000
  add t9,s0 // T9 += S0 
  lui t0,$0010 // T0 = $00100000
  add s6,t0 // S6 = $A0300000 (3MB RAM)
  b A400035C // GOTO $35C

A40002D8:
  sw s7,4(s1) // WORD[$A3F04004/$A3F08004 Depending On Version] = 0 (Delay Slot)
  addiu s5,a2,$0C // S5 = RDRAM_MODE ($A3F0000C)
  lw a0,0(sp) // A0 = TMP1
  addi sp,8 // Increment STACK 2 WORDS
  addiu	a1,r0,1 // A1 = 1
  jal UnpackAndWriteBits // CALL($A40)(TMP1, 1)
  nop // Delay Slot

  lw t0,0(a3) // T0 = WORD[$A0000000]
  lui t0,$0008 // T0 = $00080000
  add t0,a3 // T0 = $A0080000
  lw t1,0(t0) // T1 = WORD[$A0080000]
  lui t0,$0010 // T0 = $00100000
  add t0,a3 // T0 = $A0010000
  lw t1,0(t0) // T1 = WORD[$A0010000]
  lui t0,$0018 // T0 = $00180000
  add t0,a3 // T0 = $A0180000
  lw t1,0(t0) // T1 = WORD[$A0180000]
  lw t0,0(a3) // T0 = WORD[$A0000000] 
  lui t0,$0008 // T0 = $00080000
  add t0,a3 // T0 = $A0080000
  lw t1,0(t0) // T1 = WORD[$A0080000]
  lui t0,$0010 // T0 = $00100000
  add t0,a3 // T0 = $A0010000
  lw t1,0(t0) // T1 = WORD[$A0010000]
  lui t0,$0018 // T0 = $00180000
  add t0,a3 // T0 = $A0180000
  lw t1,0(t0) // T1 = WORD[$A0180000]
  lui t0,$0800 // T0 = $00800000
  add s7,t0 // S7 = $00800000
  add a2,s0 // A2 += S0*2 ($200/$400 Depending On Version)
  add a2,s0 // A2 = $A3F00400/$A3F00800 Depending On Version
  lui t0,$0020 // T0 = $00200000
  add a3,t0 // A3 = $A0200000 (2MB RAM)

A400035C:
  addiu v1,1 // V1++
  slt t0,v1,t5
  bnez t0,A4000274 // IF (V1 < T5) GOTO $274
  nop // Delay Slot

  lui t2,RI_BASE // T2 = RI_BASE ($A4700000)
  sll s2,19 // S2 <<= 19
  lui t1,$0006 // T1 = $00060000
  ori t1,$3634 // T1 = $00063634
  or t1,s2 // T1 |= S2
  sw t1,RI_REFRESH(t2) // WORD[$A4700010] RI_REFRESH = T1 
  lw t1,RI_REFRESH(t2) // T1 = RI_REFRESH WORD[$A4700010]
  lui t0,RDRAM // T0 = RDRAM ($A0000000)
  ori t0,$0300 // T0 = $A0000300
  lui t1,$0FFF // T1 = $0FFF0000
  ori t1,$FFFF // T1 = $0FFFFFFF
  and s6,t1 // S6 = $00300000
  sw s6,$18(t0) // WORD[$A0000318] = $00300000 (osMemSize)

  or sp,s8,r0 // SP = FP

  // Load S3..S7 From STACK
  addiu sp,72 // Increment STACK 18 WORDS
  lw s3,$00(sp)
  lw s4,$04(sp)
  lw s5,$08(sp)
  lw s6,$0C(sp)
  lw s7,$10(sp)
  addiu sp,24 // Increment STACK 6 WORDS

  // Store I-Cache Tag 0/0 For 16KB Of Main Memory In 32 Byte Chunks Starting At $80000000
  lui t0,$8000 // T0 = $80000000
  addiu t0,0 // T0 = $80000000
  addiu t1,t0,$4000 // T1 = $80004000
  subiu t1,32 // T1 -= 32
  mtc0 r0,TagLo
  mtc0 r0,TagHi
  A40003D8:
    cache $08,0(t0) // CACHE 0(T0), I, Index Store Tag ($08)
    sltu at,t0,t1
    bnez at,A40003D8 // IF (T0 < T1) GOTO $3D8
    addiu t0,32 // T0 += 32 (Delay Slot)

  // Store D-Cache Tag 0/0 For 8KB Of Main Memory In 16 Byte Chunks Starting At $80000000
  lui t0,$8000 // T0 = $80000000
  addiu t0,0 // T0 = $80000000
  addiu t1,t0,$2000 // T1 = $80002000
  subiu t1,16 // T1 -= 16
  A40003F8:
    cache $09,0(t0) // CACHE 0(T0), D, Index Store Tag ($09)
    sltu at,t0,t1
    bnez at,A40003F8 // IF (T0 < T1) GOTO $3F8
    addiu t0,16 // T0 += 16 (Delay Slot)
    b A4000458 // GOTO $458
    nop // Delay Slot

// Store I-Cache Tag 0/0 For 16KB Of Main Memory In 32 Byte Chunks Starting At $80000000
A4000410:
  lui t0,$8000 // T0 = $80000000
  addiu t0,0 // T0 = $80000000
  addiu t1,t0,$4000 // T1 = $80004000
  subiu t1,32 // T1 -= 32
  mtc0 r0,TagLo
  mtc0 r0,TagHi
  A4000428:
    cache $08,0(t0) // CACHE 0(T0), I, Index Store Tag ($08)
    sltu at,t0,t1
    bnez at,A4000428 // IF (T0 < T1) GOTO $428
    addiu t0,32 // T0 += 32 (Delay Slot)

  // Store D-Cache Tag 0/0 For 8KB Of Main Memory In 16 Byte Chunks Starting At $80000000
  lui t0,$8000 // T0 = $80000000
  addiu t0,0 // T0 = $80000000
  addiu t1,t0,$2000 // T1 = $80002000
  subiu t1,16 // T1 -= 16
  A4000448:
    cache $01,0(t0) // CACHE 0(T0), D, Index Writeback Invalidate ($01)
    sltu at,t0,t1
    bnez at,A4000448 // IF (T0 < T1) GOTO $3F8
    addiu t0,16 // T0 += 16 (Delay Slot)

// Copy Routine At $4C0-$774 In Bootcode (Lockout Finale & Program Loader) To Uncached RAM, Address Zero, & Jump To It
A4000458:
  j Start
  nop

// Save Registers To STACK
A4000778:
  subiu sp,160 // Decrement STACK 40 WORDS
  sw s0,$40(sp) // STACK WORD[$40] = S0
  sw s1,$44(sp) // STACK WORD[$44] = S1
  or s1,r0,r0 // S1 = 0
  or s0,r0,r0 // S0 = 0
  sw v0,$00(sp) // STACK WORD[$00] = V0
  sw v1,$04(sp) // STACK WORD[$04] = V1
  sw a0,$08(sp) // STACK WORD[$08] = A0
  sw a1,$0C(sp) // STACK WORD[$0C] = A1
  sw a2,$10(sp) // STACK WORD[$10] = A2
  sw a3,$14(sp) // STACK WORD[$14] = A3
  sw t0,$18(sp) // STACK WORD[$18] = T0
  sw t1,$1C(sp) // STACK WORD[$1C] = T1
  sw t2,$20(sp) // STACK WORD[$20] = T2
  sw t3,$24(sp) // STACK WORD[$24] = T3
  sw t4,$28(sp) // STACK WORD[$28] = T4
  sw t5,$2C(sp) // STACK WORD[$2C] = T5
  sw t6,$30(sp) // STACK WORD[$30] = T6
  sw t7,$34(sp) // STACK WORD[$34] = T7
  sw t8,$38(sp) // STACK WORD[$38] = T8
  sw t9,$3C(sp) // STACK WORD[$3C] = T9
  sw s2,$48(sp) // STACK WORD[$48] = S2
  sw s3,$4C(sp) // STACK WORD[$4C] = S3
  sw s4,$50(sp) // STACK WORD[$50] = S4
  sw s5,$54(sp) // STACK WORD[$54] = S5
  sw s6,$58(sp) // STACK WORD[$58] = S6
  sw s7,$5C(sp) // STACK WORD[$5C] = S7
  sw s8,$60(sp) // STACK WORD[$60] = S8
  sw ra,$64(sp) // STACK WORD[$64] = RA

A40007EC:
  jal A4000880 // CALL($880)
  nop // Delay Slot
  addiu s0,1 // S0++
  slti t1,s0,4
  bnez t1,A40007EC // IF (S0 < 4) GOTO $7EC
  addu s1,v0 // S1 += V0 (Delay Slot)

  srl a0,s1,2 // A0 = S1 >> 2
  jal UnpackAndWriteBits // CALL($A40)
  addiu a1,r0,1 // A1 = 1 (Delay Slot)

// Load Registers From STACK
lw ra,$64(sp) // RA = STACK WORD[$64]
srl v0,s1,2 // V0 = S1 >> 2
lw s1,$44(sp) // S1 = STACK WORD[$44]
lw v1,$04(sp) // V1 = STACK WORD[$04]
lw a0,$08(sp) // A0 = STACK WORD[$08]
lw a1,$0C(sp) // A1 = STACK WORD[$0C]
lw a2,$10(sp) // A2 = STACK WORD[$10]
lw a3,$14(sp) // A3 = STACK WORD[$14]
lw t0,$18(sp) // T0 = STACK WORD[$18]
lw t1,$1C(sp) // T1 = STACK WORD[$1C]
lw t2,$20(sp) // T2 = STACK WORD[$20]
lw t3,$24(sp) // T3 = STACK WORD[$24]
lw t4,$28(sp) // T4 = STACK WORD[$28]
lw t5,$2C(sp) // T5 = STACK WORD[$2C]
lw t6,$30(sp) // T6 = STACK WORD[$30]
lw t7,$34(sp) // T7 = STACK WORD[$34]
lw t8,$38(sp) // T8 = STACK WORD[$38]
lw t9,$3C(sp) // T9 = STACK WORD[$3C]
lw s0,$40(sp) // S0 = STACK WORD[$40]
lw s2,$48(sp) // S2 = STACK WORD[$48]
lw s3,$4C(sp) // S3 = STACK WORD[$4C]
lw s4,$50(sp) // S4 = STACK WORD[$50]
lw s5,$54(sp) // S5 = STACK WORD[$54]
lw s6,$58(sp) // S6 = STACK WORD[$58]
lw s7,$5C(sp) // S7 = STACK WORD[$5C]
lw s8,$60(sp) // S8 = STACK WORD[$60]
jr ra // GOTO RA
addiu sp,160 // Increment STACK 40 WORDS

A4000880:
  subiu sp,32 // Decrement STACK 8 WORDS
  sw ra,$1C(sp) // STACK WORD[$1C] = RA
  or t1,r0,r0 // T1 = 0
  or t3,r0,r0 // T3 = 0
  or t4,r0,r0 // T4 = 0

// FOR (T1 = 0; T1 <= 0x50; T1++)
  A4000894:
    slti k0,t4,64 // FOR (T4 = 0; T4 < 64;)
    beqzl k0,A40008FC // IF (K0 == 0) GOTO $8FC
    or v0,r0,r0 // V0 = 0 (Delay Slot)

    jal TestOnes // CALL($90C)(S4)
    or a0,t4,r0 // A0 = T4 (Delay Slot)

    blezl v0,A40008CC // IF (V0 <= 0) GOTO $8CC
    slti k0,t1,$50 // Delay Slot
    subu k0,v0,t1 // K0 = V0 - T1
    multu k0,t4 // K0 * T4
    or t1,v0,r0 // T1 = V0
    mflo k0 // K0 = K0 * T4
    addu t3,k0 // T3 += K0
    nop // Delay Slot

    slti k0,t1,$50 // IF (T1 >= $50) Continue FOR
    A40008CC:
      bnez k0,A4000894 // IF (K0 != 0) GOTO $894
      addiu t4,1 // T4++ (Delay Slot)

  sll a0,t3,2 // A0 = T3 << 2
  subu a0,t3 // A0 -= T3
  sll a0,2 // A0 <<= 2
  subu a0,t3 // A0 -= T3
  sll a0,1 // A0 <<= 1
  jal A4000980 // CALL($980)(A0, A1, S5)
  subiu a0,880 // A0 -= 880

  b A4000900 // GOTO $900
  lw ra,$1C(sp) // RA = STACK WORD[$1C] (Delay Slot)

  // Unreachable?
  or v0,r0,r0 // V0 = 0
  A40008FC:
    lw ra,$1C(sp) // RA = STACK WORD[$1C]

  A4000900:
    addiu sp,32 // Increment STACK 8 WORDS
    jr ra // GOTO RA
    nop // Delay Slot

// Test if a word can hold 1s by writing it all 1s, then
// reading back and checking bits 23-16, 10 times. Count
// of 1s is returned in v0?

TestOnes:
  subiu sp,40 // Decrement STACK 10 WORDS
  sw ra,$1C(sp) // STACK WORD[$1C] = RA
  or v0,r0,r0 // V0 = 0
// Set some mode
  jal UnpackAndWriteBits // CALL($A40)(A0, A1, S5)
  addiu a1,r0,2 // A1 = 2 (Delay Slot)

or s8,r0,r0 // S8 = 0
subiu k0,r0,1 // K0 = $FFFFFFFF
A4000928:
  sw k0,4(s4) // WORD[S4 + 4] = K0 ($FFFFFFFF)
  lw v1,4(s4) // V1 = WORD[S4 + 4] ($FFFFFFFF)
  sw k0,0(s4) // WORD[S4 + 0] = K0
  sw k0,0(s4) // WORD[S4 + 0] = K0
// GP = bits tested
  or gp,r0,r0 // GP = 0
  srl v1,16 // V1 >>= 16 ($0000FFFF)

  A4000940:
    andi k0,v1,1 // K0 = V1 & 1
// This bit didn't hold
    beqzl k0,A4000954 // IF (K0 == 0) GOTO $954
    addiu gp,1 // GP++ (Delay Slot)

// Bit passed, count it
    addiu v0,1 // V0++
    addiu gp,1 // GP++

    A4000954:
      slti k0,gp,8 // WHILE ((V1 & 1) && GP++ < 8, V1 >>= 1) 
      bnez k0,A4000940 // IF (K0 != 0) GOTO $940
      srl v1,1 // V1 >>= 1 (Delay Slot)

    addiu s8,1 // FP++
    slti k0,s8,10 // WHILE (FP < 10)
    bnezl k0,A4000928 // IF (K0 != 0) GOTO $928
    subiu k0,r0,1 // K0 = $FFFFFFFF (Delay Slot)

lw ra,$1C(sp) // RA = STACK WORD[$1C]
addiu sp,40 // Increment STACK 10 WORDS
jr ra // GOTO RA
nop // Delay Slot

// A0 is some threshold?
// Try T6=0..64
A4000980:
  subiu sp,40 // Decrement STACK 10 WORDS
  sw ra,$1C(sp) // STACK WORD[$1C] = RA
  sw a0,$20(sp) // STACK WORD[$20] = A0
  sb r0,$27(sp) // STACK BYTE[$27] = 0
  or t0,r0,r0 // T0 = 0
  or t2,r0,r0 // T2 = 0
  ori t5,r0,$C800 // T5 = $C800
  or t6,r0,r0 // T6 = 0
  slti k0,t6,64 // WHILE (T6 < 64)

  A40009A4:
    bnezl k0,A40009B8 // IF (K0 != 0) GOTO $9B8
    or a0,t6,r0 // A0 = T6 (Delay Slot)

    b A4000A30 // RETURN
    or v0,r0,r0 // V0 = 0 (Delay Slot)

// Unreachable?
    or a0,t6,r0 // A0 = T6
    A40009B8:
      // Set RDRAM mode from A0?
      jal UnpackAndWriteBits // CALL($A40)
      addiu a1,r0,1 // A1 = 1

      jal ReadAndPackBits // CALL($AD0)
      addiu a0,sp,$27 // A0 = SP + $27 (Delay Slot)

      jal ReadAndPackBits // CALL($AD0)
      addiu a0,sp,$27 // A0 = SP + $27 (Delay Slot)

    lbu k0,$27(sp) // K0 = STACK BYTE[$27]
    addiu k1,r0,$0320 // K1 = $0320
    lw a0,$20(sp) // A0 = STACK WORD[$20]
    multu k0,k1 // K0 * K1
    mflo t0 // T0 = K0 * K1
    subu k0,t0,a0 // K0 = T0 + A0
    bgezl k0,A40009F8 // IF (T0 >= A0) GOTO $9F8
    slt k1,k0,t5 // WHILE (K0 < T5) (Delay Slot)

    subu k0,a0,t0 // K0 = A0 - T0
    slt k1,k0,t5 // WHILE (K0 < T5)

    A40009F8:
      beqzl k1,A4000A0C // IF (K1 == 0) GOTO $A0C
      lw a0,$20(sp) // A0 = STACK WORD[$20] (Delay Slot)

      or t5,k0,r0 // T5 = K0
      or t2,t6,r0 // T2 = T6
      lw a0,$20(sp) // A0 = STACK WORD[$20]

      A4000A0C:
        slt k1,t0,a0 // WHILE (T0 < A0)
        beqzl k1,A4000A2C // IF (K1 == 0) GOTO $A2C
        addu v0,t2,t6 // V0 = T2 + T6 (Delay Slot)

    addiu t6,1 // T6++
    slti k1,t6,$41 // WHILE (T6 < $41)
    bnezl k1,A40009A4
    slti k0,t6,$40 // WHILE (T6 < $40) (Delay Slot)

  addu v0,t2,t6 // V0 = T2 + T6
A4000A2C:
  srl v0,1 // V0 >>= 1

A4000A30:
  lw ra,$1C(sp) // RA = STACK WORD[$1C]
  addiu sp,40 // Increment STACK 10 WORDS
  jr ra // GOTO RA
  nop // Delay Slot

// S5 is probably RDRAM_MODE at this point
// Config in A0 to be unpacked and written into *S5
// If A1 == 1, high bit is set, and write 0 to MI_INIT_MODE
UnpackAndWriteBits:
  subiu	sp,40 // Decrement STACK 10 WORDS
  andi a0,$FF // A0 &= $FF
  addiu k1,r0,1 // K1 = 1
  xori a0,$3F // A0 ^= $3F
  sw ra,$1C(sp) // STACK WORD[$1C] = RA
  bne a1,k1,A4000A64 // IF (A1 != 1) GOTO $A64
  lui t7,$4600 // T7 = $46000000 (Delay Slot) 

  lui k0,$8000 // K0 = $80000000
  or t7,k0 // T7 = $C6000000

A4000A64:
  // T7 |= (A0 & 1) << 6
  andi k0,a0,1 // K0 = A0 & 1
  sll k0,6 // K0 <<= 6
  or t7,k0 // T7 |= K0

  // T7 |= (A0 & 2) << 13
  andi k0,a0,2 // K0 = A0 & 2
  sll k0,13 // K0 <<= 13
  or t7,k0 // T7 |= K0

  // T7 |= (A0 & 4) << 20
  andi k0,a0,4 // K0 = A0 & 4
  sll k0,20 // K0 <<= 20
  or t7,k0 // T7 |= K0

  // T7 |= (A0 & 8) << 4
  andi k0,a0,8 // K0 = A0 & 8
  sll k0,4 // K0 <<= 4
  or t7,k0 // T7 |= K0

  // T7 |= (A0 & $10) << 11
  andi k0,a0,$10 // K0 = A0 & $10
  sll k0,11 // K0 <<= 11
  or t7,k0 // T7 |= K0

  // T7 |= (A0 & $20) << 18
  andi k0,a0,$20 // K0 = A0 & $20
  sll k0,18 // K0 <<= 18
  or t7,k0 // T7 |= K0

  addiu k1,r0,1 // K1 = 1
  bne a1,k1,A4000AC0 // IF (A1 != 1) GOTO $AC0
  sw t7,0(s5) // WORD[S5] = T7 (Delay Slot)

lui k0,MI_BASE // K0 = MI_BASE ($A4300000)
sw r0,MI_INIT_MODE(k0) // WORD[$A4300000] MI_INIT_MODE = 0

A4000AC0:
  lw ra,$1C(sp) // RA = STACK WORD[$1C]
  addiu sp,40 // Increment STACK 10 WORDS
  jr ra // GOTO RA
  nop // Delay Slot

// Read 6 status bits, pack into *A0
ReadAndPackBits:
  subiu sp,40 // Decrement STACK 10 WORDS
  sw ra,$1C(sp) // STACK WORD[$1C] = RA

  addiu k0,r0,$2000 // K0 = $2000
  lui k1,MI_BASE // K1 = MI_BASE ($A4300000)
  sw k0,MI_INIT_MODE(k1) // WORD[$A4300000] MI_INIT_MODE = $2000 (MI Set RDRAM)
  or s8,r0,r0 // S8 = 0

  lw s8,0(s5) // S8 = WORD[S5]
  addiu k0,r0,$1000 // K0 = $1000
  sw k0,MI_INIT_MODE(k1) // WORD[$A4300000] MI_INIT_MODE = $1000 (MI Clear RDRAM)

  // K0 = (*S5 & $40) >> 6
  addiu k1,r0,$40 // K1 = $40
  and k1,s8 // K1 &= S8
  srl k1,6 // K1 >>= 6
  // K0 |= (*S5 & $4000) >> 13
  or k0,r0,r0 // K0 = 0
  or k0,k1 // K0 |= K1
  // K0 = A
  addiu k1,r0,$4000 // K1 = $4000
  and k1,s8 // K1 &= S8
  srl k1,13 // K1 >>= 13
  // K0 |= (*S5 & $00400000) >> 20
  or k0,k1 // K0 |= K1
  // K0 = CA
  lui k1,$0040 // K1 = $00400000
  and k1,s8 // K1 &= S8
  srl k1,20 // K1 >>= 20
  or k0,k1 // K0 |= K1
  // K0 |= (*S5 & $80) >> 4
  addiu k1,r0,$80 // K1 = $80
  and k1,s8 // K1 &= S8
  srl k1,4 // K1 >>= 4
  or k0,k1 // K0 |= K1
  // K0 |= (*S5 & $8000) >> 11
  ori k1,r0,$8000 // K1 = $8000
  and k1,s8 // K1 &= S8
  srl k1,11 // K1 >>= 11
  or k0,k1 // K0 |= K1
  // K0 |= (*S5 & $00800000) >> 18
  lui k1,$0080 // K1 = $00800000
  and k1,s8 // K1 &= S8
  srl k1,18 // K1 >>= 18
  or k0,k1 // K0 |= K1

  // S8 = FE00 0000 DC00 0000 BA00 0000
  // K0 = FDBECA
  // MSB(*A0) = K0 & $FF
  sb k0,0(a0) // BYTE[A0] = K0
  lw ra,$1C(sp) // RA = STACK WORD[$1C]
  addiu sp,40 // Increment STACK 10 WORDS
  jr ra // GOTO RA
  nop // Delay Slot
