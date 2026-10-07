DATA SEGMENT
ORG 00250H
   PORTA EQU 0F0H	; 8255 PPI
   PORTB EQU 0F2H
   PORTC EQU 0F4H
   COM_REG1 EQU 0F6H
   PIC1 EQU 0E0H	; address decoding where A0=A1=0 for icw
   PIC2 EQU 0E2H	; address decoding where A0=A1=1 for ocw
   ICW1 EQU 013H  	;00010011 (0), (a7-a5 interrupt vector address), 1, (1=level triggered, 0=edge triggered), 
				;(1=interval of 4, 0=interval of 8), (1=single, 0=cascade), (1=icw4 needed, 0=icw4 not needed)
   ICW2 EQU 080H	;10000000 interrupt vector address range start (10000000 for 80h start, 01110000 for 70h start, etc)
   ICW4 EQU 003H	;00000011 1,0,0,0, (1=special fully nested mode, 0=not special fully nested mode), 
				;(0x = non buffered, 10 = buffered/slave, 11 = buffered/master), (1=auto eoi, 0=normal eoi), (1=8086 mode, 0=mcs80 mode)
   OCW1 EQU 0F8H	;11111000 how many IR ports youre using, set ports to 0 if youre using. (3 ports, 11111000, 2 ports, 11111100)
   ON_FLAG DB 0
   PAUSE_FLAG DB 0
   MODE_FLAG DB 1
   RUN_DEFAULT_FLAG DB 0
   REQUEST_PAUSE_FLAG DB 0
   TEMP DB ?
DATA ENDS




;***************************************
STK SEGMENT STACK
   BOS DW 64d DUP (?)
   TOS LABEL WORD
STK ENDS
;***************************************




CODE    SEGMENT PUBLIC 'CODE'
        ASSUME CS:CODE, DS:DATA, SS:STK
	ORG 00300H
