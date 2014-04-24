	subtitle	"Dispatch.asm"
	page
;============================================================================================
;
;  FileName: Dispatch.asm
;  Date: 5/5/2008
;  File Version: 1.2.2
;  
;  Author: David M. Flynn
;  Company: Oxford V.U.E., Inc.
;
;============================================================================================
; Notes:
;        This file is the menu dispatcher for use with the buttons on the GP CPU board.
;
;  In a file at the end of segment 2 you must add the following custom routines:
;
;	RunOrService
;	SvsMdTtlXtras
;   and constants:
;	kLastSvsScrn
;	kLastNormScrn
;
; Indirect Service Modes:
;  	constant	UsesIndirectSvsMd=1
;  SvsModeSet	EQU	Mode_Metal	;0..7 value used to select mode set
;   must be in bank 3
; 
;  SvsMdTblPtr	;First svs md of each set, 8 word table (big engien, MSB first)
;  SvsMdTblLENum	;Last Entry of each set, (SvsMdTblPtr+(SvsModeSet*2)) + (SvsMdTblLENum+SvsModeSet)
;
;============================================================================================
; Revision History
;
; 1.2.2 4/5/2008	Added UseVUE8Btns LDI2 Btns
; 1.2.1 6/2/2007	Added conditional assm's (opt-in)
; 1.2   11/9/2004	Added indirect servive mode support.  UsesIndirectSvsMd, SvsModeSet
; 1.1.2 10/22/2004	Added range checking of ScrnNumber to StartSvsMode and StartRunMode
; 1.1.1 8/27/2004	Added UsesBootloader test for BL_SetCode and call SetUIPBit.
; 1.1   7/9/2004	Added IdleR2C7, IdleR2C9, etc.
; 1.0   3/17/2004	Copied from VUE-7.
;
;============================================================================================
;
; Name	(additional stack words required) Description
;============================================================================================
;
; ButtonDispatch	(0+) User Button Command Intrerpeter
;
; PrevSvsMode	() Previous Service mode screen
; NextSvsMode	() Next Service mode screen
; StartSvsMode	() Start service mode
;  StartSvsModeX
; PrevRunMode	() Previous Run mode screen
; NextRunMode	() Next Run mode screen
; StartRunMode	() Start Run mode
;  StartRunModeX
;
; lcd_gotoW2	(0+2) Goto the char W on the 3rd line
; IdleHexByte	(0+4) Display Byte at (W) in bank 2 or 3 w/ Disp_Hex_Byte_D10
; Idle2plDec	(0+4) Display Byte at (W) in bank 2 or 3 w/ Disp_decbyteW2pl_D10
; Idle3plDec	(0+4) Display Byte at (W) in bank 2 or 3 w/ Disp_decbyteW3pl_D10
; IdleR2C1	() lcd Goto Row 2 (3rd line) Col 1
; IdleR2C4	() lcd Goto Row 2 (3rd line) Col 4
; IdleR2C6	() lcd Goto Row 2 (3rd line) Col 6
; IdleR2C7	() lcd Goto Row 2 (3rd line) Col 7
; IdleR2C8	() lcd Goto Row 2 (3rd line) Col 8
; IdleR2C9	() lcd Goto Row 2 (3rd line) Col 9
; IdleR2C12	() lcd Goto Row 2 (3rd line) Col 12
; IdleR2C14	() lcd Goto Row 2 (3rd line) Col 14
; IdleR2C15	() lcd Goto Row 2 (3rd line) Col 15
; IdleR2C16	() lcd Goto Row 2 (3rd line) Col 16
; IdleR2C17	() lcd Goto Row 2 (3rd line) Col 18
; 
;
;============================================================================================
;
	ifndef	UsesIndirectSvsMd
	constant	UsesIndirectSvsMd=0
	endif
;
	ifndef	BtnDebounceTime
BtnDebounceTime	EQU	d'15'
	endif
	ifndef	CGIBtnDebounceTime
CGIBtnDebounceTime	EQU	d'128'
	endif
	ifndef	BtnDeBounceTimer
BtnDeBounceTimer	EQU	Timer1Lo
	endif
	ifndef	UseVUE8Btns
	constant	UseVUE8Btns=0
	endif
;
;============================================================================================
;User Button Command Intrerpeter
;
; Entry: evPtrAcid
; Exit: none
; RAM used: Param78,Param79,Param7A
; Calls:(0+) RunOrService
;
ButtonDispatch	
	if UseVUE8Btns
