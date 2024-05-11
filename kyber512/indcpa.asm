BITS 64

section .note.GNU-stack
section .text

global indcpa_enc
global indcpa_dec
global pack_pk
global unpack_pk
global pack_ciphertext
global unpack_ciphertext
global pack_sk
global unpack_sk

%define KYBER_K 2
%define KYBER_N 256
%define KYBER_SYMBYTES 32
%define KYBER_POLYVECCOMPRESSEDBYTES (KYBER_K * 352) 

extern poly_frommsg
extern poly_getnoise
extern poly_invntt
extern poly_add
extern poly_compress
extern poly_decompress
extern poly_tomsg
extern poly_sub


extern polyvec_tobytes
extern polyvec_frombytes
extern polyvec_ntt
extern polyvec_pointwise_acc
extern polyvec_invntt
extern polyvec_add
extern polyvec_compress
extern polyvec_decompress

extern gen_matrix

; /*************************************************
; * Name:        pack_pk
; * 
; * Description: Serialize the public key as concatenation of the
; *              compressed and serialized vector of polynomials pk 
; *              and the public seed used to generate the matrix A.
; *
; * Arguments:   unsigned char *r:          pointer to the output serialized public key
; *              const poly *pk:            pointer to the input public-key polynomial
; *              const unsigned char *seed: pointer to the input public seed
; **************************************************/
pack_pk:
	push rbp
	mov	rbp, rsp
	sub	rsp, 48
	mov	qword [rbp-24], rdi     ; unisgned char *r
	mov	qword [rbp-32], rsi     ; const poly *pk
	mov	qword [rbp-40], rdx     ; const unsigned char *seed

	call	polyvec_compress

	mov	dword [rbp-4], 0    ; i = 0

.pack_pk_loop:
	cmp	dword [rbp-4], KYBER_SYMBYTES
	jge	.pack_pk_loop_end

	mov	eax, dword [rbp-4]
	movsx	rdx, eax                                ; i
	mov	rax, qword [rbp-40]                       ; seed
	add	rax, rdx                                  ; seed + i
	mov	edx, dword [rbp-4]                        ; i
	movsx	rdx, edx
	lea	rcx, [rdx+KYBER_POLYVECCOMPRESSEDBYTES]   ; i + KYBER_POLYVECCOMPRESSEDBYTES
	mov	rdx, qword [rbp-24]                       ; r
	add	rdx, rcx                                  ; r + i + KYBER_POLYVECCOMPRESSEDBYTES
	movzx	eax, byte [rax]                         ; seed[i]
	mov	byte [rdx], al                            ; r[i+KYBER_POLYVECCOMPRESSEDBYTES] = seed[i]

	add	dword [rbp-4], 1            ; i++
  jmp .pack_pk_loop

.pack_pk_loop_end:
	leave
	ret

; /*************************************************
; * Name:        unpack_pk
; * 
; * Description: De-serialize and decompress public key from a byte array;
; *              approximate inverse of pack_pk
; *
; * Arguments:   - polyvec *pk:                   pointer to output public-key vector of polynomials
; *              - unsigned char *seed:           pointer to output seed to generate matrix A
; *              - const unsigned char *packedpk: pointer to input serialized public key
; **************************************************/
unpack_pk:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 48
	mov	qword [rbp-24], rdi                     ; polyvec *pk
	mov	qword [rbp-32], rsi                     ; unsigned char *seed
	mov	qword [rbp-40], rdx                     ; const unsigned char *packedpk

	mov	rsi, qword [rbp-40]
	call	polyvec_decompress

	mov	dword [rbp-4], 0                        ; i = 0

.unpack_pk_loop:
	cmp	dword [rbp-4], KYBER_SYMBYTES
	jge	.unpack_pk_loop_end

	mov	eax, dword [rbp-4]                      ; i
	cdqe
	lea	rdx, [rax+KYBER_POLYVECCOMPRESSEDBYTES] ; i + KYBER_POLYVECCOMPRESSEDBYTES
	mov	rax, qword [rbp-40]                     ; packedpk
	add	rax, rdx                                ; packedpk + i + KYBER_POLYVECCOMPRESSEDBYTES
	mov	edx, dword [rbp-4]
	movsx	rcx, edx                              ; i
	mov	rdx, qword [rbp-32]                     ; seed
	add	rdx, rcx                                ; seed + i
	movzx	eax, byte [rax]                       ; packedpk[i+KYBER_POLYVECCOMPRESSEDBYTES]
	mov	byte [rdx], al                          ; seed[i] = packedpk[i+KYBER_POLYVECCOMPRESSEDBYTES]

	add	dword [rbp-4], 1                        ; i++
  jmp .unpack_pk_loop

.unpack_pk_loop_end:
	leave
	ret


