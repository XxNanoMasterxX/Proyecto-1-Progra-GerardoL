;
; Proyecto1Ger.asm
;
; Created: 3/4/2025 2:32:10 PM
; Author : laloj
;

.include "M328Pdef.inc"

.dseg
.org 0x0100
DigSelect: .byte 1
MedioS: .byte 1
AM: .byte 1 ; Valores a comparar para la alarma
ADM: .byte 1
AH: .byte 1
ADH: .byte 1
D_AM: .byte 1 ;Display de la alarma
D_ADM: .byte 1
D_AH: .byte 1
D_ADH: .byte 1
PM: .byte 1 ; Valores pasados del reloj
PDM: .byte 1
PH: .byte 1
PDH: .byte 1
FA: .byte 1 ; Banderas para la alarma




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


; Setup del clock
	ldi r16, (1 << CLKPCE)
	sts CLKPR, r16 //Hora de prescaler hermano
	ldi r16, 0b00000100
	sts CLKPR, r16 // Asi es viejo, prescaler F_cpu = 1MHz

	; Setup del timer0 y 2
	call in_tim0
	call in_tim2

	ldi r16, 0x01
	sts TIMSK0, r16
	sts TIMSK2, r16

	; Pin change setup
	ldi r16, 0x01
	sts PCICR, R16
	ldi r16, 0b00011111
	sts PCMSK0, r16

	; Valores iniciales para display
	LDI ZL, LOW(tab7seg<<1)
	LDI ZH, HIGH(tab7seg<<1)
	LPM R17, Z // Se carga el valor inicial de z hacia el port, este siendo 0.
	MOV R2, R17
	MOV R3, R17
	MOV R4, R17
	MOV R5, R17
	MOV R10, R17
	MOV R12, R17

	; Pines setup
	ldi r16, 0x00
	out ddrb, r16
	sbi DDRC, 0
	sbi DDRC, 1
	sbi DDRC, 2
	sbi DDRC, 3
	sbi DDRB, 5 
	ldi r16, 0xff
	sbi portb, 0
	sbi portb, 1
	sbi portb, 2
	sbi portb, 3
	sbi portb, 4
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
	sts DigSelect, r16
	ldi r18, 0x00
	sts MedioS, r18
	sts AM, r18
	sts ADM, r18
	sts AH, r18
	sts ADH, r18
	sts FA, r18
	ldi r19, 0x00
	ldi r20, 0x00
	ldi r21, 0x00 ; Minuto
	ldi r22, 0x00 ; Dec_Minuto
	ldi r23, 0x00 ; Hora
	ldi r24, 0x00 ; Dec_Hora
	ldi r25, 0x00
	ldi r26, 0x01 ; Dia
	ldi r27, 0x00 ; Dec_Dia
	ldi r28, 0x01 ; Mes
	ldi r29, 0x00 ; Decima de Mes
	mov r7, r25
	mov r8, r25
	mov r14, r16
	mov r15, r25
	sei

loop:
	jmp loop

