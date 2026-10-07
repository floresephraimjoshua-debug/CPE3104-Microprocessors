DATA SEGMENT
	ORG 0250H
;==========================================================
; 8255 PPI INITIALIZATIONS
;==========================================================
	PORT1A EQU 0F0H  ;8255 PORT A ADDRESS
	PORT1B EQU 0F2H  ;8255 PORT B ADDRESS
	PORT1C EQU 0F4H  ;8255 PORT C ADDRESS
	CMREG1 EQU 0F6H  ;8255 COMMAND REGISTER ADDRESS
	
	PORT2A EQU 0C0H  ;8255 PORT A ADDRESS
	PORT2B EQU 0C2H  ;8255 PORT B ADDRESS
	PORT2C EQU 0C4H  ;8255 PORT C ADDRESS
	CMREG2 EQU 0C6H  ;8255 COMMAND REGISTER ADDRESS
	
;==========================================================
; 8259 INITIALIZATIONS
;==========================================================	
	PIC1   EQU 0F8H 	 ;8259 COMMAND PORT
	PIC2   EQU 0FAH 	 ;8259 DATA PORT 
   	ICW1   EQU 013H 	 ;INITIALIZATION COMMAND WORD 1  
	ICW2   EQU 080H 	 ;INITIALIZATION COMMAND WORD 2
	ICW4   EQU 003H  	 ;INITIALIZATION COMMAND WORD 4
	OCW1  EQU 0FEH 	 ;OPERATIONAL COMMAND WORD 1
					 ;IR0-IR7: 1111 1110 = 0FEH
	
;==========================================================
; LCD MESSAGES
;==========================================================	
	MSG_TITLE		DB	'AUTOMATIC MARKER ', '$'	
	MSG_TITLE2		DB 	'REFILLER ', '$'
	MSG_REFILL		DB	'REFILLING... ', '$'
	MSG_INK			DB	'INK DETECTED! ', '$'		
	MSG_NO_INK		DB	'NOT ENOUGH INK! ', '$'	
	MSG_FINISHED 	DB	'REFILLING FINISHED!', '$'
	MSG_FINISHED2 	DB 'THANK YOU!', '$'
	MSG_SHUTDOWN	DB	'SHUTTING DOWN... ', '$'	
	
;==========================================================
; FLAGS
;==========================================================	
	ON_FLAG DB 0
	START_FLAG DB 0
	MRK1_FLAG DB 0
	MRK2_FLAG DB 0
	MRK3_FLAG DB 0
	MRK4_FLAG DB 0
DATA ENDS


STCK SEGMENT STACK
	BOS DW 64d DUP (?) ;BOTTOM OF STACK
	TOS LABEL WORD     ;TOP OF STACK
STCK ENDS




;==========================================================
; ON/OFF INTERRUPT
;==========================================================
PROCED1 SEGMENT 'CODE'
ISR1 PROC FAR
 	ASSUME CS:PROCED1, DS:DATA
	ORG 00000H	
	 PUSHF
	 PUSH AX
	 PUSH DX
	 PUSH DS

         CMP ON_FLAG, 1	;CHECKS IF DEVICE IS ON 
	 JE DEF_POS  		;IF DEVICE IS ON, SET TO DEFAULT POSITION AND TURN OFF 

	MOV ON_FLAG, 1	;TURNS THE DEVICE ON, IF IT'S OFF STATE
	
	; DISPLAY LCD TITLE MESSAGE
	 CALL LCD_CLEAR
	 MOV AL, 11000000B
	 CALL LCD_SEND_COMM
	 LEA SI, MSG_TITLE
	 CALL LCD_DISP_TEXT
	 MOV AL, 10010100B
	 CALL LCD_SEND_COMM
	 LEA SI, MSG_TITLE2
	 CALL LCD_DISP_TEXT
	
	JMP END_ISR1

	 DEF_POS:

	 ;DISPLAY LCD SHUTDOWN MESSAGE
	 CALL LCD_CLEAR
	 MOV AL, 11000000B
	 CALL LCD_SEND_COMM
	 LEA SI, MSG_SHUTDOWN
	 CALL LCD_DISP_TEXT
	 CALL DELAY1MS
	 CALL DELAY1MS
	 CALL DELAY1MS
	 CALL LCD_CLEAR
	 
	
	;CODE THAT RETURNS IOs TO NORMAL POSITION
	 MOV ON_FLAG, 0
	 MOV START_FLAG, 0
	 MOV MRK1_FLAG, 0
	 MOV MRK2_FLAG, 0
	 MOV MRK3_FLAG, 0
	 MOV MRK4_FLAG, 0
	 
	 
	 MOV DX, PORT1B
	 MOV AL, 00H
	 OUT DX, AL
	 
	
	 MOV DX, PORT2A		
	 MOV AL, 00H
	 OUT DX, AL

        END_ISR1:
	
	POP DS
	POP DX
	POP AX
	POPF
	IRET
