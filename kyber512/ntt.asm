BITS 64

section .note.GNU-stack

section .rodata

extern zetas                          ; const uint16_t zetas[]
extern omegas_inv_bitrev_montgomery   ; const uint16_t omegas_inv_bitrev_montgomery[]
extern psis_inv_montgomery            ; const uint16_t psis_inv_montgomery[]

section .text
global ntt
global invntt

%define KYBER_N 256
%define KYBER_Q 7681

extern montgomery_reduce
extern barrett_reduce

; /*************************************************
; * Name:        ntt
; * 
; * Description: Computes negacyclic number-theoretic transform (NTT) of
; *              a polynomial (vector of 256 coefficients) in place; 
; *              inputs assumed to be in normal order, output in bitreversed order
; *
; * Arguments:   - uint16_t *p: pointer to in/output polynomial
; **************************************************/
ntt:
	push	rbp
	mov	rbp, rsp
	push	rbx                 ; zachowaj rbx
	sub	rsp, 56
	mov	qword [rbp-56], rdi   ; uint16_t *p

	mov	dword [rbp-32], 1     ; int k = 1
	mov	dword [rbp-20], 7     ; int level = 7

.level_loop:
	cmp	dword [rbp-20], 0     ; level >= 0
	js	.level_loop_end

	mov	dword [rbp-24], 0     ; int start = 0
.start_loop:
	cmp	dword [rbp-24], KYBER_N   ; start < KYBER_N
	jge	.start_loop_end

	mov	eax, dword [rbp-32]   ; k
	lea	edx, [rax+1]
	mov	dword [rbp-32], edx   ; k++
	cdqe
	lea	rdx, [0+rax*2]          ; mnożymy razy 2 bo word ma 2 bajty
	lea	rax, [rel zetas]        ; zetas
	movzx	eax, word [rdx+rax]   ; zetas[k]
	mov	word [rbp-34], ax       ; zeta = zetas[k]

	mov	eax, dword [rbp-24]
	mov	dword [rbp-28], eax     ; int j = start
.inner_loop:
	mov	eax, dword [rbp-20]     ; level
	mov	edx, 1
	mov	ecx, eax
	sal	edx, cl                 ; 1 << level
	mov	eax, dword [rbp-24]     ; start
	add	eax, edx                ; start + (1 << level)
	cmp	dword [rbp-28], eax     ; j < start + (1 << level)
	jge	.inner_loop_end

	movzx	edx, word [rbp-34]    ; zeta

	mov	eax, dword [rbp-20]     ; level
	mov	esi, 1
	mov	ecx, eax
	sal	esi, cl                 ; 1 << level
	mov	ecx, esi

	mov	eax, dword [rbp-28]     ; j
	add	eax, ecx                ; j + (1 << level)
	cdqe

	lea	rcx, [0+rax*2]
	mov	rax, qword [rbp-56]     ; p
	add	rax, rcx                ; p + j + (1 << level)
	movzx	eax, word [rax]       ; p[j + (1 << level)]
	movzx	eax, ax

	imul	eax, edx              ; zeta * p[j + (1 << level)]
	mov	edi, eax
	call	montgomery_reduce

	mov	word [rbp-36], ax       ; t = montgomery_reduce(...)

	mov	eax, dword [rbp-28]     ; j
	cdqe

	lea	rdx, [0+2*rax]
	mov	rax, qword [rbp-56]     ; p
	add	rax, rdx
	movzx	eax, word [rax]       ; p[j]

	sub	ax, word [rbp-36]       ; p[j] - t

  lea bx, [0+4*KYBER_Q]
	add	ax, bx
	movzx	eax, ax

	mov	edx, dword [rbp-20]     ; level
	mov	esi, 1
	mov	ecx, edx
	sal	esi, cl                 ; 1 << level
	mov	ecx, esi
	mov	edx, dword [rbp-28]     ; j
	add	edx, ecx                ; j + 1 << level
	movsx	rdx, edx

	lea	rcx, [0+2*rdx]
	mov	rdx, qword [rbp-56]     ; p
	lea	rbx, [rcx+rdx]          ; p[...]
	mov	edi, eax
	call	barrett_reduce

	mov	word [rbx], ax          ; p[...] = barrett_reduce(p[j] + 4 * KYBER_Q - t)

	mov	eax, dword [rbp-20]
	and	eax, 1                  ; level & 1
	test	eax, eax              ; (level & 1) == 0 ?
	je	.if_not_odd_level

  ; level is odd
	mov	eax, dword [rbp-28]       ; j
	cdqe
	lea	rdx, [0+2*rax]
	mov	rax, qword [rbp-56]       ; p
	add	rax, rdx                  ; p + j
	movzx	ecx, word [rax]         ; p[j]

	movzx	edx, word [rbp-36]      ; t
	add	edx, ecx                  ; p[j] + t
	mov	word [rax], dx            ; p[j] = p[j] + t
	jmp	.if_end

