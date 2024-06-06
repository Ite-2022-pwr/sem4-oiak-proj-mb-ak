BITS 64

section .note.GNU-stack

%define KYBER_K 2
%define KYBER_POLYBYTES 416
%define KYBER_N 256

section .text
global polyvec_tobytes
global polyvec_frombytes
global polyvec_ntt
global polyvec_invntt
global polyvec_add
global polyvec_pointwise_acc

extern poly_tobytes
extern poly_frombytes
extern poly_ntt
extern poly_invntt
extern poly_add
extern montgomery_reduce
extern barrett_reduce

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

; /*************************************************
; * Name:        polyvec_frombytes
; * 
; * Description: De-serialize vector of polynomials;
; *              inverse of polyvec_tobytes 
; *
; * Arguments:   - polyvec *r: pointer to output vector of polynomials 
; *              - const unsigned char *a: pointer to input byte array
; **************************************************/
polyvec_frombytes:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 32
	mov	qword [rbp-24], rdi             ; polyvec *r
	mov	qword [rbp-32], rsi             ; const unsigned char *a

	mov	dword [rbp-4], 0                ; int i = 0
.loop:
	cmp	dword [rbp-4], KYBER_K          ; i < KYBER_K
	jge	.loop_end

	mov	eax, dword [rbp-4]              ; i
	imul	eax, eax, KYBER_POLYBYTES     ; i * KYBER_POLYBYTES
	movsx	rdx, eax

	mov	rax, qword [rbp-32]             ; a
	add	rdx, rax                        ; a + i * KYBER_POLYBYTES

	mov	eax, dword [rbp-4]              ; i
	cdqe
	sal	rax, 9                          ; rozmiar poly (512)
	mov	rcx, rax

	mov	rax, qword [rbp-24]             ; r
	add	rax, rcx                        ; &r->vec[i]

	mov	rsi, rdx
	mov	rdi, rax
	call	poly_frombytes

	add	dword[rbp-4], 1                 ; i++
  jmp .loop

.loop_end:
	leave
	ret

; /*************************************************
; * Name:        polyvec_ntt
; * 
; * Description: Apply forward NTT to all elements of a vector of polynomials
; *
; * Arguments:   - polyvec *r: pointer to in/output vector of polynomials
; **************************************************/
polyvec_ntt:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 32
	mov	qword [rbp-24], rdi           ; polyvec *r

	mov	dword [rbp-4], 0              ; int i = 0
.loop:
	cmp	dword [rbp-4], KYBER_K
	jge	.loop_end

	mov	eax, dword [rbp-4]            ; i
	cdqe
	sal	rax, 9                        ; rozmiar poly
	mov	rdx, rax

	mov	rax, qword [rbp-24]           ; r
	add	rax, rdx                      ; &r->vec[i]

	mov	rdi, rax
	call	poly_ntt

	add	dword [rbp-4], 1              ; i++
  jmp .loop

.loop_end:
	leave
	ret

; /*************************************************
; * Name:        polyvec_invntt
; * 
; * Description: Apply inverse NTT to all elements of a vector of polynomials
; *
; * Arguments:   - polyvec *r: pointer to in/output vector of polynomials
; **************************************************/
polyvec_invntt:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 32
	mov	qword [rbp-24], rdi       ; polyvec *r

	mov	dword [rbp-4], 0          ; int i = 0
.loop:
	cmp	dword [rbp-4], KYBER_K    ; i < KYBER_K
	jge	.loop_end

	mov	eax, dword [rbp-4]        ; i
	cdqe
	sal	rax, 9                    ; rozmiar poly
	mov	rdx, rax

	mov	rax, qword [rbp-24]       ; r
	add	rax, rdx                  ; &r->vec[i]

	mov	rdi, rax
	call	poly_invntt

	add	dword [rbp-4], 1          ; i++
  jmp .loop

.loop_end:
	leave
	ret

; /*************************************************
; * Name:        polyvec_add
; * 
; * Description: Add vectors of polynomials
; *
; * Arguments: - polyvec *r:       pointer to output vector of polynomials
; *            - const polyvec *a: pointer to first input vector of polynomials
; *            - const polyvec *b: pointer to second input vector of polynomials
; **************************************************/ 
polyvec_add:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 48
	mov	qword [rbp-24], rdi           ; polyvec *r
	mov	qword [rbp-32], rsi           ; const polyvec *a
	mov	qword [rbp-40], rdx           ; const polyvec *b

	mov	dword [rbp-4], 0              ; int i = 0
.loop:
	cmp	dword [rbp-4], KYBER_K        ; i < KYBER_K
	jge	.loop_end

	mov	eax, dword [rbp-4]            ; i
	cdqe
	sal	rax, 9
	mov	rdi, rax

	mov	rax, qword [rbp-24]           ; r
	add	rdi, rax                      ; r->vec[i]

	mov	eax, dword [rbp-4]            ; i
	cdqe
	sal	rax, 9
	mov	rsi, rax

	mov	rax, qword [rbp-32]           ; a
	add	rsi, rax                      ; &a->vec[i]


	mov	eax, dword [rbp-4]            ; i
	cdqe
	sal	rax, 9                        ; rozmiar poly
	mov	rdx, rax

	mov	rax, qword [rbp-40]           ; b
	add	rdx, rax                      ; &b->vec[i]

	call	poly_add

	add	dword [rbp-4], 1              ; i++
  jmp .loop