START:
   MOV AX, DATA
   MOV DS, AX		; set the Data Segment address
   MOV AX, STK
   MOV SS, AX		; set the Stack Segment address
   LEA SP, TOS		; set SP as Top of Stack
   CLI
   
   MOV DX, COM_REG1	; Configuring 8255 PPI
   MOV AL, 10000000B
   OUT DX, AL
   	
   MOV AL, ICW1		; Configuring 8259
   OUT PIC1, AL
   MOV AL, ICW2
   OUT PIC2, AL
   MOV AL, ICW4
   OUT PIC2, AL
   MOV AL, OCW1
   OUT PIC2, AL
   STI
   
   MOV AX, 0
   MOV ES, AX
   
   ; Storing interrupt vector to interrupt vector table in memory
   MOV AX, OFFSET ON_OFF		
   MOV [ES:200H], AX			;calculated from their interrupt vector address x 4, 80H x 4 = 200H
   MOV AX, SEG ON_OFF
   MOV [ES:202H], AX			;next even for stack segment
   MOV AX, OFFSET PAUSE_PLAY
   MOV [ES:204H], AX			;calculated from their interrupt vector address x 4, 81H x 4 = 204H
   MOV AX, SEG PAUSE_PLAY
   MOV [ES:206H], AX			;next even for stack segment
   MOV AX, OFFSET MODES
   MOV [ES:208H], AX			;calculated from their interrupt vector address x 4, 82H x 4 = 208H
   MOV AX, SEG MODES
   MOV [ES:20AH], AX			;next even for stack segment
   
   ; foreground routine
      HERE:
	  CMP MODE_FLAG, 0
	  JE NMI_DISPLAY
	  
	  ; Initialize LED matrix (keep this for your display)
	  MOV AL, 11111111B
	  OUT PORTB, AL
	  MOV AL, 00000000B      ; This was missing - LED matrix control
	  OUT PORTC, AL
	  
	  CALL DISPLAY_FLAGS  
	  
	  CMP ON_FLAG, 0
	  JE HERE
	  CMP PAUSE_FLAG, 1
	  JE CHECK_DELAYED_PAUSE
	  
	 CHECK_DELAYED_PAUSE:
	  CMP REQUEST_PAUSE_FLAG, 1
	  JE SKIP_PAUSE_FOR_NOW
	  JMP PAUSE
	  
	 SKIP_PAUSE_FOR_NOW:
	  CMP RUN_DEFAULT_FLAG, 1
	  JE RUN_DEFAULT_ONCE
	  CMP MODE_FLAG, 1
	  JE DEFAULT
	  
	  JMP HERE				;loop here
   
    
    RUN_DEFAULT_ONCE:
    MOV RUN_DEFAULT_FLAG, 0          ; clear so it runs only once

    ; run DEFAULT one time
    CALL DEFAULT

    ; set PA5 high
    IN   AL, PORTA
    OR   AL, 00100000b
    OUT  PORTA, AL

    ; now allow pausing
    MOV REQUEST_PAUSE_FLAG, 0        ; allow pause to happen now

    JMP HERE

   
   DISPLAY_FLAGS PROC NEAR
    MOV AL, 00000000B
    
	  CMP ON_FLAG, 1
	  JNE DF_SKIP_ON
	  OR AL, 00010000B
	 DF_SKIP_ON:
	  
	  CMP PAUSE_FLAG, 1
	  JNE DF_SKIP_PAUSE
	  OR AL, 00100000B
	 DF_SKIP_PAUSE:
	  
	  CMP MODE_FLAG, 0
	  JNE DF_SKIP_MODE
	  OR AL, 01000000B
	 DF_SKIP_MODE:
	  
	  MOV DX, PORTC
	  OUT DX, AL
	  RET
      DISPLAY_FLAGS ENDP
   
   ; Mode 1
   DEFAULT:
   
   MOTOR_ON:

     ; turn motor ON (PA5 = 1)
     IN  AL, PORTA
     OR  AL, 00100000B
     OUT PORTA, AL

     ; --- 5 second delay ---
     MOV CX, 5          ; 5 loops = 5 seconds
      WAIT_1S:
     MOV DX, 0FFFFh     ; crude 1 second delay
      DELAY_LOOP:
     DEC DX
     JNZ DELAY_LOOP
     LOOP WAIT_1S
     ; ----------------------

     ; turn motor OFF (PA5 = 0)
     IN  AL, PORTA
     AND AL, 11011111B
     OUT PORTA, AL

  STI                     ; Enable interrupts

   DISPLAY_LOOP:
    ; Scroll STRINGs continuously
    MOV SI, OFFSET STRING_1
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_1
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_2
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_2
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_3
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_3
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_4
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_4
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_5
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_5
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_6
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_6
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_7
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_7
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_8
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_8
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_9
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_9
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_10
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_10
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_11
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_11
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_12
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_12
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_13
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_13
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_14
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_14
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_15
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_15
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_16
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_16
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_17
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_17
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_18
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_18
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_19
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_19
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_20
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_20
    CALL PRINT_CHAR

    MOV SI, OFFSET STRING_21
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_21
    CALL PRINT_CHAR
    
    MOV SI, OFFSET STRING_22
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_22
    CALL PRINT_CHAR
    
    MOV SI, OFFSET STRING_23
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_23
    CALL PRINT_CHAR
    
    MOV SI, OFFSET STRING_24
    CALL PRINT_CHAR
    MOV SI, OFFSET STRING_24
    CALL PRINT_CHAR
    
    ; Check if IRQ2/NMI occurred
    CMP MODE_FLAG, 0          
    JE NMI_DISPLAY            ; Jump to NMI routine if triggered

    JMP DISPLAY_LOOP 

     
      
