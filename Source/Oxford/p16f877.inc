	LIST
; P16F877.INC  Standard Header File, Version 1.16    Microchip Technology, Inc.
	NOLIST
;
; This header file defines configurations, registers, and other useful bits of
; information for the PIC16F877 microcontroller.  These names are taken to match 
; the data sheets as closely as possible.  
;
; Note that the processor must be selected before this file is 
; included.  The processor may be selected the following ways:
;
;       1. Command line switch:
;               C:\ MPASM MYFILE.ASM /PIC16F877
;       2. LIST directive in the source file
;               LIST   P=PIC16F877
;       3. Processor Type entry in the MPASM full-screen interface
;
;==========================================================================
;
;       Revision History
;
;==========================================================================
;
;Rev:   Date:	Reason:
;
;1.16   2/15/2009	Added CCPCaptureEdgeMask
;1.15   4/5/2008	Added CaptureAllRising...
;1.14   5/13/2006	Added _GIE
;1.13   8/30/2003	DMF Added _IRP, _RP1, _RP0
;       10/4/2001	Comments added  (Dave Flynn)
;1.12   01/12/00	Changed some bit names, a register name, configuration bits
;                	to match datasheet (DS30292B)
;1.00   08/07/98	Initial Release
;
;==========================================================================
;
;       Verify Processor
;
;==========================================================================
;
	IFNDEF __16F877
	MESSG "Processor-header file mismatch.  Verify selected processor."
	ENDIF
;
;==========================================================================
;
;       Register Definitions
;
;==========================================================================
;
W	EQU	H'0000'	;used in comands like MOVF xyz,W
F	EQU	H'0001'
;
;----- Register Files------------------------------------------------------
;Bank 0
INDF	EQU	H'0000'	;indirect file register
TMR0	EQU	H'0001'	;Timer 0
PCL	EQU	H'0002'	;Low byte of PC
STATUS	EQU	H'0003'	;Status register
FSR	EQU	H'0004'	;Indirect file register pointer
PORTA	EQU	H'0005'	;I/O port A (6 bits)
PORTB	EQU	H'0006'	;I/O port B (8 bits)
PORTC	EQU	H'0007'	;I/O port C (8 bits)
PORTD	EQU	H'0008'	;I/O port D (8 bits)
PORTE	EQU	H'0009'	;I/O port E (3 bits)
PCLATH	EQU	H'000A'	;PC Latch High (5 bits)
INTCON	EQU	H'000B'	;Interupt control register
PIR1	EQU	H'000C'	;Peripheral Interupt flag Register 1
PIR2	EQU	H'000D'	;Peripheral Interupt flag Register 2
TMR1L	EQU	H'000E'	;Timer 1 low byte
TMR1H	EQU	H'000F'	;Timer 1 high byte
T1CON	EQU	H'0010'	;Timer 1 control register
TMR2	EQU	H'0011'	;Timer 2 data register
T2CON	EQU	H'0012'	;Timer 2 control register
SSPBUF	EQU	H'0013'	;Synchronous Serial Port Buffer
SSPCON	EQU	H'0014'	;Synchronous Serial Port Control Reg
CCPR1L	EQU	H'0015'	;Capture/Compare/PWM Register 1 LSB
CCPR1H	EQU	H'0016'	;Capture/Compare/PWM Register 1 MSB
CCP1CON	EQU	H'0017'	;Capture/Compare/PWM Register 1 Control Reg
RCSTA	EQU	H'0018'	;USART Receive Status and Control Reg
TXREG	EQU	H'0019'	;USART Transmit Data Reg
RCREG	EQU	H'001A'	;USART Receive Data Reg
CCPR2L	EQU	H'001B'	;Capture/Compare/PWM Register 2 LSB
CCPR2H	EQU	H'001C'	;Capture/Compare/PWM Register 2 MSB
CCP2CON	EQU	H'001D'	;Capture/Compare/PWM Register 2 Control Reg
ADRESH	EQU	H'001E'	;A/D Result Reg MSB
ADCON0	EQU	H'001F'	;A/D Control Reg 0
;
;Bank 1
OPTION_REG	EQU	H'0081'	;Option Register
TRISA	EQU	H'0085'	;Data direction register A 0=Out, 1=In
TRISB	EQU	H'0086'	;Data direction register B 0=Out, 1=In
TRISC	EQU	H'0087'	;Data direction register C 0=Out, 1=In
TRISD	EQU	H'0088'	;Data direction register D 0=Out, 1=In
TRISE	EQU	H'0089'	;Data direction register E 0=Out, 1=In
PIE1	EQU	H'008C'	;Peripheral Interupt Enable register 1
PIE2	EQU	H'008D'	;Peripheral Interupt Enable register 2
PCON	EQU	H'008E'	;Power Control flags
SSPCON2	EQU	H'0091'	;Synchronous Serial Port Control Reg 2
PR2	EQU	H'0092'	;Timer 2 Period reg
SSPADD	EQU	H'0093'	;Synchronous Serial Port (I2C mode) Address Reg
SSPSTAT	EQU	H'0094'	;Synchronous Serial Port Status Reg
TXSTA	EQU	H'0098'	;USART Tx Status and Control Reg
SPBRG	EQU	H'0099'	;Synchronous Serial Port Baud Rate Generator
ADRESL	EQU	H'009E'	;A/D Result Reg LSB
ADCON1	EQU	H'009F'	;A/D Control Reg 1
;
;Bank 2
EEDATA	EQU	H'010C'	;EEPROM data register
EEADR	EQU	H'010D'	;EEPROM address register
EEDATH	EQU	H'010E'	;program flash ram Data High bits
EEADRH	EQU	H'010F'	;program flash ram address high bits
;
;Bank 3
EECON1	EQU	H'018C'	;EEPROM control register 1
EECON2	EQU	H'018D'	;EEPROM control register 2
;
;----- STATUS Bits -Pg 18-------------------------------------------------------
;
IRP	EQU	H'0007'	;Register Bank select (used for indirect addressing)
			; 1=Bank 2,3 (100h-1FFh) (R/W-0) (aka FSR bit 8)
