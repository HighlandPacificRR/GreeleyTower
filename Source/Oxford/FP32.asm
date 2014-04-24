	subtitle	"FP32.asm"
	page
;===========================================================================================
;
;  FileName: FP32.asm
;  Date: 8/31/03
;  File Version: 1.0
;  
;  Author: David M. Flynn
;  Company: Oxford V.U.E., Inc.
;
;============================================================================================
; Notes:
;
;  This file is all general perpose routines.
;  This module may be included in any segment.
;
;  Adapted from: PIC16 32 BIT FLOATING POINT LIBRARY VERSION 1.14
;   found at Programmers Heaven, http://www.programmersheaven.com
;
;  Unary operations: both input and output are in AEXP,AARG
;
;  Binary operations: input in AEXP,AARG and BEXP,BARG with output in AEXP,AARG
;
;  All routines return WREG = 0x00 for successful completion, and WREG = 0xFF
;   for an error condition specified in FPFLAGS.
;
; 32 bit floating point representation
;
;  EXPONENT	8 bit biased exponent
;	It is important to note that the use of biased exponents produces
;	a unique representation of a floating point 0, given by
;	EXP = HIGHBYTE = MIDBYTE = LOWBYTE = 0x00, with 0 being
;	the only number with EXP = 0.
;
;  HIGHBYTE	8 bit most significant byte of sign-magnitude representation, with
;	SIGN = MSB, and implicit mantissa MSB = 1 and radix point to the
;	left of MSB
;
;  MIDBYTE	8 bit middle significant byte of sign-magnitude matissa
;
;  LOWBYTE	8 bit least significant byte of sign-magnitude matissa
;
;	RADIX
;  EXPONENT	POINT 	HIGHBYTE	MIDBYTE	LOWBYTE
;
;  xxxxxxxx	.	Sxxxxxxx	xxxxxxxx	xxxxxxxx
;
;============================================================================================
; Revision History
;
; 1.0    8/31/03	Removed test code.
;	This rev seems to work, but it has not been optimized and 
;	 uses much too much program memory (517 bytes)
; 1.0d1  8/15/03	First Code. FLO32, NRM32, INT32, FPM32, FPD32, FPS32, FPA32
;
;============================================================================================
; Conditionals
;   UsesFP32	FLO32, NRM32, INT32
;   UsesFP32Mult	FPM32
;   UsesFP32Div	FPD32
;   UsesFP32AddSub	FPS32, FPA32
;   UsesTestFP32	TestFP32
;
;============================================================================================
; Default values
	ifndef UsesFP32
	constant	UsesFP32=0
	endif
;
	ifndef UsesFP32Mult
	constant	UsesFP32Mult=0
	endif
;
	ifndef UsesFP32Div
	constant	UsesFP32Div=0
	endif
;
	ifndef UsesFP32AddSub
	constant	UsesFP32AddSub=0
	endif
;
;============================================================================================
;============================================================================================
;
;Routines
; Name	(additional stack words required) Description
;============================================================================================
; FLO32	(0) Integer to float conversion	(AARG  <--  FLOAT( AARG ))
; NRM32  (private)	(0) Normalization routine	(AARG  <--  NORMALIZE( AARG ))
; INT32	(0) Float to integer conversion	(AARG  <--  INT( AARG ))
; FPM32	(0) Floating Point Multiply	(AARG  <--  AARG * BARG)
; FPD32	(0) Floating Point Divide	(AARG  <--  AARG / BARG)
; FPS32	(0) Floating Point Subtract	(AARG  <--  AARG - BARG)
; FPA32	(0) Floating Point Add		(AARG  <--  AARG + BARG)
;
;============================================================================================
; RAM used
;Define binary operation arguments
AEXP	EQU	RAM136	; 8 bit biased exponent for argument A
AARG	EQU	RAM137	; most significant byte of contiguous 6 byte accumulator
			; most significant byte of mantissa for argument A
