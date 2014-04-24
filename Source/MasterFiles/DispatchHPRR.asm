	subtitle	"DispatchComIO.asm"
	page
;============================================================================================
;
;  FileName: DispatchComIO.asm
;  Date: 6/2/07
;  File Version: 1.1
;  
;  Author: David M. Flynn
;  Company: HPRR
;  Project: TCC Communications Computer
;
;============================================================================================
; Notes:
;        This file is the menu dispatcher for use with the buttons on the GP CPU board.
;
;
;============================================================================================
; Revision History
;
; 1.1   6/2/2007	Added service mode 11
; 1.0   9/5/2004	First code
;
;============================================================================================
;
; Name	(additional stack words required) Description
;============================================================================================
; 
; RunMdTtlXtras	() Part of starting a Run Mode, Displays the IP numbers, etc.
; 
; NormalMd03_SW5	() Run Mode Error Screen Clear Hard Error
; 
; SvsMd00Idle	() Idler routine for service mode 00 'Switch Machine''Num=     Value='
; SvsMd01Idle	() Idler routine for service mode 01 'High Switch Machine''Num=     Value='
; SvsMd02Idle	() Idler routine for service mode 02 'Block Data''Num=     Value='
; SvsMd03Idle	() Idler routine for service mode 03 'MAC Address'
; SvsMd04Idle	() Idler routine for service mode 04 'IP Address'
; SvsMd05Idle	() Idler routine for service mode 05 'Show Inputs'
; SvsMd08Idle	() Idler routine for service mode 08 'Test Scanner''Slot/Board='
; SvsMd09Idle	() Idler routine for service mode 09 'Test Scanner'
; SvsMd10Idle	() Idler routine for service mode 10 'Block Data Cab#'
; SvsMd11Idle	() Idler routine for service mode 11 'Block Module Tester'
;
; SvsMd00Sw3	() 'Switch Machine''Num=     Value=' Down
; SvsMd00Sw4	() 'Switch Machine''Num=     Value=' Up
; SvsMd00Sw5	() 'Switch Machine''Num=     Value=' Change
;
; SvsMd01Sw3	() 'High Switch Machine''Num=     Value=' Down
; SvsMd01Sw4	() 'High Switch Machine''Num=     Value=' Up
; SvsMd01Sw5	() 'High Switch Machine''Num=     Value=' Change
;
; SvsMd02Sw3	() 'Block Data''Num=     Value=' Down
; SvsMd02Sw4	() 'Block Data''Num=     Value=' Up
; SvsMd02Sw5	() 'Block Data''Num=     Value=' Change
;
; SvsMd03Sw3	() 'MAC Address' Down
; SvsMd03Sw4	() 'MAC Address' Up
; SvsMd03Sw5	() 'MAC Address' Fact
;
; SvsMd04Sw3	() 'IP Address' Down
; SvsMd04Sw4	() 'IP Address' Up
; SvsMd04Sw5	() 'IP Address' Fact
;
; SvsMd06Sw3	() Bootloader Sw3 Yes
;
; SvsMd08Sw3	() 'Test Scanner' Down
; SvsMd08Sw4	() 'Test Scanner' Up
; SvsMd08Sw5	() 'Test Scanner' Fact
;
; SvsMd10Sw3	() 'Block Data Cab#' Down
; SvsMd10Sw4	() 'Block Data Cab#' Up
; SvsMd10Sw5	() 'Block Data Cab#' Fact
;
; SvsMd11Sw3	() 'Block Module Tester''Num=     Value=' Down
; SvsMd11Sw4	() 'Block Module Tester''Num=     Value=' Up
; SvsMd11Sw5	() 'Block Module Tester''Num=     Value=' Change
;
; DispIdleDispatch	() Called every 1/2 second to update data on shown on LCD
;
;
; SvsMdTtlXtras	() not used
;
; SvsModeDispatch	() Goto the current Service mode's button handler
;
; RunModeDispatch	() Goto the current Run mode's button handler
;
; RunOrService	() Route to the correct handler for this screen/button
;
; SvsModeIdler	() Called every 1/2 second to update data for Service screens
; RunModeIdler	() Called every 1/2 second to update data for Run screens
;
;============================================================================================
; constants
;
;
;============================================================================================
;===========================================================================================
; Part of starting a Run Mode, Displays the IP numbers, etc.
;
RunMdTtlXtras	MOVLW	0x02	;erase lines 3 and 4
	CALL	lcd_GotoLineW_D10
	MOVLW	0x03
	CALL	lcd_GotoLineW_D10
	TSTF	ScrnNumber	;ScrnNumber=0
	SKPNZ
	GOTO	DispIP_D10	;'192.168.1.123'
	MOVLW	0x01	;erase line 1
	CALL	lcd_GotoLineW_D10
	MOVLW	d'1'
	SUBWF	ScrnNumber,W
	SKPZ
	RETURN		;blank line only