SW_CNT:
	ldi r18, 178
	out TCNT0, r18
	inc r19
	cpi r19, 100
	brne segundos
	push r15
	clr r15
	inc r15
	sts MedioS, r15
	clr r15
	pop r15
	segundos:
	cpi r19, 200 ; Segundo
	brne escape
	push r15
	clr r15
	sts MedioS, r15
	pop r15
	clr r19
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
	lds r18, FA
	sbrc r18, 1
	jmp alarma_c ; Si la alarma ha sido activada, salta a comparar
	DMs:
	sbrc r14, 0
	jmp DM_1
	sbrc r14, 1
	jmp DM_2
	sbrc r14, 2
	jmp DM_3
	sbrc r14, 3
	jmp DM_4
	sbrc r14, 4
	jmp DM_5

	alarma_c:
	push r16
	push r17
	push r18
	push r19
	lds r16, AM
	lds r17, ADM
	lds r18, AH
	lds r19, ADH

	cp r21, r16
	brne Alarma_No
	cp r22, r17
	brne Alarma_no
	cp r23, r18
	brne Alarma_no
	cp r24, r19
	brne Alarma_no
	cpi r20, 0x00 ; Una vez comprueba que la hora es la misma, solo se activa cuando no han pasado segundos
	brne Alarma_no
	sbi portB, 5 ; Activa alarma
	pop r19
	pop r18
	pop r17
	pop r16
	jmp DMs

	Alarma_No:
	pop r19
	pop r18
	pop r17
	pop r16
	jmp DMs


	

	DM_1: ; MODO Mostrar dia
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

	DM_2: ; MODO Mostrar Fecha
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


	DM_3: ; MODO Cambio de hora
	push r18
	lds r18, MedioS
	sbrs r18, 0
	jmp cancel1
	clc
	rol r16 ;Cambio de selector
	cpi r16, 0x10
	brne fini3
	ldi r16, 0x01
	fini3:
	sbrc r16, 0
	out portd, r2
	sbrc r16, 1
	out portd, r3
	sbrc r16, 2
	out portd, r4
	sbrc r16, 3
	out portd, r5
	out portc, r16
	pop r18
	reti
	cancel1:
	ldi r18, 0x00
	out portd, r18
	pop r18
	reti


	DM_4: ; MODO Cambiar fecha
	push r18
	lds r18, MedioS
	sbrs r18, 0
	jmp cancel2
	clc
	rol r16 ;Cambio de selector
	cpi r16, 0x10
	brne fini4
	ldi r16, 0x01
	fini4:
	sbrc r16, 0
	out portd, r9
	sbrc r16, 1
	out portd, r10
	sbrc r16, 2
	out portd, r11
	sbrc r16, 3
	out portd, r12
	out portc, r16
	pop r18
	reti
	cancel2:
	ldi r18, 0x00
	out portd, r18
	pop r18
	reti

	DM_back:
	pop r18
	jmp DM_3

	DM_5: ; MODO Alarma
	push r18
	lds r18, FA
	sbrs r18, 1
	jmp DM_back
	pop r18
	push r2
	push r3
	push r4
	push r5
	push r18
	lds r2, D_AM
	lds r3, D_ADM
	lds r4, D_AH
	lds r5, D_ADH
	lds r18, MedioS
	sbrs r18, 0
	jmp cancel3
	clc
	rol r16 ;Cambio de selector
	cpi r16, 0x10
	brne fini5
	ldi r16, 0x01
	fini5:
	sbrc r16, 0
	out portd, r2
	sbrc r16, 1
	out portd, r3
	sbrc r16, 2
	out portd, r4
	sbrc r16, 3
	out portd, r5
	out portc, r16
	pop r18
	pop r5
	pop r4
	pop r3
	pop r2
	reti
	cancel3:
	ldi r18, 0x00
	out portd, r18
	pop r18
	pop r5
	pop r4
	pop r3
	pop r2
	reti



