	subtitle	"FP32Helpers.asm"
	page
;===========================================================================================
;
;  FileName: FP32Helpers.asm
;  Date: 9/2/03
;  File Version: 1.0.1
;  Requred files: FP32.asm, LowStuff.asm
;  
;  Author: David M. Flynn
;  Company: Oxford V.U.E., Inc.
;
;============================================================================================
; Notes:
;
;  This file is all general perpose routines.
;  This module must be included in ****segment 3*****.
;  This also forces FP32.asm to segment 3.
;  To use in another segment modify _Dxx calls.
;
;  Routines called outside this file:
;   SRAM_ReadDR_D18
;   SRAM_ReadPI_D18
;   FP32.asm
;
;============================================================================================
; Revision History
;
; 1.0.1  9/2/03	Added SRAM_To_Aarg.
; 1.0    8/31/03	First code.
;
;============================================================================================
;============================================================================================
;
;Routines
; Name	(additional stack words required) Description
;============================================================================================
;
;MemMove	(0)    Move bytes from RAM to somewhere else in RAM
;SRAM_To_Aarg	(1+2)  Copy next 4 bytes from (SRAM_Addr) to AARG
;CnvtInt16ToFP32	(0)    Make an Int16 into a FP32
;SubBARGformDR	(1+1)  Subtract BARG from DR
;DivDRbyBARG	(1+1)  Divide value from Data Ram by BARG
;DivAargByDR	(1+1)  Divide AARG by value from Data Ram
;MultAargByDR	(1+1)  Multiply by value from Data Ram
;MovAargToRam	(0)    Move AARG to RAM (bank 0 or 1 RAM)
;MovRamToBarg	(0)    Move FP32 in bank 0 or 1 to BARG
;MovRamToAarg	(0)    Move FP32 in bank 0 or 1 to AARG
;MovAARG_BARG	(0)    Move the Aarg to the Barg
;
;============================================================================================
; Move bytes from RAM to somewhere else in RAM
;
; Entry: Param79=Bytes to move, Param7A=destination, Param7B=Source, SrcIRP, DestIRP
; Exit: none
; RAM used: Param78, Param79, Param7A, Param7B, FSR (verified 6/22/03)
; Calls:(0) none
;
MemMove	mBank0
MemMove_L1	BTFSC	SrcIRP
	BSF	_IRP
	BTFSS	SrcIRP
	BCF	_IRP
	MOVF	Param7B,W
	MOVWF	FSR
	MOVF	INDF,W
	MOVWF	Param78
	MOVF	Param7A,W
	MOVWF	FSR
	BTFSC	DestIRP
	BSF	_IRP
	BTFSS	DestIRP
	BCF	_IRP
	MOVF	Param78,W
	MOVWF	INDF
	INCF	Param7A,F
	INCF	Param7B,F
	DECFSZ	Param79,F
	GOTO	MemMove_L1
	RETURN
;
;===========================================================================================
; Copy next 4 bytes from (SRAM_Addr) to AARG
;
; Entry: SRAM_Addr
; Exit: AARG
; RAM used: Param79
; Calls: (1+2) SRAM_ReadPI_D18
;
SRAM_To_Aarg	MOVLW	0x04
	MOVWF	Param79
	MOVLW	low AEXP
	MOVWF	FSR
	BSF	_IRP
SRAM_To_Aarg_L1	CALL	SRAM_ReadPI_D18
	MOVWF	INDF
	INCF	FSR,F
	DECFSZ	Param79,F
	GOTO	SRAM_To_Aarg_L1
	RETURN
;
;============================================================================================
; Make an Int16 into a FP32
;
; Entry: W = ptr to bank 0 or 1
; Exit: FP32 in AEXP,AARG
; RAM used: FSR
; Calls:(0) FLO32
;
CnvtInt16ToFP32	MOVWF	FSR
	BCF	_IRP
	mBank2
	MOVF	INDF,W
	MOVWF	AARG+B2
	INCF	FSR,F
	MOVF	INDF,W
	MOVWF	AARG+B1
	CLRF	AARG+B0
	GOTO	FLO32
;
;============================================================================================
; Subtract BARG from DR
; AARG <-- DR - BARG
;
; Entry: W = offset into Data Ram, data in BARG
; Exit: FP32 in AEXP,AARG
; RAM used: Param78, Param79, Param7A, FSR
; Calls:(1+1) SRAM_ReadDR_D18, SRAM_ReadPI_D18, FPS32
;
SubBARGformDR	CLRF	Param7A	;Clear all option bits
	BSF	Param7A,1	;AARG <-- DR
	BSF	Param7A,2	;Subtract
	GOTO	DivAargByDR_E2
	