NMI_DISPLAY:
    ; Turn motor OFF
    MOV DX, PORTA
    IN  AL, DX
    AND AL, 11011111B   ; clear PA5
    OUT DX, AL

    ; Display the X using existing routine
    MOV SI, OFFSET NMI_1
    CALL PRINT_NMI
    MOV SI, OFFSET NMI_1
    CALL PRINT_NMI

    ; Optionally display blank afterwards
    MOV SI, OFFSET NMI_2
    CALL PRINT_NMI
     MOV SI, OFFSET NMI_2
    CALL PRINT_NMI
    
    ; Wait while NMI is active
    CMP MODE_FLAG, 0
    JE NMI_DISPLAY

    JMP HERE
   
   ; Print character from the specified STRING
   PRINT_CHAR:
      MOV AH, 11111110B	;column mask i guess since active low, col1 = bit 0 is on, this turns on first column, the lsb column
      MOV DI, SI				;si is current column STRING data, di is the start of the character. so im moving current column STRING to start of the character
      MOV AL, MODE_FLAG	;mov mode into al
      MOV TEMP, AL			; move mode_flag value into temp
   F1:
      CMP MODE_FLAG, 0
      JE NMI_DISPLAY			;if its paused, jump to pause
      MOV AL, AH			;move into al the column mask
      OUT PORTB, AL		;portb or porta idk
      MOV AL, BYTE PTR CS:[SI] ; Get the character to print, this means i want ONE BYTE (8 bits) (BYTE PTR) from where the STRING data is stored (CS:), 
						  ;specifically the current byte of the STRING data ([SI]) 
						  ;I only want one byte inside the code segment where the STRING data is stored at the current position
      OUT PORTA, AL		;output row data
      CMP TEMP, 0
      JE SKIP_ON_CHECK

      CMP ON_FLAG, 0		;is the circuit even on (normal mode)
      JE HERE				;if its not, then jump back to main loop

      SKIP_ON_CHECK:
      CALL DELAY_250MS
      MOV AL, 00H			;then clear row data
      OUT PORTA, AL		;output cleared row data
      INC SI				;remember, SI points to the current position of row and column data. INC moves it to the next byte? this also causes it to shift to the left instead because it builds from lsb.
      CLC
      ROL AH, 1				;this moves the active 0 bit in ah to the left. Each rotation shifts the active column to the next physical column on the LED matrix.
      CALL DELAY_500MS
      JC F1
   RET
   
      ; Print character from the specified STRING
   PRINT_NMI:
      MOV AH, 11111110B	;column mask i guess since active low, col1 = bit 0 is on, this turns on first column, the lsb column
      MOV DI, SI				;si is current column STRING data, di is the start of the character. so im moving current column STRING to start of the character
      MOV AL, MODE_FLAG	;mov mode into al
      MOV TEMP, AL			; move mode_flag value into temp
   F3:
      MOV AL, AH			;move into al the column mask
      OUT PORTB, AL		;portb or porta idk
      MOV AL, BYTE PTR CS:[SI] ; Get the character to print, this means i want ONE BYTE (8 bits) (BYTE PTR) from where the STRING data is stored (CS:), 
						  ;specifically the current byte of the STRING data ([SI]) 
						  ;I only want one byte inside the code segment where the STRING data is stored at the current position
      OUT PORTA, AL		;output row data
      CMP TEMP, 0
      JE SKIP_ON_CHECK_NMI

      CMP ON_FLAG, 0		;is the circuit even on (normal mode)
      JE HERE				;if its not, then jump back to main loop
      SKIP_ON_CHECK_NMI:
      CALL DELAY_250MS
      MOV AL, 00H			;then clear row data
      OUT PORTA, AL		;output cleared row data
      INC SI				;remember, SI points to the current position of row and column data. INC moves it to the next byte? this also causes it to shift to the left instead because it builds from lsb.
      CLC
      ROL AH, 1				;this moves the active 0 bit in ah to the left. Each rotation shifts the active column to the next physical column on the LED matrix.
      CALL DELAY_500MS
      JC F3
   RET
   
   
   PAUSE:
      MOV SI, DI
      MOV AH, 11111110B
   F2:
      CMP PAUSE_FLAG, 0
      JE UNPAUSE
      MOV AL, AH
      OUT PORTB, AL
      MOV AL, BYTE PTR CS:[SI] ; Get the character to print
      OUT PORTA, AL
      CMP ON_FLAG, 0
      JE HERE
      CALL DELAY_250MS
      MOV AL, 00H
      OUT PORTA, AL
      INC SI
      CLC
      ROL AH, 1
      JC F2
      JMP HERE
   UNPAUSE:
      MOV AL, MODE_FLAG
      CMP TEMP, AL
      JNE CHECK_MODE
      RET
      CHECK_MODE:
      CMP MODE_FLAG, 1
      JE DEFAULT

      
      
   OFF:
      MOV AL, 00000000B
      OUT PORTA, AL
      MOV AL, 11111111B
      OUT PORTB, AL
      MOV ON_FLAG, 0
      MOV MODE_FLAG, 1
   JMP HERE
      
   DELAY_250MS:	MOV CX, 250
   TIMER1:
      NOP
      NOP
      NOP
      NOP
      LOOP TIMER1
   RET
   
   DELAY_500MS:	MOV CX, 00FFH	; not 500MS
   L2:
      NOP
      NOP
      LOOP L2
   RET

   DELAY_1MS:	MOV BX, 02CAH
   L1:
      DEC BX
      NOP
      JNZ L1
      RET
   RET
   
