	subtitle	"HIGY.Routes.asm"	page;===========================================================================================;;  FileName: HIGY.Routes.asm;  Date: 9/18/04;  File Version: 2.0;  ;  Author: David M. Flynn;  Company: Highland Pacific Railroad;;============================================================================================; Notes:;;  This file is the route selector for Highlad Greeley;;============================================================================================; Revision History;; 2.0     9/18/04	Start of conversion from 6502;;============================================================================================; Conditionals;;============================================================================================;; Name	(additional stack words required) Description;============================================================================================;SetLocalRoute	Highland Greeley Route SELECTOR;Get_SMBits_Y	W=(SMBits,Y);Set_SMBits_X	(SMBits,X)=Param78;Get_SMBits2_Y	W=(SMBits2,Y);Set_SMBits2_Y	(SMBits2,Y)=Param78;Check4Conflict	Check for a conflict between a new requested route (SMBits) and the other active routes (SMBits2);SetMLRoute	Setup one MainLine Route;TestStackEmpty	Z set if empty;SetRT	Set Route W=Route Number;  DoGotoLongCmd;  DoGosubCmd;  DoGosubLongCmd;SMToPTR	Convert an SM number in W to Address in CurBlk;RlyToPtr	Convert Relay number in W to Output Number in CurBlk;ClrRT	Clear Route;FindAllUsedSMs	Find all the used SMs in all active routes (SMBits  2 bits per SM );FINDSMS	Find a SM in active routes;GetRTTempY	Get data from SRAM (RTTemp),Y;RTTOPTR	W=Route# 0..255;GetPtrTempY	Param78,W = (PtrTemp+evDataROM+Y);DoSMSet	W= SM#, Param79,0=MSb of SM#;============================================================================================; Highland Greeley Route SELECTOR ;; **** Set Local Route ****;; Entry: W=Route#, ; Exit:; Calls:(1+6) FindAllUsedSMs(6), Get_SMBits_Y, Set_SMBits2_Y, SetRT, OutputB_D10; RAM Used: Param78, Param79;SetLocalRoute	MOVWF	Param79	MOVF	OLOC,W	MOVWF	SaveOldLocal		CLRF	OLOC	CALL	FindAllUsedSMs	;find the used SMs in the ML;	MOVLW	0x0B	; for Y:=11 downto 0	MOVWF	YReg	; routes and move them toSetLcRT1	CALL	Get_SMBits_Y	CALL	Set_SMBits2_Y	; here	DECF	YReg,F	BTFSS	YReg,7	GOTO	SetLcRT1;	MOVFW	Param79	MOVWF	OLOC;	MOVFW	OML1	MOVWF	SaveOldML1		CLRF	OML1;	MOVFW	OML2	MOVWF	SaveOldML2		CLRF	OML2;	MOVFW	OML3	MOVWF	SaveOldML3		CLRF	OML3;	CALL	FindAllUsedSMs	;find the used SMs in the 	MOVF	SaveOldML1,W	; requested local rt	MOVWF	OML1	MOVF	SaveOldML2,W	MOVWF	OML2	MOVF	SaveOldML3,W	MOVWF	OML3	CALL	Check4Conflict	BTFSC	SMFound	GOTO	SetLcRT3;	MOVF	SaveOldLocal,W	;no Conflict	CALL	ClrRT	BSF	LEDLocalReady	MOVF	OLOC,W	CALL	SetRT	GOTO	SetLocalRoute_RTN;SetLcRT3	MOVF	SaveOldLocal,W	;rout conflict	MOVWF	OLOC; why was this here?	CALL	SetRTDoLocalUnable	MOVLW	low LocalUnable	MOVWF	CurBlk	MOVLW	high LocalUnable	MOVWF	CurBlk+1	BSF	OActive,7	BSF	LEDLocalUnable	BCF	LEDLocalReady	CALL	OutputB_D10;	if UsesSpeaker	CALL	Beep_D10	endif	GOTO	SetLocalRoute_RTN;;==================================================================================================; Entry: YReg; Exit:  W=(SMBits,Y); Calls: none; Ram used:FSR;Get_SMBits_Y	MOVLW	SMBits	ADDWF	YReg,W	MOVWF	FSR	BankISel	SMBits	MOVF	INDF,W	RETURN;;==================================================================================================; Entry: W=data, XReg=offset 0..B; Exit:  (SMBits,X)=Param78; Calls: none; Ram used:FSR;Set_SMBits_X	MOVWF	Param78	MOVLW	SMBits	ADDWF	XReg,W	MOVWF	FSR	BankISel	SMBits	MOVF	Param78,W	MOVWF	INDF	RETURN;;==================================================================================================; Entry: YReg; Exit:  W=(SMBits2,Y); Calls: none; Ram used:FSR;Get_SMBits2_Y	MOVLW	SMBits2	ADDWF	YReg,W	MOVWF	FSR	BankISel	SMBits2	MOVF	INDF,W	RETURN;;==================================================================================================; Entry: Param78, YReg; Exit:  (SMBits2,Y)=Param78; Calls: none; Ram used:FSR;Set_SMBits2_Y	MOVWF	Param78	MOVLW	SMBits2	ADDWF	YReg,W	MOVWF	FSR	BankISel	SMBits2	MOVF	Param78,W	MOVWF	INDF	RETURN;;==================================================================================================;Check for a conflict between a new requested route (SMBits); and the other active routes (SMBits2); return SMFound=1 if conflict else 0;; Entry: SMBits, SMBits2; Exit: SMFound=1=conflict; RAM used: Param78,Param79,Param7A,Param7B,Param7C,FSR; Calls:(1+0) Get_SMBits_Y, Get_SMBits2_Y, Check4Conflict_4;Check4Conflict	BCF	SMFound	;assume no conflict	MOVLW	0x0B	;for Y:=11 downto 0	MOVWF	YReg;Check4Conflict_L1	CALL	Get_SMBits_Y	;4 SMs from requested route	SKPNZ	GOTO	Check4Conflict_2	;none are used so don't test;	MOVWF	Param7A	;new SM's	CALL	Get_SMBits2_Y	MOVWF	Param7B	;existing route's SMs	MOVLW	0x04	MOVWF	Param7C;Check4Conflict_L2	MOVLW	0x03	ANDWF	Param7A,W	SKPNZ	GOTO	Check4Conflict_1	;  not used	MOVWF	Param79	;save those 2 bits	MOVLW	0x03	ANDWF	Param7B,W	SKPZ	CALL	Check4Conflict_4;Check4Conflict_1	RRF	Param7A,F	RRF	Param7A,F	RRF	Param7B,F	RRF	Param7B,F	DECFSZ	Param7C,F	GOTO	Check4Conflict_L2;Check4Conflict_2	BTFSC	SMFound	RETURN	DECF	YReg,F	BTFSS	YReg,7	GOTO	Check4Conflict_L1	RETURN;;we got here because both sets of bits are non zero;  the requested route's bits are in Param79 and the established route's are in the W;If the established route uses the SM with SetSM or ClrSM then it is a conflict; 00=not found, 10=set or cleared, 01=cleared by ClrSMNU, 11=set by SetSMNU;Check4Conflict_4	MOVWF	Param78	SUBLW	0x02	;SetSM or ClrSM	SKPNZ	GOTO	Check4Conflict_3;If the requested route uses the SM with SetSM or ClrSM then it is a conflict	MOVF	Param79,W	SUBLW	0x02	;SetSM or ClrSM	SKPNZ	GOTO	Check4Conflict_3;If both are not the same SetSMNU or ClrSMNU that is a conflict	MOVF	Param79,W	SUBWF	Param78,W	SKPZ;Check4Conflict_3	BSF	SMFound	RETURN;;================================================================================================;Setup one MainLine Route;; Entry: W=route number; Exit: none; RAM used: Param7A; Calls: ;SetMLRoute	MOVWF	Param7A	SUBWF	OML1,W	SKPNZ		;same as Old ML 1?	GOTO	SetMLRoute_RTN	; Yes;	MOVF	Param7A,W	SUBWF	OML2,W	SKPNZ		;same as Old ML 2?	GOTO	SetMLRoute_RTN	; Yes;	MOVF	OML3,F	SKPZ		;At least 1 ML route unused?	GOTO	SetMLRoute_RTN	; no;	CALL	FindAllUsedSMs	MOVFW	OML1	MOVWF	SaveOldML1		MOVF	Param7A,W	MOVWF	OML1;	MOVFW	OML2	MOVWF	SaveOldML2		CLRF	OML2;	MOVFW	OLOC	MOVWF	SaveOldLocal		CLRF	OLOC;	MOVLW	0x0C	MOVWF	YRegSetML1RT_L1	CALL	Get_SMBits_Y	CALL	Set_SMBits2_Y	DECFSZ	YReg,F	GOTO	SetML1RT_L1;	CALL	FindAllUsedSMs;	MOVFW	SaveOldLocal	MOVWF	OLOC	MOVFW	SaveOldML1	MOVWF	OML1	MOVFW	SaveOldML2	MOVWF	OML2	CALL	Check4Conflict	BTFSC	SMFound	GOTO	DoMLUnable	BTFSC	SMFound2	GOTO	DoMLUnable;;	MOVF	Param7A,W	MOVF	OML1,F	SKPZ	GOTO	SetML1RT2_1	MOVWF	OML1	;no Conflict	CALL	SetRT	GOTO	SetMLRoute_RTN;SetML1RT2_1	MOVF	OML2,F	SKPZ	GOTO	SetML1RT2_2	MOVWF	OML2	CALL	SetRT	GOTO	SetMLRoute_RTN;SetML1RT2_2	MOVWF	OML3	CALL	SetRT	GOTO	SetMLRoute_RTN;	;	DoMLUnable	MOVLW	low MainlineUnable	MOVWF	CurBlk	MOVLW	high MainlineUnable	MOVWF	CurBlk+1	BSF	OActive,7	BSF	LEDMainlineUnable	CALL	OutputB_D10	if UsesSpeaker	GOTO	Beep_D10	endif	GOTO	SetMLRoute_RTN;;================================================================================================; Entry: none; Exit: Z; RAM used:; Calls:(0) none;TestStackEmpty	MOVF	StackPtr,F	RETURN;;=================================================================================================; ***** Set Route *****; Entry: W=Route Number; Exit: none; RAM used:; Calls:()  ;SetRT	IORLW	0x00	SKPNZ	RETURN;	CALL	RTTOPTR	;returns Y=0SetRTA_1	CLRF	YReg;;SetRT0	CALL	GetRTTempY;;do ReturnCmd command	MOVF	Param78,W	SUBLW	ReturnCmd	SKPZ	GOTO	SetRT1;	CALL	TestStackEmpty	;Stack empty?	SKPNZ			RETURN		; Yes;	CALL	Pop_D10	;No, Pop Hi ptr	MOVWF	RTTemp+1	CALL	Pop_D10	;Low ptr	MOVWF	RTTemp	GOTO	SetRTA_1;;;Do Gosub commandSetRT1	MOVF	Param78,W	SUBLW	gosub	SKPZ	GOTO	SetRT2;	CALL	DoGosubCmd	GOTO	SetRT;;Do Gosub Long commandSetRT2	MOVF	Param78,W	SUBLW	gosubLong	SKPZ	GOTO	SetRT3;	CALL	DoGosubLongCmd	GOTO	SetRTA_1;;Do Goto commandSetRT3	MOVF	Param78,W	SUBLW	gotoCmd	SKPZ	GOTO	SetRT4;	INCF	YReg,F	CALL	GetRTTempY	GOTO	SetRT;;Do Goto Long commandSetRT4	MOVF	Param78,W	SUBLW	gotoLong	SKPZ	GOTO	SetRT5;	CALL	DoGotoLongCmd	GOTO	SetRTA_1	;;Do Rotate Turn Table CommandSetRT5	MOVF	Param78,W	SUBLW	RotateTT	SKPZ	GOTO	SetRT6;	INCF	YReg,F	;Skip Hi byte	INCF	YReg,F	CALL	GetRTTempY	MOVWF	SCount	INCF	YReg,F	CALL	GetRTTempY	MOVWF	SCount+1	INCF	YReg,W	ADDWF	RTTemp,F	ADDCF	RTTemp+1,F;	mCall2To3	TTDoRotate	GOTO	SetRTA_1;;Do Set or Clear commandSetRT6	MOVF	Param78,W	MOVWF	OActive	ANDLW	ClrSM	;SM cmd's have lo bit=1	SKPNZ		;Is an SM Cmd?	GOTO	SetRT7	; No;; SetRT treats ClrSM and ClrSMNU the same.	INCF	YReg,F	CALL	GetRTTempY	;Get offset to SM table	CALL	SMToPTR	;CurBlk=(Ptr);	INCF	YReg,W	;RTTemp+=YReg	ADDWF	RTTemp,F	ADDCF	RTTemp+1,F;	MOVLW	0x00	BTFSC	OActive,7	MOVLW	SMCMDMask	MOVWF	Param7C	MOVLW	RealSMNum+1	MOVWF	YReg	CALL	GetCurBlkY_D10	MOVWF	Param79	;MSB of SMnum	DECF	YReg,F	CALL	GetCurBlkY_D10	CALL	DoSMSet;	GOTO	SetRTA_1;;Do Set or Clear Relay commands (4)SetRT7	INCF	YReg,F	CALL	GetRTTempY	CALL	RlyToPtr	INCF	YReg,W	ADDWF	RTTemp,F	ADDCF	RTTemp+1,F	CALL	OutputB_D10	GOTO	SetRTA_1;;;=====================================================================================;DoGotoLongCmd	INCF	YReg,F	INCF	YReg,F	CALL	GetRTTempY	MOVWF	Param79	INCF	YReg,F	CALL	GetRTTempY	MOVWF	RTTemp+1	MOVFW	Param79	MOVWF	RTTemp	RETURN;;=====================================================================================;; Calls:(1+2) Push(2);DoGosubCmd	MOVF	YReg,W	ADDLW	0x02	ADDWF	RTTemp,W	mCall2To0	Push	;low ptr	mBank3	ADDCF	RTTemp+1,W	mCall2To0	Push	;Hi Ptr	mBank3	INCF	YReg,F	GOTO	GetRTTempY;;=====================================================================================;DoGosubLongCmd	MOVF	YReg,W	ADDLW	0x04	ADDWF	RTTemp,W	mCall2To0	Push	;Push low ptr	mBank3	ADDCF	RTTemp+1,W	mCall2To0	Push	;Push Hi Ptr	mBank3	INCF	YReg,F	;skip dead byte	INCF	YReg,F	;LSB of dest	CALL	GetRTTempY	MOVWF	Param79	INCF	YReg,F	;MSB of dest	CALL	GetRTTempY	MOVWF	RTTemp+1	MOVFW	Param79	MOVWF	RTTemp	RETURN;;=====================================================================================;Convert an SM number in W to Address in CurBlk; CurBlk:=(W-1)*8+FirstSMsData;SMToPTR	MOVWF	CurBlk	DECF	CurBlk,F	;SM:=SM-1	CLRF	CurBlk+1;	CALL	CurBlkX8;	MOVLW	low FirstSMsData	ADDWF	CurBlk,F	ADDCF	CurBlk+1,F	MOVLW	high FirstSMsData	ADDLW	low evDataROM	ADDWF	CurBlk+1,F	RETURN;CurBlkX8	CLRC	RLF	CurBlk,F	;SM:=SM*8	RLF	CurBlk+1,F	RLF	CurBlk,F	RLF	CurBlk+1,F	RLF	CurBlk,F	RLF	CurBlk+1,F	RETURN;;==========================================================================================;Convert Relay number in W to Output Number in CurBlk; CurBlk:=W/128*256+0x1000+(W mod 128);RlyToPtr	MOVWF	CurBlk	MOVWF	CurBlk+1	MOVLW	0x7F	ANDWF	CurBlk,F	MOVLW	0x80	;div 128 * 256	ANDWF	CurBlk+1,F	; keep the high bit	CLRC			RLF	CurBlk+1,F	; roll the high bit	RLF	CurBlk+1,F	; around to the low bit	MOVLW	0x10	;add 0x1000	IORWF	CurBlk+1,F	RETURN;;==========================================================================================;Clear Route;; Entry: Route Number in W; Exit: ;ClrRT	IORLW	0x00	SKPNZ	RETURN;	CALL	RTTOPTRClrRTA_1	CLRF	YReg	ClrRT0	CALL	GetRTTempY; return command	MOVF	Param78,W	SUBLW	ReturnCmd		SKPZ	GOTO	ClrRT1;	CALL	TestStackEmpty	SKPNZ	RETURN	CALL	Pop_D10	;Hi ptr	MOVWF	RTTemp+1	CALL	Pop_D10	;Low ptr	MOVWF	RTTemp	GOTO	ClrRTA_1;;Do GosubClrRT1	MOVF	Param78,W	SUBLW	gosub		SKPZ	GOTO	ClrRT2;	CALL	DoGosubCmd	GOTO	ClrRT;;Do Gosub LongClrRT2	MOVF	Param78,W	SUBLW	gosubLong		SKPZ	GOTO	ClrRT3;	CALL	DoGosubLongCmd	GOTO	ClrRTA_1;;Do gotoCmd commandClrRT3	MOVF	Param78,W	SUBLW	gotoCmd	SKPZ	GOTO	ClrRT4;	INCF	YReg,F	CALL	GetRTTempY	GOTO	ClrRT;;Do Goto Long command	ClrRT4	MOVF	Param78,W	SUBLW	gotoLong	SKPZ	GOTO	ClrRT5;	CALL	DoGotoLongCmd	GOTO	ClrRTA_1	;;Do Rotate Turn Table Command: do nothingClrRT5	MOVF	Param78,W	SUBLW	RotateTT	SKPZ	GOTO	ClrRT6;	INCF	YReg,F	;Hi byte	INCF	YReg,F	;Lo Step	INCF	YReg,F	;Hi Step	INCF	YReg,F	;Next CMD	GOTO	ClrRT0;;Do SetSM and ClrSM command: do nothingClrRT6	MOVF	Param78,W	SUBLW	ClrSM	SKPNZ	GOTO	ClrRT6_1;	MOVF	Param78,W	SUBLW	SetSM	SKPZ	GOTO	ClrRT7;ClrRT6_1	INCF	YReg,F	INCF	YReg,F	GOTO	ClrRT0;;Do SetRlyClrRT7	MOVF	Param78,W	SUBLW	SetRlyNC	SKPNZ	GOTO	ClrRT6_1	;do nothing for SetRlyNC;	MOVF	Param78,W	SUBLW	ClrRly	SKPNZ	GOTO	ClrRT6_1	;do nothing for ClrRly;	MOVF	Param78,W	SUBLW	SetRly	SKPZ	GOTO	ClrRT8;	INCF	YReg,F	CALL	GetRTTempY	CALL	RlyToPtr	INCF	YReg,W	ADDWF	RTTemp,F	ADDCF	RTTemp+1,F	CLRF	OActive	CALL	OutputB_D10	GOTO	ClrRTA_1;;by default must be ClrRlyNS commandClrRT8	INCF	YReg,F	CALL	GetRTTempY	CALL	RlyToPtr	INCF	YReg,W	ADDWF	RTTemp,F	ADDCF	RTTemp+1,F	BSF	OActive,7	CALL	OutputB_D10	GOTO	ClrRTA_1;;===================================================================================================;Find all the used SMs in all active routes;IN: none;OUT: SMBits  2 bits per SM ; 00=not found, 10=set or cleared, 01=cleared by ClrSMNU, 11=set by SetSMNU;; Calls:(0+5) Set_SMBits_X, FINDSMS(5);FindAllUsedSMs	MOVLW	0x0B	;for X:=11 downto 0	MOVWF	XReg;FindAllUsedSMs_L1	MOVLW	0x00	CALL	Set_SMBits_X	;Clear all 96 bits	DECF	XReg,F	BTFSS	XReg,7	GOTO	FindAllUsedSMs_L1;	MOVLW	SMCount+1	;for x:=48 downto 1	MOVWF	SMTempFindAllUsedSMs_L2	BCF	SMFound	BCF	SMFound2	GOTO	FINDSMSFINDSMS_RTN;	MOVLW	0x02	MOVWF	Param78	;2 bits	BCF	_C	BTFSC	SMFound	;1st valid bit to carry	BSF	_C;FindAllUsedSMs_L3		BankSel	SMBits	;bank2	RLF	SMBits,F	RLF	SMBits+1,F	RLF	SMBits+2,F	RLF	SMBits+3,F	RLF	SMBits+4,F	RLF	SMBits+5,F	RLF	SMBits+6,F	RLF	SMBits+7,F	RLF	SMBits+8,F	RLF	SMBits+9,F	RLF	SMBits+10,F	RLF	SMBits+11,F	mBank3	BCF	_C	BTFSC	SMFound2	;2nd valid bit to carry	BSF	_C	DECFSZ	Param78,F	GOTO	FindAllUsedSMs_L3;	DECFSZ	SMTemp,F	GOTO	FindAllUsedSMs_L2	RETURN	;;=================================================================================;Find a SM in active routes;;Entry: SMTemp SM to find;Exit: SMFound:SMFound2; 00=not found, 10=set or cleared, 01=cleared by ClrSMNU, 11=set by SetSMNU;Uses: RTtemp, YReg;; Calls:(1+4) RTTOPTR(0), GetRTTempY(3), TestStackEmpty(0), Pop_D10, DoGosubCmd(4),;	DoGosubLongCmd, DoGotoLongCmd;FINDSMS	MOVF	OLOC,W	CALL	FINDSM	MOVF	OML1,W	CALL	FINDSM	MOVF	OML2,W	CALL	FINDSM	MOVF	OML3,W;FINDSM	IORLW	0x00	SKPNZ	GOTO	FINDSMS_RTN;FINDSMA	CALL	RTTOPTRFINDSMA_1	CLRF	YRegFINDSM0	CALL	GetRTTempY	;SRAM (RTTemp,Y);;do ReturnCmd command	MOVF	Param78,W	SUBLW	ReturnCmd		SKPZ	GOTO	FINDSM1;	CALL	TestStackEmpty	SKPNZ	GOTO	FINDSMS_RTN;	CALL	Pop_D10	;Hi ptr	MOVWF	RTTemp+1	CALL	Pop_D10	;Low ptr	MOVWF	RTTemp	GOTO	FINDSMA_1;;Do Gosub commandFINDSM1	MOVF	Param78,W	SUBLW	gosub		SKPZ	GOTO	FINDSM2;	CALL	DoGosubCmd	GOTO	FINDSMA	;of rout A;;do Gosub Long commandFINDSM2	MOVF	Param78,W	SUBLW	gosubLong		SKPZ	GOTO	FINDSM3;	CALL	DoGosubLongCmd	GOTO	FINDSMA_1	;of rout A;;do gotoCmd commandFINDSM3	MOVF	Param78,W	SUBLW	gotoCmd	SKPZ	GOTO	FINDSM4;	INCF	YReg,F	CALL	GetRTTempY	GOTO	FINDSM	;;do gotoLong commandFINDSM4	MOVF	Param78,W	SUBLW	gotoLong	SKPZ	GOTO	FINDSM5;	CALL	DoGotoLongCmd	GOTO	FINDSMA_1	;;do SetSM or ClrSM commandFINDSM5	MOVF	Param78,W	SUBLW	ClrSM	SKPNZ	GOTO	FINDSM5_1;	MOVF	Param78,W	SUBLW	SetSM		SKPZ	GOTO	FINDSM6;FINDSM5_1	INCF	YReg,F	CALL	GetRTTempY	SUBWF	SMTemp,W	SKPNZ	BSF	SMFound	GOTO	FINDSM8_1;;do SetSMNU or ClrSMNU commandFINDSM6	MOVF	Param78,W	SUBLW	ClrSMNU	SKPZ	GOTO	FINDSM7;	INCF	YReg,F	CALL	GetRTTempY	SUBWF	SMTemp,W	;is this the SM we're looking for?	SKPNZ	BSF	SMFound2	;Yes	GOTO	FINDSM8_1;FINDSM7	MOVF	Param78,W	SUBLW	SetSMNU	SKPZ	GOTO	FINDSM8	;must be SetRly or ClrRly;	INCF	YReg,F	CALL	GetRTTempY	SUBWF	SMTemp,W	;is this the SM we're looking for?	SKPZ	GOTO	FINDSM8_1	;No	BSF	SMFound	;Yes	BSF	SMFound2	GOTO	FINDSM8_1;;ignor set and clr rly commands (4)FINDSM8	INCF	YReg,FFINDSM8_1	INCF	YReg,F	GOTO	FINDSM0;;=========================================================================================; Get data from SRAM (RTTemp),Y;; Entry: YReg, bank3; Exit: Param78 & W = RTTemp Data, Bank3; RAM Used: YReg, Param78; Calls: (0+3) SRAM_Read_D10;;6502:	LDA	(RTTemp),Y;PIC16:	CALL	GetRTTempY;GetRTTempY	MOVF	RTTemp+1,W	ADDLW	low evDataROM	MOVWF	SRAM_Addr1	MOVF	RTTemp,W	ADDWF	YReg,W	MOVWF	SRAM_Addr0	ADDCF	SRAM_Addr1,F	GOTO	GetGet_Read_D10;;=============================================================================================;Entry: W=Route# 0..255,;Exit: RTTemp=Route Pointer to SRAM Data;; Calls:(0) None;RTTOPTR	BCF	_C	CLRF	PtrTemp+1	MOVWF	PtrTemp	RLF	PtrTemp,F	;RT:=RT*2	RLF	PtrTemp+1,F;	MOVLW	low PRT00	;RT:=RT+offsetToPRT00	ADDWF	PtrTemp,F	ADDCF	PtrTemp+1,F	MOVLW	high PRT00	ADDWF	PtrTemp+1,F;	CLRF	YReg	;RTTemp=(PtrTemp+evDataROM)	CALL	GetPtrTempY	MOVWF	RTTemp	INCF	YReg,F	CALL	GetPtrTempY	MOVWF	RTTemp+1	RETURN;;=========================================================================================; Get data from SRAM (PtrTemp),Y;; Entry: YReg, bank3; Exit: Param78 & W = SMData, Bank3; RAM Used: YReg, Param78; Calls: (0+3) SRAM_Read;;6502:	LDA	(PtrTemp),Y;PIC16:	CALL	GetPtrTempY;GetPtrTempY	MOVF	PtrTemp+1,W	ADDLW	low evDataROM	MOVWF	SRAM_Addr1	MOVF	PtrTemp,W	ADDWF	YReg,W	MOVWF	SRAM_Addr0	ADDCF	SRAM_Addr1,F	GOTO	GetGet_Read_D10;;=============================================================================================; Entry:W= SM #, Param79=MSb of SM#, Param7C=SMCMDMask or 0x00;; Calls:(1+3) GetSMTableX_D10, GetSMTableHighX_D10, SetSMTableX_D10, SetSMTableHighX_D10;DoSMSet	MOVWF	XReg	BTFSS	Param79,0	;High SM?	CALL	GetSMTableX_D10	; No	BTFSC	Param79,0	;High SM?	CALL	GetSMTableHighX_D10	; Yes	ANDLW	SMCnFMask	;Keep Control and FB bits	IORWF	Param7C,W	;Combine w/ CMD bit	IORLW	b'00000001'	;Set Valid Data Flag	MOVWF	Param78	ANDLW	0xC0	;Ctrl and Cmd	SKPNZ		;Both off?	RETURN		; Yes;	MOVF	Param78,W	XORLW	0xC0	;Ctrl and Cmd	SKPNZ		;Both on?	RETURN		; Yes;	MOVF	Param78,W	BTFSS	Param79,0	;High SM?	BSF	SMTableLowChngFlag	; No	BTFSC	Param79,0	;High SM?	BSF	SMTableHiChngFlag	; Yes	BTFSS	Param79,0	;High SM?	GOTO	SetSMTableX_D10	; No	GOTO	SetSMTableHighX_D10	; Yes;