;
; Reorder the button bits from LDI2 to match LDI0 and OR them with LDI0 bits
;
	mBank3
	RRF	CurrentLDI_2,W
	MOVWF	Param78
	RRF	Param78,W
	XORLW	0x0F	; make btns pos logic
	ANDLW	0x0F	; kill extra bits
	MOVWF	Param78
	BTFSS	SvsModeSW
	BSF	Param78,4
	BTFSS	PrevSW
	BSF	Param78,5
	MOVF	CurrentLDI_0,W
	XORLW	0x3F	; make btns pos logic
	ANDLW	0x3F
	IORWF	Param78,F
;
	MOVLW	0x1F
	IORWF	CMD_LDO_2,F
;
	BTFSC	Param78,0	;SW703/Next
	BCF	NextLED
;
	BTFSC	Param78,1	;SW704/Sel1
	BCF	Sel1LED
;
	BTFSC	Param78,2	;SW705/Sel2
	BCF	Sel2LED
;
	BTFSC	Param78,3	;SW707/Sel3
	BCF	Sel3LED
;
	BTFSC	Param78,5	;SW702/Prev
	BCF	PrevLED
;
	else
;
	mBank3
	MOVF	CurrentLDI_0,W
	XORLW	0x3F	; make btns pos logic
	ANDLW	0x3F
	MOVWF	Param78
	endif
;
	mBank0
	MOVF	Param78,F
	SKPNZ
	GOTO	NoButton
; a button is down so reset the debounce timer
	mBank3
	MOVLW	BtnDebounceTime
	MOVWF	BtnDeBounceTimer
;
	if UsesBootloader
;Bootloader trigger, if the correct buttons are down then set the bit to trigger
; loading next time a reset occures.
	MOVLW	BL_SetCode	;BootLoader button combo
	SUBWF	Param78,W	;Button bits (positive logic)
	SKPZ
	GOTO	NoBootload
	mCall2To3	SetUIPBit
	MOVLW	StrResetNowPtr
	CALL	DispStrLine3
BD_Stop	GOTO	BD_Stop
NoBootload
	endif
;
	mBank0
;
	BTFSC	BtnDebounce
	RETURN
	BSF	BtnDebounce
;
; Convert button bits to a number 0..5
	CLRF	Param79
BD_L1	RRF	Param78,F
	BTFSC	STATUS,C
	GOTO	RunOrService
	INCF	Param79,F
	GOTO	BD_L1
;
NoButton	mBank3
	TSTF	BtnDeBounceTimer
	mBank0
	SKPZ
	GOTO	DoDebounceCGI
	BCF	BtnDebounce
	MOVF	CGI_BtnQueued,F
	SKPNZ
	RETURN
; a CGI button is down so reset the debounce timer
	mBank3
	MOVLW	CGIBtnDebounceTime
	MOVWF	BtnDeBounceTimer
	mBank0
;	
	DECF	CGI_BtnQueued,W
	CLRF	CGI_BtnQueued
	MOVWF	Param79
	GOTO	RunOrService
;
DoDebounceCGI	CLRF	CGI_BtnQueued
	RETURN
;
;===========================================================================================
; Previous Service mode screen
;
; Entry: ScrnNumber
; Exit: ScrnNumber-- wraped
; RAM used: Param78
; Calls:(1+2) SaveSvsScrnNumber, SRAM_Read_D10
;
PrevSvsMode	mBank0
	TSTF	ScrnNumber
	SKPNZ
	GOTO	PrevIsLast
	DECF	ScrnNumber,F
	GOTO	SaveSvsScrnNumber
;
PrevIsLast
	if UsesIndirectSvsMd
;
	CALL	GetLastScrnIndexVal
;
	else
;
	MOVLW	kLastSvsScrn
;
	endif
;
	MOVWF	ScrnNumber
	GOTO	SaveSvsScrnNumber
;
	if UsesIndirectSvsMd
GetLastScrnIndexVal	mBank3
	MOVLW	high evDataROM
	MOVWF	SRAM_Addr2
	MOVLW	low evDataROM
	ADDLW	high SvsMdTblLENum
	MOVWF	SRAM_Addr1
	MOVF	SvsModeSet,W
	ADDLW	low SvsMdTblLENum
	MOVWF	SRAM_Addr0
	ADDCF	SRAM_Addr1,F
	GOTO	SRAM_Read_D10