RP1	EQU	H'0006'	;Bank select (R/W-0)
RP0	EQU	H'0005'	;Bank select (R/W-0)
;RP1:RP0 00 = Bank 0 (00h-7Fh), 01 = Bank 1 (80h-FFh), 10 = Bank 2 (100h-17Fh), 11 = Bank 3 (180h-1FFh)
NOT_TO	EQU	H'0004'	;not Time-Out (R-1)
NOT_PD	EQU	H'0003'	;not Power-Down (R-1)
Z	EQU	H'0002'	;Zero
DC	EQU	H'0001'	;Digit Carry
C	EQU	H'0000'	;Carry/not Borrow
;
#Define	_IRP	STATUS,IRP
#Define	_RP1	STATUS,RP1
#Define	_RP0	STATUS,RP0
#Define	_C	STATUS,C
#Define	_Z	STATUS,Z
;
;----- INTCON Bits -Pg 20-------------------------------------------------------
;
GIE	EQU	H'0007'	;Global Interupt Enable
PEIE	EQU	H'0006'	;Peripheral Interupts
T0IE	EQU	H'0005'	;TMR0 overflow
INTE	EQU	H'0004'	;External Interupts
RBIE	EQU	H'0003'	;RB port change
T0IF	EQU	H'0002'	;TMR0 Interupt Flag Bit
INTF	EQU	H'0001'	;RB0 Interupt Flag Bit
RBIF	EQU	H'0000'	;RB Port Changed Flag Bit
;
#Define	_GIE	INTCON,GIE
;
;----- PIR1 Bits -Pg 22---------------------------------------------------------
;
PSPIF	EQU	H'0007'	;Parallel Slave Port R/W Interupt Flag
ADIF	EQU	H'0006'	;A/D Converter Interupt Flag
RCIF	EQU	H'0005'	;USART Receive Interupt Flag
TXIF	EQU	H'0004'	;USART Transmit Interupt Flag
SSPIF	EQU	H'0003'	;Synchronous Serial Port (SSP) Interupt Flag
CCP1IF	EQU	H'0002'	;Capture Compare Reg1 (CCP1) Interupt Flag
TMR2IF	EQU	H'0001'	;TMR2 to PR2 Match Interupt Flag
TMR1IF	EQU	H'0000'	;TMR1 overflow Interupt Flag
;
;----- PIR2 Bits -Pg 24---------------------------------------------------------
;
EEIF	EQU	H'0004'	;EEPROM Write Operation Interupt Flag
BCLIF	EQU	H'0003'	;SSP Bus Collision Interupt Flag
CCP2IF	EQU	H'0000'	;CCP2 Interupt Flag
;
;----- T1CON Bits -----Page 51----------------------------------------------------
;
T1CKPS1	EQU	H'0005'	;Timer1 Input Prescale Select bit
T1CKPS0	EQU	H'0004'	;Timer1 Input Prescale Select bit
			;T1CKPS1:T1CKPS0 00=1, 01=2, 10=4, 11=8