ISR1 ENDP
PROCED1 ENDS


CODE SEGMENT PUBLIC 'CODE'
ASSUME DS:DATA, CS:CODE, SS:STCK
ORG 00300H	

	START:

		MOV DX, DATA	; SETTING DATA SEGMENT ADDRESS
		MOV DS, DX
		MOV DX, STCK	;SETTING STACK SEGMENT ADDRESS
		MOV SS, DX
		LEA SP, TOS  	;SETTING STACK POINTER ADDRESS AS TOP OF STACK
		CLI		;CLEAR INTERRUPT FLAG


		
;==========================================================
; 8255 PROGRAMMING
;==========================================================	
		MOV DX, CMREG1
		MOV AL, 89H
		OUT DX, AL
		
		MOV DX, CMREG2
		MOV AL, 89H
		OUT DX, AL
		
		;	Initialise LCD
		CALL LCD_CLEAR
		CALL LCD_INITIALIZE
		
		
;==========================================================
; 8259 PROGRAMMING
;==========================================================	
		MOV DX, PIC1	;SET COMMAND PORT TO ACCESS ICW1
		MOV AL, ICW1	;STORE COMMAND BYTE 13H IN AL
		OUT DX, AL	;SEND 13H TO ADDRESS 0F8H
		MOV DX, PIC2	;SET DATA PORT TO ACCESS ICW2, ICW3 & OCW1
		MOV AL, ICW2	;STORE DATA BYTE 80H IN AL
		OUT DX, AL      ;SEND 80H TO PORT 0FAH
		MOV AL, ICW4    ;STORE DATA BYTE 03H IN AL
		OUT DX, AL     ;SEND 03H TO PORT 0FAH
		MOV AL, OCW1 	;STORE DATA BYTE 0FCH IN AL
		OUT DX, AL	;SEND 0FCH TO PORT 0FAH
		STI
		
		 MOV AX, 0
		 MOV ES, AX

;==========================================================
; INTERRUPT VECTOR TABLE
;==========================================================	
		MOV AX, OFFSET ISR1	;GET OFFSET ADDRESS OF ISR1 (IP)
		MOV [ES:200H], AX	;STORE HIGH/LOW OFFSET STARTING AT 200H
		MOV AX, SEG ISR1	;GET SEGMENT ADDRESS OF ISR1 (CS)
		MOV [ES:202H], AX
		
	

		;NOTE: THESE ADDRESSES ARE FOR UNMASKED INTERRUPTS (IR0)
		;      ONCE AN INTERRUPT IS TRIGGERED, 8086 READS IVT IN EXTRA SEGMENT
		;      IVT ADDRESSES IS USED TO FIND ROUTINES FOUND IN THE DATA SEGMENT

	       
	       
		MAIN_LOOP:
		
		
;==========================================================
; ON FLAG CHECKER
;==========================================================	

    			CMP ON_FLAG, 1		
			JNE MAIN_LOOP

;==========================================================
; SLOT STATUS INDICATOR
;==========================================================	
			MOV     AL, 00H

			MOV     DX, PORT2C
			IN      AL, DX              ; READ PORTC
			MOV     BL, AL          ; COPY BL TO MASKING
			XOR     AL, AL           ; CLEAR ACCUMULATOR

			; CHECK BIT 0
			MOV     CL, BL
			AND     CL, 01H
			CMP     CL, 01H
			JNE     NEXT1
			OR      AL, CL
			NEXT1:

			; CHECK BIT 1
			MOV     CL, BL
			AND     CL, 02H
			CMP     CL, 02H
			JNE     NEXT2
			OR      AL, CL
			NEXT2:

			; CHECK BIT 2
			MOV     CL, BL
			AND     CL, 04H
			CMP     CL, 04H
			JNE     NEXT3
			OR      AL, CL
			NEXT3:

			; CHECK BIT 3
			MOV     CL, BL
			AND     CL, 08H
			CMP     CL, 08H
			JNE     NEXT4
			OR      AL, CL
			NEXT4:

			MOV     CL, 4
			SHL     AL, CL          ; shift result to upper nibble

			MOV     DX, PORT2A
			OUT     DX, AL
			
