	.file	"indcpa.c"
	.intel_syntax noprefix
	.text
	.type	pack_pk, @function
pack_pk:
.LFB0:
	.cfi_startproc
	push	rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	mov	rbp, rsp
	.cfi_def_cfa_register 6
	sub	rsp, 48
	mov	QWORD PTR -24[rbp], rdi
	mov	QWORD PTR -32[rbp], rsi
	mov	QWORD PTR -40[rbp], rdx
	mov	rdx, QWORD PTR -32[rbp]
	mov	rax, QWORD PTR -24[rbp]
	mov	rsi, rdx
	mov	rdi, rax
	call	polyvec_compress@PLT
	mov	DWORD PTR -4[rbp], 0
	jmp	.L2
.L3:
	mov	eax, DWORD PTR -4[rbp]
	movsx	rdx, eax
	mov	rax, QWORD PTR -40[rbp]
	add	rax, rdx
	mov	edx, DWORD PTR -4[rbp]
	movsx	rdx, edx
	lea	rcx, 704[rdx]
	mov	rdx, QWORD PTR -24[rbp]
	add	rdx, rcx
	movzx	eax, BYTE PTR [rax]
	mov	BYTE PTR [rdx], al
	add	DWORD PTR -4[rbp], 1
.L2:
	cmp	DWORD PTR -4[rbp], 31
	jle	.L3
	nop
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	pack_pk, .-pack_pk
	.type	unpack_pk, @function
unpack_pk:
.LFB1:
	.cfi_startproc
	push	rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	mov	rbp, rsp
	.cfi_def_cfa_register 6
	sub	rsp, 48
	mov	QWORD PTR -24[rbp], rdi
	mov	QWORD PTR -32[rbp], rsi
	mov	QWORD PTR -40[rbp], rdx
	mov	rdx, QWORD PTR -40[rbp]
	mov	rax, QWORD PTR -24[rbp]
	mov	rsi, rdx
	mov	rdi, rax
	call	polyvec_decompress@PLT
	mov	DWORD PTR -4[rbp], 0
	jmp	.L5
.L6:
	mov	eax, DWORD PTR -4[rbp]
	cdqe
	lea	rdx, 704[rax]
	mov	rax, QWORD PTR -40[rbp]
	add	rax, rdx
	mov	edx, DWORD PTR -4[rbp]
	movsx	rcx, edx
	mov	rdx, QWORD PTR -32[rbp]
	add	rdx, rcx
	movzx	eax, BYTE PTR [rax]
	mov	BYTE PTR [rdx], al
	add	DWORD PTR -4[rbp], 1
.L5:
	cmp	DWORD PTR -4[rbp], 31
	jle	.L6
	nop
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1:
	.size	unpack_pk, .-unpack_pk
	.type	pack_ciphertext, @function
pack_ciphertext:
.LFB2:
	.cfi_startproc
	push	rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	mov	rbp, rsp
	.cfi_def_cfa_register 6
	sub	rsp, 32
	mov	QWORD PTR -8[rbp], rdi
	mov	QWORD PTR -16[rbp], rsi
	mov	QWORD PTR -24[rbp], rdx
	mov	rdx, QWORD PTR -16[rbp]
	mov	rax, QWORD PTR -8[rbp]
	mov	rsi, rdx
	mov	rdi, rax
	call	polyvec_compress@PLT
	mov	rax, QWORD PTR -8[rbp]
	lea	rdx, 704[rax]
	mov	rax, QWORD PTR -24[rbp]
	mov	rsi, rax
	mov	rdi, rdx
	call	poly_compress@PLT
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2:
	.size	pack_ciphertext, .-pack_ciphertext
	.type	unpack_ciphertext, @function
unpack_ciphertext:
.LFB3:
	.cfi_startproc
	push	rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	mov	rbp, rsp
	.cfi_def_cfa_register 6
	sub	rsp, 32
	mov	QWORD PTR -8[rbp], rdi
	mov	QWORD PTR -16[rbp], rsi
	mov	QWORD PTR -24[rbp], rdx
	mov	rdx, QWORD PTR -24[rbp]
	mov	rax, QWORD PTR -8[rbp]
	mov	rsi, rdx
	mov	rdi, rax
	call	polyvec_decompress@PLT
	mov	rax, QWORD PTR -24[rbp]
	lea	rdx, 704[rax]
	mov	rax, QWORD PTR -16[rbp]
	mov	rsi, rdx
	mov	rdi, rax
	call	poly_decompress@PLT
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE3:
	.size	unpack_ciphertext, .-unpack_ciphertext
	.type	pack_sk, @function