;
	MOVLW	Str_SNPtr	;Run Mode Scrn 2
	CALL	PrintString_D10	;'S/N:' 7004
	MOVLW	eSN0
	CALL	ReadEEwW_D10
	MOVWF	Param76
	MOVLW	eSN1
	CALL	ReadEEwW_D10
	MOVWF	Param77
	BSF	Disp_LZO
	GOTO	Disp_decword_D10
;
;===========================================================================================
; Run Mode Screen 0
;
; Entry: Bank3
; Exit:
;
NormalMd00_SW4	GOTO	MainB0Rtn
;===========================================================================================
; Run Mode Screen 0
;
; Entry: Bank3
; Exit:
;
NormalMd00_SW5	GOTO	MainB0Rtn
;
;===========================================================================================
; Run Mode Screen 3 Clear Hard Error
;
; Entry: Bank3
; Exit:
;
NormalMd03_SW5
;	BCF	HardErrorLatch
	GOTO	StartRunMode	;return to user selected run screen
;
;===========================================================================================
; Idler routine for service mode 00 'Switch Machine''Num=     Value='
;
SvsMd00Idle	CALL	IdleR2C4
	MOVLW	SMSvsPtr
	CALL	Idle3plDec
	CALL	IdleR2C16
	mBank3
	MOVFW	SMSvsPtr
	MOVWF	XReg
	CALL	GetSMTableX_D10
	GOTO	Disp_Hex_Byte_D10
;
;===========================================================================================
; Idler routine for service mode 01 'High Switch Machine''Num=     Value='
;
SvsMd01Idle	CALL	IdleR2C4
	MOVLW	SMHighSvsPtr
	CALL	Idle3plDec
	CALL	IdleR2C16
	mBank3
	MOVFW	SMHighSvsPtr
	MOVWF	XReg
	CALL	GetSMTableHighX_D10
	GOTO	Disp_Hex_Byte_D10
;
;===========================================================================================
; Idler routine for service mode 02 'Block Data''Num=     Value='
;
SvsMd02Idle	CALL	IdleR2C4
	MOVLW	SvsBlkNum
	CALL	Idle3plDec
	CALL	IdleR2C12
;
	if UsesBlockCmdTable
	mBank3
	MOVFW	SvsBlkNum
	MOVWF	XReg
	CALL	GetBlockCmdTable2X_D10
	CALL	Disp_Hex_Byte_D10
	mBank3
	CALL	GetBlockCmdTableX_D10
	CALL	Disp_Hex_Byte_D10
	endif
;
	mBank3
	MOVFW	SvsBlkNum
	MOVWF	XReg
	CALL	GetBlockPwrTable2X_D10
	CALL	Disp_Hex_Byte_D10
	mBank3
	CALL	GetBlockPwrTableX_D10
	GOTO	Disp_Hex_Byte_D10
;
;===========================================================================================
; Idler routine for service mode 03 'MAC Address'
;
SvsMd03Idle	CALL	lcd_GotoLine2
DispMAC_E2_D10	mCall2To0	DispMAC_E2
	RETURN
;
;===========================================================================================
; Idler routine for service mode 04 'IP Address'
;
SvsMd04Idle	CALL	lcd_GotoLine2
DispIP_E2_D10	mCall2To0	DispIP_E2
	RETURN
;
	if UsesShowInputs
