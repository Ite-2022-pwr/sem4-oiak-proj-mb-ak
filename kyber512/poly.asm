BITS 64

section .note.GNU-stack
section .text

%define KYBER_N 256
%define KYBER_SYMBYTES 32
%define KYBER_Q 7681
%define KYBER_ETA 5

global poly_ntt
global poly_invntt
global poly_add
global poly_sub
global poly_frommsg
global poly_tomsg
global poly_getnoise

extern ntt
extern invntt
extern barrett_reduce
extern freeze
extern shake256
extern cbd

; /*************************************************
; * Name:        poly_ntt
; * 
; * Description: Computes negacyclic number-theoretic transform (NTT) of
; *              a polynomial in place; 
; *              inputs assumed to be in normal order, output in bitreversed order
; *
; * Arguments:   - uint16_t *r: pointer to in/output polynomial
; **************************************************/
poly_ntt:
	push	rbp
	mov	rbp, rsp

	call	ntt

	leave
	ret

; /*************************************************
; * Name:        poly_invntt
; * 
; * Description: Computes inverse of negacyclic number-theoretic transform (NTT) of
; *              a polynomial in place; 
; *              inputs assumed to be in bitreversed order, output in normal order
; *
; * Arguments:   - uint16_t *a: pointer to in/output polynomial
; **************************************************/
poly_invntt:
	push	rbp
	mov	rbp, rsp

  call	invntt

	leave
	ret

; /*************************************************
; * Name:        poly_add
; * 
; * Description: Add two polynomials
; *
; * Arguments: - poly *r:       pointer to output polynomial
; *            - const poly *a: pointer to first input polynomial
; *            - const poly *b: pointer to second input polynomial
; **************************************************/ 
poly_add:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 48
	mov	qword [rbp-24], rdi         ; poly *r
	mov	qword [rbp-32], rsi         ; const poly *a
	mov	qword [rbp-40], rdx         ; const poly *b

	mov	dword [rbp-4], 0            ; i = 0

.poly_add_loop:
	cmp	dword [rbp-4], KYBER_N      ; i < KYBER_N
	jge	.poly_add_loop_end

	mov	rax, qword [rbp-32]         ; a
	mov	edx, dword [rbp-4]          ; i
	movsx	rdx, edx

	movzx	ecx, word [rax+rdx*2]     ; a->coeffs[i]

	mov	rax, qword [rbp-40]         ; b
	movzx	eax, word [rax+rdx*2]     ; b->coeffs[i]
	add	eax, ecx                    ; b->coeffs[i] + a->coeffs[i]
	movzx	eax, ax

	mov	edi, eax
	call	barrett_reduce

	mov	rdx, qword [rbp-24]         ; r
	mov	ecx, dword [rbp-4]          ; i
	movsx	rcx, ecx
	mov	word [rdx+rcx*2], ax        ; r->coeffs[i] = barrett_reduce(a->coeffs[i] + b->coeffs[i])

	add	dword [rbp-4], 1
  jmp .poly_add_loop

.poly_add_loop_end:
	leave
	ret

; /*************************************************
; * Name:        poly_sub
; * 
; * Description: Subtract two polynomials
; *
; * Arguments: - poly *r:       pointer to output polynomial
; *            - const poly *a: pointer to first input polynomial
; *            - const poly *b: pointer to second input polynomial
; **************************************************/ 
poly_sub:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 48
	mov	qword [rbp-24], rdi             ; poly *r
	mov	qword [rbp-32], rsi             ; const poly *a
	mov	qword [rbp-40], rdx             ; const poly *b

	mov	dword [rbp-4], 0                ; i = 0

.poly_sub_loop:
	cmp	dword [rbp-4], KYBER_N          ; i < KYBER_N
	jge	.poly_add_loop_end

	mov	rax, qword [rbp-32]             ; a
	mov	edx, dword [rbp-4]              ; i
	movsx	rdx, edx
	movzx	ecx, word [rax+rdx*2]         ; a->coeffs[i]

	mov	rax, qword [rbp-40]             ; b
	movzx	edx, word [rax+rdx*2]         ; b->coeffs[i]
	mov	eax, ecx
	sub	eax, edx                        ; a->coeffs[i] - b->coeffs[i]

	add	ax, KYBER_Q
	add	ax, KYBER_Q
	add	ax, KYBER_Q
	movzx	eax, ax
	mov	edi, eax                        ; a->coeffs - b->coeffs[i] + 3 * KYBER_Q
	call	barrett_reduce

	mov	rdx, qword [rbp-24]             ; r
	mov	ecx, dword [rbp-4]              ; i
	movsx	rcx, ecx
	mov	word [rdx+rcx*2], ax            ; r->coeffs[i]

	add	dword[rbp-4], 1                 ; i++
  jmp .poly_sub_loop