pack_sk:
.LFB4:
	.cfi_startproc
	push	rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	mov	rbp, rsp
	.cfi_def_cfa_register 6
	sub	rsp, 16
	mov	QWORD PTR -8[rbp], rdi
	mov	QWORD PTR -16[rbp], rsi
	mov	rdx, QWORD PTR -16[rbp]
	mov	rax, QWORD PTR -8[rbp]
	mov	rsi, rdx
	mov	rdi, rax
	call	polyvec_tobytes@PLT
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE4:
	.size	pack_sk, .-pack_sk
	.type	unpack_sk, @function
unpack_sk:
.LFB5:
	.cfi_startproc
	push	rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	mov	rbp, rsp
	.cfi_def_cfa_register 6
	sub	rsp, 16
	mov	QWORD PTR -8[rbp], rdi
	mov	QWORD PTR -16[rbp], rsi
	mov	rdx, QWORD PTR -16[rbp]
	mov	rax, QWORD PTR -8[rbp]
	mov	rsi, rdx
	mov	rdi, rax
	call	polyvec_frombytes@PLT
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE5:
	.size	unpack_sk, .-unpack_sk
	.globl	gen_matrix
	.type	gen_matrix, @function
gen_matrix:
.LFB6:
	.cfi_startproc
	push	rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	mov	rbp, rsp
	.cfi_def_cfa_register 6
	push	rbx
	sub	rsp, 344
	.cfi_offset 3, -24
	mov	QWORD PTR -328[rbp], rdi
	mov	QWORD PTR -336[rbp], rsi
	mov	DWORD PTR -340[rbp], edx
	mov	rax, rsp
	mov	rbx, rax
	mov	DWORD PTR -20[rbp], 0
	mov	DWORD PTR -28[rbp], 4
	mov	eax, DWORD PTR -28[rbp]
	imul	eax, eax, 168
	mov	edx, eax
	sub	rdx, 1
	mov	QWORD PTR -48[rbp], rdx
	mov	edx, eax
	mov	eax, 16
	sub	rax, 1
	add	rax, rdx
	mov	edi, 16
	mov	edx, 0
	div	rdi
	imul	rax, rax, 16
	sub	rsp, rax
	mov	rax, rsp
	add	rax, 0
	mov	QWORD PTR -56[rbp], rax
	mov	DWORD PTR -32[rbp], 0
	jmp	.L12
.L13:
	mov	eax, DWORD PTR -32[rbp]
	movsx	rdx, eax
	mov	rax, QWORD PTR -336[rbp]
	add	rax, rdx
	movzx	edx, BYTE PTR [rax]
	mov	eax, DWORD PTR -32[rbp]
	cdqe
	mov	BYTE PTR -320[rbp+rax], dl
	add	DWORD PTR -32[rbp], 1
.L12:
	cmp	DWORD PTR -32[rbp], 31
	jle	.L13
	mov	DWORD PTR -32[rbp], 0
	jmp	.L14
.L22:
	mov	DWORD PTR -36[rbp], 0
	jmp	.L15
.L21:
	mov	DWORD PTR -20[rbp], 0
	mov	eax, DWORD PTR -20[rbp]
	mov	DWORD PTR -24[rbp], eax
	cmp	DWORD PTR -340[rbp], 0
	je	.L16
	mov	eax, DWORD PTR -32[rbp]
	mov	BYTE PTR -288[rbp], al
	mov	eax, DWORD PTR -36[rbp]
	mov	BYTE PTR -287[rbp], al
	jmp	.L17
.L16:
	mov	eax, DWORD PTR -36[rbp]
	mov	BYTE PTR -288[rbp], al
	mov	eax, DWORD PTR -32[rbp]
	mov	BYTE PTR -287[rbp], al
.L17:
	lea	rcx, -320[rbp]
	lea	rax, -272[rbp]
	mov	edx, 34
	mov	rsi, rcx
	mov	rdi, rax
	call	shake128_absorb@PLT
	mov	ecx, DWORD PTR -28[rbp]
	lea	rdx, -272[rbp]
	mov	rax, QWORD PTR -56[rbp]
	mov	rsi, rcx
	mov	rdi, rax
	call	shake128_squeezeblocks@PLT
	jmp	.L18
