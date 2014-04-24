	subtitle	"HTTPServer.asm"
	page
;===========================================================================================
;
;  FileName: HTTPServer.asm
;  Date: 5/10/09
;  File Version: 1.0
;  
;  Author: David M. Flynn
;  Company: Oxford V.U.E., Inc.
;
;============================================================================================
; Notes:
;
;  This file is the HTTP server.
;  Include this file in *** Segment 3 *** after Ether.asm
;  This file contains no custom routines.
;  The file Ether.asm must have the dispater routines for this file.
;
;  Example Dispaters:
;
;========================
; EGI dispatcher
;	if UseUCEGIs
;LastUCEGI	EQU	'A'
;
;UCEGIDispatch	mPCLGoto
;	GOTO	DoEGI_A
;	endif
;
;LastEGI	EQU	'a'
;
;EGIDispatch	mPCLGoto
;	GOTO	DoEGI_a
;
;LastCGI	EQU	'a'
;
;CGIDispatch	mPCLGoto
;	GOTO	DoCGI_a
;
;LastCGI_Action	EQU	0x01
;
;CGI_ActionDispatch	mPCLGoto
;	GOTO	DoCGI_Action_1
;
;LastHashEGI	EQU	'A'
;
;HashEGIDispatch	mPCLGoto
;	GOTO	DoHashEGI_A
;
;DoCGI_Action_1	... do stuff
;	GOTO	http_recv_CGI
;
;
;==============================================================================================
; Revision History
;
; 1.0     5/10/2009	Added UsesHashEGIs.
; 1.0b1   11/30/2003	Added UseUCEGIs, support for upper case EGIs.
; 1.0a2     8/27/03	Fixed DoCGI_a calculations
; 1.0a1     6/25/03	Copied http_recv from Ether.asm.
;
;==============================================================================================
; Conditionals
	ifndef usesPutNicVolts
	constant	usesPutNicVolts=0
	endif
	ifndef UseUCEGIs
	constant	UseUCEGIs=0
	endif
;
;==============================================================================================
;==============================================================================================
;segment 3 routines
; Name	(additional stack words required) Description
;==============================================================================================
;http_recv	Handle incoming HTTP request.
;http_recv_CGI	We found a ? after the file name, so parse the rest of the request.
;http_recv_1	The CGI's if any have been completed, continue with the filename part of the GET
;tx_file_byte	Transmit a byte from the current i2c file to the NIC
;DoCGI_a	() CGI 'a=' action number
;GetCGIInt16	(1+2) Get an Int16 from the NIC's buffer and put it in Param77:Param76
;EGIADC0Volts
;EGIADC1Volts
;putnic_volts	Send the voltage string for the given ADC to the NIC
;
;==============================================================================================
;==============================================================================================
; Handle incoming HTTP request.
;
; "GET /index.html " or "GET /index.html?"
; The current rev as of 10/22/02 ignores anything after the "?" a future
; rev should have a parser to handle CGI type data from a POST type <form>
; (i.e. "GET /page.html?a=6&b=2")
; 
;
http_recv	mBank0
	CLRF	tpxdlen+1	; tpxdlen = 0; Check for 'GET' 
	CLRF	tpxdlen
; if (match_byte('G') && match_byte('E') && match_byte('T')) 
	MOVLW	'G'	;match_byte('G')
	CALL	match_byteW_D18
	BTFSS	Param78,0
	RETURN
;
	MOVLW	'E'	;match_byte('E')
	CALL	match_byteW_D18
	BTFSS	Param78,0
	RETURN
;
	MOVLW	'T'	;match_byte('T')
	CALL	match_byteW_D18
	BTFSS	Param78,0
	RETURN
;
	MOVLW	' '	; match_byte(' '); 
	CALL	match_byteW_D18
;
	MOVLW	'/'	; match_byte('/'); Start of filename
	CALL	match_byteW_D18
;
	CALL	ZeroFName_D18	;zero filename
;
; for (i=0; i<ROM_FNAMELEN && get_byte(c) && c>' ' && c!='?'; i++) 
	CLRF	Param79	;i=0;
http_recv_L2	CALL	getch_net_D18
	BTFSC	atend
	GOTO	http_recv_1	;atend
