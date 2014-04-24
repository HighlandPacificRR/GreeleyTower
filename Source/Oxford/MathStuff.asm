	subtitle	"MathStuff.asm"
	page
;===========================================================================================
;
;  FileName: MathStuff.asm
;  Date: 4/21/05
;  File Version: 1.1
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
;============================================================================================
; Revision History
;
; 1.1    4/21/05	Broke out Div16by16 to save memory
; 1.0d2  8/20/03	Added Div24x24
; 1.0d1  8/15/03	First Code, Mult16x16
;
;============================================================================================
; Conditionals
;
;  UsesMult16x16	Mult16x16
;  UsesDiv32by16	Div32by16
;  UsesDiv24x24	Div24x24
;
;============================================================================================
; Default values
;
	ifndef UsesDiv24x0A
	constant	UsesDiv24x0A=0
	endif
;
	ifndef UsesDiv24xW
	constant	UsesDiv24xW=0
	endif
;
	ifndef UsesDiv16x16
	constant	UsesDiv16x16=0
	endif
;
	ifndef UsesMult16x16
	constant	UsesMult16x16=0
	endif
;
	ifndef UsesDiv32by16
	constant	UsesDiv32by16=0
	endif
;
	ifndef UsesDiv24x24
	constant	UsesDiv24x24=0
	endif
;
	ifndef UsesDiv32x32
	constant	UsesDiv32x32=0
	endif
;
;============================================================================================
;
;Routines
; Name	(additional stack words required) Description
;============================================================================================
;
;Mult16x16	(0) Multiply two 16 bit numbers. A 32 bit number is returned. (58 bytes)
;Div32by16	(0) Divide a 32 bit number by a 16 bit number and return a 16 bit number.
;Div24x0A	(0) 24 bit devide by d'10' Param7B:Param7A:Param79 = Param7B:Param7A:Param79 / d'10'
;Div24xW	(1+0) Devide a 24 bit number by W
;Div16x16	(0) 16 bit devide nrator1:nrator0 / denom1:denom0 >> result1:result0, remain1:remain0
;Div24x24	(0) Devide a 24 bit number by another 24 bit number and return a 24 bit number
;Div32x32	(0) Devide a 32 bit number by another 32 bit number and return a 32 bit number
;Div16x16 (alt)	(0) Devide a 16 bit number by another 16 bit number and return a 16 bit number
;============================================================================================
; RAM used
	if UsesDiv32x32
nrator3	EQU	RAM146
nrator2	EQU	RAM145
result3	EQU	RAM146
result2	EQU	RAM145
denom3	EQU	RAM142
denom2	EQU	RAM141
remain3	EQU	RAM13E
remain2	EQU	RAM13D
shift3	EQU	RAM13A
shift2	EQU	RAM139
	endif
;
	if UsesDiv32x32 | UsesDiv16x16
nrator1	EQU	RAM144
nrator0	EQU	RAM143
result1	EQU	RAM144
result0	EQU	RAM143
denom1	EQU	RAM140
denom0	EQU	RAM13F
remain1	EQU	RAM13C
remain0	EQU	RAM13B
shift1	EQU	RAM138
shift0	EQU	RAM137
BCount	EQU	RAM136
	endif
;
;==================================================================================
	if UsesMult16x16
;============================================================================================
; Multiply two 16 bit numbers. A 32 bit number is returned.
; Numbers are little endian
;
; Entry: Param71:Param70 * Param73:Param72 (aka I1 * I2)
; Exit: Param77:Param76:Param75:Param74 (aka L)
; RAM Used:Param70..Param77
; Calls:(0) none
;
Mult16x16	CLRF	Param74	;L=0
	CLRF	Param75
	CLRF	Param76
	CLRF	Param77
;
	MOVFW	Param70	;if I1==0 then exit
	IORWF	Param71,W
	SKPNZ
	RETURN
;
	MOVFW	Param72	;if I2==0 then exit
	IORWF	Param73,W
	SKPNZ
	RETURN
;
	MOVFW	Param70	;L=I1
	MOVWF	Param74,F
	MOVFW	Param71
	MOVWF	Param75,F
;
	TSTF	Param73	;if I2==1 then exit
	SKPZ		; else L=L*2
	GOTO	Mult16x16_notZ
	MOVLW	0x01
	SUBWF	Param72,W
	SKPZ
	GOTO	Mult16x16_notZ
	RETURN