.L20:
	mov	rdx, QWORD PTR -56[rbp]
	mov	eax, DWORD PTR -20[rbp]
	movzx	eax, BYTE PTR [rdx+rax]
	movzx	edx, al
	mov	eax, DWORD PTR -20[rbp]
	lea	ecx, 1[rax]
	mov	rax, QWORD PTR -56[rbp]
	mov	ecx, ecx
	movzx	eax, BYTE PTR [rax+rcx]
	movzx	eax, al
	sal	eax, 8
	or	eax, edx
	and	ax, 8191
	mov	WORD PTR -58[rbp], ax
	cmp	WORD PTR -58[rbp], 7680
	ja	.L19
	mov	eax, DWORD PTR -32[rbp]
	cdqe
	sal	rax, 10
	mov	rdx, rax
	mov	rax, QWORD PTR -328[rbp]
	lea	rcx, [rdx+rax]
	mov	eax, DWORD PTR -24[rbp]
	lea	edx, 1[rax]
	mov	DWORD PTR -24[rbp], edx
	mov	edx, eax
	mov	eax, DWORD PTR -36[rbp]
	cdqe
	sal	rax, 8
	add	rdx, rax
	movzx	eax, WORD PTR -58[rbp]
	mov	WORD PTR [rcx+rdx*2], ax
.L19:
	add	DWORD PTR -20[rbp], 2
	mov	eax, DWORD PTR -28[rbp]
	imul	eax, eax, 168
	sub	eax, 2
	cmp	eax, DWORD PTR -20[rbp]
	jnb	.L18
	mov	DWORD PTR -28[rbp], 1
	mov	ecx, DWORD PTR -28[rbp]
	lea	rdx, -272[rbp]
	mov	rax, QWORD PTR -56[rbp]
	mov	rsi, rcx
	mov	rdi, rax
	call	shake128_squeezeblocks@PLT
	mov	DWORD PTR -20[rbp], 0
.L18:
	cmp	DWORD PTR -24[rbp], 255
	jbe	.L20
	add	DWORD PTR -36[rbp], 1
.L15:
	cmp	DWORD PTR -36[rbp], 1
	jle	.L21
	add	DWORD PTR -32[rbp], 1
.L14:
	cmp	DWORD PTR -32[rbp], 1
	jle	.L22
	mov	rsp, rbx
	nop
	mov	rbx, QWORD PTR -8[rbp]
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE6:
	.size	gen_matrix, .-gen_matrix
	.globl	indcpa_keypair
	.type	indcpa_keypair, @function
indcpa_keypair:
.LFB7:
	.cfi_startproc
	push	rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	mov	rbp, rsp
	.cfi_def_cfa_register 6
	sub	rsp, 5232
	mov	QWORD PTR -5224[rbp], rdi
	mov	QWORD PTR -5232[rbp], rsi
	lea	rax, -5216[rbp]
	mov	QWORD PTR -16[rbp], rax
	lea	rax, -5216[rbp]
	add	rax, 32
	mov	QWORD PTR -24[rbp], rax
	mov	BYTE PTR -5[rbp], 0
	lea	rax, -5216[rbp]
	mov	esi, 32
	mov	rdi, rax
	call	randombytes@PLT
	lea	rcx, -5216[rbp]
	lea	rax, -5216[rbp]
	mov	edx, 32
	mov	rsi, rcx
	mov	rdi, rax
	call	sha3_512@PLT
	mov	rcx, QWORD PTR -16[rbp]
	lea	rax, -2080[rbp]
	mov	edx, 0
	mov	rsi, rcx
	mov	rdi, rax
	call	gen_matrix
	mov	DWORD PTR -4[rbp], 0
	jmp	.L24
.L25:
	movzx	eax, BYTE PTR -5[rbp]
	lea	edx, 1[rax]
	mov	BYTE PTR -5[rbp], dl
	movzx	edx, al
	mov	eax, DWORD PTR -4[rbp]
	cdqe
	sal	rax, 9
	mov	rcx, rax
	lea	rax, -5152[rbp]
	add	rcx, rax
	mov	rax, QWORD PTR -24[rbp]
	mov	rsi, rax
	mov	rdi, rcx
	call	poly_getnoise@PLT
	add	DWORD PTR -4[rbp], 1
.L24:
	cmp	DWORD PTR -4[rbp], 1
	jle	.L25
	lea	rax, -5152[rbp]
	mov	rdi, rax
	call	polyvec_ntt@PLT
	mov	DWORD PTR -4[rbp], 0
	jmp	.L26
.L27:
	movzx	eax, BYTE PTR -5[rbp]
	lea	edx, 1[rax]
	mov	BYTE PTR -5[rbp], dl
	movzx	edx, al
	mov	eax, DWORD PTR -4[rbp]
	cdqe
	sal	rax, 9
	mov	rcx, rax
	lea	rax, -3104[rbp]
	add	rcx, rax
	mov	rax, QWORD PTR -24[rbp]
	mov	rsi, rax
	mov	rdi, rcx
	call	poly_getnoise@PLT
	add	DWORD PTR -4[rbp], 1