; Name terminated by space or '?' 
	MOVLW	'!'	;"!" aka " "+1 or 0x21
	SUBWF	Param78,W	;Char-'!' should not barrow
	BTFSS	STATUS,C
	GOTO	http_recv_1	;<=' '
	MOVLW	'?'	;Next char = '?'
	SUBWF	Param78,W
	BTFSC	STATUS,Z
	GOTO	http_recv_CGI	; yes, there should be arguments next
; romdir.f.name[i] = c; 
	MOVLW	low romdir.f.name
	ADDWF	Param79,W	;i
	MOVWF	FSR
	BSF	STATUS,IRP
	MOVF	Param78,W
	MOVWF	INDF	;(romdir.f.name+Param79)
	INCF	Param79,F
	MOVLW	ROM_FNAMELEN	;Have we read ROM_FNAMELEN chars?
	SUBWF	Param79,W
	BTFSS	STATUS,Z
	GOTO	http_recv_L2	; not yet
;
;Test the ROM_FNAMELEN+1 char for '?' (CGI w/ max len file name)
	CALL	getch_net_D18
	BTFSC	atend
	GOTO	http_recv_1	;atend
	MOVLW	'?'	;Next char = '?'
	SUBWF	Param78,W
	BTFSS	STATUS,Z
	GOTO	http_recv_1	; No
;
;
;==================================================================================
;
; We found a ? after the file name, so parse the rest of the request.
; The format should be "a=20&B=0"
; Only single characters a..z are valid
; Values are 16 bit unsigned (0..65535) or
; text "text chars" is sent as '&c=text+chars&d='
; As each param is pulled from the NICs buffer get the data and
;  process it one piece at a time.
;
http_recv_CGI	CALL	getch_net_D18
	BTFSC	atend
	GOTO	http_recv_1
;
	MOVLW	'a'
	SUBWF	Param78,W	;Char-'a'
	BTFSS	STATUS,C	;skip if Char>='a'
	GOTO	http_recv_1	; chr<'a', cancel CGI
	MOVLW	LastCGI+1	;Last CGI +1
	SUBWF	Param78,W	;Char-('z'+1)
	BTFSC	STATUS,C	;skip if Char<('z'+1)
	GOTO	http_recv_1	; chr>'z', cancel CGI
;	
; We have a char (a..LastCGI)
	MOVF	Param78,W
	MOVWF	Param7C	;Save char for later
;
; The next char must be '=' or we skip CGIs and just work with the GET up to the '?'
;
	CALL	getch_net_D18
	BTFSC	atend
	GOTO	http_recv_1	;atend, cancel CGI
	MOVLW	'='	;Char = '='?
	SUBWF	Param78,W
	BTFSS	STATUS,Z
	GOTO	http_recv_1	; no, Invalid format cancel CGI
;
	MOVLW	'a'
	SUBWF	Param7C,W	;CGI # 0=a, 1=b, etc.
	GOTO	CGIDispatch
;
;===================================================================================================
; The CGI's if any have been completed, continue with the filename part of the GET
;
; if find_file(romdir.f.name)
http_recv_1	CALL	find_file_D18
	BTFSC	Param78,0
	GOTO	http_recv_3
; 
; else File not found, get index.htm 
http_recv_2	BSF	STATUS,RP1	;bank2
	CLRF	romdir.f.name	; romdir.f.name[0] = 0; 
	CALL	find_file_D18	;get index.htm
;
http_recv_3	CLRF	checklo	;checkhi = checklo = 0; 
	CLRF	checkhi
	BCF	checkflag	; checkflag = 0; 
;
	MOVLW	IPHDR_LEN+TCPHDR_LEN	; txin = IPHDR_LEN + TCPHDR_LEN;
	MOVWF	txin
; setnic_addr((TXSTART*256)+sizeof(ETHERHEADER)+IPHDR_LEN+TCPHDR_LEN); 
	MOVLW	TXSTART
	MOVWF	Param7B
	MOVLW	ETHERHEADER_LEN+IPHDR_LEN+TCPHDR_LEN
	MOVWF	Param7A
	CALL	setnic_addr_D18
; if (!fileidx) No files at all in ROM - disaster! 
	MOVF	Param72,F	;fileidx
	BTFSC	STATUS,Z
	GOTO	http_recv_Err	;Z=1 File not found
			;File found OK
	CALL	open_file_D18	; open_file() Start i2c transfer