;===========================================================================================
; Idler routine for service mode 05 'Show Inputs'
;
SvsMd05Idle	CALL	lcd_GotoLine2
	MOVLW	'0'
	CALL	DisplaysW_D10
	CALL	Disp_Colon
	MOVLW	CurrentLDI_0
	CALL	IdleHexByte
;
	if UsesLDI1
	CALL	Disp_Space
	MOVLW	'1'
	CALL	DisplaysW_D10
	CALL	Disp_Colon
	MOVLW	CurrentLDI_1
	CALL	IdleHexByte
	endif
;
	if UsesLDI2
	CALL	Disp_Space
	MOVLW	'2'
	CALL	DisplaysW_D10
	CALL	Disp_Colon
	MOVLW	CurrentLDI_2
	CALL	IdleHexByte
	endif
	RETURN
	endif
;
	if UsesInputTester|UsesOutputTester
;===========================================================================================
; Idler routine for service mode 08 'Test Scanner''Slot/Board='
;
SvsMd08Idle	CALL	IdleR2C12
	mBank3
	MOVF	SvsInSlotBoard,W
	GOTO	Disp_Hex_Byte_D10
;
	endif
	if UsesInputTester
;===========================================================================================
; Idler routine for service mode 09 'Test Scanner'
SvsMd09Idle	CALL	lcd_GotoLine2
	mBank3
	MOVF	CurBlk,W	;Save CurBlk
	MOVWF	SvsCurBlk
	MOVF	CurBlk+1,W
	MOVWF	SvsCurBlk+1
	MOVLW	0x80
	MOVWF	CurBlk
	MOVF	SvsInSlotBoard,W
	MOVWF	CurBlk+1
	CALL	Disp_Hex_Byte_D10
	CALL	Disp_Colon
Show8Bytes_L1	CALL	Show8Inputs
	mBank3
	MOVLW	0x40
	SUBWF	CurBlk,W
	SKPNZ
	CALL	Disp_Space
	mBank3
	MOVF	CurBlk,F
	SKPZ
	GOTO	Show8Bytes_L1
	MOVF	SvsCurBlk,W	;Restore CurBlk
	MOVWF	CurBlk
	MOVF	SvsCurBlk+1,W
	MOVWF	CurBlk+1
	GOTO	MainB0Rtn
;
Show8Inputs	MOVLW	0x08	;get 8 bits
	MOVWF	Param7A
Show8Inputs_L1	mBank3
	DECF	CurBlk,F
	mCall2To3	InputB
	RLF	IActive,W
	RLF	Param79,F
	DECFSZ	Param7A,F
	GOTO	Show8Inputs_L1
	MOVF	Param79,W
	GOTO	Disp_Hex_Byte_D10
;
	endif
;===========================================================================================
;Idler routine for service mode 10 'Block Data Cab#'
;
SvsMd10Idle	CALL	IdleR2C16
	mBank3
	INCF	SvsCabNum,W
	GOTO	Disp_Hex_Byte_D10
;
;===========================================================================================
; Idler routine for service mode 11 'Block Module Tester''Num=     Value='
;
	if UsesBlockModules
SvsMd11Idle	CALL	IdleR2C4
	MOVLW	SvsBMdlNum
	CALL	Idle2plDec
	CALL	IdleR2C16
	mBank3
	MOVF	SvsBMdlVal,W
	CALL	Disp_Hex_Byte_D10
	GOTO	SvsTestOneModule
	endif
;
;===========================================================================================
; Idler routine for service mode 12 'Output Board Tester''Num=     Value='
;
	if UsesOutputTester
SvsMd12Idle	CALL	IdleR2C4
	mBank3
	MOVF	SvsInSlotBoard,W
	CALL	Disp_Hex_Byte_D10
	mBank3
	MOVF	SvsBMdlNum,W
	ANDLW	0x7F
	CALL	Disp_Hex_Byte_D10
;
	CALL	IdleR2C16
	mBank3
	MOVF	SvsBMdlVal,W
	ANDLW	0x80
	CALL	Disp_Hex_Byte_D10
;
	mBank3
	MOVF	CurBlk,W	;Save CurBlk
	MOVWF	SvsCurBlk
	MOVF	CurBlk+1,W
	MOVWF	SvsCurBlk+1