;
GetSvsMdFromTable	mBank3
	MOVLW	high evDataROM	;0x01
	MOVWF	SRAM_Addr2
	MOVLW	low evDataROM	;0x0B
	ADDLW	high SvsMdTblPtr	;0x02
	MOVWF	SRAM_Addr1
	CLRC
	RLF	SvsModeSet,W	;SvsModeSet*2
	ADDLW	low SvsMdTblPtr	;0x6E
	MOVWF	SRAM_Addr0
	ADDCF	SRAM_Addr1,F
;
	CALL	SRAM_ReadPI_D10	;Ptr MSB
	MOVWF	Param78	;0x01
	MOVF	ScrnNumber,W
	MOVWF	Param79
	CALL	SRAM_Read_D10	;Ptr LSB
	mBank3
	CLRF	SRAM_Addr1
	ADDWF	Param79,W
	MOVWF	SRAM_Addr0
	ADDCF	Param78,F
	MOVF	Param78,W
	ADDLW	low evDataROM
	MOVWF	SRAM_Addr1
	GOTO	SRAM_Read_D10
;	
	endif
;
;===========================================================================================
; Next Service mode screen
;
; Entry: ScrnNumber
; Exit: ScrnNumber++ wraped
; RAM used:
; Calls:(1+) StartSvsModeX,WriteEEP79W_D10
;
NextSvsMode	
	if UsesIndirectSvsMd
;
	CALL	GetLastScrnIndexVal
;
	else
;
	mBank0
	MOVLW	kLastSvsScrn
;
	endif
;
	SUBWF	ScrnNumber,W	;Current scrn - last
	MOVLW	0xFF
	SKPB		;skip if index<last
	MOVWF	ScrnNumber	;-1
	INCF	ScrnNumber,F	;add 1
;
SaveSvsScrnNumber	MOVLW	eSvsScrnNumber
	MOVWF	Param79
	MOVF	ScrnNumber,W
	CALL	WriteEEP79W_D10	;1+0
	GOTO	StartSvsModeX
;	
;===========================================================================================
; Start service mode
;
; Entry: ScrnNumber
; Exit: ScrnNumber++ wraped
; RAM used: Param7C
; Calls:(1+) StartSvsModeX,ReadEEwW_D10,DispStrLine0,Disp_decbyteW2pl_D10,SRAM_ReadDR_D10,
;	DispStrLine1,SvsMdTtlXtras,DispStrLine2,DispStrLine3,PrintString_D10
;
StartSvsMode	MOVLW	eSvsScrnNumber
	CALL	ReadEEwW_D10	;1+0
	MOVWF	ScrnNumber
;
	if UsesIndirectSvsMd
	CALL	GetLastScrnIndexVal
	else
	MOVLW	kLastSvsScrn
	endif
;
	MOVWF	Param78
	INCF	Param78,W
	SUBWF	ScrnNumber,W	;Current scrn - last+1
	SKPB		;skip if index < last+1
	CLRF	ScrnNumber
;
StartSvsModeX	BSF	ServiceMode
	mLED5_ON		; Service LED on
;
	MOVLW	SvsModeStrPtr	;'Service Mode '
	CALL	DispStrLine0	;Display the SvsMode string
;
	if UsesIndirectSvsMd
	CALL	GetSvsMdFromTable
	else
	MOVFW	ScrnNumber
	endif
;
	MOVWF	Param7C	;Param7C=Service Mode Number
	CALL	Disp_decbyteW2pl_D10
;
	MOVF	Param7C,W
	ADDLW	SvsModeTitles	;offset to title's str ptr
	CALL	SRAM_ReadDR_D10	;get str ptr
	IORLW	0x00
	SKPZ		;was the ptr zero
	CALL	DispStrLine1	; No, display it
;
	CALL	SvsMdTtlXtras
;
	MOVF	Param7C,W
	ADDLW	SvsModeInfoLines	;offset to info's str ptr
	CALL	SRAM_ReadDR_D10	;get str ptr
	IORLW	0x00
	SKPZ		;was the ptr zero
	CALL	DispStrLine2
;
	MOVLW	Str_NextPtr
	CALL	DispStrLine3
	MOVF	Param7C,W
	ADDLW	SvsModeCmdLines
	CALL	SRAM_ReadDR_D10	;get str ptr
	SKPNZ
	GOTO	SSM_NextOnly
	CALL	PrintString_D10
