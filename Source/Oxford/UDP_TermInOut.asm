	subtitle	"UDP_TermInOut.asm"
	page
;===========================================================================================
;
;  FileName: UDP_TermInOut.asm
;  Date: 4/22/05
;  File Version: 1.0a2
;  
;  Author: David M. Flynn
;  Company: Oxford V.U.E., Inc.
;
;============================================================================================
; Notes:
;
;  This file is standard handler routines for UDP.
;  These routines are the building blocks for a UDP data sincronizer.
;  Used to send and modify data in RAM bank 2, usually 18 bytes starting w/ adc0LSB
;
;  Put in segment 3 after Ether.asm
;
;  Constants:
;   kUDP_DS_TargetIP	destination for UDP_DataSender
;   kBytesToUDP	Bytes UDP_DataSender
;   kLinkTime	EQU	1	;+1=2 seconds
;
;  Ram Locations:
;   REMLinkTestByte	EQU	REMadc2LSB	;rotates '@'..'O'
;   LinkTestByte	EQU	adc2LSB	;rotates '@'..'O'
;   REMLinkCount	RES	1	;sequencial bad links.
;   UDP_DS_DataStart	UDP_DS_DataStart equ adc0LSB or other bank 2 ram
;   UDP_DS_REMDataStart UDP_DS_DataStart equ REMadc0LSB or other bank 2 ram
;#Define	GoodLink	Flags27,5
;
;  Timers:
;   LinkTimer	EQU	Timer5Lo
;
;============================================================================================
; Revision History
;
; 1.0a2    4/22/05	Fixed a mCall wrong segment error
; 1.0a1    2/7/05	Fisrt code, copied routines from TCP GSE project
;
;============================================================================================
; Conditionals
;
;  	constant	IsMaster=1	;one is master the other slave
;
;============================================================================================
;
; Name	(additional stack words required) Description
;================================================================================================
; UDP_DataSender	Send BytesToUDP (48 max) bytes starting with UDP_DS_DataStart to kUDP_DS_TargetIP
; UDP_Term_Handler	Handler for incoming UDP terminal port (TermPort) data
;	 Look for kBytesToUDP and store at UDP_DS_REMDataStart
;
; GotLink	(private) Reset LinkTimer set GoodLink if REMLinkTestByte=LinkTestByte
; TestLink	Check for a good link.  If bad clr GoodLink
;
;calls outside this file
;
;	mCall3To1	Locate_ARP
;	mCall3To1	put_data2	;move to txbuff
;	mCall3To1	UDP_Send
;	CALL	getch_net_D18
;	CALL	PrepDataForUDP
;
;===========================================================================================
;===========================================================================================
; UDP data sender
;
; Usually called by OnTheHalfSecond, and by some routines wanting a faster responce.
; Send the bytes at UDP_DS_DataStart for a total of kBytesToUDP bytes.
; 
;
; Entry: none
; Exit: none
; RAM used:Param70, Param71, Param78, Param79, Param7A, Param7B, Param7C, FSR
; Calls: (1+4) Locate_ARP, put_data2, UDP_Send
;
UDP_DataSender	mBank0
	MOVLW	kUDP_DS_TargetIP
	MOVWF	remip_b0
;
	mCall3To1	Locate_ARP
;
	BSF	_RP0	;bank 1
	MOVLW	AS_RESOLVED
	SUBWF	ae_state,W
	BCF	_RP0	;bank 0
	SKPZ		;skip if resolved
	RETURN		;still pending try again later
;
; Send the ADCs,
;
	if IsMaster
	mBank2
	INCF	REMLinkTestByte,W
	ANDLW	0x0F
	IORLW	0x40	;@..O
	MOVWF	LinkTestByte
	else
	mCall3To2	PrepDataForUDP	;must return w/ bank 2 selected
;	mBank2
	MOVF	REMLinkTestByte,W
	MOVWF	LinkTestByte
	endif
;
	mBank0
	CLRF	txin
	MOVLW	kBytesToUDP	;count
	MOVWF	Param79
	MOVLW	low UDP_DS_DataStart	;source
	MOVWF	Param7A
	mCall3To1	put_data2	;move to txbuff
;	
;
; local and remote port numbers
	MOVLW	high TermPort
	MOVWF	locport_b1
	MOVWF	remport_b1
	MOVLW	low TermPort
	MOVWF	locport_b0
	MOVWF	remport_b0
;
	mCall3To1	UDP_Send
	RETURN
;
;========================================================================================
; Handler for the incoming data at the UDP terminal port (TermPort)
;
; Receive REMadc0..7
;
; Port 57 "any private terminal access"
;
; Entry:next NIC byte to read is first byte of UDP data field
; Exit:
; RAM used:
; Calls:(1+)
;
UDP_Term_Handler	MOVLW	kBytesToUDP	;move 18 bytes
	MOVWF	Param79
	MOVLW	UDP_DS_REMDataStart
	MOVWF	FSR
	BSF	_IRP
UDP_TH_L1	CALL	getch_net_D18
	BTFSC	atend	;Read past end?
	RETURN		;Yes.
	MOVWF	INDF
	INCF	FSR,F
	DECFSZ	Param79,F
	GOTO	UDP_TH_L1
;
; fall through to GotLink
;
;============================================================================================
; Reset the link integrity timer
; Called by UDP_Term_Handler when all kBytesToUDP are received.
;
; Entry: none
; Exit: none
; RAM used: none
; Calls: (0) none
;
GotLink	mBank3
	MOVLW	0xFF
	MOVWF	LinkTimer
	MOVLW	kLinkTime
	MOVWF	LinkTimer+1
	BCF	_RP0	;Bank2
;
	if IsMaster		;ie LCO Module
	MOVF	REMLinkTestByte,W
	SUBWF	LinkTestByte,W
	else		;Slave, ie PAD Module
	INCF	LinkTestByte,W
	ANDLW	0x0F
	IORLW	0x40	;@..O
	SUBWF	REMLinkTestByte,W
	endif
;
	BCF	_RP1	;Bank0
	SKPNZ
	BSF	GoodLink
	RETURN
;
;============================================================================================
; Check for a good link.  If bad clr GoodLink
; Called by OnTheTick
; Also, if this routine is called 256 times (12.8 seconds) without the data updating GoodLink is cleared.
;
; Entry: none
; Exit: none
; RAM used: none
; Calls: (0) none
;
TestLink	mBank0
	BTFSS	GoodLink
	RETURN
	mBank3
	MOVF	LinkTimer+1,W
	IORWF	LinkTimer,W
	SKPZ
	GOTO	TL_NewData
;
; No data has been received for more than kLinkTime+1 seconds
TL_Bad	mBank0
	BCF	GoodLink
	RETURN
;
; We have recieved data, but is it old?
TL_NewData	mBank2
;
	if IsMaster		;ie LCO Module
	MOVF	REMLinkTestByte,W
	SUBWF	LinkTestByte,W
	else		;Slave, ie PAD Module
	INCF	LinkTestByte,W
	ANDLW	0x0F
	IORLW	0x40	;@..O
	SUBWF	REMLinkTestByte,W
	endif
	SKPNZ
	GOTO	TL_Good
	INCF	REMLinkCount,F
	SKPNZ
	GOTO	TL_Bad
;
TL_Good	CLRF	REMLinkCount
	mBank0
	RETURN
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
