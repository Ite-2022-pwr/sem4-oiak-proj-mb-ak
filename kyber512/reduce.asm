BITS 64

section .note.GNU-stack

section .text

%define KYBER_Q 7681

%define qinv 7679             ; -inverse_mod(q,2^18)
%define rlog 18

global montgomery_reduce
global barrett_reduce
global freeze

; /*************************************************
; * Name:        montgomery_reduce
; * 
; * Description: Montgomery reduction; given a 32-bit integer a, computes
; *              16-bit integer congruent to a * R^-1 mod q, 
; *              where R=2^18 (see value of rlog)
; *
; * Arguments:   - uint32_t a: input unsigned integer to be reduced; has to be in {0,...,2281446912}
; *              
; * Returns:     unsigned integer in {0,...,2^13-1} congruent to a * R^-1 modulo q.
; **************************************************/
montgomery_reduce:
	push	rbp
	mov	rbp, rsp

	mov	edx, qinv
  mov eax, edi
	imul	eax, edx                          ; u = a * qinv
	mov	ecx, 1
	sal	ecx, rlog                           ; 1 << rlog
  dec ecx                                 ; (1 << rlog) - 1
  and eax, ecx                            ; u &= ((1 << rlog) - 1)

	imul	eax, eax, KYBER_Q                 ; u * KYBER_Q
  add eax, edi                            ; u += a
  shr eax, rlog                           ; u >> rlog

  leave
  ret

; /*************************************************
; * Name:        barrett_reduce
; * 
; * Description: Barrett reduction; given a 16-bit integer a, computes
; *              16-bit integer congruent to a mod q in {0,...,11768}
; *
; * Arguments:   - uint16_t a: input unsigned integer to be reduced
; *              
; * Returns:     unsigned integer in {0,...,11768} congruent to a modulo q.
; **************************************************/
barrett_reduce:
	push	rbp
	mov	rbp, rsp

	mov	eax, edi
	shr	eax, 13                             ; u = a >> 13

	imul	eax, eax, KYBER_Q                 ; u *= KYBER_Q

  sub edi, eax                            ; a -= u

  mov eax, edi
	
  leave
	ret

; /*************************************************
; * Name:        freeze
; * 
; * Description: Full reduction; given a 16-bit integer a, computes
; *              unsigned integer a mod q.
; *
; * Arguments:   - uint16_t x: input unsigned integer to be reduced
; *              
; * Returns:     unsigned integer in {0,...,q-1} congruent to a modulo q.
; **************************************************/
freeze:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 24
	mov	eax, edi
	mov	word [rbp-20], ax                   ; uint16_t x

	call	barrett_reduce
	mov	word [rbp-2], ax                    ; r = barrett_reduce(x)

	sub	ax, KYBER_Q                         ; r - KYBER_Q
	mov	word [rbp-4], ax                    ; m = r - KYBER_Q

	mov	word [rbp-6], ax                    ; c = m
	sar	word [rbp-6], 15                    ; c >>= 15

	movzx	eax, word [rbp-2]                 ; r
	xor	ax, word [rbp-4]                    ; r ^ m
	and	ax, word [rbp-6]                    ; (r ^ m) & c
	mov	edx, eax
	movzx	eax, word [rbp-4]                 ; m
	xor	eax, edx                            ; m ^ ((r ^ m) & c)

	leave
	ret