SSM_NextOnly	RETURN
;
;===========================================================================================
; Previous Run mode screen
;
; Entry: ScrnNumber
; Exit: ScrnNumber-- wraped
; RAM used:
; Calls:(0+) SaveRunScrnNumber
;
PrevRunMode	TSTF	ScrnNumber
	SKPNZ
	GOTO	PrevIsLastR
	DECF	ScrnNumber,F
	GOTO	SaveRunScrnNumber
PrevIsLastR	MOVLW	kLastNormScrn
	MOVWF	ScrnNumber
	GOTO	SaveRunScrnNumber
;
;===========================================================================================
; Next Run mode screen
;
; Entry: ScrnNumber
; Exit: ScrnNumber++ wraped
; RAM used:
; Calls:(1+) StartRunModeX,WriteEEP79W_D10
;
NextRunMode	mBank0
	MOVF	ScrnNumber,W
	SUBLW	kLastNormScrn
	MOVLW	0xFF
	SKPNZ
	MOVWF	ScrnNumber	;-1
	INCF	ScrnNumber,F	;add 1
SaveRunScrnNumber	MOVLW	eScrnNumber
	MOVWF	Param79
	MOVF	ScrnNumber,W
	CALL	WriteEEP79W_D10
	GOTO	StartRunModeX
;	
;============================================================================================
; Start Run mode
;
; Entry: none
; Exit: ScrnNumber=0, ServiceMode=False
; RAM used:
; Calls:(1+) ReadEEwW_D10,DispStrLine0,DispIP,lcd_GotoLineW_D10,Disp_Hex_Byte_D10
;
StartRunMode	MOVLW	eScrnNumber
	CALL	ReadEEwW_D10
	MOVWF	ScrnNumber
	SUBLW	kLastNormScrn	;kLastNormScrn-ScrnNumber
	SKPNB
	CLRF	ScrnNumber
StartRunModeX	BCF	ServiceMode
	mLED5_OFF		; Service LED OFF
	MOVLW	SIGNONStrPtr	;'Baume Limiter v1.0d1'
	CALL	DispStrLine0
	GOTO	RunMdTtlXtras
;
;===========================================================================================
; Goto the char W on the 3rd line
;
; Entry: Char Position in W (0..19)
; Exit: none
; RAM Used:Param78, Param79 (Verified 2/1/04)
; Calls:(0+2) lcd_gotoxy_D10
;
lcd_gotoW2	MOVWF	Param79
	MOVLW	d'2'	;3rd line
	MOVWF	Param78
	MOVF	Param79,W
	GOTO	lcd_gotoxy_D10
;
;===========================================================================================
; Display the hex byte at (W) in bank 2 or 3
;
; Entry: W = address of byte to display
; Exit: none
; RAM Used:Param76, Param79, FSR
; Calls:(0+4) Disp_Hex_Byte_D10
;
IdleHexByte	MOVWF	FSR
	BSF	_IRP
	MOVF	INDF,W
	GOTO	Disp_Hex_Byte_D10
;
;===========================================================================================
; Display the Decimal byte at (W) in bank 2 or 3
;
; Entry: W = address of byte to display
; Exit: none
; RAM Used: Param71:0, Param77, Param78, Param79, FSR
; Calls:(0+4) Disp_decbyteW2pl_D10
;
Idle2plDec	MOVWF	FSR
	BSF	_IRP
	MOVF	INDF,W
Disp_decbyteW2pl_D10	mCall2To0	Disp_decbyteW2pl
	RETURN
;
;===========================================================================================
; Display the Decimal byte at (W) in bank 2 or 3
;
; Entry: W = address of byte to display
; Exit: none
; RAM Used: Param71:0, Param77, Param78, Param79, FSR
; Calls:(0+4) Disp_decbyteW3pl_D10
;
Idle3plDec	MOVWF	FSR
	BSF	_IRP
	MOVF	INDF,W
Disp_decbyteW3pl_D10	mCall2To0	Disp_decbyteW3pl
	RETURN
;
;===========================================================================================
	ifndef UsesIdleR2C1
	constant	UsesIdleR2C1=0
	endif
	if UsesIdleR2C1
;===========================================================================================
; lcd Goto Row 2 (3rd line) Col 1
;
; Entry: none
; Exit: none
; RAM Used: Param78, Param79 (Verified 2/1/04)
; Calls:(0+2) lcd_gotoW2
;
IdleR2C1	MOVLW	d'1'
	GOTO	lcd_gotoW2
;
	endif
