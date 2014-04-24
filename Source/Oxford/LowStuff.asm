	subtitle	"LowStuff.asm"
	page
;===========================================================================================
;
;  FileName: LowStuff.asm
;  Date: 5/25/09
;  File Version: 1.8.3
;  
;  Author: David M. Flynn
;  Company: Oxford V.U.E., Inc.
;
;============================================================================================
; Notes:
;
;  This file is all general perpose routines.
;  Custom stuff is in Main.asm
;     OnTheTick is called every 1/20th second
;     OnTheHalfSecond is Goto'd every 1/2 second
;
;  I2C EEPROMs
;    The brain has 8 medium width SOIC ICs at U2..U9 with hardware addresses of 0..7.
;    These locations may be populated with 24LC256 I/SM 256Kb (32K x 8) serial EEPROMs
;    with 64 bytes per page or 24LC512 I/SM 512Kb (64K x 8) serial EEPROMs with 128 bytes per page.
;    All the chips installed must be the same.
;    EEPROMs must be installed in 64KB increments.
;    The routines in this file do NOT test for writes across page boundies.
;    Default is to use 15+3 bit addressing for 24LC256s. Set Using64KBEEPROM to 1 by
;    defining the constant Using64KBEEPROM=1 to use 16+3 bit addressing.
;    EndOfEEROM defaults to 0x01 for 64Kbytes of eeprom set to 0x02 for 128BK, 0x03 for 192KB, etc.
;
;  Calls/gotos to routines outside this segment:
;
;	if CodeMemStrings
;	mCall0To2	StringDispatch	;Get the next Char
;	endif
;
;	mCall0To2	OnTheTick	;call every 1/20th sec
;
;	GOTO	Main	; go to beginning of program
;
;	BSF	PCLATH,4
;	GOTO	OnTheHalfSecond
;
;============================================================================================
; Revision History
; 1.8.3     5/25/2009	Added conditional Do_ZeroRAM
; 1.8.2     4/6/2009	Changed conditional UsesLCD>>PrintString
; 1.8.1     12/16/2008	Added support for 24AA02E48 HasMAC_Addr_EEPROM=1
; 1.8       4/5/2008	Added UsesPulseCounter1/2 Pulse counters on CCP1/CCP2
; 1.7.11    5/7/2006	Fixed RS232BufIO.
; 1.7.10    5/6/06	Moved UsesRS232BufIO vars to bank3, made ScanRS232In interupt driven.
; 1.7.9     10/6/05	Added support for ServoControl.asm, UsesServoControl
; 1.7.8     3/29/05	Added UsesPushPopParams,UsesSRamPushPopPrm, minor improvments to Push and Pop.
; 1.7.7     3/13/05	Fixed SRAM_Zero problem with CurrentAddress buffers
; 1.7.6     2/7/05	Changed some mBank0's to CLRF STATUS to save a byte
;	Added some conditionsal's (opt-in type) UsesDelay10uS, UsesDelay40uS,
;	 UsesLCDBlink, UsesLCDClear, UsesLCDCursoBlink, Useslcd_Home, Useslcd_ReadData
;
; 1.7.5     1/27/05	Fixed EraseEEROM:clear ptr to point to last byte in Data, 0x007FFF
; 1.7.4     1/16/05	Added comments.
; 1.7.3     9/21/04	Added some conditionals:UsesByte2Str,UsesDateToBCD,UsesNum2Str,UsesNum3BToStr
; 1.7.2     9/5/04	Moved RTC equ's into this file.
; 1.7.1     8/2/04	Added DispIPLine defaults to 1.
; 1.7       4/28/04	Added AddressEEROMR, CopyEEROMtoSRAM, changed AddressEEROM
;	Added Using64KBEEPROM, EndOfEEROM
;	The maximum EEROM size is now 512KB (8 x 24LC512I/SM)
; 1.6       3/31/04	Added Display_Colon, Display_Dot, DispIP, DispMAC.
; 1.5.18    1/27/04	Added InitLCDAtStartup defalts to 1.
; 1.5.17    1/19/04	Fixed a goto in "if ShowSplashScrn else ... "
;	Changed StandardInits no longer shows the SIGNONStr when ShowSplashScrn=1
; 1.5.16    12/25/03	Changed DispDec2pl, DispDec3pl, BtnDebounce and ClrLine to #Define
; 1.5.15    12/8/03	Changed SendRS232,SendToLCD to #Define
;	Added lcd_SetDDRamAddress, lcd_ReadData
;	Moved write of LDO's before read of LDI's
; 1.5.14    11/30/03	Added Disp_decbyteW3pl and Disp_decbyteW2pl
; 1.5.13    11/24/03	Added Timer Finished routine calls for timers >=2. constant UsesTimerFinished
; 1.5.12    11/15/03	Added ifndef for UsesMAX110, Fixed SRAM test bug.
; 1.5.11    10/12/03	Changed ISR timers so ISR_Timers can be any value
; 1.5.10    9/3/03	Added Disp_NLS to work with Disp_LZO to kill spaces
; 1.5.9     8/29/03	Added Disp_LZO option to Disp_dec3B
; 1.5.8     8/24/03	Moved to MathStuff.asm:Div24x0A,Div16x16
; 1.5.7     8/15/03	Added SRAM_ReadDR.
; 1.5.6     6/23/03	Added Call ScrollStringIdle
; 1.5.5     6/1/03	Added constant EraseROMMsgLine=2, DateToBCD
; 1.5.4     5/14/03    Added SRAM_ReadPD.
; 1.5.3     5/6/03	Extended the use of DisplayOrPut, NumsToNic.
; 1.5.2     4/21/03	Added UsesOscilator1, UsesOscilator2: oscilators on CCP1 and CCP2.
;	PortC bits:CCP1, CCP2, Oscilator1Time, Oscilator2Time.
; 1.5.1     4/18/03	Added new names SelectLDI2, SelectLDI3, SelectLDO2, SelectLDO3, SelMax110
;	Added support for LDO_2 and LDO_3.
; 1.5       4/17/03	Added LCD cursor control routines.
;	Moved LCD equates into LowStuff.asm.
; 1.4.5     4/15/03	Changed Flags26,escaped to escaped.
; 1.4.4     4/10/03	Added UsesISR, TXSTAValue.
; 1.4.3      4/9/03	Added BaudRate, defaults to Baud9600
; 1.4.2      4/8/03	Added port A init value PORTA_Value.
;	Added defaults section.
; 1.4.1      4/5/03	Fixed a initialization problem w/ 74AHC573 latches
; 1.4        4/4/03    Added Modeless Serial IO
;	if UsesRS232BufIO
;  in bank 3
;   rsInBuffCount	RES	1	;0 = No chrs in buffer
;   rsOutBuffCount	RES	1
;   rsInBuffPtr	RES	1	;get byte post inc
;   rsOutBuffPtr	RES	1	;send byte post inc
;   #Define	rsGotChar	Flags27,0	;Set if a byte is in W
;  in SRAM
;   evRS232InBuff	EQU	0x0204	;256 bytes
;   evRS232OutBuff	EQU	0x0205	;256 bytes
;  new routines: ScanRS232In, GetRS232Chr, ScanRS232Out, PutRS232Chr
;	endif
;
; 1.3.4      3/28/03	Added ShowSplashScrn/DispSplashScrn
;	Fixed bug in SetupDataROM
; 1.3.3      3/27/03   Added LCD_ChrsPerLine to PrintString
;	Added lcd_gotoxy_NC
; 1.3.2      3/26/03	Added UsesSRAM,UsesNIC, and expanded UsesI2C
;	Modified ANATest w/ ANATestSpacing,ANATestLine
; 1.3.1      2/26/03   Optimizing and commenting.
; 1.3        2/21/03	Moved Standard initialization routines to LowStuff
; 1.2        2/18/03   Added SetupDataROM
; 1.1.5      2/12/03	Minor bug fixes to Disp_dec3B,read_adcs
; 1.1.4      1/24/03   Modified Disp_decbyteW, Disp_decword, Disp_dec3B to replace
;	their counterparts in NICStuff.
;	Added SRAM_WritePI, SRAM_ReadPI
; 1.1.3      1/17/03	Added conditions UsesLCD and RS232Config
; 1.1.2     12/18/02   Modified SRam test to return if no error and Param70<>0
; 1.1.1     10/25/02   Moved custom routines to main.asm
;	 This file is now all standard routines
;	 Moved serial and other unused routines back into LowStuff.asm
;	 Current size 0x7A9 w/ everything on.
;
; 1.1       10/22/02   Moved unused/old code to OldCode file.
;	Optimized scanio to (1+3) from (1+5)
; 1.0.3     10/16/02   Strings to SRAM
; 1.0.2     10/1/02	Strings moved to main.asm, oldCode moved to end
; 1.0.1     9/17/02	Fisrt rev'd version
;
;============================================================================================
; Default values
;
	ifndef HasMAC_Addr_EEPROM
	constant	HasMAC_Addr_EEPROM=0
	endif
;
	ifndef UsesPulseCounter1
	constant	UsesPulseCounter1=0
	endif
;
	ifndef UsesPulseCounter2
	constant	UsesPulseCounter2=0
	endif
;
	ifndef BaudRate
BaudRate	EQU	Baud9600
	endif
;
	ifndef TXSTAValue
TXSTAValue	EQU	b'01100001'	;Async,9th bit is 2nd stop bit
	endif
;
	ifndef PORTA_Value
PORTA_Value	EQU	0x00
	endif
;
	ifndef ANATestSpacing
ANATestSpacing	EQU	d'06'
	endif
;
	ifndef ANATestLine
ANATestLine	EQU	0x02	;3rd line
	endif
;
	ifndef ShowSplashScrn
	constant	ShowSplashScrn=0
	endif
;
	ifndef UsesOscilator1
	constant	UsesOscilator1=0
	endif
;
	ifndef UsesOscilator2
	constant	UsesOscilator2=0
	endif
;
	ifndef EraseROMMsgLine
	constant	EraseROMMsgLine=2
	endif
;
	ifndef UsesMAX110
	constant	UsesMAX110=0
	endif
;
	ifndef UsesTimerFinished
	constant	UsesTimerFinished=0
	endif
;
	ifndef InitLCDAtStartup
	constant	InitLCDAtStartup=1
	endif
; I2C EEPROMs
	ifndef EnableEEROMCopy
	constant	EnableEEROMCopy=0	;Allow EEROM to be copied to SRAM
	endif
	ifndef Using64KBEEPROM
	constant	Using64KBEEPROM=0	;EEPROM addressing 0:15+3, 1:16+3
	endif
	ifndef EndOfEEROM
EndOfEEROM	EQU	0x01	;0x010000 is the first address past the end
			; EEPROMs must be installed in 64KB increments
	endif
;
	ifndef DispIPLine
DispIPLine	EQU	0x01
	endif
;
; Optional features (You must op-in if you need these)
;
	ifndef UsesBootloader
	constant	UsesBootloader=0
	endif
;
	ifndef UsesByte2Str
	constant	UsesByte2Str=0
	endif
;
	ifndef UsesDateToBCD
	constant	UsesDateToBCD=0
	endif
;
	ifndef UsesNum2Str
	constant	UsesNum2Str=0
	endif
;
	ifndef UsesNum3BToStr
	constant	UsesNum3BToStr=0
	endif