.if_not_odd_level:
	mov	eax, dword [rbp-28]       ; j
	cdqe
	lea	rdx, [0+2*rax]
	mov	rax, qword [rbp-56]       ; p
	add	rax, rdx                  ; p + j
	movzx	edx, word [rax]         ; p[j]
  mov rbx, rax

	movzx	eax, word [rbp-36]      ; t
	add	eax, edx                  ; p[j] + t
	movzx	eax, ax

	mov	edi, eax
	call	barrett_reduce
	mov	word [rbx], ax            ; p[j] = barrett_reduce(p[j] + t)

.if_end:
	add	dword [rbp-28], 1         ; j++
  jmp .inner_loop

.inner_loop_end:

  mov	eax, dword [rbp-20]       ; level
	mov	edx, 1
	mov	ecx, eax
	sal	edx, cl                   ; 1 << level
	mov	eax, dword [rbp-28]       ; j
  add	eax, edx                  ; j + (1 << level)
	mov	dword [rbp-24], eax       ; start = j (1 << level)

  jmp .start_loop

.start_loop_end:

	sub	dword [rbp-20], 1   ; level--
  jmp .level_loop

.level_loop_end:
	mov	rbx, qword [rbp-8]  ; przywróć rbx
	leave
	ret

; /*************************************************
; * Name:        invntt
; * 
; * Description: Computes inverse of negacyclic number-theoretic transform (NTT) of
; *              a polynomial (vector of 256 coefficients) in place; 
; *              inputs assumed to be in bitreversed order, output in normal order
; *
; * Arguments:   - uint16_t *a: pointer to in/output polynomial
; **************************************************/
invntt:
	push	rbp
	mov	rbp, rsp
	push	rbx                     ; zachowaj rbx
	sub	rsp, 56
	mov	qword [rbp-56], rdi       ; uint16_t *a

	mov	dword [rbp-32], 0         ; int level = 0
.level_loop:
	cmp	dword [rbp-32], 8
	jge	.level_loop_end

	mov	dword [rbp-20], 0         ; int start = 0
.start_loop:
	mov	eax, dword [rbp-32]       ; level
	mov	edx, 1
	mov	ecx, eax
	sal	edx, cl                   ; 1 << level
	mov	eax, edx
	cmp	dword [rbp-20], eax       ; start < (1 << level)
	jge	.start_loop_end

	mov	dword [rbp-28], 0         ; jTwiddle = 0

	mov	eax, dword [rbp-20]
	mov	dword [rbp-24], eax       ; int j = start
.inner_loop:
	cmp	dword [rbp-24], 255       ; j < KYBER_N - 1
	jge	.inner_loop_end

	mov	eax, dword [rbp-28]       ; jTwiddle
	lea	edx, [rax+1]              ; jTwiddle + 1
	mov	dword [rbp-28], edx       ; jTwiddle++
	cdqe

	lea	rdx, [0+2*rax]
	lea	rax, [rel omegas_inv_bitrev_montgomery]
	movzx	eax, word [rdx+rax]     ; omegas_inv_bitrev_montgomery[jTwiddle++]
	mov	word [rbp-34], ax         ; w = omegas_inv_bitrev_montgomery[jTwiddle++]

	mov	eax, dword [rbp-24]       ; j
	cdqe

	lea	rdx, [0+2*rax]
	mov	rax, qword [rbp-56]       ; a
	add	rax, rdx                  ; a + j
	movzx	eax, word [rax]         ; a[j]
	mov	word [rbp-36], ax         ; temp = a[j]

	mov	eax, dword [rbp-32]       ; level
	and	eax, 1
	test	eax, eax                ; (level & 1) == 0
	je .if_not_odd_level

	mov	eax, dword [rbp-32]       ; level
	mov	edx, 1
	mov	ecx, eax
	sal	edx, cl                   ; 1 << level
	mov	eax, dword [rbp-24]       ; j
	add	eax, edx                  ; j + (1 << level)
	cdqe

	lea	rdx, [0+2*rax]
	mov	rax, qword [rbp-56]       ; a
	add	rax, rdx                  ; a + j + (1 << level)
	movzx	edx, word [rax]         ; a[j + (1 << level)]

	movzx	eax, word [rbp-36]      ; temp
	add	eax, edx                  ; temp + a[j + 1 << level]
	movzx	eax, ax

	mov	edx, dword [rbp-24]       ; j
	movsx	rdx, edx
	lea	rcx, [0+2*rdx]
	mov	rdx, qword [rbp-56]       ; a
	lea	rbx, [rcx+rdx]            ; a + j

	mov	edi, eax
	call	barrett_reduce
	mov	word [rbx], ax            ; a[j] = barrett_reduce(temp + a[j + 1 << level])
	jmp	.if_end