.poly_add_loop_end:
	leave
	ret

; /*************************************************
; * Name:        poly_frommsg
; * 
; * Description: Convert 32-byte message to polynomial
; *
; * Arguments:   - poly *r:                  pointer to output polynomial
; *              - const unsigned char *msg: pointer to input message
; **************************************************/
poly_frommsg:
	push	rbp
	mov	rbp, rsp
	mov	qword [rbp-24], rdi                       ; poly *r
	mov	qword [rbp-32], rsi                       ; const unsigned char *msg

	mov	word [rbp-2], 0                           ; i = 0

.poly_frommsg_loop_outer:
	cmp	word [rbp-2], KYBER_SYMBYTES
	jge	.poly_frommsg_loop_outer_end
	mov	word [rbp-4], 0                           ; j = 0

.poly_frommsg_loop_inner:
	cmp	word [rbp-4], 8                           ; j < 8
	jge	.poly_frommsg_loop_inner_end

	movzx	edx, word [rbp-2]                       ; i
	mov	rax, qword [rbp-32]                       ; msg
	add	rax, rdx                                  ; msg + i
	movzx	eax, byte [rax]                         ; msg[i]
	movzx	edx, al
	movzx	eax, word [rbp-4]                       ; j
	mov	ecx, eax
	sar	edx, cl                                   ; msg[i] >> j
	mov	eax, edx
	and	eax, 1                                    ; (msg[i] >> j) & 1
	neg	eax                                       ; -((msg[i] >> j) & 1)
	mov	word [rbp-6], ax                          ; uint16_t mask = -((msg[i] >> j) & 1)

	movzx	eax, word [rbp-2]                       ; i
	lea	edx, [0+rax*8]                            ; i * 8
	movzx	eax, word [rbp-4]                       ; j
	add	edx, eax                                  ; i * 8 + j
	movsx	rdx, edx
  
  mov rbx, KYBER_Q
  inc ebx
  sar ebx, 1                                    ; (KYBER_Q + 1) / 2

	movzx	eax, word [rbp-6]                       ; mask
	and	ax, bx                                    ; mask & ((KYBER_Q + 1) / 2)

	mov	ecx, eax
	mov	rax, qword [rbp-24]                       ; r
	mov	word [rax+rdx*2], cx                      ; r->coeffs[i * 8 + j] = mask & ((KYBER_Q + 1) / 2)

	movzx	eax, word [rbp-4]                       ; j
	add	eax, 1                                    ; j++
	mov	word [rbp-4], ax
  jmp .poly_frommsg_loop_inner

.poly_frommsg_loop_inner_end:
	movzx	eax, word [rbp-2]
	add	eax, 1                                    ; i++
	mov	word [rbp-2], ax
  jmp .poly_frommsg_loop_outer

.poly_frommsg_loop_outer_end:
	leave
	ret

; /*************************************************
; * Name:        poly_tomsg
; * 
; * Description: Convert polynomial to 32-byte message
; *
; * Arguments:   - unsigned char *msg: pointer to output message
; *              - const poly *a:      pointer to input polynomial
; **************************************************/
poly_tomsg:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 32
	mov	qword [rbp-24], rdi                       ; unsigned char *msg
	mov	qword [rbp-32], rsi                       ; const poly *a

	mov	dword [rbp-4], 0                          ; i = 0

.poly_tomsg_loop_outer:
	cmp	dword [rbp-4], KYBER_SYMBYTES             ; i < KYBER_SYMBYTES
	jge	.poly_tomsg_loop_outer_end

	mov	eax, dword [rbp-4]                        ; i
	movsx	rdx, eax
	mov	rax, qword [rbp-24]                       ; msg
	add	rax, rdx                                  ; msg + i
	mov	byte [rax], 0                             ; msg[i] = 0

	mov	dword [rbp-8], 0                          ; j = 0

