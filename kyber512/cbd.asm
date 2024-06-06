BITS 64

section .note.GNU-stack

section .text

%define KYBER_N 256
%define KYBER_Q 7681

global cbd

; /*************************************************
; * Name:        load_littleendian
; * 
; * Description: load bytes into a 64-bit integer 
; *              in little-endian order
; *
; * Arguments:   - const unsigned char *x: pointer to input byte array
; *              - bytes:                  number of bytes to load, has to be <= 8
; *
; * Returns 64-bit unsigned integer loaded from x
; **************************************************/
load_littleendian:
	push	rbp
	mov	rbp, rsp
	mov	qword [rbp-24], rdi       ; const unsigned char *x
	mov	dword [rbp-28], esi       ; int bytes

	mov	rax, qword [rbp-24]       ; x
	movzx	eax, byte [rax]         ; x[0]
	movzx	eax, al
	mov	qword [rbp-16], rax       ; uint64_t r = x[0]

	mov	dword [rbp-4], 1          ; int i = 0
.loop:
	mov	eax, dword [rbp-4]        ; i
	cmp	eax, dword [rbp-28]       ; i < bytes
	jge	.loop_end

	mov	eax, dword [rbp-4]        ; i
	movsx	rdx, eax

	mov	rax, qword [rbp-24]       ; x
	add	rax, rdx                  ; x + i
	movzx	eax, byte [rax]         ; x[i]
	movzx	edx, al

	mov	eax, dword [rbp-4]        ; i
	sal	eax, 3                    ; i * 8
	mov	ecx, eax
	sal	rdx, cl                   ; x[0] << (i * 8)
	mov	rax, rdx

	or	qword [rbp-16], rax       ; r |= x[0] << (i * 8)

	inc dword [rbp-4]             ; i++
  jmp .loop

.loop_end:
	mov	rax, qword [rbp-16]       ; return r
  leave
	ret

; /*************************************************
; * Name:        cbd
; * 
; * Description: Given an array of uniformly random bytes, compute 
; *              polynomial with coefficients distributed according to
; *              a centered binomial distribution with parameter KYBER_ETA
; *
; * Arguments:   - poly *r:                  pointer to output polynomial  
; *              - const unsigned char *buf: pointer to input byte array
; **************************************************/
cbd:
  ; KYBER_ETA = 5
	push	rbp
	mov	rbp, rsp
	sub	rsp, 112
	mov	qword [rbp-104], rdi        ; poly *r
	mov	qword [rbp-112], rsi        ; const unsigned char *buf

	mov	dword [rbp-12], 0           ; int i = 0
.outer_loop:
  mov eax, KYBER_N
  sar eax, 2
	cmp	dword [rbp-12], eax         ; i < KYBER_N / 4
	jge	.outer_loop_end

	mov	edx, dword [rbp-12]         ; i
  lea eax, [0+edx*5]              ; i * 5
	movsx	rdx, eax

	mov	rax, qword [rbp-112]        ; buf
	add	rax, rdx                    ; buf + i * 5
	mov	esi, 5
	mov	rdi, rax
	call	load_littleendian
	mov	qword [rbp-24], rax         ; uint64_t t = load_littleendian(buf + i * 5, 5)

	mov	qword [rbp-8], 0            ; uint64_t d = 0

	mov	dword [rbp-16], 0           ; int j = 0
.inner_loop:
	cmp	dword [rbp-16], 5           ; j < 5
	jge	.inner_loop_end

	mov	eax, dword [rbp-16]         ; j
	mov	rdx, qword [rbp-24]         ; t
	mov	ecx, eax
	shr	rdx, cl                     ; t >> j
	mov rax, 0x0842108421
	and	rax, rdx                    ; (t >> j) & 0x0842108421
	add	qword [rbp-8], rax          ; d += (t >> j) & 0x0842108421

	inc	dword [rbp-16]              ; j++
  jmp .inner_loop