BEXP	EQU	RAM13D	; 8 bit biased exponent for argument B
BARG	EQU	RAM13E	; most significant byte of mantissa for argument B
;
;Define library register variables
SIGN	EQU	RAM141	; save location for sign in MSB
TEMP	EQU	RAM142	; 2 bytes temporary storage
;
;==================================================================================
;
;Define literal constants
EXPBIAS	EQU	d'128'
B0	EQU	0x00	;MSB
B1	EQU	0x01
B2	EQU	0x02
B3	EQU	0x03
B4	EQU	0x04
B5	EQU	0x05	;LSB
;
;
;Define floating point library exception flags
FPFLAGS	EQU	RAM144	; floating point library exception flags
;
IOV	EQU	0	; bit0 = integer overflow flag
FOV	EQU	1	; bit1 = floating point overflow flag
FUN	EQU	2	; bit2 = floating point underflow flag
FDZ	EQU	3	; bit3 = floating point divide by zero flag
RND	EQU	6	; bit6 = floating point rounding flag, 0 = truncation
			; 1 = rounding to nearest LSB
SAT	EQU	7	; bit7 = floating point saturate flag, 0 = terminate on
			; exception without saturation, 1 = terminate on
			; exception with saturation to appropriate value
;
;====================================================================================================
; Some usefull values
;
; Dec  =  Exp ARG+B0 ARG+B1 ARG+B2	bin
;  0   =  00    00     00     00	0
;  1   =  81    00     00     00	2^1 x .1
;  2   =  82    00     00     00	2^2 x .1
; 2.5  =  82    20     00     00	2^2 x .101
; 3.1416= 82    49     0F     F9	2^2 x .1100 1001 0000 1111 1111 1001
;  5   =  83    20     00     00	2^3 x .101
; 10   =  84    20     00     00	2^4 x .1010
; 100  =  87    48     00     00	2^7 x .1100 100
; 1000 =  8A    7A	00     00	2^10 x .1111 1010 00
; 10000=  8E    1C	40     00	2^14 x .1001 1100 0100 00
; 1000000= 94   74     24     00	2^20 x .1111 0100 0010 0100 0000
;
	if UsesFP32
;====================================================================================================
; Integer to float conversion
;
; Entry: 24 bit 2's complement integer right justified in AARG+B0, AARG+B1, AARG+B2
; Exit: 32 bit floating point number in AEXP, AARG+B0, AARG+B1, AARG+B2
; RAM Used:
; Calls:(0) none
;
; Result: AARG  <--  FLOAT( AARG )
;
FLO32	mBank2
	MOVLW	d'24'+EXPBIAS	; initialize exponent and add bias
	MOVWF	AEXP
	CLRF	SIGN
	BTFSS	AARG+B0,7	; test sign
	GOTO	NRM32
	COMF	AARG+B2,F	; if < 0, negate and set MSB in SIGN
	COMF	AARG+B1,F
	COMF	AARG+B0,F
	INCF	AARG+B2,F
	SKPNZ
	INCF	AARG+B1,F
	SKPNZ
	INCF	AARG+B0,F
	BSF	SIGN,7
;
; fall through to normalization routine NRM32
;
;=============================================================================================================
; Normalization routine
;
; Entry: 32 bit unnormalized floating point number in AEXP, AARG+B0, AARG+B1, AARG+B2, with sign in SIGN,7
; Exit: 32 bit normalized floating point number in AEXP, AARG+B0, AARG+B1, AARG+B2
; RAM Used: none
; Calls:(0) none
;
; Result: AARG  <--  NORMALIZE( AARG )
;
;
NRM32	CLRF	TEMP	; clear exponent decrement
	MOVF	AARG+B0,W	; test if highbyte=0
	SKPZ
	GOTO	NORM32
	MOVF	AARG+B1,W	; if so, shift 8 bits by move
	MOVWF	AARG+B0
	MOVF	AARG+B2,W
	MOVWF	AARG+B1
	CLRF	AARG+B2
	BSF	TEMP,3	; increase decrement by 8