.if_not_odd_level:
	mov	eax, dword [rbp-32]       ; level
	mov	edx, 1
	mov	ecx, eax
	sal	edx, cl                   ; 1 << level

	mov	eax, dword [rbp-24]       ; j
	add	eax, edx                  ; j + (1 << level)
	cdqe

	lea	rdx, [0+2*rax]
	mov	rax, qword [rbp-56]       ; a
	add	rax, rdx                  ; a + j + (1 << level)
	movzx	ecx, word [rax]         ; a[j + (1 << level)]

	mov	eax, dword [rbp-24]       ; j
	cdqe

	lea	rdx, [0+2*rax]
	mov	rax, qword [rbp-56]       ; a
	add	rax, rdx                  ; a + j

	movzx	edx, word [rbp-36]      ; temp
	add	edx, ecx                  ; temp + a[j + (1 << level)]

	mov	word [rax], dx            ; a[j] = temp + a[j + (1 << level)]

.if_end:
	movzx	eax, word [rbp-34]      ; W

	movzx	esi, word [rbp-36]      ; temp

	mov	edx, dword [rbp-32]       ; level
	mov	edi, 1
	mov	ecx, edx
	sal	edi, cl                   ; 1 << level
	mov	ecx, edi

	mov	edx, dword [rbp-24]       ; j
	add	edx, ecx                  ; j + (1 << level)
	movsx	rdx, edx

	lea	rcx, [0+2*rdx]
	mov	rdx, qword [rbp-56]       ; a
	add	rdx, rcx                  ; a + j + (1 << level)
	movzx	edx, word [rdx]         ; a[j + (1 << level)]
	movzx	edx, dx

	sub	esi, edx                  ; temp - a[...]
	mov	ecx, esi

	lea	edx, [rcx+4*KYBER_Q]      ; temp + 4 * KYBER_Q - a[...]

	imul	eax, edx                ; W * (temp + 4 * KYBER_Q - a[...])

	mov	dword [rbp-40], eax       ; t = W * (temp + 4 * KYBER_Q - a[j + (1 << level)])

	mov	eax, dword [rbp-32]       ; level
	mov	edx, 1
	mov	ecx, eax
	sal	edx, cl                   ; 1 << level

	mov	eax, dword [rbp-24]       ; j
	add	eax, edx                  ; j + (1 << level)
	cdqe

	lea	rdx, [0+2*rax]
	mov	rax, qword [rbp-56]       ; a
	lea	rbx, [rdx+rax]            ; a + j + (1 << level)

	mov	eax, dword [rbp-40]       ; t
	mov	edi, eax
	call	montgomery_reduce
	mov	word [rbx], ax            ; a[j + (1 << level)] = montgomery_reduce(t)

	mov	eax, dword [rbp-32]       ; level
	mov	edx, 2
	mov	ecx, eax
	sal	edx, cl                   ; 2 << level
	mov	eax, edx
	add	dword [rbp-24], eax       ; j += 2 << level
  jmp .inner_loop

.inner_loop_end:

	add	dword [rbp-20], 1         ; start++
  jmp .start_loop

.start_loop_end:

	add	dword [rbp-32], 1         ; level++
  jmp .level_loop

.level_loop_end:

	mov	dword [rbp-24], 0         ; j = 0

.montgomery_reduce_loop:
	cmp	dword [rbp-24], KYBER_N       ; j < KYBER_N
	jge	.montgomery_reduce_loop_end

	mov	eax, dword [rbp-24]           ; j
	cdqe

	lea	rdx, [0+2*rax]
	mov	rax, qword [rbp-56]           ; a
	add	rax, rdx                      ; a + j
  mov rbx, rax
	movzx	eax, word [rax]             ; a[j]
	movzx	edx, ax

	mov	eax, dword [rbp-24]           ; j
	cdqe

	lea	rcx, [0+2*rax]
	lea	rax, [rel psis_inv_montgomery]
	movzx	eax, word [rcx+rax]           ; psis_inv_montgomery[j]
	movzx	eax, ax

	imul	eax, edx                      ; psis_inv_montgomery[j] * a[j]
	mov	ecx, eax

	mov	edi, ecx
	call	montgomery_reduce
	mov	word [rbx], ax                  ; a[j] = montgomery_reduce(psis_inv_montgomery[j] * a[j])

	add	dword [rbp-24], 1                 ; j++
  jmp .montgomery_reduce_loop

.montgomery_reduce_loop_end:
	mov	rbx, qword [rbp-8]      ; przywróć rbx
	leave
	ret