;
; Optional features (You must op-out if you don't need these)
;
;   Fix_dec3B,Num3BToStr,Disp_dec3B
	ifndef Uses3BNums
	constant	Uses3BNums=1
	endif
;
;   display_rtc
	ifndef Use_display_rtc
	constant	Use_display_rtc=1
	endif
;
;   DispMAC,DispMAC_E2
	ifndef UsesDispMAC
	constant	UsesDispMAC=1
	endif
;
	ifndef UsesDelay10uS
	constant	UsesDelay10uS=0
	endif
	ifndef UsesDelay40uS
	constant	UsesDelay40uS=0
	endif
;
	ifndef UsesLCDBlink
	constant	UsesLCDBlink=0
	endif
	ifndef UsesLCDClear
	constant	UsesLCDClear=0
	endif
	ifndef UsesLCDCursoBlink
	constant	UsesLCDCursoBlink=0
	endif
	ifndef Useslcd_Home
	constant	Useslcd_Home=0
	endif
	ifndef Useslcd_ReadData
	constant	Useslcd_ReadData=0
	endif
	ifndef UsesPushPopParams
	constant	UsesPushPopParams=0
	endif
	ifndef UsesSRamPushPopPrm
	constant	UsesSRamPushPopPrm=0
	endif
	ifndef UsesServoControl
	constant	UsesServoControl=0
	endif
;
;============================================================================================
; Conditionals
;
;
; UsesI2C	open_file, close_file, i2c_stop, i2c_start, i2c_writeW,
;	i2c_read1, i2c_read
; ISR_Timers	DoDecTimers
; CodeMemStrings	StringDispatch
; SRAM_Strings	StringDispatch
; UsesPushPop	PushParams, PopParams, Push, Pop
; Do_SRAM_Test	SRAM_Test
; Do_RS232_Test	RS232_Test
; UsesLCD	lcd_nybble, lcd_Home, lcd_Clear, wait_LCD_Ready, lcd_gotoWClr,
;	lcd_GotoLineW,PrintString
; UsesDataLogging	TimeToSRAM
; HasRTC	display_rtc, set_rtc, read_rtc, read_rtc_byte, read_rtc_nibble,
;	write_rtc_nibble, lcd_gotoxy, SendLCD_CmdW, lcd_char, Init_LCD
; Do_LD_Test	LD_Test
; RTCTest	calls display_rtc from ToggleSysLED
; ANATest	displays adcs 0,1, and 3 as X, Y, and Z from ToggleSysLED
; UsesLDI0	calls ReadLDI_0 from scan_io
; UsesLDI1	calls ReadLDI_1 from scan_io
; UsesLDI2	calls ReadLDI_2 from scan_io
; UsesLDI3	calls ReadLDI_3 from scan_io
; UsesLDO0	calls OPT_WriteLDO_0 from scan_io
; UsesLDO1	calls OPT_WriteLDO_1 from scan_io
;
; AnyANAUsed	read_adcs, ReadADC
;
; UsesRS232	init port
; RS232Active	DispSerial, putchar, get_char, getnum, TXString
; RS232Config	user_config, xmodem_recv
; Do_eeROM_Test	eeROM_Test
; UsesMAX110	WaitMAX110NotBusy, CalMAX110, ReadMAX110
; UsesRS232BufIO	ScanRS232In, GetRS232Chr, ScanRS232Out, PutRS232Chr
;
; Uses3BNums	Fix_dec3B,Num3BToStr,Disp_dec3B
; Use_display_rtc	display_rtc
; UsesDispMAC	DispMAC
; UsesByte2Str	Byte2Str
; UsesDateToBCD	DateToBCD
; UsesNum2Str	Num2Str
; UsesNum3BToStr	Num3BToStr
; UsesDelay10uS	Delay10uS
; UsesDelay40uS	Delay40uS
; UsesLCDBlink	lcd_Blink
; UsesLCDClear	lcd_Clear
; UsesLCDCursoBlink	lcd_CursorBlink
; Useslcd_Home	lcd_Home
; Useslcd_ReadData	lcd_SetDDRamAddress,lcd_ReadData
; 
;============================================================================================
;
;Routines in segment 0
; Name	(additional stack words required) Description
;============================================================================================
;
;StandardInits	(1+3) ClearRam, Init ANA I/O, Setup RS232, Setup I2C bus, PortB, PortD, PortA, PortE
;	T1CON, Latched Outputs, T2CON, INTCON, PR2, myeth, Init_LCD, test/zero SRAM, SetupStrings,
;	Display SIGNONStr
; 
;ClearRam	(1+0) Clear all the 'F877's RAM to 0
;
;PrintString	(1+2) Send a string (W) to DisplaysW
;TXString	(1+0) Send a string out the serial port
;
;Fix_decbyte	(0) used in converting base 10 byte values to ascii
;Disp_decbyteW3pl	(1+2) Sets Flags25:DispDec3pl
;Disp_decbyteW2pl	(1+2) Sets Flags25:DispDec2pl
;Disp_decbyteW	(1+2) Display a byte in unsigned decimal format no leading 0's no leading spaces
;Fix_decword	(0) Used to convert a word value to a string
;Num2Str	(1+1) Convert an Int16 (Param77:Param76) to a pStr at txbuff
;Disp_decword	(1+2) 16 bit version of Disp_decbyteW
;Fix_dec3B	(0) Used to convert a 3 byte value to a string
;Num3BToStr	(1+1) Convert an Int24 at Param77:Param76:Param74 to a pStr at txbuff
;Disp_dec3B	(1+2) 24 bit version of Disp_decbyteW
;
;ReadData	(0) Read Data from input device, W = select value (Select0,SelectSRAM, etc.)
;
;Set8bitAddr	(0) Set the low 8 address bits to the value in the W
;SetSRAM_Addr	(0) Put the SRAM address on the address bus
;SRAM_OffsetAddr	(0) Offset the SRAM_Addr by W
;SRAM_NextAddr	(0) Increments the SRAM_Addr
;SRAM_PrevAddr	(0) Decrements the SRAM_Addr
;SRAM_WritePI	(1+0) Write the value in the W to SRAM address SRAM_Addr then increment address
;SRAM_Write	(1+0) Write the value in the W to SRAM address SRAM_Addr
;SRAM_ReadPD	(1+0) Read the value in SRAM address SRAM_Addr into the W then decrement address
;SRAM_ReadDR	(1+0) Set SRAM address to evDataROM+W then SRAM_ReadPI
;SRAM_ReadPI	(1+0) Read the value in SRAM address SRAM_Addr into the W then increment address
;StringDispatch	(1+0) Param7F=String Number (0..n), Param7D=Character Number
;SRAM_Read	(1+0) Read the value in SRAM address SRAM_Addr into the W
;SRAM_Test	(1+3) Test the SRAM (512KB) a successful test displays (SRAM:5A.1.2.3)
;SRAM_Zero	(1+3) Zero the Static RAM
;ZeroSRAM_Addr	(1+0) Setup the SRAM address buffers and variables
;
;Processor RAM version
;PushParams	(0) Push Params76..7D stack++,  STATUS, FSR and W are unchanged
;PopParams	(0) POP Params76..7D --stack,  STATUS, FSR and W are unchanged
;Push	(0) Push the W onto the stack++,  STATUS, FSR and W are unchanged
;Pop	(0) Pop the W from the --stack,  STATUS and FSR are unchanged
;
;SRAM version
;PushParams	(1+1) Push Params76..7D stack++,  STATUS, FSR and W are unchanged
;PopParams	(1+1) POP Params76..7D --stack,  STATUS, FSR and W are unchanged
;Push	(1+1) Push the W onto the stack++,  STATUS, FSR and W are unchanged
;Pop	(1+1) Pop the W from the --stack,  STATUS and FSR are unchanged
;
;Delay1Sec	(1+0) Delay 1 Second (RAM used:Param77,78,79)
;DelayWmS	(0)   Delay (value in W) milliseconds (RAM used:Param77,78,79)
;Delay10uS	(0)   Delay 10us (RAM used:Param77)
;Delay100uS	(0)   Delay 100us (RAM used:Param77)
;Delay40uS	(0)   Delay 40us (RAM used:Param77)
;DelayWuS	(0)   Delay W us (RAM used:Param77)
;
;lcd_nybble	(0)   Send a nybble to the LCD
;lcd_On	(1+0) Send LCD command for Disp On, Cursor Off, Blink Off
;lcd_Blink	(1+0) Send LCD command for Disp On, Cursor Off, Blink On
;lcd_CursorBlink	(1+0) Send LCD command for Disp On, Cursor On, Blink On
;lcd_Cursor	(1+0) Send LCD command for Disp On, Cursor On, Blink Off
;lcd_Home	(1+0) Home the cursor without clearing DDRAM
;lcd_Clear	(1+0) Home the cursor clearing DDRAM
;lcd_SetDDRamAddress	(1+0) Set the DD Ram Address (W)
;lcd_ReadData	(1+0) Read from DD Ram (Data returned in W and Param78)
;wait_LCD_Ready	(0)   Polls the LCDs Busy Flag until clear
;lcd_GotoLineW	(1+0) Goto the beginning of line W, Clears line.
;lcd_gotoxy	(1+0) Go to an X-Y position on the display, top left is 0, 0 (W,Param78)
;lcd_gotoxy_NC	(1+0) No Clear version of lcd_gotoxy
;SendLCD_CmdW	(1+0) Send a command byte in W to the LCD as two nybbles
;SendLCD_Cmd79	(1+0) Send a command byte in Param79 to the LCD as two nybbles
;lcd_char	(1+0) Send a character byte to the LCD as two nybbles
;Init_LCD	(1+1) Initialise the LCD
;
;Byte2Str	(1+1) Convert a Byte (Param77) to a pStr at txbuff
;Disp_Hex_Byte	(1+2) Send a byte, W, to the display as 2 hex digits
;Disp_Hex_Nibble	(1+1) Send a nibble to the display as a hex digit
;
;Display_Colon	(1+1) Load a ':' into the W and goto DisplaysW
;Display_Dot	(1+1) Load a '.' into the W and goto DisplaysW
;DisplaysW	(1+1) Display handler; redirects to LCD and/or serial
;DispSerial	(1+0) Send the Char in Param75
;putchar	(0) Send the byte in the W out the serial port
;DispNIC	(1+1) Send the char to the NIC
;RS232_Test	(1+0) Test the RS232 port by echoing every character
;
;ReadEE79	(0) Read from the CPU's EEPROM using Param79 as Address
;ReadEE79PI	(0) Read from the CPU's EEPROM using Param79++ as Address
;ReadEEwW	(0) Read from the CPU's EEPROM using W as Address
;WriteEEP79WPI	(0) Write CPU's EEPROM using address from Param79++ and Data in W
;WriteEEP79W	(0) Write CPU's EEPROM using address from Param79 and Data in W
;WriteEEwW	(0) Write CPU's EEPROM using current value in EEADR and W as Data
;
;   Reading/Writing 2 LSBs of MAC Address and 4 byte IP address
;csum_nonvol	(1+0) Do a 1's complement checksum of the CPU's non-volatile eeprom
;read_nonvol	(1+1) Read in the nonvolatile parameters to ram, return 0 if error
;write_nonvol	(1+1) Write out the nonvolatile parameters to CPU's eeprom
;
;TimeToSRAM	(1+1) copy the 6 byte time to the SRAM
;display_rtc	(1+3) Display the RTC on the LCD in the from YY:MM:DD:HH:mm:ss
;DateToBCD	(1+0) Convert RTC_Year..RTC_Seconds to BCD for set_rtc
;set_rtc	(1+1) Set the RTC with Data form RTC_Year..RTC_Seconds (BCD format)
;read_rtc	(1+2) Read the Real Time Clock
;read_rtc_byte	(1+1) Read one byte from the Real Time Clock
;read_rtc_nibble	(1+0) Read one nibble from the Real Time Clock
;write_rtc_nibble	(1+0) Writes the low nibble from Param79 to the RTC Address from Param78
;
;WaitMAX110NotBusy	(1+1) Wait for the MAX110 to finish, will loop forever if an error occures
;CalMAX110	(1+2) Calibrate the MAX110 14bit ADC for Channel 0
;ReadMAX110	(0) Read the MAX110 14bit ADC Channel 0
;
;OPT_WriteLDO_0	(0) if CMD_LDO_0<>CurrentLDO_0 then WriteLDO_0
;WriteLDO_0	(0) Write the data in CurrentLDO_0 to the latch
;OPT_WriteLDO_1	(0) if CMD_LDO_1<>CurrentLDO_1 then WriteLDO_1
;WriteLDO_1	(0) Write the data in CurrentLDO_1 to the latch
;OPT_WriteLDO_2	(0) if CMD_LDO_1<>CurrentLDO_2 then WriteLDO_2
;WriteLDO_2	(0) Write the data in CurrentLDO_2 to the latch
;OPT_WriteLDO_3	(0) if CMD_LDO_3<>CurrentLDO_3 then WriteLDO_3
;WriteLDO_3	(0) Write the data in CurrentLDO_3 to the latch
;ReadLDI_0	(1+0) Read the data from the latch and store it at CurrentLDI_0 & W
;ReadLDI_1	(1+0) Read the data from the latch and store it at CurrentLDI_1 & W
;ReadLDI_2	(1+0) Read the data from the latch and store it at CurrentLDI_2 & W
;ReadLDI_3	(1+0) Read the data from the latch and store it at CurrentLDI_3 & W
;LD_Test	    Flash each led for 1 seconds then echo switches to LEDs
;
;geticks	(0) Update the current tick count, return W=1 if changed
;scan_io	(1+3) Check timer, scan ADCs, toggle LED if timeout 
;read_adcs	(0+0) Read ADC values
;ReadADC	(0) returns ADRESH in Param78 and ADRESL in Param78
;
;AddressEEROMR	(1+0) Set the eeprom address from eeROMbuff.Addr and restart for a read
;AddressEEROM	(1+0) Set the eeprom address from eeROMbuff.Addr writing mode
;ReadEEROM	(1+1) Read data (eeROMbuff.len 1..32 bytes) from eeproms (eeROMbuff.Addr) to eeROMbuff.Data
;EraseEEROM	(1+3) Erases the 2nd eeROM chip and clr the ptrs
;WriteEEROM	(1+1) Write eeROMbuff.Data (eeROMbuff.len 1..32 bytes) to the eeproms (eeROMbuff.Addr)
;CopyEEROMtoSRAM	(1+1) Copy the whole data space (EEROM) to SRAM 32KB buffer evBuff32KB (W= 32KB page #)
;SetupDataROM	(1+2) Copy d.d file to SRAM starting at evDataRom*256
;SetupStrings	(1+2) Copy the s.s file to SRAM starting at evStrings*256
;open_file	(1+0) Open the previously-found file for transmission (serial eeprom)
;close_file	(1+0) Close the previously-opened file (serial eeprom)
;i2c_stop	(0) Ends a iic operation
;i2c_start	(0) Start an iic operation
;i2c_writeW	(0) writes a byte to the serial EEPROM, hangs if no ACK
;i2c_read1	(0) Normal iic read with ACK
;i2c_read	(0) if Param77 then ACK else NAK
;
;find_file	(1+0) Find a filename in ROM filesystem
;user_config	(1+2) User initialisation code; get serial number and IP address
;xmodem_recv	(1+2) Handle incoming XMODEM data block
;
;ScanRS232In	(1+1) Get a character from the RS232 port and put it in the buffer
;GetRS232Chr	(0+1) Get a character from the RS232 input buffer
;ScanRS232Out	(0+1) Put a character from the output buffer in the RS232 port
;PutRS232Chr	(0+1) Put a character into the RS232 output buffer
;
;get_char	(0) Get a character from the serial port
;getnum	(1+1) Get a 16-bit decimal number from the console (serial port)
;eeROM_Test	(1+3) Test the eeROM
;
;DispIP	(1+3) Display IP address on 2nd line
;DispMAC	(1+3) Display MAC address on 2nd line
; 
; 
;============================================================================================
;LCD Stuff
; DMC-20434 20Char x 4 line LCD
LCD_MODE	EQU	0x28
LCD_4Bits	EQU	0x02
LCD_Dots1	EQU	0x02	;5x7 dots
LCD_Dots2	EQU	0x08
LCD_EnterMode	EQU	0x06	;Incrementing cursor, not horiz scroll
LCD_Clear	EQU	0x01
LCD_Home	EQU	0x02
LCD_LINE2	EQU	0x40	;20 dec
LCD_ON	EQU	0x0C	;Disp On, Cursor Off, Blink Off
LCD_Cursor	EQU	b'00001110'	;Disp On, Cursor On, Blink Off
LCD_CursorBlink	EQU	b'00001111'	;Disp On, Cursor On, Blink On
LCD_Blink	EQU	b'00001101'	;Disp On, Cursor Off, Blink On
;
LCD_SETPOS	EQU	0x80
;
;============================================================================================
; Real Time Clock Addresses  EPSON RTC-72421
RTC_OneSec	EQU	0x00	; 1-second digit reg.
RTC_TenSec	EQU	0x01	; 10-second digit reg.
RTC_OneMinute	EQU	0x02	; 1-minute digit reg.
RTC_TenMinute	EQU	0x03	; 10-minute digit reg.
RTC_OneHour	EQU	0x04	; 1-hour digit reg.
RTC_TenHourAMPM	EQU	0x05	; 10-hour digit & AM/PM bit reg.
RTC_OneDay	EQU	0x06	; 1-day digit reg.
RTC_TenDay	EQU	0x07	; 10-day digit reg.
RTC_OneMonth	EQU	0x08	; 1-month digit reg.
RTC_TenMonth	EQU	0x09	; 10-month digit reg.
RTC_OneYear	EQU	0x0A	; 1-year digit reg.
RTC_TenYear	EQU	0x0B	; 10-year digit reg.
RTC_Week	EQU	0x0C	; Week 0..6
RTC_CtrlRegD	EQU	0x0D	; Control Reg. D
RTC_CtrlRegE	EQU	0x0E	; Control Reg. E
RTC_CtrlRegF	EQU	0x0F	; Control Reg. F
;
RTC_AMPMmask	EQU	0x04	; mask to extract AM/PM bit
RTC_KillAMPMmask	EQU	0x03	; mask to kill the AM/PM bit
;RTC_CtrlRegF bits
RTC_24Bit	EQU	0x04	; set this bit for 24 hour mode
RTC_ReadBit	EQU	5	; active low  (PORTD)
RTC_WriteBit	EQU	4	; active low  (PORTD)
RTC_ReadMask	EQU	0x10	; set the write bit
RTC_WriteMask	EQU	0x20	; set the read bit
RTC_CSBit	EQU	6	;RTC chip select Active Low (PORTB)
;============================================================================================
; Reset Vector entry point
;
	ORG	0x0000	; processor reset vector
;
	MOVLW	0x10	; ensure page bits are cleared
	MOVWF	PCLATH
	GOTO	Main	; go to beginning of program
;
;============================================================================================
; Interupt entry point
;
	ORG	0x0004	; interrupt vector location
	if UsesISR
; save W, STATUS and FSR
	MOVWF	ISR_W_Temp	; save off current W register contents
	MOVF	STATUS,W	; move status register into W register
	mBank3
	MOVWF	ISR_Status_Save	; save contents of STATUS register
	MOVF	ISR_W_Temp,W
	MOVWF	ISR_W_Save
	MOVF	FSR,W	; save FSR
	MOVWF	ISR_FSR_Save
	MOVF	PCLATH,W	; save PCLATH
	MOVWF	ISR_PCLATH_Save
	CLRF	PCLATH
;
;
; isr code must go here
; Do not call a subroutine as it is posible geting here
;  put the 8th address on the stack.
;
	CLRF	STATUS	;saves 1 byte over mBank0
	if UsesOscilator1
	BTFSS	PIR1,CCP1IF
	GOTO	NotCCP1IF
	MOVLW	low Oscilator1Time
	ADDWF	CCPR1L,F
	ADDCF	CCPR1H,F
	MOVLW	high Oscilator1Time
	ADDWF	CCPR1H,F
	MOVLW	0x01
	XORWF	CCP1CON,F
	BCF	Osc1SyncBit
	BTFSC	CCP1CON,CCP1M0
	BSF	Osc1SyncBit
	BCF	PIR1,CCP1IF
NotCCP1IF
	endif
;
	if UsesOscilator2
	BTFSS	PIR2,CCP2IF
	GOTO	NotCCP2IF
	MOVLW	low Oscilator2Time
	ADDWF	CCPR2L,F
	ADDCF	CCPR2H,F
	MOVLW	high Oscilator2Time
	ADDWF	CCPR2H,F
	MOVLW	0x01
	XORWF	CCP2CON,F
	BCF	Osc2SyncBit
	BTFSC	CCP2CON,CCP2M0
	BSF	Osc2SyncBit
	BCF	PIR2,CCP2IF
NotCCP2IF
	endif
;	
	if UsesPulseCounter1
	CLRF	STATUS	;saves 1 byte over mBank0
	BTFSS	PIR1,CCP1IF
	GOTO	PulseCounter1_End
	BCF	PIR1,CCP1IF
	mBank3
	INCF	PulseCounter1,F
;
PulseCounter1_End
	endif
;
	if UsesPulseCounter2
	CLRF	STATUS	;saves 1 byte over mBank0
	BTFSS	PIR2,CCP2IF
	GOTO	PulseCounter2_End
	BCF	PIR2,CCP2IF
	mBank3
	INCF	PulseCounter2,F
;
PulseCounter2_End
	endif
;
	if UsesRS232BufIO
	BTFSC	PIR1,RCIF	;Char in buffer?
	GOTO	ScanRS232In	;No
ScanRS232In_RTN
	endif
;
	BTFSS	PIR1,TMR2IF	;Timer 2 Caused interupt?
	GOTO	ISR_2
	BCF	PIR1,TMR2IF
;
	if ISR_Timers>0
;------------------------------------------------------------------------
; Decrement routine for 16 bit timers
;  If the timer is not at zero then decriment it.
;
;DoDecTimers
	mBank3
	MOVF	Timer1Hi,W
	IORWF	Timer1Lo,W
	IORWF	Timer1MSB,W
	BTFSC	STATUS,Z
	GOTO	Timer1IsZero
	MOVLW	0x01
	SUBWF	Timer1Lo,F
	BTFSS	STATUS,C
	SUBWF	Timer1Hi,F	;borrowed
	BTFSS	STATUS,C
	SUBWF	Timer1MSB,F
;
Timer1IsZero	
	endif
	if ISR_Timers>1
	CLRF	ISR_W_Temp	;0..ISR_Timers-2
	BSF	STATUS,IRP	;banks 2,3
	MOVLW	low Timer2Lo
	MOVWF	FSR	;TimerXLo
DoDecTimerN	MOVF	INDF,W
	INCF	FSR,F	;TimerXHi
	IORWF	INDF,W
	SKPNZ
	GOTO	TimerIsZero
	DECF	FSR,F	;TimerXLo
	MOVLW	0x01
	SUBWF	INDF,F
	INCF	FSR,F	;TimerXHi
	SKPNB
	DECF	INDF,F
;
	if UsesTimerFinished
	MOVF	INDF,W
	DECF	FSR,F	;TimerXLo
	IORWF	INDF,W
	SKPZ
	GOTO	TimerFinishedRtn	;It's not zero yet
	MOVF	ISR_W_Temp,W	;0..ISR_Timers-2
	BSF	PCLATH,4	;Segment 2
	GOTO	TimerFinishedDispatch
TimerFinishedRtn
	INCF	FSR,F	;TimerXHi
	endif
;
;
TimerIsZero	INCF	FSR,F	;TimerX+1Lo
	INCF	ISR_W_Temp,F
	MOVLW	ISR_Timers-1
	SUBWF	ISR_W_Temp,W
	SKPZ
	GOTO	DoDecTimerN
	endif
;
;
ISR_2	
;
	if UsesSpeedTrap
	CLRF	STATUS	;saves 1 byte over mBank0
	BTFSS	PIR1,CCP1IF
	GOTO	ISR_3
	BCF	PIR1,CCP1IF
;	mLED2_ON
	mBank3
	BTFSC	stArmed	;armed?
	GOTO	SpeedTrap_1	;Yes
	CLRF	STATUS	;saves 1 byte over mBank0
	MOVF	CCPR1L,W	;No, arm the trap
	mBank3
	BSF	stArmed	;Current value to ram
	MOVWF	TrapL
	CLRF	STATUS	;saves 1 byte over mBank0
	MOVF	CCPR1H,W
	mBank3
	MOVWF	TrapH
	GOTO	ISR_3
;
SpeedTrap_1	BTFSC	stTrapped	;Old trap value was read?
	GOTO	ISR_3	;No
	CLRF	STATUS	;saves 1 byte over mBank0
	MOVF	CCPR1L,W	;Yes, Trap=CCPR-Trap
	mBank3
	BSF	stTrapped
	SUBWF	TrapL,F
	CLRF	STATUS	;saves 1 byte over mBank0
	MOVF	CCPR1H,W
	mBank3
	BTFSS	STATUS,C
	DECF	TrapH,F
	SUBWF	TrapH,F
	endif
;
ISR_3
;
	if UsesServoControl
	GOTO	IRQ_Servo1
IRQ_ServoRtn
	endif
;
; restore W, STATUS and FSR
	mBank3
	MOVF	ISR_PCLATH_Save,W	; restore PCLATH
	MOVWF	PCLATH
	MOVF	ISR_FSR_Save,W	; restore FSR
	MOVWF	FSR
	MOVF	ISR_W_Save,W
	MOVWF	ISR_W_Temp	; put the W here so we can get to it after
	MOVF	ISR_Status_Save,W	; retrieve copy of STATUS register
	MOVWF	STATUS	; restore pre-isr STATUS register contents
	SWAPF	ISR_W_Temp,F	; swap is used because status bits are unaffected
	SWAPF	ISR_W_Temp,W	; restore pre-isr W register contents
	endif		; if UsesISR
	RETFIE		; return from interrupt
;
;=========================================================================================
;=========================================================================================
; Standard Initalization routines
;
; ClearRam, Init ANA I/O, Setup RS232, Setup I2C bus, PortB, PortD, PortA, PortE
; T1CON, Latched Outputs, T2CON, INTCON, PR2, myeth, Init_LCD, test/zero SRAM, SetupStrings,
; Display SIGNONStr
;
; Entry: none
; Exit: none
; RAM used: All
; Calls:(1+3) ClearRam,SetupStrings,lcd_GotoLineW,PrintString,StandardInits_1,DelayWmS,Init_LCD
;	DisplaysW,SRAM_Test,SRAM_Zero
;
StandardInits	CALL	ClearRam
;
	MOVLW	ADCON0Val	;div32,CH0,ON
	MOVWF	ADCON0
	BSF	STATUS,RP0	;Bank 1
	MOVLW	ADCON1_Value	;may be All_Digital
	MOVWF	ADCON1
	BCF	STATUS,RP0	;Bank 0
;
	if UsesRS232
;============================================================================================
; Setup RS232 pg.97-98
	BSF	_RP0	;Bank 1
	MOVLW	BaudRate	;9600 Baud Fosc/(64(X+1))
	MOVWF	SPBRG	; 19660800/4/(16(32))=9600
;
	MOVLW	TXSTAValue	;Enable TX/ASync/Low Speed (was 22)
	MOVWF	TXSTA
;
	BCF	STATUS,RP0	; Bank 0
	MOVLW	0x90	;Enable RX, continious receive
	MOVWF	RCSTA
;
;	BSF	STATUS,RP0	; Bank 1
;	BSF	TRISC,RTS	; async RTS input
;	BCF	TRISC,CTS	; async CTS output
;	BCF	STATUS,RP0	; Bank 0
;	BSF	PORTC,RTS	; RTS input
;	BSF	PORTC,CTS	; CTS output
	endif
;
	if UsesI2C
;===========================================================================================
; I2C init code
; configure SSP for hardware I2C
	BSF	STATUS,RP0	; Bank 1
	BSF	TRISC,SCL	; I2C SCL pin is input (will be controlled by SSP)
	BSF	TRISC,SDA	; I2C SDA pin is input (will be controlled by SSP)
	BCF	STATUS,RP0	; Bank 0
	BSF	PORTC,SDA
	BSF	PORTC,SCL
	BSF	STATUS,RP0	; Bank 1
	BSF	SSPSTAT,SMP	; I2C slew rate control disabled
	BCF	STATUS,RP0	; Bank 0
	BSF	SSPCON,SSPM3	; I2C master mode in hardware
	BCF	SSPCON,SSPM2
	BCF	SSPCON,SSPM1
	BCF	SSPCON,SSPM0
	BSF	SSPCON,SSPEN	; enable SSP module
	BSF	STATUS,RP0	; Bank 1
	MOVLW	d'48'	; set I2C clock rate to 100kHz
	MOVWF	SSPADD	; Fosc/(4*(SSPADD+1))=100.310kHz
	BCF	STATUS,RP0	; Bank 0
;
	endif
;
; setup Port B All outputs with SelectEnable=1,IORead=1,IOWrite=1, LCD_E=0
	MOVLW	PORTA_Value
	MOVWF	PORTA
	MOVLW	PORTB_Value
	MOVWF	PORTB
	CLRF	PORTD
	BSF	STATUS,RP0	; Bank 1
	MOVLW	TRISBValue	;All out
	MOVWF	TRISB
	BCF	OPTION_REG,NOT_RBPU	; Use pullups on port B
;
	MOVLW	All_Out
	MOVWF	TRISD	; set for clearing latched outputs
;
	MOVLW	TRISAValue
	MOVWF	TRISA
;
	MOVLW	TRISEValue
	MOVWF	TRISE
;
	BCF	STATUS,RP0	; Bank 0
;
	MOVLW	TIMER1_SET	; Init timer 1
	MOVWF	T1CON
;
;Set all Latched outputs to 0x00
	MOVLW	Select0	;Select0, A0..A7
	CALL	StandardInits_1
	MOVLW	Select1	;Select1, A8..A15
	CALL	StandardInits_1
	MOVLW	Select2	;Select2, A16..A23
	CALL	StandardInits_1
;
	if UsesLDO0
;Set outputs of LDO_0 on so LEDs will be off
	MOVLW	LDO_0_InitVal	;all high except reset
	MOVWF	PORTD
	mBank3
	MOVWF	CMD_LDO_0
	MOVWF	CurrentLDO_0
	MOVLW	SelectLDO0
	CALL	StandardInits_1
	endif
;
	if UsesLDO1
	MOVLW	LDO_1_InitVal
	MOVWF	PORTD
	mBank3
	MOVWF	CMD_LDO_1
	MOVWF	CurrentLDO_1
	MOVLW	SelectLDO1
	CALL	StandardInits_1
	endif
;
	if UsesLDO2
	MOVLW	LDO_2_InitVal
	MOVWF	PORTD
	mBank3
	MOVWF	CMD_LDO_2
	MOVWF	CurrentLDO_2
	MOVLW	SelectLDO2
	CALL	StandardInits_1
	endif
;
	if UsesLDO3
	MOVLW	LDO_3_InitVal
	MOVWF	PORTD
	mBank3
	MOVWF	CMD_LDO_3
	MOVWF	CurrentLDO_3
	MOVLW	SelectLDO3
	CALL	StandardInits_1
	endif
;
;
; Setup TMR2 for 1/256 sec interupts
	MOVLW	T2CON_Value
	MOVWF	T2CON
	BSF	_RP0	; Bank 1
	BSF	INTCON,PEIE
;
	if ISR_Timers>0
	BSF	PIE1,TMR2IE
	endif
;
	MOVLW	HasISR
	ANDLW	0x80	; True?
	SKPZ	
	BSF	INTCON,GIE	;GIE bit
	MOVLW	PR2_Value
	MOVWF	PR2
	BCF	_RP0	; Bank 0
;
;
	if UsesNIC
; Setup MAC address (ethernet hardware addreess)
; The MAC address is six consecutive bytes for fast access.
	MOVLW	MAC_Addr0
	MOVWF	myeth0
	MOVLW	MAC_Addr1
	MOVWF	myeth1
	MOVLW	MAC_Addr2
	MOVWF	myeth2
	MOVLW	MAC_Addr3
	MOVWF	myeth3
	CLRF	myeth4	;will be loaded from eprom(0)
	CLRF	myeth5	;will be loaded from eprom(1)
;
	if HasMAC_Addr_EEPROM
	MOVLW	MAC_Addr4
	MOVWF	myeth4
	MOVLW	MAC_Addr5
	MOVWF	myeth5
	endif
	endif
;
	BSF	BtnDebounce
;Extended powerup delay
	MOVLW	0xFF
	CALL	DelayWmS
;
	if UsesLCD & InitLCDAtStartup
	Call	Init_LCD	; Init LCD 
	BSF	SendToLCD	;disp_lcd:=TRUE; Set display flags 
	endif
;
	if RS232Active
	BSF	SendRS232	;disp_serial:=TRUE; Set display flags
	endif
;
; if activated go to the LED and Switch test from here
	if Do_LD_Test
	GOTO	LD_Test
	endif
;
	if UsesLCD & InitLCDAtStartup
	CLRW
	CALL	lcd_GotoLineW
	if ShowSplashScrn
	MOVLW	eSplashText
	CALL	DispSplashScrn_1
	MOVLW	0x01	;2nd line
	CALL	lcd_GotoLineW
	MOVLW	eSplashText2
	CALL	DispSplashScrn_1
	else
	MOVLW	':'
	CALL	DisplaysW
	endif		;if ShowSplashScrn
	endif		;if UsesLCD
;
	if UsesSRAM
;========================================
; zeroing sram, because of multiplexing this is about 2,000,000 bus cycles (about 4 seconds)
;
; If SRAM test is activated go to the SRAM test from here
;
	if Do_SRAM_Test
	BCF	Param70,0
	Call	SRAM_Test	;test and zero
	else
	if Do_ZeroRAM
	Call	SRAM_Zero	;just zero
	endif
	endif
	endif
;
;================================================================
; Move strings to SRAM
	if SRAM_Strings
	Call	SetupStrings
	endif
;
;
	if UsesLCD & InitLCDAtStartup
	if ShowSplashScrn
	else
	CLRW
	CALL	lcd_GotoLineW
	MOVLW	SIGNONStrPtr	;Display the SIGNON string
	CALL	PrintString
	endif
	endif
;
	if UsesPulseCounter1
	MOVLW	CaptureAllRising
	MOVWF	CCP1CON
	BSF	_RP0	;Bank1
	BSF	PIE1,CCP1IE
	BSF	TRISC,CCP1	; set to input
	BCF	_RP0	;Bank0
	BSF	INTCON,PEIE
	endif
;
	if UsesPulseCounter2
	MOVLW	CaptureAllRising
	MOVWF	CCP2CON
	BSF	_RP0	;Bank1
	BSF	PIE2,CCP2IE
	BSF	TRISC,CCP2	; set to input
	BCF	_RP0	;Bank0
	BSF	INTCON,PEIE
	endif
;
	if UsesOscilator1
	MOVLW	CompSetOnMatch
	MOVWF	CCP1CON
	BSF	_RP0	;Bank1
	BSF	PIE1,CCP1IE
	BCF	TRISC,CCP1
	BCF	_RP0	;Bank0
	BCF	PORTC,CCP1
	BSF	INTCON,PEIE
	endif
;
	if UsesOscilator2
	MOVLW	CompSetOnMatch
	MOVWF	CCP2CON
	BSF	STATUS,RP0	;Bank1
	BSF	PIE2,CCP2IE
	BCF	TRISC,CCP2
	BCF	STATUS,RP0	;Bank0
	BCF	PORTC,CCP2
	BSF	INTCON,PEIE
	endif
;
	if UsesServoControl
	CALL	SetupForServos
	endif
;
	if UsesBootloader
	mCall0To3	PwrUpTest
	endif
;
	if UsesRS232BufIO
	mBank1
	BSF	PIE1,RCIE
	BCF	_RP0
	BSF	INTCON,PEIE
	endif
;
	RETURN
;
StandardInits_1	CLRF	STATUS	;saves 1 byte over mBank0
	MOVWF	Param78
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORWF	Param78,W
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	NOP
	BSF	PORTB,SelectEnable
	RETURN
;
DispSplashScrn_1	MOVWF	Param7A
;
	if LCD_ChrsPerLine=d'20'
	MOVLW	' '
	CALL	DisplaysW
	MOVLW	' '
	CALL	DisplaysW
	endif
;
DispSplashScrn_L1	MOVFW	Param7A
	CALL	ReadEEwW
	SKPNZ
	RETURN
	CALL	DisplaysW
	INCF	Param7A,F
	GOTO	DispSplashScrn_L1
;
;===============================================================================================
; Clear all RAM
; Entry: none
; Exit: none
; RAM used: All
; Calls:(1+0) ClearRam_L2
;
ClearRam	CLRF	STATUS
	MOVLW	0x5F	;Clear 20h-7Eh, 95 bytes
	MOVWF	Param7F
	MOVLW	0x20
	MOVWF	FSR
	CALL	ClearRam_L2
;
	MOVLW	0x50	;Clear A0h-FFh, 80 bytes
	MOVWF	Param7F
	MOVLW	0xA0
	MOVWF	FSR
	CALL	ClearRam_L2
;
	BSF	STATUS,IRP	;Clear 110h-16Fh, 96 bytes
	MOVLW	0x60	;96
	MOVWF	Param7F
	MOVLW	0x10
	MOVWF	FSR
	CALL	ClearRam_L2
;	
	MOVLW	0x60	;Clear 190h-1EFh, 96 bytes
	MOVWF	Param7F
	MOVLW	0x90
	MOVWF	FSR
;
ClearRam_L2	CLRF	INDF
	INCF	FSR,F
	DECFSZ	Param7F,F
	GOTO	ClearRam_L2
	RETURN
;
;
	if UsesLCD
;=========================================================================================
; Send string number (W) to DisplaysW
; Entry: W = string number
; RAM used: Param7D=CharCount, Param7F=StringNumber
; Calls:(1+2) DisplaysW
;
PrintString	MOVWF	Param7F
	CLRF	Param7D	;CharCount=0
PrintString_L1	
	if CodeMemStrings
	mCall0To2	StringDispatch	;Get the next Char
	endif
	if SRAM_Strings
	CALL	StringDispatch	;Get the next Char
	endif
	INCF	Param7D,F	;CharCount:=CharCount+1
	IORLW	0x00	;set Z if last char
	BTFSC	STATUS,Z
	RETURN		;00 = done
	CALL	DisplaysW	;Display the Char
	MOVLW	LCD_ChrsPerLine
	SUBWF	Param7D,W	;CharCount-LCD_ChrsPerLine
	SKPZ		;skip if zero
	GOTO	PrintString_L1
	RETURN
;
	endif
;
	if RS232Active
;=============================================================================================
;Send a string out the serial port
; Entry: W = String Number
; Exit: none
; RAM used: Param7D, Param7F
; Calls:(1+0) StringDispatch, putchar
;
TXString	MOVWF	Param7F
	CLRF	Param7D
TXString_L1	
	if CodeMemStrings
	mCall0To2	StringDispatch	;Get the next Char
	endif
	if SRAM_Strings
	CALL	StringDispatch	;Get the next Char
	endif
	INCF	Param7D,F
	IORLW	0x00	;Set Z if last byte (00)
	BTFSC	STATUS,Z
	RETURN
;
	CALL	putchar
	GOTO	TXString_L1
;
	endif
;
;============================================================================================
; used in converting base 10 byte values to ascii
;
; Param78=Param77 div Param79
; Param77=Param77 mod Param79
;
; Entry: Param79=100 or 10, Param77=data
; Exit: Param77 remainder, Param78=0..9
; RAM used: Param77, Param78, Param79  (verified 6/1/03)
; Calls:(0) none
;
Fix_decbyte	CLRF	Param78
	MOVF	Param79,W
	SUBWF	Param77,W	;data-100
	BTFSS	STATUS,C
	RETURN		;Param77>=100
;
Fix_decbyte_L1	INCF	Param78,F
	MOVWF	Param77
	MOVF	Param79,W
	SUBWF	Param77,W	;data-100
	BTFSC	STATUS,C
	GOTO	Fix_decbyte_L1	;Param77>=100
	RETURN
;
;=====================================================================================
; Display a byte in unsigned decimal format no leading 0's no leading spaces
; Entry: W=Data, Flags25:DispDec2pl, Flags25:DispDec3pl, Flags25:DispLSpaces
;  Setting Flags25:DispDec2pl causes a leading zero in the second place
;  Setting Flags25:DispDec3pl causes a leading zero in the third place
; Exit:none
; RAM used: Param71:0, Param77, Param78, Param79, FSR
; Calls:(1+2) Fix_decbyte, DisplaysW
;
Disp_decbyteW3pl	CLRF	STATUS	;saves 1 byte over mBank0
	BSF	DispDec3pl
Disp_decbyteW2pl	CLRF	STATUS	;saves 1 byte over mBank0
	BSF	DispDec2pl
Disp_decbyteW	CLRF	STATUS	;saves 1 byte over mBank0
	BCF	Param71,0	;Zero flag
	MOVWF	Param77
	MOVLW	d'100'
	MOVWF	Param79
	CALL	Fix_decbyte
	MOVF	Param78,W
	BTFSS	STATUS,Z	; skip if Param78=0
	GOTO	Disp_decbyteW_Show3	;first digit is not zero
	BTFSC	DispDec3pl	; show 3 places?
	GOTO	Disp_decbyteW_Show3	;Display 3rd digit 0..9
	BTFSS	DispLSpaces
	GOTO	Disp_decbyteW_1	;no leading space
	MOVLW	' '
	GOTO	Disp_decbyteW_Show3S	;show the leading space
;
Disp_decbyteW_Show3	BSF	Param71,0	;Show Zero flag
	ADDLW	'0'
Disp_decbyteW_Show3S	CALL	DisplayOrPut
;
Disp_decbyteW_1	MOVLW	d'10'
	MOVWF	Param79
	CALL	Fix_decbyte
	MOVF	Param78,W
	BTFSS	STATUS,Z	;skip if 0
	GOTO	Disp_decbyteW_2	;secnd digit not zero
	BTFSC	Param71,0
	GOTO	Disp_decbyteW_2	;prev digit was shown 
	BTFSC	DispDec2pl	; show 2 places?
	GOTO	Disp_decbyteW_2	;Display 2nd digit 0..9
	BTFSS	DispLSpaces
	GOTO	Disp_decbyteW_3
	MOVLW	' '
	GOTO	Disp_decbyteW_2S
;
Disp_decbyteW_2	ADDLW	'0'
Disp_decbyteW_2S	CALL	DisplayOrPut
;
Disp_decbyteW_3	MOVF	Param77,W
	ADDLW	'0'
	BCF	DispDec3pl
	BCF	DispDec2pl
	GOTO	DisplayOrPut
;
;==============================================================================
; Used to convert a word value to a string
; Entry: Param7A:Param79=multiplier (10000,1000,100 or 10), Param77:Param76=data
; Exit: Param77:Param76 remainder, Param78=result('0'..'9')
; RAM used: Param76, Param77, Param78, Param79, Param7A
; Calls:(0) none
;
Fix_decword	CLRF	Param78
;if multiplier >= data
Fix_decword_L1	MOVF	Param7A,W
	SUBWF	Param77,W	
	BTFSC	STATUS,Z
	GOTO	Fix_decword_1	;high data = high multi
	BTFSS	STATUS,C	;skip if not barrowed data>=multi
	GOTO	Fix_decword_End	;high data < high multiplier
	GOTO	Fix_decword_2	;high data > high multiplier
Fix_decword_1	MOVF	Param79,W
	SUBWF	Param76,W	;low data - low multi
	BTFSS	STATUS,C	;skip if not barrowed data>=multi
	GOTO	Fix_decword_End	;data < multiplier
;result++
;data -= multiplier
Fix_decword_2	INCF	Param78,F
	MOVF	Param79,W
	SUBWF	Param76,F	;low data - low multi
	BTFSS	STATUS,C	; skip if not barrowed
	DECF	Param77,F
	MOVF	Param7A,W
	SUBWF	Param77,F	;high data - high multi
	GOTO	Fix_decword_L1	;Param77>=100
; else done
Fix_decword_End	RETURN
;
	if UsesNum2Str
;============================================================================================
; Convert an Int16 (Param77:Param76) to a pStr at txbuff
;
; Entry: Int16 in Param77:Param76
; Exit: pStr at txbuff
; RAM used: Param76, Param77, Param78, Param7A, Param7B, FSR
; Calls: (1+1) Disp_decword
;
Num2Str	CLRF	STATUS	;saves 1 byte over mBank0
	MOVLW	txbuff+1	;string
	MOVWF	FSR
;	BCF	STATUS,IRP	;banks 0 and 1
	CLRF	Param7B	;len
;
	BSF	NumsToRam
	CALL	Disp_decword
	BCF	NumsToRam
;
	GOTO	NumsToRamSetLen
;
	endif
;===============================================================================================
; 16 bit version of Disp_decbyteW
; if DispDec2pl is cleared
;  output to DisplaysW is '00000'..'65535'
;  else output to DisplaysW is '##0.00'..'655.35'
; Enrty: Param77:Param76  16 bit value
; Exit: none
; RAM used: Param76, Param77, Param78, Param79, Param7A
; Calls: (1+2) Fix_decword, DisplaysW
;
Disp_decword	mBank0
	BTFSC	DispDec2pl
	BSF	Disp_LZO
	BTFSC	DispDec1pl
	BSF	Disp_LZO
	MOVLW	low d'10000'
	MOVWF	Param79
	MOVLW	high d'10000'
	MOVWF	Param7A
	CALL	Fix_decword	;(1+0)
	MOVF	Param78,W
	BTFSS	Disp_LZO	;if set ##0.00
	GOTO	Disp_decword_1	; else disp 0
	BTFSC	STATUS,Z	; don't disp 0
	GOTO	Disp_decword_2A	; show a <space> instead
Disp_decword_1	ADDLW	'0'
	BCF	Disp_LZO
Disp_decword_1sp	CALL	DisplayOrPut	;(1+2)
	GOTO	Disp_decword_2
;
Disp_decword_2A	MOVLW	' '
	BTFSS	Disp_NLS
	GOTO	Disp_decword_1sp
;
Disp_decword_2	MOVLW	low d'1000'
	MOVWF	Param79
	MOVLW	high d'1000'
	MOVWF	Param7A
	CALL	Fix_decword
	MOVF	Param78,W
	BTFSS	Disp_LZO
	GOTO	Disp_decword_3
;
	BTFSC	STATUS,Z	; don't disp 0
	GOTO	Disp_decword_4A	; show a <space> instead
Disp_decword_3	ADDLW	'0'
	BCF	Disp_LZO
Disp_decword_3Sp	CALL	DisplayOrPut
	GOTO	Disp_decword_4
;
Disp_decword_4A	MOVLW	' '
	BTFSS	Disp_NLS
	GOTO	Disp_decword_3Sp
;
Disp_decword_4	MOVLW	d'100'
	MOVWF	Param79
	CLRF	Param7A
	CALL	Fix_decword
	MOVF	Param78,W
	BTFSS	Disp_LZO
	GOTO	Disp_decword_5LZ
	BTFSS	DispDec1pl
	GOTO	Disp_decword_5LZ
	SKPNZ		; don't disp 0
	GOTO	Disp_decword_5D	; show a <space> instead
;
Disp_decword_5LZ	ADDLW	'0'
	BCF	Disp_LZO
Disp_decword_4sp	CALL	DisplayOrPut
	GOTO	Disp_decword_5B
;
Disp_decword_5D	MOVLW	' '
	BTFSS	Disp_NLS
	GOTO	Disp_decword_4sp
;
Disp_decword_5B	BTFSS	DispDec2pl
	GOTO	Disp_decword_5
	MOVLW	'.'
	CALL	DisplayOrPut
;
Disp_decword_5	MOVLW	d'10'
	MOVWF	Param79
	CLRF	Param7A
	CALL	Fix_decword
	MOVF	Param78,W
	ADDLW	'0'
	CALL	DisplayOrPut
;
	BTFSS	DispDec1pl
	GOTO	Disp_decword_7
	MOVLW	'.'
	CALL	DisplayOrPut
Disp_decword_7	MOVLW	'0'
	ADDWF	Param76,W
;reset defaults
	BCF	DispDec3pl
	BCF	DispDec2pl
	BCF	DispDec1pl
	BCF	Disp_LZO
	BCF	Disp_NLS
;
;================================================================
;
DisplayOrPut	mBank0
	BTFSC	NumsToNic
	GOTO	DOP_Put
	BTFSC	NumsToRam
	GOTO	DOP_Ram
	GOTO	DisplaysW
DOP_Put
	if UsesNIC
	mCall0To1	putnic_checkbyte
	endif
	RETURN
;
DOP_Ram	MOVWF	INDF
	INCF	FSR,F
	RETURN
;
	if Uses3BNums
;==============================================================================
; Used to convert a 3 byte value to a string
; Entry: Param7B:Param7A:Param79=multiplier (1,000,000, 100,000, 10,000, 1,000, 100 or 10)
;   , Param77:Param76:Param74=data
; Exit: Param77:Param76:Param74 remainder, Param78=result(0..9)
; RAM used: Param74, Param76, Param77, Param78, Param79, Param7A, Param7B
; Calls:(0) none
;
Fix_dec3B	CLRF	Param78
;if multiplier >= data
Fix_dec3B_L1	MOVF	Param7B,W
	SUBWF	Param77,W	
	BTFSC	STATUS,Z
	GOTO	Fix_dec3B_3	;high data = high multi
	BTFSS	STATUS,C	;skip if not barrowed data>=multi
	GOTO	Fix_dec3B_End	;high data < high multiplier
	GOTO	Fix_dec3B_2	;high data > high multiplier
;
Fix_dec3B_3	MOVF	Param7A,W
	SUBWF	Param76,W	
	BTFSC	STATUS,Z
	GOTO	Fix_dec3B_1	;mid data = mid multi
	BTFSS	STATUS,C	;skip if not barrowed data>=multi
	GOTO	Fix_dec3B_End	;mid data < mid multiplier
	GOTO	Fix_dec3B_2	;mid data > mid multiplier
Fix_dec3B_1	MOVF	Param79,W
	SUBWF	Param74,W	;low data - low multi
	BTFSS	STATUS,C	;skip if not barrowed data>=multi
	GOTO	Fix_dec3B_End	;data < multiplier
;result++
;data -= multiplier
Fix_dec3B_2	INCF	Param78,F
	MOVF	Param79,W
	SUBWF	Param74,F	;low data - low multi
	BTFSS	STATUS,C	; skip if not barrowed
	DECF	Param76,F
	MOVF	Param7A,W
	SUBWF	Param76,F	;mid data - mid multi
	BTFSS	STATUS,C	; skip if not barrowed
	DECF	Param77,F
	MOVF	Param7B,W
	SUBWF	Param77,F	;high data - high multi
	GOTO	Fix_dec3B_L1	;Param77>=100
; else done
Fix_dec3B_End	MOVLW	'0'	
	ADDWF	Param78,F
	RETURN
;
	endif
;
	if UsesNum3BToStr
;===============================================================================================
; Convert an Int24 at Param77:Param76:Param74 to a pStr at txbuff
;
; Enrty: Param77:Param76:Param74
; Exit: pStr at txbuff
; RAM used: Param74,Param76, Param77, Param78, Param79, Param7A, Param7B, FSR
; Calls: (1+1) Disp_dec3B
;
Num3BToStr	CLRF	STATUS	;saves 1 byte over mBank0
	MOVLW	txbuff+1	;string
	MOVWF	FSR
;	BCF	_IRP	;banks 0 and 1
;
	BSF	NumsToRam
	CALL	Disp_dec3B
	BCF	NumsToRam
;
	endif
;
	if UsesNum2Str | UsesNum3BToStr
NumsToRamSetLen	MOVLW	txbuff+1
	SUBWF	FSR,W	;W=FSR-(txbuff+1)
	MOVWF	Param7B
	MOVLW	txbuff
	MOVWF	FSR
	MOVFW	Param7B
	MOVWF	INDF
	RETURN
	endif
;
	if Uses3BNums
;===============================================================================================
; 24 bit version of Disp_decbyteW
; output to DisplaysW is '00000000'..'16777215'
; Enrty: Param77:Param76:Param74  24 bit value little endian
; Options: Set flag Disp_LZO for leading zero omission. This flag gets cleared.
; Exit: none
; RAM used: Param74,Param76, Param77, Param78, Param79, Param7A, Param7B, FSR
; Calls: (1+2) Fix_dec3B, DisplaysW
;
Disp_dec3B	mBank0
	MOVLW	0x80	;d'10,000,000'
	MOVWF	Param79	;=0x989680
	MOVLW	0x96
	MOVWF	Param7A
	MOVLW	0x98
	MOVWF	Param7B
	CALL	Disp_dec3B_1
;
	MOVLW	0x40	;d'1,000,000'
	MOVWF	Param79	;=0x0F4240
	MOVLW	0x42
	MOVWF	Param7A
	MOVLW	0x0F
	MOVWF	Param7B
	CALL	Disp_dec3B_1
;
	MOVLW	0xA0	;d'100,000'
	MOVWF	Param79	;=0x0186A0
	MOVLW	0x86
	MOVWF	Param7A
	MOVLW	0x01
	MOVWF	Param7B
	CALL	Disp_dec3B_1
;
	MOVLW	low d'10000'	;d'10,000'
	MOVWF	Param79	;=0x002710
	MOVLW	high d'10000'
	MOVWF	Param7A
	CLRF	Param7B
	CALL	Disp_dec3B_1
;
	MOVLW	low d'1000'
	MOVWF	Param79
	MOVLW	high d'1000'
	MOVWF	Param7A
	CALL	Disp_dec3B_1
;
	MOVLW	d'100'
	MOVWF	Param79
	CLRF	Param7A
	CALL	Disp_dec3B_1
;
	MOVLW	d'10'
	MOVWF	Param79
	CALL	Disp_dec3B_1
;
	MOVLW	'0'
	ADDWF	Param74,W
	BCF	Disp_LZO
	GOTO	Disp_dec3B_2
;
Disp_dec3B_1	CALL	Fix_dec3B
	BTFSS	Disp_LZO
	GOTO	Disp_dec3B_3
	MOVLW	'0'
	SUBWF	Param78,W
	SKPNZ
	RETURN
;reset defaults
	BCF	Disp_LZO
	BCF	Disp_NLS
Disp_dec3B_3	MOVF	Param78,W
Disp_dec3B_2	GOTO	DisplayOrPut
;
	endif
;=================================================================================
; Read Data from input device
;
;  Note: Address Enable ON, IORead ON, Get Data, IORead OFF, Address Enable OFF
;
; Entry: W=Select Value (Select0,SelectSRAM, etc.)
; Exit: W = data from port
; Ram used: Param78 (verified 2/26/03)
; Calls: (0) none
;
ReadData	MOVWF	Param78
	mBank1
	if UsesRS232BufIO
	BCF	_GIE
	BTFSC	_GIE
	GOTO	$-2
	endif
	MOVLW	All_In
	MOVWF	TRISD
	BCF	STATUS,RP0	;Bank0
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORWF	Param78,W
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	BCF	PORTB,IORead
	NOP		;wait 200nS
	MOVF	PORTD,W
	BSF	PORTB,IORead
	BSF	PORTB,SelectEnable
	if UsesRS232BufIO
	BSF	_GIE
	endif
	RETURN	
;
;=================================================================================
; Set the low 8 address bits to the value in the W
;
; Entry: W= and 8 bit address
; Exit: CurrentAddr0 is changed
; RAM used: none (verified 2/26/03)
; Calls:(0) none
;
Set8bitAddr
	if UsesRS232BufIO
	BCF	_GIE
	BTFSC	_GIE
	GOTO	$-2
	endif
	mSet8bitAddr
	if UsesRS232BufIO
	BSF	_GIE
	endif
	RETURN
;
;
	if UsesSRAM
;=================================================================================
; Put the SRAM address on the address bus
; Entry:SRAM_Addr
; Exit:address bus and CurrentAddr = SRAM_Addr
;	PORTD is set for output
; RAM used: none (verified 2/26/03)
; Calls:(0) none
;
SetSRAM_Addr	mBank1
	if UsesRS232BufIO
	BCF	_GIE
	BTFSC	_GIE
	GOTO	$-2
	endif
	MOVLW	All_Out
	MOVWF	TRISD
	BSF	STATUS,RP1	;Bank3
	MOVF	SRAM_Addr0,W
	SUBWF	CurrentAddr0,W
	BTFSC	STATUS,Z
	GOTO	SetSRAM_Addr_1
	MOVF	SRAM_Addr0,W
	MOVWF	CurrentAddr0
	mBank0
	MOVWF	PORTD
;
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	Select0
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	BSF	PORTB,SelectEnable
;
	mBank3
SetSRAM_Addr_1	MOVF	SRAM_Addr1,W
	SUBWF	CurrentAddr1,W
	BTFSC	STATUS,Z
	GOTO	SetSRAM_Addr_2
	MOVF	SRAM_Addr1,W
	MOVWF	CurrentAddr1
	mBank0
	MOVWF	PORTD
;
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	Select1
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	BSF	PORTB,SelectEnable
;
	mBank3
SetSRAM_Addr_2	MOVF	SRAM_Addr2,W
	SUBWF	CurrentAddr2,W
	BTFSC	STATUS,Z
	GOTO	Bank0Rtn
	MOVF	SRAM_Addr2,W
	MOVWF	CurrentAddr2
	mBank0
	MOVWF	PORTD
;
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	Select2
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	BSF	PORTB,SelectEnable
;
	if UsesRS232BufIO
	BSF	_GIE
	endif
	GOTO	Bank0Rtn
;
;=================================================================================
; Offset the SRAM_Addr by W
; Entry:W=Offset
; Exit: none
; RAM used: none (verified 2/26/03)
; Calls:(0) none
;
SRAM_OffsetAddr	mBank3
	ADDWF	SRAM_Addr0,F
	BTFSC	STATUS,C
	INCFSZ	SRAM_Addr1,F
	GOTO	Bank0Rtn
	INCF	SRAM_Addr2,F
	GOTO	Bank0Rtn
;
;=================================================================================
; Increments the SRAM_Addr, if past end (>=0x080000) roll over to 0x000000
; Entry:none
; Exit:W = 0x00, Z=1, if address = 0x000000
; RAM used: none (verified 2/26/03)
; Calls:(0) none
;
SRAM_NextAddr	mBank3
	INCFSZ	SRAM_Addr0,F
	GOTO	SRAM_NextAddr_1
	INCFSZ	SRAM_Addr1,F
	GOTO	SRAM_NextAddr_1
	INCF	SRAM_Addr2,F
SRAM_NextAddr_1	MOVLW	0xF8	;SRAM ends at 0x07FFFF
	ANDWF	SRAM_Addr2,W
	BTFSC	STATUS,Z
	GOTO	SRAM_NextAddr_2
	CLRF	SRAM_Addr0
	CLRF	SRAM_Addr1
	CLRF	SRAM_Addr2
SRAM_NextAddr_2	MOVF	SRAM_Addr0,W
	IORWF	SRAM_Addr1,W
	IORWF	SRAM_Addr2,W
	GOTO	Bank0Rtn
;
;=================================================================================
; Decrements the SRAM_Addr, if less than 0x000000 then set to 0x07FFFF
; Entry:none
; Exit:none
; RAM used: none (verified 2/26/03)
; Calls:(0) none
;
SRAM_PrevAddr	mBank3
	DECF	SRAM_Addr0,F
	INCFSZ	SRAM_Addr0,W
	GOTO	SRAM_PrevAddr_1
	DECF	SRAM_Addr1,F
	INCFSZ	SRAM_Addr1,W
	GOTO	SRAM_PrevAddr_1
	DECF	SRAM_Addr2,F
SRAM_PrevAddr_1	MOVLW	0xFF
	SUBWF	SRAM_Addr2,W
	BTFSS	STATUS,Z
	GOTO	Bank0Rtn
	MOVLW	0x07
	MOVWF	SRAM_Addr2
	MOVLW	0xFF
	MOVWF	SRAM_Addr1
	MOVWF	SRAM_Addr0
	GOTO	Bank0Rtn
;
;=================================================================================
; Write the value in the W to SRAM address SRAM_Addr then increment address
;
; Entry: W=data to write, SRAM_Addr=SRAM address
; Exit: none
; RAM used:Param78 (verified 2/26/03)
; Calls:(1+0) SetSRAM_Addr, SRAM_NextAddr
;
SRAM_WritePI	MOVWF	Param78
	CALL	SetSRAM_Addr
	CALL	SRAM_NextAddr
	GOTO	SRAM_Write_1
;
;=================================================================================
; Write the value in the W to SRAM address SRAM_Addr
;
; Entry: W=data to write, SRAM_Addr=SRAM address
; Exit: Param78=data
; RAM used: Param78 (verified 2/26/03)
; Calls:(1+0) SetSRAM_Addr
;
SRAM_Write	MOVWF	Param78
	CALL	SetSRAM_Addr
SRAM_Write_1	MOVF	Param78,W
;
	if UsesRS232BufIO
	BCF	_GIE
	BTFSC	_GIE
	GOTO	$-2
	endif
;
	MOVWF	PORTD
	BSF	PORTB,IORead	;OE* = inactive
	BCF	PORTB,IOWrite
;
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	SelectSRAM
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	BSF	PORTB,SelectEnable
;
	BSF	PORTB,IOWrite	
	if UsesRS232BufIO
	BSF	_GIE
	endif
	RETURN
;
;
;=================================================================================
; Read the value in SRAM address SRAM_Addr into the W then decrement address
;
; Entry: SRAM_Addr=SRAM address
; Exit: W = value from SRAM
; RAM used: none (verified 2/26/03)
; Calls:(1+0) SetSRAM_Addr, SRAM_NextAddr
;
SRAM_ReadPD	CALL	SetSRAM_Addr
	CALL	SRAM_PrevAddr
	GOTO	SRAM_Read_1
;
	endif
;
	if UsesDataROM
;=================================================================================
; Set SRAM address to evDataROM+W then SRAM_ReadPI
;
; Entry: W=DataRom offset
; Exit: W = value from SRAM, SRAM_Addr=evDataROM+W+1
; RAM used: none (verified 8/15/03)
; Calls:(1+0) SetSRAM_Addr, SRAM_NextAddr
;
SRAM_ReadDR	mBank3
	MOVWF	SRAM_Addr0
	MOVLW	low evDataROM
	MOVWF	SRAM_Addr1
	MOVLW	high evDataROM
	MOVWF	SRAM_Addr2
;
; fall through to SRAM_ReadPI
;
	endif
;
	if UsesSRAM
;=================================================================================
; Read the value in SRAM address SRAM_Addr into the W then increment address
;
; Entry: SRAM_Addr=SRAM address
; Exit: W = value from SRAM
; RAM used: none (verified 2/26/03)
; Calls:(1+0) SetSRAM_Addr, SRAM_NextAddr
;
SRAM_ReadPI	CALL	SetSRAM_Addr
	CALL	SRAM_NextAddr
	GOTO	SRAM_Read_1
;
	endif
;
	if SRAM_Strings
;=============================================================================================
; Entry: Param7F=String Number (0..n), Param7D=Character Number
; Exit: W=Character
; RAM used: Param7D, Param7F  (verified 10/2/02)
; Calls:(1+0) SetSRAM_Addr
; 
; Strings were stored in SRAM at power up
; String Zero is at (evStrings x 256) + (String Number x 8) + Character Number
;
StringDispatch	mBank3
	MOVLW	high evStrings
	MOVWF	SRAM_Addr2	;0x01
	CLRF	SRAM_Addr1
	BCF	STATUS,C
	RLF	Param7F,W	;x2
	MOVWF	SRAM_Addr0
	RLF	SRAM_Addr1,F
	RLF	SRAM_Addr0,F	;x4
	RLF	SRAM_Addr1,F
	RLF	SRAM_Addr0,F	;x8
	RLF	SRAM_Addr1,F
;
	MOVLW	low evStrings	;0x02
	ADDWF	SRAM_Addr1,F	;0x02..0x08
	MOVF	Param7D,W
	ADDWF	SRAM_Addr0,F
	BTFSC	STATUS,C
	INCF	SRAM_Addr1,F
;
; Fall through to SRAM_Read
	endif
;
	if UsesSRAM
;=================================================================================
; Read the value in SRAM address SRAM_Addr into the W
; Entry: SRAM_Addr=SRAM address
; Exit: W = value from SRAM
; RAM used: none (verified 2/26/03)
; Calls:(1+0) SetSRAM_Addr
;
SRAM_Read	CALL	SetSRAM_Addr
SRAM_Read_1	BSF	STATUS,RP0	;Bank1
	if UsesRS232BufIO
	BCF	_GIE
	BTFSC	_GIE
	GOTO	$-2
	endif
	MOVLW	All_In
	MOVWF	TRISD
	BCF	STATUS,RP0	;Bank0
	BSF	PORTB,IOWrite	;R/W* = R
	BCF	PORTB,IORead	;OE* = active
;
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	SelectSRAM
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	NOP
	MOVF	PORTD,W
	BSF	PORTB,SelectEnable
;
	BSF	PORTB,IORead	
	if UsesRS232BufIO
	BSF	_GIE
	endif
	RETURN
;
;
	if Do_SRAM_Test
;=================================================================================
; Test the Static RAM 
; 1: 55 >> 000000 (display 5 or -)
; 2: AA >> 000000 (display 5A)
; 3: low byte from address >> all (display 5A.1)
; 4: middle byte from address >> all (diplay 5A.1.2)
; 5: high byte from address >> all (diplay 5A.1.2.3)
;  if all 5 tests are ok and Param70<>0 then loop and test again
; 6: clear all locations to 0x00
;
; Entry: Param70=0 = single pass, 1=loop forever.
; Exit: if Param70<>0 does NOT exit
; RAM used: Param70, Param75, Param78, Param79, Param7A, Param7B
; Calls:(1+3) lcd_GotoLineW, DisplaysW, SetSRAM_Addr, SRAM_NextAddr, SRAM_Write, SRAM_Read
;
SRAM_Test	MOVLW	0x02
	CALL	lcd_GotoLineW	;goto begining of 3rd line
	MOVLW	'S'
	CALL	DisplaysW
	MOVLW	'R'
	CALL	DisplaysW
	MOVLW	'A'
	CALL	DisplaysW
	MOVLW	'M'
	CALL	DisplaysW
	MOVLW	':'
	CALL	DisplaysW
	CALL	ZeroSRAM_Addr	; initialize address
; test 1
	MOVLW	0x55
	CALL	SRAM_Write	; write 0x55 to location 0
	CALL	SRAM_Read
	SUBLW	0x55
	BTFSS	STATUS,Z
	GOTO	SRAM_Test_E1
	MOVLW	'5'
	CALL	DisplaysW
; test 2
	MOVLW	0xAA
	CALL	SRAM_Write	; write 0x55 to location 0
	CALL	SRAM_Read
	SUBLW	0xAA
	BTFSS	STATUS,Z
	GOTO	SRAM_Test_E1
	MOVLW	'A'
	CALL	DisplaysW
; test 3
; Write the low address value to all bytes.
;
SRAM_Test_L1	mBank3
	MOVF	SRAM_Addr0,W
	CALL	SRAM_Write
	CALL	SRAM_NextAddr
	BTFSS	STATUS,Z
	GOTO	SRAM_Test_L1
	MOVLW	'.'
	CALL	DisplaysW
;
SRAM_Test_L2	CALL	SRAM_Read
	mBank3
	SUBWF	SRAM_Addr0,W
	BTFSS	STATUS,Z
	GOTO	SRAM_Test_E2
	CALL	SRAM_NextAddr
	BTFSS	STATUS,Z
	GOTO	SRAM_Test_L2
	MOVLW	'1'
	CALL	DisplaysW
; test 4
SRAM_Test_L3	mBank3
	MOVF	SRAM_Addr1,W
	CALL	SRAM_Write
	CALL	SRAM_NextAddr
	BTFSS	STATUS,Z
	GOTO	SRAM_Test_L3
	MOVLW	'.'
	CALL	DisplaysW
;
SRAM_Test_L4	CALL	SRAM_Read
	mBank3
	SUBWF	SRAM_Addr1,W
	BTFSS	STATUS,Z
	GOTO	SRAM_Test_E2
	CALL	SRAM_NextAddr
	BTFSS	STATUS,Z
	GOTO	SRAM_Test_L4
	MOVLW	'2'
	CALL	DisplaysW
; test 5
SRAM_Test_L5	mBank3
	MOVF	SRAM_Addr2,W
	CALL	SRAM_Write
	CALL	SRAM_NextAddr
	BTFSS	STATUS,Z
	GOTO	SRAM_Test_L5
	MOVLW	'.'
	CALL	DisplaysW
;
SRAM_Test_L6	CALL	SRAM_Read
	mBank3
	SUBWF	SRAM_Addr2,W
	BTFSS	STATUS,Z
	GOTO	SRAM_Test_E2
	CALL	SRAM_NextAddr
	BTFSS	STATUS,Z
	GOTO	SRAM_Test_L6	
	MOVLW	'3'
	CALL	DisplaysW
	CALL	Delay1Sec
	BTFSC	Param70,0	;Param70=0
	GOTO	SRAM_Test	;No, Loop forever
; zero all
; initialize address
	endif		; Do_SRAM_Test
	if Do_ZeroRAM
;=================================================================================
; Zero the Static RAM 
; Put 0x00 in every location read back and display error if cannot zero
;
; Entry: none
; Exit: none, if error then doesn't exit
; RAM used: Param70, Param71, Param72, Param78 (verified 2/26/03)
; Calls:(1+0) SetSRAM_Addr, SRAM_Write_1, SRAM_Read_1,
;  if error calls:(1+3) lcd_GotoLineW, DisplaysW, SRAM_Read, Disp_Hex_Byte
;
SRAM_Zero	CLRF	Param70	; aka SRAM_Addr0
	CLRF	Param71	; aka SRAM_Addr1
	CLRF	Param72	; aka SRAM_Addr2
	CALL	ZeroSRAM_Addr
	CLRF	Param78
;
SRAM_Zero_L1	CALL	SRAM_Write_1
	CALL	SRAM_Read_1
	BTFSS	STATUS,Z	; skip if good
	GOTO	SRAM_Zero_Err
; next address 0
	BSF	STATUS,RP0	;Bank1
	MOVLW	All_Out
	MOVWF	TRISD
	BCF	STATUS,RP0	;Bank0
	INCF	Param70,F	;aka SRAMAddr0
	MOVF	Param70,W
	MOVWF	PORTD
;
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	Select0
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	BSF	PORTB,SelectEnable
	MOVF	Param70,W
	BTFSS	STATUS,Z
	GOTO	SRAM_Zero_L1
; next address 1
	INCF	Param71,F	;aka SRAMAddr0
	MOVF	Param71,W
	MOVWF	PORTD
;
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	Select1
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	BSF	PORTB,SelectEnable
;
	ifdef evEndOfSRAM
	MOVLW	low evEndOfSRAM
	SUBWF	Param71,W
	BTFSS	STATUS,Z
	GOTO	SRAM_Zero_NotDone
	MOVLW	high evEndOfSRAM
	SUBWF	Param72,W
	BTFSS	STATUS,Z
	endif
	GOTO	SRAM_Zero_NotDone
;
; fall through to ZeroSRAM_Addr
;=======================================================================================
; Setup the SRAM address buffers and variables
;
ZeroSRAM_Addr	mBank3
	MOVLW	0xFF
	MOVWF	SRAM_Addr0
	MOVWF	SRAM_Addr1
	MOVWF	SRAM_Addr2
	CALL	SetSRAM_Addr
	CALL	SRAM_NextAddr
	GOTO	SetSRAM_Addr
;
;=======================================================================================
;
SRAM_Zero_NotDone
;
	MOVF	Param71,W
	BTFSS	STATUS,Z
	GOTO	SRAM_Zero_L1
; next address 2
	INCF	Param72,F
	MOVF	Param72,W
	MOVWF	PORTD
;
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	Select2
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	BSF	PORTB,SelectEnable
	MOVF	Param72,W
;
	ANDLW	0xF8
	SKPNZ
	GOTO	SRAM_Zero_L1
	GOTO	ZeroSRAM_Addr
;
;
SRAM_Test_E2
SRAM_Test_E1
SRAM_Zero_Err	
	if UsesLCD
	MOVLW	0x02
	CALL	lcd_GotoLineW	;goto begining of 3rd line
	ifdef eSRAMErrStr
	MOVLW	eSRAMErrStr
	CALL	DispSplashScrn_1
	else
	MOVLW	'S'
	CALL	DisplaysW
	endif
	endif
;
	CALL	SRAM_Read
	CALL	Disp_Hex_Byte
SRAM_Zero_Stop	GOTO	SRAM_Zero_Stop	; loop until reset
;
	endif
	endif
;
	if UsesPushPopParams
;=================================================================================
; Push Params76..7D stack++ (8 bytes)
;
; Entry: Params76..7D values to push
; Exit: STATUS, FSR and W are unchanged
; RAM used: Param7F, SaveStatus, FSR_Save, PPCounter, StackBase... (verified 2/26/03)
; Calls:(0) none
;
PushParams	MOVWF	Param7F
	MOVF	STATUS,W
	mBank3
	MOVWF	SaveStatus
;
	MOVF	FSR,W	;save FSR
	MOVWF	FSR_Save
;
	MOVLW	0x08	;add 8
	MOVWF	PPCounter
;
PushParams_L1	MOVLW	Param76-1
	ADDWF	PPCounter,W
	MOVWF	FSR	;075+PPCounter or 07D..076
	BCF	STATUS,IRP	;Bank0-1
	MOVF	INDF,W
	MOVWF	PPTemp
;
	MOVLW	low StackBase
	ADDWF	StackPtr,W
	MOVWF	FSR
	INCF	StackPtr,F
	BSF	STATUS,IRP	;Bank2-3
	MOVF	PPTemp,W
	MOVWF	INDF	;1A0...
	DECFSZ	PPCounter,F
	GOTO	PushParams_L1
;
	MOVF	FSR_Save,W	;restore FSR
	MOVWF	FSR
;
	MOVF	SaveStatus,W
	MOVWF	STATUS
;
	SWAPF	Param7F,F	; swap is used because status bits are unaffected
	SWAPF	Param7F,W	; restore W register contents
	RETURN
;
;=================================================================================
; POP Params76..7D --stack
;
; Entry: none
; Exit: STATUS, FSR and W are unchanged, Params76..7D (8 bytes from stack)
; RAM used: Param7F, SaveStatus, FSR_Save, PPCounter, StackBase... (verified 2/26/03)
; Calls:(0) none
;
PopParams	MOVWF	Param7F
	MOVF	STATUS,W
	mBank3
	BSF	STATUS,IRP	;Bank3 too
	MOVWF	SaveStatus
;
	MOVF	FSR,W	;save FSR
	MOVWF	FSR_Save
;
	MOVLW	0x08	;add 8
	MOVWF	PPCounter
;
PopParams_L1	DECF	StackPtr,F
	MOVLW	low StackBase
	ADDWF	StackPtr,W
	MOVWF	FSR
	BSF	STATUS,IRP	;Bank2-3
	MOVF	INDF,W
	MOVWF	PPTemp
;
	MOVF	PPCounter,W
	SUBLW	Param7D+1
	MOVWF	FSR	;07E-PPCounter or 076..07D
	BCF	STATUS,IRP	;Bank0-1	
	MOVF	PPTemp,W
	MOVWF	INDF	;1A0...
	DECFSZ	PPCounter,F
	GOTO	PopParams_L1
;
	MOVF	FSR_Save,W	;restore FSR
	MOVWF	FSR
;
	MOVF	SaveStatus,W
	MOVWF	STATUS
	SWAPF	Param7F,F	; swap is used because status bits are unaffected
	SWAPF	Param7F,W	; restore W register contents
	RETURN
;
	endif
	if UsesPushPop
;=================================================================================
; Push the W onto the stack++
;
; Entry: W = value to be pushed
; Exit: STATUS, FSR and W are unchanged
; RAM Used: Param7F, SaveStatus, FSR_Save, PPCounter, StackBase (verified 2/26/03)
; Calls:(0) none
;
Push	MOVWF	Param7F
	MOVF	STATUS,W
	mBank3
	BankISel	StackBase
	MOVWF	SaveStatus
;
	MOVF	FSR,W	;save FSR
	MOVWF	FSR_Save
;
	MOVF	StackPtr,W
	INCF	StackPtr,F
	ADDLW	low StackBase
	MOVWF	FSR
;
	MOVLW	StackPtrMask	;0x0F or 0x1F
	ANDWF	StackPtr,F	;Prevent stack from killing Param70
;
	MOVF	Param7F,W
	MOVWF	INDF	;1A0...
;
	MOVF	FSR_Save,W	;restore FSR
	MOVWF	FSR
;
	MOVF	SaveStatus,W
	MOVWF	STATUS
	SWAPF	Param7F,F	; swap is used because status bits are unaffected
	SWAPF	Param7F,W	; restore W register contents
	RETURN
;
;=================================================================================
; Pop the W from the --stack
; STATUS is changed by MOVF Param7F,W  FSR is unchanged
;
; Entry: none
; Exit: W = value from top of stack
; RAM Used: Param7F, SaveStatus, FSR_Save, PPCounter, StackBase (verified 2/26/03)
; Calls:(0) none
;
Pop	MOVF	STATUS,W
	mBank3
	BankISel	StackBase	;Bank3 too
	MOVWF	SaveStatus
;
	MOVF	FSR,W	;save FSR
	MOVWF	FSR_Save
;
	DECF	StackPtr,F
;
	MOVLW	StackPtrMask	;0x0F or 0x1F
	ANDWF	StackPtr,F	;Prevent stack under flow
;
	MOVF	StackPtr,W
	ADDLW	low StackBase
	MOVWF	FSR
	MOVF	INDF,W	;1A0...
	MOVWF	Param7F
;
	MOVF	FSR_Save,W	;restore FSR
	MOVWF	FSR
;
	MOVF	SaveStatus,W
	MOVWF	STATUS
	MOVF	Param7F,W	; we want the Z bit to be correct
	RETURN
	endif		; UsesPushPop
;
	if UsesSRamPushPopPrm
;=================================================================================
; Push Params76..7D stack++ (8 bytes)
;
; Entry: Params76..7D values to push
; Exit: STATUS, FSR and W are unchanged
; RAM used: Param7F, SaveStatus, FSR_Save, PPCounter (verified 2/26/03)
; Calls:(1+1) SRAM_Write, SRAM_NextAddr
;
PushParams	MOVWF	Param7F
	MOVF	STATUS,W
	mBank3
	MOVWF	SaveStatus
;
	MOVF	FSR,W	;save FSR
	MOVWF	FSR_Save
;
	MOVF	StackPtr,W
	MOVWF	SRAM_Addr0
	ADDLW	0x08
	MOVWF	StackPtr
	MOVLW	low evParamStack
	MOVWF	SRAM_Addr1
	MOVLW	high evParamStack
	MOVWF	SRAM_Addr2
;
	MOVLW	0x08	;add 8
	MOVWF	PPCounter
;
	MOVLW	Param76
	MOVWF	FSR	;075+PPCounter or 07D..076
;
PushParams_L1	MOVF	INDF,W
	CALL	SRAM_WritePI
	INCF	FSR,F
	DECFSZ	PPCounter,F
	GOTO	PushParams_L1
;
	MOVF	FSR_Save,W	;restore FSR
	MOVWF	FSR
;
	MOVF	SaveStatus,W
	MOVWF	STATUS
;
	SWAPF	Param7F,F	; swap is used because status bits are unaffected
	SWAPF	Param7F,W	; restore W register contents
	RETURN
;
;=================================================================================
; POP Params76..7D --stack
;
; Entry: none
; Exit: STATUS, FSR and W are unchanged, Params76..7D (8 bytes from stack)
; RAM used: Param7F, SaveStatus, FSR_Save, PPCounter, Params76..7D (verified 2/26/03)
; Calls:(0) none
;
PopParams	MOVWF	Param7F
	MOVF	STATUS,W
	mBank3
	BSF	STATUS,IRP	;Bank3 too
	MOVWF	SaveStatus
;
	MOVF	FSR,W	;save FSR
	MOVWF	FSR_Save
;
	DECF	StackPtr,W
	MOVWF	SRAM_Addr0
	ADDLW	0xF9	;-7
	MOVWF	StackPtr
	MOVLW	low evParamStack
	MOVWF	SRAM_Addr1
	MOVLW	high evParamStack
	MOVWF	SRAM_Addr2
;
	MOVLW	0x08	;add 8
	MOVWF	PPCounter
	MOVLW	Param7D
	MOVWF	FSR	;07E-PPCounter or 076..07D
;
PopParams_L1	CALL	SRAM_Read
	MOVWF	INDF
	CALL	SRAM_PrevAddr
	DECF	FSR,F
;
	DECFSZ	PPCounter,F
	GOTO	PopParams_L1
;
	MOVF	FSR_Save,W	;restore FSR
	MOVWF	FSR
;
	MOVF	SaveStatus,W
	MOVWF	STATUS
	SWAPF	Param7F,F	; swap is used because status bits are unaffected
	SWAPF	Param7F,W	; restore W register contents
	RETURN
;
	endif
	if UsesSRamPushPop
;=================================================================================
; Push the W onto the stack++
;
; Entry: W = value to be pushed
; Exit: STATUS, FSR and W are unchanged
; RAM Used: Param7F, SaveStatus, FSR_Save, PPCounter (verified 2/26/03)
; Calls:(1+1) SRAM_Write
;
Push	MOVWF	Param7F
	MOVF	STATUS,W
	mBank3
	MOVWF	SaveStatus
;
	MOVF	StackPtr,W
	MOVWF	SRAM_Addr0
	INCF	StackPtr,F
	MOVLW	low evParamStack
	MOVWF	SRAM_Addr1
	MOVLW	high evParamStack
	MOVWF	SRAM_Addr2
;
	MOVF	Param7F,W
	CALL	SRAM_Write
;
	MOVF	SaveStatus,W
	MOVWF	STATUS
	SWAPF	Param7F,F	; swap is used because status bits are unaffected
	SWAPF	Param7F,W	; restore W register contents
	RETURN
;
;=================================================================================
; Pop the W from the --stack
; STATUS is changed by MOVF Param7F,W  FSR is unchanged
;
; Entry: none
; Exit: W = value from top of stack
; RAM Used: Param7F, SaveStatus, PPCounter (verified 2/26/03)
; Calls:(1+1) SRAM_Read
;
Pop	MOVF	STATUS,W
	mBank3
	MOVWF	SaveStatus
;
	DECF	StackPtr,F
	MOVWF	StackPtr,W
	MOVWF	SRAM_Addr0
	MOVLW	low evParamStack
	MOVWF	SRAM_Addr1
	MOVLW	high evParamStack
	MOVWF	SRAM_Addr2
;
	CALL	SRAM_Read
	MOVWF	Param7F
;
	MOVF	SaveStatus,W
	MOVWF	STATUS
	MOVF	Param7F,W	; we want the Z bit to be correct
	RETURN
	endif		; UsesSRamPushPop
;
;==================================================================================
; Delay 1 Second
;
; Entry: none
; Exit: none
; RAM used: Param77, Param78, Param79 (verified 2/26/03)
; Calls:(1+0) DelayWmS
;
Delay1Sec	MOVLW	d'250'
	CALL	DelayWmS
	CALL	DelayWmS
	CALL	DelayWmS
;
;==================================================================================
; Delay (value in W) milliseconds  (999978ns/loop + overhead) (Fosc = 19.6608MHz)
;
; Entry: W = mS to delay
; Exit: none
; RAM used: Param77, Param78, Param79 (verified 2/26/03)
; Calls:(0) none
;
;   CLOCK=19660800/4 = 203ns/cycle
;
DelayWmS	MOVWF	Param79	;W*4926+5
	MOVF	Param79,F
	BTFSC	STATUS,Z
	GOTO	DelayWmS_end
DelayWmS_L1	MOVLW	0x06	;3+4632+3+285+3=4926
	MOVWF	Param78
DelayWmS_L2	CLRF	Param77	;6*(4+768)=4632
DelayWmS_L3	DECFSZ	Param77,F	;3*256=768
	GOTO	DelayWmS_L3
	DECFSZ	Param78,F
	GOTO	DelayWmS_L2
	MOVLW	0x5F
	MOVWF	Param77
DelayWmS_L4	DECFSZ	Param77,F	;3*95=285
	GOTO	DelayWmS_L4
	DECFSZ	Param79,F
	GOTO	DelayWmS_L1
DelayWmS_end	RETLW	d'250'
;
;======================================================================================
; Delay uS    1 cycle = .203uS (Fosc = 19.6608MHz)
;
; 0x1F	;(31*3+5)*0.203=19.894uS
;
; Entry: none
; Exit: none
; RAM used: Param77 (verified 2/26/03)
; Calls:(0) none
;
	if UsesDelay10uS
Delay10uS	MOVLW	0x0F	;(15*3+5)*0.203=10.15
	GOTO	DelayWuS
	endif
Delay100uS	MOVLW	0xA3	;(163*3+5)*0.203=100.282
	if UsesDelay40uS
	GOTO	DelayWuS
Delay40uS	MOVLW	0x40	;(64*3+5)*0.203=39.991
	endif
DelayWuS	MOVWF	Param77
DelayWuS_Loop	DECFSZ	Param77,F
	GOTO	DelayWuS_Loop
	RETURN
;
	if UsesLCD
;======================================================================================
;======================================================================================	
; Send a nybble to the LCD
;	
; Entry: W:0..3 = Nibble to send
; Exit: Param78 has the Nibble
; RAM used: Param78 (verified 2/26/03)
; Calls:(0) none
;
lcd_nybble	MOVWF	Param78
	BSF	PORTB,LCD_E	;LCD_E = 1
	MOVLW	0x0F
	ANDWF	Param78,F	;only the low nibble
	MOVLW	0xF0
	ANDWF	PORTD,W	;kill the low nibble
	IORWF	Param78,W	; and replace with bByte's low nibble
	MOVWF	PORTD
	NOP		;delay 400nS
	NOP
	BCF	PORTB,LCD_E	;LCD_E = 0
	RETURN
;
;===================================================================================
; Send LCD command for Disp On, Cursor Off, Blink Off
;
; Entry: none
; Exit: none
; RAM Used: Param78, Param79 (verified 4/17/03)
; Calls:(1+0) wait_LCD_Ready, SendLCD_CmdW
;
lcd_On	MOVLW	LCD_ON
	GOTO	lcd_RdyAndCmd
;
	if UsesLCDBlink
;===================================================================================
; Send LCD command for Disp On, Cursor Off, Blink On
;
; Entry: none
; Exit: none
; RAM Used: Param78, Param79 (verified 4/17/03)
; Calls:(1+0) wait_LCD_Ready, SendLCD_CmdW
;
lcd_Blink	MOVLW	LCD_Blink
	GOTO	lcd_RdyAndCmd
;
	endif
	if UsesLCDCursoBlink
;===================================================================================
; Send LCD command for Disp On, Cursor On, Blink On
;
; Entry: none
; Exit: none
; RAM Used: Param78, Param79 (verified 4/17/03)
; Calls:(1+0) wait_LCD_Ready, SendLCD_CmdW
;
lcd_CursorBlink	MOVLW	LCD_CursorBlink
	GOTO	lcd_RdyAndCmd
;
	endif
;===================================================================================
; Send LCD command for Disp On, Cursor On, Blink Off
;
; Entry: none
; Exit: none
; RAM Used: Param78, Param79 (verified 4/17/03)
; Calls:(1+0) wait_LCD_Ready, SendLCD_CmdW
;
lcd_Cursor	MOVLW	LCD_Cursor
	GOTO	lcd_RdyAndCmd
;
	if Useslcd_Home
;===================================================================================
; Home the cursor without clearing DDRAM
;
; Entry: none
; Exit: none
; RAM Used: Param78, Param79 (verified 2/26/03)
; Calls:(1+0) wait_LCD_Ready, SendLCD_CmdW
;
lcd_Home	MOVLW	LCD_Home
	GOTO	lcd_RdyAndCmd
;
	endif
;=========================================================================
; Home the cursor clearing DDRAM
;
; Entry: none
; Exit: none
; RAM used: Param78, Param79 (verified 2/26/03)
; Calls:(1+0) wait_LCD_Ready, SendLCD_CmdW
;
	if UsesLCDClear
lcd_Clear	MOVLW	LCD_Clear
	endif
lcd_RdyAndCmd	MOVWF	Param79
	CALL	wait_LCD_Ready
	GOTO	SendLCD_Cmd79
;
	if Useslcd_ReadData
;=========================================================================
; Set the DD Ram Address
; First line starts at 0x00..0x13, 2nd at 0x40..0x53, 3rd at 0x14..0x27, 4th at 0x54..0x67
;
; Entry: W=DD Ram Address (7 bits)
; Exit: none
; RAM Used: Param78, Param79 (verified 12/8/03)
; Calls:(1+0) wait_LCD_Ready, SendLCD_CmdW
;
lcd_SetDDRamAddress	IORLW	0x80
	GOTO	lcd_RdyAndCmd
;
;=========================================================================
; Read from DD Ram
;
; Entry: none
; Exit: Byte in W and Param78
; RAM used: Param78 (verified 12/8/03)
; Calls:(1+0) wait_LCD_Ready
;
lcd_ReadData	CALL	wait_LCD_Ready
	BSF	PORTD,LCD_RW	; LCD_RD = 1; Read
	BSF	PORTD,LCD_AS	; LCD_RS = 1; Data
	BSF	PORTB,LCD_E	;LCD_E = 1
	NOP
	NOP
	MOVF	PORTD,W	;get high nibble
	ANDLW	0x0F
	MOVWF	Param78
	SWAPF	Param78,F
	BCF	PORTB,LCD_E	;LCD_E = 0
	NOP
	NOP
	BSF	PORTB,LCD_E	;LCD_E = 1
	NOP		
	NOP
	MOVF	PORTD,W	;get low nibble
	ANDLW	0x0F
	IORWF	Param78,F
	BCF	PORTB,LCD_E	;LCD_E = 0
	MOVF	Param78,W
	RETURN
;	
	endif
;=========================================================================
; Polls the LCDs Busy Flag until clear
;
; Entry: none
; Exit: none
; RAM used: none (verified 2/26/03)
; Calls:(0) none
;
wait_LCD_Ready	mBank1
	if UsesRS232BufIO
	BCF	_GIE
	BTFSC	_GIE
	GOTO	$-2
	endif
	MOVLW	0x0F	;Data In
	MOVWF	TRISD
	BCF	STATUS,RP0	;Bank0
	BSF	PORTD,LCD_RW	; LCD_RD = 1; Read
	BCF	PORTD,LCD_AS	; LCD_RS = 0; command
	BSF	PORTB,LCD_E	;LCD_E = 1
	NOP
	NOP
	MOVF	PORTD,W	;get high nibble
	BCF	PORTB,LCD_E	;LCD_E = 0
	NOP
	NOP
	BSF	PORTB,LCD_E	;LCD_E = 1
	NOP		;loose the low nibble
	NOP
	BCF	PORTB,LCD_E	;LCD_E = 0
	if UsesRS232BufIO
	BSF	_GIE
	endif
	ANDLW	0x08	;Busy Flag
	BTFSS	STATUS,Z
	GOTO	wait_LCD_Ready
	RETURN
;
;===================================================================================
; No Clear version of lcd_gotoxy
;
; Entry: W='X' value, Param78='Y' value
; Exit: none
; RAM used: Param78, Param79 (verified 4/18/03)
; Calls: (1+0) wait_LCD_Ready, lcd_nybble
;
lcd_gotoxy_NC	mBank0
	BCF	ClrLine
	GOTO	lcd_gotoxy_NC_1
;
;===================================================================================
; part of lcd_gotoxy (do not call)
;
lcd_gotoWClr	MOVWF	Param7A
	CALL	SendLCD_CmdW
	MOVLW	d'20'
	MOVWF	Param7B
lcd_gotoWClr_L1	MOVLW	' '
	CALL	lcd_char
	DECFSZ	Param7B,F
	GOTO	lcd_gotoWClr_L1
	CALL	wait_LCD_Ready	
	MOVF	Param7A,W
	GOTO	SendLCD_CmdW
;
;===================================================================================
; Goto the beginning of line W
; 
; Entry: W='X' value, Param78='Y' value
; Exit: none
; RAM used: Param78, Param79, Param7A, Param7B (verified 2/26/03)
; Calls:(1+1) wait_LCD_Ready, SendLCD_CmdW
;
lcd_GotoLineW	MOVWF	Param78
	CLRW
;
; fall through to lcd_gotoxy
;===================================================================================
;  Go to an X-Y position on the display, top left is 0, 0
; if W(X)=0 then clear line
;
; Entry: W='X' value, Param78='Y' value
; Exit: none
; RAM used: Param78, Param79, Param7A, Param7B (verified 2/26/03)
; Calls:(1+1) wait_LCD_Ready, SendLCD_CmdW
;						
; W=W+LCD_SETPOS
; if (y=1) or (y=3)
;  W=W+LCD_LINE2
; if (y=2) or (y=3)
;  W=W+20
lcd_gotoxy	mBank0
	BCF	ClrLine
	ANDLW	0x1F	;limit to low 5 bits
	BTFSC	STATUS,Z
	BSF	ClrLine
lcd_gotoxy_NC_1	BTFSC	Param78,0	;inc DDRAM pos by 20
	ADDLW	LCD_LINE2
	BTFSC	Param78,1
	ADDLW	d'20'
	IORLW	LCD_SETPOS
	MOVWF	Param78
	CALL	wait_LCD_Ready
	MOVF	Param78,W
	BTFSC	ClrLine
	GOTO	lcd_gotoWClr
;
; fall through to SendLCD_CmdW
;===========================================================================================
; Send a command byte to the LCD as two nybbles
;		
; Entry: W=Byte to send
; Exit: none
; RAM used: Param78, Param79 (verified 2/26/03)
; Calls:(1+0) lcd_nybble
;
SendLCD_CmdW	MOVWF	Param79
SendLCD_Cmd79	mBank1
	MOVLW	All_Out
	MOVWF	TRISD
	BCF	STATUS,RP0
	BCF	PORTD,LCD_RW	; LCD_RD = 0; write
	BCF	PORTD,LCD_AS	; LCD_RS = 0; command
	SWAPF	Param79,W	; Send high nibble to LCD
	CALL	lcd_nybble
	MOVF	Param79,W	; Send low nibble to LCD
;
	GOTO	lcd_nybble
;
;======================================================================================
; Send a character byte to the LCD as two nybbles
;		
; Entry: W
; Exit: Param79 will contain the value from W
; RAM used: Param78, Param79 (verified 2/26/03)
; Calls:(1+0) wait_LCD_Ready, lcd_nybble
;
lcd_char	MOVWF	Param79
	CALL	wait_LCD_Ready
	mBank1
	MOVLW	All_Out
	MOVWF	TRISD
	BCF	STATUS,RP0
;
	BCF	PORTD,LCD_RW	; LCD_RD = 0; write
	BSF	PORTD,LCD_AS	; LCD_RS = 1; data
	SWAPF	Param79,W	; Send high nibble to LCD
	CALL	lcd_nybble
;
	MOVF	Param79,W	; Send low nibble to LCD
	GOTO	lcd_nybble
;
;======================================================================================
; Initialise the LCD
; Entry: none
; Exit: none
; RAM used: Param78, Param79
; Calls:(1+1) DelayWmS, SendLCD_CmdW, Delay100uS, LCD_Clear
;
Init_LCD	BSF	STATUS,RP0
	MOVLW	All_Out	; Ensure RS and R/W lines are O/Ps
	MOVWF	TRISD
	BCF	STATUS,RP0
;
	BCF	PORTD,LCD_AS	; LCD_RS = 0; command
	BCF	PORTD,LCD_RW	; LCD_RD = 0; write
;
	MOVLW	d'20'
	CALL	DelayWmS	; Ensure LCD is stable after power-up
;Optrex Display
	MOVLW	LCD_MODE
	CALL	SendLCD_CmdW
	MOVLW	0x06
	CALL	DelayWmS
;
	MOVLW	LCD_MODE
	CALL	SendLCD_CmdW
	MOVLW	0x06
	CALL	DelayWmS
;
	MOVLW	LCD_MODE
	CALL	SendLCD_CmdW
	MOVLW	0x06
	CALL	DelayWmS
;
	MOVLW	LCD_ON
	CALL	SendLCD_CmdW
	CALL	Delay100uS
;
	MOVLW	LCD_EnterMode
	CALL	SendLCD_CmdW
	CALL	Delay100uS
;
	MOVLW	LCD_Clear
	GOTO	SendLCD_CmdW
;
	endif
;=========================================================================================
	if UsesByte2Str
;============================================================================================
; Convert a Byte (Param77) to a pStr at txbuff (two Hex digits)
;
; Entry: Byte in Param76
; Exit: pStr at txbuff
; RAM used: Param76, Param79, FSR
; Calls:(1+1) Disp_Hex_Byte
;
Byte2Str	CLRF	STATUS	;saves 1 byte over mBank0
	MOVLW	txbuff
	MOVWF	FSR
;	BCF	STATUS,IRP	;banks 0 and 1
	MOVLW	0x02	;len=2
	MOVWF	INDF
	INCF	FSR,F
;
	BSF	NumsToRam
	CALL	Disp_Hex_Byte_E2
	BCF	NumsToRam
;
	RETURN
;
	endif
;
;=========================================================================================
; Disp_Hex_Byte send a byte to the display as 2 hex digits
; entry: W=value
; exit: none
; RAM used:Param75, Param76, Param79
; Calls:(1+2) Disp_Hex_Nibble, DisplaysW
;
Disp_Hex_Byte	MOVWF	Param76	;save the data
Disp_Hex_Byte_E2	SWAPF	Param76,W	;get hi nibble in low nibble of W
	CALL	Disp_Hex_Nibble	;output the high nibble
	MOVF	Param76,W	; now the low nibble
;
;fall through to Disp_Hex_Nibble
;
;===============================================================
; Send a nibble to the display as a hex digit
; Entry: W:0..3 = Nibble to display
; RAM used: Param75, Param78, Param79
; Calls:(1+1) DisplaysW
;
Disp_Hex_Nibble	ANDLW	0x0F	;kill the other nibble
	ADDLW	'0'	; add offset
	MOVWF	Param79
	MOVLW	0x3A	;'9'+1 should barrow if 0..9
	SUBWF	Param79,W	
	CLRW
	BTFSC	STATUS,C	;skip if barrowed
	MOVLW	0x07
	ADDWF	Param79,W
;
	GOTO	DisplayOrPut
;
;=========================================================================================
; Load a ':' into the W and goto DisplaysW
;
Display_Colon	MOVLW	':'
	GOTO	DisplaysW
;
;=========================================================================================
; Load a '.' into the W and goto DisplaysW
;
Display_Dot	MOVLW	'.'
;
; fall through to DisplaysW
;=========================================================================================
; Display handler; redirects to LCD and/or serial
; 					 
; RAM used: Param75=CharTemp,Param78, Param79
; Calls:(1+1) wait_LCD_Ready, SendLCD_CmdW, lcd_char, putchar
;
DisplaysW	MOVWF	Param75	;CharTemp=W
	mBank0
	BTFSS	SendToLCD	; if (disp_lcd)
	GOTO	DispSerial	;not LCD try Serial
;
	MOVLW	0x0D	; if (b == '\r') 
	SUBWF	Param75,W
	BTFSS	STATUS,Z
	GOTO	DisplaysW_1
;
;Carrage Return (0D)
	if UsesLCD
;
	CALL	wait_LCD_Ready
	MOVLW	LCD_SETPOS	; lcd_cmd(LCD_SETPOS); 
	CALL	SendLCD_CmdW
;
	endif
;
	GOTO	DispSerial
;
; else if (b == '\n') 
DisplaysW_1	MOVLW	0x0A
	SUBWF	Param75,W
	BTFSS	STATUS,Z
	GOTO	DisplaysW_2
;
;Line Feed (0A)
	if UsesLCD
;
	CALL	wait_LCD_Ready
	MOVLW	LCD_SETPOS+LCD_LINE2	; lcd_cmd(LCD_SETPOS + LCD_LINE2); 
	CALL	SendLCD_CmdW
	endif
;
	GOTO	DispSerial
;
DisplaysW_2	
	if UsesLCD
;
	MOVF	Param75,W	; lcd_char(b); 
	CALL	lcd_char
	endif
;
;  fall through to  DispSerial
;====================================================================================
;     DispSerial
; Entry: Param75 char to send
; Exit: none
; RAM used: Param75=CharToSend
; Calls:(1+0) putchar
;
DispSerial	
	if RS232Active
	BTFSS	SendRS232
	RETURN		;serial is off, skip it.
; if (b == '\n') 
	MOVLW	0x0A
	SUBWF	Param75,W
	BTFSS	STATUS,Z
	GOTO	DispSerial_1
	MOVLW	0x0D	; putchar('\r'); 
	CALL	putchar
	GOTO	DispSerial_2
;
DispSerial_1	MOVLW	0x0D
	SUBWF	Param75,W
	BTFSS	STATUS,Z
	GOTO	DispSerial_2
	CALL	DispSerial_2
	MOVLW	0x0A	; putchar('\r'); 
	GOTO	putchar
	
DispSerial_2	MOVF	Param75,W	; putchar(b); 
;
; fall through to putchar
;
;==================================================================================
; Send the byte in the W out the serial port
; Entry: W=char
; Exit: W is unchanged
; RAM used: none (verified 1/30/03)
; Calls:(0) none
;
putchar	mBank0
	BTFSS	PIR1,TXIF
	GOTO	$-1
	MOVWF	TXREG
;
	endif
	RETURN
;
;
	if Do_RS232_Test
;==================================================================================
; Test the RS232 port by echoing every character
;
; Entry: none
; Exit: Doesn't exit
; RAM used:Param78
; Calls: (1+0) get_char, putchar
;
RS232_Test	CALL	get_char
	MOVF	Param78,W
	CALL	putchar
	GOTO	RS232_Test
;
	endif
;
;========================================================================================
;========================================================================================
; Read from the CPU's EEPROM using Param79 as Address
;
; Entry: Param79=address to read
; Exit: W=data from eeprom, Param79
; RAM used: Param79 (verified 2/26/03)
; Calls:(0) none
;
ReadEE79	MOVF	Param79,W
	GOTO	ReadEEwW
;
; fall through to ReadEEwW
;
;========================================================================================
; Read from the CPU's EEPROM using Param79++ as Address
;
; Entry: Param79=address to read
; Exit: W=data from eeprom, Param79++
; RAM used: Param79 (verified 2/26/03)
; Calls:(0) none
;
ReadEE79PI	MOVF	Param79,W
	INCF	Param79,F
;
; fall through to ReadEEwW
;
;========================================================================================
; Read from the CPU's EEPROM using W as Address
; Entry: W=address to read
; Exit: W=data from eeprom
; RAM used: none (verified 2/26/03)
; Calls:(0) none
;
ReadEEwW	mBank2
	MOVWF	EEADR
	CLRF	EEADRH
	BSF	STATUS,RP0	;bank3
	BCF	EECON1,EEPGD
	BSF	EECON1,RD
	BCF	STATUS,RP0	;bank2
	MOVF	EEDATA,W
	BCF	STATUS,RP1	;bank0
	RETURN
;
;=========================================================================================
; Write CPU's EEPROM using address from Param79++ and Data in W
; Entry: Param79=address, W=data
; Exit: EEADR=address, W=data, Param79++
; RAM used: Param78, Param79 (verified 2/26/03)
; Calls:(0) WriteEEwW
;
WriteEEP79WPI	MOVWF	Param78
	MOVF	Param79,W
	INCF	Param79,F
	GOTO	WriteEEP79W_1
;
;=========================================================================================
; Write CPU's EEPROM using address from Param79 and Data in W
; Entry: Param79=address, W=data
; Exit: EEADR=address, W=data
; RAM used: Param78, Param79 (verified 2/26/03)
; Calls:(0) WriteEEwW
;
WriteEEP79W	MOVWF	Param78
	MOVF	Param79,W
WriteEEP79W_1	mBank2
	MOVWF	EEADR
	BCF	STATUS,RP1
	MOVF	Param78,W
;
; fall through to WriteEEwW
;
;=========================================================================================
; Write CPU's EEPROM using current value in EEADR and W as Data
; Entry: EEADR=address, W=data
; Exit: none
; RAM used: none (verified 2/26/03)
; Calls:(0) none
;
WriteEEwW	mBank2
	CLRF	EEADRH
	MOVWF	EEDATA
	BSF	STATUS,RP0	;Bank3
	if UsesISR
	BCF	_GIE	;Disable interupts
	BTFSC	_GIE
	GOTO	$-2
	endif
	BCF	EECON1,EEPGD
	BSF	EECON1,WREN
	MOVLW	0x55	;load
	MOVWF	EECON2
	MOVLW	0xAA
	MOVWF	EECON2
	BSF	EECON1,WR	;fire!
	BTFSC	EECON1,WR	;wait for write to finish
	GOTO	$-1	; test again
	BCF	EECON1,WREN
	if UsesISR
	MOVLW	HasISR	;restore interupts
	ANDLW	0x80	; True?
	BTFSS	STATUS,Z	
	BSF	_GIE	;GIE bit
	endif
	GOTO	Bank0Rtn
;
	if UsesNIC
;===========================================================================================
; Do a 1's complement checksum of the CPU's non-volatile eeprom
; (6 bytes tested, 2 lsB of MAC Address, and 4 byte IP Address)
; Entry: none
; Exit: Param78=Checksum
; RAM used:Param78, Param79 (verified 2/26/03)
; Calls:(1+0) ReadEEwW
;
csum_nonvol	CLRF	Param78	;csum
	CLRF	Param79	;count
csum_nonvol_L1	MOVLW	0x06
	SUBWF	Param79,W
	BTFSC	STATUS,C
	GOTO	csum_nonvol_End
	CALL	ReadEE79PI	;sum += read_eeprom(i++);
	ADDWF	Param78,F
	GOTO	csum_nonvol_L1
csum_nonvol_End	MOVLW	0xFF
	XORWF	Param78,F
	RETLW	00
;
;=====================================================================================
; Read in the nonvolatile parameters, return 0 if error
;  This routine is called one time only at power up.
;  It reads:
;    2 lsB of MAC Address, and 4 byte IP Address
;
; Entry:none
; Exit: if csum error then Param78=0 else 1
; RAM used: Param78, Param79, FSR (verified 2/26/03)
; Calls:(1+1) ReadEEwW, csum_nonvol
;
read_nonvol	CLRF	Param79
;
	if HasMAC_Addr_EEPROM=0
	CALL	ReadEE79PI
	MOVWF	myeth4
	endif
;
	if HasMAC_Addr_EEPROM=0
	CALL	ReadEE79PI
	MOVWF	myeth5
	endif
;
	CALL	ReadEE79PI
	MOVWF	myip_b3
	CALL	ReadEE79PI
	MOVWF	myip_b2
	CALL	ReadEE79PI
	MOVWF	myip_b1
	CALL	ReadEE79PI
	MOVWF	myip_b0
;
	if HasMAC_Addr_EEPROM=0
	CALL	csum_nonvol	; return (csum_nonvol() == read_eeprom(6)); 
	MOVLW	0x06
	CALL	ReadEEwW
	SUBWF	Param78,W	;calc'd csum = csum?
	MOVLW	0x01	;ok
	BTFSS	STATUS,Z	;skip if same
	CLRW		;Error!
	MOVWF	Param78
	RETURN
	else
	RETLW	0x01
	endif
;
;========================================================================================================
; Write out the nonvolatile parameters to CPU's eeprom
; Entry: myeth4, myeth5, myip
; Exit: none
; RAM used: Param78, Param79, myeth4, myeth5, myip (verified 2/26/03)
; Calls:(1+1) WriteEEP79W, csum_nonvol
; 
write_nonvol	CLRF	Param79
;
	if HasMAC_Addr_EEPROM=0
	MOVF	myeth4,W
	CALL	WriteEEP79WPI	; write_eeprom(0, myeth[4]);
	MOVF	myeth5,W
	CALL	WriteEEP79WPI	; write_eeprom(1, myeth[5]);
	endif
;
	MOVF	myip_b3,W
	CALL	WriteEEP79WPI	; write_eeprom(2, myip.b[3]);
	MOVF	myip_b2,W
	CALL	WriteEEP79WPI	; write_eeprom(3, myip.b[2]);
	MOVF	myip_b1,W
	CALL	WriteEEP79WPI	; write_eeprom(4, myip.b[1]);
	MOVF	myip_b0,W
	CALL	WriteEEP79WPI	; write_eeprom(5, myip.b[0]);
	if HasMAC_Addr_EEPROM=0
	CALL	csum_nonvol	; write_eeprom(6, csum_nonvol());
	MOVLW	0x06
	MOVWF	Param79
	MOVF	Param78,W
	GOTO	WriteEEP79W
	else
	RETURN
	endif
;
	endif
;===========================================================================================================
;===========================================================================================================
	if UsesDataLogging & HasRTC
; copy the 6 byte time to the SRAM
;
; Entry: SRAM_Addr
; Exit: SRAM_Addr is incremented
; RAM used: Param78, FSR (verified 2/26/03)
; Calls:(1+1) SRAM_WritePI
;
TimeToSRAM	MOVLW	low RTC_Year
	MOVWF	FSR
	BSF	STATUS,IRP
TimeToSRAM_L1	MOVF	INDF,W
	CALL	SRAM_WritePI
	MOVLW	low RTC_Seconds
	SUBWF	FSR,W
	BTFSC	STATUS,Z
	RETURN
	INCF	FSR,F
	GOTO	TimeToSRAM_L1
;
	endif
;
	if HasRTC & UsesLCD & Use_display_rtc
;=======================================================================================
; Display the RTC on the LCD in the from YY:MM:DD:HH:mm:ss
; Entry: RTC_Year..RTC_Seconds
; Exit: none
; RAM used: Param78, Param79, FSR
; Calls:(1+3) read_rtc, lcd_gotoxy, Disp_decbyteW, DisplaysW
;
display_rtc	CALL	read_rtc
	MOVLW	0x02	;line 2 (3rd line)
	CALL	lcd_GotoLineW
;
	MOVLW	low RTC_Year
	MOVWF	FSR
	BSF	STATUS,IRP
;
	
display_rtc_L1	MOVF	INDF,W
	BSF	DispDec2pl
	CALL	Disp_decbyteW
	MOVLW	':'
	GOTO	DisplaysW
	INCF	FSR,F
	MOVLW	low RTC_Seconds
	SUBWF	FSR,W
	BTFSS	STATUS,Z
	GOTO	display_rtc_L1
	MOVF	INDF,W
	BSF	DispDec2pl
	GOTO	Disp_decbyteW
;
	endif
;
	if HasRTC & UsesDateToBCD
;=======================================================================================
; Convert RTC_Year..RTC_Seconds to BCD for set_rtc
;
; Entry: Int8 data in RTC_Year..RTC_Seconds
; Exit: BCD formated data in RTC_Year..RTC_Seconds, bank is unchanged
; RAM used: Param77, Param78, Param79, Param7A, FSR (verified 6/1/03)
; Calls:(1+0) Fix_decbyte
;
DateToBCD	MOVLW	RTC_Year
	MOVWF	FSR
	BSF	STATUS,IRP
	MOVLW	0x06	;convert 6 bytes
	MOVWF	Param7A
	MOVLW	d'10'
	MOVWF	Param79
DateToBCD_L1	MOVF	INDF,W
	MOVWF	Param77
	Call	Fix_decbyte
	SWAPF	Param78,W
	ADDWF	Param77,W
	MOVWF	INDF
	INCF	FSR,F
	DECFSZ	Param7A,F
	GOTO	DateToBCD_L1
	RETURN
	endif
;
	if HasRTC
;=======================================================================================
; Set the RTC with Data form RTC_Year..RTC_Seconds (BCD format)
;
; Entry: BCD formated data in RTC_Year..RTC_Seconds
; Exit: none
; RAM used: Param78, Param79, FSR (verified 2/26/03)
; Calls:(1+0) write_rtc_nibble
;
set_rtc	CLRF	STATUS	;saves 1 byte over mBank0
;
	MOVLW	RTC_CtrlRegF
	MOVWF	Param78
	MOVLW	RTC_24Bit
	MOVWF	Param79
	CALL	write_rtc_nibble
;
	MOVLW	low RTC_Year
	MOVWF	FSR
	BSF	STATUS,IRP
;
	MOVLW	RTC_TenYear
	MOVWF	Param78
set_rtc_L1	SWAPF	INDF,W
	MOVWF	Param79
	CALL	write_rtc_nibble
;
	DECF	Param78,F
	MOVF	INDF,W
	MOVWF	Param79
	CALL	write_rtc_nibble
	DECF	Param78,F
	INCF	FSR,F
	MOVLW	low RTC_Seconds+1
	SUBWF	FSR,W
	BTFSS	STATUS,Z
	GOTO	set_rtc_L1
	RETURN
;
	endif
;
	if HasRTC
;=======================================================================================
; Read the Real Time Clock 
; Entry: none
; Exit: RTC_Year..RTC_Seconds
; RAM used: Param78, Param79, RTC_Year..RTC_Seconds, FSR (verified 2/26/03)
; Calls:(1+2) read_rtc_byte
;
read_rtc	CLRF	STATUS	;saves 1 byte over mBank0
	MOVLW	low RTC_Seconds
	MOVWF	FSR
	BSF	STATUS,IRP
;
	MOVLW	0x07
	MOVWF	Param79
	MOVLW	RTC_TenSec
	CALL	read_rtc_byte
	DECF	FSR,F
	MOVLW	RTC_TenMinute
	CALL	read_rtc_byte
	DECF	FSR,F
	MOVLW	0x03
	MOVWF	Param79
	MOVLW	RTC_TenHourAMPM
	CALL	read_rtc_byte
	DECF	FSR,F
	MOVLW	RTC_TenDay
	CALL	read_rtc_byte
	DECF	FSR,F
	MOVLW	0x01
	MOVWF	Param79
	MOVLW	RTC_TenMonth
	CALL	read_rtc_byte
	DECF	FSR,F
	MOVLW	0x0F
	MOVWF	Param79
	MOVLW	RTC_TenYear
;
; Fall through to read_rtc_byte
;
;=====================================================================
; Read a byte from the RTC
;
; Entry: Param79=High nibble mask, W=RTC Address, FSR>>RAM (ie RTC_Seconds)
; Exit: INDF=(Value from RTC Address) * 10 + (Value from RTC Addres - 1)
; RAM used: Param78, Param79, FSR (verified 2/26/03)
; Calls:(1+1) read_rtc_nibble
;
read_rtc_byte	MOVWF	Param78
	CLRF	INDF
	CALL	read_rtc_nibble
	ANDWF	Param79,W
	MOVWF	INDF
	BCF	STATUS,C
	RLF	INDF,F
	RLF	INDF,F
	RLF	INDF,F
	ADDWF	INDF,F
	ADDWF	INDF,F
	DECF	Param78,F
;
;fall through to read_rtc_nibble
;
;==================================================================
; Entry: Param78=RTC Address, FSR>>RAM (ie RTC_Seconds)
; Exit: W=Value from RTC, INDF=INDF+Value from RTC
; RAM used: Param78 (verified 2/26/03)
; Calls:(1+0) Set8bitAddr
;
read_rtc_nibble	MOVF	Param78,W
	CALL	Set8bitAddr
	BSF	STATUS,RP0	;Bank1
	MOVLW	All_In
	if UsesRS232BufIO
	BCF	_GIE
	BTFSC	_GIE
	GOTO	$-2
	endif
	MOVWF	TRISD
	BCF	STATUS,RP0	;Bank0
;
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	SelectRTC
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	BCF	PORTB,IORead
	NOP
	MOVF	PORTD,W
	BSF	PORTB,IORead	
	BSF	PORTB,SelectEnable
;
	ANDLW	0x0F
	ADDWF	INDF,F
	if UsesRS232BufIO
	BSF	_GIE
	endif
	RETURN
;
;=======================================================================================
; Writes the low nibble from Param79 to the RTC Address from Param78
; Entry: Param79=data, Param78=address
; exit: none
; RAM used: Param78, Param79 (verified 2/26/03)
; Calls:(1+0) Set8bitAddr
;
write_rtc_nibble	MOVF	Param78,W
	CALL	Set8bitAddr
	BSF	STATUS,RP0	;Bank1
	MOVLW	All_Out
	if UsesRS232BufIO
	BCF	_GIE
	BTFSC	_GIE
	GOTO	$-2
	endif
	MOVWF	TRISD
	BCF	STATUS,RP0	;Bank0
;
	MOVF	Param79,W
	MOVWF	PORTD
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	SelectRTC
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	BCF	PORTB,IOWrite
	NOP
	BSF	PORTB,IOWrite	
	BSF	PORTB,SelectEnable
	if UsesRS232BufIO
	BSF	_GIE
	endif
	RETURN
;
	endif
;
;=========================================================================================================
;=========================================================================================================
	if UsesMAX110
;
; At this time only channel zero is supported
;
;1X clock 10,240 clocks / convertion Channel 0
;MAX110CtrlWdC1	EQU	0x920C	;first calibration control word
;MAX110CtrlWdC2	EQU	0x9208	;second calibration control word
;MAX110CtrlWdC3	EQU	0x9204	;third calibration control word
;MAX110CtrlWd0	EQU	0x9200	;control word to read Channel 0
;Ö4 clock 81,920 clocks / convertion Channel 0
MAX110CtrlWdC1	EQU	0x8D0C	;first calibration control word
MAX110CtrlWdC2	EQU	0x8D08	;second calibration control word
MAX110CtrlWdC3	EQU	0x8D04	;third calibration control word
MAX110CtrlWd0	EQU	0x8D00	;control word to read Channel 0
;
;=================================================================================
; Wait for the MAX110 to finish
;  will loop forever if an error occures
;  Calls:(1+1) ReadLDI_3
;
WaitMAX110NotBusy	mBank3
	BTFSC	CurrentLDI_3,Max110Busy
	GOTO	Bank0Rtn
	CALL	ReadLDI_3
	GOTO	WaitMAX110NotBusy	;will loop forever if bad I/O
;
;=================================================================================
; Calibrate the MAX110 14bit ADC for Channel 0
;  Entry: none
;  Exit: none
;  RAM used:Param77, Param78, Param79
;  Calls:(1+2) WaitMAX110NotBusy, ReadMAX110_SE
;
CalMAX110	MOVLW	high MAX110CtrlWdC1	;Set the speed and 
	MOVWF	Param77	; do an offset conversion
	MOVLW	low MAX110CtrlWdC1
	MOVWF	Param78
	CALL	ReadMAX110_SE
;
	CALL	WaitMAX110NotBusy	;Gain-Calibration
	MOVLW	high MAX110CtrlWdC2
	MOVWF	Param77
	MOVLW	low MAX110CtrlWdC2
	MOVWF	Param78
	CALL	ReadMAX110_SE
;
	CALL	WaitMAX110NotBusy	;Offset-null conversion
	MOVLW	high MAX110CtrlWdC3
	MOVWF	Param77
	MOVLW	low MAX110CtrlWdC3
	MOVWF	Param78
	CALL	ReadMAX110_SE
;
	CALL	WaitMAX110NotBusy
	CALL	ReadMAX110	;prime the pump
	CALL	WaitMAX110NotBusy
;
; fall through and read valid data for the first time
;=================================================================================
; Read the MAX110 14bit ADC Channel 0
;  Entry: none
;  Exit: MAXadc0LSB,MAXadc0MSB
;  RAM used:Param77, Param78, Param79
;  Calls:(0) none
;
ReadMAX110	mBank3
	BTFSS	CurrentLDI_3,Max110Busy
	GOTO	RdMAX110_Busy
;
	MOVLW	high MAX110CtrlWd0
	MOVWF	Param77
	MOVLW	low MAX110CtrlWd0
	MOVWF	Param78
;
ReadMAX110_SE	MOVLW	d'16'	;16 bits to move, Second Entry point
	MOVWF	Param79
;
	mBank1
	MOVLW	b'01111101'
	if UsesRS232BufIO
	BCF	_GIE
	BTFSC	_GIE
	GOTO	$-2
	endif
	MOVWF	TRISD
	BCF	STATUS,RP0	;Bank0
	CLRF	PORTD	;MAX110 SCLK=0
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	SelMax110
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
;
ReadMAX110_L1	RLF	Param78,F
	RLF	Param77,F
	RRF	Param77,W
	ANDLW	0x80
	MOVWF	PORTD	;Din=Param77<7>, SCLK=0
	NOP
	NOP
	IORLW	0x02
	MOVWF	PORTD	;SCLK=1
	NOP
	NOP
	NOP
	RRF	PORTD,W	;Carry=Dout
	DECFSZ	Param79,F
	GOTO	ReadMAX110_L1
;
	RLF	Param78,F	;move last bit into mem
	RLF	Param77,F
	mBank3
	BCF	CurrentLDI_3,Max110Busy ;Make busy* active
	BCF	STATUS,RP0	; Bank 2
	MOVF	Param78,W
	MOVWF	MAXadc0LSB
	MOVF	Param77,W
	MOVWF	MAXadc0MSB
;
;
RdMAX110_Busy	mBank0
	BSF	PORTB,SelectEnable
	if UsesRS232BufIO
	BSF	_GIE
	endif
	RETURN
	endif
;
;========================================================================================================
	if UsesLDO0
;========================================================================================================
; if CMD_LDO_0<>CurrentLDO_0 then WriteLDO_0
; Entry: CMD_LDO_0, CurrentLDO_0
; Exit: none
; RAM used: none (verified 2/26/03)
; Calls:(0) none
;
OPT_WriteLDO_0	mBank3
	MOVF	CMD_LDO_0,W
	SUBWF	CurrentLDO_0,W
	SKPNZ
	GOTO	Bank0Rtn
;
;=================================================================================
; Write the data in CMD_LDO_0 to the latch
; Entry: CurrentLDO_0
; Exit: none
; RAM used: none (verified 2/26/03)
; Calls:(0) none
;
WriteLDO_0	mBank1
	MOVLW	All_Out
	if UsesRS232BufIO
	BCF	_GIE
	BTFSC	_GIE
	GOTO	$-2
	endif
	MOVWF	TRISD
	BSF	_RP1	;Bank3
	MOVF	CMD_LDO_0,W
	MOVWF	CurrentLDO_0
	mBank0
	MOVWF	PORTD
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	SelectLDO0
WriteLDO_X	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	NOP
	BSF	PORTB,SelectEnable
	if UsesRS232BufIO
	BSF	_GIE
	endif
	RETURN
;
	endif	UsesLDO0
;
	if UsesLDO1
;=================================================================================
; if CMD_LDO_1<>CurrentLDO_1 then WriteLDO_1
; Entry: CMD_LDO_1, CurrentLDO_1
; Exit: none
; RAM used: none (verified 2/26/03)
; Calls:(0) none
;
OPT_WriteLDO_1	mBank3
	MOVF	CMD_LDO_1,W
	SUBWF	CurrentLDO_1,W
	SKPNZ
	GOTO	Bank0Rtn
;
;=================================================================================
; Write the data in CMD_LDO_1 to the latch
; Entry: CMD_LDO_1
; Exit: CurrentLDO_1 = CMD_LDO_1
; RAM used: none (verified 2/26/03)
; Calls:(0) none
;
WriteLDO_1	mBank1
	MOVLW	All_Out
	if UsesRS232BufIO
	BCF	_GIE
	BTFSC	_GIE
	GOTO	$-2
	endif
	MOVWF	TRISD
	BSF	STATUS,RP1	;Bank 3
	MOVF	CMD_LDO_1,W
	MOVWF	CurrentLDO_1
	mBank0
	MOVWF	PORTD
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	SelectLDO1
	GOTO	WriteLDO_X
;
	endif		;UsesLDO1
;
	if UsesLDO2
;=================================================================================
; if CMD_LDO_2<>CurrentLDO_2 then WriteLDO_2
; Entry: CMD_LDO_2, CurrentLDO_2
; Exit: none
; RAM used: none (verified 2/26/03)
; Calls:(0) none
;
OPT_WriteLDO_2	mBank3
	MOVF	CMD_LDO_2,W
	SUBWF	CurrentLDO_2,W
	SKPNZ
	GOTO	Bank0Rtn
;
;=================================================================================
; Write the data in CMD_LDO_2 to the latch
; Entry: CMD_LDO_2
; Exit: CurrentLDO_2 = CMD_LDO_2
; RAM used: none (verified 2/26/03)
; Calls:(0) none
;
WriteLDO_2	mBank1
	MOVLW	All_Out
	if UsesRS232BufIO
	BCF	_GIE
	BTFSC	_GIE
	GOTO	$-2
	endif
	MOVWF	TRISD
	BSF	STATUS,RP1	;Bank 3
	MOVF	CMD_LDO_2,W
	MOVWF	CurrentLDO_2
	mBank0
	MOVWF	PORTD
	MOVF	PORTB,W
	ANDLW	AddressMask	;clear low nibble
	IORLW	SelectLDO2
	GOTO	WriteLDO_X
;
	endif		;UsesLDO1
;
	if UsesLDO3
;=================================================================================
; if CMD_LDO_3<>CurrentLDO_3 then WriteLDO_3
; Entry: CMD_LDO_3, CurrentLDO_3
; Exit: none
; RAM used: none (verified 2/26/03)
; Calls:(0) none
;
OPT_WriteLDO_3	mBank3
	MOVF	CMD_LDO_3,W
	SUBWF	CurrentLDO_3,W
	SKPNZ
	GOTO	Bank0Rtn
;
;=================================================================================
; Write the data in CMD_LDO_3 to the latch
; Entry: CMD_LDO_3
; Exit: CurrentLDO_3 = CMD_LDO_3
; RAM used: none (verified 2/26/03)
; Calls:(0) none
;
WriteLDO_3	mBank1
	MOVLW	All_Out
	if UsesRS232BufIO
	BCF	_GIE
	BTFSC	_GIE
	GOTO	$-2
	endif
	MOVWF	TRISD
	BSF	STATUS,RP1	;Bank 3
	MOVF	CMD_LDO_3,W
	MOVWF	CurrentLDO_3
	mBank0
	MOVWF	PORTD
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	SelectLDO3
	GOTO	WriteLDO_X
;
	endif		;UsesLDO1
;
	if UsesLDI0
;=================================================================================
; Read the data from the latch and store it at CurrentLDI_0
; Entry:none
; Exit:CurrentLDI_0 and W contain the Data
; RAM used: Param78 (verified 2/26/03)
; Calls:(1+0) ReadData
;
ReadLDI_0	MOVLW	SelectLDI0
	CALL	ReadData
;
	mBank3
	MOVWF	CurrentLDI_0
	endif
Bank0Rtn
ReadLDI_end	mBank0
	RETURN
;
	if UsesLDI1
;=================================================================================
; Read the data from the latch and store it at CurrentLDI_1
; Entry:none
; Exit:CurrentLDI_1 and W contain the Data
; RAM used: Param78 (verified 2/26/03)
; Calls:(1+0) ReadData
;
ReadLDI_1	MOVLW	SelectLDI1
	CALL	ReadData
;
	mBank3
	MOVWF	CurrentLDI_1
	GOTO	ReadLDI_end
	endif
;
	if UsesLDI2
;=================================================================================
; Read the data from the latch and store it at CurrentLDI_2
;
; Entry:none
; Exit:CurrentLDI_2 and W contain the Data
; RAM used: Param78 (verified 2/26/03)
; Calls:(1+0) ReadData
;
ReadLDI_2	MOVLW	SelectLDI2
	CALL	ReadData
;
	mBank3
	MOVWF	CurrentLDI_2
	GOTO	ReadLDI_end
	endif
;
	if UsesLDI3
;=================================================================================
; Read the data from the latch and store it at CurrentLDI_3
;
; Entry:none
; Exit:CurrentLDI_3 and W contain the Data
; RAM used: Param78 (verified 2/26/03)
; Calls:(1+0) ReadData
;
ReadLDI_3	MOVLW	SelectLDI3
	CALL	ReadData
;
	mBank3
	MOVWF	CurrentLDI_3
	GOTO	ReadLDI_end
	endif
;
;===============================================================================================
	if Do_LD_Test
;===============================================================================================
; Flash each led for 1 seconds then echo switches to LEDs
; Entry:none
; Exit: Does NOT exit
; RAM used:
; Calls:
;
LD_Test	MOVLW	0x02
LD_Test_L1	MOVWF	Param7A
	mBank3
	MOVLW	0xFF
	XORWF	Param7A,W
	MOVWF	CMD_LDO_0
	CALL	WriteLDO_0
	MOVLW	SystemLEDMask
	XORWF	PORTA,F	;toggle system led
; delay 1 second
	CALL	Delay1Sec
	RLF	Param7A,W
	ANDLW	0x7E
	BTFSS	STATUS,Z
	GOTO	LD_Test_L1
;
LD_Test_L2	CALL	ReadLDI_0
	mBank3
	MOVF	CurrentLDI_0,W
	MOVWF	CMD_LDO_0
	RLF	CMD_LDO_0,F
	CALL	WriteLDO_0
	MOVLW	SystemLEDMask
	XORWF	PORTA,F	;toggle system led
	MOVLW	d'250'
	CALL	DelayWmS	
	GOTO	LD_Test_L2
	endif		;Do_LD_Test
;
;
;=====================================
; geticks
; Update the current tick count, return W=1 if changed
; TIMER1_DIV=120, Fosc/4/8/(120*256)=20
; RAM used:tickcount, lastc, Param78 (verified 1/30/03)
; Calls:(0) none
;
geticks	CLRWDT		;Kick watchdog
	MOVF	TMR1H,W
	MOVWF	Param78	;store it temp
	MOVF	lastc,W
	SUBWF	Param78,F	; tc = TMR1H - lastc; 
	MOVLW	TIMER1_DIV	; if (tc >= TIMER1_DIV)
	SUBWF	Param78,W
	BTFSS	_C
	RETLW	0x00
	INCF	tickcount,F	; tickcount++; 
	MOVLW	TIMER1_DIV	; lastc = lastc+TIMER1_DIV;
	ADDWF	lastc,F
	RETLW	0x01
;	
;=====================================================================================
; Check timer, scan ADCs, toggle LED if timeout 
; RAM used: Param78, Param79
; Calls:(1+0) geticks, OnTheTick, ToggleSysLED, ReadLDI_N(1+0), OPT_WriteLDO_N(0)
;
scan_io	mBank0
	if UsesRS232BufIO
	CALL	ScanRS232Out
	endif
;
	CALL	geticks
	ANDLW	0x01
	SKPNZ
	GOTO	scan_io_1
;
	if UsesScrollMenu
	CALL	ScrollMenuIdle
	CALL	ScrollStringIdle
	endif
;
	mCall0To2	OnTheTick	;call every 1/20th sec
;
scan_io_1	
	if AnyANAUsed
	CALL	read_adcs	;read the next adc
	endif
;
	if UsesLDO0
	CALL	OPT_WriteLDO_0
	endif
;
	if UsesLDO1
	CALL	OPT_WriteLDO_1
	endif
;
	if UsesLDO2
	CALL	OPT_WriteLDO_2
	endif
;
	if UsesLDO3
	CALL	OPT_WriteLDO_3
	endif
;
;
	if UsesLDI0
	CALL	ReadLDI_0
	endif
;
	if UsesLDI1
	CALL	ReadLDI_1
	endif
;
	if UsesLDI2
	CALL	ReadLDI_2
	endif
;
	if UsesLDI3
	CALL	ReadLDI_3
	endif
;
;=====================================================================================
;Toggle the system LED
; if tickcount-ledticks >= LEDTIME then toggle the LED and fall throug to OnTheHalfSecond
; Entry:ledticks,tickcount
; Exit:tickcount-ledticks
; RAM used:ledticks, tickcount, Param78
; Calls:(1+3) OnTheHalfSecond, lcd_GotoLineW,PrintString,Disp_decword,Disp_decbyteW
;	
;ToggleSysLED
	mBank0
; Check for timeout using the tick counter
; if tickcount-ledticks >= LEDTIME then ledticks=tickcount
	MOVLW	LEDTIME	;10
	MOVWF	Param78
	MOVF	ledticks,W	;22
	SUBWF	tickcount,W	;W:=tickcount-W, W=55-22=33
	SUBWF	Param78,W	;W:=LEDTIME-W, W=10-33=-23
	BTFSC	STATUS,Z
	GOTO	ToggleSysLED_1
	BTFSC	STATUS,C	;skip if borrow
	RETURN
;
; below here are routines that run every 0.5 seconds
;
ToggleSysLED_1	MOVF	tickcount,W
	MOVWF	ledticks
	MOVLW	SystemLEDMask	; Toggle system LED 
	XORWF	PORTA,F
;
; fall through to ShowAnXYZ
;
	if ANATest
;=========================================================
; X,Y,Z Analog display
ShowAnXYZ	MOVLW	ANATestLine
	CALL	lcd_GotoLineW
	if ANATestSpacing>5
	MOVLW	'X'
	CALL	DisplaysW
	endif
	BSF	STATUS,RP1	;Bank 2
	MOVF	adc0LSB,W
	MOVWF	Param76
	MOVF	adc0MSB,W
	MOVWF	Param77
	CALL	Disp_decword
;
	MOVLW	ANATestLine
	MOVWF	Param78
	MOVLW	ANATestSpacing+1
	CALL	lcd_gotoxy
	if ANATestSpacing>5
	MOVLW	'Y'
	CALL	DisplaysW
	endif
	BSF	STATUS,RP1
	MOVF	adc1LSB,W
	MOVWF	Param76
	MOVF	adc1MSB,W
	MOVWF	Param77
	CALL	Disp_decword
;	
	MOVLW	ANATestLine
	MOVWF	Param78
	MOVLW	ANATestSpacing+ANATestSpacing+2
	if ANATestSpacing>5
	CALL	lcd_gotoxy
	MOVLW	'Z'
	endif
	CALL	DisplaysW
	BSF	STATUS,RP1
	MOVF	adc3LSB,W
	MOVWF	Param76
	MOVF	adc3MSB,W
	MOVWF	Param77
	CALL	Disp_decword	
	endif		;ANATest
;
;==============================================================================
; Goto the custom routines in Main.asm
;
	BSF	PCLATH,4
	GOTO	OnTheHalfSecond
;
;=========================================================================================
; Read ADC values. A new adc value is read each call
;
; CurADC bits:
; 7 Channel is set
; 6 Conversion is started
; 5..3 ADC Channel number 0..7
; 2..0 not used
;
; Entry: none
; Exit: none
; RAM used: Param78,Param79, adc0LSB..adc7MSB, FSR (verified 2/7/05)
; Calls: (0+0) ReadADC
;
read_adcs
;
	if AnyANAUsed
	mBank0
	RRF	CurADC,W
	MOVWF	Param78
	RRF	Param78,F
	RRF	Param78,W
	ANDLW	0x07
	MOVWF	Param78,F
	INCF	Param78,F	;Param78 is now 1..8
;
; Param79 = bit mask
	BSF	_C
	CLRF	Param79
read_adcs_L1	RLF	Param79,F
	DECFSZ	Param78,F
	GOTO	read_adcs_L1
;
	MOVLW	0x38
	ANDWF	CurADC,W
	MOVWF	Param78	;Param78 is ADC# x 8, 0x00,0x08,0x10,..,0x38
;
	MOVLW	ANA_UsageMask
	ANDWF	Param79,W
	SKPNZ
	GOTO	ReadADC_Next
;
	BTFSC	CurADC,7	;Is ADCON0 setup?
	GOTO	ReadADC	;Yes
;
set_ADCON0	BSF	CurADC,7
	MOVF	ADCON0,W
	ANDLW	CHS_NoneMask	;clr CHS0..CHS2
	IORWF	Param78,W
	MOVWF	ADCON0	;set CHS0..CHS2
	RETURN
;
;========================================================================
; returns ADRESH in (FSR) and ADRESL in (FSR-1)
;
; Entry: Param78=CurADC & 0x38
; Exit: CurADC++ (if data was read)
; RAM used: Param78, FSR (verified 5/12/03)
; Calls:(0)
;
ReadADC	BTFSC	CurADC,6	;Was convertion started?
	GOTO	ReadADC_1	; Yes
	BSF	ADCON0,GO	; No, Start convertion
	BSF	CurADC,6
	RETURN
;
ReadADC_1	RRF	Param78,F	;Ö4
	RRF	Param78,W
	ANDLW	0x0E	;clear unwanted bits
	ADDLW	low adc0MSB
	MOVWF	FSR
	BSF	_IRP	;banks 2 & 3
ReadADC_L1	BTFSC	ADCON0,GO_DONE
	GOTO	ReadADC_L1	; Just in case we got back here fast.
	MOVF	ADRESH,W
	MOVWF	INDF
	DECF	FSR,F
	BSF	_RP0	;Bank 1
	MOVF	ADRESL,W
	MOVWF	INDF
	BCF	_RP0	;Bank 0
ReadADC_Next	MOVLW	0x08
	ADDWF	CurADC,F	;next adc
	MOVLW	0x38
	ANDWF	CurADC,F	;clear upper bits
;
	endif
	RETURN
;
;========================================================================================================
	if UsesI2C
;===============================================================================================
; Set the eeprom address
;  Can address all 8 32K eerom chips.
;
; Entry:eeROMbuff.Addr
; Exit:eeprom is ready for data to write
;      Param78 has EEROM_ADDR (aka chip select)
; RAM used: Param78, FSR (verified 2/26/03)
; Calls:(1+0) i2c_start, i2c_writeW, i2c_stop
;
AddressEEROMR	BCF	Param79,0	;Write flag Reading
	GOTO	AddressEEROM_E2
AddressEEROM	BSF	Param79,0	;Write flag to Writing
AddressEEROM_E2	CALL	i2c_start
	BSF	STATUS,IRP
	MOVLW	low eeROMbuff.Addr+1
	MOVWF	FSR	; middle byte of address
;
	if Using64KBEEPROM
	DECF	FSR,F	; MSB of address
	MOVF	INDF,W
	else
	RLF	INDF,W	; A15 >> C
	DECF	FSR,F	; MSB of address
	RLF	INDF,W	; 2:1:0 A17:A16:A15
	endif
;
	MOVWF	Param78
	RLF	Param78,W
;
	ANDLW	0x0E	; keep only address bits
	IORLW	EEROM_ADDR	; eerom 0 =0xA0
	MOVWF	Param78	; save the eerom command for later
			;  used by ReadEEROM
	CALL	i2c_writeW	; Command includes chip select
	INCF	FSR,F	; middle byte
	MOVF	INDF,W
;
	if Using64KBEEPROM
	else
	ANDLW	0x7F	; A15 was included in the cmd
	endif
;
	CALL	i2c_writeW	; hi byte
	INCF	FSR,F	; LSB of address
	MOVF	INDF,W
	CALL	i2c_writeW	; lo byte
	BTFSC	Param79,0	;Setup for writing?
	RETURN		; Yes
;
	CALL	i2c_stop	; stop this write
	CALL	i2c_start
	MOVF	Param78,W
	IORLW	0x01	; restart at the same address as read
	CALL	i2c_writeW
	RETURN
;
;===============================================================================================
; Read data (eeROMbuff.len 1..32 bytes) from eeproms (eeROMbuff.Addr) to eeROMbuff.Data
; Entry:eeROMbuff.len, eeROMbuff.Addr
; Exit:eeROMbuff.Data
; RAM used: Param78, Param79, FSR (verified 2/26/03)
; Calls:(1+1) AddressEEROMR, i2c_start, i2c_writeW, i2c_stop, i2c_read1, close_file
;
ReadEEROM	CALL	AddressEEROMR
;
	MOVLW	low eeROMbuff.len
	MOVWF	FSR
;	BSF	STATUS,IRP	;done by AddressEEROM
	MOVF	INDF,W
	MOVWF	Param79	;store len for easy access
	MOVLW	low eeROMbuff.Data
	MOVWF	FSR
ReadEEROM_L1	CALL	i2c_read1
	CALL	DOP_Ram
	DECFSZ	Param79,F
	GOTO	ReadEEROM_L1
	GOTO	close_file
;
	endif		;UsesI2C
;
	if UsesDataLogging
;===============================================================================================
; Erases the 2nd eeROM chip and clr the ptrs
;
; Entry: none
; Exit: none
; RAM used:Param78, FSR
; Calls:(1+3) lcd_gotoxy, DisplaysW, Disp_Hex_Byte, WriteEEROM, AddressEEROM, i2c_start, i2c_writeW, i2c_stop
;
EraseEEROM
	if UsesLCD
	MOVLW	EraseROMMsgLine
	CALL	lcd_GotoLineW	; goto(0,EraseROMMsgLine)
	MOVLW	Str_AddrPtr	;'Addr:'
	CALL	PrintString
	else
	mBank0
	endif
;
	MOVLW	low eeROMbuff.len
	MOVWF	FSR
	BSF	STATUS,IRP
	MOVLW	d'32'	;max byte writable at once
	CALL	DOP_Ram
; Set address to 0x008000
	MOVLW	0x00
	CALL	DOP_Ram	; high addr
	MOVLW	0x80
	CALL	DOP_Ram	; mid addr
	MOVLW	0x00
	CALL	DOP_Ram	; low addr
;
	MOVLW	0x20	; 32 data bytes to 0xFF
	MOVWF	Param78
	MOVLW	0xFF
EraseEEROM_L1	CALL	DOP_Ram
	DECFSZ	Param78,F
	GOTO	EraseEEROM_L1
;
EraseEEROM_L2	MOVLW	low eeROMbuff.Addr	;Show address being erased
	MOVWF	FSR	;008000
	MOVF	INDF,W
	CALL	Disp_Hex_Byte
	INCF	FSR,F
	MOVF	INDF,W
	CALL	Disp_Hex_Byte
	INCF	FSR,F
	MOVF	INDF,W
	CALL	Disp_Hex_Byte
;	
	CALL	WriteEEROM
	MOVLW	0x05
	CALL	DelayWmS	;wait 5mS
; Verify
	CALL	ReadEEROM
	MOVLW	low eeROMbuff.Data
	MOVWF	FSR
	MOVLW	0x20
	MOVWF	Param78
EraseEEROM_L3	INCFSZ	INDF,W
	GOTO	EraseEEROM_Error
	INCF	FSR,F
	DECFSZ	Param78,F
	GOTO	EraseEEROM_L3	
;	
	MOVLW	low eeROMbuff.Addr+2	; Addr=Addr+32
	MOVWF	FSR	;LSB
	MOVLW	0x20	; add 32 to the address
	ADDWF	INDF,F
	DECF	FSR,F	;middle byte
	MOVLW	0x01
	BTFSC	STATUS,C
	ADDWF	INDF,F
	DECF	FSR,F	;MSB
	BTFSC	STATUS,C
	ADDWF	INDF,F
;
	MOVLW	EndOfEEROM
	SUBWF	INDF,W
	SKPNZ
	GOTO	EraseEEROM_1
	if UsesLCD
	MOVLW	EraseROMMsgLine
	MOVWF	Param78
	MOVLW	d'5'
	CALL	lcd_gotoxy	;goto(5,EraseROMMsgLine)
	endif
	GOTO	EraseEEROM_L2
;
; clear ptr to point to last byte in Data, 0x007FFF
;
EraseEEROM_1	MOVLW	eROMFDA0
	MOVWF	Param79
	MOVLW	0xFF
	CALL	WriteEEP79WPI
	MOVLW	0x7F
	CALL	WriteEEP79WPI
	MOVLW	0x00
	GOTO	WriteEEP79W
;
;
EraseEEROM_Error	MOVLW	Str_ErrorPtr	;"Error!"
	CALL	PrintString
EraseEEROM_Stop	GOTO	EraseEEROM_Stop
	endif		;UsesDataLogging
;
	if UsesI2C
;===============================================================================================
; Write eeROMbuff.Data (eeROMbuff.len 1..32 bytes) to the eeproms (eeROMbuff.Addr)
;  After calling WriteEEROM allow 5ms for write operation to complete before calling any i2c routines.
;
; Entry:eeROMbuff.len, eeROMbuff.Addr, eeROMbuff.Data
; Exit:none
; RAM used: Param78, FSR (verified 2/26/03)
; Calls:(1+1) AddressEEROM, i2c_start, i2c_writeW, i2c_stop
;
WriteEEROM	CALL	AddressEEROM
	MOVLW	low eeROMbuff.len
	MOVWF	FSR
;	BSF	STATUS,IRP	;done by AddressEEROM
	MOVF	INDF,W
	MOVWF	Param78	;store len for easy access
	MOVLW	low eeROMbuff.Data
	MOVWF	FSR
WriteEEROM_L1	MOVF	INDF,W
	CALL	i2c_writeW
	INCF	FSR,F
	DECFSZ	Param78,F
	GOTO	WriteEEROM_L1
	GOTO	i2c_stop
;
	endif
;
	if EnableEEROMCopy
;===============================================================================================
; Copy the whole data space (EEROM) to SRAM 32KB buffer evBuff32KB
;
; Entry: W=0..F (EEROM upper 4 address bits (A15..A18))
; Exit: None
; Calls:(1+1) AddressEEROMR, i2c_read1, SRAM_WritePI, close_file
; RAM used: Param78,Param79,FSR
;
CopyEEROMtoSRAM	mBank2
	ANDLW	0x0F	;paranoid? Yes!
	MOVWF	eeROMbuff.Addr	;MSB
	CLRF	eeROMbuff.Addr+1
	CLRF	eeROMbuff.Addr+2	;LSB
	CLRC
	RRF	eeROMbuff.Addr,F	;we only do 32KB chunks so roll
	RRF	eeROMbuff.Addr+1,F	; the address bits A15..A18 into place
;
	mBank3
	CLRF	SRAM_Addr0
	MOVLW	low evBuff32KB
	MOVWF	SRAM_Addr1
	MOVLW	high evBuff32KB
	MOVWF	SRAM_Addr2
;
	CALL	AddressEEROMR
;
CopyEEROMtoSRAM_L1	CALL	i2c_read1
	CALL	SRAM_WritePI
	mBank3
	MOVLW	0x7F
	ANDWF	SRAM_Addr1,W	;Has the low 15 bits of
	IORWF	SRAM_Addr0,W	; the address
	SKPZ		; rolled over to zero?
	GOTO	CopyEEROMtoSRAM_L1	; No
;	
	GOTO	close_file
	endif
;
	if UsesDataROM
;===============================================================================================
; DataROM  Copy d.d file to SRAM
;
; Entry: None
; Exit: d.d >> SRAM starting at evDataROM*256
; RAM used:
;
SetupDataROM	CALL	ZeroFName
;
	mBank3
	MOVLW	high evDataROM
	MOVWF	SRAM_Addr2
	MOVLW	low evDataROM
	MOVWF	SRAM_Addr1
	CLRF	SRAM_Addr0
;
	MOVLW	'd'
;
	GOTO	SS_1
;
	endif
;
	if SRAM_Strings
;===============================================================================================
; Strings  Copy the s.s file to SRAM
; Entry:None
; Exit: s.s >> SRAM starting at evStrings*256
; RAM used:
; Calls: (1+2) find_file,open_file,SS_file_byte,SRAM_Write,SRAM_NextAddr,sfb_ReadNextB,i2c_read1
;
SetupStrings	CALL	ZeroFName
;
	mBank3
	MOVLW	high evStrings
	MOVWF	SRAM_Addr2	;0x01
	MOVLW	low evStrings
	MOVWF	SRAM_Addr1	;0x02
	CLRF	SRAM_Addr0
;
	MOVLW	's'	;Set filename = "s.s"
SS_1	CALL	DOP_Ram
	INCF	FSR,F
	MOVWF	INDF
	DECF	FSR,F
	MOVLW	'.'
	MOVWF	INDF
;
	mBank3
;
	CALL	find_file
	BTFSS	Param78,0
	GOTO	SS_NotFound	;file not found
	CALL	open_file
;
SS_L2	CALL	SS_file_byte
	mBank2
	BTFSS	End_Of_File
	GOTO	SS_L2
;	
	GOTO	close_file
;
SS_NotFound	CLRF	Param79	;fill with zeros
SS_L3	CLRW
	CALL	SRAM_WritePI
	CLRW
	CALL	SRAM_WritePI
	CLRW
	CALL	SRAM_WritePI
	DECFSZ	Param79,F
	GOTO	SS_L3
	RETURN
;
;=======================================
; Calls: (1+1) sfb_ReadNextB,SRAM_Write,SRAM_NextAddr
;
SS_file_byte	CALL	sfb_ReadNextB
	BTFSC	End_Of_File	;we're done with this file?
	RETURN		;yes
	MOVF	Param78,W
	GOTO	SRAM_WritePI
;
;=======================================
; CAUTION  Returns with Bank 2 selected
;
; Calls: (1+0) i2c_read1
;
sfb_ReadNextB	CALL	i2c_read1	;next file byte >> Param78
	BSF	STATUS,RP1	; Bank 2
	MOVF	romdir.f.len,W
	IORWF	romdir.f.len+1,W
	BTFSS	STATUS,Z
	GOTO	sfb_ReadNextB_1
	BSF	End_Of_File	;read past end return 0
	RETURN
sfb_ReadNextB_1	MOVF	romdir.f.len,W	; romdir.f.len--; Decrement length
	BTFSC	STATUS,Z
	DECF	romdir.f.len+1,F
	DECF	romdir.f.len,F
	RETURN
;
	endif		;SRAM_Strings
;
	if UsesI2C
;===============================================================================================
; Open the previously-found file for transmission
; sends start bit, slave address (aka chip # 0..7)
;
; RAM used: romdir.f.start (verified 2/26/03)
; Calls:(1+0) i2c_start, i2c_writeW, i2c_stop
;
; Note: the files must be in EEROM 0
;
open_file	CALL	i2c_start
	MOVLW	EEROM_ADDR	; i2c_write(EEROM_ADDR) Write start pointer to eerom 
	CALL	i2c_writeW
	BSF	STATUS,RP1	; i2c_write(high romdir.f.start); hi byte
	MOVF	romdir.f.start+1,W
	CALL	i2c_writeW
	BSF	STATUS,RP1	; i2c_write(low romdir.f.start); low byte
	MOVF	romdir.f.start,W
	CALL	i2c_writeW
	CALL	i2c_stop
	CALL	i2c_start
	MOVLW	EEROM_ADDR|1	; i2c_write(EEROM_ADDR | 1) Restart ROM access as read cycle 
	GOTO	i2c_writeW
;
;=======================================================================
; Close the previously-opened file (aka stop read operation)
; Dummy read cycle w/ NAK instead of ACK
;
; RAM used: Param78 (verified 2/26/03)
; Calls:(1+0) i2c_read, i2c_stop
;
close_file	CLRF	Param78
	CALL	i2c_read
;
; fall through to i2c_stop
;
;=====================================================================================================
; Ends a iic operation
; use I2C(MASTER, SDA=PIN_C4, SCL=PIN_C3, RESTART_WDT, FAST) 
; Entry: none
; Exit: none
; RAM used: none (verified 2/26/03)
; Calls:(0) none
i2c_stop	mBank1
	BSF	SSPCON2,PEN	; send stop bit
	BTFSC	SSPCON2,PEN	; has stop bit been sent?
	GOTO	$-1	; no, loop back to test
	BCF	_RP0	; Bank 0
	RETURN
;
;=================================================================================================
; Start an iic operation
; RAM used: none (verified 2/26/03)
; Calls: (0) none
;
i2c_start	mBank1
	BSF	SSPCON2,SEN	; send start bit
	BTFSC	SSPCON2,SEN	; has SEN cleared yet
	GOTO	$-1	; no, loop back to test
	BCF	_RP0	; Bank 0
	RETURN
;
;================================================================================================
; writes a byte to the serial EEPROM, hangs if no ACK
; entry: W byte to send
; exit: none
; RAM used: none (verified 2/26/03)
; Calls:(0) none
;
i2c_writeW	mBank0
	BCF	PIR1,SSPIF	; clear interrupt flag
	MOVWF	SSPBUF	; move data to SSPBUF
	BTFSS	PIR1,SSPIF	; has SSP completed sending?
	GOTO	$-1	; no, loop back to test
	BSF	STATUS,RP0
	BTFSC	SSPCON2,ACKSTAT	; has slave sent ACK?
	GOTO	$-1	; no, try again
	BCF	_RP0	; Bank 0
	RETURN
;
;=========================================================================================
; Read next byte
; RAM used: Param78 (verified 2/26/03)
; Calls:(0) i2c_read
;
i2c_read1	BSF	Param78,0
;
; fall through to i2c_read
;
;=========================================================================================
; Read from external serial eeprom(s)
; Entry: Param78 = 1 Read next byte send ACK, 0 = Dummy Read w/NAK
; Exit: Param78 and W = Return Value
; RAM used: Param78 (verified 2/26/03)
; Calls:(0) none
;
i2c_read	mBank0
	BCF	PIR1,SSPIF	; clear interrupt flag
	BSF	STATUS,RP0
	BSF	SSPCON2,RCEN	; enable receive mode
	BCF	STATUS,RP0
	BTFSS	PIR1,SSPIF	; has SSP received a data byte?
	GOTO	$-1	; no, loop back to test
	BSF	STATUS,RP0
	BSF	SSPCON2,ACKDT	; NAK
	BTFSC	Param78,0
	BCF	SSPCON2,ACKDT	; ACK
	BSF	SSPCON2,ACKEN	; send ACKDT bit
;
	BTFSC	SSPCON2,ACKEN	; has ACKDT bit been sent yet?
	GOTO	$-1	; no, loop back to test
	BCF	STATUS,RP0
;
	MOVF	SSPBUF,W	; save data to RAM
	MOVWF	Param78
	BSF	STATUS,RP0
	BCF	SSPCON2,RCEN	; disable receive mode
	BCF	STATUS,RP0
	RETURN
	endif		;UsesI2C
;
	if UsesEEROMFiles
;=======================================
;
ZeroFName	MOVLW	ROM_FNAMELEN	;zero filename
	MOVWF	Param78
	MOVLW	low romdir.f.name
	MOVWF	FSR
	BSF	STATUS,IRP
ZeroFName_L1	CLRF	INDF	;117..117+B
	INCF	FSR,F
	DECFSZ	Param78,F
	GOTO	ZeroFName_L1
	MOVLW	low romdir.f.name
	MOVWF	FSR
	RETURN
;
;=================================================================================================
; Definitions for filesystem
; 
; The filesystem is in 1 or 2 ROMs (32k bytes each). At the start of the first ROM is a 
; directory of 1 or more filename blocks, each of which have pointers to 
; data blocks. The end of the directory is marked by a dummy length of FFFFh 
; 
; All the HTTP files include the appropriate HTTP headers. 
; 
; There may be 2 special files in the file list:
;  "s.s" is the strings file for SRAM based strings.
;  "d.d" is the SRAM data image
; 
; Filename block structure
; WORD len;	Length of file in bytes
; WORD start;	Start address of file data in ROM
; WORD check;	TCP checksum of file
; BYTE flags;	Embedded Gateway Interface (EGI) flags
; char name[ROM_FNAMELEN]; Lower-case filename with extension
; 	
;
;===============================================================================================
;===============================================================================================
; Find a filename in ROM filesystem. Return false if not found 
; ** Sets fileidx(Param72) to 0 if ROM error, 1 if file is first in ROM, 2 if 2nd.. 
; ** and leaves directory info in 'romdir' 
; ** If the first byte of name is zero, match first directory entry
;
; Entry: romdir.f.name
; Exit: Param78:0 1=found
; RAM used: Param77, Param78, Param79, Param7A, romdir(19 bytes) (verified 2/26/03)
; Calls:(1+0) i2c_start, i2c_writeW, i2c_stop, i2c_read, i2c_read1
;
; BOOL mismatch=1, end=0;   Param79:0, Param79:1
; int i; Param7A
; BYTE b; Param7B
;
find_file	BSF	Param79,0	; mismatch=1
	BCF	Param79,1	; end=0
	CLRF	Param77	; fileidx = 0; Set ROM address pointer to 0 
	CALL	i2c_start
	MOVLW	EEROM_ADDR
	CALL	i2c_writeW	; i2c_write(EEROM_ADDR); 
	CLRW
	CALL	i2c_writeW	; i2c_write(0) Address=0x0000
	CLRW	
	CALL	i2c_writeW	; i2c_write(0)
	CALL	i2c_stop
	CALL	i2c_start	;Read next directory entry
	MOVLW	EEROM_ADDR|1	; i2c_write(EEROM_ADDR | 1);
	CALL	i2c_writeW	; continue read at current address
;  
; Get file len, ptr, csum and flags     romdir.f.len..romdir.f.flags  7 bytes
; for i=7 downto 1
find_file_L1	MOVLW	0x07
	MOVWF	Param7A
	MOVLW	low romdir.f.len	; romdir.b[i] = i2c_read(1); 
	MOVWF	FSR
	BSF	STATUS,IRP
;
find_file_L2	CALL	i2c_read1
	CALL	DOP_Ram	;110+Param7A
	DECFSZ	Param7A,F
	GOTO	find_file_L2
;
	BSF	STATUS,RP1
	INCF	romdir.f.len+1,W	;if high byte = FF that's the end
	BTFSS	STATUS,Z
	GOTO	find_file_1
	BSF	Param79,1	; end = 1
	GOTO	find_file_4	; Abandon if no entry 
;
find_file_1	BCF	Param79,0	; mismatch = 0;  Try matching name 
; for i=ROM_FNAMELEN downto 0
	MOVLW	ROM_FNAMELEN
	MOVWF	Param7A
find_file_L3	CALL	i2c_read1
	SUBWF	INDF,W
	BTFSS	STATUS,Z
	BSF	Param79,0	; mismatch = 1;
	INCF	FSR,F
	DECFSZ	Param7A,F
	GOTO	find_file_L3	; test all 12 bytes
; if (!romdir.f.name[0])   If null name, match anything 
	BSF	STATUS,RP1
	MOVF	romdir.f.name,F
	BTFSC	STATUS,Z
	BCF	Param79,0	; mismatch = 0; 
; 
; Loop until matched 	
; while (!end && fileidx++<>MAXFILES && mismatch); 
find_file_4	BTFSC	Param79,1	; skip if not end
	GOTO	find_file_5	; end of dir
	MOVF	Param77,W	;fileidx
	INCF	Param77,F
	SUBLW	MAXFILES	; MAXFILES-fileidx
	BTFSC	STATUS,Z
	GOTO	find_file_5	; no more files
	BTFSC	Param79,0	; skip if not mismatch
	GOTO	find_file_L1	; mismatch
; if (mismatch) 
find_file_5	BTFSS	Param79,0	; skip if mismatch
	GOTO	find_file_End	; not mismatch
; romdir.f.len = 0; 
	BSF	STATUS,RP1
	CLRF	romdir.f.len
	CLRF	romdir.f.len+1
	BCF	STATUS,RP1
; return(!mismatch); 
find_file_End	CALL	close_file	; i2c_read(0); NAK
	CLRF	Param78
	BTFSS	Param79,0	; skip if mismatch
	BSF	Param78,0	; return found=true
	RETLW	00
;
	endif
;
	if RS232Config
;=================================================================================================
; User initialisation code; get serial number and IP address 
; Skip if user hits ESC
; RAM used: Param7F
; Calls:(1+2) TXString, getnum, putchar, write_nonvol, xmodem_recv
; 	
user_config	mBank0
	BCF	escaped	; escaped = false
	MOVLW	SerNumStrPtr	;"\r\nSerial num? "
	CALL	TXString
	CALL	getnum	; w = getnum();
; if (!escaped) 
	BTFSC	escaped
	GOTO	UC_SkipMAC
 
	MOVF	Param79,W	; myeth[4] = w >> 8;
	MOVWF	myeth4

	MOVF	Param78,W	; myeth[5] = w; 
	MOVWF	myeth5
 
UC_SkipMAC	BCF	escaped	; escaped = 0;
;
	MOVLW	IPAddrStrPtr	;"\r\nIP addr? "
	CALL	TXString
;	
;	BSF	PORTA,UserLED2	; USERLED1 = USERLED2 = 1;
;	BSF	PORTA,UserLED1
	CALL	getnum	; myip.b[3] = getnum(); 
	BTFSC	escaped
	GOTO	UC_SkipIP
;
	MOVF	Param78,W
	MOVWF	myip_b3
	MOVLW	'.'
	CALL	putchar
; if (!escaped) 
	CALL	getnum	; myip.b[2] = getnum(); 
	BTFSC	escaped
	GOTO	UC_SkipIP
	MOVF	Param78,W
	MOVWF	myip_b2
	MOVLW	'.'
	CALL	putchar
; if (!escaped) 
	CALL	getnum	; myip.b[1] = getnum(); 
	BTFSC	escaped
	GOTO	UC_SkipIP
	MOVF	Param78,W
	MOVWF	myip_b1
	MOVLW	'.'
	CALL	putchar
;
	CALL	getnum	; myip.b[0] = getnum(); 
	BTFSC	escaped
	GOTO	UC_SkipIP
	MOVF	Param78,W
	MOVWF	myip_b0	;we either have a serial num and an IP
	CALL	write_nonvol	; or just an IP and the serial will be reused
;
UC_SkipIP	MOVLW	XmodemStrPtr	;"\r\nXmodem? "
	CALL	TXString
	endif
; fall through to xmodem_recv
;
	if xmodemEEROM
;==============================================================================================
; Handle incoming XMODEM data block
;
; Entry: none
; Exit: none
; RAM used:Param75, Param76, Param78, Param79, Param7A, Param7B, Param7C
; Calls:(1+2) geticks, putchar, get_char, i2c_start, i2c_writeW, i2c_stop
;
; BYTE b Param79, len=0 Param76, idx Param7A, blk Param7B, i Param7C
; BOOL rxing(Param75,0)=FALSE, b1(Param75,1)=FALSE, b2(Param75,2)=FALSE, b3(Param75,3)=FALSE
;
xmodem_recv	mBank0
	CLRF	Param76	;len
	BCF	Param75,0	;rxing=FALSE
	BCF	Param75,1	;b1=FALSE
	BCF	Param75,2	;b2=FALSE
	BCF	Param75,3	;b3=FALSE
; 
; timeout(ledticks, 0); 
	MOVF	tickcount,W
	MOVWF	ledticks
;
xmodem_recv_Loop	BTFSC	PIR1,RCIF
	GOTO	xmodem_recv_3
;
	CALL	geticks	; geticks() Check for timeout 
; if (timeout(ledticks, LEDTIME)) 
;
	MOVLW	LEDTIME
	MOVWF	Param78
	MOVF	ledticks,W
	SUBWF	tickcount,W	;W:=tickcount-ledticks
	SUBLW	Param78	;W:=LEDTIME-W
	BTFSC	STATUS,Z
	GOTO	xmodem_recv_1	;ticks=LEDTIME
	BTFSC	STATUS,C	
	GOTO	xmodem_recv_Loop	;ticks<LEDTIME
;
xmodem_recv_1	MOVF	tickcount,W	;it is time
	MOVWF	ledticks
	MOVLW	SystemLEDMask	; SYSLED = !SYSLED; 
	XORWF	PORTA,F
;	BSF	PORTA,UserLED1	; USERLED1 = 1; 
; if (!rxing)  Send NAK if idle 
	BTFSC	Param75,0	;rxing
	GOTO	xmodem_recv_2
	CLRF	Param76	; len = 0;
	BCF	Param75,3	; b1 = FALSE; 
	BCF	Param75,2	;b2=FALSE
	BCF	Param75,1	;b1=FALSE
	MOVLW	NAK	; putchar(NAK); 
	CALL	putchar
;
xmodem_recv_2	BCF	Param75,0	; rxing = FALSE; 
	GOTO	xmodem_recv_Loop
;
xmodem_recv_3	CALL	get_char	; b = getchar() Get character 
	MOVF	Param78,W
	MOVWF	Param79	;b
	BSF	Param75,0	; rxing = TRUE;
; if (!b1)   Check if 1st char 
	BTFSC	Param75,1	;b1
	GOTO	xmodem_recv_5
; if (b == SOH)   ..if SOH, move on 
	MOVLW	SOH
	SUBWF	Param79,W	;b
	BTFSS	STATUS,Z
	GOTO	xmodem_recv_4
	BSF	Param75,1	; b1 = TRUE; 
; else if (b == EOT) ..if EOT, we're done 
	GOTO	xmodem_recv_Loop
;
xmodem_recv_4	MOVLW	EOT
	SUBWF	Param79,W	;b
	BTFSS	STATUS,Z
	GOTO	xmodem_recv_Loop
; 
	MOVLW	ACK	; putchar(ACK);
	CALL	putchar
	RETURN		;the only way out of xmodem
; 
; else if (!b2)   Check if 2nd char 
xmodem_recv_5	BTFSC	Param75,2	;b2
	GOTO	xmodem_recv_6
; blk = b;    ..block num 
	MOVF	Param79,W	;b
	MOVWF	Param7B	;blk
	BSF	Param75,2	; b2 = TRUE; 
	GOTO	xmodem_recv_Loop
;
; else if (!b3)   Check if 3rd char 
xmodem_recv_6	BTFSC	Param75,3	;b3
	GOTO	xmodem_recv_7
; if (blk == ~b)   ..inverse block num 
	MOVF	Param79,W	;b
	XORLW	0xFF
	SUBWF	Param7B,W	;blk
	BTFSS	STATUS,Z
	GOTO	xmodem_recv_Loop
;
	BSF	Param75,3	; b3 = TRUE;
	DECF	Param7B,F	; blk--
	GOTO	xmodem_recv_Loop
;
; else if (len < XBLOCK_LEN)  Rest of chars up to block len 
xmodem_recv_7	MOVLW	XBLOCK_LEN
	SUBWF	Param76,W	;len
	BTFSC	STATUS,C
	GOTO	xmodem_recv_8
;  Buffer into ROM page 
; idx = len & (ROMPAGE_LEN - 1); 
	MOVF	Param76,W	;len
	ANDLW	ROMPAGE_LEN-1
	MOVWF	Param7A	;idx
	INCF	Param76,F	; len++;
; txbuff[idx] = b;  If end of ROM page.. 
	MOVLW	txbuff
	ADDWF	Param7A,W	;idx
	MOVWF	FSR
	BCF	STATUS,IRP
	MOVF	Param79,W	;b
	MOVWF	INDF	;0A0..0A0+Param7A (0BF max)
; if (idx == ROMPAGE_LEN-1) ..write to ROM 
	MOVLW	ROMPAGE_LEN-1
	SUBWF	Param7A,W	;idx
	BTFSS	STATUS,Z
	GOTO	xmodem_recv_Loop
;
	CALL	i2c_start
	MOVLW	EEROM_ADDR	;eeprom 0 write
	CALL	i2c_writeW
	BCF	STATUS,C
	RRF	Param7B,W	;blk  blocks are 128 bytes not 256
	CALL	i2c_writeW	;high byte of address
	CLRF	Param78	; move the low bit around to the high bit
	RRF	Param7B,W	;blk
	RRF	Param78,F
	MOVLW	ROMPAGE_LEN
	SUBWF	Param76,W	;W:=len-ROMPAGE_LEN
	IORWF	Param78,W	; get the high bit
	CALL	i2c_writeW	;low byte of address
; for (i=0; i<ROMPAGE_LEN; i++) 
	MOVLW	ROMPAGE_LEN
	MOVWF	Param7C	;i
	MOVLW	txbuff
	MOVWF	FSR
	BCF	STATUS,IRP
xmodem_recv_L1	MOVF	INDF,W	;0A0+Param7C
	CALL	i2c_writeW	;data byte 64 max before i2c_stop
	INCF	FSR,F
	DECFSZ	Param7C,F	;i
	GOTO	xmodem_recv_L1
;
	CALL	i2c_stop
	GOTO	xmodem_recv_Loop
;
; else  End of block, send ACK 
; 
xmodem_recv_8	MOVLW	ACK	; putchar(ACK);
	CALL	putchar
;
	MOVLW	SystemLEDMask	; SYSLED = !SYSLED; 
	XORWF	PORTA,F
	CLRF	Param76	; len = 0; 
	BCF	Param75,3	; b1 = FALSE;
	BCF	Param75,2	;b2=FALSE
	BCF	Param75,1	;b1=FALSE
	GOTO	xmodem_recv_Loop
;
	endif
;
	if UsesRS232BufIO
;=================================================================================================
; Get a character from the RS232 port and put it in the buffer
; ISR version. If no char is available do nothing.
;
; Entry: none, Bank0 must be selected
; Exit: none
; RAM used: none
; Calls: (0) none
;
ScanRS232In	MOVF	RCSTA,W
	MOVWF	ISR_W_Temp	;save reciever status
	MOVF	RCREG,W
	BTFSS	ISR_W_Temp,OERR	;skip if overrun error
	GOTO	ScanRS232In_1
	BCF	RCSTA,CREN	;clear overrunn
	BSF	RCSTA,CREN
	GOTO	ScanRS232In_RTN
;
ScanRS232In_1	MOVWF	ISR_W_Temp	;Save Data received
; set 24 bit address
	BSF	_RP0	;Bank1
	MOVLW	All_Out
	MOVWF	TRISD
	BSF	_RP1	;Bank3
	MOVF	rsInBuffInPtr,W	;W=(rsInBuffInPtr)
	INCF	rsInBuffInPtr,F	;rsInBuffInPtr++
	INCF	rsInBuffCount,F	;rsInBuffCount++
	mBank0
	MOVWF	PORTD
;
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	Select0
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	BSF	PORTB,SelectEnable
;
	MOVLW	low evRS232InBuff
	MOVWF	PORTD
;
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	Select1
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	BSF	PORTB,SelectEnable
;
	MOVLW	high evRS232InBuff
	MOVWF	PORTD
;
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	Select2
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	BSF	PORTB,SelectEnable
; Store data in SRAM
	MOVF	ISR_W_Temp,W
	MOVWF	PORTD
	BSF	PORTB,IORead	;OE* = inactive
	BCF	PORTB,IOWrite
;
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	SelectSRAM
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	BSF	PORTB,SelectEnable
;
	BSF	PORTB,IOWrite	
; Restore 24 bit address
	mBank3
	MOVF	CurrentAddr0,W
	mBank0
	MOVWF	PORTD
;
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	Select0
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	BSF	PORTB,SelectEnable
;
	mBank3
	MOVF	CurrentAddr1,W
	mBank0
	MOVWF	PORTD
;
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	Select1
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	BSF	PORTB,SelectEnable
;
	mBank3
	MOVF	CurrentAddr2,W
	mBank0
	MOVWF	PORTD
;
	MOVF	PORTB,W
	ANDLW	AddressMask
	IORLW	Select2
	MOVWF	PORTB
	BCF	PORTB,SelectEnable
	BSF	PORTB,SelectEnable
;
	GOTO	ScanRS232In_RTN
	endif
;
;
	if UsesRS232BufIO
;=================================================================================================
; Get a character from the RS232 input buffer
;
; Entry: none, Bank0 must be selected
; Exit: rsGotChar set if char is in W else cleared
; RAM used: none (verified 4/4/2003)
; Calls: (0+1) SRAM_Read
;
GetRS232Chr	BCF	rsGotChar	;Default to no char.
	mBank3
	MOVF	rsInBuffCount,F
	mBank0
	SKPNZ		;Chars in buffer?
	RETURN		;No
	BSF	rsGotChar	;we're getting a char
	mBank3
	DECF	rsInBuffCount,F	;rsInBuffCount--
	MOVF	rsInBuffOutPtr,W	;SRAM_Addr0=(rsInBuffOutPtr++)
	INCF	rsInBuffOutPtr,F
	MOVWF	SRAM_Addr0
	MOVLW	high evRS232InBuff
	MOVWF	SRAM_Addr2
	MOVLW	low evRS232InBuff
	MOVWF	SRAM_Addr1
	GOTO	SRAM_Read
;
;=================================================================================================
; Put a character from the output buffer in the RS232 port
;
; Entry: none, Bank0 must be selected
; Exit: none
; RAM used: none (verified 4/4/2003)
; Calls:(0+1) SRAM_Read
;
ScanRS232Out	BTFSS	PIR1,TXIF	;Last Tx done yet?
	RETURN		;No
	mBank3
	MOVF	rsOutBuffCount,F
	SKPNZ		;Output buffer empty?
	GOTO	Bank0Rtn	;Yes
	DECF	rsOutBuffCount,F	;rsOutBuffCount--
	MOVF	rsOutBuffOutPtr,W	;W=rsOutBuffOutPtr++
	INCF	rsOutBuffOutPtr,F
	MOVWF	SRAM_Addr0
	MOVLW	high evRS232OutBuff
	MOVWF	SRAM_Addr2
	MOVLW	low evRS232OutBuff
	MOVWF	SRAM_Addr1
	CALL	SRAM_Read
	MOVWF	TXREG
	RETURN
;
;=================================================================================================
; Put a character into the RS232 output buffer
;
; Entry: Char in W
; Exit: Param78=Param77=Char
; RAM used: Param77, Param78, Param79 (verified 4/10/2003)
; Calls: (1+2) SRAM_Write, ScanRS232Out
;
PutRS232Chr	MOVWF	Param77	;save char
PutRS232Chr_L1	mBank3
	INCFSZ	rsOutBuffCount,W	;Is buffer about to overflow?
	GOTO	PutRS232Chr_1	;No
	CALL	ScanRS232Out
	GOTO	PutRS232Chr_L1
;
PutRS232Chr_1	mBank3
	MOVF	rsOutBuffInPtr,W	;W=(rsOutBuffInPtr++)
	INCF	rsOutBuffInPtr,F
	INCF	rsOutBuffCount,F	;rsOutBuffCount++
	MOVWF	SRAM_Addr0
	MOVLW	high evRS232OutBuff
	MOVWF	SRAM_Addr2
	MOVLW	low evRS232OutBuff
	MOVWF	SRAM_Addr1
	MOVF	Param77,W
	GOTO	SRAM_Write	
;
	endif
;
	if RS232Active
;===========================================================================================================
; Get a character from the serial port
; Warning! Waits for next chr.
; Entry: none
; Exit: Param78=Chr, Param79=RCSTA
; RAM used: Param78, Param79 (verified 1/30/03)
; Calls: (0) none
; use RS232 (BAUD=9600, XMIT=PIN_C6, RCV=PIN_C7, ERRORS) 
;
get_char	BTFSS	PIR1,RCIF
	GOTO	get_char
	MOVF	RCSTA,W
	MOVWF	Param79
	MOVF	RCREG,W
	MOVWF	Param78
	BTFSS	Param79,OERR
	RETURN
	BCF	RCSTA,CREN
	BSF	RCSTA,CREN
	RETURN
; 
	endif
;
	if RS232Config
;==============================================================================================
;  Get a 16-bit decimal number from the console 
;  Return it when any non-numeric key is pressed (except backspace)
; RAM used: Param70:Param71=val, Param72=n, Param73=i, Param78, Param79, txbuff..txbuff+4
; Calls:(1+1) scan_io, get_char, putchar
;
getnum	mBank0
	CLRF	Param70	;val (2 bytes)
	CLRF	Param71
	CLRF	Param72	;n=0
; while (!kbhit()) 
getnum_L1	BTFSC	PIR1,RCIF
	GOTO	getnum_1
	CALL	scan_io
	GOTO	getnum_L1
;
getnum_1	CALL	get_char	; Param78 = getchar();
; if (c == 0x1b) 
	MOVLW	0x1B	; escape
	SUBWF	Param78,W
	BTFSS	STATUS,Z
	GOTO	getnum_2	; not escape
	BSF	escaped	; escaped = 1; 
	GOTO	getnum_6
; else if (c>='0' && c<='9') 
getnum_2	MOVLW	'0'
	SUBWF	Param78,W	;Char-'0'
	BTFSS	STATUS,C	;skip if Char>='0'
	GOTO	getnum_3
	MOVLW	0x3A	;'9'+1
	SUBWF	Param78,W	;Char-('9'+1)
	BTFSC	STATUS,C	;skip if Char<('9'+1)
	GOTO	getnum_3
; if (n < sizeof(buff)) 
	MOVLW	0x05	;n=0..4
	SUBWF	Param72,W	;W=n-5
	BTFSC	STATUS,C	;skip if n<5
	GOTO	getnum_6
	MOVF	Param72,W	; buff[n++] = c;
	INCF	Param72,F	;n++
	ADDLW	txbuff
	MOVWF	FSR
	BCF	STATUS,IRP
	MOVF	Param78,W
	MOVWF	INDF	;txbuff..txbuff+5
	MOVF	Param78,W	; putchar(c); 
	CALL	putchar
	GOTO	getnum_6
; else if (c=='\b' || c==0x7f) 
getnum_3	MOVLW	0x08	;backspace
	SUBWF	Param78,W
	BTFSC	STATUS,Z
	GOTO	getnum_4
	MOVLW	0x7F	;delete
	SUBWF	Param78,W
	BTFSS	STATUS,Z
	GOTO	getnum_5
; if (n > 0) 
getnum_4	MOVF	Param72,F
	BTFSC	STATUS,Z
	GOTO	getnum_6
; handle backspace or delete
	DECF	Param72,F	; n--
	MOVLW	'\b'
	CALL	putchar
	MOVLW	' '
	CALL	putchar
	MOVLW	'\b'
	CALL	putchar
	GOTO	getnum_6
;
getnum_5	CLRF	Param78	; c = 0  was an invalid Char
;  while (c && !escaped); 
getnum_6	MOVF	Param78,F
	BTFSC	STATUS,Z
	GOTO	getnum_7	; invalid Char or Chr(13)
	BTFSS	escaped
	GOTO	getnum_L1	; get another one
;
;handle the first char dif
getnum_7	MOVF	Param72,W
	BTFSC	STATUS,Z
	GOTO	getnum_End
	MOVLW	txbuff
	MOVWF	FSR
	BCF	STATUS,IRP
	MOVLW	'0'
	SUBWF	INDF,W	;txbuff..txbuff+4
	INCF	FSR,F
	MOVWF	Param70
; while (n>1) 
getnum_L2	DECF	Param72,F	;n--
	BTFSC	STATUS,Z
	GOTO	getnum_End
;
; val = (val * 10) + (buff[i++] - '0'); 
	MOVLW	0x09	;add 9 times + the original
	MOVWF	Param73	; i:=9
	MOVF	Param71,W	;temp:=val
	MOVWF	Param79
	MOVF	Param70,W
	MOVWF	Param78
getnum_L3	MOVF	Param78,W	;val:=val+temp
	ADDWF	Param70,F
	BTFSC	STATUS,C
	INCF	Param71,F
	MOVF	Param79,W
	ADDWF	Param71,F
	DECFSZ	Param73,F
	GOTO	getnum_L3
;
	MOVLW	'0'
	SUBWF	INDF,W	;txbuff..txbuff+4
	INCF	FSR,F
	ADDWF	Param70,F
	BTFSC	STATUS,C
	INCF	Param71,F
	GOTO	getnum_L2
;
getnum_End	MOVF	Param70,W	; return(val); 
	MOVWF	Param78
	MOVF	Param71,W
	MOVWF	Param79
	RETURN
	endif
;
	if Do_eeROM_Test
;===============================================================================================
; Test the eeROM
; Entry: none
; Exit: Does NOT exit
; RAM used:
; Calls:(1+)
;
eeROM_Test	MOVLW	0x02
	CALL	lcd_GotoLineW	;goto begining of 3rd line
	MOVLW	'e'
	CALL	DisplaysW
	MOVLW	'e'
	CALL	DisplaysW
	MOVLW	'R'
	CALL	DisplaysW
	MOVLW	'O'
	CALL	DisplaysW
	MOVLW	'M'
	CALL	DisplaysW
	MOVLW	':'
	GOTO	DisplaysW
;read first byte and show it
	CALL	i2c_start
	MOVLW	EEROM_ADDR
	CALL	i2c_writeW	; i2c_write(EEROM_ADDR); 
	CLRW
	CALL	i2c_writeW	; i2c_write(0) Address=0x0000
	CLRW	
	CALL	i2c_writeW	; i2c_write(0)
	CALL	i2c_stop
	CALL	i2c_start	;Read next directory entry
	MOVLW	EEROM_ADDR|1	; i2c_write(EEROM_ADDR | 1);
	CALL	i2c_writeW	; continue read at current address
	CALL	i2c_read1
	MOVWF	Param7A
	CALL	close_file
	MOVF	Param7A,W
	CALL	Disp_Hex_Byte
eeROM_Test_Stop	GOTO	eeROM_Test_Stop
	endif
;
	if UsesNIC & UsesLCD
;=====================================
; Display IP address on 2nd line
;
; Entry: none
; Exit: none
; RAM used: Param71:0, Param77,Param78, Param79, Param7A, Param7B
; Calls:(1+3) lcd_GotoLineW, Disp_decbyteW, Display_Dot
;
DispIP	MOVLW	DispIPLine
	CALL	lcd_GotoLineW
;
;  Bank0 must be selected before calling this entry point
DispIP_E2	BCF	DispLSpaces
	MOVF	myip_b3,W	; MSB
	CALL	Disp_decbyteW
	CALL	Display_Dot
	MOVF	myip_b2,W
	CALL	Disp_decbyteW
	CALL	Display_Dot
	MOVF	myip_b1,W 
	CALL	Disp_decbyteW
	CALL	Display_Dot
	MOVF	myip_b0,W	; LSB
	GOTO	Disp_decbyteW
;
	if UsesDispMAC
;=====================================
; Display MAC address on 2nd line
;
; Entry: none
; Exit: none
; RAM used: Param71:0, Param76, Param77,Param78, Param79, Param7A, Param7B
; Calls:(1+3) lcd_GotoLineW, Disp_Hex_Byte, Display_Colon
;
DispMAC	MOVLW	0x01
	CALL	lcd_GotoLineW
;
;  Bank0 must be selected before calling this entry point
DispMAC_E2	MOVF	myeth0,W	; MSB
	CALL	Disp_Hex_Byte
	CALL	Display_Colon
	MOVF	myeth1,W
	CALL	Disp_Hex_Byte
	CALL	Display_Colon
	MOVF	myeth2,W 
	CALL	Disp_Hex_Byte
	CALL	Display_Colon
	MOVF	myeth3,W	; LSB
	CALL	Disp_Hex_Byte
	CALL	Display_Colon
	MOVF	myeth4,W	; LSB
	CALL	Disp_Hex_Byte
	CALL	Display_Colon
	MOVF	myeth5,W	; LSB
	GOTO	Disp_Hex_Byte
;
	endif
	endif
; 
;================================================================================================
; end of segment 0  (0000-07FF)
;================================================================================================
;

 
 
 
 
 
 
 
 
 
 