;
	MOVF	AARG+B0,W	; test if highbyte=0
	SKPZ
	GOTO	NORM32
	MOVF	AARG+B1,W	; if so, shift 8 bits by move
	MOVWF	AARG+B0
	CLRF	AARG+B1
	BCF	TEMP,3	; increase decrement by 8
	BSF	TEMP,4
;
	MOVF	AARG+B0,W	; if highbyte=0, result=0
	SKPNZ
	GOTO	RES032
;
NORM32	MOVF	TEMP,W
	SUBWF	AEXP,F
	SKPZ
	BTFSS	STATUS,C
	GOTO	SETFUN32
;
	BCF	STATUS,C	; clear carry bit
;
NORM32A	BTFSC	AARG+B0,7	; if MSB=1, normalization done
	GOTO	FIXSIGN32
	RLF	AARG+B2,F	; otherwise, shift left and 
	RLF	AARG+B1,F	; decrement EXP
	RLF	AARG+B0,F
	DECFSZ	AEXP,F
	GOTO	NORM32A
;
	GOTO	SETFUN32	; underflow if EXP=0
;
FIXSIGN32	BTFSS	SIGN,7
	BCF	AARG+B0,7	; clear explicit MSB if positive
FP_NoErrRtn	BCF	STATUS,RP1	;bank0
	RETLW	0x00
;
;========================================================================================================
; Float to integer conversion
;
; Entry: 32 bit floating point number in AEXP, AARG+B0, AARG+B1, AARG+B2
;        FPFLAGS,RND : FPFLAGS,SAT
; Exit: 24 bit 2's complement integer right justified in AARG+B0, AARG+B1, AARG+B2
; RAM Used: none
; Calls:(0) none
;
;Result: AARG  <--  INT( AARG )
;
;
INT32	mBank2
	CLRF	FPFLAGS	; added by DMF 9/1/03
	MOVF	AARG+B0,W	; save sign in SIGN
	MOVWF	SIGN
	BSF	AARG+B0,7	; make MSB explicit
;
	MOVLW	EXPBIAS	; remove bias from EXP
	SUBWF	AEXP,F
	BTFSS	AEXP,7	; if <= 0, result=0
	SKPNZ
	GOTO	RES032
;
	MOVF	AEXP,W
	SUBLW	d'24'
	MOVWF	AEXP
	SKPZ
	BTFSC	AEXP,7
	GOTO	SETIOV32	
;
	MOVLW	0x08	; do byte shift if EXP >= 8
	SUBWF	AEXP,W
	BTFSS	STATUS,C
	GOTO	SHIFT32
	MOVWF	AEXP
	RLF	AARG+B2,F	; rotate next bit for rounding
	MOVF	AARG+B1,W
	MOVWF	AARG+B2
	MOVF	AARG+B0,W
	MOVWF	AARG+B1
	CLRF	AARG+B0
;
	MOVLW	0x08	; do another byte shift if EXP >= 8
	SUBWF	AEXP,W
	BTFSS	STATUS,C
	GOTO	SHIFT32
	MOVWF	AEXP
	RLF	AARG+B2,F	; rotate next bit for rounding
	MOVF	AARG+B1,W
	MOVWF	AARG+B2
	CLRF	AARG+B1
;
	MOVF	AEXP,W	; shift completed if EXP = 0
	SKPNZ
	GOTO	SHIFT32OK
;
SHIFT32	BCF	STATUS,C
	RRF	AARG+B0,F	; right shift by EXP
	RRF	AARG+B1,F
	RRF	AARG+B2,F
	DECFSZ	AEXP,F
	GOTO	SHIFT32
;
SHIFT32OK	BTFSC	FPFLAGS,RND
	BTFSS	AARG+B2,0
	GOTO	INT32OK
	BTFSS	STATUS,C
	GOTO	INT32OK
	INCF	AARG+B2,F
	SKPNZ
	INCF	AARG+B1,F
	SKPNZ
	INCF	AARG+B0,F
	BTFSC	AARG+B0,7	; test for overflow
	GOTO	SETIOV32