;
; while (tx_file_byte()) Copy bytes from ROM to NIC 
;
http_recv_L4	CALL	tx_file_byte	;5 (1+1+1+2)
	mBank2
	BTFSS	End_Of_File
	GOTO	http_recv_L4
	CALL	close_file_D18	; close_file();
	GOTO	http_recv_4
;
http_recv_Err	MOVLW	Str_HTTP_FAILPtr	;"HTTP/ 200 OK\r\n\r\nNo Web pages!\r\n"
	mCall3To1	PutString
;
http_recv_4	MOVLW	TFIN+TACK	; tflags = TFIN+TACK;
	MOVWF	tflags
	MOVF	checkhi,W	; d_checkhi = checkhi;Save checksum 
	MOVWF	d_checkhi
	MOVF	checklo,W	; d_checklo = checklo; 
	MOVWF	d_checklo
	mCall3To1	tcp_xmit
	RETURN
;  
;===================================================================================
; Transmit a byte from the current i2c file to the NIC 
; ** Return Param78:0=0 when complete file is sent else Param78:0=1
; ** If file has EGI flag set, perform run-time variable substitution
;
; RAM used: Param77:0 Param78,Param79
; Calls:(1+) i2c_read1_D18
;
; Check if any bytes left to send 
tx_file_byte	CALL	tfb_ReadNextB
	BTFSC	End_Of_File	;we're done with this file?
	RETURN		;yes
; Get next byte from ROM 
	BTFSS	EGI_ATVARS_bit	; This file uses EGI_ATVARS
	GOTO	tfb_NoAtEGIs	; No
	MOVLW	'@'
	SUBWF	Param78,W
	BTFSS	STATUS,Z	; This char is "@"
	GOTO	tfb_NoAtEGIs	;no
; If '@' and EGI var substitution.. 
; ..get 2nd byte 
	CALL	tfb_ReadNextB	;Param78 = i2c_read(1);
	BTFSC	End_Of_File	;we're done with this file?
	RETURN		;yes;
;
;todo! if fileidx=nn then do filenn EGIs else CommonEGIs
;  this may become necessary later.
;
;bank 2 was selected by tfb_ReadNextB
	mBank0
;
	if UseUCEGIs
; EGI's @A..@LastUCEGI
;
	MOVLW	LastUCEGI+1
	SUBWF	Param78,W	;W=EGI-(LastUCEGI+1)
	SKPB		;EGI>LastUCEGI?
	GOTO	UnknownUCEGI	; Yes
	MOVLW	'A'	;first EGI
	SUBWF	Param78,W	;W=EGI-'A'
	SKPB		;EGI>='A'?
	GOTO	UCEGIDispatch	; Yes
UnknownUCEGI
	endif
; EGI's @a..@LastEGI
;
	MOVLW	LastEGI+1
	SUBWF	Param78,W	;W=EGI-(LastEGI+1)
	SKPB		;EGI>LastEGI?
	GOTO	UnknownEGI	; Yes
	MOVLW	'a'	;first EGI
	SUBWF	Param78,W	;W=EGI-'a'
	SKPB		;EGI>='a'?
	GOTO	EGIDispatch	; Yes
; else Unknown variable 
; putnic_checkbyte, "??" 
UnknownEGI	MOVLW	'?'
	MOVWF	Param78
	CALL	putnic_checkbyte_D18
	GOTO	tx_file_byte_Send	; fall through for the second "?"
;
;
	if UsesHashEGIs
;==================================================================================
; Handle the hash egi's  <!--#A--> .. <!--#z-->
tfb_NoAtEGIs	BTFSS	EGI_HASHVARS_bit	; yes bank=1
	GOTO	tx_file_byte_Send
	MOVLW	'<'
	SUBWF	Param78,W
	BTFSS	STATUS,Z	; This char is "<"?
	GOTO	tx_file_byte_Send	;no
;
; It must start with "<!--#" or its not a hash var
; Test for a "!"
	CALL	tfb_ReadNextB	;Param78 = i2c_read(1);
	BTFSC	End_Of_File	;we're done with this file?
	RETURN		;yes
	MOVLW	'!'
	SUBWF	Param78,W
	BTFSS	STATUS,Z	; This char is "!"?
	GOTO	HashNormalTag	;no, must be a normal tag
