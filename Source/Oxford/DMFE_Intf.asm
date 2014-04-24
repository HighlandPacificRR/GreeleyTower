	subtitle	"DMFE_Intf.asm"
	page
;*******************************************************************************
;
;    Filename: DMFE_Intf.asm
;    Date:11/5/2005
;    File Revision:1.0.1
;
;    Author:David M. Flynn
;    Company:Oxford V.U.E., Inc.
; 
;**********************************************************************
;
; Notes:
;  Caution the routines called within this file return Bank3 selected.
;
;
;**********************************************************************
; Revision History
;
; 1.0.1  11/5/2005	Updated some constants
; 1.0    2/27/2005     Fixed timing and testing, first working version.
; 1.0b1  2/15/2005	Copied from HPRR Communication.ASM
;
;**********************************************************************
; Routine	Description
;=======================================================================
; DMFE_Inft_Init	Initialize
;
; OutputC	(CurSM),Y -> OBit, (CurSM),Y+1 -> high nibble=OSlot, low nibble=OBoard (3/3)
; OutputB	CurBlk -> OBit, CurBlk+1 -> high nibble=OSlot, low nibble=OBoard (3/3)
; OutputA	(CurBlk),Y -> OBit, (CurBlk),Y+1 -> high nibble=OSlot, low nibble=OBoard (3/3)
; Output	OBit=0..7F, OBoard=0..7, OSlot=0..2 (3/3)
;
; InputC	(CurSM),Y -> IBit, (CurSM),Y+1 -> high nibble=ISlot, low nibble=IBoard (3/3)
; InputB	CurBlk -> IBit, CurBlk+1 -> high nibble=ISlot, low nibble=IBoard (3/3)
; InputA	(CurBlk),Y -> IBit, (CurBlk),Y+1 -> high nibble=ISlot, low nibble=IBoard (3/3)
; Input	IBit=0..7F, IBoard=0..7, ISlot=0..2 (3/3)
;
;=======================================================================
;
;=================================================================================================
; Hardware IO routines
;
;Old Hardware (6522):
;  PB0..PB6 = Bit# 0..127 output only
;  PB7 = Data I/O
;  PA0..PA2 = Board# 0..7 output only
;  PA3 = Slot 0 Device select Active low output only
;  PA4 = Slot 1 Device select Active low output only
;  PA5 = Slot 2 Device select Active low output only
;  PA7 = R/W*  output only
;
; New Hardware (The Brain PIC16F877)
;   LDO_8..LDO_14 = Bit# 0..127 output only (J1-25..J1-31)
;   RA0 = Data I/O (J2-1)
;   RC0..RC2 = Board# 0..7 output only (J2-17..J2-19)
;   SEL12 = Slot 0 Device select Active low output only (J1-33)
;   SEL13 = Slot 1 Device select Active low output only (J1-34)
;   SEL14 = Slot 2 Device select Active low output only (J1-35)
;   LDO_15 = R/W* output only (J1-32)
;
; DMFE 16 pin connector
; 1  D0 (J1-25) LDO1-0		16  A0 (J2-17) RC0
; 2  D1 (J1-26) LDO1-1		15  A1 (J2-18) RC1
; 3  D2 (J1-27) LDO1-2		14  A2 (J2-19) RC2
; 4  D3 (J1-28) LDO1-3		13  R/W* (J1-32) LDO1-7
; 5  D4 (J1-29) LDO1-4		12  DEV* SEL12* or SEL13* or SEL14*
; 6  D5 (J1-30) LDO1-5		11  Ground
; 7  D6 (J1-31) LDO1-6		10  Ground
; 8  D7 (J2-1) RA0		9   Ground
;
Slot_0_DEV_Sel	EQU	0x00
Slot_1_DEV_Sel	EQU	0x01
Slot_2_DEV_Sel	EQU	0x02
LDO_4_Select	EQU	0x03	;D0..D6
LDO_5_Select	EQU	0x04	;A0..A2
;
; New Interface Board (Double Buffered)
;  Port E bits 0..2 + Select12
;   Slot 0 DEV*
;   Slot 1 DEV*
;   Slot 2 DEV*
;   LDO 4
;   LDO 5
;
; DMFE 16 pin connector
; 1  D0  LDO4-0		16  A0 LDO5-0
; 2  D1  LDO4-1		15  A1 LDO5-1
; 3  D2  LDO4-2		14  A2 LDO5-2
; 4  D3  LDO4-3		13  R/W* LDO4-7
; 5  D4  LDO4-4		12  DEV* SEL16* or SEL17* or SEL18*
; 6  D5  LDO4-5		11  Ground
; 7  D6  LDO1-6		10  Ground
; 8  D7  Read RA1 / Write RA0 	9   Ground
;
;=================================================================================================
; Initialize
;
DMFE_Inft_Init	mBank1
	BCF	TRISA,0	;Data Out
	BSF	TRISA,1	;Data In
	BSF	TRISA,2	;Input J6-4 (Active low)
	BSF	TRISA,3	;Remote Reset J6-3 (Active low)
	CLRF	TRISE	; all out PSP off
	BCF	_RP0	; Bank 0
	RETURN
