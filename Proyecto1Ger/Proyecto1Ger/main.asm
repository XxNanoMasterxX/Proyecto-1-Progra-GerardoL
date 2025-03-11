;
; Proyecto1Ger.asm
;
; Created: 3/4/2025 2:32:10 PM
; Author : laloj
;

.include "M328Pdef.inc"
.cseg
.org 0x0000
rjmp SETUP_GEN
.org OVF2addr
jmp DISP_LGC
.org OVF0addr //Timer0, Overfloq
jmp SW_CNT

SETUP_GEN:
	cli
	ldi r16, HIGH(RAMEND)
	out SPH, R16
	ldi R16, LOW(RAMEND)
	out spl, r16

	tab7seg: .DB 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6D, 0x7D, 0x07, 0x7f, 0x67, 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71


; Setup del clock0
	ldi r16, (1 << CLKPCE)
	sts CLKPR, r16 //Hora de prescaler hermano
	ldi r16, 0b00000100
	sts CLKPR, r16 // Asi es viejo, prescaler F_cpu = 1MHz

	call in_tim0
	call in_tim2

	ldi r16, 0x01
	sts TIMSK0, r16
	sts TIMSK2, r16

	LDI ZL, LOW(tab7seg<<1)
	LDI ZH, HIGH(tab7seg<<1)
	LPM R17, Z // Se carga el valor inicial de z hacia el port, este siendo 0.
	MOV R2, R17
	MOV R3, R17
	MOV R4, R17
	MOV R5, R17
	MOV R10, R17
	MOV R12, R17


	sbi DDRC, 0
	sbi DDRC, 1
	sbi DDRC, 2
	sbi DDRC, 3
	ldi r16, 0xff
	out ddrd, r16
	sbi portc, 0
	cbi portc, 1
	cbi portc, 2
	cbi portc, 3

	ldi r16, 0b10000000
	mov r6, r16
	ldi r16, 0x06
	mov r9, r16
	mov r11, r16
	ldi r16, 0x01
	ldi r18, 0x00
	ldi r19, 0x00
	ldi r20, 0x00
	ldi r21, 0x00
	ldi r22, 0x00
	ldi r23, 0x00
	ldi r24, 0x00
	ldi r25, 0x00
	ldi r26, 0x01
	ldi r27, 0x00
	ldi r28, 0x01
	ldi r29. 0x00
	mov r7, r25
	mov r8, r25
	sei

loop:
	jmp loop

SW_CNT:
	ldi r18, 178
	out TCNT0, r18
	inc r19
	cpi r19, 200 ; Segundo
	brne Disp_Select
	clr r19
	inc r20
	cpi r20, 60 ; Minutos
	brne Disp_Select
	sbr r25, 1
	clr r20
	inc r21
	cpi r21, 10 ; Decimas de minutos
	brne Disp_Select
	sbr r25, 2
	clr r21
	inc r22
	cpi r22, 6 ; Horas
	brne Disp_Select
	cpi r24, 2
	breq hora2
	sbr r25, 4
	clr r22
	inc r23
	cpi r23, 10 ; Decimas de horas
	brne Disp_Select
	sbr r25, 8
	clr r23
	inc r24
	jmp Disp_Select
	hora2:
	sbr r25, 4
	clr r22
	inc r23
	cpi r23, 4 ; Decimas de horas
	brne Disp_Select
	sbr r25, 8
	inc r26
	clr r23
	clr r24

Disp_Select:
	clc
	rol r16 ;Cambio de selector
	cpi r16, 0x10
	brne fini
	ldi r16, 0x01
	fini:
	sbrc r16, 0
	out portd, r2
	sbrc r16, 1
	out portd, r3
	sbrc r16, 2
	out portd, r4
	sbrc r16, 3
	out portd, r5
	out portc, r16
	reti


DISP_LGC:
	ldi r18, 100
	sts TCNT2, r18
	sbrs r25, 0
	jmp dec_min
	mov r7, r21
	call table_loop
	mov r2, r17
	cbr r25, 1
	dec_min:
	sbrs r25, 1
	jmp hora
	mov r7, r22
	call table_loop
	mov r3, r17
	cbr r25, 2
	hora:
	sbrs r25, 2
	jmp dec_hora
	mov r7, r23
	call table_loop
	mov r4, r17
	cbr r25, 4
	dec_hora:
	sbrs r25, 3
	jmp disp_fini
	mov r7, r24
	call table_loop
	mov r5, r17
	cbr r25, 8
	disp_fini:
	reti
	

in_tim0:
	LDI R16, (1<<CS01) | (1<<CS00)
	OUT TCCR0B, R16 // Setear prescaler del TIMER 0 a 64
	LDI R16, 178
	OUT TCNT0, R16 // Cargar valor inicial en TCNT0
	RET

in_tim2:
	ldi r16, 0x04
	sts TCCR2B, r16
	ldi r16, 100
	sts TCNT2, r16
	ret

table_loop:
	LDI ZL, LOW(tab7seg<<1)
	LDI ZH, HIGH(tab7seg<<1)
table_loop1:
	cp r7, r8
	breq tab_fini
	inc r8
	adiw Z, 1
	jmp table_loop1
	tab_fini:
	lpm r17, z
	clr r8
	ret

	