T1OSCEN	EQU	H'0003'	;Timer1 Oscilator Enable Control Bit
NOT_T1SYNC	EQU	H'0002'	;Timer1 External Clock Sync Bit 0=sync 1=don't sync
TMR1CS	EQU	H'0001'	;Timer1 Clock Source Select bit
TMR1ON	EQU	H'0000'	;Timer1 On Bit
;
;----- T2CON Bits -Pg 55--------------------------------------------------------
;
TOUTPS3	EQU	H'0006'	;Timer2 Output Postscale Select Bit 0000=1:1
TOUTPS2	EQU	H'0005'	;Timer2 Output Postscale Select Bit 0001=1:2
TOUTPS1	EQU	H'0004'	;Timer2 Output Postscale Select Bit 0010=1:3
TOUTPS0	EQU	H'0003'	;Timer2 Output Postscale Select Bit 1111=1:16
TMR2ON	EQU	H'0002'	;Timer2 On Bit
T2CKPS1	EQU	H'0001'	;Timer2 Prescaler Select Bit 0=see T2CKPS0, 1=16
T2CKPS0	EQU	H'0000'	;Timer2 Prescaler Select Bit 0=1, 1=4
;
;----- SSPCON Bits ----14h-----------------Page 67-----------------------------------
;
WCOL	EQU	H'0007'	;Write Collision Detect Bit
SSPOV	EQU	H'0006'	;Receive Overflow Indicator Bit
SSPEN	EQU	H'0005'	;Synchronous Serial Port Enable Bit
CKP	EQU	H'0004'	;Clock Polarity Select Bit
SSPM3	EQU	H'0003'	;Synchronous Serial Port Mode Select Bit
SSPM2	EQU	H'0002'	; see page 67
SSPM1	EQU	H'0001'
SSPM0	EQU	H'0000'
;
;----- CCP1CON Bits -Pg 58------------------------------------------------------
;
CCP1X	EQU	H'0005'	;PWM 1 Duty Cycle bit 
CCP1Y	EQU	H'0004'	;PWM 1 Duty Cycle LSB
CCP1M3	EQU	H'0003'	;CCP1 Mode Select Bit See Page 58
CCP1M2	EQU	H'0002'	;CCP1 Mode Select Bit
CCP1M1	EQU	H'0001'	;CCP1 Mode Select Bit
CCP1M0	EQU	H'0000'	;CCP1 Mode Select Bit
;
;----- RCSTA Bits --18h----Page 96---------------------------------------------------
;
SPEN	EQU	H'0007'	;Serial Port Enable Bit
RX9	EQU	H'0006'	;9-bit Receive Enable
SREN	EQU	H'0005'	;Single Receive Enable Bit
CREN	EQU	H'0004'	;Continuous Receive Enable Bit
ADDEN	EQU	H'0003'	;Address Enable Detect Bit
FERR	EQU	H'0002'	;Framing Error Bit
OERR	EQU	H'0001'	;Overrun Error Bit
RX9D	EQU	H'0000'	;9th Bit of Received Data
;
;----- CCP2CON Bits -Pg 58------------------------------------------------------
;
CCP2X	EQU	H'0005'	;PWM 2 Duty Cycle bit 
CCP2Y	EQU	H'0004'	;PWM 2 Duty Cycle LSB
CCP2M3	EQU	H'0003'	;CCP2 Mode Select Bit See Page 58
CCP2M2	EQU	H'0002'	;CCP2 Mode Select Bit
CCP2M1	EQU	H'0001'	;CCP2 Mode Select Bit
CCP2M0	EQU	H'0000'	;CCP2 Mode Select Bit
;CCPnCON values: 
CompSetOnMatch	EQU	0x08	;Compare mode, set output on match
CompClrOnMatch	EQU	0x09	;Compare mode, clr output on match
;
CaptureAllFalling	EQU	0x04	;Capture mode, every falling edge
CaptureAllRising	EQU	0x05	;Capture mode, every rising edge
CCPCaptureEdgeMask	EQU	0x01
Capture4thRising	EQU	0x05	;Capture mode, every 4th rising edge
Capture16thRising	EQU	0x05	;Capture mode, every 16th rising edge
;
;----- ADCON0 Bits ----1Fh-----Page 111-----------------------------------------------
;
ADCS1	EQU	H'0007'	;A/D Conversion Clock Select Bits
ADCS0	EQU	H'0006'
CHS2	EQU	H'0005'	;Analog Channel Select Bits
CHS1	EQU	H'0004'
CHS0	EQU	H'0003'
GO	EQU	H'0002'	;Go/*Done A/D Conversion Status
NOT_DONE	EQU	H'0002'
GO_DONE	EQU	H'0002'
ADON	EQU	H'0000'	;A/D On Bit
;
;----- OPTION_REG Bits -----------------------------------------------------
;
NOT_RBPU	EQU	H'0007'	;not Port B pull-up enable 
INTEDG	EQU	H'0006'	;Interupt Edge select bit 1=rising
T0CS	EQU	H'0005'	;TMR0 clock source 1=RA4,0=CLKOUT
T0SE	EQU	H'0004'	;TMR0 source edge 0=rising
PSA	EQU	H'0003'	;Prescaler assignment 0=TMR0
PS2	EQU	H'0002'	;Prescaler bit 2 see page 19
PS1	EQU	H'0001'	;Prescaler bit 1
PS0	EQU	H'0000'	;Prescaler bit 0
;
;----- TRISE Bits ---------------------------------------------------------
;
IBF	EQU	H'0007'	;Input Buffer Full Status Bit
OBF	EQU	H'0006'	;Output Buffer Full Status Bit
IBOV	EQU	H'0005'	;Input Buffer Overflow Detect Bit
PSPMODE	EQU	H'0004'	;Parallel Slave Port Mode Select Bit
TRISE2	EQU	H'0002'	;Data Direction Control (PORTE:2) 1=In, 0=Out
TRISE1	EQU	H'0001'	;Data Direction Control (PORTE:1) 1=In, 0=Out
TRISE0	EQU	H'0000'	;Data Direction Control (PORTE:0) 1=In, 0=Out
;
;----- PIE1 Bits ----------------------------------------------------------
;
PSPIE	EQU	H'0007'	;Parallel Slave Port Interupt Enable
ADIE	EQU	H'0006'	;A/D Converter Interupt Enable
RCIE	EQU	H'0005'	;USART Receive Interupt Enable
TXIE	EQU	H'0004'	;USART Transmit Interupt Enable
SSPIE	EQU	H'0003'	;Synchronous Serial Port (SSP) Interupt Enable
CCP1IE	EQU	H'0002'	;Capture Compare Reg1 (CCP1) Interupt Enable
TMR2IE	EQU	H'0001'	;TMR2 to PR2 Match Interupt Enable
TMR1IE	EQU	H'0000'	;TMR1 Overflow Interupt Enable
;
;----- PIE2 Bits ----------------------------------------------------------
;
EEIE	EQU	H'0004'	;EEPROM Write Operation Interupt Enable
BCLIE	EQU	H'0003'	;SSP Bus Collision Interupt Enable
CCP2IE	EQU	H'0000'	;CCP2 Interupt Enable
;
;----- PCON Bits ----------------------------------------------------------
;
NOT_POR	EQU	H'0001'	;Power-on Reset Status Bit
NOT_BOR	EQU	H'0000'	;Brown-out Reset Status Bit
;
;----- SSPCON2 Bits ----91h-----Page 68-----------------------------------------------
;
GCEN	EQU	H'0007'	;General Call Enable Bit (i2c slave mode only)
ACKSTAT	EQU	H'0006'	;Acknowledge Status Bit (i2c master mode only)
ACKDT	EQU	H'0005'	;Acknowledge Data Bit (i2c master mode only)
ACKEN	EQU	H'0004'	;Acknowledge Sequence Enable Bit (i2c master mode only)
RCEN	EQU	H'0003'	;Receive Enable Bit (i2c master mode only)
PEN	EQU	H'0002'	;Stop Condition Enable Bit (i2c master mode only)
RSEN	EQU	H'0001'   	;Repeated Start Condition Enable Bit (i2c master mode only)
SEN	EQU	H'0000'	;Start Condition Enable Bit (i2c master mode only)
;
;----- SSPSTAT 94h Bits ------Page 66--------------------------------------------
;
SMP	EQU	H'0007'	;Sample Bit
CKE	EQU	H'0006'	;Clock Edge Select
D	EQU	H'0005'	;Data/*Address Bit (i2c mode only)
I2C_DATA	EQU	H'0005'
NOT_A	EQU	H'0005'
NOT_ADDRESS	EQU	H'0005'
D_A	EQU	H'0005'
DATA_ADDRESS	EQU	H'0005'
P	EQU	H'0004'	;Stop Bit (i2c mode only)
I2C_STOP	EQU	H'0004'
S	EQU	H'0003'	;Start Bit (i2c mode only)
I2C_START	EQU	H'0003'
R	EQU	H'0002'	;R/W Bit Info (i2c mode only)
I2C_READ	EQU	H'0002'
NOT_W	EQU	H'0002'
NOT_WRITE	EQU	H'0002'
R_W	EQU	H'0002'
READ_WRITE	EQU	H'0002'
UA	EQU	H'0001'	;Update Address (10 bit i2c mode only) 
BF	EQU	H'0000'	;Buffer Full Status Bit
;
;----- TXSTA Bits ---98h----Page 95--------------------------------------------------
;
CSRC	EQU	H'0007'	;Clock Source Select Bit
TX9	EQU	H'0006'	;9-Bit Transmit Enable Bit
TXEN	EQU	H'0005'	;Transmit Enable Bit
SYNC	EQU	H'0004'	;USART Mode Select Bit
BRGH	EQU	H'0002'	;High Baud Rate Select Bit 0=low speed
TRMT	EQU	H'0001'	;Transmit Shift Reg Status Bit
TX9D	EQU	H'0000'	;9th Bit of Transmit Data, can be parity bit
;
;----- ADCON1 Bits --9Fh----Page 112--------------------------------------------------
;
ADFM	EQU	H'0007'	;A/D Result Format Select Bit
PCFG3	EQU	H'0003'	;A/D Port Configuration Bits
PCFG2	EQU	H'0002'	; see page 112
PCFG1	EQU	H'0001'
PCFG0	EQU	H'0000'
;
;----- EECON1 Bits --------------------------------------------------------
;
EEPGD	EQU	H'0007'	;Program/Data Select 0=Data
WRERR	EQU	H'0003'	;Error Flag Bit 0=OK
WREN	EQU	H'0002'	;Write Enable 1=allow writes
WR	EQU	H'0001'	;Write control bit
RD	EQU	H'0000'	;Read control bit
;
;==========================================================================
;
;       RAM Definition
;
;==========================================================================
;
        __MAXRAM H'1FF'
        __BADRAM H'8F'-H'90', H'95'-H'97', H'9A'-H'9D'
        __BADRAM H'105', H'107'-H'109'
        __BADRAM H'185', H'187'-H'189', H'18E'-H'18F'
;
;==========================================================================
;
;       Configuration Bits
;
;==========================================================================
;
_CP_ALL                      EQU     H'0FCF'	;Code Protection Flash 0x0000..0x1fff
_CP_HALF                     EQU     H'1FDF'	;0x1000..0x1fff
_CP_UPPER_256                EQU     H'2FEF'	;0x1f00..0x1fff
_CP_OFF                      EQU     H'3FFF'	;none
_DEBUG_ON                    EQU     H'37FF'	;in-circuit debugger mode
_DEBUG_OFF                   EQU     H'3FFF'
_WRT_ENABLE_ON               EQU     H'3FFF'	;enable write to flash
_WRT_ENABLE_OFF              EQU     H'3DFF'
_CPD_ON                      EQU     H'3EFF'	;code protect EEPROM
_CPD_OFF                     EQU     H'3FFF'
_LVP_ON                      EQU     H'3FFF'	;enable low voltage programming
_LVP_OFF                     EQU     H'3F7F'
_BODEN_ON                    EQU     H'3FFF'	;enable brown-out detect reset
_BODEN_OFF                   EQU     H'3FBF'
_PWRTE_OFF                   EQU     H'3FFF'	;Power-Up timer 72ms
_PWRTE_ON                    EQU     H'3FF7'
_WDT_ON                      EQU     H'3FFF'	;Watch Dog Timer
_WDT_OFF                     EQU     H'3FFB'
_LP_OSC                      EQU     H'3FFC'	;Low Power crystal
_XT_OSC                      EQU     H'3FFD'	;Crystal/Resinator
_HS_OSC                      EQU     H'3FFE'	;High Speed crystal/resinator
_RC_OSC                      EQU     H'3FFF'	;Resistor/Capacitor
;
        LIST
;