;
; Test for a "-"
	CALL	tfb_ReadNextB	;Param78 = i2c_read(1);
	BTFSC	End_Of_File	;we're done with this file?
	RETURN		;yes
	MOVLW	'-'
	SUBWF	Param78,W
	BTFSS	STATUS,Z	; This char is "-"?
	GOTO	HashFalseStart	;no, must be an html comment
;
; Test for another "-"
	CALL	tfb_ReadNextB	;Param78 = i2c_read(1);
	BTFSC	End_Of_File	;we're done with this file?
	RETURN		;yes
	MOVLW	'-'
	SUBWF	Param78,W
	BTFSS	STATUS,Z	; This char is "-"?
	GOTO	HashFalseStart	;no, must be an html comment
;
; Test for a "#"
	CALL	tfb_ReadNextB	;Param78 = i2c_read(1);
	BTFSC	End_Of_File	;we're done with this file?
	RETURN		;yes
	MOVLW	'#'
	SUBWF	Param78,W
	BTFSS	STATUS,Z	; This char is "#"?
	GOTO	HashFalseStart	;no, must be an html comment
;
; Get the hash value and store it in Param79
	CALL	tfb_ReadNextB	;Param78 = i2c_read(1);
	BTFSC	End_Of_File	;we're done with this file?
	RETURN		;yes
	MOVF	Param78,W
	MOVWF	Param79
;
; kill all other chars including the closing ">"
HandleHashEGIs_L1	CALL	tfb_ReadNextB	;Param78 = i2c_read(1);
	BTFSC	End_Of_File	;we're done with this file?
	RETURN		;yes
	MOVLW	'>'
	SUBWF	Param78,W
	BTFSS	STATUS,Z	; This char is ">"?
	GOTO	HandleHashEGIs_L1	;no, keep looking
;
;bank 2 was selected by tfb_ReadNextB
	mBank0
; EGI's <!--#A--> .. <!--#B--> (LastHashEGI)
;
	MOVLW	LastHashEGI+1
	SUBWF	Param79,W	;W=EGI-(LastEGI+1)
	SKPB		;EGI>LastEGI?
	RETURN		; Yes
	MOVLW	'A'	;first EGI
	SUBWF	Param79,W	;W=EGI-'a'
	SKPB		;EGI>='a'?
	GOTO	HashEGIDispatch	; Yes
;
; Unrecognized #EGI
	RETURN
;
;"<!" it must be an html comment
HashFalseStart	MOVF	Param78,W
	MOVWF	Param79
	MOVLW	'<'	; Put the "<"
	CALL	putnic_checkbyte_D18
	MOVLW	'!'
	CALL	putnic_checkbyte_D18
	MOVF	Param79,W
	MOVWF	Param78
	GOTO	tx_file_byte_Send
;
HashNormalTag	MOVF	Param78,W
	MOVWF	Param79
	MOVLW	'<'	; Put the "<"
	CALL	putnic_checkbyte_D18
	MOVF	Param79,W
	MOVWF	Param78
	else
tfb_NoAtEGIs
	endif
;
; else Non-EGI byte; send out unmodified 
tx_file_byte_Send	MOVF	Param78,W
	GOTO	putnic_checkbyte_D18
;
;=======================================
; CAUTION  Returns with Bank 2 selected
;
tfb_ReadNextB	mCall3To0	i2c_read1	;next file byte >> Param78
	BSF	STATUS,RP1	; Bank 2
	MOVF	romdir.f.len,W
	IORWF	romdir.f.len+1,W
	BTFSS	STATUS,Z
	GOTO	tfb_ReadNextB_1
	BSF	End_Of_File	;read past end return 0
	RETURN
tfb_ReadNextB_1	MOVF	romdir.f.len,W	; romdir.f.len--; Decrement length
	BTFSC	STATUS,Z
	DECF	romdir.f.len+1,F
	DECF	romdir.f.len,F
	RETURN
;
;
;==============================================================================================
; CGI 'a=' action number
; Convert text to an Int16 at Param77:Param76
;
DoCGI_a	CALL	GetCGIInt16
;
; Now do something based on the value in Param76.
;
	TSTF	Param77
	SKPZ
	GOTO	http_recv_CGI	;>255 not valid
	TSTF	Param76
	SKPNZ
	GOTO	http_recv_CGI	;0x00 not valid
	MOVLW	LastCGI_Action+1
	SUBWF	Param76,W	;W=CGIValue-(LastCGI_Action+1)
	SKPB		;skip if action#<(LastCGI_Action+1)
	GOTO	http_recv_CGI
