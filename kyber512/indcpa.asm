BITS 64

section .note.GNU-stack
section .text

global indcpa_enc

%define KYBER_K 2
%define KYBER_SYMBYTES 32
%define KYBER_POLYVECCOMPRESSEDBYTES (KYBER_K * 352) 

extern unpack_pk
extern poly_frommsg
extern polyvec_ntt
extern gen_matrix
extern poly_getnoise
extern polyvec_pointwise_acc
extern polyvec_invntt
extern polyvec_add
extern polyvec_pointwise_acc
extern poly_invntt
extern poly_add
extern pack_ciphertext

indcpa_enc:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 7760
	mov	qword [rbp-7736], rdi     ; unsigned char *c
	mov	qword [rbp-7744], rsi     ; const unsigned char *m
	mov	qword [rbp-7752], rdx     ; const unsigned char *pk
	mov	qword [rbp-7760], rcx     ; const unsigned char *coins

	mov	byte [rbp-5], 0           ; nonce (unsigned char)
	mov	rdx, qword [rbp-7752]
	lea	rcx, [rbp-7728]           ; seed (unsigned char [KYBER_SYMBYTES])
	lea	rax, [rbp-2064]           ; &pkpv (polyvec)
	mov	rsi, rcx
	mov	rdi, rax
	call	unpack_pk

	mov	rdx, qword [rbp-7744]
	lea	rax, [rbp-7184]           ; &k (poly)
	mov	rsi, rdx
	mov	rdi, rax
	call	poly_frommsg

	lea	rax, [rbp-2064]
	mov	rdi, rax
	call	polyvec_ntt

	lea	rcx, [rbp-7728]           ; seed
	lea	rax, [rbp-5136]           ; at (polyvec [KYBER_K])
	mov	edx, 1
	mov	rsi, rcx
	mov	rdi, rax
	call	gen_matrix

	mov	dword [rbp-4], 0
	jmp	.L31
.L32:
	movzx	eax, byte [rbp-5]
	lea	edx, [rax+1]
	mov	byte [rbp-5], dl
	movzx	edx, al
	mov	eax, dword [rbp-4]
	cdqe
	sal	rax, 9
	mov	rcx, rax
	lea	rax, [rbp-1040]
	add	rcx, rax
	mov	rax, qword [rbp-7760]
	mov	rsi, rax
	mov	rdi, rcx
	call	poly_getnoise
	add	dword [rbp-4], 1
.L31:
	cmp	dword [rbp-4], 1
	jle	.L32
	lea	rax, [rbp-1040]
	mov	rdi, rax
	call	polyvec_ntt
	mov	dword [rbp-4], 0
	jmp	.L33
.L34:
	movzx	eax, byte [rbp-5]
	lea	edx, [rax+1]
	mov	byte [rbp-5], dl
	movzx	edx, al
	mov	eax, dword [rbp-4]
	cdqe
	sal	rax, 9
	mov	rcx, rax
	lea	rax, [rbp-3088]
	add	rcx, rax
	mov	rax, qword [rbp-7760]
	mov	rsi, rax
	mov	rdi, rcx
	call	poly_getnoise
	add dword [rbp-4], 1
.L33:
	cmp	dword [rbp-4], 1
	jle	.L34
	mov	dword [rbp-4], 0
	jmp	.L35
.L36:
	mov	eax, dword [rbp-4]
	cdqe
	sal	rax, 10
	mov	rdx, rax
	lea	rax, [rbp-5136]
	add	rdx, rax
	lea	rax, [rbp-6160]
	mov	ecx, dword [rbp-4]
	movsx	rcx, ecx
	sal	rcx, 9
	add	rcx, rax
	lea	rax, [rbp-1040]
	mov	rsi, rax
	mov	rdi, rcx
	call	polyvec_pointwise_acc
	add	dword [rbp-4], 1
.L35:
	cmp	dword [rbp-4], 1
	jle	.L36
	lea	rax, [rbp-6160]
	mov	rdi, rax
	call	polyvec_invntt
	lea	rdx, [rbp-3088]
	lea	rcx, [rbp-6160]
	lea	rax, [rbp-6160]
	mov	rsi, rcx
	mov	rdi, rax
	call	polyvec_add
	lea	rdx, [rbp-1040]
	lea	rcx, [rbp-2064]
	lea	rax, [rbp-6672]
	mov	rsi, rcx
	mov	rdi, rax
	call	polyvec_pointwise_acc
	lea	rax, [rbp-6672]
	mov	rdi, rax
	call	poly_invntt
	movzx	eax, byte [rbp-5]
	lea	edx, [rax+1]
	mov	byte [rbp-5], dl
	movzx	edx, al
	mov	rcx, qword [rbp-7760]
	lea	rax, [rbp-7696]
	mov	rsi, rcx
	mov	rdi, rax
	call	poly_getnoise
	lea	rdx, [rbp-7696]
	lea	rcx, [rbp-6672]
	lea	rax, [rbp-6672]
	mov	rsi, rcx
	mov	rdi, rax
	call	poly_add
	lea	rdx, [rbp-7184]
	lea	rcx, [rbp-6672]
	lea	rax, [rbp-6672]
	mov	rsi, rcx
	mov	rdi, rax
	call	poly_add
	lea	rdx, [rbp-6672]
	lea	rcx, [rbp-6160]
	mov	rax, qword [rbp-7736]
	mov	rsi, rcx
	mov	rdi, rax
	call	pack_ciphertext
	nop
	leave
	ret