;
	MOVLW	0x80
	MOVWF	CurBlk
	MOVF	SvsInSlotBoard,W
	MOVWF	CurBlk+1
SvsTOB_L1	DECF	CurBlk,F
	BCF	OActive,7
	BTFSC	SvsBMdlVal,7
	BSF	OActive,7
	MOVF	SvsBMdlNum,W
	ANDLW	0x7F
	SUBWF	CurBlk,W
	SKPZ
	BCF	OActive,7
	mCall2To3	OutputB
	MOVF	CurBlk,F
	SKPZ
	GOTO	SvsTOB_L1
;
	MOVF	SvsCurBlk,W	;Restore CurBlk
	MOVWF	CurBlk
	MOVF	SvsCurBlk+1,W
	MOVWF	CurBlk+1
	GOTO	MainB0Rtn
;
;
	endif
;
;===========================================================================================
;*******************************************************************************************
;===========================================================================================
; 'Switch Machine''Num=     Value=' Down
SvsMd00Sw3	DECF	SMSvsPtr,F
	GOTO	MainB0Rtn
;===========================================================
; 'Switch Machine''Num=     Value=' Up
SvsMd00Sw4	INCF	SMSvsPtr,F
	GOTO	MainB0Rtn
;===========================================================
; 'Switch Machine''Num=     Value=' Change
SvsMd00Sw5	MOVF	SMSvsPtr,W
	MOVWF	XReg
	CALL	GetSMTableX_D10
	MOVLW	SMCMDMask
	XORWF	Param78,W
	CALL	SetSMTableX_D10
	BSF	SMTableLowChngFlag
	GOTO	MainB0Rtn
;
;===========================================================================================
; 'High Switch Machine''Num=     Value=' Down
SvsMd01Sw3	DECF	SMHighSvsPtr,F
	GOTO	MainB0Rtn
;===========================================================
; 'High Switch Machine''Num=     Value=' Up
SvsMd01Sw4	INCF	SMHighSvsPtr,F
	GOTO	MainB0Rtn
;===========================================================
; 'High Switch Machine''Num=     Value=' Change
SvsMd01Sw5	MOVF	SMHighSvsPtr,W
	MOVWF	XReg
	CALL	GetSMTableHighX_D10
	MOVLW	SMCMDMask
	XORWF	Param78,W
	CALL	SetSMTableHighX_D10
	BSF	SMTableHiChngFlag
	GOTO	MainB0Rtn
;
;===========================================================================================
; 'Block Data''Num=     V=' Down
SvsMd02Sw3	DECF	SvsBlkNum,F
	MOVLW	kMaxBlockNum
	BTFSC	SvsBlkNum,7
	MOVWF	SvsBlkNum
	GOTO	MainB0Rtn
;===========================================================
; 'Block Data''Num=     V=' Up
SvsMd02Sw4	MOVLW	kMaxBlockNum
	SUBWF	SvsBlkNum,W
	SKPZ
	INCF	SvsBlkNum,W
	MOVWF	SvsBlkNum
	GOTO	MainB0Rtn
	if UsesBlockCmdTest
	if UsesBlockCmdTable
;===========================================================
; 'Block Data''Num=     V=' Change SvsCabNum
SvsMd02Sw5	MOVF	SvsBlkNum,W
	MOVWF	XReg
	MOVF	SvsCabNum,W
	SUBLW	0x04	;4-cab
	SKPNB
	GOTO	SvsMd02Sw5_1
;
	INCF	SvsCabNum,W
	MOVWF	Param79
	MOVLW	0x20
	MOVWF	Param7A
	BCF	_C
SvsMd02Sw5_L1	RRF	Param7A,F
	DECFSZ	Param79,F
	GOTO	SvsMd02Sw5_L1
	CALL	GetBlockCmdTableX_D10
	XORWF	Param7A,W	;cab
	IORLW	0x80
	CALL	SetBlockCmdTableX_D10
	GOTO	MainB0Rtn
;
SvsMd02Sw5_1	MOVLW	0x04
	SUBWF	SvsCabNum,W
	MOVWF	Param79
	MOVLW	0x10
	MOVWF	Param7A
	BCF	_C