;
	DECF	Param76,W	;0..N
	GOTO	CGI_ActionDispatch
;
;
;=========================================================================================
; Get an Int16 from the NIC's buffer and put it in Param77:Param76
; Exits when EOD or chr & or ' ' or <'0' or >'9'
;
; Entry: next char in NIC buffer is first char of data
; Exit: Int16 in Param77:Param76
;       atend=1 or the next char is the name of the next CGI
; RAM Used:Param73, Param74, Param75, Param76, Param77, Param78
; Calls: (1+2) getch_net_D18
;
; get first data char
GetCGIInt16	CLRF	Param76
	CLRF	Param77
GetCGIInt16_L1	CALL	getch_net_D18
	BTFSC	atend
	RETURN		;atend, we're done with this number
;
	MOVLW	'&'	;Char = '&'?
	SUBWF	Param78,W
	SKPNZ
	RETURN
;
	MOVLW	' '	;Char = ' '?
	SUBWF	Param78,W
	SKPNZ
	RETURN
;
	MOVLW	'0'
	SUBWF	Param78,W	;Char-'0'
	SKPNB		;skip if Char>='0'
	RETURN		; chr<'0', cancel CGI
	MOVLW	0x3A	;'9'+1
	SUBWF	Param78,W	;Char-('9'+1)
	SKPB		;skip if Char<('9'+1)
	RETURN		; chr>'9', cancel CGI
; valid char 0..9
; val = (val * 10) + (char - '0'); 
	MOVLW	0x09	;add 9 times + the original
	MOVWF	Param73	; i:=9
	MOVF	Param76,W	;temp:=val
	MOVWF	Param74
	MOVF	Param77,W
	MOVWF	Param75
GetCGIInt16_L2	MOVF	Param74,W	;val:=val+temp
	ADDWF	Param76,F
	ADDCF	Param77,F
	MOVF	Param75,W
	ADDWF	Param77,F
	DECFSZ	Param73,F
	GOTO	GetCGIInt16_L2
;
	MOVLW	'0'
	SUBWF	Param78,W	;Char-'0'
	ADDWF	Param76,F
	ADDCF	Param77,F
;
	GOTO	GetCGIInt16_L1
;
;==============================================================================================
	if usesPutNicVolts
;**************************
;  ADC0 volts n.n format
;**************************
;
; putnic_volts(adc0); 
EGIADC0Volts	BSF	STATUS,RP1	; Bank 2
	MOVF	adc0MSB,W
	MOVWF	nrator1
	MOVF	adc0LSB,W
	MOVWF	nrator0
	GOTO	putnic_volts
;
;**************************
;  ADC1 volts n.n format
;**************************
;
; putnic_volts(adc1); 
EGIADC1Volts	BSF	STATUS,RP1	; Bank 2
	MOVF	adc1MSB,W
	MOVWF	nrator1
	MOVF	adc1LSB,W
	MOVWF	nrator0
	GOTO	putnic_volts
;
;=======================================================================================
;  Send the voltage string for the given ADC to the NIC
; 	
;  v = (val / 21); 0..48 >> 0.0 .. 4.8
;
putnic_volts	BSF	STATUS,RP1	; Bank 2
	CLRF	denom1	; clear high byte
	MOVLW	0x15	; 21
	MOVWF	denom0
	mCall3To0	Div16x16	; /21
; putnic_checkbyte(v/10 + '0'); 
	BSF	STATUS,RP1	;bank2
	MOVF	result0,W	;0..48
	MOVWF	Param77
	MOVLW	0x0A
	MOVWF	Param79
	CALL	Fix_decbyte_D18
	MOVLW	'0'
	ADDWF	Param78,W	;0..4
	CALL	putnic_checkbyte_D18

	MOVLW	'.'	; putnic_checkbyte('.'); 
	CALL	putnic_checkbyte_D18
; putnic_checkbyte(v%10 + '0'); 
	MOVLW	'0'
	ADDWF	Param77,W	;the remainder 0..9
	GOTO	putnic_checkbyte_D18
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
;
;
;
;
;
;
;
