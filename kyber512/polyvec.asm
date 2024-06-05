BITS 64

section .note.GNU-stack

%define KYBER_K 2
%define KYBER_POLYBYTES 416

section .text
global polyvec_tobytes

extern poly_tobytes

; /*************************************************
; * Name:        polyvec_tobytes
; * 
; * Description: Serialize vector of polynomials
; *
; * Arguments:   - unsigned char *r: pointer to output byte array 
; *              - const polyvec *a: pointer to input vector of polynomials
; **************************************************/
polyvec_tobytes:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 32
	mov	qword [rbp-24], rdi           ; unsigned char *r
	mov	qword [rbp-32], rsi           ; const polyvec *a

	mov	dword [rbp-4], 0              ; i = 0
.loop:
	cmp	dword [rbp-4], KYBER_K
	jge	.loop_end

	mov	eax, dword [rbp-4]            ; i
	cdqe
	sal	rax, 9                        ; i * 512 (rozmiar poly)
	mov	rdx, rax

	mov	rax, qword [rbp-32]           ; a
	add	rdx, rax                      ; a + i * 512

	mov	eax, dword [rbp-4]            ; i
	imul	eax, eax, KYBER_POLYBYTES   ; i * KYBER_POLYBYTES
	movsx	rcx, eax

	mov	rax, qword [rbp-24]           ; r
	add	rax, rcx                      ; r + i * KYBER_POLYBYTES

	mov	rsi, rdx
	mov	rdi, rax
	call	poly_tobytes                ; poly_tobytes(r + i * KYBER_POLYBYTES, &a->vec[i])

	add	dword [rbp-4], 1                ; i++
  jmp .loop

.loop_end:
	leave
	ret