SvsMd02Sw5_L2	RRF	Param7A,F
	DECFSZ	Param79,F
	GOTO	SvsMd02Sw5_L2
	CALL	GetBlockCmdTable2X_D10
	XORWF	Param7A,W	;cab
	IORLW	0x80
	CALL	SetBlockCmdTable2X_D10
	GOTO	MainB0Rtn
	else
;===========================================================
; 'Block Data''Num=     V=' Change SvsCabNum
SvsMd02Sw5	MOVF	SvsBlkNum,W
	MOVWF	XReg
	MOVF	SvsCabNum,W
	SUBLW	0x04	;4-cab
	SKPNB
	GOTO	SvsMd02Sw5_1
;
	INCF	SvsCabNum,W
	MOVWF	Param79
	MOVLW	0x20
	MOVWF	Param7A
	BCF	_C
SvsMd02Sw5_L1	RRF	Param7A,F
	DECFSZ	Param79,F
	GOTO	SvsMd02Sw5_L1
	CALL	GetBlockPwrTableX_D10
	XORWF	Param7A,W	;cab
	CALL	SetBlockPwrTableX_D10
	GOTO	MainB0Rtn
;
SvsMd02Sw5_1	MOVLW	0x04
	SUBWF	SvsCabNum,W
	MOVWF	Param79
	MOVLW	0x10
	MOVWF	Param7A
	BCF	_C
SvsMd02Sw5_L2	RRF	Param7A,F
	DECFSZ	Param79,F
	GOTO	SvsMd02Sw5_L2
	CALL	GetBlockPwrTable2X_D10
	XORWF	Param7A,W	;cab
	CALL	SetBlockPwrTable2X_D10
	GOTO	MainB0Rtn
	endif
	endif
;
;===========================================================================================
;===========================================================================================
; 'MAC Address' Down
;
SvsMd03Sw3	mBank0
	DECF	myeth5,F
write_nonvol_D10	mCall2To0	write_nonvol
	RETURN
;
;=========================================================
; 'MAC Address' Up
;
SvsMd03Sw4	mBank0
	INCF	myeth5,F
	GOTO	write_nonvol_D10
;
;=========================================================
; 'MAC Address' Fact
;
SvsMd03Sw5	mBank0
	MOVLW	low kMAClsw
	MOVWF	myeth5
	GOTO	write_nonvol_D10
;
;===========================================================================================
; 'IP Address' Down
;
SvsMd04Sw3	mBank0
	DECF	myip_b0,F
	GOTO	write_nonvol_D10
;
;=========================================================
; 'IP Address' Up
;
SvsMd04Sw4	mBank0
	INCF	myip_b0,F
	GOTO	write_nonvol_D10
;
;=========================================================
; 'IP Address' Fact
;
SvsMd04Sw5	mBank0
	MOVLW	kIPlsb
	MOVWF	myip_b0
	GOTO	write_nonvol_D10
;
;===========================================================================================
; Bootloader Sw3 Yes
SvsMd06Sw3	mCall2To3	SetUIPBit
SvsMd07Sw3	CLRF	PCLATH	;Reset
	GOTO	0x0000
;
	if UsesInputTester|UsesOutputTester
;===========================================================================================
; 'Test Scanner' Down
;
SvsMd08Sw3	DECF	SvsInSlotBoard,W
	ANDLW	0x37
	MOVWF	SvsInSlotBoard
	GOTO	MainB0Rtn
;
;=========================================================
; 'Test Scanner' Up
;
SvsMd08Sw4	INCF	SvsInSlotBoard,F
	BTFSS	SvsInSlotBoard,3
	GOTO	MainB0Rtn
	MOVF	SvsInSlotBoard,W
	ADDLW	0x10
	ANDLW	0x30
	MOVWF	SvsInSlotBoard
	GOTO	MainB0Rtn
;
;=========================================================
; 'Test Scanner' Fact
;
SvsMd08Sw5	CLRF	SvsInSlotBoard
	GOTO	MainB0Rtn
;
	endif
;===========================================================================================
; 'Block Data Cab#' Down
;
SvsMd10Sw3	DECF	SvsCabNum,F
	MOVLW	0x08
	BTFSC	SvsCabNum,7
	MOVWF	SvsCabNum
	GOTO	MainB0Rtn