;
INT32OK	BTFSS	SIGN,7	; if sign bit set, negate	
	GOTO	FP_NoErrRtn
	COMF	AARG+B0,F
	COMF	AARG+B1,F
	COMF	AARG+B2,F
	INCF	AARG+B2,F
	SKPNZ
	INCF	AARG+B1,F
	SKPNZ
	INCF	AARG+B0,F
	GOTO	FP_NoErrRtn
;
RES032	CLRF	AARG+B0	; integer result equals zero
	CLRF	AARG+B1
	CLRF	AARG+B2
	CLRF	AEXP	; clear EXP for other routines
	GOTO	FP_NoErrRtn
;
SETIOV32	BSF	FPFLAGS,IOV	; set integer overflow flag
	BTFSS	FPFLAGS,SAT	; test for saturation
	GOTO	FP_ErrRtn	; return error code in WREG
;
	CLRF	AARG+B0	; saturate to largest two's
	BTFSS	SIGN,7	; complement 16 bit integer
	MOVLW	0xFF
	MOVWF	AARG+B0	; SIGN = 0, 0x 7F FF FF
	MOVWF	AARG+B1	; SIGN = 1, 0x 80 00 00
	MOVWF	AARG+B2
	RLF	SIGN,F
	RRF	AARG+B0,F
FP_ErrRtn	BCF	STATUS,RP1	;bank0
	RETLW	0xFF	; return error code in WREG
;
	endif
;
	if UsesFP32Mult
;============================================================================================================
; Floating Point Multiply
;
; Entry: 32 bit floating point number in AEXP, AARG+B0, AARG+B1, AARG+B2
;        32 bit floating point number in BEXP, BARG+B0, BARG+B1, BARG+B2
;        FPFLAGS,RND : FPFLAGS,SAT
; Exit: 32 bit floating point product in AEXP, AARG+B0, AARG+B1, AARG+B2
; RAM Used: none
; Calls:(0) none
;
;Result: AARG  <--  AARG * BARG
;
;
FPM32	mBank2
	MOVLW	0xC0	; RND
	MOVWF	FPFLAGS	; this causes bad results
;	CLRF	FPFLAGS	; added by DMF 9/1/03
	MOVF	AEXP,W	; test for zero arguments
	SKPZ
	MOVF	BEXP,W
	SKPNZ
	GOTO	RES032
;
M32BNE0	MOVF	AARG+B0,W
	XORWF	BARG+B0,W
	MOVWF	SIGN	; save sign in SIGN
;
	MOVF	BEXP,W
	ADDWF	AEXP,F
	MOVLW	EXPBIAS
	BTFSS	STATUS,C
	GOTO	MTUN32
;
	ADDWF	AEXP,F
	BTFSC	STATUS,C
	GOTO	SETFOV32	; set multiply overflow flag
	GOTO	MOK32
;
MTUN32	ADDWF	AEXP,F
	BTFSS	STATUS,C
	GOTO	SETFUN32
;
MOK32	BSF	AARG+B0,7	; make argument MSB's explicit
	BSF	BARG+B0,7
	BCF	STATUS,C
	CLRF    	AARG+B3	; clear initial partial product
	CLRF    	AARG+B4
	CLRF	AARG+B5
	MOVLW	d'24'
	MOVWF	TEMP	; initialize counter
;
MLOOP32	BTFSS	AARG+B2,0	; test high byte
	GOTO	MNOADD32
;
MADD32	MOVF	BARG+B2,W
	ADDWF	AARG+B5,F
	MOVF	BARG+B1,W
	BTFSC	STATUS,C
	INCFSZ	BARG+B1,W
	ADDWF	AARG+B4,F
;
	MOVF	BARG+B0,W
	BTFSC	STATUS,C
	INCFSZ	BARG+B0,W
	ADDWF	AARG+B3,F
;
MNOADD32	RRF	AARG+B3,F
	RRF	AARG+B4,F
	RRF	AARG+B5,F
	RRF	AARG+B0,F
	RRF	AARG+B1,F
	RRF	AARG+B2,F
	BCF	STATUS,C
	DECFSZ	TEMP,F
	GOTO	MLOOP32