;==========================================================
; START FLAG SETTER
;==========================================================	
			MOV  DX, PORT2C
			IN   AL, DX
			TEST AL, 10H	;START IS LOCATED IN PORT2C, BIT 04 
			JZ      STARTFLAG_SET0
			JMP STARTFLAG_SET1
			
			
			
			CONTINUE:
			
;==========================================================
; INK-LEVEL SENSOR
;==========================================================				
			; SELECT CHANNEL IN0 (ADD_A=0, ADD_B=0, ADD_C=0)
			MOV DX, PORT1B
			MOV AL, 00000000b   ; PB0=ADD_A, PB1=ADD_B, PB2=ADD_C, PB3-5=ALE, START & OE
			OUT DX, AL

			;PULSE ALE TO LATCH ADDRESS
			MOV AL, 00001000b   ; ALE = PB3 = 1
			OUT DX, AL
			CALL DELAY1MS       ; SHORT DELAY TO LATCH ADDRESS
			MOV AL, 00000000b   ; ALE = 0
			OUT DX, AL

			; START CONVERSION
			MOV AL, 00010000b   ; START = PB4 = 1
			OUT DX, AL
			CALL DELAY1MS       ; WAIT CONVERSION
			MOV AL, 00000000b   ; START LOW
			OUT DX, AL

			; ENABLE OUTPUT
			MOV AL, 00100000b   ; OE = PB5 = 1
			OUT DX, AL
			CALL DELAY1MS

			; READ ADC VALUE FROM PORTC 
			MOV DX, PORT1C
			IN AL, DX
			CALL REVERSE_BITS

			; THRESHOLD IS ANYTHING LESS THAN 51 STEPS  (5000 mV x 51/255 = 1000 mV = 1V)
			; LOW-FLUID LEVELS MEAN THAT INK AS A CONDUCTIVE MEDIUM IS NO LONGER AVAILABLE 


			CMP AX, 33H 	;33H = 51D
			JL SENSOR_LOW   ; below threshold ? clear START_FLAG
			JMP SENSOR_OK

			;REVERSE BITS (ADC0808 LSB = OUT8, MSB = OUT1)
			REVERSE_BITS:
			   PUSH CX
			   PUSH DX
			   PUSH SI
			   XOR DX, DX
			   XOR SI, SI
			   MOV CL, 8
			REV_LOOP:
			   MOV DL, AL
			   AND DL, 1
			   SHL SI, 1
			   OR SI, DX
			   SHR AL, 1
			   DEC CL
			   JNZ REV_LOOP
			   MOV AX, SI
			   POP SI
			   POP DX
			   POP CX
			   RET

			;1MS DELAY
			DELAY1MS PROC FAR
			   PUSH CX        ;SAVE REGISTERS
			   PUSH DX
			   MOV CX, 50     ;OUTER LOOP (MAJOR CLOCK)
			OUTER_LOOP:
			   MOV DX, 200    ;INNER LOOP (MINOR CLOCK)
			INNER_LOOP:
			   NOP            ; WASTE 1 CYCLE
			   DEC DX
			   JNZ INNER_LOOP
			   DEC CX
			   JNZ OUTER_LOOP
			   POP DX         ;RESTORE REGISTERS
			   POP CX
			   RET 
			DELAY1MS ENDP

			   ;WATER LEVEL IS LOW, HIGH RESISTANCE AND LOW VOLTAGE
			   SENSOR_LOW:
			      MOV START_FLAG, 0 	;DO NOT START MOTORS
			      
			      ;	DISPLAY LOW INK MESSAGE
			      CALL LCD_CLEAR
			      MOV AL, 11000000B
			      CALL LCD_SEND_COMM
			      LEA SI, MSG_NO_INK
			      CALL LCD_DISP_TEXT
			      CALL DELAY1MS
			      CALL DELAY1MS
			      CALL DELAY1MS
			      CALL LCD_CLEAR
			      
			      JMP MAIN_LOOP
    
			   SENSOR_OK:
			   ; START_FLAG REMAIN AS IS



