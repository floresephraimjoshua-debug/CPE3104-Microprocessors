;*********************************************************************************************
;
; File:              FLORES_SY_GOMEZ_ADC.pdsprj
; Author (s):     Ephraim Joshua M. Flores, Riley Aaron Sy & Alexa Janine Gomez
; Class:           CPE 3104  MW 10:30 AM - 1:30  PM
; Description:   Interfacing Analog to Digital Converter (ADC0808)
;
;*********************************************************************************************/


DATA SEGMENT
   PORTA          EQU 0F0H
   PORTB          EQU 0F2H 
   PORTC          EQU 0F4H
   COM_REGA   EQU 0F6H
DATA ENDS

CODE SEGMENT PUBLIC 'CODE'
ASSUME CS:CODE, DS:DATA

MAIN:

    MOV AX, DATA
    MOV DS, AX

    MOV DX, COM_REGA      ; setup control word port
    MOV AL, 89H           ; 10001001B
    OUT DX, AL

START:

    MOV  DX, PORTB
    MOV  AL, 00H  ; 1.) Set ADD_A, ADD_B & ADD_C to 0 to select IN 0 (ADC)
    OUT   DX, AL
    
    CALL WAIT_1MS
    
    MOV  DX, PORTB  ; 2.) Set ALE = 1 to latch ADD_A–C, delay approx. 1 ms, then hold their values.
    MOV  AL, 08H
    OUT   DX, AL
    
    CALL WAIT_1MS
    
    MOV  DX, PORTB  ; 3.)Set START = 1; wait for  approx. 1/CLOCK, holding ADD_A–C and ALE.
    MOV  AL, 18H
    OUT   DX, AL
    
    CALL WAIT_EOC
    
    MOV  DX, PORTB  ; 4.)Set OE = 1, ALE = 0, START = 0, and hold ADD_A–C
    MOV  AL, 20H
    OUT   DX, AL
    
    MOV DX, PORTC      ; or PORTA depending on your wiring
    IN  AL, DX         ; AL = ADC value

    ; Compute whole volts and remainder: divide by 51
    MOV BL, 51
    MOV AH, 0
    DIV BL             ; AX / BL -> quotient in AL (whole volts), remainder in AH

    MOV DL, AL         ; SAVE whole-volts (0..5) in DL

    ; Convert remainder (AH) to tenths digit:
    MOV AL, AH         ; AL = remainder (0..50)
    MOV BH, 10
    MUL BH             ; AX = AL * 10  (AL*10 fits in 0..500)
    ; result now in AX; need to divide by 51

    MOV BL, 51
    DIV BL             ; AX / 51 -> quotient in AL (decimal digit 0..9), remainder in AH

    MOV DH, AL         ; DH = decimal digit (0..9)

    ; Combine digits: upper nibble = decimal, lower nibble = whole
     MOV AL, DL        ; AL = whole-volts (0–5)
     AND AL, 0Fh       ; keep only lower nibble

     MOV AH, DH        ; AH = decimal digit (0–9)
     MOV CL, 4         ; shift count = 4
     SHL AH, CL        ; AH = decimal digit << 4

     OR  AL, AH        ; combine upper and lower nibbles      ; AL = combined BCD byte

    ; Output to port (where 7448 decoders read the nibble pairs)
    MOV DX, PORTA
    OUT DX, AL
    
    JMP START
      
;-----------------------------------

WAIT_EOC:
    MOV BX, 007AH
L2:
    DEC BX
    NOP
    JNZ L2
    RET

WAIT_1MS:
    MOV BX, 0FFFH
L1:
    DEC BX
    NOP
    JNZ L1
    RET

CODE ENDS
END MAIN