;
	BTFSC	AARG+B3,7	; check for postnormalization
	GOTO	MROUND32
	RLF	AARG+B0,F
	RLF	AARG+B5,F
	RLF	AARG+B4,F
	RLF	AARG+B3,F
	DECF	AEXP,F
;
; Round does not work
MROUND32	BTFSC	FPFLAGS,RND
	BTFSS	AARG+B5,0
	GOTO	MUL32OK
;	RLF	AARG+B0,F	;original code rotate next significant bit into
;	BTFSC	STATUS,C	;original code
	BTFSS	AARG+B0,7	;NEW CODE
	GOTO	MUL32OK	;NEW CODE
	INCF	AARG+B5,F	; carry for rounding
	SKPNZ
	INCF	AARG+B4,F
	SKPNZ
	INCF	AARG+B3,F
;
	BTFSS	STATUS,C	; has rounding caused carryout?
	GOTO	MUL32OK
	RRF	AARG+B3,F	; if so, right shift
	RRF	AARG+B4,F
	RRF	AARG+B5,F
	INCF	AEXP,F
	BTFSC	STATUS,C	; check for overflow
	GOTO	SETFOV32
;
MUL32OK	BTFSS	SIGN,7
	BCF	AARG+B3,7	; clear explicit MSB if positive
;
	MOVF	AARG+B3,W
	MOVWF	AARG+B0	; move result to AARG
	MOVF	AARG+B4,W
	MOVWF	AARG+B1
	MOVF	AARG+B5,W
	MOVWF	AARG+B2
	GOTO	FP_NoErrRtn
;
SETFOV32	BSF	FPFLAGS,FOV	; set floating point underflag
	BTFSS	FPFLAGS,SAT	; test for saturation
	GOTO	FP_ErrRtn	; return error code in WREG
;
	MOVLW	0xFF
	MOVWF	AEXP	; saturate to largest floating
	MOVWF	AARG+B0	; point number = 0x FF 7F FF FF
	MOVWF	AARG+B1	; modulo the appropriate sign bit
	MOVWF	AARG+B2
	RLF	SIGN,F
	RRF	AARG+B0,F
	GOTO	FP_ErrRtn	; return error code in WREG
;
	endif
;
	if UsesFP32Div
;=============================================================================================================
; Floating Point Divide
;
; Entry: 32 bit floating point dividend in AEXP, AARG+B0, AARG+B1, AARG+B2
;        32 bit floating point divisor in BEXP, BARG+B0, BARG+B1, BARG+B2
;        FPFLAGS,RND : FPFLAGS,SAT
; Exit: 32 bit floating point quotient in AEXP, AARG+B0, AARG+B1, AARG+B2
; RAM Used: none
; Calls:(0) none
;
; Result: AARG  <--  AARG / BARG
;
;
FPD32	mBank2
	CLRF	FPFLAGS	; added by DMF 9/1/03
	MOVF	BEXP,W	; test for divide by zero
	SKPNZ
	GOTO	SETFDZ32
;
D32BNE0	MOVF	AARG+B0,W
	XORWF	BARG+B0,W
	MOVWF	SIGN	; save sign in SIGN
	BSF	AARG+B0,7	; make argument MSB's explicit
	BSF	BARG+B0,7
;
TALIGN32	CLRF	TEMP	; clear align increment
	MOVF	AARG+B0,W
	MOVWF	AARG+B3	; test for alignment
	MOVF	AARG+B1,W
	MOVWF	AARG+B4
	MOVF	AARG+B2,W
	MOVWF	AARG+B5
;
	MOVF	BARG+B2,W
	SUBWF	AARG+B5,F
	MOVF	BARG+B1,W
	BTFSS	STATUS,C
	INCFSZ	BARG+B1,W
;
TS1ALIGN32	SUBWF	AARG+B4,F
	MOVF	BARG+B0,W
	BTFSS	STATUS,C
	INCFSZ	BARG+B0,W
;
TS2ALIGN32	SUBWF	AARG+B3,F
;
	CLRF	AARG+B3
	CLRF	AARG+B4
	CLRF	AARG+B5
