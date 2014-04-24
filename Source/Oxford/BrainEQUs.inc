	subtitle	"BrainEQUs.inc"
	page
;===========================================================================================
;
;  FileName: BrainEQUs.inc
;  Date: 5/6/06
;  File Version: 1.1.1
;  
;  Author: David M. Flynn
;  Company: Oxford V.U.E., Inc.
;
;============================================================================================
; Notes:
;  This file contains only EQU's.
;  These EQU's are common to most Brain (GP CPU) projects.
;
;============================================================================================
; Revision History
;
; 1.1.1 5/6/2006	Added ADC EQUs, Baud38400
; 1.1   12/2/2004	Added Param70... and HasISR to this file.
; 1.0   10/29/2004	Copied EQU's from Vis-U-Etch7.asm
;
;============================================================================================
;
All_In	EQU	0xFF
All_Out	EQU	0x00
;
;=========================================================================================
;Conditions
	if UsesISR
HasISR	EQU	0x80	;used to enable interupts 0x80=true 0x00=false
	else
HasISR	EQU	0x00	;used to enable interupts 0x80=true 0x00=false
	endif
;
;---------------------------------------------------------
; Baud rates for Fosc= 19.6608MHz
; Low speed async (Baud Fosc/(64(X+1)))
Baud1200	EQU	0xFF	;1200 0% Error
Baud2400	EQU	0x7F	;2400 0% Error
Baud4800	EQU	0x3F	;4800 0% Error
Baud9600	EQU	0x1F	;9600 0% Error
Baud19200	EQU	0x0F	;19200 0% Error
Baud28800	EQU	0x09	;30720 Tx with 2 stop bits
Baud33600	EQU	0x08	;34133
Baud38400	EQU	0X07	;38400 0% Error
Baud57600	EQU	0x04	;61440
;Baud115200	EQU	0x02	;102.4 12% Error
; Low speed async (Baud=Fosc/(16(X+1)))
;Baud115200	EQU	0x0A	;111.709 3% Error
;
;----------------------------
; Timer 2 stuff
;
T2CON_Value	EQU	b'01111110'	;preS 1:16 postS 1:16
PR2_Value	EQU	d'75'	;3.90625 miliseconds
;
TIMER1_DIV	EQU	d'120'	;Fosc/4/8/(120*256)=20
;bit 0 is used for R/W 1/0, bits 3:1 are the device # 0..7, each device can hold 32k bytes
EEROM_ADDR	EQU	0xA0	;i2c addr for eerom 0
ROMPAGE_LEN	EQU	d'32'	; eerom buffer size
XBLOCK_LEN	EQU	d'128'	;xmodem block length
MACLEN	EQU	0x06
IPAddrLEN	EQU	0x04
ROM_FNAMELEN	EQU	0x0C	;Maximum filename size
MAXFILES	EQU	d'100'	;Maximum files in dir
;
;ADCON0 stuff
ADCON0Val	EQU	0x81	;div32,CH0,ON
ADC_CLOCK_DIV_32	EQU	0x80
ADC_CLOCK_DIV_Mask	EQU	0x38
CHS_NoneMask	EQU	0xC7	;Channel select none aka zero
CHS0Mask	EQU	0x00	; bits for ch 0
CHS1Mask	EQU	0x08	; bits for ch 1
CHS2Mask	EQU	0x10	; bits for ch 2
CHS3Mask	EQU	0x18	; bits for ch 3
CHS4Mask	EQU	0x20	; bits for ch 4
CHS5Mask	EQU	0x28	; bits for ch 5
CHS6Mask	EQU	0x30	; bits for ch 6
CHS7Mask	EQU	0x38	; bits for ch 7
;
;
;ADCON1 stuff
All_Analog	EQU	0x80	;AN0..AN7 w/ Right Justified
All_AnalogLeft	EQU	0x00	;AN0..AN7 w/ Left Justified
MaxAnaWVref	EQU	0x81	;AN0..AN2,Vref+,AN4..AN7
Analog5Chnls	EQU	0x82	;AN0..AN4
Analog5ChnlsLeft	EQU	0x02	;AN0..AN4
Analog4ChnlsWVref	EQU	0x83	;AN0..AN2,Vref+,AN4
RA0_RA1_RA3_ANALOG	EQU	0x84	;AN0,AN1,AN3 w/ Right Justified
Analog2ChnlsWVref	EQU	0x85	;AN0,AN1,Vref+
All_Digital	EQU	0x87	;No AN w/ Right Justified of ADRESH
Analog6ChnlsWVref	EQU	0x88	;AN0,AN1,Vref-,Vref+,AN4..AN7
Analog6Chnls	EQU	0x89	;AN0..AN5
Analog5ChnlsWVref	EQU	0x8A	;AN0..AN2,Vref+,AN4,AN5
Analog4ChnlsW2Vref	EQU	0x8B	;AN0,AN1,Vref-,Vref+,AN4,AN5
Analog3ChnlsW2Vref	EQU	0x8C	;AN0,AN1,Vref-,Vref+,AN4
Analog2ChnlsW2Vref	EQU	0x8D	;AN0,AN1,Vref-,Vref+
RA0_ANALOG	EQU	0x8E	;RA0 w/ Right Justified
Analog1ChnlW2Vref	EQU	0x8F	;AN0,Vref-,Vref+
;
LEDTIME	EQU	d'10'	;Interval for toggling system LED 10 ticks
TXBUFFLEN	EQU	d'64'	;64 byte buffer A0..DF
;
;1:8 prescale,Osc Enabled, Timer on, etc see page 51
TIMER1_SET	EQU	0x35	;1:8 Prescale, Osc Off,Internal Fosc/4 clock, Enabled
;
;ascii
SOH	EQU	0x01
EOT	EQU	0x04
ACK	EQU	0x06
LF	EQU	0x0A
CR	EQU	0x0D
NAK	EQU	0x15
CAN	EQU	0x18
ESC	EQU	d'27'
;
PCOL_ARP	EQU	0x0806	;Protocol type: ARP 
PCOL_IP	EQU	0x0800	;IP
ARPPRO	EQU	0x0800	
; 
HTYPE	EQU	0x0001
ARPREQ	EQU	0x0001	;ARP request & response IDs 
ARPRESP	EQU	0x0002 
RARPREQ	EQU	0x0003	;RARP request & response IDs 
RARPRESP	EQU	0x0004
; 
PICMP	EQU	1	;IP protocol values: ICMP 
ICMP_EReply	EQU	0	;ICMP type echo reply
ICMP_ERequest	EQU	8	;ICMP type echo request
;
; IP ipcol values
PTCP	EQU	6	;TCP 
PUDP	EQU	d'17'	;UDP 
; 
ETHHDR_LEN	EQU	MACLEN+MACLEN+2	;Ethernet frame header length 
IPHDR_LEN	EQU	d'20'	;IP, TCP and ICMP header lengths 
TCPHDR_LEN	EQU	d'20' 
UDPHDR_LEN	EQU	d'8'
ICMPHDR_LEN	EQU	4	;(only include type, code & csum in ICMP hdr) 
TCPOPT_LEN	EQU	4	;Length of TCP MSS option 
TCPSYN_LEN	EQU	d'24'	;TCP header length including MSS option	
MAXPING_LEN	EQU	d'212'	;Max length of Ping data 
NICETHERHEADER_LEN	EQU	0x12	;NIC hardware packet header length
ETHERHEADER_LEN	EQU	0x0E
eeROMBuffLen	EQU	0x20	; size of eeROM buffer in RAM
; 
;TCP segment code bits
TFIN	EQU	0x01	;Option flags: no more data (sender is done)
TSYN	EQU	0x02	;synchronize sequence numbers 
TRST	EQU	0x04	;reset connection 
TPUSH	EQU	0x08	;this segment requests a push of buffered data 
TACK	EQU	0x10	;acknowledgement field is valid
TURGE	EQU	0x20	;urgent pointer field is valid
; 
TCP_MSS	EQU	d'1460'	;Max Segment Size for TCP 
TCP_WDWSize	EQU	d'3000'	;Max Window size for buffer fit
;
;TCP/UDP Ports
ECHOPORT	EQU	d'7'	;udp/tcp Port numbers: echo 
DAYPORT	EQU	d'13'	;udp/tcp daytime 
TimePort	EQU	d'37'	;udp/tcp time
TermPort	EQU	d'57'	;udp/tcp any private terminal access
FilePort	EQU	d'59'	;udp/tcp any private file service
BOOTPSPort	EQU	d'67'	;udp/tcp BOOTP or DHCP server
BOOTPCPort	EQU	d'68'	;udp/tcp BOOTP or DHCP client
TFTPPort	EQU	d'69'	;udp/tcp Trivial File Transfer Protocol
HTTPORT	EQU	d'80'	;udp/tcp World Wide Web HTTP
xferPort	EQU	d'82'	;udp/tcp XFER Utility
IPDATAPORT	EQU	d'87'	;udp/tcp any private terminal link
;
TTFTPtoSRAMPort	EQU	FilePort
TTFTPtoEEROMPort	EQU	TFTPPort
TCPRS232Port	EQU	TermPort
;
;PCLATH values for the diferent segments
Seg0Val	EQU	0x00
Seg1Val	EQU	0x08
Seg2Val	EQU	0x10
Seg3Val	EQU	0x18
;
;PortA bits
SystemLED	EQU	4
;
SystemLEDMask	EQU	0x10
;
;PortB bits
PORTB_Value	EQU	0x70	;init value for B
Select0	EQU	0x00	;low 8 address bits
Select1	EQU	0x01	;middle 8 address bits
Select2	EQU	0x02	;high 8 address bits
SelectSRAM	EQU	0x03	;Static Ram CS pin
SelectNIC	EQU	0x04	;NIC chip select
SelectRTC	EQU	0x05	;RTC chip select
Select6	EQU	0x06	;J2-31 Quad DAC
Select7	EQU	0x07	;J2-32 Latched Data In 2
SelectLDO0	EQU	0x08	;Latched Data Out 0
SelectLDO1	EQU	0x09	;Latched Data Out 1
SelectLDI0	EQU	0x0A	;Latched Data In 0
SelectLDI1	EQU	0x0B	;Latched Data In 1
Select12	EQU	0x0C	;J1-33
Select13	EQU	0x0D	;J1-34 Latched Data Out 2
Select14	EQU	0x0E	;Oxidider Pulse accumulator J1-35
Select15	EQU	0x0F	;Acid Pulse accumulator J1-36
SelectEnable	EQU	4	;active low enables 1 of 16 select lines
IORead	EQU	5
IOWrite	EQU	6
LCD_E	EQU	7
AddressMask	EQU	0xF0
;
;PortC bits
CCP1	EQU	2
CCP2	EQU	1
RTS	EQU	2
SCL	EQU	3
SDA	EQU	4
CTS	EQU	5
;
;PortD bits
LCD_AS	EQU	4
LCD_RW	EQU	5
;
;=======================================================================================================
;  Common Ram 70-7F same for all banks
;      except for ISR_W_Temp these are used for paramiter passing and temp vars
;=======================================================================================================
Param70	EQU	0x70
Param71	EQU	0x71
Param72	EQU	0x72
Param73	EQU	0x73
Param74	EQU	0x74
Param75	EQU	0x75
Param76	EQU	0x76	;PushParams76..7D 
Param77	EQU	0x77	;scratch pad byte
Param78	EQU	0x78	;return value & scratch pad byte
Param79	EQU	0x79	;return value & scratch pad byte
Param7A	EQU	0x7A	;return value & scratch pad byte
Param7B	EQU	0x7B
Param7C	EQU	0x7C
Param7D	EQU	0x7D
ISR_W_Temp	EQU	0x7E	;used by ISR
Param7F	EQU	0x7F	;String Ptr and W_Temp for Push/Pop
;