;============================================================================================
; Divide value from Data Ram by BARG
;
; Entry: W = offset into Data Ram, Denominator in BARG
; Exit: FP32 in AEXP,AARG
; RAM used: Param78, Param79, Param7A, FSR
; Calls:(1+1) SRAM_ReadDR_D18, SRAM_ReadPI_D18, FPD32
;
DivDRbyBARG	CLRF	Param7A	;Clear all option bits
	BSF	Param7A,1	;AARG <-- DR
	GOTO	DivAargByDR_E2
;
;============================================================================================
; Divide AARG by value from Data Ram
;
; Entry: W = offset into Data Ram, Numerator in AARG
; Exit: FP32 in AEXP,AARG
; RAM used: Param78, Param79, Param7A, FSR
; Calls:(1+1) SRAM_ReadDR_D18, SRAM_ReadPI_D18, FPS32, FPA32, FPD32, FPM32
;
DivAargByDR	CLRF	Param7A,0	;Clear all option bits
;
; Param7A flag bits	Clr	Set
;  0  Multiply	Default	Multiply
;  1  Dest for DR	BARG	AARG
;  2  Subtract	Default	Subtract
;  3  Add	Default	Add
;
DivAargByDR_E2	MOVWF	Param78
	BTFSS	Param7A,1	;setup dest for DR
	MOVLW	low BEXP
	BTFSC	Param7A,1
	MOVLW	low AEXP
	MOVWF	FSR
	BSF	_IRP
	MOVLW	0x04
	MOVWF	Param79
	MOVF	Param78,W
	CALL	SRAM_ReadDR_D18
DivAargByDR_1	MOVWF	INDF
	INCF	FSR,F
	DECFSZ	Param79,F	;Last byte?
	GOTO	DivAargByDR_2	; No, get another.
;
	BTFSC	Param7A,2	;Subtract?
	GOTO	FPS32	; Yes
	BTFSC	Param7A,0	;Multiply?
	GOTO	FPM32	; Yes, Multiply
	BTFSC	Param7A,0	;Add?
	GOTO	FPA32	; Yes, Add
	GOTO	FPD32	;Default to Divide
;
DivAargByDR_2	CALL	SRAM_ReadPI_D18
	GOTO	DivAargByDR_1
;
;============================================================================================
; Multiply by value from Data Ram
;
; Entry: W = offset into Data Ram, Mult in AARG
; Exit: FP32 in AEXP,AARG
; RAM used: Param78, Param79, Param7A, FSR
; Calls:(1+1) SRAM_ReadDR_D18, SRAM_ReadPI_D18, FPM32
;
MultAargByDR	CLRF	Param7A	;Clear all option bits
	BSF	Param7A,0	;Multiply
	GOTO	DivAargByDR_E2
;
;============================================================================================
; Move AARG to RAM (bank 0 or 1 RAM)
;
; Entry: W = ptr to bank 0 or 1 RAM
; Exit: none
; RAM used: Param78, Param79, Param7A, Param7B, FSR (verified 8/30/03)
; Calls:(0) MemMove
;
MovAargToRam	MOVWF	Param7A	;dest
	BCF	DestIRP
	MOVLW	low AEXP
	MOVWF	Param7B	;src
	BSF	SrcIRP
Move4Bytes	MOVLW	0x04
	MOVWF	Param79	;count
	GOTO	MemMove
;
;============================================================================================
; Move FP32 in bank 0 or 1 to BARG
;
; Entry: W ptr to RAM
; Exit: BARG
; RAM used: Param78, Param79, Param7A, Param7B, FSR (verified 8/30/03)
; Calls:(0) MemMove
;
MovRamToBarg	MOVWF	Param7B	;src
	BCF	SrcIRP
MoveToBarg	MOVLW	low BEXP
MoveToHiRAM	MOVWF	Param7A	;dest
	BSF	DestIRP
	GOTO	Move4Bytes
;
;============================================================================================
; Move FP32 in bank 0 or 1 to AARG
;
; Entry: W ptr to RAM
; Exit: AARG
; RAM used: Param78, Param79, Param7A, Param7B, FSR (verified 8/31/03)
; Calls:(0) MemMove
;
MovRamToAarg	MOVWF	Param7B	;src
	BCF	SrcIRP
MoveToAarg	MOVLW	low AEXP
	GOTO	MoveToHiRAM
;
;============================================================================================
; Move the Aarg to the Barg
;
; Action: BARG <-- AARG
; Entry:none
; Exit:none
; RAM used: Param78, Param79, Param7A, Param7B, FSR (verified 8/30/03)
; Calls:(0) MemMove
;
MovAARG_BARG	MOVLW	low AEXP
	MOVWF	Param7B	;src
	BSF	SrcIRP
	GOTO	MoveToBarg
;	
;
;
;