;
Mult16x16_AddI1	MOVFW	Param70	;L=L+I1
	ADDWF	Param74,F
	MOVLW	0x01
	BTFSC	STATUS,C
	ADDWF	Param75,F
	BTFSC	STATUS,C
	ADDWF	Param76,F
	BTFSC	STATUS,C
	ADDWF	Param77,F
	MOVFW	Param71
	ADDWF	Param75,F
	MOVLW	0x01
	BTFSC	STATUS,C
	ADDWF	Param76,F
	BTFSC	STATUS,C
	ADDWF	Param77,F
;
Mult16x16_notZ	RRF	Param73,F	;ASR I2
	RRF	Param72,F
	BCF	Param73,7
;
	BCF	STATUS,C	;ASL L
	RLF	Param74,F
	RLF	Param75,F
	RLF	Param76,F
	RLF	Param77,F
;
	BTFSS	Param72,0	;if lsb is 0 then L=L*2
	GOTO	Mult16x16_notZ
Mult16x16_Tst1	TSTF	Param73	;if I2==1 then exit
	SKPZ		; else L=L+I1
	GOTO	Mult16x16_AddI1
	MOVLW	0x01
	SUBWF	Param72,W
	SKPZ
	GOTO	Mult16x16_AddI1
	RETURN
;
	endif
;
	if UsesDiv32by16
;============================================================================================
; Divide a 32 bit number by a 16 bit number and return a 16 bit number.
; Numbers are little endian
;
; Entry: 
;   numerator: Param77:Param76:Param75:Param74
;   denominator: Param72:Param71
; Exit: 
;   result: Param77:Param76:Param75:Param74
;   remainder: remain3 remain2  remain1  remain0
; RAM used:Param71..Param77
; Calls:(0) none
;
Div32by16	mBank2
	MOVFW	Param74
	MOVWF	shift0
	MOVFW	Param75
	MOVWF	shift1
	MOVFW	Param76
	MOVWF	shift2
	MOVFW	Param77
	MOVWF	shift2
;
	MOVFW	Param71
	MOVWF	denom0
	MOVFW	Param72
	MOVWF	denom1
	CLRF	denom2
	CLRF	denom3
	CALL	Div32x32_E2
	BSF	STATUS,RP1	;Bank 2
	MOVFW	result0
	MOVWF	Param74
	MOVFW	result1
	MOVWF	Param75
	MOVFW	result2
	MOVWF	Param76
	MOVFW	result3
	MOVWF	Param77
	BCF	STATUS,RP1	;Bank 0
	RETURN
;
	endif
;
	if UsesDiv24x0A
;============================================================================================
; 24 bit devide by d'10' (universal version)
;
; Param7B:Param7A:Param79 = Param7B:Param7A:Param79 / d'10'
;
; Entry: Param7B:Param7A:Param79
;   (aka numerator: nrator2  nrator1  nrator0)
; Exit: Param7B:Param7A:Param79, remain2:remain1:remain0
; RAM used: Param7B,Param7A,Param79
; Calls: (1+0) Div32x32_E2
; 
Div24x0A	MOVLW	0x0A
;
;
; fall through to Div24xW
	endif
;
	if UsesDiv24xW
;============================================================================================
; Devide a 24 bit number by W
;
; Param7B:Param7A:Param79 = Param7B:Param7A:Param79 / W
;
; Entry: Param7B:Param7A:Param79, W
;   (aka numerator: nrator2  nrator1  nrator0)
; Exit: Param7B:Param7A:Param79, remain2:remain1:remain0
; RAM used: Param7B,Param7A,Param79
; Calls: (1+0) Div32x32_E2
; 
Div24xW	mBank2
	MOVWF	denom0
	CLRF	denom1
	CLRF	denom2
	CLRF	denom3
	CLRF	shift3
	MOVFW	Param7B
	MOVWF	shift2
	MOVFW	Param7A
	MOVWF	shift1
	MOVFW	Param79
	MOVWF	shift0
	CALL	Div32x32_E2
	BSF	STATUS,RP1	;Bank 2
	MOVFW	result2
	MOVWF	Param7B
	MOVFW	result1
	MOVWF	Param7A
	MOVFW	result0
	MOVWF	Param79
	BCF	STATUS,RP1	;Bank 0
	RETURN