;
	BTFSS	STATUS,C
	GOTO	DALIGN32OK
;
	BCF	STATUS,C	; align if necessary
	RRF	AARG+B0,F
	RRF	AARG+B1,F
	RRF	AARG+B2,F
	RRF	AARG+B3,F
	MOVLW	0x01
	MOVWF	TEMP	; save align increment	
;
DALIGN32OK	MOVF	BEXP,W	; compare AEXP and BEXP
	SUBWF	AEXP,F
	BTFSS	STATUS,C
	GOTO	ALTB32
;
AGEB32	MOVLW	EXPBIAS
	ADDWF	TEMP,W
	ADDWF	AEXP,F
	BTFSC	STATUS,C
	GOTO	SETFOV32
	GOTO	DARGOK32	; set overflow flag
;
ALTB32	MOVLW	EXPBIAS
	ADDWF	TEMP,W
	ADDWF	AEXP,F
	BTFSS	STATUS,C
	GOTO	SETFUN32	; set underflow flag
;
DARGOK32	MOVLW	d'24'	; initialize counter
	MOVWF	TEMP+B1
;
DLOOP32	RLF	AARG+B5,F	; left shift
	RLF	AARG+B4,F
	RLF	AARG+B3,F
	RLF	AARG+B2,F
	RLF	AARG+B1,F
	RLF	AARG+B0,F
	RLF	TEMP,F
;
	MOVF	BARG+B2,W	; subtract
	SUBWF	AARG+B2,F
	MOVF	BARG+B1,W
	BTFSS	STATUS,C
	INCFSZ	BARG+B1,W
DS132	SUBWF	AARG+B1,F
;
	MOVF	BARG+B0,W
	BTFSS	STATUS,C
	INCFSZ	BARG+B0,W
DS232	SUBWF	AARG+B0,F
;
	RLF	BARG+B0,W
	IORWF	TEMP,F
;
	BTFSS	TEMP,0	; test for restore
	GOTO	DREST32
;
	BSF	AARG+B5,0
	GOTO	DOK32
;
DREST32	MOVF	BARG+B2,W	; restore if necessary
	ADDWF	AARG+B2,F
	MOVF	BARG+B1,W
	BTFSC	STATUS,C
	INCFSZ	BARG+B1,W
DAREST32	ADDWF	AARG+B1,F
;
	MOVF	BARG+B0,W
	BTFSC	STATUS,C
	INCF	BARG+B0,W
	ADDWF	AARG+B0,F
;
	BCF	AARG+B5,0
;
DOK32	DECFSZ	TEMP+B1,F
	GOTO	DLOOP32
;
DROUND32	BTFSC	FPFLAGS,RND
	BTFSS	AARG+B5,0
	GOTO	DIV32OK
	BCF	STATUS,C
	RLF	AARG+B2,F	; compute next significant bit
	RLF	AARG+B1,F	; for rounding
	RLF	AARG+B0,F
	RLF	TEMP,F
;
	MOVF	BARG+B2,W	; subtract
	SUBWF	AARG+B2,F
	MOVF	BARG+B1,W
	BTFSS	STATUS,C
	INCFSZ	BARG+B1,W
	GOTO	DS1ROUND32
	BSF	STATUS,C
	BTFSS	STATUS,C
DS1ROUND32	SUBWF	AARG+B1,F
;
	MOVF	BARG+B0,W
	BTFSS	STATUS,C
	INCFSZ	BARG+B0,W
	GOTO	DS2ROUND32
	BSF	STATUS,C
	BTFSS	STATUS,C
DS2ROUND32	SUBWF	AARG+B0,F
;
	RLF	BARG+B0,W
	IORWF	TEMP,W
	ANDLW	0x01	
;
	ADDWF	AARG+B5,F
	BTFSC	STATUS,C
	INCF	AARG+B4,F
	SKPNZ
	INCF	AARG+B3,F