.loop_end:
	leave
	ret

; /*************************************************
; * Name:        polyvec_pointwise_acc
; * 
; * Description: Pointwise multiply elements of a and b and accumulate into r
; *
; * Arguments: - poly *r:          pointer to output polynomial
; *            - const polyvec *a: pointer to first input vector of polynomials
; *            - const polyvec *b: pointer to second input vector of polynomials
; **************************************************/ 
polyvec_pointwise_acc:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 48
	mov	qword [rbp-24], rdi           ; poly *r
	mov	qword [rbp-32], rsi           ; const polyvec *a
	mov	qword [rbp-40], rdx           ; const polyvec *b

	mov	dword [rbp-8], 0              ; int j = 0
.outer_loop:
	cmp	dword [rbp-8], KYBER_N        ; j < KYBER_N
	jge	.outer_loop_end

	mov	rax, qword [rbp-40]           ; b
	mov	edx, dword [rbp-8]            ; j
	movsx	rdx, edx
	movzx	eax, word [rax+rdx*2]       ; b->vec[0].coeffs[j]
	movzx	eax, ax
	imul	eax, eax, 4613              ; 4613 * b->vec[0].coeffs[j]
	mov	edi, eax
	call	montgomery_reduce

	mov	word [rbp-10], ax             ; t = montgomery_reduce(4613 * b->vec[0].coeffs[j])

	mov	rax, qword [rbp-32]           ; a
	mov	edx, dword [rbp-8]            ; j
	movsx	rdx, edx
	movzx	eax, word [rax+rdx*2]       ; a->vec[0].coeffs[j]
	movzx	edx, ax

	movzx	eax, word [rbp-10]          ; t
	imul	eax, edx                    ; t * a->vec[0].coeffs[j]
	mov	edi, eax
	call	montgomery_reduce           ; montgomery_reduce(t * a->vec[0].coeffs[j]) 

	mov	rdx, qword [rbp-24]           ; r
	mov	ecx, dword [rbp-8]            ; j
	movsx	rcx, ecx
	mov	word [rdx+rcx*2], ax          ; r->coeffs[j] = montgomery_reduce(t * a->vec[0].coeffs[j])

	mov	dword [rbp-4], 1              ; int i = 1
.inner_loop:
	cmp	dword [rbp-4], KYBER_K        ; i < KYBER_K
	jge	.inner_loop_end

	mov	rax, qword [rbp-40]           ; b
	mov	edx, dword [rbp-8]            ; j
	movsx	rdx, edx
	mov	ecx, dword [rbp-4]            ; i
	movsx	rcx, ecx
	sal	rcx, 8                        ; liczba współczynników wielomianu
	add	rdx, rcx                      ; i * 256 + j
	movzx	eax, word [rax+rdx*2]       ; b->vec[i].coeffs[j]
	movzx	eax, ax
	imul	eax, eax, 4613              ; 4613 * b->vec[i].coeffs[j]
	mov	edi, eax
	call	montgomery_reduce
	mov	word [rbp-10], ax             ; t = montgomery_reduce(4613 * b->vec[i].coeffs[j]);

	mov	rax, qword [rbp-32]           ; a
	mov	edx, dword [rbp-8]            ; j
	movsx	rdx, edx
	mov	ecx, dword [rbp-4]            ; i
	movsx	rcx, ecx
	sal	rcx, 8                        ; liczba współczynników wielomianu
	add	rdx, rcx                      ; i * 256 + j
	movzx	eax, word [rax+rdx*2]       ; a->vec[i].coeffs[j]
	movzx	edx, ax

	movzx	eax, word [rbp-10]          ; t
	imul	eax, edx                    ; t * a->vec[i].coeffs[j]

	mov	edi, eax
	call	montgomery_reduce           ; montgomery_reduce(t * a->vec[i].coeffs[j])
	mov	ecx, eax

	mov	rax, qword [rbp-24]           ; r
	mov	edx, dword [rbp-8]            ; j
	movsx	rdx, edx
	movzx	eax, word [rax+rdx*2]       ; r->coeffs[j]
	add	ecx, eax                      ; r->coeffs[j] + montgomery_reduce(...)

	mov	rax, qword [rbp-24]           ; r
	mov	edx, dword [rbp-8]            ; j
	movsx	rdx, edx
	mov	word [rax+rdx*2], cx          ; r->coeffs[j] += montgomery_reduce(...)

	add	dword [rbp-4], 1              ; i++
  jmp .inner_loop

.inner_loop_end:
	mov	rax, qword [rbp-24]           ; r
	mov	edx, dword [rbp-8]            ; j
	movsx	rdx, edx

	movzx	eax, word [rax+rdx*2]       ; r->coeffs[j]
	movzx	eax, ax
	mov	edi, eax
	call	barrett_reduce

	mov	rdx, qword [rbp-24]           ; r
	mov	ecx, dword [rbp-8]            ; j
	movsx	rcx, ecx
	mov	word [rdx+rcx*2], ax          ; r->coeffs[j] = barrett_reduce(r->coeffs[j])

	add	dword [rbp-8], 1              ; j++
  jmp .outer_loop

.outer_loop_end:
	leave
	ret