;
;=========================================================
; 'Block Data Cab#' Up
;
SvsMd10Sw4	BTFSC	SvsCabNum,3
	GOTO	SvsMd10Sw5
	INCF	SvsCabNum,F
	GOTO	MainB0Rtn
;
;=========================================================
; 'Block Data Cab#' Fact
;
SvsMd10Sw5	CLRF	SvsCabNum
	GOTO	MainB0Rtn
;
;===========================================================================================
	if UsesBlockModules
; 'Block Module Tester''Num=     Value=' Down
SvsMd11Sw3	CALL	SvsTestModuleOFF
	DECF	SvsBMdlNum,F
	MOVLW	kLastBlkModule
	BTFSC	SvsBMdlNum,7
	MOVWF	SvsBMdlNum
	GOTO	MainB0Rtn
;===========================================================
; 'Block Module Tester''Num=     Value=' Up
SvsMd11Sw4	CALL	SvsTestModuleOFF
	INCF	SvsBMdlNum,F
	MOVF	SvsBMdlNum,W
	SUBLW	kLastBlkModule+1
	SKPNZ
	CLRF	SvsBMdlNum
	GOTO	MainB0Rtn
;===========================================================
; 'Block Module Tester''Num=     Value=' Change
SvsMd11Sw5	INCF	SvsBMdlVal,F
	MOVF	SvsBMdlVal,W
	SUBLW	d'25'	;24=test all
	SKPNZ
	CLRF	SvsBMdlVal
	else
SvsMd11Sw3
SvsMd11Sw4
SvsMd11Sw5
	endif
	GOTO	MainB0Rtn
;===========================================================================================
	if UsesOutputTester
; 'Output Board Tester''Num=     Value=' Down
SvsMd12Sw3	DECF	SvsBMdlNum,F
	GOTO	MainB0Rtn
;===========================================================
; 'Output Board Tester''Num=     Value=' Up
SvsMd12Sw4	INCF	SvsBMdlNum,F
	GOTO	MainB0Rtn
;===========================================================
; 'Output Board Tester''Num=     Value=' Change
SvsMd12Sw5	MOVLW	0x80
	XORWF	SvsBMdlVal,F
	endif
SvsMdTtlXtras	GOTO	MainB0Rtn
;
;===========================================================================================
;===========================================================================================
DecAndSave	MOVWF	Param79
	CALL	ReadEE79_D10
	MOVWF	Param78
	DECF	Param78,W
	GOTO	WriteEEP79W_D10
;
;=============================================================
IncAndSave	MOVWF	Param79
	CALL	ReadEE79_D10
	MOVWF	Param78
	INCF	Param78,W
	GOTO	WriteEEP79W_D10
;
;=============================================================
;
Save7879	MOVWF	Param79
	MOVFW	Param78
	GOTO	WriteEEP79W_D10
;
;===========================================================================================
;*******************************************************************************************
;===========================================================================================
; Branch Tables
	ORG	0x1780
;============================================================================================
;
; Entry: Bank0 selected
;
DispIdleDispatch	mBank0
	BSF	PCLATH,0	;0xX7XX
	BSF	PCLATH,1
	BSF	PCLATH,2
	MOVF	ScrnNumber,W
	BTFSS	ServiceMode
	GOTO	RunModeIdler
	GOTO	SvsModeIdler
;
;===========================================================================================
;============================================================================================
; Part of starting a Svs Mode, Displays the ID numbers, etc.
;
;SvsMdTtlXtras	RETURN ;;;;; moved up to save a word
;
;===========================================================================================
; Goto the current Service mode's button handler
;
; Entry: W=ScrnNumber
; Exit: none
;
SvsModeDispatch	TSTF	Param79
	SKPNZ		;Button = 0 'Next"?
	GOTO	NextSvsMode	; Yes
	MOVLW	0x04
	SUBWF	Param79,W
	SKPNZ		;Button = 4 'Service Mode/Run Mode'
	GOTO	StartRunMode	; Yes
	MOVLW	0x05
	SUBWF	Param79,W
	SKPNZ		;Button = 5 'Previous'
	GOTO	PrevSvsMode	; Yes