;
;
	if UsesInOutC
;=================================================================================================
;
;Entry: (CurSM),Y -> OBit
;       (CurSM),Y+1 -> high nibble=OSlot, low nibble=OBoard
;	OActive=00 or 80 (MSB only)
;Exit: 
;
OutputC	CLRF	SRAM_Addr2
	MOVF	CurSM+1,W
	MOVWF	SRAM_Addr1
	MOVF	CurSM,W
	GOTO	OutputA_E2
;
	endif
;============================================================
;Entry: CurBlk -> OBit
;       CurBlk+1 -> high nibble=OSlot, low nibble=OBoard
;	OActive=00 or 80 (MSB only)
;
OutputB	MOVF	CurBlk,W
	MOVWF	OBit
	MOVF	CurBlk+1,W
	GOTO	OutputA1
;
;=================================================================================================
;Entry: (CurBlk),Y -> OBit
;       (CurBlk),Y+1 -> high nibble=OSlot, low nibble=OBoard
;	OActive=00 or 80 (MSB only)
;Exit: 
;
OutputA	CLRF	SRAM_Addr2
	MOVF	CurBlk+1,W
	MOVWF	SRAM_Addr1
	MOVF	CurBlk,W
OutputA_E2	ADDWF	YReg,W
	MOVWF	SRAM_Addr0
	ADDCF	SRAM_Addr1,F
	mCall3To0	SRAM_ReadPI
	mBank3
	MOVWF	OBit
	mCall3To0	SRAM_ReadPI
	mBank3
OutputA1	MOVWF	Param78
	ANDLW	0x07
	MOVWF	OBoard
	SWAPF	Param78,W
	ANDLW	0x07
	MOVWF	OSlot
;
; fall through to Output
;
;=====================================================================================
;OUPUT BIT
;Entry: OBit=0..7F, OBoard=0..7, OSlot=0..2
;Exit: Bank3 is selected
;	OActive=00 or 80 (MSB only)
Output	mBank1
	CLRF	TRISD	;output
	mBank3
	RLF	OActive,W
	mBank0
	BTFSS	_C	;Data
	BCF	PORTA,0
	BTFSC	_C
	BSF	PORTA,0
;
	mBank3
	MOVF	OBit,W	;Address 0..127
	ANDLW	0x7F	; R/W* = W*
	mBank0
	MOVWF	PORTD
	MOVLW	LDO_4_Select
	CALL	WriteSel12Data
;
	MOVF	OBoard,W
	ANDLW	0x07
	mBank0
	MOVWF	PORTD
	MOVLW	LDO_5_Select
	CALL	WriteSel12Data
;
	MOVF	OSlot,W
	ANDLW	0x03	;limit to 0..2
	mBank0
