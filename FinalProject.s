; DEFINE GPIO ADDRESSES
; LCD
RS			EQU 0x20		; RS connects to P3.5
RW			EQU 0x40		; RW connects to P3.6
EN			EQU 0x80		; EN connects to P3.7
LCD_CTRL	EQU 0x40004C20	; Port 3 base address assigned to LCD control pins
LCD_DATA	EQU 0x40004C40	; Port 5 base address assigned to LCD data pins

; LED
LED_DATA	EQU 0x40004C01	; Port 2 base address assigned to LEDs
; P2.5->Denied, P2.6->Granted, P2.7->Operational

; RFID Reader / Arduino Nano
RFID_CTRL	EQU 0x40004C00	; Port 1 base address assigned to Arduino control pin

ID_Table	EQU 0x00008000

; LCD Pins
; P3.5->RS, P3.6->RW, P3.7->EN
; P5.0->D0, P5.1->D1, P5.2->D2, P5.3->D3, P5.4->D4, P5.5->D5, P5.6->D6, P5.7->D7
; LED Pins
; P2.5->Denied, P2.6->Granted, P2.7->Operational
; RFID Reader / Arduino Nano Pins
; P1.6->IN, P1.7->IN

			AREA FinalProject, CODE, READONLY
			export __main

__main proc
			; Initialize peripherals
			; LCD
			;BL LCDInit
			
			; LED
			LDR R0, =LED_DATA
			MOV R1, #0xE0			; 1110 0000
			STRB R1, [R0, #0x04]
			; Turn on Operational LED
			MOV R1, #0x80			; 1000 0000
			STRB R1, [R0, #0x02]
			
			; RFID Reader
			LDR R0, =RFID_CTRL
			MOV R1, #0x00			; 0000 0000, P1.7->IN, P1.6->IN
			STRB R1, [R0, #0x04]
			
main_
			;BL LCDNoIDP
						
			; Read RFID
Read		LDR R0, =RFID_CTRL
			LDRB R1, [R0, #0x00]
			AND R1, #0xC0
			CMP R1, #0x00
			BEQ Read
			CMP R1, #0x40
			BEQ Denied		
			
			; Access granted
			; Show access granted message on LCD
			;BL LCDAccGrP
			
			; Indicate access granted with LED
			MOV R2, #0
BlinkLoop1	LDR R0, =LED_DATA
			MOV R1, #0x40			; 0100 0000
			STRB R1, [R0, #0x02]
			
			MOV R12, #0x300			; Adjust delay
			BL Delay
			
			MOV R1, #0x00			; 0000 0000
			STRB R1, [R0, #0x02]
			
			MOV R12, #0x300
			BL Delay
			
			CMP R2, #4
			ADD R2, #1
			BNE BlinkLoop1
			
			MOV R1, #0x80			; 1000 0000
			STRB R1, [R0, #0x02]
			B main_
						
Denied
			; Show denied message on LCD
			;BL LCDDenP
			
			; Indicate access denied with LED
			MOV R2, #0
BlinkLoop2	LDR R0, =LED_DATA
			MOV R1, #0x20			; 0010 0000
			STRB R1, [R0, #0x02]
			
			MOV R12, #0x300			; Adjust delay
			BL Delay
			
			MOV R1, #0x00			; 0000 0000
			STRB R1, [R0, #0x02]
			
			MOV R12, #0x300
			BL Delay
			
			CMP R2, #4
			ADD R2, #1
			BNE BlinkLoop2
			
			MOV R1, #0x80			; 1000 0000
			STRB R1, [R0, #0x02]
			B main_		
			endp
			
			
LCDInit		function					
			LDR R7, =LCD_CTRL		; P3: control pins
			LDR R8, =LCD_DATA		; P5: data or commands 		
			MOV R9, #0xE0			; 1110 0000 
			STRB R9, [R7, #0x04]	; outputs pins for EN, RW, RS
			MOV R9, #0xFF
			STRB R9, [R8, #0x04]	; All of Port 5 as output pins to LCD
			
			PUSH {LR}		
			
			MOV R9, #0x38			; 2 lines, 7x5 characters, 8-bit mode		 
			BL LCDCommand			; Send command in R2 to LCD
			
			; TURN ON THE DISPLAY AND THE CURSOR
			MOV R9, #0x0F
			BL LCDCommand
			
			POP {LR}			
			BX LR
			endp
			
LCDCommand	function				; R2 brings in the command byte			
			LDR R7, =LCD_CTRL
			LDR R8, =LCD_DATA			
			STRB R9, [R8, #0x02]
			MOV R9, #0x00			; RS = 0, command register selected, RW = 0, write to LCD
			ORR R9, #EN
			STRB R9, [R7, #0x02]	; EN = 1
			PUSH {LR}
			MOV R12, #0x50
			BL Delay
			
			MOV R9, #0x00
			STRB R9, [R7, #0x02]	; EN = 0 and RW = RS = 0	
			POP {LR}
			BX LR
			endp				
			
LCDData		function				; R3 brings in the character byte			
			LDR R7, =LCD_CTRL
			LDR R8, =LCD_DATA			
			STRB R10, [R8, #0x02]
			MOV R10, #RS			; RS = 1, data register selected, RW = 0, write to LCD
			ORR R10, #EN
			STRB R10, [R7, #0x02]	; EN = 1
			PUSH {LR}
			MOV R12, #0x50
			BL Delay
			
			MOV R10, #RS
			STRB R10, [R7, #0x02]	; EN = 0, RW = 0, RS = 1	
			
			MOV R9, #0x06
			BL LCDCommand
			
			POP {LR}
			BX LR
			endp
			
LCDNoIDP	function
			PUSH {LR}
			BL ClearLCD
			LDR R7, =NoIDPrompt
			
			MOV R6, #0			
NoIDPLoop1	LDRB R10, [R7, R6]
			BL LCDData
			CMP R6, #3
			ADD R6, #1
			BNE NoIDPLoop1
			
			LDRB R9, [R7, R6]
			BL LCDCommand
			ADD R6, #1
			
NoIDPLoop2	LDRB R10, [R7, R6]
			BL LCDData
			CMP R6, #8
			ADD R6, #1
			BNE NoIDPLoop2
			
			POP {LR}
			BX LR
			endp
			
LCDAccGrP	function
			PUSH {LR}
			BL ClearLCD
			LDR R7, =AccGrPrompt
			MOV R6, #0
			
AccGrPLoop1	LDRB R10, [R7, R6]
			BL LCDData
			CMP R6, #5
			ADD R6, #1
			BNE AccGrPLoop1
			
			LDRB R9, [R7, R6]
			BL LCDCommand
			ADD R6, #1
			
AccGrPLoop2	LDRB R10, [R7, R6]
			BL LCDData
			CMP R6, #13
			ADD R6, #1
			BNE AccGrPLoop2
			
			POP {LR}
			BX LR
			endp
			
LCDDenP		function
			PUSH {LR}
			BL ClearLCD
			LDR R7, =DenPrompt
			MOV R6, #0
			
DenPLoop1	LDRB R10, [R7, R6]
			BL LCDData
			CMP R6, #5
			ADD R6, #1
			BNE DenPLoop1
			
			LDRB R9, [R7, R6]
			BL LCDCommand
			ADD R6, #1
			
DenPLoop2	LDRB R10, [R7, R6]
			BL LCDData
			CMP R6, #12
			ADD R6, #1
			BNE DenPLoop2
			
			POP {LR}
			BX LR
			endp
			
ClearLCD	function
			PUSH {LR}		
			
			; Clear Display
			MOV R9, #0x01
			BL LCDCommand
			
			; Return Cursor Home
			MOV R9, #0x02
			BL LCDCommand
			
			POP {LR}			
			BX LR
			endp
			
Delay		function
			; Inputted value for R12 will change amount of delay.
DelayLoop1	MOV R11, #0xFF
DelayLoop2	SUBS R11, #1
			BNE DelayLoop2
			SUBS R12, #1
			BNE DelayLoop1
			BX LR
			endp
			
			
			AREA FPData, DATA, READONLY

NoIDPrompt	DCB 'S', 'C', 'A', 'N', 0xC0, 'C', 'A', 'R', 'D'
AccGrPrompt	DCB 'A', 'C', 'C', 'E', 'S', 'S', 0xC0, 'G', 'R', 'A', 'N', 'T', 'E', 'D'
DenPrompt	DCB 'A', 'C', 'C', 'E', 'S', 'S', 0xC0, 'D', 'E', 'N', 'I', 'E', 'D'
MasterID	DCB 0x62, 0x5F, 0x8B, 0x51
			end