.PHONY: test.n64

BASS=bass

test.n64: boot_stub.bin
	$(BASS) test.asm -create -o test.n64

boot_stub.bin: boot_stub.asm
	$(BASS) boot_stub.asm -create -o boot_stub.bin