.L26:
	cmp	DWORD PTR -4[rbp], 1
	jle	.L27
	mov	DWORD PTR -4[rbp], 0
	jmp	.L28
.L29:
	mov	eax, DWORD PTR -4[rbp]
	cdqe
	sal	rax, 10
	mov	rdx, rax
	lea	rax, -2080[rbp]
	add	rdx, rax
	lea	rax, -4128[rbp]
	mov	ecx, DWORD PTR -4[rbp]
	movsx	rcx, ecx
	sal	rcx, 9
	add	rcx, rax
	lea	rax, -5152[rbp]
	mov	rsi, rax
	mov	rdi, rcx
	call	polyvec_pointwise_acc@PLT
	add	DWORD PTR -4[rbp], 1
.L28:
	cmp	DWORD PTR -4[rbp], 1
	jle	.L29
	lea	rax, -4128[rbp]
	mov	rdi, rax
	call	polyvec_invntt@PLT
	lea	rdx, -3104[rbp]
	lea	rcx, -4128[rbp]
	lea	rax, -4128[rbp]
	mov	rsi, rcx
	mov	rdi, rax
	call	polyvec_add@PLT
	lea	rdx, -5152[rbp]
	mov	rax, QWORD PTR -5232[rbp]
	mov	rsi, rdx
	mov	rdi, rax
	call	pack_sk
	mov	rdx, QWORD PTR -16[rbp]
	lea	rcx, -4128[rbp]
	mov	rax, QWORD PTR -5224[rbp]
	mov	rsi, rcx
	mov	rdi, rax
	call	pack_pk
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE7:
	.size	indcpa_keypair, .-indcpa_keypair
	.globl	indcpa_enc
	.type	indcpa_enc, @function
indcpa_enc:
.LFB8:
	.cfi_startproc
	push	rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	mov	rbp, rsp
	.cfi_def_cfa_register 6
	sub	rsp, 7760
	mov	QWORD PTR -7736[rbp], rdi
	mov	QWORD PTR -7744[rbp], rsi
	mov	QWORD PTR -7752[rbp], rdx
	mov	QWORD PTR -7760[rbp], rcx
	mov	BYTE PTR -5[rbp], 0
	mov	rdx, QWORD PTR -7752[rbp]
	lea	rcx, -7728[rbp]
	lea	rax, -2064[rbp]
	mov	rsi, rcx
	mov	rdi, rax
	call	unpack_pk
	mov	rdx, QWORD PTR -7744[rbp]
	lea	rax, -7184[rbp]
	mov	rsi, rdx
	mov	rdi, rax
	call	poly_frommsg@PLT
	lea	rax, -2064[rbp]
	mov	rdi, rax
	call	polyvec_ntt@PLT
	lea	rcx, -7728[rbp]
	lea	rax, -5136[rbp]
	mov	edx, 1
	mov	rsi, rcx
	mov	rdi, rax
	call	gen_matrix
	mov	DWORD PTR -4[rbp], 0
	jmp	.L31
.L32:
	movzx	eax, BYTE PTR -5[rbp]
	lea	edx, 1[rax]
	mov	BYTE PTR -5[rbp], dl
	movzx	edx, al
	mov	eax, DWORD PTR -4[rbp]
	cdqe
	sal	rax, 9
	mov	rcx, rax
	lea	rax, -1040[rbp]
	add	rcx, rax
	mov	rax, QWORD PTR -7760[rbp]
	mov	rsi, rax
	mov	rdi, rcx
	call	poly_getnoise@PLT
	add	DWORD PTR -4[rbp], 1
.L31:
	cmp	DWORD PTR -4[rbp], 1
	jle	.L32
	lea	rax, -1040[rbp]
	mov	rdi, rax
	call	polyvec_ntt@PLT
	mov	DWORD PTR -4[rbp], 0
	jmp	.L33
.L34:
	movzx	eax, BYTE PTR -5[rbp]
	lea	edx, 1[rax]
	mov	BYTE PTR -5[rbp], dl
	movzx	edx, al
	mov	eax, DWORD PTR -4[rbp]
	cdqe
	sal	rax, 9
	mov	rcx, rax
	lea	rax, -3088[rbp]
	add	rcx, rax
	mov	rax, QWORD PTR -7760[rbp]
	mov	rsi, rax
	mov	rdi, rcx
	call	poly_getnoise@PLT
	add	DWORD PTR -4[rbp], 1