DISP_LGC:

	M_1: ; Actualiza los valores del display de minutos, horas, dia o mes. Solo actualiza si hay cambio.
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
	push r17

	in r16, pinb
	sbrs r16, 0
	jmp B_Alarm
	sbrs r16, 1
	jmp B_Up
	sbrs r16, 2
	jmp B_Down
	sbrs r16, 3
	jmp B_DigChange
	sbrs r16, 4
	jmp M_CHANGE

	salir:
	pop r17
	pop r16
	reti


	B_Alarm:
		sbrc r14, 0
		jmp A_Off
		sbrc r14, 1
		jmp salir
		sbrc r14, 2
		jmp salir
		sbrc r14, 3
		jmp salir
		sbrc r14, 4
		jmp A_Set

		A_Off: ; En modo 1, apaga la alarma si esta activa
		cbi portb, 5
		jmp salir

		A_Set: ; Si esta en modo alarma, activa o reinica la alarma. Solo la activa si hubo cambios a la hora
		push r18
		lds r18, FA
		sbrc r18, 1
		jmp A_Set_reset
		sbrs r18, 0
		jmp A_Set_cancel
		sts AM, r21
		sts ADM, r22
		sts AH, r23
		sts ADH, r24

		push r2
		push r3
		push r4
		push r5
	
		mov r7, r21
		call table_loop
		mov r2, r17
		mov r7, r22
		call table_loop
		mov r3, r17
		mov r7, r23
		call table_loop
		mov r4, r17
		mov r7, r24
		call table_loop
		mov r5, r17

		sts D_AM, r2
		sts D_ADM, r3
		sts D_AH, r4
		sts D_ADH, r5

		pop r5
		pop r4
		pop r3
		pop r2

		lds r21, PM
		lds r22, PDM
		lds r23, PH
		lds r24, PDH
		sbr r25, 15
		sbr r18, 2
		cbr r18, 1
		sts FA, r18

		A_Set_cancel:
		pop r18
		jmp salir
		
		A_Set_reset:
		cbr r18, 3
		sts FA, r18
		pop r18
		jmp salir


	B_Up: ; Analiza en que modo esta y sube el digito correspondiente.
		sbrc r14, 0
		jmp salir
		sbrc r14, 1
		jmp salir
		sbrc r14, 2
		jmp HM_Up
		sbrc r14, 3
		jmp F_Up
		sbrc r14, 4
		jmp A_Up

		HM_Up: ; Sube horas y minutos
		push r18
		lds r18, DigSelect
		sbrc r18, 0
		jmp M_Up
		jmp H_Up

			M_Up:
			pop r18
			sbr r25, 1
			inc r21
			cpi r21, 10
			brne escapeD
			sbr r25, 2
			clr r21
			inc r22
			cpi r22, 6
			brne escapeD
			clr r22
			jmp salir

			H_Up:
			pop r18
			sbr r25, 4
			inc r23
			cpi r24, 2
			breq H_Up_High
			cpi r23, 10
			brne escapeD
			sbr r25, 8
			clr r23
			inc r24
			cpi r24, 6
			brne escapeD
			clr r24
			jmp salir
			H_Up_High:
			cpi r23, 4
			brne escapeD
			sbr r25, 8
			clr r23
			clr r24
			jmp salir

		F_Up: ; Sube fecha
		push r18
		lds r18, DigSelect
		sbrc r18, 0
		jmp Mo_Up
		jmp D_Up

				escapeD:
				jmp salir

			Mo_Up:
			pop r18
			clr r27
			ldi r26, 0x01
			sbr r25, 16
			sbr r25, 32
			sbr r25, 64
			inc r28
			cpi r29, 1
			breq M_Up_High
			cpi r28, 10
			brne escapeD
			sbr r25, 128
			clr r28
			inc r29
			jmp salir
			M_Up_High:
			cpi r28, 3
			brne escapeB
			sbr r25, 128
			ldi r28, 0x01
			clr r29
			jmp salir
			
			D_Up:
			pop r18
			sbr r25, 16
			inc r26
			cpi r29, 0x01
			breq D_Up_High
			sbrc r28, 3
			jmp D_Up_High
			cpi r28, 0x02
			breq D_Up_Feb
			cpi r27, 3
			breq D_Up_Low
			cpi r26, 10
			brne escapeB
			clr r26
			inc r27
			sbr r25, 32
			jmp salir
			
			D_Up_High:
			cpi r27, 3
			breq D_Up_High1
			cpi r26, 10
			brne escapeB
			clr r26
			inc r27
			sbr r25, 32
			jmp salir
			D_Up_High1:
			sbrs r28, 0
			jmp D_Up_High_Impar
			jmp D_Up_High_Par
			D_Up_High_Par:
			sbr r25, 32
			ldi r26, 0x01
			clr r27
			jmp salir
			D_Up_High_Impar:
			cpi r26, 0x02
			brne escapeB
			sbr r25, 32
			ldi r26, 0x01
			clr r27
			jmp salir

				

			D_Up_Feb:
			cpi r27, 2
			breq D_Up_Feb_C
			cpi r26, 10
			brne escapeB
			clr r26
			sbr r25, 32
			inc r27
			jmp salir
					escapeB:
					jmp salir
			D_Up_Feb_C:
			cpi r26, 9
			brne escapeB
			ldi r26, 0x01
			sbr r25, 32
			clr r27
			jmp salir


			D_Up_Low:
			sbrs r28, 0
			jmp D_Up_Low_Par
			jmp D_Up_Low_Impar
			D_Up_Low_Par:
			sbr r25, 32
			ldi r26, 0x01
			clr r27
			jmp salir
			D_Up_Low_Impar:
			cpi r26, 0x02
			brne escapeB
			sbr r25, 32
			ldi r26, 0x01
			clr r27
			jmp salir

			A_Up:
			push r18
			lds r18, FA
			sbrc r18, 1
			jmp A_Up_Cancel
			sbrc r18, 0
			jmp A_Up_C
			sts PM, r21
			sts PDM, r22
			sts PH, r23
			sts PDH, r24
			inc r18
			sts FA, r18
			jmp A_Up_C

			A_Up_C:
			lds r18, DigSelect
			sbrc r18, 0
			jmp AM_Up
			jmp AH_Up

			A_Up_Cancel:
			pop r18
			jmp salir

				AM_Up:
				pop r18
				sbr r25, 1
				inc r21
				cpi r21, 10
				brne escapeF
				sbr r25, 2
				clr r21
				inc r22
				cpi r22, 6
				brne escapeF
				clr r22
				jmp salir
						
						escapeF:
						jmp salir

				AH_Up:
				pop r18
				sbr r25, 4
				inc r23
				cpi r24, 2
				breq AH_Up_High
				cpi r23, 10
				brne escapeF
				sbr r25, 8
				clr r23
				inc r24
				cpi r24, 6
				brne escapeF
				clr r24
				jmp salir
				AH_Up_High:
				cpi r23, 4
				brne escapeF
				sbr r25, 8
				clr r23
				clr r24
				jmp salir
				
	B_Down: ; Analiza en cual modo esta y decrementa el digito correspondiente.
	sbrc r14, 0
		jmp salir
		sbrc r14, 1
		jmp salir
		sbrc r14, 2
		jmp HM_Down
		sbrc r14, 3
		jmp F_Down
		sbrc r14, 4
		jmp A_Down

		HM_Down: ; Decrementa hora y minutos
		push r18
		lds r18, DigSelect
		sbrc r18, 0
		jmp M_Down
		jmp H_Down

			M_Down:
			pop r18
			sbr r25, 1
			dec r21
			cpi r21, 0xff
			brne escapeC
			sbr r25, 2
			ldi r21, 0x09
			dec r22
			cpi r22, 0xff
			brne escapeC
			ldi r22, 0x05
			jmp salir

			H_Down:
			pop r18
			sbr r25, 4
			dec r23
			cpi r23, 0xff
			brne escapeC
			sbr r25, 8
			dec r24
			cpi r24, 0xff
			breq H_Down_High
			ldi r23, 0x09
			jmp salir
			H_Down_High:
			ldi r24, 0x02
			ldi r23, 0x03
			jmp salir
			
					escapeC:
					jmp salir

		F_Down: ; Decrementa fecha
		push r18
		lds r18, DigSelect
		sbrc r18, 0
		jmp Mo_Down
		jmp D_Down

			Mo_Down:
			pop r18
			clr r27
			ldi r26, 0x01
			sbr r25, 16
			sbr r25, 32
			sbr r25, 64
			dec r28
			sbrs r29, 0
			breq M_Down_High
			sbrs r28, 7
			jmp salir
			sbr r25, 128
			ldi r28, 0x09
			dec r29
			jmp salir
			M_Down_High:
			cpi r28, 0x00
			brne escapeC
			sbr r25, 128
			ldi r28, 0x02
			ldi r29, 0x01
			jmp salir

			D_Down:
			pop r18
			sbr r25, 16
			dec r26
			cpi r29, 0x01
			breq D_Down_High
			sbrc r28, 3
			jmp D_Down_High
			cpi r28, 0x02
			breq D_Down_Feb
			cpi r27, 0
			breq D_Down_Low
			cpi r26, 0xff
			brne escapeC
			ldi r26, 9
			dec r27
			sbr r25, 32
			jmp salir
			
			D_Down_High:
			cpi r27, 0
			breq D_Down_High1
			cpi r26, 0xff
			brne escapeE
			ldi r26, 0x09
			dec r27
			sbr r25, 32
			jmp salir
			D_Down_High1:
			cpi r26, 0
			brne escapeE
			sbrs r28, 0
			jmp D_Down_High_Par
			jmp D_Down_High_Impar
			D_Down_High_Par:
			sbr r25, 32
			ldi r26, 0x01
			ldi r27, 0x03
			jmp salir
			D_Down_High_Impar:
			sbr r25, 32
			clr r26
			ldi r27, 0x03
			jmp salir

				

			D_Down_Feb:
			cpi r27, 0
			breq D_Down_Feb_C
			cpi r26, 0xff
			brne escapeE
			ldi r26, 0x09
			sbr r25, 32
			dec r27
			jmp salir
					
			D_Down_Feb_C:
			cpi r26, 0
			brne escapeE
			ldi r26, 0x08
			sbr r25, 32
			ldi r27, 0x02
			jmp salir
					

			D_Down_Low:
			cpi r26, 0
			brne escapeE
			sbrs r28, 0
			jmp D_Down_Low_Par
			jmp D_Down_Low_Impar
			D_Down_Low_Par:
			sbr r25, 32
			clr r26
			ldi r27, 0x03
			jmp salir
			D_Down_Low_Impar:
			sbr r25, 32
			ldi r26, 0x01
			ldi r27, 0x03
			jmp salir
					escapeE:
					jmp salir

			A_Down: ; Decrementa fecha
			push r18
			lds r18, FA
			sbrc r18, 1
			jmp A_Up_Cancel
			sbrc r18, 0
			jmp A_Down_C
			sts PM, r21
			sts PDM, r22
			sts PH, r23
			sts PDH, r24
			inc r18
			sts FA, r18
			jmp A_Down_C

			A_Down_C:
			lds r18, DigSelect
			sbrc r18, 0
			jmp AM_Down
			jmp AH_Down

			A_Down_Cancel:
			pop r18
			jmp salir

				AM_Down:
				pop r18
				sbr r25, 1
				dec r21
				cpi r21, 0xff
				brne escapeE
				sbr r25, 2
				ldi r21, 0x09
				dec r22
				cpi r22, 0xff
				brne escapeE
				ldi r22, 0x05
				jmp salir

				AH_Down:
				pop r18
				sbr r25, 4
				dec r23
				cpi r23, 0xff
				brne escapeE
				sbr r25, 8
				dec r24
				cpi r24, 0xff
				breq AH_Down_High
				ldi r23, 0x09
				jmp salir
				AH_Down_High:
				ldi r24, 0x02
				ldi r23, 0x03
				jmp salir


	B_DigChange: ; Cambia el digito que afecta arriba y abajo
		sbrc r14, 0
		jmp salir
		sbrc r14, 1
		jmp salir
		sbrc r14, 2
		jmp DigChange
		sbrc r14, 3
		jmp DigChange
		sbrc r14, 4

		DigChange:
		push r18
		lds r18, DigSelect
		lsl r18
		sbrc r18, 2
		ldi r18, 0x01
		sts DigSelect, r18
		pop r18
		jmp salir

    M_CHANGE: ; Cambia el modo
		lsl r14
		sbrc r14, 5
		jmp modreset
		jmp salir
		modreset:
		push r18
		lds r18, FA
		sbrc r18, 0
		jmp A_Cancel
		pop r18
		ldi r17, 0x01
		mov r14, r17
		jmp salir
		A_cancel:
		clr r18
		sts FA, r18
		pop r18
		lds r21, PM
		lds r22, PDM
		lds r23, PH
		lds r24, PDH
		sbr r25, 15
		ldi r17, 0x01
		mov r14, r17
		jmp salir
	

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

	