;==========================================================
; START FLAG CHECKER
;==========================================================	
	
			START_STATE:    ;CHECKS START_FLAG
			CMP START_FLAG, 1
			JNE MAIN_LOOP
			
	
			
;==========================================================
; MARKER SLOT DETECTION
;==========================================================	
			SLOT1:
			MOV DX, PORT2C
			IN AL, DX
			AND AL, 01H
			CMP AL, 01H
			JE CALL_MRK1_SET
			
			SLOT2:
			MOV DX, PORT2C
			IN AL, DX
			AND AL, 02H
			CMP AL, 02H
			JE CALL_MRK2_SET
			
			SLOT3:
			MOV DX, PORT2C
			IN AL, DX
			AND AL, 04H
			CMP AL, 04H
			JE CALL_MRK3_SET
			
			SLOT4:
			MOV DX, PORT2C
			IN AL, DX
			AND AL, 08H
			CMP AL, 08H
			JE CALL_MRK4_SET
			
			JMP MOTOR_CONTROL
			
			
			
			 
;==========================================================
; POSITION TEST
;==========================================================	
			MOTOR_CONTROL:
			
			MOV AL, 00H

			CMP MRK1_FLAG, 1
			JNE SKIP1
			OR  AL, 01H
			MOV MRK1_FLAG, 0
			SKIP1:

			CMP MRK2_FLAG, 1
			JNE SKIP2
			OR  AL, 02h
			MOV MRK2_FLAG, 0
			SKIP2:

			CMP MRK3_FLAG, 1
			JNE SKIP3
			OR  AL, 04h
			MOV MRK3_FLAG, 0
			SKIP3:

			CMP MRK4_FLAG, 1
			JNE SKIP4
			OR  AL, 08h
			MOV MRK4_FLAG, 0

			SKIP4:


;==========================================================
; ACTIVATE PUMPS
;==========================================================	
			CMP AL, 00H
			JE MAIN_LOOP		 ;CHECKS IF MARKER SLOTS ARE FILLED
			MOV DX, PORT2A		 ;OUTPUT COMBINED PUMP BITMASK
			OUT DX, AL
			
			 ;	DISPLAY INK MESSAGE
			CALL LCD_CLEAR
			MOV AL, 11000000B
			CALL LCD_SEND_COMM
			LEA SI, MSG_INK
			CALL LCD_DISP_TEXT
			CALL DELAY1MS
			CALL DELAY1MS
			CALL DELAY1MS
		
			;	DISPLAY REFILLING MESSAGE
			CALL LCD_CLEAR
			MOV AL, 11000000B
			CALL LCD_SEND_COMM
			LEA SI, MSG_REFILL
			CALL LCD_DISP_TEXT
			
			
			;PUMPS RUN IN 5 SECS
			MOV CX, 2D          	;100 X 50ms  = 5 SECS
			DELAY_OUTER:
			MOV DX, 0FFFFh   		;50MS INNER DELAY
			DELAY_INNER:
			DEC DX
			JNZ DELAY_INNER
			LOOP DELAY_OUTER
			
			;TURN ALL PUMPS OFF
			MOV DX, PORT2A		
			MOV AL, 00H
			OUT DX, AL
			
			
			; DISPLAY LCD FINISHED MESSAGE
			CALL LCD_CLEAR
			MOV AL, 11000000B
			CALL LCD_SEND_COMM
			LEA SI, MSG_FINISHED
			CALL LCD_DISP_TEXT
			MOV AL, 10010100B
			CALL LCD_SEND_COMM
			LEA SI, MSG_FINISHED2
			CALL LCD_DISP_TEXT
			
			CALL DELAY1MS
			CALL DELAY1MS
			CALL DELAY1MS
			CALL DELAY1MS
			CALL DELAY1MS
			CALL DELAY1MS
			
			; DISPLAY LCD TITLE MESSAGE
			CALL LCD_CLEAR
			MOV AL, 11000000B
			CALL LCD_SEND_COMM
			LEA SI, MSG_TITLE
			CALL LCD_DISP_TEXT
			MOV AL, 10010100B
			CALL LCD_SEND_COMM
			LEA SI, MSG_TITLE2
			CALL LCD_DISP_TEXT
			
			
			JMP PROC_END
			
			
			
			
			