.poly_tomsg_loop_inner:
	cmp	dword [rbp-8], 8                          ; j < 8
	jge	.poly_tomsg_loop_inner_end

	mov	eax, dword [rbp-4]                        ; i
	lea	edx, [0+rax*8]                            ; i * 8
	mov	eax, dword [rbp-8]                        ; j
	add	edx, eax                                  ; i * 8 + j
	mov	rax, qword [rbp-32]                       ; a
	movzx	eax, word [rax+rdx*2]                   ; a->coeffs[i * 8  j]
	mov	edi, eax
	call	freeze

  sal eax, 1                                    ; freeze(a->coeffs[8*i+j]) << 1

  mov rbx, KYBER_Q
  sar rbx, 1                                    ; KYBER_Q / 2
	add	eax, ebx                                  ; (freeze(a->coeffs[8*i+j]) << 1) + KYBER_Q/2
  
  xor rdx, rdx
  mov ebx, KYBER_Q
  div ebx                                       ; ((freeze(a->coeffs[8*i+j]) << 1) + KYBER_Q/2)/KYBER_Q

	and	eax, 1                                    ; (((freeze(a->coeffs[8*i+j]) << 1) + KYBER_Q/2)/KYBER_Q) & 1
	mov	word [rbp-10], ax                         ; t = (((freeze(a->coeffs[8*i+j]) << 1) + KYBER_Q/2)/KYBER_Q) & 1

	mov	eax, dword [rbp-4]                        ; i
	movsx	rdx, eax
	mov	rax, qword [rbp-24]                       ; msg
	add	rax, rdx                                  ; msg + i
	movzx	eax, byte [rax]                         ; msg[i]
	mov	esi, eax

	movzx	edx, word [rbp-10]                      ; t
	mov	ecx, dword [rbp-8]                        ; j
	sal	edx, cl                                   ; t << j
	mov	eax, edx
	or	esi, eax                                  ; msg[i] | t << j
	mov	ecx, esi

	mov	eax, dword [rbp-4]                        ; i
	movsx	rdx, eax
	mov	rax, qword [rbp-24]                       ; msg
	add	rax, rdx                                  ; msg + i
	mov	edx, ecx
	mov	byte [rax], dl                            ; msg[i] |= t << j

	add	dword [rbp-8], 1                          ; j++
  jmp .poly_tomsg_loop_inner

.poly_tomsg_loop_inner_end:
	add	dword [rbp-4], 1                              ; i++
  jmp .poly_tomsg_loop_outer

.poly_tomsg_loop_outer_end:
	leave
	ret

; /*************************************************
; * Name:        poly_getnoise
; * 
; * Description: Sample a polynomial deterministically from a seed and a nonce,
; *              with output polynomial close to centered binomial distribution
; *              with parameter KYBER_ETA
; *
; * Arguments:   - poly *r:                   pointer to output polynomial
; *              - const unsigned char *seed: pointer to input seed 
; *              - unsigned char nonce:       one-byte input nonce
; **************************************************/
poly_getnoise:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 416
	mov	qword [rbp-392], rdi                      ; poly *r
	mov	qword [rbp-400], rsi                      ; const unsigned char *seed
	mov	byte [rbp-404], dl                        ; unsigned char nonce

	mov	dword [rbp-4], 0                          ; i = 0
.poly_getnoise_loop:
	cmp	dword [rbp-4], KYBER_SYMBYTES
	jge	.poly_getnoise_loop_end

	movsxd	rdx, dword [rbp-4]                    ; i
	mov	rax, qword [rbp-400]                      ; seed
	add	rax, rdx                                  ; seed + i
	movzx	edx, byte [rax]                         ; seed[i]
	mov	eax, dword [rbp-4]                        ; i
	cdqe
	mov	byte [rbp+rax-384], dl                    ; extseed[i] = seed[i]

	add	dword [rbp-4], 1                          ; i++
  jmp .poly_getnoise_loop

.poly_getnoise_loop_end:

	movzx	eax, byte [rbp-404]                     ; nonce
	mov	byte [rbp-384+KYBER_SYMBYTES], al         ; extseed[KYBER_SYMBYTES] = nonce

	lea	rdi, [rbp-336]                            ; buf
	lea	esi, [KYBER_ETA*KYBER_N/4]                ; KYBER_ETA * KYBER_N / 4
	lea	rdx, [rbp-384]                            ; extseed
	lea	ecx, [KYBER_SYMBYTES+1]                   ; KYBER_SYMBYTES + 1
	call	shake256

	lea	rsi, [rbp-336]                            ; buf
	mov	rdi, qword [rbp-392]                      ; r
	call	cbd

	leave
	ret