.L33:
	cmp	DWORD PTR -4[rbp], 1
	jle	.L34
	mov	DWORD PTR -4[rbp], 0
	jmp	.L35
.L36:
	mov	eax, DWORD PTR -4[rbp]
	cdqe
	sal	rax, 10
	mov	rdx, rax
	lea	rax, -5136[rbp]
	add	rdx, rax
	lea	rax, -6160[rbp]
	mov	ecx, DWORD PTR -4[rbp]
	movsx	rcx, ecx
	sal	rcx, 9
	add	rcx, rax
	lea	rax, -1040[rbp]
	mov	rsi, rax
	mov	rdi, rcx
	call	polyvec_pointwise_acc@PLT
	add	DWORD PTR -4[rbp], 1
.L35:
	cmp	DWORD PTR -4[rbp], 1
	jle	.L36
	lea	rax, -6160[rbp]
	mov	rdi, rax
	call	polyvec_invntt@PLT
	lea	rdx, -3088[rbp]
	lea	rcx, -6160[rbp]
	lea	rax, -6160[rbp]
	mov	rsi, rcx
	mov	rdi, rax
	call	polyvec_add@PLT
	lea	rdx, -1040[rbp]
	lea	rcx, -2064[rbp]
	lea	rax, -6672[rbp]
	mov	rsi, rcx
	mov	rdi, rax
	call	polyvec_pointwise_acc@PLT
	lea	rax, -6672[rbp]
	mov	rdi, rax
	call	poly_invntt@PLT
	movzx	eax, BYTE PTR -5[rbp]
	lea	edx, 1[rax]
	mov	BYTE PTR -5[rbp], dl
	movzx	edx, al
	mov	rcx, QWORD PTR -7760[rbp]
	lea	rax, -7696[rbp]
	mov	rsi, rcx
	mov	rdi, rax
	call	poly_getnoise@PLT
	lea	rdx, -7696[rbp]
	lea	rcx, -6672[rbp]
	lea	rax, -6672[rbp]
	mov	rsi, rcx
	mov	rdi, rax
	call	poly_add@PLT
	lea	rdx, -7184[rbp]
	lea	rcx, -6672[rbp]
	lea	rax, -6672[rbp]
	mov	rsi, rcx
	mov	rdi, rax
	call	poly_add@PLT
	lea	rdx, -6672[rbp]
	lea	rcx, -6160[rbp]
	mov	rax, QWORD PTR -7736[rbp]
	mov	rsi, rcx
	mov	rdi, rax
	call	pack_ciphertext
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE8:
	.size	indcpa_enc, .-indcpa_enc
	.globl	indcpa_dec
	.type	indcpa_dec, @function
indcpa_dec:
.LFB9:
	.cfi_startproc
	push	rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	mov	rbp, rsp
	.cfi_def_cfa_register 6
	sub	rsp, 3104
	mov	QWORD PTR -3080[rbp], rdi
	mov	QWORD PTR -3088[rbp], rsi
	mov	QWORD PTR -3096[rbp], rdx
	mov	rdx, QWORD PTR -3088[rbp]
	lea	rcx, -2560[rbp]
	lea	rax, -1024[rbp]
	mov	rsi, rcx
	mov	rdi, rax
	call	unpack_ciphertext
	mov	rdx, QWORD PTR -3096[rbp]
	lea	rax, -2048[rbp]
	mov	rsi, rdx
	mov	rdi, rax
	call	unpack_sk
	lea	rax, -1024[rbp]
	mov	rdi, rax
	call	polyvec_ntt@PLT
	lea	rdx, -1024[rbp]
	lea	rcx, -2048[rbp]
	lea	rax, -3072[rbp]
	mov	rsi, rcx
	mov	rdi, rax
	call	polyvec_pointwise_acc@PLT
	lea	rax, -3072[rbp]
	mov	rdi, rax
	call	poly_invntt@PLT
	lea	rdx, -2560[rbp]
	lea	rcx, -3072[rbp]
	lea	rax, -3072[rbp]
	mov	rsi, rcx
	mov	rdi, rax
	call	poly_sub@PLT
	lea	rdx, -3072[rbp]
	mov	rax, QWORD PTR -3080[rbp]
	mov	rsi, rdx
	mov	rdi, rax
	call	poly_tomsg@PLT
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE9:
	.size	indcpa_dec, .-indcpa_dec
	.ident	"GCC: (Debian 13.2.0-13) 13.2.0"
	.section	.note.GNU-stack,"",@progbits