;
; Calculate offset as ScrnNumber x 3 + (Button - 1)
;
	DECF	Param79,F	;0..2
	MOVF	ScrnNumber,W	;0..63
	ADDWF	ScrnNumber,W	; x 3
	ADDWF	ScrnNumber,W	;0..189 + 0..2
	ADDWF	Param79,W
	mBank3
	ADDWF	PCL,F
;00 'Switch Machine''Num=     Value='  next, prev, Down, Up, Chng
	GOTO	SvsMd00Sw3	;SW3 Down
	GOTO	SvsMd00Sw4	;SW4 Up
	GOTO	SvsMd00Sw5	;SW5 Change
;01 'High Switch Machine''Num=     Value='  next, prev, Down, Up, Chng
	GOTO	SvsMd01Sw3	;SW3 Down
	GOTO	SvsMd01Sw4	;SW4 Up
	GOTO	SvsMd01Sw5	;SW5 Change
;02 'Block Data''Num=     Value='  next, prev, Down, Up, Chng
	GOTO	SvsMd02Sw3	;SW3 Down
	GOTO	SvsMd02Sw4	;SW4 Up
	if UsesBlockCmdTest
	GOTO	SvsMd02Sw5	;SW5 Change
	else
	GOTO	MainB0Rtn
	endif
;03 'MAC Address'
	GOTO	SvsMd03Sw3	;SW3 Down
	GOTO	SvsMd03Sw4	;SW4 Up
	GOTO	SvsMd03Sw5	;SW5 Fact
;04 'IP Address'
	GOTO	SvsMd04Sw3	;SW3 Down
	GOTO	SvsMd04Sw4	;SW4 Up
	GOTO	SvsMd04Sw5	;SW5 Fact
;05 'Show Inputs'
	GOTO	MainB0Rtn
	GOTO	MainB0Rtn
	GOTO	MainB0Rtn
;06 'Bootloader'
	GOTO	SvsMd06Sw3	;SW3 Yes
	GOTO	NextSvsMode	;SW4 No
	GOTO	MainB0Rtn
;07 'Reset'
	GOTO	SvsMd07Sw3	;SW3 Yes
	GOTO	NextSvsMode	;SW4 No
	GOTO	MainB0Rtn
;08 'Test Scanner'
	if UsesInputTester|UsesOutputTester
	GOTO	SvsMd08Sw3	;SW3 Down
	GOTO	SvsMd08Sw4	;SW4 Up
	GOTO	SvsMd08Sw5	;SW5 Fact
	else
	GOTO	MainB0Rtn
	GOTO	MainB0Rtn
	GOTO	MainB0Rtn
	endif
;09 'Test Scanner'
	GOTO	MainB0Rtn	;SW3 Down
	GOTO	MainB0Rtn	;SW4 Up
	GOTO	MainB0Rtn	;SW5 Fact
;10 'Block Data Cab#'
	GOTO	SvsMd10Sw3	;SW3 Down
	GOTO	SvsMd10Sw4	;SW4 Up
	GOTO	SvsMd10Sw5	;SW5 Fact
;
;11 'Block Module Tester''Num=     Value='  next, prev, Down, Up, Chng
	GOTO	SvsMd11Sw3	;SW3 Down
	GOTO	SvsMd11Sw4	;SW4 Up
	GOTO	SvsMd11Sw5	;SW5 Change
;
;12 'Output Board Tester''Num=     Value='  next, prev, Down, Up, Chng
	if UsesOutputTester
	GOTO	SvsMd12Sw3	;SW3 Down
	GOTO	SvsMd12Sw4	;SW4 Up
	GOTO	SvsMd12Sw5	;SW5 Change
	else
	GOTO	MainB0Rtn
	GOTO	MainB0Rtn
	GOTO	MainB0Rtn
	endif
;
;============================================================================================
; Goto the current Run mode's button handler
;
; Entry: Param79 btn num (0..5)
; Exit: none
;
RunModeDispatch	MOVLW	0x04
	SUBWF	Param79,W
	SKPNZ		;SW6?
	GOTO	StartSvsMode	; yes
	MOVLW	0x05
	SUBWF	Param79,W
	SKPNZ		;SW7?
	GOTO	PrevRunMode	; yes
