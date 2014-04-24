	subtitle	"UDP_DataInOut.asm"
	page
;===========================================================================================
;
;  FileName: UDP_DataInOut.asm
;  Date: 6/28/05
;  File Version: 1.0.1
;  
;  Author: David M. Flynn
;  Company: Oxford V.U.E., Inc.
;
;============================================================================================
; Notes:
;
;  This file is standard handler routines for UDP.
;  These routines are the building blocks for UDP data handling.
;  Used to send and modify data in one page (64KB) of SRAM.
;
;  Put in segment 3 after Ether.asm
;
;  Data Format:  (data is big endien)
;   DataType	byte
;   Length	word (1..1024, 0x0001..0x0400)
;   Dest Addr	word
;   Data Bytes	Length
;
;  Constants:
;   kUDP_SRAM_Page	EQU	0x02	;SRAM_Addr2 value for receiving
;			  Always send from page SRAM_DestAddr2
;
;  Ram Locations:
;   Bank3:
;SRAM_UDP_Tx_DT	RES	1	;Transmited data type
;SRAM_Len	RES	1	; 2 bytes Bigendian
;SRAM_Len_Lo	RES	1
;SRAM_DestAddr2	RES	1	; 3 bytes Bigendian
;SRAM_DestAddr1	RES	1
;SRAM_DestAddr0	RES	1
;SRAM_UDP_Rx_IP	RES	1	;Low byte of IP address
;SRAM_UDP_Rx_DT	RES	1	;Received data type
;SRAM_Len_Rx	RES	1	; 2 bytes Bigendian
;SRAM_Len_Lo_Rx	RES	1
;SRAM_DestAddr1_Rx	RES	1	; 2 bytes Bigendian
;SRAM_DestAddr0_Rx	RES	1
;TTFTP_Flags	RES	1
;#Define	UDP_DataReceived	TTFTP_Flags,0
;#Define	UDP_DataSent	TTFTP_Flags,1
;
;
;============================================================================================
; Revision History
;
; 1.0.1    6/28/05	Added SRAM_UDP_Rx_IP.
; 1.0      4/24/05	Defaulted UDP_DataReceived to false in UDP_Data_Handler
; 1.0a5    3/15/05	Changed DataType to 1 byte and made it and IP variables.
; 1.0a4    3/13/05	Removed kUDP_SRAM_SrcPage, optimized code.
; 1.0a3    3/9/05	Added kUDP_SRAM_SrcPage
; 1.0a2    2/27/05	Fixed long call error.
; 1.0a1    2/8/05	Fisrt code, copied routines from UDP_TermInOut.asm
;
;============================================================================================
; Conditionals
;
	ifndef kUDP_SRAM_Page
kUDP_SRAM_Page	EQU	0x02	;Receive to this page
	endif
;
;============================================================================================
;
; Name	(additional stack words required) Description
;================================================================================================
; UDP_DataSender	Send SRAM_Len bytes at kUDP_SRAM_Page,SRAM_DestAddr1,SRAM_DestAddr0
;	 to W:IPDATAPORT
; UDP_Data_Handler	Handler for incoming UDP data port 87 (IPDATAPORT) data
;
;
;calls outside this file
;
;	mCall3To1	Locate_ARP
;	CALL	putnic_checkbyte_D18
;	mCall3To1	UDP_Send
;	CALL	getch_net_D18
;	CALL	match_word_D18
;	CALL	SRAM_ReadPI_D18
;	CALL	SRAM_WritePI_D18
;
;==============================================================================
; Setup UDP to send one page (256 bytes) from SRAM
; Only use in segment 3
;
; Entry: W=IPAddress, Bank3
; Exit: none, goto UDP_DataSender_RTN
; RAM used:Param70, Param71, Param78, Param79, Param7A, Param7B, Param7C, FSR
; Calls: (1+4) Locate_ARP, UDP_Send
;
mSendSRAM_UDPData	macro	DestPage,TheDataType
	BSF	STATUS,RP0
	BSF	STATUS,RP1	;Bank3
	MOVWF	Param78
	MOVLW	high DestPage
	MOVWF	SRAM_DestAddr2
	MOVLW	low DestPage
	MOVWF	SRAM_DestAddr1