; Characters Data to display on 5x7 LED Matrix
STRING_1:
      DB 00011111B
      DB 00000001B
      DB 00000001B
      DB 00001111B
      DB 00000001B
      DB 00000001B
      DB 00011111B

STRING_2:
      DB 00000001B
      DB 00000001B
      DB 00001111B
      DB 00000001B
      DB 00000001B
      DB 00011111B
      DB 00000000B

STRING_3:
      DB 00000001B
      DB 00001111B
      DB 00000001B
      DB 00000001B
      DB 00011111B
      DB 00000000B
      DB 00000001B

STRING_4:
      DB 00001111B
      DB 00000001B
      DB 00000001B
      DB 00011111B
      DB 00000000B
      DB 00000001B
      DB 00000001B


STRING_5: 
      DB 00001111B
      DB 00000001B
      DB 00011111B
      DB 00000000B
      DB 00010000B
      DB 00010000B
      DB 00010000B

STRING_6: 
      DB 00000001B
      DB 00011111B
      DB 00000000B
      DB 00010000B
      DB 00010000B
      DB 00010000B
      DB 00010000B

STRING_7: 
      DB 00011111B
      DB 00000000B
      DB 00010000B
      DB 00010000B
      DB 00010000B
      DB 00010000B
      DB 00010001B

STRING_8: 
      DB 00000000B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00010001B
      DB 00010001B
      DB 00010001B

STRING_9: 
      DB 00010000B
      DB 00010000B
      DB 00010000B
      DB 00010000B
      DB 00010001B
      DB 00010001B
      DB 00001110B

STRING_10:
      DB 00010000B
      DB 00010000B
      DB 00010000B
      DB 00010001B
      DB 00010001B
      DB 00001110B
      DB 00000000B
STRING_11:
      DB 00010000B
      DB 00010000B
      DB 00010001B
      DB 00010001B
      DB 00001110B
      DB 00000000B
      DB 00011111B

STRING_12:
      DB 00010000B
      DB 00010001B
      DB 00010001B
      DB 00001110B
      DB 00000000B
      DB 00011111B
      DB 00000001B

STRING_13:
      DB 00010001B
      DB 00010001B
      DB 00001110B
      DB 00000000B
      DB 00011111B
      DB 00000001B
      DB 00000001B
      
STRING_14:
      DB 00010001B
      DB 00001110B
      DB 00000000B
      DB 00011111B
      DB 00000001B
      DB 00000001B
      DB 00011111B
      
STRING_15:
      DB 00001110B
      DB 00000000B
      DB 00011111B
      DB 00000001B
      DB 00000001B
      DB 00011111B
      DB 00000001B
      
STRING_16:
      DB 00000000B
      DB 00011111B
      DB 00000001B
      DB 00000001B
      DB 00011111B
      DB 00000001B
      DB 00000001B