;===========================================================================================
; lcd Goto Row 2 (3rd line) Col 4
;
; Entry: none
; Exit: none
; RAM Used: Param78, Param79 (Verified 2/1/04)
; Calls:(0+2) lcd_gotoW2
;
IdleR2C4	MOVLW	d'4'
	GOTO	lcd_gotoW2
;
;===========================================================================================
	ifndef UsesIdleR2C6
	constant	UsesIdleR2C6=0
	endif
	if UsesIdleR2C6
;===========================================================================================
; lcd Goto Row 2 (3rd line) Col 6
;
; Entry: none
; Exit: none
; RAM Used: Param78, Param79 (Verified 2/1/04)
; Calls:(0+2) lcd_gotoW2
;
IdleR2C6	MOVLW	d'6'
	GOTO	lcd_gotoW2
;
	endif
;===========================================================================================
	ifndef UsesIdleR2C7
	constant	UsesIdleR2C7=0
	endif
	if UsesIdleR2C7
;===========================================================================================
; lcd Goto Row 2 (3rd line) Col 7
;
; Entry: none
; Exit: none
; RAM Used: Param78, Param79 (Verified 2/1/04)
; Calls:(0+2) lcd_gotoW2
;
IdleR2C7	MOVLW	d'7'
	GOTO	lcd_gotoW2
;
	endif
;===========================================================================================
	ifndef UsesIdleR2C8
	constant	UsesIdleR2C8=0
	endif
	if UsesIdleR2C8
;===========================================================================================
; lcd Goto Row 2 (3rd line) Col 8
;
; Entry: none
; Exit: none
; RAM Used: Param78, Param79 (Verified 2/1/04)
; Calls:(0+2) lcd_gotoW2
;
IdleR2C8	MOVLW	d'8'
	GOTO	lcd_gotoW2
;
	endif
;===========================================================================================
	ifndef UsesIdleR2C9
	constant	UsesIdleR2C9=0
	endif
	if UsesIdleR2C9
;===========================================================================================
; lcd Goto Row 2 (3rd line) Col 9
;
; Entry: none
; Exit: none
; RAM Used: Param78, Param79 (Verified 2/1/04)
; Calls:(0+2) lcd_gotoW2
;
IdleR2C9	MOVLW	d'9'
	GOTO	lcd_gotoW2
;
	endif
;===========================================================================================
; lcd Goto Row 2 (3rd line) Col 12
;
; Entry: none
; Exit: none
; RAM Used: Param78, Param79 (Verified 2/1/04)
; Calls:(0+2) lcd_gotoW2
;
IdleR2C12	MOVLW	d'12'
	GOTO	lcd_gotoW2
;
;===========================================================================================
	ifndef UsesIdleR2C14
	constant	UsesIdleR2C14=0
	endif
	if UsesIdleR2C14
;===========================================================================================
; lcd Goto Row 2 (3rd line) Col 14
;
; Entry: none
; Exit: none
; RAM Used: Param78, Param79 (Verified 2/1/04)
; Calls:(0+2) lcd_gotoW2
;
IdleR2C14	MOVLW	d'14'
	GOTO	lcd_gotoW2
;
	endif
;===========================================================================================
	ifndef UsesIdleR2C15
	constant	UsesIdleR2C15=0
	endif
	if UsesIdleR2C15
;===========================================================================================
; lcd Goto Row 2 (3rd line) Col 15
;
; Entry: none
; Exit: none
; RAM Used: Param78, Param79 (Verified 2/1/04)
; Calls:(0+2) lcd_gotoW2
;
IdleR2C15	MOVLW	d'15'
	GOTO	lcd_gotoW2
;
	endif
;===========================================================================================
; lcd Goto Row 2 (3rd line) Col 16
;
; Entry: none
; Exit: none
; RAM Used: Param78, Param79 (Verified 2/1/04)
; Calls:(0+2) lcd_gotoW2
;
IdleR2C16	MOVLW	d'16'
	GOTO	lcd_gotoW2
;
;===========================================================================================
	ifndef UsesIdleR2C17
	constant	UsesIdleR2C17=0
	endif
	if UsesIdleR2C17
;===========================================================================================
; lcd Goto Row 2 (3rd line) Col 17
;
; Entry: none
; Exit: none
; RAM Used: Param78, Param79 (Verified 2/1/04)
; Calls:(0+2) lcd_gotoW2
;
IdleR2C17	MOVLW	d'17'
	GOTO	lcd_gotoW2
;
	endif
;
;
;
