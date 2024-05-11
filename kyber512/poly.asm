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

extern ntt
extern invntt
extern barrett_reduce

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
