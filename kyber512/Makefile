CC=/usr/bin/gcc
ASM=/usr/bin/nasm
LDFLAGS=-lcrypto

ASMSRC= indcpa.asm poly.asm reduce.asm
OBJFILES= indcpa.o poly.o reduce.o
SOURCES= cbd.c fips202.c indcpa.c kem.c ntt.c poly.c polyvec.c PQCgenKAT_kem.c precomp.c rng.c verify.c
HEADERS= api.h cbd.h fips202.h indcpa.h ntt.h params.h poly.h polyvec.h reduce.h rng.h verify.h

PQCgenKAT_kem: $(HEADERS) $(SOURCES) $(OBJFILES)
	$(CC) -ggdb -Wall -o $@ $(SOURCES) $(OBJFILES) $(LDFLAGS)

indcpa.o: indcpa.asm
	$(ASM) -f elf64 -g -F dwarf indcpa.asm
poly.o: poly.asm
	$(ASM) -f elf64 -g -F dwarf poly.asm
reduce.o: reduce.asm
	$(ASM) -f elf64 -g -F dwarf reduce.asm

.PHONY: clean

clean:
	-rm PQCgenKAT_kem
	-rm *.o