;
	endif
;
;
	if UsesDiv16x16
;==================================================================================
;Div16x16  16 bit devide (minimum version)
; nrator=nrator/denom
;
; Entry:
;   numerator: nrator1:nrator0
;   denominator: denom1:denom0
; Exit:
;   result: result1:result0
;   remainder: remain1:remain0
; RAM used: none
; Calls: (0) Div32x32
;
	if UsesDiv32x32 | UsesDiv24x24
Div16x16	mBank2
	CLRF	nrator2
	CLRF	denom2
	endif
;
;  fall through to Div24x24
;
	endif
;
	if UsesDiv24x24 | UsesDiv32x32
;============================================================================================
; Devide a 24 bit number by another 24 bit number and return a 24 bit number
;  (mimimum code version)
;
; Entry:
;  numerator: nrator2:nrator1:nrator0
;  denominator: denom2:denom1:denom0
; Exit:
;  result: result2:result1:result0
;  remainder: remain2  remain1  remain0
; RAM used: none
; Calls: (0) Div32x32
;
Div24x24	mBank2
	CLRF	nrator3
	CLRF	denom3
;
; fall through to Div32x32
;
	endif
;
	if UsesDiv32x32 | UsesDiv24x24
;==============================================================================================
; Devide a 32 bit number by another 32 bit number and return a 32 bit number
;
; Note: nrator and result are the same registers
;
; Entry:
;   numerator: nrator3:nrator2:nrator1:nrator0
;   denominator: denom3:denom2:denom1:denom0
; Exit:
;   result: result3:result2:result1:result0
;   remainder: remain3:remain2:remain1:remain0
; RAM used: none
; Calls:(0) none
;
Div32x32	mBank2
	MOVF	nrator3,W	;shift=nrator
	MOVWF	shift3
	MOVF	nrator2,W	;shift=nrator
	MOVWF	shift2
	MOVF	nrator1,W
	MOVWF	shift1
	MOVF	nrator0,W
	MOVWF	shift0
Div32x32_E2	MOVLW	d'32'
	MOVWF	BCount	;we'll be shifting 32 bits
	CLRF	result3	;result=0
	CLRF	result2
	CLRF	result1
	CLRF	result0
;
	CLRF	remain3	;remain=0
	CLRF	remain2
	CLRF	remain1
	CLRF	remain0
Div32x32_L1	BCF	STATUS,C	;C=0
	RLF	shift0,F	;ASL shift
	RLF	shift1,F
	RLF	shift2,F
	RLF	shift3,F	;C=shift<32>
	RLF	remain0,F	;ROL remain
	RLF	remain1,F
	RLF	remain2,F
	RLF	remain3,F
;
	MOVF	denom3,W
	SUBWF	remain3,W
	BTFSS	STATUS,Z	;denom=remain?
	GOTO	Div32x32_1	;No
;
	MOVF	denom2,W
	SUBWF	remain2,W
	BTFSS	STATUS,Z	;denom=remain?
	GOTO	Div32x32_1	;No
;
	MOVF	denom1,W
	SUBWF	remain1,W
	BTFSS	STATUS,Z
	GOTO	Div32x32_1
;
	MOVF	denom0,W
	SUBWF	remain0,W
Div32x32_1	BTFSS	STATUS,C	;denom>remain?
	GOTO	Div32x32_2	;yes
;
	MOVF	denom0,W	;remain=remain-denom
	SUBWF	remain0,F	;remain0=remain0-denom0
	SKPB		;if borrow then cascade carry
	GOTO	Div32x32_nb1
;	
	DECF	remain1,F	; remain1--
	MOVF	remain1,W
	XORLW	0xFF
	SKPZ		;if remain1=0xFF
	GOTO	Div32x32_nb1
	DECF	remain2,F	; remain2--
	MOVF	remain2,W
	XORLW	0xFF
	SKPNZ		;if remain1=0xFF
	DECF	remain3,F	; remain2--
;	
Div32x32_nb1	MOVF	denom1,W
	SUBWF	remain1,F	;remain1=remain1-denom1
	SKPB		;if borrow
	GOTO	Div32x32_nb2
	DECF	remain2,F	; remain2--
	MOVF	remain2,W
	XORLW	0xFF
	SKPNZ		;if remain1=0xFF
	DECF	remain3,F	; remain2--