STRING_17:
      DB 00011111B
      DB 00000001B
      DB 00000001B
      DB 00011111B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      
STRING_18:
      DB 00000001B
      DB 00000001B
      DB 00011111B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000000B
      
STRING_19:
      DB 00000001B
      DB 00011111B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000000B
      DB 00000000B
      
STRING_20:
      DB 00011111B
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000000B
      DB 00000000B
      DB 00000000B

STRING_21:
      DB 00000001B
      DB 00000001B
      DB 00000001B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B

STRING_22:
      DB 00000001B
      DB 00000001B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B

STRING_23:
      DB 00000001B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B

STRING_24:
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B
      DB 00000000B

NMI_1:
      DB 01010101B   ; *   *
      DB 01001110B   ;  * *
      DB 01000100B   ;   *
      DB 01011111B   ; *****
      DB 01000100B   ;   *
      DB 01001110B   ;  * *
      DB 01010101B   ; *   *


NMI_2:
      DB 01000000B
      DB 01000000B
      DB 01000000B
      DB 01000000B
      DB 01000000B
      DB 01000000B
      DB 01000000B

      


PROCED1 SEGMENT 'CODE'	
ON_OFF PROC FAR		;when i press the switch1
						;this ISR will run, toggling the flag to its opposite state
ASSUME CS:PROCED1, DS:DATA
ORG 00000H
   PUSHF
   PUSH AX
   PUSH DX
   MOV DX, PORTC
   IN AL, DX
   CMP ON_FLAG, 1 		;check if circuit is marked on
   JE RESET_ON			;if on, jump to reset
   MOV ON_FLAG, 1 		;if off, mark as on by setting 1 to on_flag
   OR AL, 00010000B
   MOV DX, PORTC
   OUT DX, AL
   JMP EXIT_ON_OFF		;exit procedure
   RESET_ON:
      MOV ON_FLAG, 0		;set on_flag to 0
      OR AL, 00010000B
      MOV DX, PORTC
      OUT DX, AL
   EXIT_ON_OFF:			;general exit code
   POP DX 
   POP AX
   POPF
   IRET
ON_OFF ENDP
PROCED1 ENDS

;MOTOR 
PROCED2 SEGMENT 'CODE'		;this checks whether the current state is paused or played. 
							 ;when called, it will set the flag to on or off. 
PAUSE_PLAY PROC FAR
ASSUME CS:PROCED2, DS:DATA
ORG 00050H
   PUSHF
   PUSH AX
   PUSH DX
   MOV DX, PORTC
   IN AL, DX
   CMP PAUSE_FLAG, 1 		;check if circuit is marked on
   JE RESET_PAUSE			;if on, jump to reset
   MOV PAUSE_FLAG, 1 		;if off, mark as on by setting 1 to on_flag
   OR AL, 00100000B
   MOV DX, PORTC
   OUT DX, AL
   JMP EXIT_PAUSE		;exit procedure
   RESET_PAUSE:
      MOV PAUSE_FLAG, 0		;set on_flag to 0
      OR AL, 00100000B
      MOV DX, PORTC
      OUT DX, AL
   EXIT_PAUSE:			;general exit code
   POP DX 
   POP AX
   POPF
   IRET
PAUSE_PLAY ENDP
PROCED2 ENDS

;X NMI 
PROCED3 SEGMENT 'CODE'	
MODES PROC FAR
ASSUME CS:PROCED3, DS:DATA
ORG 00100H
    PUSHF
    CMP MODE_FLAG, 1
    JE RESET_MODE
    OR  AL, 01000000B
      MOV DX, PORTC
      OUT DX, AL
     MOV MODE_FLAG, 1
    RESET_MODE:
    MOV MODE_FLAG, 0     ; set flag for main loop
    OR AL, 01000000B
    MOV DX, PORTC
   OUT DX, AL
    POPF
    STI
    IRET
MODES ENDP
PROCED3 ENDS

CODE ENDS 
END START
