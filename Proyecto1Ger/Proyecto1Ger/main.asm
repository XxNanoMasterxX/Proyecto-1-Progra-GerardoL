;
; Proyecto1Ger.asm
;
; Created: 3/4/2025 2:32:10 PM
; Author : laloj
;

.include "M328Pdef.inc"

.dseg
.org 0x0100
MODO: .byte 1
estado_anterior: .byte 1

.cseg
.org 0x0000
rjmp SETUP_GEN
.org PCI0addr
jmp PIN_CHANGE
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
	;sts CLKPR, r16 // Asi es viejo, prescaler F_cpu = 1MHz

	call in_tim0
	call in_tim2

	ldi r16, 0x01
	sts TIMSK0, r16
	sts TIMSK2, r16

	ldi r16, 0x01
	sts PCICR, R16
	ldi r16, 0b00010001
	sts PCMSK0, r16

	LDI ZL, LOW(tab7seg<<1)
	LDI ZH, HIGH(tab7seg<<1)
	LPM R17, Z // Se carga el valor inicial de z hacia el port, este siendo 0.
	MOV R2, R17
	MOV R3, R17
	MOV R4, R17
	MOV R5, R17
	MOV R10, R17
	MOV R12, R17

	ldi r16, 0x00
	out ddrb, r16
	sbi DDRC, 0
	sbi DDRC, 1
	sbi DDRC, 2
	sbi DDRC, 3
	ldi r16, 0xff
	out portb, r16
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
	ldi r16, 0xff
	sts estado_anterior, r16
	ldi r16, 0x01
	ldi r18, 0x00
	ldi r19, 0x00
	ldi r20, 0x00
	ldi r21, 0x00
	ldi r22, 0x00
	ldi r23, 0x00
	ldi r24, 0x00
	ldi r25, 0x00
	ldi r26, 0x01 ; Dia
	ldi r27, 0x00 ; Dec_Dia
	ldi r28, 0x01 ; Mes
	ldi r29, 0x00 ; Decima de Mes
	mov r7, r25
	mov r8, r25
	mov r14, r16
	sei

loop:
	jmp loop

SW_CNT:
	ldi r18, 178
	out TCNT0, r18
	inc r19
	cpi r19, 200 ; Segundo
	brne escape

	

	clr r19
	jmp temporal

	inc r20
	cpi r20, 60 ; Minutos
	brne escape

	sbr r25, 1
	clr r20
	inc r21
	cpi r21, 10 ; Decimas de minutos
	brne escape

	sbr r25, 2
	clr r21
	inc r22
	cpi r22, 6 ; Horas
	brne escape

	cpi r24, 2
	breq hora2
	sbr r25, 4
	clr r22
	inc r23
	cpi r23, 10 ; Decimas de horas
	brne escape

	sbr r25, 8
	clr r23
	inc r24
	jmp Disp_Select
	hora2:
	sbr r25, 4
	clr r22
	inc r23
	cpi r23, 4 ; Decimas de horas
	brne escape
	// Dia y Mes increase
	sbr r25, 8
	sbr r25, 16
	clr r23
	clr r24
				temporal:
				sbr r25, 16
	sbrc r28, 3 ; Check de mes
	rjmp Mes_Alto
	sbrc r29, 0
	rjmp Mes_Alto
	jmp Mes_bajo

			escape:
			jmp Disp_Select

	Mes_bajo:
	sbrc r28, 0
	rjmp bajo_impar
	; meses bajos, pares
		cpi r28, 0x02
		breq febrero
		; Meses pares que no son febrero
		cpi r27, 3
		breq Month_Inc_Pl
		inc r26
		cpi r26, 10
		brne escape
		clr r26
		inc r27
		sbr r25, 32
		jmp Disp_Select

			

		Month_Inc_Pl:
		inc r26
		cpi r26, 1
		brne escape
		ldi r26, 0x01
		clr r27
		inc r28
		sbr r25, 32
		sbr r25, 64
		jmp Disp_Select

		febrero:
		inc r26
		cpi r27, 2
		breq feb_fini
		cpi r26, 10
		brne escape
		clr r26
		inc r27
		sbr r25, 32
		cpi r27, 2
		brne escape
		feb_fini:
		cpi r26, 9
		brne escape
		ldi r26, 0x01
		clr r27
		inc r28
		sbr r25, 32
		sbr r25, 64
		jmp Disp_Select

	bajo_impar:
		cpi r27, 3
		breq Month_Inc_Il
		inc r26
		cpi r26, 10
		brne escape
		clr r26
		inc r27
		sbr r25, 32
		cpi r27, 10
		brne escape


		Month_Inc_Il:
		inc r26
		cpi r26, 2
		brne Disp_Select
		ldi r26, 0x01
		clr r27
		inc r28
		sbr r25, 32
		sbr r25, 64
		jmp Disp_Select


	

	Mes_Alto:
	sbrc r28, 0
	rjmp alto_impar
	cpi r27, 3
		breq Month_Inc_Ph
		inc r26
		cpi r26, 10
		brne Disp_Select
		clr r26
		inc r27
		sbr r25, 32
		cpi r27, 10
		brne Disp_Select


		Month_Inc_Ph:
		inc r26
		cpi r26, 2
		brne Disp_Select
		ldi r26, 0x01
		clr r27
		inc r28
		sbr r25, 32
		sbr r25, 64
		cpi r29, 0x01
		brne Disp_Select
		cpi r28, 0x03
		brne Disp_Select
		clr r29
		ldi r28, 0x01
		sbr r25, 128
		jmp Disp_Select

	alto_impar:
	cpi r27, 3
		breq Month_Inc_Ih
		inc r26
		cpi r26, 10
		brne Disp_Select
		clr r26
		inc r27
		sbr r25, 32
		cpi r27, 10
		brne Disp_Select


		Month_Inc_Ih:
		inc r26
		cpi r26, 1
		brne Disp_Select
		ldi r26, 0x01
		clr r27
		inc r28
		sbr r25, 32
		sbr r25, 64
		cpi r28, 10
		brne Disp_Select
		clr r28
		inc r29
		sbr r25, 128
		jmp Disp_Select

	
	