;	
Div32x32_nb2	MOVF	denom2,W
	SUBWF	remain2,F	;remain2=remain2-denom2
	SKPNB		;if borrow
	DECF	remain3,F	;  remain3--
	MOVF	denom3,W
	SUBWF	remain3,F	;remain3=remain3-denom3
	BSF	STATUS,C
Div32x32_2	RLF	result0,F
	RLF	result1,F
	RLF	result2,F
	RLF	result3,F
	DECFSZ	BCount,F
	GOTO	Div32x32_L1
;
	BCF	STATUS,RP1	;Bank 0
	RETURN 
;
	else
	if UsesDiv16x16
;
;==============================================================================================
; Devide a 16 bit number by another 16 bit number and return a 16 bit number
;
; Note: nrator and result are the same registers
;
; Entry:
;   numerator: nrator1:nrator0
;   denominator: denom1:denom0
; Exit:
;   result: result1:result0
;   remainder: remain1:remain0
; RAM used: none
; Calls:(0) none
;
Div16x16	mBank2
	MOVF	nrator1,W	;shift=nrator
	MOVWF	shift1
	MOVF	nrator0,W
	MOVWF	shift0
	MOVLW	d'16'
	MOVWF	BCount	;we'll be shifting 16 bits
	CLRF	result1	;result=0
	CLRF	result0
;
	CLRF	remain1	;remain=0
	CLRF	remain0
Div16x16_L1	BCF	STATUS,C	;C=0
	RLF	shift0,F	;ASL shift
	RLF	shift1,F	;C=shift<16>
	RLF	remain0,F	;ROL remain
	RLF	remain1,F
;
	MOVF	denom1,W
	SUBWF	remain1,W
	BTFSS	STATUS,Z
	GOTO	Div16x16_1
;
	MOVF	denom0,W
	SUBWF	remain0,W
Div16x16_1	BTFSS	STATUS,C	;denom>remain?
	GOTO	Div16x16_2	;yes
;
	MOVF	denom0,W	;remain=remain-denom
	SUBWF	remain0,F	;remain0=remain0-denom0
	SKPB		;if borrow then cascade carry
	GOTO	Div16x16_nb1
;	
	DECF	remain1,F	; remain1--
;	
Div16x16_nb1	MOVF	denom1,W
	SUBWF	remain1,F	;remain1=remain1-denom1
	BSF	STATUS,C
Div16x16_2	RLF	result0,F
	RLF	result1,F
	DECFSZ	BCount,F
	GOTO	Div16x16_L1
;
	BCF	STATUS,RP1	;Bank 0
	RETURN 
;
	endif
	endif
;
	if oldCode
;==================================================================================
;Div16x16  16 bit devide
; RAM13D:RAM13C / RAM13F:RAM13E >> Param79:Param78
;
; Entry: RAM13D:RAM13C, RAM13F:RAM13E
; Exit: Param79:Param78
; RAM used:Param77, Param78, Param79, Param7A, 
;	RAM13C, RAM13D, RAM13E, RAM13F, RAM140 (verified 2/26/03)
; Calls:(0) none
;
Div16x16	CLRF	Param78
	CLRF	Param79
	CLRF	Param77
	CLRF	Param7A
;
	mBank2
	MOVF	RAM13F,W	;test for divide by zero
	BTFSS	STATUS,Z
	GOTO	Div16x16_1	;high byte not zero
	MOVF	RAM13E,W
	BTFSC	STATUS,Z
	GOTO	Div16x16_End	;both bytes are zero. n/0=0
;
Div16x16_1	MOVLW	0x10	;16 bits
	MOVWF	RAM140
Div16x16_L1	BCF	STATUS,C	;rotate high bit of 13D:13C
	RLF	RAM13C,F	;  into low bit on 7A:77
	RLF	RAM13D,F
	RLF	Param77,F
	RLF	Param7A,F
;
	MOVF	RAM13F,W
	SUBWF	Param7A,W	;W=7A-13F
	BTFSS	STATUS,Z	; skip if =
	GOTO	Div16x16_2
	MOVF	RAM13E,W
	SUBWF	Param77,W	;W=77-13E
Div16x16_2	BTFSS	STATUS,C	; skip if no barrow ( >= )
	GOTO	Div16x16_3	;7A:77<13F:13E
