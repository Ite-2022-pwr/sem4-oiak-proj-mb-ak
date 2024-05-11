BITS 64

section .note.GNU-stack
section .text

global indcpa_enc

%define KYBER_K 2
%define KYBER_N 256
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
	lea	rsi, [rbp-7728]           ; seed (unsigned char [KYBER_SYMBYTES])
	lea	rdi, [rbp-2064]           ; &pkpv (polyvec)
	call	unpack_pk

	mov	rsi, qword [rbp-7744]
	lea	rdi, [rbp-7184]           ; &k (poly)
	call	poly_frommsg

	lea	rdi, [rbp-2064]
	call	polyvec_ntt

	lea	rsi, [rbp-7728]           ; seed
	lea	rdi, [rbp-5136]           ; at (polyvec [KYBER_K])
	mov	edx, 1
	call	gen_matrix

	mov	dword [rbp-4], 0        ; int i = 0
.poly_getnoise_sp_loop:
	cmp	dword [rbp-4], KYBER_K        ; i < KYBER_K
	jge .poly_getnoise_sp_loop_end

	movzx	eax, byte [rbp-5]
	lea	edx, [rax+1]                  ; nonce++
	mov	byte [rbp-5], dl
	movzx	edx, al                     ; nonce

	mov	eax, dword [rbp-4]            ; i
	cdqe
	sal	rax, 9                        ; i * 2^9 = i * 512 = i * 2 * 256 = i * sizeof(uint16_t) * KYBER_N (rozmiar poly) = i << 9
	mov	rdi, rax
	lea	rax, [rbp-1040]               ; sp (polyvec)
	add	rdi, rax                      ; sp.vec + i
	mov	rsi, qword [rbp-7760]         ; coins
	call	poly_getnoise

	add	dword [rbp-4], 1              ; i++
  jmp .poly_getnoise_sp_loop

.poly_getnoise_sp_loop_end:
	lea	rax, [rbp-1040]               ; sp
	mov	rdi, rax
	call	polyvec_ntt

	mov	dword [rbp-4], 0              ; i = 0
	; jmp	.poly_getnoise_ep_loop_end

.poly_getnoise_ep_loop:
	cmp	dword [rbp-4], KYBER_K
	jge	.poly_getnoise_ep_loop_end

	movzx	eax, byte [rbp-5]           ; nonce
	lea	edx, [rax+1]                  ; nonce++
	mov	byte [rbp-5], dl
	movzx	edx, al                     ; nonce

	mov	eax, dword [rbp-4]            ; i
	cdqe
	sal	rax, 9                        ; i << 9 = i * sizeof(poly)
	mov	rdi, rax
	lea	rax, [rbp-3088]               ; ep (polyvec)
	add	rdi, rax                      ; ep.vec + i
	mov	rsi, qword [rbp-7760]         ; coins
	call	poly_getnoise

	add dword [rbp-4], 1              ; i++
  jmp .poly_getnoise_ep_loop

.poly_getnoise_ep_loop_end:

  ; matrix-vector multiplication
	mov	dword [rbp-4], 0                ; i = 0

.polyvec_pointwise_acc_loop:
	cmp	dword [rbp-4], KYBER_K
	jge	.polyvec_pointwise_acc_loop_end

	mov	eax, dword [rbp-4]              ; i
	cdqe
	sal	rax, 10                         ; i << 10 = i * 1024 = i * sizeof(polyvec)
	mov	rdx, rax
	lea	rax, [rbp-5136]                 ; at
	add	rdx, rax                        ; at + i (&at[i])

	mov	eax, dword [rbp-4]
  cdqe
	sal	rax, 9                          ; i << 9 = i * sizeof(poly)
  mov rdi, rax
	lea	rax, [rbp-6160]                 ; bp (polyvec)
	add	rdi, rax                        ; bp.vec + 1 (&bp.vec[i])

	lea	rsi, [rbp-1040]                 ; sp
	call	polyvec_pointwise_acc

	add	dword [rbp-4], 1                ; i++
  jmp .polyvec_pointwise_acc_loop

.polyvec_pointwise_acc_loop_end:

	lea	rdi, [rbp-6160]                 ; bp
	; mov	rdi, rax
	call	polyvec_invntt

	lea	rdx, [rbp-3088]                 ; ep
	lea	rsi, [rbp-6160]                 ; bp
	lea	rdi, [rbp-6160]                 ; bp
	call	polyvec_add

	lea	rdx, [rbp-1040]                 ; sp
	lea	rsi, [rbp-2064]                 ; pkpv
	lea	rdi, [rbp-6672]                 ; v (poly)
	call	polyvec_pointwise_acc

	lea	rdi, [rbp-6672]                 ; v
	call	poly_invntt

	movzx	eax, byte [rbp-5]             ; nonce
	lea	edx, [rax+1]                    ; nonce++
	mov	byte [rbp-5], dl
	movzx	edx, al

	mov	rsi, qword [rbp-7760]           ; coins
	lea	rdi, [rbp-7696]                 ; epp (poly)
	call	poly_getnoise

	lea	rdx, [rbp-7696]                 ; epp
	lea	rsi, [rbp-6672]                 ; v
	lea	rdi, [rbp-6672]                 ; v
	call	poly_add

	lea	rdx, [rbp-7184]                 ; k
	lea	rsi, [rbp-6672]                 ; v
	lea	rdi, [rbp-6672]                 ; v
	call	poly_add

	lea	rdx, [rbp-6672]                 ; v
	lea	rsi, [rbp-6160]                 ; bp
	mov	rdi, qword [rbp-7736]           ; c
	call	pack_ciphertext

	leave
	ret