;
	MOVLW	TheDataType
	MOVWF	SRAM_UDP_Tx_DT
	MOVLW	0x01	;256 bytes
	MOVWF	SRAM_Len
	CLRF	SRAM_Len_Lo
	CLRF	SRAM_DestAddr0
	MOVF	Param78,W
	GOTO	UDP_DataSender
	endm
;
;===========================================================================================
;===========================================================================================
; UDP data sender
;
; Usually called by OnTheHalfSecond, and by some routines wanting a faster responce.
; Send SRAM_Len bytes at kUDP_SRAM_Page,SRAM_DestAddr1,SRAM_DestAddr0.
; 
; Bytes sent:
;  SRAM_UDP_Tx_DT
;  SRAM_Len	high byte
;  SRAM_Len_Lo
;  SRAM_DestAddr1
;  SRAM_DestAddr0
;  data
;
; Entry: W=IP address, SRAM_Len, SRAM_Len_Lo, SRAM_DestAddr2, SRAM_DestAddr1, SRAM_DestAddr0
; Exit: none, goto UDP_DataSender_RTN
; RAM used:Param70, Param71, Param78, Param79, Param7A, Param7B, Param7C, FSR
; Calls: (1+5) Locate_ARP(1+4), UDP_Send
;
UDP_DataSender	mBank3
	BCF	UDP_DataSent
	mBank0
	MOVWF	remip_b0
;
	mCall3To1	Locate_ARP	;1+1+4
;
	BSF	_RP0	;bank 1
	MOVLW	AS_RESOLVED
	SUBWF	ae_state,W
	BCF	_RP0	;bank 0
	SKPZ		;skip if resolved
	GOTO	UDP_DataSender_RTN	;still pending try again later
;
	mBank3
	BSF	UDP_DataSent
	CALL	Std_UDP_Setup	;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	CLRF	txin
;
;Move kUDP_DataType, length and address (6 bytes) to NIC buffer
;
	MOVLW	low SRAM_UDP_Tx_DT
	MOVWF	FSR
	BSF	_IRP
	MOVF	INDF,W
	CALL	putnic_checkbyte_D18	;SRAM_UDP_Tx_DT
	INCF	FSR,F
	MOVF	INDF,W
	CALL	putnic_checkbyte_D18	;SRAM_Len
	INCF	FSR,F
	MOVF	INDF,W
	CALL	putnic_checkbyte_D18	;SRAM_Len_Lo
;
	INCF	FSR,F	;skip SRAM_DestAddr2
	INCF	FSR,F
	MOVF	INDF,W	;SRAM_DestAddr1
	CALL	putnic_checkbyte_D18
	INCF	FSR,F
	MOVF	INDF,W	;SRAM_DestAddr0
	CALL	putnic_checkbyte_D18
;
;Move Data from SRAM to NIC Buffer
;
	mBank3
	MOVF	SRAM_Len,W
	MOVWF	Param7A
	MOVF	SRAM_Len_Lo,W
	MOVWF	Param79
	MOVF	SRAM_DestAddr2,W
	MOVWF	SRAM_Addr2
	MOVF	SRAM_DestAddr1,W
	MOVWF	SRAM_Addr1
	MOVF	SRAM_DestAddr0,W
	MOVWF	SRAM_Addr0
;	
UDP_DataSender_L3	CALL	SRAM_ReadPI_D18
	CALL	putnic_checkbyte_D18
;
	DECFSZ	Param79,F
	GOTO	UDP_DataSender_L3
;
	MOVF	Param7A,F
	SKPNZ
	GOTO	UDP_DataSender_1
	DECFSZ	Param7A,F
	GOTO	UDP_DataSender_L3
;
UDP_DataSender_1
;end of data check		
	mBank3
	MOVF	SRAM_UDP_Tx_DT,W
	CALL	putnic_checkbyte_D18	;SRAM_UDP_DataType
;
; local and remote port numbers
	MOVLW	high IPDATAPORT
	MOVWF	locport_b1
	MOVWF	remport_b1
	MOVLW	low IPDATAPORT
	MOVWF	locport_b0
	MOVWF	remport_b0
;
	mCall3To1	UDP_Send_E2
	GOTO	UDP_DataSender_RTN
;
;=====================================================================================================
;
Std_UDP_Setup	mBank0
	CLRF	checklo	;checkhi = checklo = 0; 
	CLRF	checkhi
	BCF	checkflag	; checkflag = 0; 
	CLRF	tpxdlen
	CLRF	tpxdlen+1