;if 7A:77>=13F:13E then 7A:77 = 7A:77 - 13F:13E
	MOVF	RAM13E,W
	SUBWF	Param77,F	;77=77-13E
	BTFSS	STATUS,C	; skip if no barrow ( >= )
	DECF	Param7A,F	
	MOVF	RAM13F,W
	SUBWF	Param7A,F	;7A=7A-13F
	BSF	STATUS,C
Div16x16_3	RLF	Param78,F
	RLF	Param79,F
	DECFSZ	RAM140,F
	GOTO	Div16x16_L1
;
Div16x16_End	BCF	STATUS,RP1	;Bank 0
	RETURN
;
	endif
;
	if oldCode
;==================================================================================
; 24 bit devide by d'10'
;
; Param7B:Param7A:Param79 = Param7B:Param7A:Param79 / d'10'
;
;          counter, out lsb, out msb, out hib, in lsb, in msb, in hib, scr lsb,scr msb,scr hib
; RAM used:RAM142, Param79, Param7A, Param7B, RAM13C, RAM13D, RAM13E, RAM13F, RAM140, RAM141
;	(verified 2/26/03)
;
Div24x0A	mBank2
	MOVF	Param79,W	;move to in lsb,msb,hib
	MOVWF	RAM13C
	MOVF	Param7A,W
	MOVWF	RAM13D
	MOVF	Param7B,W
	MOVWF	RAM13E
	
	CLRF	Param79	;out lsb
	CLRF	Param7A	;out msb
	CLRF	Param7B	;out hib
	CLRF	RAM13F	;scratch lsb
	CLRF	RAM140	;scratch msb
	CLRF	RAM141	;scratch hib
;
;
	MOVLW	0x18	;24 bits
	MOVWF	RAM142	; counter
Div24x0A_L1	BCF	STATUS,C	;rotate high bit of input
	RLF	RAM13C,F	;in lsb  into low bit of scratch
	RLF	RAM13D,F	;in msb
	RLF	RAM13E,F	;in hib
	RLF	RAM13F,F	;scratch lsb
	RLF	RAM140,F	;scratch msb
	RLF	RAM141,F	;scratch hib
;
	MOVLW	d'10'
	SUBWF	RAM13F,W	;scratch lsb W=(77)-10
	BTFSS	STATUS,C	; skip if no barrow ( >= )
	GOTO	Div24x0A_1	;(7A:77)<10
;if 7A:77>=10 then 7A:77 = 7A:77 - 10
	MOVLW	d'10'
	SUBWF	RAM13F,F	;scratch lsb 77=77-10
	BTFSS	STATUS,C	; skip if no barrow ( >= )
	DECF	RAM140,F	;scratch msb
	INCF	RAM140,W
	BTFSS	STATUS,Z
	DECF	RAM141,F	;scratch hib
;
	BSF	STATUS,C
Div24x0A_1	RLF	Param79,F	;out lsb
	RLF	Param7A,F	;out msb
	RLF	Param7B,F	;out hib
	DECFSZ	RAM142,F	;counter
	GOTO	Div24x0A_L1
;
	BCF	STATUS,RP1
	RETLW	00
;
	endif
;
	if oldCode
;============================================================================================
; Devide a 24 bit number by another 24 bit number and return a 24 bit number
;
; Entry:
;  numerator: Param76:Param75:Param74
;  denominator: Param73:Param72:Param71
; Exit:
;  result: Param76:Param75:Param74
;  remainder: remain2  remain1  remain0
; RAM used:Param71..Param76
; Calls: (1+0) Div32x32_E2
;
Div24x24	mBank2
	MOVFW	Param74
	MOVWF	shift0
	MOVFW	Param75
	MOVWF	shift1
	MOVFW	Param76
	MOVWF	shift2
	CLRF	shift3
;
	MOVFW	Param71
	MOVWF	denom0
	MOVFW	Param72
	MOVWF	denom1
	MOVFW	Param73
	MOVWF	denom2
	CLRF	denom3
	CALL	Div32x32_E2
	BSF	STATUS,RP1	;Bank 2
	MOVFW	result0
	MOVWF	Param74
	MOVFW	result1
	MOVWF	Param75
	MOVFW	result2
	MOVWF	Param76
	BCF	STATUS,RP1	;Bank 0
	RETURN
;
	endif
;
;
;
;
;