; /*************************************************
; * Name:        pack_ciphertext
; * 
; * Description: Serialize the ciphertext as concatenation of the
; *              compressed and serialized vector of polynomials b
; *              and the compressed and serialized polynomial v
; *
; * Arguments:   unsigned char *r:          pointer to the output serialized ciphertext
; *              const polyvec *b:          pointer to the input vector of polynomials b
; *              const poly *v:             pointer to the input polynomial v
; **************************************************/
pack_ciphertext:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 32
	mov	qword [rbp-8], rdi                        ; unsigned char *r
	mov	qword [rbp-16], rsi                       ; const polyvec *b
	mov	qword [rbp-24], rdx                       ; const poly *v

	call	polyvec_compress

	mov	rax, qword [rbp-8]                        ; r
	lea	rdi, [rax+KYBER_POLYVECCOMPRESSEDBYTES]   ; r + KYBER_POLYVECCOMPRESSEDBYTES
	mov	rsi, qword[rbp-24]                        ; v
	call	poly_compress
	
	leave
	ret

; /*************************************************
; * Name:        unpack_ciphertext
; * 
; * Description: De-serialize and decompress ciphertext from a byte array;
; *              approximate inverse of pack_ciphertext
; *
; * Arguments:   - polyvec *b:             pointer to the output vector of polynomials b
; *              - poly *v:                pointer to the output polynomial v
; *              - const unsigned char *c: pointer to the input serialized ciphertext
; **************************************************/
unpack_ciphertext:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 32
	mov	qword [rbp-8], rdi                          ; polyvec *b
	mov	qword [rbp-16], rsi                         ; poly *v
	mov	qword [rbp-24], rdx                         ; const unsigned char *c

	mov	rsi, qword [rbp-24]
	call	polyvec_decompress

	mov	rax, qword [rbp-24]                         ; c
	lea	rsi, [rax+KYBER_POLYVECCOMPRESSEDBYTES]     ; c + KYBER_POLYVECCOMPRESSEDBYTES
	mov	rdi, qword [rbp-16]                         ; v
	call	poly_decompress

	leave
	ret

; /*************************************************
; * Name:        pack_sk
; * 
; * Description: Serialize the secret key
; *
; * Arguments:   - unsigned char *r:  pointer to output serialized secret key
; *              - const polyvec *sk: pointer to input vector of polynomials (secret key)
; **************************************************/
pack_sk:
	push	rbp
	mov	rbp, rsp

	call	polyvec_tobytes

	leave
	ret

; /*************************************************
; * Name:        unpack_sk
; * 
; * Description: De-serialize the secret key;
; *              inverse of pack_sk
; *
; * Arguments:   - polyvec *sk:                   pointer to output vector of polynomials (secret key)
; *              - const unsigned char *packedsk: pointer to input serialized secret key
; **************************************************/
unpack_sk:
	push	rbp
	mov	rbp, rsp

	call	polyvec_frombytes

	leave
	ret

; /*************************************************
; * Name:        indcpa_enc
; * 
; * Description: Encryption function of the CPA-secure 
; *              public-key encryption scheme underlying Kyber.
; *
; * Arguments:   - unsigned char *c:          pointer to output ciphertext
; *              - const unsigned char *m:    pointer to input message (of length KYBER_SYMBYTES bytes)
; *              - const unsigned char *pk:   pointer to input public key
; *              - const unsigned char *coin: pointer to input random coins used as seed
; *                                           to deterministically generate all randomness
; **************************************************/
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


; /*************************************************
; * Name:        indcpa_dec
; * 
; * Description: Decryption function of the CPA-secure 
; *              public-key encryption scheme underlying Kyber.
; *
; * Arguments:   - unsigned char *m:        pointer to output decrypted message
; *              - const unsigned char *c:  pointer to input ciphertext
; *              - const unsigned char *sk: pointer to input secret key
; **************************************************/
indcpa_dec:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 3120
	mov	qword  [rbp-3096], rdi
	mov	qword  [rbp-3104], rsi
	mov	qword  [rbp-3112], rdx
	
	mov	qword  [rbp-8], rax
	xor	eax, eax
	mov	rdx, qword  [rbp-3104]
	lea	rcx, [rbp-3088]
	lea	rax, [rbp-2064]
	mov	rsi, rcx
	mov	rdi, rax
	
	call	unpack_ciphertext

	mov	rdx, qword  [rbp-3112]
	lea	rax, [rbp-1040]
	mov	rsi, rdx
	mov	rdi, rax

	call	unpack_sk

	lea	rax, [rbp-2064]
	mov	rdi, rax

	call	polyvec_ntt

	lea	rdx, [rbp-2064]
	lea	rcx, [rbp-1040]
	lea	rax, [rbp-2576]
	mov	rsi, rcx
	mov	rdi, rax

	call	polyvec_pointwise_acc

	lea	rax, [rbp-2576]
	mov	rdi, rax

	call	poly_invntt
	lea	rdx, [rbp-3088]
	lea	rcx, [rbp-2576]
	lea	rax, [rbp-2576]
	mov	rsi, rcx
	mov	rdi, rax

	call	poly_sub

	lea	rdx, [rbp-2576]
	mov	rax, qword  [rbp-3096]
	mov	rsi, rdx
	mov	rdi, rax
	call	poly_tomsg

	leave
	ret