;hardware protocol
	MOVLW	high PCOL_IP	;0x0800
	MOVWF	nicin.eth.pcol
	MOVLW	low PCOL_IP
	MOVWF	nicin.eth.pcol+1
;
; setnic_addr((TXSTART*256)+sizeof(ETHERHEADER)+IPHDR_LEN+UDPHDR_LEN)
	MOVLW	TXSTART
	MOVWF	Param7B
	MOVLW	ETHERHEADER_LEN+IPHDR_LEN+UDPHDR_LEN
	MOVWF	Param7A
	GOTO	setnic_addr_D18
;
;
;========================================================================================
; Handler for the incoming data at the UDP data port (IPDATAPORT)
;
; Port 87 Private data link port.
;
; Entry:next NIC byte to read is first byte of UDP data field
; Exit: UDP_DataReceived is set if valid data is received
;	SRAM_UDP_DataType, SRAM_Len, SRAM_DestAddr2, SRAM_DestAddr1, SRAM_DestAddr0
; RAM used:
; Calls:(1+)
;
UDP_Data_Handler	MOVF	remip_b0,W
	MOVWF	Param78
	mBank3
	BCF	UDP_DataReceived	;Default to no data
	MOVLW	low SRAM_UDP_Rx_IP
	MOVWF	FSR
	BSF	_IRP
;
	MOVF	Param78,W	; get SRAM_UDP_Rx_IP
	MOVWF	INDF
	INCF	FSR,F
;
	CALL	getch_net_D18	; get SRAM_UDP_Rx_DT
	MOVWF	INDF
	INCF	FSR,F
	CALL	getch_net_D18	; get SRAM_Len_Rx
	MOVWF	INDF
	INCF	FSR,F
	CALL	getch_net_D18	; get SRAM_Len_Lo_Rx
	MOVWF	INDF
	INCF	FSR,F
;
	CALL	getch_net_D18	; get SRAM_DestAddr1_Rx
	MOVWF	INDF
	INCF	FSR,F
	CALL	getch_net_D18	; get SRAM_DestAddr0_Rx
	MOVWF	INDF
;
	BTFSC	atend
	RETURN		; bad data, too short
;
; if length is 0x0000 or > 0x0400 then exit
	mBank3
	MOVFW	SRAM_Len_Rx
	IORWF	SRAM_Len_Lo_Rx,W
	SKPNZ		;Length=0x0000?
	GOTO	UDP_Bank0_Rtn	; Yes
;
	MOVLW	0x05
	SUBWF	SRAM_Len_Rx,W
	SKPB		;Length > 0x04FF?
	GOTO	UDP_Bank0_Rtn	; Yes
	MOVLW	0x04
	SUBWF	SRAM_Len_Rx,W
	SKPZ		;Length < 0x0400?
	GOTO	UDP_Data_Handler_1	; Yes
	TSTF	SRAM_Len_Lo_Rx
	SKPZ		;Length = 0x0400?
	GOTO	UDP_Bank0_Rtn	; No
;
; Move SRAM_Len bytes of data into SRAM
UDP_Data_Handler_1	mBank3
	MOVF	SRAM_Len_Rx,W
	MOVWF	Param7A
	MOVF	SRAM_Len_Lo_Rx,W
	MOVWF	Param79
	MOVLW	kUDP_SRAM_Page
	MOVWF	SRAM_Addr2
	MOVF	SRAM_DestAddr1_Rx,W
	MOVWF	SRAM_Addr1
	MOVF	SRAM_DestAddr0_Rx,W
	MOVWF	SRAM_Addr0
;
UDP_Data_Handler_L3	CALL	getch_net_D18	; get the next data byte
	BTFSC	atend
	RETURN		; bad data, too short
	CALL	SRAM_WritePI_D18
;
	DECFSZ	Param79,F
	GOTO	UDP_Data_Handler_L3
;
	MOVF	Param7A,F
	SKPNZ
	RETURN
	DECFSZ	Param7A,F
	GOTO	UDP_Data_Handler_L3
;
	CALL	getch_net_D18
	BTFSC	atend
	RETURN		; bad data, too short
	mBank3
	SUBWF	SRAM_UDP_Rx_DT,W
	SKPNZ
	BSF	UDP_DataReceived	;tell the world the data has arrived
;
UDP_Bank0_Rtn	mBank0
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
;