.inner_loop_end:

  ; a[0] =  d & 0x1f
	mov	rax, qword [rbp-8]          ; d
	and	eax, 0x1f
	mov	qword [rbp-64], rax         ; a[0]

  ; b[0] = (d >>  5) & 0x1f
	mov	rax, qword [rbp-8]
	shr	rax, 5
	and	eax, 0x1f
	mov	qword [rbp-96], rax         ; b[0]

  ; a[1] = (d >> 10) & 0x1f
	mov	rax, qword [rbp-8]
	shr	rax, 10
	and	eax, 0x1f
	mov	qword [rbp-56], rax         ; a[1]

  ; b[1] = (d >> 15) & 0x1f
	mov	rax, qword [rbp-8]
	shr	rax, 15
	and	eax, 0x1f
	mov	qword [rbp-88], rax         ; b[1]

  ; a[2] = (d >> 20) & 0x1f
	mov	rax, qword [rbp-8]
	shr	rax, 20
	and	eax, 0x1f
	mov	qword [rbp-48], rax         ; a[2]

  ; b[2] = (d >> 25) & 0x1f
	mov	rax, qword [rbp-8]
	shr	rax, 25
	and	eax, 0x1f
	mov	qword [rbp-80], rax         ; b[2]

  ; a[3] = (d >> 30) & 0x1f
	mov	rax, qword [rbp-8]
	shr	rax, 30
	and	eax, 0x1f
	mov	qword [rbp-40], rax         ; a[3]

  ; b[3] = (d >> 35)
	mov	rax, qword [rbp-8]
	shr	rax, 35
	mov	qword [rbp-72], rax         ; b[3]

  ; r->coeffs[4*i+0] = a[0] + KYBER_Q - b[0]
	mov	rax, qword [rbp-64]         ; a[0]
	mov	edx, eax
	mov	rax, qword [rbp-96]         ; b[0]
	mov	ecx, edx
	sub	ecx, eax                    ; a[0] - b[0]
	add	cx, KYBER_Q                 ; a[0] - b[0] + KYBER_Q
	mov	eax, dword [rbp-12]         ; i
	lea	edx, [0+rax*4]              ; i * 4
	movsx	rdx, edx
	mov	rax, qword [rbp-104]        ; r
	mov	word [rax+rdx*2], cx
  
  ; r->coeffs[4*i+1] = a[1] + KYBER_Q - b[1]
	mov	rax, qword [rbp-56]         ; a[1]
	mov	edx, eax
	mov	rax, qword [rbp-88]         ; b[1]
	mov	ecx, edx
	sub	ecx, eax                    ; a[1] - b[1]
	add	cx, KYBER_Q                 ; a[1] - b[1] + KYBER_Q
	mov	eax, dword [rbp-12]         ; i
	lea	edx, [1+rax*4]              ; i * 4 + 1
	movsx	rdx, edx
	mov	rax, qword [rbp-104]        ; r
	mov	word [rax+rdx*2], cx

  ; r->coeffs[4*i+2] = a[2] + KYBER_Q - b[2]
	mov	rax, qword [rbp-48]         ; a[2]
	mov	edx, eax
	mov	rax, qword [rbp-80]         ; b[2]
	mov	ecx, edx
	sub	ecx, eax                    ; a[2] - b[2]
	add	cx, KYBER_Q                 ; a[2] - b[2] + KYBER_Q
	mov	eax, dword [rbp-12]         ; i
	lea	edx, [2+rax*4]              ; i * 4 + 2
	movsx	rdx, edx
	mov	rax, qword [rbp-104]        ; r
	mov	word [rax+rdx*2], cx
  
  ; r->coeffs[4*i+3] = a[3] + KYBER_Q - b[3]
	mov	rax, qword [rbp-40]         ; a[3]
	mov	edx, eax
	mov	rax, qword [rbp-72]         ; b[3]
	mov	ecx, edx
	sub	ecx, eax                    ; a[3] - b[3]
	add	cx, KYBER_Q                 ; a[3] - b[3] + KYBER_Q
	mov	eax, dword [rbp-12]         ; i
	lea	edx, [3+rax*4]              ; i * 4 + 3
	movsx	rdx, edx
	mov	rax, qword [rbp-104]        ; r
	mov	word [rax+rdx*2], cx

	inc dword [rbp-12]              ; i++
  jmp .outer_loop

.outer_loop_end:
	leave
	ret