;==========================================================
; MARKER SLOT FLAGS
;==========================================================	
			MRK1_SET:
			   MOV MRK1_FLAG, 1
			   RET
			 
			MRK2_SET:
			   MOV MRK2_FLAG, 1
			   RET
	
			MRK3_SET:
			   MOV MRK3_FLAG, 1
			   RET

			MRK4_SET:
			   MOV MRK4_FLAG, 1
			   RET
			
;==========================================================
; CALL ROUTINES
;==========================================================	
			CALL_MRK1_SET:		;REDUNDANCY REQUIRED SINCE 'JE' CANNOT BE USED WITH 'RET'
			CALL  MRK1_SET
			JMP SLOT2
			
			CALL_MRK2_SET:
			CALL MRK2_SET
			JMP SLOT3
			
			CALL_MRK3_SET:
			CALL MRK3_SET
			JMP SLOT4
			
			CALL_MRK4_SET:
			CALL MRK4_SET
			JMP MOTOR_CONTROL

;==========================================================
; START FLAG ROUTINES
;==========================================================	
	               ;ROUTINE THAT SETS START FLAG = 0
			STARTFLAG_SET0:
			MOV START_FLAG , 0
			JMP CONTINUE
			
			;ROUTINE THAT SETS START FLAG = 1
			STARTFLAG_SET1:		    
			MOV START_FLAG, 1
			JMP CONTINUE
			
;==========================================================
; LCD ROUTINES
;==========================================================	
			LCD_INITIALIZE:
			    MOV AL, 00111000B
			    CALL LCD_SEND_COMM
			    MOV AL, 00001000B
			    CALL LCD_SEND_COMM
			    MOV AL, 00000001B
			    CALL LCD_SEND_COMM
			    MOV AL, 00000110B
			    CALL LCD_SEND_COMM
			    MOV AL, 00001100B
			    CALL LCD_SEND_COMM
			    RET
			
			   
			LCD_CLEAR PROC FAR
			    MOV AL, 00000001B
			    CALL LCD_SEND_COMM
			    CALL DELAY_LCD
			    CALL DELAY_LCD
			    RET
			    LCD_CLEAR ENDP
			 

			LCD_SEND_COMM PROC FAR
			    PUSH AX
			    PUSH BX
			    MOV DX, PORT1A
			    OUT DX, AL
			    MOV DX, PORT1B
			    MOV AL, 10000000B
			    OUT DX, AL
			    CALL DELAY_LCD
			    MOV DX, PORT1B
			    MOV AL, 00000000B
			    OUT DX, AL
			    POP BX
			    POP AX
			    RET
			LCD_SEND_COMM ENDP
			  
			    
			LCD_DISP_TEXT PROC FAR
			    MOV AL, [SI]
			    CMP AL, '$'
			    JE LCD_TEXT_END
			    CALL LCD_SEND_CHAR
			    INC SI
			    JMP LCD_DISP_TEXT
			LCD_TEXT_END:
			    RET
			    LCD_DISP_TEXT ENDP
			
			
			LCD_SEND_CHAR:
			 PUSH AX
			 PUSH BX
			 MOV DX, PORT1A
			 OUT DX, AL
			 MOV DX, PORT1B
			 MOV AL, 11000000B
			 OUT DX, AL
			 CALL DELAY_LCD
			 MOV DX, PORT1B
			 MOV AL, 01000000B
			 OUT DX, AL
			 POP BX
			 POP AX
			 RET
			
	
			DELAY_LCD:
			    MOV BX, 02CAH
			DELAYLOOP_1MS:
			    DEC BX
			    NOP
			    JNZ DELAYLOOP_1MS
			    RET
		        
			DELAY_FAST:
			   MOV CX, 020h
			DFAST:
			   NOP
			   LOOP DFAST
			   RET			   
			
			
			
			
;==========================================================
; END OF PROCESS
;==========================================================				
			
			PROC_END:
			
			
			
			MOV START_FLAG, 0
			;WAIT FOR START BUTTON TO BE RELEASED
			WAIT_START_RELEASE:
			MOV DX, PORT2C
			IN AL, DX
			TEST AL, 10H
			JNZ WAIT_START_RELEASE     ;STILL PRESSED, WAIT
			

			JMP MAIN_LOOP
      
			

		
CODE ENDS
END START

		


		