Disp_Select:
	ldi r17, 0x01
	cp r14, r17
	breq DM_1
	ldi r17, 0x02
	cp r14, r17
	breq DM_2
	ldi r17, 0x04
	cp r14, r17
	breq DM_3
	ldi r17, 0x08
	cp r14, r17
	breq DM_4
	DM_1:
	clc
	rol r16 ;Cambio de selector
	cpi r16, 0x10
	brne fini1
	ldi r16, 0x01
	fini1:
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

	DM_2:
	clc
	rol r16 ;Cambio de selector
	cpi r16, 0x10
	brne fini2
	ldi r16, 0x01
	fini2:
	sbrc r16, 0
	out portd, r9
	sbrc r16, 1
	out portd, r10
	sbrc r16, 2
	out portd, r11
	sbrc r16, 3
	out portd, r12
	out portc, r16
	reti

	DM_3:
	reti

	DM_4:
	reti


DISP_LGC:


	M_1:
		push r17
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
		jmp dia
		mov r7, r24
		call table_loop
		mov r5, r17
		cbr r25, 8

		dia:
		sbrs r25, 4
		jmp dec_dia
		mov r7, r26
		call table_loop
		mov r9, r17
		cbr r25, 16

		dec_dia:
		sbrs r25, 5
		jmp mes
		mov r7, r27
		call table_loop
		mov r10, r17
		cbr r25, 32

		mes:
		sbrs r25, 6
		jmp dec_mes
		mov r7, r28
		call table_loop
		mov r11, r17
		cbr r25, 64

		dec_mes:
		sbrs r25, 7
		jmp disp_fini
		mov r7, r29
		call table_loop
		mov r12, r17
		cbr r25, 64

		jmp disp_fini

	disp_fini:
	pop r17
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
PIN_CHANGE:
	push r16

	in r16, pinb
	sbrs r16, 0
	rjmp B_1
	sbrs r16, 1
	rjmp B_2
	sbrs r16, 2
	rjmp B_3
	sbrs r16, 3
	rjmp B_4
	sbrs r16, 4
	rjmp M_CHANGE

	salir:
	pop r16
	reti


	B_1:
	rjmp salir

	B_2:
	rjmp salir

	B_3:
	rjmp salir

	B_4:
	rjmp salir

    M_CHANGE:
	lsl r14
	sbrc r14, 4
	jmp modreset
	jmp salir
	modreset:
	ldi r17, 0x01
	mov r14, r17
	rjmp salir
	

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

	