;
	SKPZ		; test if rounding caused carryout
	GOTO	DIV32OK
	RRF	AARG+B3,F
	RRF	AARG+B4,F
	RRF	AARG+B5,F
	INCF	AEXP,F
	SKPNZ		; test for overflow
	GOTO	SETFOV32
;
;
DIV32OK	BTFSS	SIGN,7
	BCF	AARG+B3,7	; clear explicit MSB if positive
;
	MOVF	AARG+B3,W
	MOVWF	AARG+B0,F	; move result to AARG
	MOVF	AARG+B4,W
	MOVWF	AARG+B1,F
	MOVF	AARG+B5,W
	MOVWF	AARG+B2,F
;
	GOTO	FP_NoErrRtn
;
SETFUN32	BSF	FPFLAGS,FUN	; set floating point underflag
	BTFSS	FPFLAGS,SAT	; test for saturation
	GOTO	FP_ErrRtn	; return error code in WREG
;
	MOVLW	0x01	; saturate to smallest floating
	MOVWF	AEXP,F	; point number = 0x 01 00 00 00
	CLRF	AARG+B0	; modulo the appropriate sign bit
	CLRF	AARG+B1
	CLRF	AARG+B2
	RLF	SIGN,F
	RRF	AARG+B0,F
	GOTO	FP_ErrRtn	; return error code in WREG
;
SETFDZ32	BSF	FPFLAGS,FDZ	; set divide by zero flag
	GOTO	FP_ErrRtn
;
	endif
;
	if UsesFP32AddSub
;============================================================================================================
; Floating Point Subtract
;
; Entry: 32 bit floating point number in AEXP, AARG+B0, AARG+B1, AARG+B2
;        32 bit floating point number in BEXP, BARG+B0, BARG+B1, BARG+B2
;        FPFLAGS,RND : FPFLAGS,SAT
; Exit: 32 bit floating point sum in AEXP, AARG+B0, AARG+B1, AARG+B2
; RAM Used: none
; Calls:(0) none
;
; Result: AARG  <--  AARG - BARG
;
FPS32	mBank2
	MOVLW	0x80
	XORWF	BARG+B0,F
;
;============================================================================================================
; Floating Point Add
;
; Entry: 32 bit floating point number in AEXP, AARG+B0, AARG+B1, AARG+B2
;        32 bit floating point number in BEXP, BARG+B0, BARG+B1, BARG+B2
;        FPFLAGS,RND : FPFLAGS,SAT
; Exit: 32 bit floating point sum in AEXP, AARG+B0, AARG+B1, AARG+B2
; RAM Used: none
; Calls:(0) none
;
; Result: AARG  <--  AARG + BARG
;
;
FPA32	mBank2
	CLRF	FPFLAGS	; added by DMF 9/1/03
	MOVF	AARG+B0,W	; exclusive or of signs in TEMP
	XORWF	BARG+B0,W
	MOVWF	TEMP
;
	MOVF	AEXP,W	; use AARG if AEXP >= BEXP
	SUBWF	BEXP,W
	BTFSS	STATUS,C
	GOTO	USEA32
;
	MOVF	BEXP,W
	MOVWF	AARG+B5	; otherwise, swap AARG and BARG
	MOVF	AEXP,W
	MOVWF	BEXP
	MOVF	AARG+B5,W
	MOVWF	AEXP
;
	MOVF	BARG+B0,W
	MOVWF	AARG+B5
	MOVF	AARG+B0,W
	MOVWF	BARG+B0
	MOVF	AARG+B5,W
	MOVWF	AARG+B0
;
	MOVF	BARG+B1,W
	MOVWF	AARG+B5
	MOVF	AARG+B1,W
	MOVWF	BARG+B1
	MOVF	AARG+B5,W
	MOVWF	AARG+B1
;
	MOVF	BARG+B2,W
	MOVWF	AARG+B5
	MOVF	AARG+B2,W
	MOVWF	BARG+B2
	MOVF	AARG+B5,W
	MOVWF	AARG+B2
;
USEA32	MOVF	AARG+B0,W
	MOVWF	SIGN	; save sign in SIGN
	BSF	AARG+B0,7	; make MSB's explicit
	BSF	BARG+B0,7