;
; fall through to WriteSel12Data
;
;====================================================================================
; write data at port D to LDO4 or LDO5, or pulse Select16..18 (DEV0..DEV2)
;
; Entry: W=3 bit Address for port E, bank 0
; Exit: bank 3
;
WriteSel12Data	MOVWF	PORTE
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	Select12
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	NOP
	NOP
	NOP
	NOP
	NOP
	BSF	PORTB,SelectEnable
	mBank3
	RETURN
;
	if UsesInOutC
;===============================================================================
;Entry: (CurSM),Y -> IBit
;       (CurSM),Y+1 -> high nibble=ISlot, low nibble=IBoard
;Exit: IActive=00 or 80 (MSB only)
;
InputC	CLRF	SRAM_Addr2
	MOVF	CurSM+1,W
	MOVWF	SRAM_Addr1
	MOVF	CurSM,W
	GOTO	InputA_E2
;
	endif
;==============================================================================
;Entry: CurBlk = IBit
;       CurBlk+1 = high nibble=ISlot, low nibble=IBoard
;Exit: IActive=00 or 80 (MSB only)
InputB	MOVFW	CurBlk
	MOVWF	IBit
	MOVFW	CurBlk+1
	GOTO	InputA2
;
;===============================================================================
;Entry: (CurBlk),Y -> IBit
;       (CurBlk),Y+1 -> high nibble=ISlot, low nibble=IBoard
;Exit: IActive=00 or 80 (MSB only)
;
InputA	CLRF	SRAM_Addr2
	MOVF	CurBlk+1,W
	MOVWF	SRAM_Addr1
	MOVF	CurBlk,W
InputA_E2	ADDWF	YReg,W
	MOVWF	SRAM_Addr0
	ADDCF	SRAM_Addr1,F
	mCall3To0	SRAM_ReadPI
	mBank3
	MOVWF	Param78
	SUBLW	0xFE
	SKPZ
	GOTO	InputA1
	CLRF	IActive
	RETURN
;
InputA1	MOVF	Param78,W
	MOVWF	IBit
	mCall3To0	SRAM_Read
	mBank3
InputA2	MOVWF	Param78
	ANDLW	0x07
	MOVWF	IBoard
	SWAPF	Param78,W
	ANDLW	0x03
	MOVWF	ISlot
;
; fall through to Input
;
;===============================================================================
; Get input bit for ISlot,IBoard,IBit into IActive:7
;
; Entry: IBit=0..7F, IBoard=0..7, ISlot=0..2
; Exit: IActive=00 or 80 (MSB only) Bank3 is selected
;
Input	mBank1
	CLRF	TRISD	;output
; set IBit and R/W*
	mBank3
	MOVF	IBit,W	;Address 0..127
	ANDLW	0x7F	; R/W* = W*
	mBank0
	MOVWF	PORTD
	MOVLW	LDO_4_Select	;LDO4
	CALL	WriteSel12Data
; Set IBoard
	MOVF	IBoard,W
	ANDLW	0x07
	mBank0
	MOVWF	PORTD
	MOVLW	LDO_5_Select	;LDO5
	CALL	WriteSel12Data
; Write Address
	MOVF	ISlot,W
	ANDLW	0x03	;limit to 0..2
	mBank0
	CALL	WriteSel12Data
; SET R/W* to Read
	mBank0
	BSF	PORTD,7	; R/W* = R
	MOVLW	LDO_4_Select	;LDO4
	CALL	WriteSel12Data
; Read Data	
	MOVF	ISlot,W
	ANDLW	0x03	;limit to 0..2
	mBank0
	MOVWF	PORTE
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	Select12
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	NOP
	NOP
	NOP
	NOP
	MOVF	PORTA,W
	BSF	PORTB,SelectEnable
	mBank3
	CLRF	IActive
	ANDLW	0x02
	SKPZ
	BSF	IActive,7
	RETURN
;
;
;
;
;
;
