CC=/usr/bin/gcc
NASM=/usr/bin/nasm
LDFLAGS=-lcrypto

ASMSRC= indcpa.asm poly.asm reduce.asm ntt.asm polyvec.asm
OBJFILES= indcpa.o poly.o reduce.o ntt.o polyvec.o
SOURCES= cbd.c fips202.c indcpa.c kem.c poly.c polyvec.c PQCgenKAT_kem.c precomp.c rng.c verify.c
HEADERS= api.h cbd.h fips202.h indcpa.h ntt.h params.h poly.h polyvec.h reduce.h rng.h verify.h

PQCgenKAT_kem: $(HEADERS) $(SOURCES) $(OBJFILES) $(ASMSRC)
	$(CC) -ggdb -Wall -no-pie -o $@ $(SOURCES) $(OBJFILES) $(LDFLAGS)

indcpa.o: indcpa.asm
	$(NASM) -f elf64 -g -F dwarf indcpa.asm
poly.o: poly.asm
	$(NASM) -f elf64 -g -F dwarf poly.asm
reduce.o: reduce.asm
	$(NASM) -f elf64 -g -F dwarf reduce.asm
ntt.o: ntt.asm
	$(NASM) -f elf64 -g -F dwarf ntt.asm
polyvec.o: polyvec.asm
	$(NASM) -f elf64 -g -F dwarf polyvec.asm

.PHONY: clean

clean:
	-rm PQCgenKAT_kem
	-rm *.o