;
	MOVF	BARG+B0,W
	MOVWF	AARG+B3
	MOVF	BARG+B1,W
	MOVWF	AARG+B4
	MOVF	BARG+B2,W
	MOVWF	AARG+B5
;
	MOVF	BEXP,W	; compute shift count in BEXP
	SUBWF	AEXP,W
	MOVWF	BEXP
	SKPNZ
	GOTO	AROUND32
;
	MOVLW	8
	SUBWF	BEXP,W
	BTFSS	STATUS,C	; if BEXP >= 8, do byte shift
	GOTO	ALIGNB32
	MOVWF	BEXP
	RLF	AARG+B5,F	; rotate next bit for rounding
	MOVF	AARG+B4,W
	MOVWF	AARG+B5
	MOVF	AARG+B3,W
	MOVWF	AARG+B4
	CLRF	AARG+B3
;
	MOVLW	8
	SUBWF	BEXP,W
	BTFSS	STATUS,C	; if BEXP >= 8, do byte shift
	GOTO	ALIGNB32
	MOVWF	BEXP
	RLF	AARG+B5,F	; rotate next bit for rounding
	MOVF	AARG+B4,W
	MOVWF	AARG+B5
	CLRF	AARG+B4
;
;
ALIGNB32	MOVF	BEXP,W	; already aligned if BEXP = 0
	SKPNZ
	GOTO	AROUND32
;
ALOOPB32	BCF	STATUS,C	; right shift by BEXP
	RRF	AARG+B3,F
	RRF	AARG+B4,F
	RRF	AARG+B5,F
	DECFSZ	BEXP,F
	GOTO	ALOOPB32
;
AROUND32	BTFSC	FPFLAGS,RND
	BTFSS	AARG+B5,0
	GOTO	ALIGNED32
;
	BTFSS	STATUS,C
	GOTO	ALIGNED32
	INCF	AARG+B5,F
	SKPNZ
	INCF	AARG+B4,F
	SKPNZ
	INCF	AARG+B3,F
;
	SKPZ
	GOTO	ALIGNED32
	RRF	AARG+B3,F
	RRF	AARG+B4,F
	RRF	AARG+B5,F
	INCF	AEXP,F
	SKPNZ
	GOTO	SETFOV32
;
ALIGNED32	BTFSS	TEMP,7	; negate if signs opposite
	GOTO	AOK32
;
	COMF	AARG+B3,F
	COMF	AARG+B4,F
	COMF	AARG+B5,F
	INCF	AARG+B5,F
	SKPNZ
	INCF	AARG+B4,F
	SKPNZ
	INCF	AARG+B3,F
;
AOK32	MOVF	AARG+B5,W	; add
	ADDWF	AARG+B2,F
	MOVF	AARG+B4,W
	BTFSC	STATUS,C
	INCFSZ	AARG+B4,W
	ADDWF	AARG+B1,F
;
	MOVF	AARG+B3,W
	BTFSC	STATUS,C
	INCFSZ	AARG+B3,W
	ADDWF	AARG+B0,F
;
	BTFSC	TEMP,7
	GOTO	ACOMP32
	BTFSS	STATUS,C
	GOTO	FIXSIGN32
;
	RRF	AARG+B0,F	; shift right and increment EXP
	RRF	AARG+B1,F
	RRF	AARG+B2,F
	INCFSZ	AEXP,F
	GOTO	FIXSIGN32
	GOTO	SETFOV32
;
ACOMP32	BTFSC	STATUS,C
	GOTO	NRM32	; normalize and fix sign
;
	COMF	AARG+B0,F	; negate, toggle sign bit and
	COMF	AARG+B1,F	; then normalize
	COMF	AARG+B2,F
	INCF	AARG+B2,F
	SKPNZ
	INCF	AARG+B1,F
	SKPNZ
	INCF	AARG+B0,F
;
	MOVLW	0x80
	XORWF	SIGN,F
	GOTO	NRM32
;
	endif
;
;
;
;
;
;
;
;