; Calculate offset as ScrnNumber x 3 + (Button - 1)
;
	MOVF	ScrnNumber,W	;0..63
	ADDWF	ScrnNumber,W	;x2=0..126
	ADDWF	ScrnNumber,W	;x3=0..189
	ADDWF	ScrnNumber,W	;x4=0..252 + 0..3
	ADDWF	Param79,W
	mBank3
	ADDWF	PCL,F
;Screen 0, SIGNONStrPtr, IP
	GOTO	NextRunMode	;SW2 Next
	GOTO	MainB0Rtn	;SW3
	GOTO	NormalMd00_SW4	;SW4
	GOTO	NormalMd00_SW5	;SW5
;Screen 1, SIGNONStrPtr, S/N
	GOTO	NextRunMode	;SW2 Next
	GOTO	MainB0Rtn	;SW3
	GOTO	MainB0Rtn	;SW4
	GOTO	MainB0Rtn	;SW5
;Screen 2, SIGNONStrPtr
	GOTO	NextRunMode	;SW2 Next
	GOTO	MainB0Rtn	;SW3
	GOTO	NormalMd00_SW4	;SW4
	GOTO	NormalMd00_SW5	;SW5
;Screen 3, (Err | Login),SW2 to clear
	GOTO	NormalMd03_SW5	;SW2 Cancel
	GOTO	MainB0Rtn	;SW3
	GOTO	MainB0Rtn	;SW4
	GOTO	MainB0Rtn	;SW5
;	
;============================================================================================
; Route to the correct handler for this screen/button
;
; Entry: Param79 is now the normalized button number.
;        ScrnNumber is the Current Screen Number SW2..SW7 = 0..5
; Exit:
;
RunOrService	BSF	PCLATH,0	;0xX7XX
	BSF	PCLATH,1
	BSF	PCLATH,2
	BTFSS	ServiceMode
	GOTO	RunModeDispatch
	GOTO	SvsModeDispatch
;
;============================================================================================
;
SvsModeIdler	ADDWF	PCL,F
	GOTO	SvsMd00Idle	;Scrn #00'Switch Machine'
	GOTO	SvsMd01Idle	;Scrn #01'High Switch Machine'
	GOTO	SvsMd02Idle	;Scrn #02'Block Data'
	GOTO	SvsMd03Idle	;Scrn #03'MAC Address'
	GOTO	SvsMd04Idle	;Scrn #04'IP Address'
	if UsesShowInputs
	GOTO	SvsMd05Idle	;Scrn #05'Input '
	else
	GOTO	MainB0Rtn
	endif
	GOTO	MainB0Rtn	;Scrn #06'Bootloader'
	GOTO	MainB0Rtn	;Scrn #07'Remote Reset'
;
	if UsesInputTester|UsesOutputTester
	GOTO	SvsMd08Idle	;Scrn #08'Test Scanner'
	else
	GOTO	MainB0Rtn
	endif
;
	if UsesInputTester
	GOTO	SvsMd09Idle	;Scrn #09'Test Scanner'
	else
	GOTO	MainB0Rtn
	endif
;
	GOTO	SvsMd10Idle	;Scrn #10'Block Data Cab#'
	if UsesBlockModules
	GOTO	SvsMd11Idle	;Scrn #11'Block Module Tester'
	else
	GOTO	MainB0Rtn
	endif
	if UsesOutputTester
	GOTO	SvsMd12Idle	;Scrn #12'Output Board Tester'
	else
	GOTO	MainB0Rtn
	endif
;
;============================================================================================
;
RunModeIdler	ANDLW	0x03
	ADDWF	PCL,F
	GOTO	ShowRunScrn00	;Scrn #00 SIGNONStrPtr,IP
	GOTO	ShowRunScrn00	;Scrn #01 SIGNONStrPtr,SN
	GOTO	ShowRunScrn00	;Scrn #02 SIGNONStrPtr
	GOTO	DoErrorDisplay	;Scrn #03
;
;
;
;
;
;
;
;
;
;
;
;
