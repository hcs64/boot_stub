N64 Boot Stub

boot_stub.bin is a replacement for the CIC-6102 IPL3. It simply loads code from
the ROM at 0x1000 into RSP DMEM at 0xa400'0080, and then jumps to it. It works
thanks to a hash collision against the official IPL3.

---

IPL2 (which is built into the console) checks that the hash of the IPL3 code in
the ROM is accepted by the CIC on the cartridge. It would be interesting to
write a new IPL3, rather than including a 4K chunk of official code in every
homebrew N64 project.

The hash algorithm protecting IPL3 has been known for some time, but until
recently there were no known collisions. awygle's GPU-based ipl3hasher has made
this much more practical: a collision for boot_stub was found in under an hour.

boot_stub is meant to accelerate future IPL3 development. It loads and runs
code without performing any verification, so there is no need to find a
new collision on every debug cycle.

---

I've included a proof of concept N64 ROM (poc.n64, from test.asm), which just
displays a blinking screen. This uses the RDRAM and cache init code from the
official IPL3 (BOOTCODE.asm), but strips out almost everything else. It runs
out of DMEM, where the stub leaves it.

---

This wouldn't have been possible for me without:

* ipl3hasher by awygle
* bootcsumr, from fin and fraser's pseultra
* krom's N64 'Bare Metal' code, particularly the CIC-6102 disassembly
* near, ARM9, et al's bass assembler for N64

Thanks for making my dreams come true!

-hcs 2020-07-23
