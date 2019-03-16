\**************************
\** RetroClinic - RamFS  **
\** (c)2009 Mark Haysman **
\**************************


lastDrv		= &CF				;Last drive accessed

vdip		= &FCF8
vdipS		= &FCF9
pageL		= &FCFF
pageH		= &FCFE

\ Other Vectors

osfcv		= &021E				;The filing control vector
gsinit		= &FFC2
gsread		= &FFC5
osfind		= &FFCE				;open/close file
osbput		= &FFD4
osbget		= &FFD7
osargs		= &FFDA
osfile		= &FFDD
osrdch		= &FFE0
osasci		= &FFE3
osword		= &FFF1
osbyte		= &FFF4
oscli		= &FFF7

\ Variables

ramFSID		= 12				;Filing System number of RAM Filing System using JIM.
diskFSID	= 4				;Filing system number of Disk System
chanBASE	= 96				;Channel Base

zpm0		= &F8				;Zero Page Workspace variable, can be moved if necessary
zpm1		= &F9
zpm2		= &B6
zpm3		= &B7
zpm4		= &B8
zpm5		= &B9
zpm6		= &BA
zpm7		= &BB


ORG &8000

\
\
\************************************************
\** Main Service Entry
\
.ROMstart	BRK
		BRK
		BRK
		JMP service01
		EQUB	&82
		EQUB	LO(cpyMsg)
		EQUB	&10			;Version number
		EQUS	"RamFS"
		BRK
		EQUS	"1.00 (03 Aug 2009)"
.cpyMsg		BRK
		EQUS	"(C)RetroClinic"
		BRK
		EQUS	"With thanks for additional code to J.G.Harston"
		BRK

.jump_osfcv	JMP (osfcv)

.errDisk	JSR errARG
		BRK
		EQUS	"Disk "
		BCC errNoARG
		
.errBad		JSR errARG
		BRK
		EQUS	"Bad "
		BCC errNoARG

.errFile	JSR errARG
		BRK
		EQUS	"File "
		BCC errNoARG
\
\
\************************************************
\** Print Error Routine with argument = error number
\		
.errARG		LDX #&02
		LDA #&00
		STA &0100

.errNoARG	STA &B3				;Entry point with no argument
		PLA
		STA &AE
		PLA
		STA &AF
		LDA &B3
		LDY #&00
		JSR mIncAE			;16 bit Increment to &AE
		LDA (&AE),Y
		STA &0101
		DEX

.loop_8054	JSR mIncAE			;16 bit Increment to &AE
		INX
		LDA (&AE),Y
		STA &0100,X
		BMI prtRTS
		BNE loop_8054
		JMP &0100
\
\
\************************************************
\ ** Print String Routine
\
.prtStr		STA &B3				;Store old value of A
		PLA
		STA &AE				;Place next address from JSR in (&AE)
		PLA
		STA &AF
		LDA &B3				;Reload A and store it
		PHA
		TYA
		PHA				;Save Y too
		LDY #&00

.loop_8073	JSR mIncAE			;16 bit Increment to &AE
		LDA (&AE),Y			;Load character at (&AE)
		BMI jump_8080			;if it's >&7F then jump
		JSR prtChrA			;Print single character
		JMP loop_8073			;Loop back

.jump_8080	PLA				;Restore old values of A and Y
		TAY
		PLA

.prtRTS		CLC				;Clear carry to show complete
		JMP (&00AE)			;Jump back to next command after string
\
\
\************************************************
\** Print a full stop
\
.prtChr2E	LDA #&2E
\
\
\************************************************
\** Print Single Character
\
.prtChrA	JSR saveAXY			;Save AXY
		PHA
		JSR osbyte_EC			;*FX236 Read character destination status
		TXA
		PHA
		ORA #&10			;Disable spooled output
		JSR osbyte_03X			;*FX 3 - Write output stream, with A=stream destination
		PLA
		TAX
		PLA
		JSR osasci			;Write character
		JMP osbyte_03			;Restore old output stream and return
\
\
\************************************************
\** Print A as 2 digit Hex number
\
.prtHexA8bit	PHA				;Save A
		JSR mLSR4			;Move top nibble to lower 4 bits
		JSR prtHexA4bit			;Print hex digit
		PLA				;Recall A
\
\
\************************************************
\** Print lower 4 bits of A as Hex number
\
.prtHexA4bit	PHA
		AND #&0F
		CMP #&0A
		BCC jump_80B1
		ADC #&06

.jump_80B1	ADC #&30
		JSR prtChrA
		PLA
		RTS
\
\
\
.x80B8		JSR x80C8
		DEX
		DEX
		JSR x80C0

.x80C0		LDA (&B0),Y
		JSR set10
		STA &FD72,X
		INX
		INY
		RTS

.x80C8		JSR x80CB

.x80CB		LDA (&B0),Y
		STA &BC,X
		INX
		INY
		RTS
\
\
\***********************************************
\** Decimal Printing routines - by JGH
\
\** On entry, Scratchram &FDA0-&FDA3 = number to print
\** &FDA4 = Character to pad with or zero for no padding
\** &FD70-&FD73 = subtraction workspace
\

.PrDec24	JSR setSCR
		LDA #&00
		STA &FDA3
		JMP PrDec24a
		
.PrDec24_5	JSR setSCR
		LDA #&00
		STA &FDA3
		JMP PrDec24a5
		
.PrDec16	JSR setSCR
		LDA #&00
		STA &FDA3
		STA &FDA2
		JMP PrDec16a
		
.PrDec8		JSR setSCR
		LDA #&00
		STA &FDA3
		STA &FDA2
		STA &FDA1
		JMP PrDec8a
		
.PrDec8_2	JSR setSCR
		LDA #&00
		STA &FDA3
		STA &FDA2
		STA &FDA1
		JMP PrDec8a2
		
.PrDec24a5	JSR setSCR
		LDA #&00
		STA &FD73			;sub+3 - Subtractant is &00aayyxx
		LDA #&01
		LDY #&86
		LDX #&A0
		JSR PrDecDigit			;100,000s
		JMP PrDec16a

.PrDec32	JSR setSCR
		LDX #&3B
		LDA #&9A
		LDY #&CA
		JSR PrDecDigit32		;1,000,000,000s
		LDX #&05
		LDA #&F5
		LDY #&E1
		JSR PrDecDigit32		;100,000,000s
		
.PrDec24a	JSR setSCR
		LDA #&00
		STA &FD73			;sub+3 - Subtractant is &00aayyxx
		LDA #&98
		LDY #&96
		LDX #&80
		JSR PrDecDigit			;10,000,000s
		LDA #&0F
		LDY #&42
		LDX #&40
		JSR PrDecDigit			;1,000,000s
		LDA #&01
		LDY #&86
		LDX #&A0
		JSR PrDecDigit			;100,000s

.PrDec16a	JSR setSCR
		LDA #&00
		STA &FD73			;sub+3 - Subtractant is &00aayyxx
		LDY #&27
		LDX #&10
		JSR PrDecDigit16		;10,000s
		LDY #&03
		LDX #&E8
		JSR PrDecDigit16		;1000s
		LDA &FDA4
		CMP #&20
		BEQ PrDec8x
		CLC
		SBC #&10
		CMP #&20
		BEQ PrDec8x
		LDA #&2C
		
.PrDec8x	JSR prtChrA

.PrDec8a	JSR setSCR
		LDA #&00
		STA &FD73			;sub+3 - Subtractant is &00aayyxx
		LDX #&64
		JSR PrDecDigit8			;100s
.PrDec8aJ	LDX #&0A
		JSR PrDecDigit8			;10s
		LDA &FDA0			;num+0
		BPL PrDecPrint			;1s
		
.PrDec8a2	JSR setSCR
		LDA #&00
		STA &FD73			;sub+3 - Subtractant is &00aayyxx
		BEQ PrDec8aJ
\
\** Main Routines
\
.PrDecDigit32	STX &FD73			;sub+3
		LDX #&00
		BEQ PrDecDigit
		
.PrDecDigit8    LDY #&00			;Use &0000xx

.PrDecDigit16	LDA #&00			;Use &00yyxx

.PrDecDigit	STX &FD70			;sub+0
		STY &FD71			;sub+1
		STA &FD72			;sub+2 - Set up subtractant
		LDX #&FF			;Initialise digit counter

.PrDecLp	SEC
		LDY #&00
		PHP				;Prepare for 4-byte subtraction

.PrDecSubLp	PLP
		LDA &FDA0,Y			;num,Y
		SBC &FD70,Y			;sub,Y
		STA &FDA0,Y			;num,Y - Subtract byte at Y
		PHP
		INY
		CPY #&04
		BNE PrDecSubLp			;Step through 4 bytes
		PLP
		INX
		BCS PrDecLp			;Loop until subtracted too much
		LDY #&00
		PHP

.PrDecAddLp	PLP
		LDA &FDA0,Y			;num,Y
		ADC &FD70,Y			;sub,Y
		STA &FDA0,Y			;num,Y - Add final subtraction back
		PHP
		INY
		CPY #&04
		BNE PrDecAddLp
		PLP
		TXA
		BNE PrDecPrint			;If not zero, print it
		LDA &FDA4			;pad
		BEQ PrDecZero			;Exit if pad is null
		CMP #&20
		BEQ PrSpace
		
.PrDecPrint	ORA #&30
		JSR prtChrA			;OSWRCH - Print this digit
		LDA #&30
		STA &FDA4			;pad - Set pad to '0' for other digits
		
.PrDecZero	RTS

.PrSpace	JMP prtChrA
\
\
\************************************************
\** Fill &C7-&CB with spaces - Immediate DIR, Volume, Drive and open file buffer
\
.fillC7CB	LDA #&20
		LDX #&06

.loop_80D6	STA &C7,X
		DEX
		BPL loop_80D6

.x80DB		RTS
\
\
\************************************************
\** Process filename without resetting GSREAD
\
.procFNameR	JSR setDirDrv			;Set up Drive and Directories, checks for FDC Idle
		JSR fillC7CB			;Fill &C7-&CB with spaces - Immediate DIR, Volume, Drive and open file buffer
		BMI x80F7			;Always jump
\
\
\************************************************
\** Filename Processing
\
.procFName	JSR setDirDrv			;Set up Drive and Directories, checks for FDC Idle

.x80E7		JSR fillC7CB			;Fill &C7-&CB with spaces - Immediate DIR, Volume, Drive and open file buffer
		LDA &BC				;Transfer address of filename to GSINIT
		STA &F2
		LDA &BD
		STA &F3
		LDY #&00			;Offset 0
		JSR gsinitCLC			;JSR gsinit with CLC

.x80F7		LDX #&01

.x80F9		JSR gsread			;Call GSREAD
		BCC x80F9a			;BCS x80DB			;Return if end of string is reached
		JMP procFNameX
		
.x80F9a		STA &C7				;Store result at &C7
		CMP #&2E			;Is it a "."?
		BNE x8108			;If not then jump
		LDA #&20
		BNE x8155

.x8108		CMP #&3A			;Is it a ":"?
		BNE x812D			;If not then jump
		JSR gsread			;If so, then get the next character in the string
		BCS errBadDrvA			;If end of string, jump to "Bad Drive" error
		SEC
		SBC #&30
		BCC errBadDrvA			;If less than "0" jump to "Bad Drive" error
		CMP #&06			;
		BCS errBadDrvA			;If greater than "6" jump to "Bad Drive" error
		JSR setDrvCF			;CLI and check drive idle, validate drive number AND#03, and store it at &CF
		JSR gsread			;Get next character
		BCS procFNameX			;x817E			;Jump to return if end of string
		CMP #&2E			;Is this character a "."?
		BEQ x8129			;If so, then it's ok, jump

.errBadDrvA	JMP errBadDrv			;Jump to "Bad Drive" error

.x8129		LDA #&24			;A="$"
		BNE x8155

.x812D		CMP #&2A			;Is character a "*"?
		BNE x814A			;If not then jump
		JSR gsread			;Get next character
		BCS x813E			;Jump if end of string
		CMP #&2E			;Is it a "."?
		BNE x816C			;Jump if so to "Bad Filename" error
		LDA #&23			;A="#"
		BNE x8155

.x813E		LDX #&00

.x8140		LDA #&23			;A="#"

.x8142		STA &C7,X
		INX
		CPX #&07
		BNE x8142
		JMP procFNameX			;RTS

.x814A		JSR gsread			;Get next character
		BCS procFNameX			;x817E			;Exit if end of string
		CMP #&2E			;Is it a "."?
		BNE x8163			;If not, then jump
		LDA &C7				;Load immediate DIR

.x8155		STA &CE
		JMP x80F9

.x815A		JSR gsread			;Get next character
		BCS procFNameX			;x817E			;Exit if end of string
		CPX #&07			;Have we exceeded max filename size?
		BEQ x816C			;If so, jump to "Bad Filename" error

.x8163		CMP #&2A			;Is it a "*"?
		BNE x8179			;Jump if not
		JSR gsread
		BCS x8140			;Jump if end of string reached

.x816C		JSR errBad			;Error - "Bad Filename"
		EQUB	&CC
		EQUS	"name"
		BRK

.x8179		STA &C7,X
		INX
		BNE x815A			;Always jump back to x815A

.procFNameX	LDA &C7
		CMP #&20
		BEQ x816C
		RTS
\
\
\************************************************
\** Print Filename at offset=Y
\
.prtFileName	JSR saveAXY
		JSR set0E
		LDA &FD0F,Y
		PHP
		AND #&7F
		BNE x818F
		JSR prtChr20x2
		BEQ x8195

.x818F		JSR prtChrA
		JSR prtChr2E

.x8195		LDX #&06

.x8197		LDA &FD08,Y
		AND #&7F
		JSR prtChrA
		INY
		DEX
		BPL x8197
		JSR prtChr20x2
		LDA #&20
		PLP
		BPL x81AD
		LDA #&4C

.x81AD		JSR prtChrA
		JMP prtChr20
\
\
\************************************************
\** Print number of spaces in the Y register
\
.prtChr20xY	JSR prtChr20
		DEY
		BNE prtChr20xY
		RTS
\
\
\************************************************
\** Math Routines
\
.mLSR6_AND3	LSR A				;LSR A * 6, then AND &03
		LSR A

.mLSR4_AND3	LSR A				;LSR A * 4, then AND &03
		LSR A

.mLSR2_AND3	LSR A				;LSR A * 2, then AND &03
		LSR A
		AND #&03
		RTS

.mLSR5		LSR A				;LSR A * 5

.mLSR4		LSR A				;LSR A * 4

.mLSR3		LSR A
		LSR A
		LSR A
		RTS

.mASL5		ASL A				;ASL A * 5

.mASL4		ASL A				;ASL A * 4
.mASL3		ASL A				;ASL A * 3
		
.mASL2		ASL A				;ASL A * 2
		ASL A
		RTS

.mINY8		INY				;INY x 8

.mINY7		INY				;INY x 7
		INY
		INY

.mINY4		INY				;INY x 4
		INY
		INY
		INY
		RTS

.mDEY8		DEY				;DEY x 8
		DEY
		DEY
		DEY
		
.mDEY4		DEY
		DEY
		DEY
		DEY
		RTS
\
\
\************************************************
\** ????
\
.blockYvars	LDA &BE
		STA &A6
		LDA &BF
		STA &A7
		LDA #&FF
		STA &BA
		LDX &C3
		INX
		STX &A4
		LDA &C4
		JSR mLSR4_AND3			;LSR A * 4, then AND &03
		STA &A5
		INC &A5
		LDA &C2
		STA &A3
		BNE x8207
		DEC &A4
		BNE x8207
		DEC &A5

.x8207		LDA &C4
		AND #&03
		TAX
		LDA &C5

.x820E 		SEC

.x820F		INC &BA
		SBC #&0A
		BCS x820F
		DEX
		BPL x820E
		ADC #&0A
		STA &BB

.x821C		RTS
\
\
\
.sta23_10CF	LDA #&23
		BNE x8223

.staFF_10CF	LDA #&FF

.x8223		JSR set10
		STA &FDCF
		RTS
\
\
\
.x8227_5	JSR procFNameR
		JSR chkDrv5
		JMP getCatFirstE
\
\
\
.x8227		JSR procFNameR			;Process filename without resetting GSREAD
		JMP getCatFirstE
\
\
\
.x822D		JSR procFName			;Read Filename, drive and directory from Paramter block
		LDA &CF
		CMP #&05			;If drive is USB, then skip file processing for now
		BEQ x821C
\
\
\************************************************
\** Check first filename in catalog, and error if not present
\
.getCatFirstE	JSR getCatFirst			;Get first entry in catalog that matches, C=1=found,Y=offset
		BCS x821C

.x8235		JSR errFile			;Error - "File not found"
		EQUB	&D6
		EQUS	"not found"
		BRK
\
\
\************************************************
\** *INFO command
\
.cmdInfo	JSR sta23_10CF			;?&10CF=&23
		JSR getNextArg			;Get next argument from command line
		JSR x8227_5

.x824C		JSR prtFNattr			;Print Filename and attributes
		JSR getCatNext			;Get next entry in catalog that matches, C=1=found,Y=offset
		BCS x824C
		RTS
\
\
\************************************************
\** *EX command
\
.cmdEX		JSR sta23_10CF			;?&10CF=&23
		LDY #&02
		LDA (&F2),Y
		CMP #&0D			;Check to see if cmd has no arguments
		BNE cmdEX_1
		INY				;if not, put a <CR> in the first place the new cmd line will be
		STA (&F2),Y		
		
.cmdEX_1	LDA #&03
		CLC
		ADC &F2				;Bump &F2 up by 3, to give the same details as the Master would pass
		STA &F2
		LDA #&00
		ADC &F3
		STA &F3
		LDY #&00
		JMP osfsc9_J0
\
\
\************************************************
\** *EX Support for MOS 3.20+
\
.osfsc_09	JSR storeXY_F2			;STX &F2
						;STY &F3
						;LDY #&00
.osfsc9_J0	JSR setSCR
		
.osfsc9_L1	LDA (&F2),Y
		STA &FD00,Y
		INY
		CPY #&05
		BNE osfsc9_L1
		
.osfsc9_J1	LDY #&00

.osfsc9_L2	LDA infoStr,Y
		STA (&F2),Y
		INY
		CMP #&0D
		BNE osfsc9_L2
		JSR set10
		LDA &FDCB
		CLC
		ADC #&30
		LDY #&03
		STA (&F2),Y			;Replace current Drive
		LDA &FDCA
		INY
		INY
		STA (&F2),Y			;And directory with deafults
		JSR setSCR
		LDA &FD00
		CMP #&3A			;Is first character a ":"?
		BEQ osfsc9_J9			;If so, then copy all the argument
		CMP #&0D			;Is it a <CR>?
		BEQ osfsc9_ex			;If so, then no more needed
		LDY #&05
		STA (&F2),Y			;Otherwise, store it at the $ point
		JMP osfsc9_ex
		
.osfsc9_J9	LDY #&00

.osfsc9_L9	LDA &FD00,Y
		CMP #&0D
		BEQ osfsc9_ex
		INY
		INY
		STA (&F2),Y
		DEY
		BNE osfsc9_L9		
		
.osfsc9_ex	LDY #&00
		JMP cmdInfo
		
.infoStr	EQUS	"I.:0.$.*"
		EQUB	&0D
\
\
\************************************************
\** INFO Support for MOS 3.20+
\
.osfsc_0A	JSR storeXY_F2			;STX &F2				;Store pointer
						;STY &F3
						;LDY #&00
		JMP cmdInfo			;And process as normal
\
\
\************************************************
\** Catalog filemane processing
\
.getCatFirst	JSR loadCAT			;Load the catalog
		LDY #&F8			;Prepare Y register for 0 after first INYs
		BNE x825F			;Always jump to x825F

.getCatNext	JSR set10
		LDY &FDCE

.x825F		JSR mINY8			;INY x 8
		JSR set0F
		CPY &FD05			;Compare with number of files on disk (contents is x8)
		BCS x82AB			;If reached then exit with carry clear
		JSR mINY8			;INY x 8
		LDX #&07

.x826C		LDA &C7,X
		JSR set10
		CMP &FDCF
		BEQ x8281
		JSR chkAlphaChar
		JSR set0E
		EOR &FD07,Y
		BCS x827D
		AND #&DF			;Ignore character case

.x827D		AND #&7F			;Clear bit 7
		BNE x828A

.x8281		DEY
		DEX
		BPL x826C
		JSR set10
		STY &FDCE
		SEC
		RTS

.x828A		DEY
		DEX
		BPL x828A
		BMI x825F
\
\
\************************************************
\** Delete filename from catalog
\
.deleteCatFN	JSR x9833			;Check file not open

.delCFN1	JSR set0E
		LDA &FD10,Y
		STA &FD08,Y
		JSR set0FS
		LDA &FD10,Y
		STA &FD08,Y
		INY
		CPY &FD05
		BCC delCFN1
		TYA
		SBC #&08
		STA &FD05

.x82AB		CLC

.x82AC		RTS
\
\
\************************************************
\** Check for Alphanumeric Character in A
\
.chkAlphaChar	PHA
		AND #&DF
		CMP #&41
		BCC x82B8
		CMP #&5B
		BCC x82B9

.x82B8		SEC

.x82B9		PLA
		RTS
\
\
\
.x82BB		JSR set10
		BIT &FDC7
		BMI x82AC
\
\
\************************************************
\** Print Filename and attributes
\
.prtFNattr	JSR saveAXY
		JSR prtFileName			;Print Filename at offset=Y
		TYA
		PHA
		LDA #&60
		STA &B0
		LDA #&10
		STA &B1
		JSR readFileAttr		;Read file attributes
		LDY #&02
		JSR prtChr20
		JSR x82F4
		JSR x82F4
		JSR x82F4
		PLA
		TAY
		JSR set0F
		LDA &FD0E,Y
		AND #&03
		JSR prtHexA4bit
		LDA &FD0F,Y
		JSR prtHexA8bit
		JMP prtChr0D

.x82F4		LDX #&03

.x82F6		JSR set10
		LDA &FD62,Y
		JSR prtHexA8bit
		DEY
		DEX
		BNE x82F6
		JSR mINY7			;INY x 7
		JMP prtChr20
\
\
\************************************************
\** *DRIVE command
\
.cmdDrive	JSR getNextArg			;Get next argument from command line
		JSR getDrv
		JSR set10
		STA &FDCB			;Save to the Current Drive

.setDrvCF	AND #&07			;Drop bit b3, which gets set by ADFS
		CMP #&06
		BCS errBadDrv			;Ensure Drive is in range 0-5
		STA &CF
		RTS
\
\
\************************************************
\** Setup Default Directory
\
.setDirDrv	JSR set10
		LDA &FDCA			;Current Default Directory
		STA &CE				;Store it at &CE
\
\
\************************************************
\** Setup Default Drive
\
.setDrv		JSR set10
		LDA &FDCB			;Load the current Default Drive
		JMP setDrvCF			;CLI and check drive idle, validate drive number AND#07, and store it at &CF
\
\
\************************************************
\** Jump to gsinit with the carry flag clear
\
.gsinitCLC	CLC
		JMP gsinit
\
\
\************************************************
\** Setup Default Drive with a CLC call to gsinit
\
.gsinitCLC_D	JSR gsinitCLC			;JSR gsinit with CLC
		BEQ setDrv			;jump to setup default drive
\
\
\************************************************
\** Get Drive number from input buffer and validate, then store in &CF
\
.getDrv		JSR gsread
		BCS errBadDrv
		CMP #&3A
		BEQ getDrv
		SEC
		SBC #&30
		BCC errBadDrv
		JSR setDrvCF			;CLI and check drive idle, validate drive number AND#07, and store it at &CF
		CLC
		RTS

.errBadDrv	JSR errBad			;Error - "Bad drive"
		EQUB	&CD
		EQUS	"drive"
		BRK
\
\
\************************************************
\** Check for Drive n range 0-4, IE USB not permitted
\
.chkDrv5	PHA
		LDA &CF
		AND #&07
		CMP #&05
		BCS errBadDrv
		PLA
		RTS
		
.chkDrv5A	AND #&07			;This routine checks drive number in A
		CMP #&05			;And returns an error if not in range 0-4
		BCS errBadDrv
		RTS
		
.chkDrv4A	AND #&07			;This routine checks drive number in A
		CMP #&04			;And returns an error if not in range 0-3
		BCS errBadDrv
		RTS
\
\
\************************************************
\** Read file attributes
\
.readFileAttr	JSR saveAXY
		TYA
		PHA
		TAX
		LDA &B1
		CMP #&10
		BNE rfa_J1
		LDA #&FD
		STA &B1
		
.rfa_J1		LDY #&02
		LDA #&00

.x8347		JSR set10
		STA (&B0),Y
		INY
		CPY #&12
		BNE x8347
		LDY #&02

.x8350		JSR x838E
		INY
		INY
		CPY #&0E
		BNE x8350
		PLA
		TAX
		JSR set0E
		LDA &FD0F,X
		BPL x8366
		LDA #&0A
		LDY #&0E
		JSR set10
		STA (&B0),Y

.x8366		JSR set0F
		LDA &FD0E,X
		LDY #&04
		JSR x837A
		LDY #&0C
		LSR A
		LSR A
		PHA
		AND #&03
		JSR set10
		STA (&B0),Y
		PLA
		LDY #&08

.x837A		LSR A
		LSR A
		PHA
		AND #&03
		JSR set10
		STA (&B0),Y
		CMP #&03
		BNE x838C
		LDA #&FF
		STA (&B0),Y
		INY
		STA (&B0),Y

.x838C		PLA
		RTS

.x838E		JSR x8391

.x8391		JSR set0F
		LDA &FD08,X
		JSR set10S
		STA (&B0),Y
		INX
		INY
		RTS
\
\
\************************************************
\** 16 bit Increment to &AE
\
.mIncAE		INC &AE
		BNE x839F
		INC &AF

.x839F		RTS

\
\
\************************************************
\** Save AXY Routine
\
.saveAXY	PHA
		TXA
		PHA
		TYA
		PHA
		LDA #HI(x83C3-1)
		PHA
		LDA #LO(x83C3-1)
		PHA

.x83AB		LDY #&05

.x83AD		TSX
		LDA &0107,X
		PHA
		DEY
		BNE x83AD
		LDY #&0A

.x83B7		LDA &0109,X
		STA &010B,X
		DEX
		DEY
		BNE x83B7
		PLA
		PLA

.x83C3		PLA
		TAY
		PLA
		TAX
		PLA
		RTS

.x83C9		TSX
		STA &0103,X
		JMP x83C3

.x83D0		PHA
		TXA
		PHA
		TYA
		PHA
		LDA #HI(x83C9-1)
		PHA
		LDA #LO(x83C9-1)
		PHA
		BNE x83AB
\
\
\************************************************
\** OSFSC &05 - *CAT
\
.osfsc_05	JSR storeXY_F2			;Save X and Y at &F2 and &F3
		JSR setDirDrv			;Set up Drive and Directories
		JSR gsinitCLC_D			;Setup Default Drive with a CLC call to gsinit
		LDA &CF
		CMP #&05
		BNE catJ1
		JMP catUSB
		
.catJ1		JSR loadCAT
		LDY #&FF
		STY &A8
		INY
		STY &AA
		
.x83EA		JSR set0E
		LDA &FD00,Y
		CPY #&08
		BCC x83F4
		JSR set0F
		LDA &FCF8,Y

.x83F4		JSR prtChrA
		INY
		CPY #&0C
		BNE x83EA
		JSR prtStr
		EQUS	" ("
		LDA &FD04			;Load Disk Cycle number
		JSR prtHexA8bit			;Print Hex Number in A
		JSR prtStr
		EQUS	") "
		NOP
		LDA &CF
		AND #&04
		BEQ notNV			;If It's Drive 4, then add an NV to the RAM
		JSR prtStr
		EQUS	"NV"
		NOP

.notNV		JSR prtStr
		EQUS	"RAM"
		EQUB	&0D
		EQUS	"Drive "
		LDA &CF				;Load Drive Number
		JSR prtHexA4bit			;Print Single Digit
		LDY #&0D
		JSR prtChr20xY			;Print number of Spaces in Y reg
		JSR prtStr
		EQUS	"Option "
		LDA &FD06
		JSR mLSR4			;LSR A * 4
		JSR prtHexA4bit			;Print lower 4 bits
		JSR prtStr
		EQUS	" ("
		LDY #&03
		ASL A
		ASL A
		TAX

.x8439		LDA x852E,X			;Print option from table
		JSR prtChrA
		INX
		DEY
		BPL x8439
		JSR prtStr
		EQUS	")"
		EQUB	&0D
		EQUS	"Directory :"
		NOP
		JSR set10
		LDA &FDCB			;Load the current default drive
		JSR prtHexA4bit
		JSR prtChr2E
		LDA &FDCA			;Current Default Directory
		JSR prtChrA
		LDY #&06
		JSR prtChr20xY			;Print number of spaces in Y reg
		JSR prtStr
		EQUS	"Library :"
		LDA &FDCD
		JSR prtHexA4bit
		JSR prtChr2E
		LDA &FDCC
		JSR prtChrA
		JSR prtChr0D			;Print a Carriage Reuturn
		LDY #&00

.x8487		JSR set0FS
		CPY &FD05			;Compare with number of files on disk
		BCS x84A3			;If past it then jump out
		JSR set0ES
		LDA &FD0F,Y
		JSR set10S
		EOR &FDCA			;Compare with Default Directory
		AND #&7F
		BNE x849E

.x8496		JSR set0ES
		LDA &FD0F,Y
		AND #&80
		STA &FD0F,Y

.x849E		JSR mINY8			;INY x 8
		BCC x8487

.x84A3		LDY #&00
		JSR x84B5
		BCC x84C0
		LDA #&FF
		JSR set10
		STA &FD82
		JMP prtChr0D

.x84B2		JSR mINY8			;INY x 8

.x84B5		JSR set0FS
		CPY &FD05
		BCS x84BF
		JSR set0ES
		LDA &FD08,Y
		BMI x84B2

.x84BF		RTS

.x84C0		STY &AB
		LDX #&00

.x84C4		JSR set0ES
		LDA &FD08,Y
		AND #&7F
		JSR set10S
		STA &FD60,X
		INY
		INX
		CPX #&08
		BNE x84C4

.x84D2		JSR x84B5
		BCS x84F6
		SEC
		LDX #&06

.x84DA		JSR set0ES
		LDA &FD0E,Y
		JSR set10S
		SBC &FD60,X
		DEY
		DEX
		BPL x84DA
		JSR mINY7			;INY x 7
		JSR set0ES
		LDA &FD0F,Y
		AND #&7F
		JSR set10S
		SBC &FD67
		BCC x84C0
		JSR mINY8			;INY x 8
		BCS x84D2

.x84F6		JSR set0ES
		LDY &AB
		LDA &FD08,Y
		ORA #&80
		STA &FD08,Y
		JSR set10S
		LDA &FD67
		CMP &AA
		BEQ x8517
		LDX &AA
		STA &AA
		BNE x8517
		JSR prtChr0D			;Print Carriage Return

.x8510		JSR prtChr0D			;Print Carriage Return
		LDY #&FF
		BNE x8520

.x8517		LDY &A8
		BNE x8510
		LDY #&05
		JSR prtChr20xY

.x8520		INY
		STY &A8
		LDY &AB
		JSR prtChr20x2
		JSR prtFileName			;Print Filename at offset=Y
		JMP x84A3

.x852E		EQUS	"off"			;Option Statements
		BRK
		EQUS	"LOAD"
		EQUS	"RUN"
		BRK
		EQUS	"EXEC"
\
\
\************************************************
\** Error routine for USB Catalog
\
.errNodisk	JSR uFlush
		JSR errARG
		EQUB	&FF
.strNodisk	EQUS	"No Disk"
		BRK
\
\
\************************************************
\** USB catalog
\
.catUSB		JSR setSCR			;Set Scratchram workspace
		JSR wrIPH			;Set Hex Mode
		JSR wrDVL			;Write DVL<CR> to monitor
		LDY #&00
		LDX #&00
		STX &FDF0			;Zero file counter
		STX &FDF1			;Zero directory counter			
		
.cu_L1		JSR uRDbL			;Read a byte from USB
		CMP #&0D			;Is it a <CR>?
		BEQ cu_L3			;Exit if so

		STA &FDE0,Y			;Store result at first buffer
		CMP strNodisk,Y			;Check it with the possible error code
		BNE cu_L2
		INX				;Add to count if it matches
		CPX #&07			;If error is returned, then give error
		BEQ errNodisk
		
.cu_L2		INY
		CPY #&0B
		BNE cu_L1

.cu_L3		LDA #&20
		STA &FDE0,Y
		JSR uSync
		JSR wrDSN			;Write DSN<CR> to monitor
		LDY #&00
		
.cu_L4		JSR uRDbL			;Read a byte from USB
		STA &FDEC,Y	
		INY
		CPY #&04			;Have we got 4 bytes?
		BNE cu_L4
		
		LDY #&00
		
.cu_L5		LDA &FDE0,Y
		JSR prtChrA
		INY
		CPY #&0C
		BNE cu_L5
		
		LDA #&28
		JSR prtChrA
		LDY #&03
		
.cu_L6		LDA &FDEC,Y
		JSR prtHexA8bit
		DEY
		CPY #&01
		BNE cu_J6
		LDA #&2D
		JSR prtChrA
		
.cu_J6		CPY #&FF
		BNE cu_L6
		JSR prtStr
		EQUS	") USB"
		EQUB	&0D
		EQUS	"Drive 5"
		NOP
		LDY #&0D
		JSR prtChr20xY			;Print number of Spaces in Y reg
		JSR prtStr
		EQUS	"Option N/A"		
		EQUB	&0D
		EQUS	"Directory :"
		NOP
		JSR set10
		LDA &FDCB			;Load the current default drive
		JSR prtHexA4bit
		JSR prtChr2E
		LDA &FDCA			;Current Default Directory
		JSR prtChrA
		LDY #&06
		JSR prtChr20xY			;Print number of spaces in Y reg
		JSR prtStr
		EQUS	"Library :"
		LDA &FDCD
		JSR prtHexA4bit
		JSR prtChr2E
		LDA &FDCC
		JSR prtChrA
		JSR prtChr0Dx2			;Print a Carriage Reuturn				
		
\***********************************************;Main catalog can now be read

		JSR setSCR
		JSR uSync
		JSR wrDIR			;Write "DIR" to monitor
		LDA #&0D
		JSR uWRbL			;and a <CR>
		JSR uRDbL
		CMP #&0D
		BEQ cu_L10
		JMP errNodisk
		
.cu_L10		LDY #&FF

.cu_L11		JSR uRDbL			;Read a line from the monitor
		INY
		CMP #&0D
		BEQ cu_L12
		STA &FD00,Y
		JMP cu_L11
		
.cu_L12		LDA #&00
		STA &FD00,Y
		JSR prtChr20x2
		LDY #&00
		
.cu_L12a	LDA &FD00,Y			;Load the line from buffer
		CMP uprmpt,Y			;Compare it with a prompt
		BNE cu_J13			;If not equal, then jump out
		INY
		CPY #&04			;If all 4 chars equal the prompt, then jump out
		BNE cu_L12a
		JMP cu_FINAL		
		
.cu_J13		LDY #&00
		LDA &FD00
		CMP #&2E			;Is first character a "."?
		BNE cu_L13			;If not, then its a regular entry
		JSR prtChrA			;otherwise it's a single dot directory
		INY
		LDA &FD01			;check for second dot directory
		CMP #&20			;if not, then jump
		BEQ cu_L14
		JSR prtChrA			;print second "."
		INY
		TYA				;mess up A register so it doesn't contain "."
		JMP cu_L14

.cu_L13		LDA &FD00,Y
		CMP #&20			;Is it a space?
		BEQ cu_L14			;if so then jump out
		CMP #&2E			;Is it a "."
		BEQ cu_L14			;again, jump out if so
		CMP #&00			;Is it the end of the filename
		BEQ cu_NOEXT			;if so, then no extension
		JSR prtChrA
		INY
		JMP cu_L13
		
.cu_NOEXT	INC &FDF0			;Increment file counter
		LDA #&20

.cu_L13a	JSR prtChrA
		INY
		CPY #&0F
		BNE cu_L13a
		JMP cu_J19
		
.cu_L14		PHA
		TYA
		PHA
.cu_L14a	CPY #&09
		BCS cu_L15
		JSR prtChr20
		INY
		JMP cu_L14a
		
.cu_L15		PLA
		TAY
		PLA
		CMP #&2E			;Is it a "."?
		BEQ cu_EXT			;if so then jump to extension routine
		
.cu_DIR		INC &FDF1			;Increment directory counter
		LDA #&3C
		JSR prtChrA
		INY

.cu_L16		LDA &FD00,Y
		BEQ cu_L17
		JSR prtChrA
		INY
		BNE cu_L16

.cu_L17		LDA #&3E
		JSR prtChrA
		JSR prtChr20
		JMP cu_J19
		
.cu_EXT		INC &FDF0			;Increment file counter
.cu_L18		LDA &FD00,Y
		BEQ cu_L19
		JSR prtChrA
		INY
		BNE cu_L18

.cu_L19		JSR prtChr20x2
.cu_J19		JSR prtChr20
		JSR prtChr20x2
		JMP cu_L10		
		
.cu_FINAL	LDA #&86			;Get cursor position
		JSR osbyte
		CPX #20				;if it's past 20, we need 2 <CR>s
		BCC cu_J20a
		JSR prtChr0D
		
.cu_J20a	JSR prtChr0D
		LDA &FDF0			;Get number of files
		PHA
		STA &FDA0
		LDA #&00
		STA &FDA4
		JSR PrDec8
		JSR prtStr
		EQUS	" file"
		NOP
		PLA
		CMP #&01
		BEQ cu_J20
		LDA #&73			;print an "s" if needed
		JSR prtChrA
		
.cu_J20		LDA #&2C
		JSR prtChrA
		JSR prtChr20
		LDA &FDF1			;Get number of directories
		PHA
		STA &FDA0
		LDA #&00
		STA &FDA4
		JSR PrDec8
		JSR prtStr
		EQUS	" director"
		NOP
		PLA
		CMP #&01			;print either "y" or "ies"
		BEQ cu_J21
		JSR prtStr
		EQUS	"ies"
		NOP
		JMP cu_J22
		
.cu_J21		LDA #&79
		JSR prtChrA
		
.cu_J22		JSR prtChr0D
		RTS
\
\
\************************************************
\** ???
\
.x853E		JSR set0F
		LDA &FD0E,Y
		JSR mLSR4_AND3			;LSR A * 4, then AND &03
		STA &C4
		CLC
		LDA #&FF
		ADC &FD0C,Y
		LDA &FD0F,Y
		ADC &FD0D,Y
		STA &C5
		LDA &FD0E,Y
		AND #&03
		ADC &C4
		STA &C4

.x855D		JSR set0F
		SEC
		LDA &FD07,Y
		SBC &C5
		PHA
		LDA &FD06,Y
		AND #&03
		SBC &C4
		TAX
		LDA #&00
		CMP &C2
		PLA
		SBC &C3
		TXA
		SBC &C6
.cmdRTS		RTS
\
\
\************************************************
\** Command jump table
\
.cmdTabD	EQUS	"ACCESS"
		EQUB	HI(cmdAccess-1)
		EQUB	LO(cmdAccess-1)
		EQUB	&32
		
		EQUS	"BACKUP"
		EQUB	HI(cmdBackup-1)
		EQUB	LO(cmdBackup-1)
		EQUB	&54
		
		EQUS	"COMPACT"
		EQUB	HI(cmdCompact-1)
		EQUB	LO(cmdCompact-1)
		EQUB	&0A
		
		EQUS	"COPY"
		EQUB	HI(cmdCopy-1)
		EQUB	LO(cmdCopy-1)
		EQUB	&64
		
		EQUS	"DELETE"
		EQUB	HI(cmdDelete-1)
		EQUB	LO(cmdDelete-1)
		EQUB	&01
		
		EQUS	"DESTROY"
		EQUB	HI(cmdDestroy-1)
		EQUB	LO(cmdDestroy-1)
		EQUB	&02
		
		EQUS	"DIR"
		EQUB	HI(cmdDir-1)
		EQUB	LO(cmdDir-1)
		EQUB	&09
		
		EQUS	"DRIVE"
		EQUB	HI(cmdDrive-1)
		EQUB	LO(cmdDrive-1)
		EQUB	&0A

		EQUS	"ENABLE"
		EQUB	HI(cmdEnable-1)
		EQUB	LO(cmdEnable-1)
		EQUB	&00
		
		EQUS	"EX"
		EQUB	HI(cmdEX-1)
		EQUB	LO(cmdEX-1)
		EQUB	&9A
		
		EQUS	"FREE"
		EQUB	HI(cmdFree-1)
		EQUB	LO(cmdFree-1)
		EQUB	&0A
		
		EQUS	"INFO"
		EQUB	HI(cmdInfo-1)
		EQUB	LO(cmdInfo-1)
		EQUB	&02

		EQUS	"LIB"
		EQUB	HI(cmdLib-1)
		EQUB	LO(cmdLib-1)
		EQUB	&09
		
		EQUS	"RENAME"
		EQUB	HI(cmdRename-1)
		EQUB	LO(cmdRename-1)
		EQUB	&87
		
		EQUS	"TITLE"
		EQUB	HI(cmdTitle-1)
		EQUB	LO(cmdTitle-1)
		EQUB	&0B
		
		EQUS	"WIPE"
		EQUB	HI(cmdWipe-1)
		EQUB	LO(cmdWipe-1)
		EQUB	&02

.cmdTabDE	EQUB	HI(cmdNull-1)		;This is a *RUN command
		EQUB	LO(cmdNull-1)
		EQUB	&00
\
\************************************************
\
.cmdTabU	EQUS	"BUILD"
		EQUB	HI(cmdBuild-1)
		EQUB	LO(cmdBuild-1)
		EQUB	&01
		
		EQUS	"DTRAP"
		EQUB	HI(cmdDtrap-1)
		EQUB	LO(cmdDtrap-1)
		EQUB	&00		

		EQUS	"DUMP"
		EQUB	HI(cmdDump-1)
		EQUB	LO(cmdDump-1)
		EQUB	&01
		
		EQUS	"EXPORT"
		EQUB	HI(uEXPcmd-1)
		EQUB	LO(uEXPcmd-1)
		EQUB	&01		

		EQUS	"LIST"
		EQUB	HI(cmdList-1)
		EQUB	LO(cmdList-1)
		EQUB	&01
		
		EQUS	"IMPORT"
		EQUB	HI(uIMPcmd-1)
		EQUB	LO(uIMPcmd-1)
		EQUB	&01
		
		EQUS	"MONITOR"
		EQUB	HI(cmdMoni-1)
		EQUB	LO(cmdMoni-1)
		EQUB	&00		
		
		EQUS	"RAM"
		EQUB	HI(cmdRam-1)
		EQUB	LO(cmdRam-1)
		EQUB	&00
		
		EQUS	"RAMTEST"
		EQUB	HI(RAMtest-1)
		EQUB	LO(RAMtest-1)
		EQUB	&00
		
		EQUS	"TYPE"
		EQUB	HI(cmdType-1)
		EQUB	LO(cmdType-1)
		EQUB	&01
		
.cmdTabDT	EQUS	"DISK"
		EQUB	HI(cmdRam-1)
		EQUB	LO(cmdRam-1)
		EQUB	&00
		
		EQUS	"DISC"
		EQUB	HI(cmdRam-1)
		EQUB	LO(cmdRam-1)
		EQUB	&00

.cmdTabUE	EQUB	HI(cmdRTS-1)		;This points to an RTS
		EQUB	LO(cmdRTS-1)
		EQUB	&00
\
\************************************************
\
.cmdTabH	EQUS	"RFS"
		EQUB	HI(helpRFS-1)
		EQUB	LO(helpRFS-1)
		EQUB	&00
		
		EQUS	"UTILS"
		EQUB	HI(helpUTILS-1)
		EQUB	LO(helpUTILS-1)
		EQUB	&00

.cmdTabHE	EQUB	HI(x99EB-1)		;Not sure on this command
		EQUB	LO(x99EB-1)
		EQUB	&00
\
\
\************************************************
\** OSFSC &03 - Unrecognised OS Command
\
.osfsc_03	JSR storeXY_F2			;Save X and Y at &F2 and &F3
		LDX #&FD
		LDA (&F2),Y
		CMP #&5D			;Is first Char of command "]"?
		BNE x8630			;If not then jump to command interpreter
		INY				;Skip the "]"
		JMP uCmd			;Send the rest of the line to the usb monitor

.x8630		JSR setSCR
		TYA
		PHA

.x8632		INX
		INX
		PLA
		PHA
		TAY
		JSR gsinitCLC			;JSR gsinit with CLC
		INX
		LDA cmdTabD,X			;Load character from command table
		BMI x8668			;if it's >&80 then must be an address, so jump
		DEX
		DEY
		STX &B8

.x8644		INX
		INY
		LDA cmdTabD,X
		BMI x8661
		EOR (&F2),Y
		AND #&5F
		BEQ x8644
		DEX

.x8652		INX
		LDA cmdTabD,X
		BPL x8652
		LDA (&F2),Y
		CMP #&2E
		BNE x8632
		INY
		BCS x8668

.x8661		LDA (&F2),Y
		JSR chkAlphaChar		;Check if it's a character
		BCC x8632

.x8668		PLA
		LDA cmdTabD,X
		PHA
		LDA cmdTabD+1,X
		PHA
		RTS
\
\
\************************************************
\** Save X and Y at &F2 and &F3
\
.storeXY_F2	STX &F2
		STY &F3
		LDY #&00
		RTS		
\
\
\************************************************
\** *WIPE command
\
.cmdWipe	JSR sta23_10CF			;?&10CF=&23
		JSR getNextArg			;Get next argument from command line
		JSR x8227_5

.x8686		JSR set0E
		LDA &FD0F,Y
		BMI x869D
		JSR prtFileName			;Print Filename at offset=Y
		JSR prtStr
		EQUS	" : "
		NOP
		JSR x9CA7
		BEQ x86A3

.x869A		JSR prtChr0D

.x869D		JSR getCatNext			;Get next entry in catalog that matches, C=1=found,Y=offset
		BCS x8686
		RTS

.x86A3		JSR loadCAT			;x8E59
		JSR deleteCatFN			;Delete filename at Y from catalog
		JSR saveCAT
		JSR set10
		LDY &FDCE
		JSR mDEY8			;DEY x 8
		STY &FDCE
		JMP x869A
\
\
\************************************************
\** *DELETE command
\
.cmdDelete	JSR staFF_10CF			;?&10CF=&FF
		JSR getNextArg			;Get next argument from command line
		JSR x8227_5
		JSR x82BB			;Print attributes if OPT set
		JSR deleteCatFN			;Delete filename at Y from catalog
		JMP saveCAT
\
\
\************************************************
\** *DESTROY command
\
.cmdDestroy	JSR chkEnable
		JSR sta23_10CF			;?&10CF=&23
		JSR getNextArg			;Get next argument from command line
		JSR x8227_5

.x86D6		JSR set0E
		LDA &FD0F,Y
		BMI x86E1
		JSR prtFileName			;Print Filename at offset=Y
		JSR prtChr0D

.x86E1		JSR getCatNext			;Get next entry in catalog that matches, C=1=found,Y=offset
		BCS x86D6
		JSR prtStr
		EQUB	&0D
		EQUS	"Delete (Y/N) ? "
		NOP
		JSR x9CA7
		BEQ x8702
		JMP prtChr0D

.x8702		JSR loadCAT			;x8E59
		JSR getCatFirst			;Get first entry in catalog that matches, C=1=found,Y=offset

.x8708		JSR set0E
		LDA &FD0F,Y
		BMI x8719
		JSR deleteCatFN			;Delete filename at Y from catalog
		JSR set10S
		LDY &FDCE
		JSR mDEY8			;DEY x 8
		STY &FDCE

.x8719		JSR getCatNext			;Get next entry in catalog that matches, C=1=found,Y=offset
		BCS x8708
		JSR saveCAT
		JSR prtStr
		EQUB	&0D
		EQUS	"Deleted"
		EQUB	&0D
		NOP
		RTS
\
\
\************************************************
\** OSFILE A=&00 Drives 0-4 - Save file to RAM
\
.osfile_00	JSR procFName			;Process filename
		LDA &CF				;Get the drive number
		CMP #&05			;Is is the usb?
		BEQ osfile_00u			;then process it
		JSR createFileN			;Create file, but we've already processed the filename
		JSR x9855			;pwsptr=?10DC/DD
		JSR readFileAttr		;Read file attributes

.x8749		JMP writeRAMblock		;Do the transfer
\
\
\************************************************
\** OSFILE A=&00 Drive 5 - Save file to USB
\
.osfile_00u	JSR uSync			;Synchronise Monitor	
		JSR wrIPH			;Write IPH <CR> to monitor
		JSR wrOPW
		LDY #&00

.OO_L1		LDA &C7,Y			;Write filename to monitor
		CMP #&20
		BEQ OO_L2
		JSR uWRbL
		INY
		CPY #&07
		BNE OO_L1
		
.OO_L2		LDA #&0D
		JSR uWRbL			;Write final <CR> to monitor
		JSR uCHKa			;Does this cover the error checks needed?
		JSR wrSEK			;Write "SEK 0000" to monitor to select start of file		
		JSR setSCR			;Set scratchram workspace
		LDY #&00
		
.OO_L3		LDA (&B0),Y			;Get a copy of the paramter block
		STA &FD00,Y			;and save it in scratch workspace
		INY
		CPY #&12
		BNE OO_L3
		SEC
		LDA &FD0E			;Subtract the start address from the end address
		SBC &FD0A
		STA &FD00
		LDA &FD0F
		SBC &FD0B
		STA &FD01
		LDA &FD10
		SBC &FD0C
		STA &FD02
		LDA &FD11
		SBC &FD0D
		STA &FD03			;Result stored in &00-&03
		JSR wrWRF			;Write "WRF " to monitor
		LDY #&03
		
.OO_L4		LDA &FD00,Y			;Write it to the monitor backwards
		JSR uWRbL
		CPY #&00
		BEQ OO_L5
		DEY
		JMP OO_L4
		
.OO_L5		LDA #&0D			;Send a final <CR>
		JSR uWRbL
		JSR setSCR
		LDA &FD0A
		STA zpm0
		JSR set10
		STA &FD72
		JSR setSCR
		LDA &FD0B			;Transfer start address to counter
		STA zpm1
		JSR set10
		STA &FD73			;And to Tube control block
		JSR setSCR
		LDA &FD0C
		JSR set10
		STA &FD74
		JSR setSCR
		LDA &FD0D
		JSR set10
		STA &FD75
		LDA #&00			;A=0=Tube Save
		JSR setTubeXfer 		;Setup the Tube Transfer
		JSR setSCR
		LDY #&00
		JMP OO_L7
		
		
.OO_L6		BIT zpm7
		BMI OO_Wtube
		LDA (zpm0),Y
		JMP OO_WtubeJ
.OO_Wtube	LDA &FEE5
		
.OO_WtubeJ	JSR uWRbL
		INC zpm0
		BNE OO_L7
		INC zpm1
		
.OO_L7		LDA &FD00
		SEC
		SBC #&01
		STA &FD00
		LDA &FD01
		SBC #&00
		STA &FD01
		BCS OO_L6
		JSR wrCLF
		LDY #&00

.OO_L8		LDA &C7,Y			;Write filename to monitor
		CMP #&20
		BEQ OO_L9
		JSR uWRbL
		INY
		CPY #&07
		BNE OO_L8
		
.OO_L9		LDA #&0D
		JSR uWRbL
		JSR uSync
		RTS
\
\
\************************************************
\** OSFILE A=&FF Drives 0-4 - Load File from RAM
\
.osfile_FF	JSR x822D			;Read Filename from paramter block
		LDA &CF				;Get Current drive
		CMP #&05			;is it the USB?
		BEQ osfile_FFu			;jump if so
		JSR x9855			;Setup private workspace pointer &B0 &B1
		JSR readFileAttr		;Read file attributes

.x8757		STY &BC
		LDX #&00
		LDA &C0
		BNE x8765
		INY
		INY
		LDX #&02
		BNE x876D

.x8765		JSR set0F
		LDA &FD0E,Y
		STA &C4
		JSR setLoadTU			;Set Load address pointers for Tube

.x876D		JSR set0F
		LDA &FD08,Y
		STA &BE,X
		INY
		INX
		CPX #&08
		BNE x876D
		JSR setExecTU			;Set Execution address pointers for Tube
		LDY &BC
		JSR x82BB			;Print info line of ?&10C7>=&80

.x8780		JMP readRAMblock		;Do the transfer
\
\
\************************************************
\** OSFILE A=&FF Drive 5 - Load File from USB
\
.osfile_FFu	JSR uSync			;Synchronise Monitor
		JSR wrIPH			;Write "IPH<CR>" to monitor
		JSR wrDIR			;Write "DIR" to monitor
		LDA #&20
		JSR uWRbL			;and a space
		LDY #&00

.FFu_L1		LDA &C7,Y			;Write Filename to monitor
		CMP #&20
		BEQ FFu_L2
		JSR uWRbL
		INY
		CPY #&07
		BNE FFu_L1
		
.FFu_L2		LDA #&0D
		JSR uWRbL			;Send a final <CR> to monitor
		JSR setERR			;Setup error check page, just incase
		LDY #&00
		STY &FD00
		DEY
		STY &FD01
		INY

.FFu_L3		JSR uRDbL			;Start of error check routine for the extract
		CMP #&0D			;This is messy and needs tidying up
		BEQ FFu_L3			;If first byte back is a CR, then ignore it
		STA &FD02,Y			;Store result at error buffer
		CMP #&20
		BEQ FFu_L5
		CMP &C7,Y			;Check the character is part of the filename
		BEQ FFu_L4			;if so, then proceed
		INY				;Skip the error header and first bytes
		INY
		INY
		JMP uCHK_L1			;and jump to error handler
		
.FFu_L4		INY
		JMP FFu_L3

.FFu_L5		LDX #&00
		JSR setSCR			;Set scratchpad workpage
		
.FFu_L6		JSR uRDbL			;Next 4 bytes from VNC1L are the filesize
		STA &FDF4,X			;Store them temporarily
		INX
		CPX #&04
		BNE FFu_L6
		
\***********************************************;Now we have the filesize, we can load it

		JSR uSync			;Sync up the monitor
		LDY #&00

.FFu_L7		LDA ustr1,Y			;Write "RD " to monitor
		BEQ FFu_L8
		JSR uWRbL
		INY
		BNE FFu_L7
		
.FFu_L8		LDY #&00		

.FFu_L9		LDA &C7,Y			;Write the Filename to monitor
		JSR uWRbL
		CMP #&20
		BEQ FFu_L10
		INY
		CPY #&07
		BNE FFu_L9
	
\***********************************************;Now data can be read
	
.FFu_L10	LDA #&0D
		JSR uWRbL			;Write final <CR> to monitor		
		LDY #&02
		JSR set10
		LDA (&B0),Y			;Copy Start address to Counter
		STA &FD72			;And to tube control block
		STA zpm0
		INY
		LDA (&B0),Y
		STA zpm1
		STA &FD73
		INY
		LDA (&B0),Y
		STA &FD74
		INY
		LDA (&B0),Y
		STA &FD75
		LDA #&01			;A=1=Tube Load
		JSR setTubeXfer			;Initialise Tube Transfer
		JSR setSCR
		LDY #&00
		JMP FFu_L12
		
.FFu_L11	JSR uRDbL
		BIT zpm7
		BMI FFu_Rtube
		STA (zpm0),Y
		JMP FFu_RtubeJ
		
.FFu_Rtube	STA &FEE5		
		
.FFu_RtubeJ	INC zpm0
		BNE FFu_L12
		INC zpm1
		
.FFu_L12	LDA &FDF4
		SEC
		SBC #&01
		STA &FDF4
		LDA &FDF5
		SBC #&00
		STA &FDF5
		BCS FFu_L11
		
		RTS
\
\
\************************************************
\** OSFSC &02 - */ Command
\
.osfsc_02	JSR storeXY_F2			;Save X and Y at &F2 and &F3

.cmdNull	JSR x87FB			;Entry point for *<???> unrecognised command through DFS
		JSR set10
		STY &FDDB
		JSR procFName
		JSR set10
		STY &FDDA
		JSR getCatFirst			;Get first entry in catalog that matches, C=1=found,Y=offset
		BCS x87C4
		JSR set10
		LDY &FDDB
		LDA &FDCC
		STA &CE
		LDA &FDCD
		JSR setDrvCF			;CLI and check drive idle, validate drive number AND#03, and store it at &CF
		JSR x80E7
		JSR getCatFirst			;Get first entry in catalog that matches, C=1=found,Y=offset
		BCS x87C4
		JSR errBad			;Jump to "Bad Command" error
		EQUB	&FE
		EQUS	"command"
		BRK

.x87C4		JSR x8757			;Load the data
		JSR set10
		CLC
		LDA &FDDA
		TAY
		ADC &F2
		STA &FDDA
		LDA &F3
		ADC #&00
		STA &FDDB
		LDA &FD76
		AND &FD77
		ORA &FDD7
		CMP #&FF
		BEQ x87F8
		LDA &C0
		STA &FD74
		LDA &C1
		STA &FD75
		LDX #&74
		LDY #&FD			;#&10
		LDA #&04
		JMP &0406			;Tube Call #&04 - Execute Code

.x87F8		JMP (&00C0)

.x87FB		LDA #&FF
		STA &C0
		LDA &F2
		STA &BC
		LDA &F3
		STA &BD
		RTS
\
\
\************************************************
\** *DIR command
\
.cmdDir		LDX #&00
		BEQ x880E
\
\
\************************************************
\** *LIB command
\
.cmdLib		LDX #&02

.x880E		JSR x881A
		JSR set10
		STA &FDCB,X			;Load the current default drive
		LDA &CE
		STA &FDCA,X			;Current Default Directory
		RTS
\
\
\************************************************
\** ???
\
.x881A		LDA #&24
		STA &CE
		JSR gsinitCLC			;JSR gsinit with CLC
		BNE x882A
		LDA #&00
		JSR setDrvCF			;CLI and check drive idle, validate drive number AND#03, and store it at &CF
		BEQ x885A

.x882A		JSR set10
		LDA &FDCB			;Load the current default drive
		JSR setDrvCF			;CLI and check drive idle, validate drive number AND#03, and store it at &CF

.x8830		JSR gsread
		BCS x8845
		CMP #&3A
		BNE x8853
		JSR getDrv
		JSR gsread
		BCS x885A
		CMP #&2E
		BEQ x8830

.x8845		JSR errBad
		EQUB	&CE
		EQUS	"directory"
		BRK
		
.x8853		STA &CE
		JSR gsread
		BCC x8845

.x885A		LDA &CF
		RTS
\
\
\************************************************
\** *TITLE command
\
.cmdTitle	JSR getNextArg			;Get next argument from command line
		JSR setDirDrv			;Set up Drive and Directories, checks for FDC Idle
		JSR loadCAT			;x8306
		LDX #&0B
		LDA #&00

.x886A		JSR x8880
		DEX
		BPL x886A

.x8870		INX
		JSR gsread
		BCS x887D
		JSR x8880
		CPX #&0B
		BCC x8870

.x887D		JMP saveCAT

.x8880		CPX #&08
		BCC x8888
		JSR set0F
		STA &FCF8,X
		RTS

.x8888		JSR set0E
		STA &FD00,X
		RTS
\
\
\************************************************
\** *ACCESS Command
\
.cmdAccess	JSR sta23_10CF			;?&10CF=&23
		JSR getNextArg			;Get next argument from command line
		JSR procFNameR			;Process filename without resetting GSREAD
		LDX #&00
		JSR gsinitCLC			;JSR gsinit with CLC
		BNE x88BF

.x889C		STX &AA
		JSR getCatFirst			;Get first entry in catalog that matches, C=1=found,Y=offset
		BCS x88A6
		JMP x8235

.x88A6		JSR x9836
		JSR set0E
		LDA &FD0F,Y
		AND #&7F
		ORA &AA
		STA &FD0F,Y
		JSR x82BB
		JSR getCatNext			;Get next entry in catalog that matches, C=1=found,Y=offset
		BCS x88A6
		BCC x887D

.x88BD		LDX #&80

.x88BF		JSR gsread
		BCS x889C
		CMP #&4C
		BEQ x88BD
		JSR errBad			;Error "Bad attribute"
		EQUB	&CF
		EQUS	"attribute"
		BRK
\
\
\************************************************
\** OSFSC &00 - *OPT command
\
.osfsc_00	JSR saveAXY
		TXA
		CMP #&04
		BEQ x88F8
		CMP #&02
		BCC x88ED
.errBadOpt	JSR errBad			;Error "Bad option"
		EQUB	&CB
		EQUS	"option"
		BRK

.x88ED		LDX #&FF
		TYA
		BEQ x88F4
		LDX #&00

.x88F4		JSR set10
		STX &FDC7
		RTS

.x88F8		TYA
		PHA
		JSR setDirDrv			;Set up Drive and Directories, checks for FDC Idle
		JSR loadCAT
		PLA
		JSR mASL4			;ASL A * 4
		JSR set0F
		EOR &FD06
		AND #&30
		EOR &FD06
		STA &FD06
		JMP saveCAT
\
\
\************************************************
\** Disk Full Error
\
.errDiskFull	JSR errDisk			;Error "Disk full"
		EQUB	&C6
		EQUS	"full"
		BRK
\
\
\************************************************
\** Routine to create a file
\
.createFile	JSR procFName			;Process filename
.createFileN	JSR getCatFirst			;Get first entry in catalog that matches, C=1=found,Y=offset
		BCC x8926			;If file doesnt exist, then jump x8926
		JSR deleteCatFN			;File exists, so delete filename at Y from catalog

.x8926		LDA &C2
		PHA
		LDA &C3
		PHA
		SEC
		LDA &C4
		SBC &C2
		STA &C2
		LDA &C5
		SBC &C3
		STA &C3
		JSR set10
		LDA &FD7A
		SBC &FD78
		STA &C6
		JSR x8957
		JSR set10
		LDA &FD79
		STA &FD75
		LDA &FD78
		STA &FD74
		PLA
		STA &BF
		PLA
		STA &BE
		RTS

.x8957		LDA #&00			;Find space in the catalog
		STA &C4
		LDA #&02

.x895D		STA &C5
		JSR set0F
		LDY &FD05
		BEQ x8991
		CPY #&F8
		BCS errCatFull
		JSR x855D
		JMP x8976

.x896E		BEQ errDiskFull
		JSR mDEY8			;DEY x 8
		JSR x853E

.x8976		TYA
		BCC x896E
		STY &B0
		JSR set0F
		LDY &FD05

.x897E		CPY &B0
		BEQ x8991
		JSR set0E
		LDA &FD07,Y
		STA &FD0F,Y
		JSR set0FS
		LDA &FD07,Y
		STA &FD0F,Y
		DEY
		BCS x897E

.x8991		LDX #&00
		JSR x89D1

.x8996		LDA &C7,X
		JSR set0E
		STA &FD08,Y
		INY
		INX
		CPX #&08
		BNE x8996

.x89A1		LDA &BD,X
		DEY
		JSR set0F
		STA &FD08,Y
		DEX
		BNE x89A1
		JSR x82BB
		TYA
		PHA
		JSR set0F
		LDY &FD05
		JSR mINY8			;INY x 8
		STY &FD05
		JSR saveCAT			;Save CAT to disk
		PLA
		TAY
		RTS

.errCatFull	JSR errARG
		EQUB	&BE
		EQUS	"Catalogue full"
		BRK

.x89D1		JSR set10
		LDA &FD76
		AND #&03
		ASL A
		ASL A
		EOR &C6
		AND #&FC
		EOR &C6
		ASL A
		ASL A
		EOR &FD74
		AND #&FC
		EOR &FD74
		ASL A
		ASL A
		EOR &C4
		AND #&FC
		EOR &C4
		STA &C4
		RTS
\
\
\***********************************************
\** *ENABLE Command
\
.cmdEnable	JSR set10
		LDA #&01
		STA &FDC8
		RTS
\
\
\************************************************
\** Set Load address pointers for Tube
\
.setLoadTU	JSR set10
		LDA #&00
		STA &FD75
		LDA &C4
		JSR mLSR2_AND3			;LSR A * 2, then AND &03
		CMP #&03
		BNE x8A0C
		LDA #&FF
		STA &FD75

.x8A0C		STA &FD74
		RTS
\
\
\************************************************
\** Set Execution address pointers for Tube
\
.setExecTU	JSR set10
		LDA #&00
		STA &FD77
		LDA &C4
		JSR mLSR6_AND3			;LSR A * 6, then AND &03
		CMP #&03
		BNE x8A23
		LDA #&FF
		STA &FD77

.x8A23		STA &FD76
		RTS
\
\
\***********************************************
\** *RENAME command
\
.cmdRename	JSR staFF_10CF			;?&10CF=&FF
		JSR gsinitCLC			;JSR gsinit with CLC
		BNE x8A32

.x8A2F		JMP x99FC

.x8A32		JSR procFNameR			;Process filename without resetting GSREAD
		TYA
		PHA
		JSR getCatFirst			;Get first entry in catalog that matches, C=1=found,Y=offset
		BCS x8A3F
		JMP x8235

.x8A3F		JSR x9833
		STY &B3
		PLA
		TAY
		JSR gsinitCLC
		BEQ x8A2F
		JSR procFNameR			;Process filename without resetting GSREAD
		JSR getCatFirst			;Get first entry in catalog that matches, C=1=found,Y=offset
		BCC x8A5E
		JSR errFile			;Error "File exists"
		EQUB	&C4
		EQUS	"exists"
		BRK

.x8A5E		LDY &B3
		JSR mINY8			;INY x 8
		LDX #&07

.x8A65		LDA &C7,X
		JSR set0E
		STA &FD07,Y
		DEY
		DEX
		BPL x8A65
		CLC
		JSR set0F
		SED
		LDA &FD04
		ADC #&01
		CLD
		STA &FD04
		JMP saveCAT
\
\
\************************************************
\** Provide Escape condition and error
\
.errEsc		JSR osbyte_7E
		JSR errARG
		EQUB	&11
		EQUS	"Escape"
		BRK
\
\
\************************************************
\** OSFSC &07 - Request file handles
\		
.osfsc_07	LDX #(chanBASE)				;Lowest File Handle Value
		LDY #(chanBASE+4)			;Highest File Handle Value

.x8DAA		RTS
\
\
\************************************************
\** OSFSC &06 - New FS about to take over
\
.osfsc_06	JSR saveAXY
		LDA #&77
		JMP osbyte
\
\
\************************************************
\** ???
\
.x8DB3		JSR osfsc_06

.x8DB6		LDA #&00

.x8DB8		CLC
		ADC #&20
		BEQ x8DAA
		TAY
		JSR x8DCE
		BNE x8DB8

.x8DC3		TYA
		BEQ x8DB3
		JSR calcChanY
		BCC x8DCE
		JMP x90B2

.x8DCE		PHA
		JSR x9056
		BCS x8E19
		JSR set11
		LDA &FD1B,Y
		EOR #&FF
		JSR set10S
		AND &FDC0
		STA &FDC0
		JSR set11S
		LDA &FD17,Y
		AND #&60
		BEQ x8E19
		JSR x8E1E
		JSR set11S
		LDA &FD17,Y
		AND #&20
		BEQ x8E16
		JSR set10S
		LDX &FDC4
		JSR set11S
		LDA &FD14,Y
		JSR set0FS
		STA &FD0C,X
		JSR set11S
		LDA &FD15,Y
		JSR set0FS
		STA &FD0D,X
		JSR set11S
		LDA &FD16,Y
		JSR mASL4			;ASL A * 4
		JSR set0FS
		EOR &FD0E,X
		AND #&30
		EOR &FD0E,X
		STA &FD0E,X
		JSR saveCAT
		JSR set10
		LDY &FDC2

.x8E16		JSR x9150

.x8E19		JSR set10
		LDX &FDC6
		PLA
		RTS

.x8E1E		JSR x8E4C

.x8E21		LDX #&07

.x8E23		JSR set11
		LDA &FD0C,Y
		STA &C6,X
		DEY
		DEY
		DEX
		BNE x8E23
		JSR getCatFirst			;Get first entry in catalog that matches, C=1=found,Y=offset
		BCC x8E67
		JSR set10
		STY &FDC4
		JSR set0FS
		LDA &FD0E,Y
		LDX &FD0F,Y
		JSR set10S
		LDY &FDC2
		JSR set11S
		EOR &FD0D,Y
		AND #&03
		BNE x8E67
		TXA
		CMP &FD0F,Y
		BNE x8E67

.x8E4B		RTS
\
\
\
.x8E4C		JSR set11
		LDA &FD0E,Y
		AND #&7F
		STA &CE
		LDA &FD17,Y
		AND #&07			;As we've taken this out of setDrvCF, need to put it back in?
		JMP setDrvCF			;CLI and check drive idle, validate drive number AND#03, and store it at &CF

.x8E67		JSR errARG
		EQUB	&C8
		EQUS	"Disk changed"
		BRK
\
\
\************************************************
\** Start of OSFIND Routine
\
.x8E78		CMP #&00			;Is it requesting a Close?
		BNE x8E82			;Jump if not
		JSR saveAXY
		JMP x8DC3

.x8E82		JSR x83D0
		STX &BC				;Store LSB of filename string
		STY &BD				;Store MSB of filename string
		STA &B4				;Store OSFIND type
		BIT &B4
		PHP
		JSR procFName
		JSR getCatFirst			;Get first entry in catalog that matches, C=1=found,Y=offset
		BCS x8EB0
		PLP
		BVC x8E9C
		LDA #&00
		RTS

.x8E9C		PHP
		LDA #&00
		LDX #&07

.x8EA1		JSR set10
		STA &BE,X
		STA &FD74,X
		DEX
		BPL x8EA1
		LDA #&40
		STA &C5
		JSR createFile

.x8EB0		PLP
		PHP
		BVS x8EB7
		JSR x9823

.x8EB7		JSR x8F83
		BCC x8ECA

.x8EBC		JSR set11
		LDA &FD0C,Y
		BPL x8EE7
		BIT &B4
		BMI x8EE7
		JSR x8F7E
		BCS x8EBC

.x8ECA		JSR set10
		LDY &FDC2
		BNE x8EF0
		JSR errARG
		EQUB	&C0
		EQUS	"Too many files open"
		BRK

.x8EE7		JSR errFile
		EQUB &C2
		EQUB	"open"
		BRK
\
\
\************************************************
\** Continuation of OSFIND
\
.x8EF0		LDA #&08		
		JSR set10
		STA &FDC5

.x8EF5		JSR set0E
		LDA &FD08,X
		JSR set11S
		STA &FD00,Y
		INY
		JSR set0FS
		LDA &FD08,X
		JSR set11S
		STA &FD00,Y
		INY
		INX
		JSR set10S
		DEC &FDC5
		BNE x8EF5
		LDX #&10
		LDA #&00

.x8F0D		JSR set11
		STA &FD00,Y
		INY
		DEX
		BNE x8F0D
		JSR set10S
		LDA &FDC2
		TAY
		JSR mLSR5			;LSR A * 5
		ADC #&11
		JSR set11S
		STA &FD13,Y
		JSR set10S
		LDA &FDC1
		JSR set11S
		STA &FD1B,Y
		JSR set10S
		ORA &FDC0
		STA &FDC0
		JSR set11S
		LDA &FD09,Y
		ADC #&FF
		LDA &FD0B,Y
		ADC #&00
		STA &FD19,Y
		LDA &FD0D,Y
		ORA #&0F
		ADC #&00
		JSR mLSR4_AND3			;LSR A * 4, then AND &03
		STA &FD1A,Y
		PLP
		BVC x8F77
		BMI x8F53
		LDA #&80
		ORA &FD0C,Y
		STA &FD0C,Y

.x8F53		JSR set11
		LDA &FD09,Y
		STA &FD14,Y
		LDA &FD0B,Y
		STA &FD15,Y
		LDA &FD0D,Y
		JSR mLSR4_AND3			;LSR A * 4, then AND &03
		STA &FD16,Y

.x8F68		LDA &CF
		JSR set11
		ORA &FD17,Y
		STA &FD17,Y
		TYA
		JSR mLSR5			;LSR A * 5
		ADC #(chanBASE-1)		;Was 90. before that was ORA #&10
		RTS

.x8F77		JSR set11
		LDA #&20
		STA &FD17,Y
		BNE x8F68

.x8F7E		TXA
		PHA
		JMP x8FC2
\
\
\
.x8F83		JSR set10
		LDA #&00
		STA &FDC2
		LDA #&08
		STA &B5
		TYA
		TAX
		LDY #&A0

.x8F90		STY &B3
		TXA
		PHA
		LDA #&08
		STA &B2
		LDA &B5
		JSR set10
		BIT &FDC0
		BEQ x8FBC
		JSR set11S
		LDA &FD17,Y
		EOR &CF
		AND #&03
		BNE x8FC2

.x8FA8		JSR set0E
		LDA &FD08,X
		JSR set11S
		EOR &FD00,Y
		AND #&7F
		BNE x8FC2
		INX
		INY
		INY
		DEC &B2
		BNE x8FA8
		SEC
		BCS x8FCC

.x8FBC		JSR set10
		STY &FDC2
		STA &FDC1

.x8FC2		SEC
		LDA &B3
		SBC #&20
		STA &B3
		ASL &B5
		CLC

.x8FCC		PLA
		TAX
		LDY &B3
		LDA &B5
		BCS x8FD6
		BNE x8F90

.x8FD6		RTS
\
\
\
.x8FD7		JSR stackClaim			;Change stacked A to &00
		JSR set10
		LDA &FDC0
		PHA
		TYA
		BNE x8FE6
		JSR x8DB6
		BEQ x8FE9

.x8FE6		JSR x8DC3

.x8FE9		PLA
		JSR set10
		STA &FDC0
		RTS
\
\
\************************************************
\** Changes Stacked A to &00 to claim the call
\
.stackClaim	PHA
		TXA
		PHA
		LDA #&00
		TSX
		STA &0109,X
		PLA
		TAX
		PLA
		RTS
\
\
\************************************************
\** Start of OSARGS Routine
\
.OSargs		JSR saveAXY			;Save the Registers
		CMP #&FF			;Is the call A=&FF?
		BEQ x8FD7			;If so, do all outstanding Disk Updates
		CPY #&00			;Is the Y register Y=&00?
		BEQ x9014			;If so, then jump to Y=&00 command set
		CMP #&03			;Check if A > &03
		BCS argsExit			;Return if so
		JSR stackClaim			;Change stacked A to &00
		CMP #&01
		BNE Jx9037
		JMP x92A9
		
.Jx9037		JMP x9037

.x9014		CMP #&06			;Check if A > &06
		BCS argsExit			;Return if so
		JSR stackClaim			;Change stacked A to &00
		CMP #&00
		BNE x9014a
.x9014b		JMP osargs00			;Jump to OSARGS 00 routine

.x9014a		CMP #&04
		BCS osargs45			;Jump to OSARGS 04 and 05 routine
		CMP #&03
		BEQ x9014b			;Read libfs, same as Read FS
		CMP #&02
		BEQ argsExit			;Exit if OSARGS 02
\
\** OSARGS 01 Handler
\
		LDA #&FF
		STA &02,X
		STA &03,X
		JSR set10
		LDA &FDDA
		STA &00,X
		LDA &FDDB
		STA &01,X
		LDA #&00

.argsExit	RTS
\
\** OSARGS 04 and 05 Handler
\
.osargs45	PHP				;Save stack - EQ = used, NE = free
		TXA
		PHA				;Save zero page offset
		JSR setDrv			;Get current Drive
		JSR readUF			;Read Used and Free space
		PLA
		TAX				;Get zero page offset back
		LDA zpm0				;Get used space
		STA &01,X
		LDA zpm1
		STA &02,X
		PLP
		BNE osargs45_1
		LDA zpm2
		STA &01,X
		LDA zpm3
		STA &02,X
		
.osargs45_1	LDA #&00
		STA &00,X
		STA &03,X
		RTS
\
\** Read Used and Free space
\** On entry, &CF = Drive to examine
\** On exit, zpm0 & zpm1 = used number of sectors
\** zpm2 & zpm3 = free number of sectors
\** A = Number of used filenames
\
.readUF		JSR loadCAT
		LDA #&02			;Catalog takes up 2 sectors
		STA zpm0
		LDA #&00
		STA zpm1
		JSR set0F
		LDX &FD05			;Get number of files
		BEQ readUF_X
		
.readUF_1	LDA &FD05,X
		CLC
		ADC zpm0
		STA zpm0
		PHP
		LDA &FD06,X
		JSR mLSR4_AND3
		PLP
		ADC zpm1
		STA zpm1
		LDA &FD04,X
		BEQ readUF_2
		INC zpm0
		BNE readUF_2
		INC zpm1
		
.readUF_2	TXA
		SEC
		SBC #&08
		TAX
		CMP #&08
		BCS readUF_1		
		
.readUF_X	LDA &FD07
		SEC
		SBC zpm0
		STA zpm2
		PHP
		LDA &FD06
		AND #&03
		PLP
		SBC zpm1
		STA zpm3
		LDA &FD05			;Get number of files
		JMP mLSR3			;Divide by 8
\
\
\************************************************
\** FREE Command
\
.cmdFree	JSR gsinitCLC_D
		JSR readUF
		PHA
		EOR #31
		JSR setSCR
		STA &FDA0
		PHA
		LDA #&20
		STA &FDA4
		JSR PrDec8_2
		JSR prtStr
		EQUS	" File"
		NOP
		PLA
		CMP #&01
		BEQ cmdFree_J1
		LDA #&73
		JSR prtChrA
		
.cmdFree_J1	LDA #&20
		JSR prtChrA
		LDA zpm3
		STA &FDA2
		JSR prtHexA4bit
		LDA zpm2
		STA &FDA1
		JSR prtHexA8bit
		JSR prtStr
		EQUS	" Sector"
		NOP
		LDA zpm2
		CMP #&01
		BNE cmdFree_J2a
		LDA zpm3
		BEQ cmdFree_J2

.cmdFree_J2a	LDA #&73
		JSR prtChrA
				
.cmdFree_J2	LDA #&20
		JSR prtChrA
		LDA #&20
		STA &FDA4
		LDA #&00
		STA &FDA0
		JSR PrDec24_5
		JSR prtStr
		EQUS	" Bytes Free"
		EQUB &0D
		NOP
		PLA
		STA &FDA0
		PHA
		LDA #&20
		STA &FDA4
		JSR PrDec8_2
		JSR prtStr
		EQUS	" File"
		NOP 
		PLA
		CMP #&01
		BEQ cmdFree_J3
		LDA #&73
		JSR prtChrA
				
.cmdFree_J3	LDA #&20
		JSR prtChrA
		LDA zpm1
		STA &FDA2
		JSR prtHexA4bit
		LDA zpm0
		STA &FDA1
		JSR prtHexA8bit
		JSR prtStr
		EQUS	" Sectors "
		NOP
		LDA #&20
		STA &FDA4
		LDA #&00
		STA &FDA0
		JSR PrDec24_5
		JSR prtStr
		EQUS	" Bytes Used"
		EQUB &0D
		NOP
		RTS
\
\
\************************************************
\** Return Filing System Number
\
.osargs00	JSR setSCR			;Set scratchram workpage
		LDA #ramFSID			;RamFS system filing type
		LDX &FD8F			;Check DiskTrap status
		BEQ osargs_J1			;If 0 then not active, so skip
		LDA #diskFSID			;Else fool system into thinking Disk

.osargs_J1	TSX
		STA &0105,X			;Store it where A gets pulled
		RTS				;and return
\
\
\

.x9037		JSR x90AA
		JSR set10
		STY &FDC2
		ASL A
		ADC &FDC2
		TAY
		JSR set11S
		LDA &FD10,Y
		STA &00,X
		LDA &FD11,Y
		STA &01,X
		LDA &FD12,Y
		STA &02,X
		LDA #&00
		STA &03,X
		RTS

.x9056		PHA
		JSR set10
		STX &FDC6
		TYA
		AND #&E0
		STA &FDC2
		BEQ x9075
		JSR mLSR5			;LSR A * 5
		TAY
		LDA #&00
		SEC

.x9069		ROR A
		DEY
		BNE x9069
		JSR set10
		LDY &FDC2
		BIT &FDC0
		BNE x9078

.x9075		PLA
		SEC
		RTS

.x9078		PLA
		CLC
		RTS

.x907B		PHA
		TXA
		JMP x9082
\
\
\************************************************
\** Calculate Channel # memory location in page &1100
\
.calcChanY	PHA				;Current channel in Y
		TYA				;Xfer to A

.x9082		SEC
		SBC #(chanBASE-17)		;Subtract 17 from Channel Base Number (channel_base-17)
		CMP #&10			;Check it's in range
		BCC x908A
		CMP #&18
		BCC x908C

.x908A		LDA #&08

.x908C		JSR mASL5			;ASL A * 5
		TAY				;Channel number now forms top 3 bits of Y register
		PLA				;Restore A
		RTS				;and return
\
\
\************************************************
\** OSFSC &01 - Check EOF
\
.osfsc_01	PHA
		TYA
		PHA
		TXA
		TAY
		JSR x90AA
		TYA
		JSR x930C
		BNE x90A4
		LDX #&FF
		BNE x90A6

.x90A4		LDX #&00

.x90A6		PLA
		TAY
		PLA

.x90A9		RTS
\
\
\
.x90AA		JSR calcChanY
		JSR x9056
		BCC x90A9

.x90B2		JSR errARG
		EQUB	&DE
		EQUS	"RamFS Channel"
		BRK

.x90BE		JSR errARG
		EQUB	&DF
		EQUS	"EOF"
		BRK
\
\
\************************************************
\** Start of OSBGET Routine
\
.x90C6		JSR x83D0			;Some sort of messing with SaveAXY Return address?
		JSR x90AA			;Calculate current channel
		TYA
		JSR x930C
		BNE x90E5
		JSR set11
		LDA &FD17,Y			;Get channel buffer flags
		AND #&10			;Check EOF bit
		BNE x90BE			;Jump to error if set
		LDA #&10
		JSR x9141
		JSR set10
		LDX &FDC6
		LDA #&FE
		SEC
		RTS

.x90E5		JSR set11
		LDA &FD17,Y
		BMI x90F4
		JSR x8E4C			;?????
		JSR x9150
		SEC
		JSR x9158

.x90F4		JSR set11
		LDA &FD10,Y			;Load channel LSB address
		STA &BC				;Store at &BC
		LDA &FD13,Y			;Load channel MSB address
		STA &BD				;Store at &BD
		JSR setDFS			;Set equivalent workpage in RAM
		LDY &BC				;Y register had the offset
		LDA &FD00,Y			;Load the byte from the buffer
		PHA				;and store it
		JSR set10S
		LDY &FDC2
		LDX &BC
		INX
		TXA
		JSR set11S
		STA &FD10,Y
		BNE x9123
		CLC
		LDA &FD11,Y
		ADC #&01
		STA &FD11,Y
		LDA &FD12,Y
		ADC #&00
		STA &FD12,Y
		JSR x9146

.x9123		CLC
		PLA
		RTS

.x9126		JSR set11
		CLC
		LDA &FD0F,Y
		ADC &FD11,Y
		STA &C5
		STA &FD1C,Y
		LDA &FD0D,Y
		AND #&03
		ADC &FD12,Y
		STA &C4
		STA &FD1D,Y

.x913F		LDA #&80

.x9141		JSR set11
		ORA &FD17,Y
		BNE x914B

.x9146		LDA #&7F

.x9148		JSR set11
		AND &FD17,Y

.x914B		JSR set11
		STA &FD17,Y
		CLC
		RTS
\
\
\
.x9150		JSR set11
		LDA &FD17,Y
		AND #&40
		BEQ x9194
		CLC

.x9158		PHP
		JSR set10
		LDY &FDC2
		JSR set11S
		LDA &FD13,Y
		STA &BF
		JSR x8B90			;Sets top bits of address to &FF for Tube
		JSR set11S			;Becasue x8B90 sets Page 10
		LDA #&00
		STA &BE
		STA &C2
		LDA #&01
		STA &C3
		PLP
		BCS x918B
		LDA &FD1C,Y
		STA &C5
		LDA &FD1D,Y
		STA &C4
		LDA &BF				;Get MSB of RAM to be written to
		STA zpm6			;Store it to send to routine
		LDA #&FD			;Replace MSB with JIM window
		STA &BF				;And Store
		JSR writeRAMblock		;Do the write
		JSR set10
		LDY &FDC2
		LDA #&BF
		JSR x9148
		BCC x9191

.x918B		JSR x9126
		LDA &BF				;Get MSB of RAM to be written to
		STA zpm6			;Store it to send to routine
		LDA #&FD			;Replace MSB with JIM window
		STA &BF				;And Store
		JSR readRAMblock		;Do the read

.x9191		JSR set10
		LDY &FDC2

.x9194		RTS

.x9195		JMP x9828

.x9198		JSR errFile			;Error - "File read only"
		EQUB	&C1
		EQUS	"read only"
		BRK

.x91A6		JSR saveAXY
		JMP x91B2
\
\
\************************************************
\** Start of OSBPUT Routine
\
.x91AC		JSR saveAXY
		JSR x90AA

.x91B2		PHA
		JSR set11
		LDA &FD0C,Y			;Check if the file is Read Only
		BMI x9198
		LDA &FD0E,Y			;Check if file is locked
		BMI x9195
		JSR x8E4C			;Setup drive etc
		TYA
		CLC
		ADC #&04
		JSR x930C			;????
		BEQ x91B2_A
		JMP x923F
		
.x91B2_A	JSR x8E21			;Mess with catalog...?
		JSR set10
		LDX &FDC4
		JSR set0F
		SEC
		LDA &FD07,X
		SBC &FD0F,X
		PHA
		LDA &FD06,X
		SBC &FD0E,X
		AND #&03
		JSR set10S
		STA &FDC3
		ASL A
		ASL A
		ASL A
		ASL A
		JSR set0FS
		EOR &FD0E,X
		AND #&30
		EOR &FD0E,X
		STA &FD0E,X
		JSR set10S
		LDA &FDC3
		JSR set11S
		CMP &FD1A,Y
		BNE x9224
		PLA
		CMP &FD19,Y
		BNE x9225
		STY &B4
		JSR osbyte_C7R
		JSR x907B
		CPY &B4
		BNE x920E
		JSR osbyte_C7W			;*FX199 - Write *SPOOL file handle (0)

.x920E		LDY &B4
		JSR x8DCE
		JSR errARG
		EQUB	&BF
		EQUS	"Can't extend"
		BRK

.x9224		PLA

.x9225		JSR set0FS
		STA &FD0D,X
		JSR set11S
		STA &FD19,Y
		JSR set10S
		LDA &FDC3
		JSR set11S
		STA &FD1A,Y
		LDA #&00
		JSR set0FS
		STA &FD0C,X
		JSR saveCAT
		;JSR x98DA
		JSR set10S
		LDY &FDC2

.x923F		JSR set11
		LDA &FD17,Y
		BMI x925B
		JSR x9150
		JSR set11
		LDA &FD14,Y
		BNE x9257
		TYA
		JSR x930C
		BNE x9257
		JSR x9126
		BNE x925B

.x9257		SEC
		JSR x9158

.x925B		JSR set11
		LDA &FD10,Y
		STA &BC
		LDA &FD13,Y
		STA &BD
		JSR setDFS			;Set workpage buffer to equivalent page
		LDY &BC				;Load Y register with the offset
		PLA				;Retrieve the value to store
		STA &FD00,Y			;And write it
		JSR set10S
		LDY &FDC2
		LDA #&40
		JSR x9141
		INC &BC
		LDA &BC
		JSR set11S
		STA &FD10,Y
		BNE x928E
		JSR x9146
		JSR set11
		LDA &FD11,Y
		ADC #&01
		STA &FD11,Y
		LDA &FD12,Y
		ADC #&00
		STA &FD12,Y

.x928E		TYA
		JSR x930C
		BCC x92A8
		LDA #&20
		JSR x9141
		LDX #&02

.x929B		JSR set11
		LDA &FD10,Y
		STA &FD14,Y
		INY
		DEX
		BPL x929B
		DEY
		DEY
		DEY

.x92A8		RTS
\
\
\
.x92A9		JSR saveAXY
		JSR x90AA
		JSR mINY4			;INY x 4
		JSR set10
		LDY &FDC2

.x92B5		JSR x9324
		BCS x92D7
		JSR set11
		LDA &FD14,Y
		STA &FD10,Y
		LDA &FD15,Y
		STA &FD11,Y
		LDA &FD16,Y
		STA &FD12,Y
		JSR x92E6
		LDA #&00
		JSR x91A6
		JMP x92B5
\
\
\
.x92D7		JSR set11
		LDA &00,X
		STA &FD10,Y
		LDA &01,X
		STA &FD11,Y
		LDA &02,X
		STA &FD12,Y

.x92E6		LDA #&6F
		JSR x9148
		JSR set11
		LDA &FD0F,Y
		ADC &FD11,Y
		JSR set10S
		STA &FDC5
		JSR set11S
		LDA &FD0D,Y
		AND #&03
		ADC &FD12,Y
		CMP &FD1D,Y
		BNE x92A8
		JSR set10S
		LDA &FDC5
		JSR set11S
		CMP &FD1C,Y
		BNE x92A8
		JMP x913F
\
\
\
.x930C		JSR set11
		TAX
		LDA &FD12,Y
		CMP &FD16,X
		BNE x9323
		LDA &FD11,Y
		CMP &FD15,X
		BNE x9323
		LDA &FD10,Y
		CMP &FD14,X

.x9323		RTS

.x9324		JSR set11
		LDA &FD14,Y
		CMP &00,X
		LDA &FD15,Y
		SBC &01,X
		LDA &FD16,Y
		SBC &02,X
		RTS
\
\
\************************************************
\** RAM Initialisiation checks and format
\
.setRam		JSR saveAXY
		JSR setSCR
		LDY #&00
		
.setR1		LDA &FD80,Y			;Load BOOT check area
		CMP cpyMsg,Y			;Is the (C) message stored there?
		BNE setR2			;if not, then it's a power on boot
		INY
		CPY #&0F
		BNE setR1			;If it's all there okay, then it's a regular boot
		LDA #&56			;Set the flag to indicate normal boot
		STA &FDDA			;Store flag
		RTS				;And return
		
.setR2		LDY #&00			;(C) message not found

.setR3		LDA cpyMsg,Y			;so copy it to the BOOT check area
		STA &FD80,Y
		INY
		CPY #&10
		BNE setR3
		LDA #&00			;Ok, it's a power on boot
		TAY
		STA zpm0			;setup to format the drives
.setR4		STA &FCFE			;starting with drive 0
		LDA #&10
		STA &FCFF
		TYA
		
.setR5		STA &FD00,Y			;Clear first page of directory
		INY
		BNE setR5
		INC &FCFF
		
.setR6		STA &FD00,Y			;And the second
		INY
		BNE setR6
		LDA #&03			;Load MSB sector count into place
		STA &FD06
		LDA #&20			;and LSB
		STA &FD07
		LDA zpm0
		CLC
		ADC #&04			;Next drive to be done
		STA zpm0
		CMP #&10			;Have we done all 4?
		BNE setR4			;go back if not
		JSR setSCR			;Set scratchram workpage
		LDA #&12			;Set the flag to indicate a power on boot
		STA &FDDA			;Store flag
		JSR osbyte_EA			;Check for Tube presence
		TXA
		EOR #&FF
		JSR set10
		STA &FDD7			;Store the flag	
		LDA #&24			;Set Directory to "$"
		STA &FDCA			;Current Default Directory
		LDA #&25			;and library to "%"
		STA &FDCC
		LDY #&00			;Set directory drive to 0
		STY &FDCB			;Store the current default drive
		STY &FDC0			;Zero the open channels
		STY &FDC9
		DEY
		STY &FDC8
		STY &FDC7
		LDY #&04			;And library drive to 4
		STY &FDCD
		RTS				;And return
\
\
\************************************************
\** Check for RAMFS initialisation.
\** C=0 RAMFS is initialised, C=1 RAMFS not initialised
\
.bootChk	JSR setSCR
		LDY #&00
		
.bootChk_L1	LDA &FD80,Y			;Load BOOT check area
		CMP cpyMsg,Y			;Is the (C) message stored there?
		BNE bootChk_no			;if not, then there's no RAMFS present
		INY
		CPY #&0F
		BNE bootChk_L1
		CLC
		RTS
		
.bootChk_no	SEC
		RTS
\
\
\********************************************************************
\** ROM Service Call &03 - Auto Boot
\
.x9334		JSR prtStr
		EQUS	"RetroClinic RamFS"
		NOP
		JSR setSCR
		LDA #&00
		STA &FDD9			;Store &00 to *RAM/Serv03 flag
		JSR bootChk
		BCS noRAMFS		
		LDA &FDDA
		CMP #&12			;If bootup flag is &12, then it's been initialised
		BEQ R03_init			;so print that
		CMP #&56			;Check for normal boot flag
		BNE noRAMFS			;No RAMFS if not either &12 or &56
		
.R03_exit	LDA &FD8F			;Check DiskTrap flag
		BEQ R03_exit2			;branch if not set
		LDA #&83			;otherwise print reminder
		JSR prtChrA
		JSR prtStr
		EQUS	"(DT)"
		NOP
		
.R03_exit2	JSR prtChr0Dx2			
		JMP x9348

.R03_init	LDA #&82
		JSR prtChrA
		JSR prtStr
		EQUB	"initialised"
		NOP
		JMP R03_exit2
		
.noRAMFS	LDA #&81			;RamFS not found, so report it
		JSR prtChrA
		JSR prtStr
		EQUB	"not detected"
		NOP
		JMP R03_exit2
\
\
\************************************************
\** *DTRAP Command
\
.cmdDtrap	JSR stackClaim			;Change stacked A to &00
		JSR setSCR			;Set scratchram workspace
		LDA &FD8F			;Load DiskTrap status
		EOR #&FF			;Invert it
		STA &FD8F			;And put it back
		LDA #&7F			;Set the system up for a forced <CTRL><BREAK>
		STA &FE4E
.dt_reboot	JMP (&FFFC)			;And jump
\
\
\************************************************
\** DTRAP proceedure
\
.doDtrapC	JSR saveAXY			;Routine must keep all registers intact
		JSR setSCR			;Set scratchram workspace
		LDX #&00
		
.doD_L3		LDA &FD80,X			;Load the init check string
		CMP cpyMsg,X			;is it there?
		BNE doDtrapX			;if not, then we haven't booted up yet, or RAMFS is not present
		INX
		CPX #&0F
		BNE doD_L3
		LDA &FD80,X			;As X is now &0F, what about the DiskTrap status?
		CMP cpyMsg,X
		BEQ doDtrapX			;If disabled, then exit
		
.doDtrap	LDA #&BB
		LDX #&00
		LDY #&FF
		JSR osbyte			;Get the ROM socket that Basic is in
		CPX #&FF			;Is BASIC not present,  or are we in MOS 3.50 which FUCKS UP HERE
		BNE doD_J1			;because it hasn't initialised yet
		LDX #&0C			;If so, assune Basic is in socket C and be done with it

.doD_J1		STX zpm0			;Store BASIC socket number
		LDY #&00			;Now we need to hijack the system

.doD_L1		CPY &F4				;Are we looking at our own ROM?
		BEQ doD_L2			;If so skip
		CPY zpm0			;Are we looking at BASIC?
		BEQ doD_L2			;If so skip
		LDA #&00			;Disable any other ROMs
		STA &2A1,Y
.doD_L2		INY
		CPY #&10
		BNE doD_L1
		
.doDtrapX	RTS
\
\
\************************************************
\** *RAM command
\
.cmdRam		JSR setSCR
		LDA #&FF
		STA &FDD9
		STA &FDD8
		CPX #202			;Check postition of command counter
		BCC x9348			;If it's less than 202, then it's *RAM
		LDA &FD8F			;Get DiskTrap status
		BNE x9348			;if set, then carry on
.cmdRamRTS	RTS				;else exit, it must be a *DISK/C

.x9348		JSR stackClaim			;Change stacked A to &00
		LDA #&06
		JSR jump_osfcv			;Call OSFSC with A=6, new FS about to take over
		LDX #&0D

.x9353		LDA x9943,X			;Transfer our vectors
		STA &0212,X
		DEX
		BPL x9353
		JSR osbyte_A8			;*FX168 - Read address of ROM pointer table
		STY &B1
		STX &B0
		LDX #&07
		LDY #&1B

.x9367		LDA x9933+3,Y			;Transfer ROM pointer table
		STA (&B0),Y
		INY
		LDA x9933+3,Y
		STA (&B0),Y
		INY
		LDA &F4
		STA (&B0),Y
		INY
		DEX
		BNE x9367
		STX &CF
		JSR set10
		STY &FD82
		STY &FD83
		LDX #&0F
		JSR osbyte_8F			;Vectors Claimed
		
.x93C0		JSR setSCR
		LDA &FDD9
		BNE SHbrkChk
		JSR osbyte_EA			;Check for Tube presence
		TXA
		EOR #&FF
		JSR set10
		STA &FDD7			;Store the flag	
		LDY #&00
		STY &FDC0			;Zero the open channels
		STY &FDC9
		DEY
		STY &FDC8
		STY &FDC7

.SHbrkChk	JSR setSCR
		LDA &FDD8			;Get bootup option
		BNE x942C
		JSR set10
		LDA &FDCB			;Get Current Default Drive
		LDX &FDCA			;And Default Directory
		JSR setSCR
		STX &FDD6			;Store them while we do Shift Break stuff
		STA &FDD7
		JSR set10
		LDA #&24			;Set Directory to "$"
		STA &FDCA			;Current Default Directory
		LDA &FDCB			;Get current Default drive
		CMP #&05
		BCS skipUSB			;Skip it if it is the USB
		STA &CF				;and copy it
		JSR SHbreak			;Do a Shift Break check on Default Drive
		JSR set10

.skipUSB	LDA #&04			;Not there, So check Drive 4
		STA &CF				;Store at &CF
		STA &FDCB			;and &10CB
		JSR SHbreak			;Check for Shift Break now
		JSR setSCR
		LDA &FDD7
		LDX &FDD6
		JSR set10
		STX &FDCA			;Restore Default drive and directory
		STA &FDCB
		STA &CF
		RTS
		
.SHbreak	JSR loadCAT
		LDY #&00
		LDX #&00
		JSR set0F
		LDA &FD06
		JSR mLSR4			;LSR A * 4
		BEQ x942C
		PHA
		LDX #LO(x993D)
		LDY #HI(x993D)
		JSR storeXY_F2			;Save X and Y at &F2 and &F3
		JSR procFNameR			;Process filename without resetting GSREAD
		JSR getCatFirst			;Get first entry in catalog that matches, C=1=found,Y=offset
		PLA
		BCS x942D
		JSR prtStr
		EQUS	"File not found"
		EQUB	&0D
		EQUB	&0D
		NOP

.x942C		RTS

.x942D		CMP #&02
		BCC x943F
		BEQ x9439
		LDX #LO(x993B)
		LDY #HI(x993B)
		BNE x9443

.x9439		LDX #LO(x993D)
		LDY #HI(x993D)
		BNE x9443

.x943F		LDX #LO(x9933)
		LDY #HI(x9933)

.x9443		PLA
		PLA
		JMP oscli
\
\
\************************************************
\** IRQ Service Routine for vdip
\** Removed temporarily to allow other programs use of the interrupt
\
;.servIRQ	RTS
;		
;		BIT vdipS			;Check the VNC1L
;		BMI serviceR1			;If data is not availalble, then it's not ours so exit
;		
;.servIRQ2	SEI				;Disable Interrputs
;		LDA vdip			;Load the byte, this automatically clears the IRQ
;		TAY
;		LDA #138
;		LDX #0
;		JSR osbyte			;Send it to the input buffer
;		BIT vdipS			;Check for more bytes available
;		BPL servIRQ2			;Loop if so
;		LDA #&81			;Setup IRQ and !DREQ
;		STA &FCF9			;and store
;		LDA #&00			;Claim the IRQ
;		CLI				;Re-Enable Interrupts
;		RTS				;and return
\
\
\
\**********************************
\** Main ROM Service entry point **
\**********************************
\
\************************************************
\** Service Entry - Call &01 - Absolute public workspace claim
\
.service01	;CMP #&05			;First check interrupts for speed
		;BEQ servIRQ			;If so, go service the IRQ
		CMP #&25			;Is it a Master Temp Filing System setup?
		BEQ service25			;Jump to that if so
		CMP #&01			;Is it claim Absolute workspace
		BNE service03			;Jump if not
		JSR setRam			;Now we initialise the RamFS Drives
		JSR doDtrapC			;And do the Disk Trap routine		

.serviceR1	RTS				;Then return with no claim.

.serviceR1x	PLA
		TAX
		PLA
		RTS

.service25	PHA
		TXA
		PHA
		JSR setSCR			;Set scratchram workspace
		LDA &FD8F			;Get DTRAP status
		BNE serviceR1x			;Ignore this call if active
		LDX #&00
.serv25lp	LDA fstable,X			;Copy the FS Table
		STA (&F2),Y			;To (&F2),Y
		INY
		INX
		CPX #&0B
		BNE serv25lp
		PLA
		TAX
		PLA
		
		RTS				;Registers will restore on exit
		
.fstable	EQUS	"RAM"
		EQUB	&20
		EQUB	&20
		EQUB	&20
		EQUB	&20
		EQUB	&20
		EQUB	chanBASE
		EQUB	chanBASE+4
		EQUB	ramFSID			;RamFS Filing System Number
\
\************************************************
\** Service call &03 - Auto boot
\
.service03	JSR saveAXY			;Save AXY
		CMP #&03			;Is it Call &03?
		BNE service04			;No, go to next
		JSR setSCR
		STY &FDD8			;Store boot option in Scratch RAM
		LDA #&7A			;Call OSBYTE with &7A
		JSR osbyte			;Scan keyboard
		TXA	
		BMI x9489			;No key pressed, accept call
		CMP #&33			;Check it for a "R"
		BNE serviceR1			;If not then RTS
		LDA #&78			;Write the key pressed back into buffer
		JSR osbyte

.x9489		JMP x9334
\
\************************************************
\** Service call &04 - Unrecognised * command
\
.service04	CMP #&04			;It it service call &04?
		BNE service12			;If not, then jump
		LDX #cmdTabDE-cmdTabD		;length of DFS command table - Was &72

.x9492		JMP x8630
\
\************************************************
\** Service call &12 - Initialise filing system
\
.service12	CMP #&12			;Is it service call &12?
		BNE service09			;Jump if not
		PHA
		JSR setSCR			;Set scratchram workspace
		LDA #ramFSID			;RamFS system filing type
		STA zpm0
		LDA &FD8F			;Check DiskTrap status
		BEQ service12a			;If not active, then jump
		LDA #diskFSID			;Else fool system into thinking Disk
		STA zpm0			;By responding to diskFSID

.service12a	PLA
		CPY zpm0			;RamFS is type 23 or Disk is 4, so is it our type of Filing System?
		BNE serviceR3			;Exit if not
		JMP cmdRam
\
\***************************
\** Service call &09 - *HELP
\
.service09	CMP #&09
		BNE service0A
		LDA (&F2),Y
		LDX #cmdTabUE-cmdTabD		;length of command table - Was &A0
		CMP #&0D
		BNE x9492
		TYA
		INX
		LDY #&02
		JMP x99BD
\
\************************************************
\** Service call &0A - Claim static workspace
\
.service0A	JSR stackClaim			;Change stacked A to &00
		CMP #&0A
		BNE service08

.serviceR3	RTS

.serviceR4S	TSX
		STA &0105,X
		RTS
\
\************************************************
\** Service call &08 - Unrecognised OSWORD
\
.service08	CMP #&08			;Is it an OSWORD?
		BNE serviceR4S			;If not, then return - with A preserved
		LDY &F0
		STY &B0				;Store X on entry at &B0
		LDY &F1
		STY &B1				;Store Y on entry at &B1
		LDY &EF				;Load A on entry
		CPY #&7F
		BEQ osword7F			;Jump if &7F to check DTRAP status
		CPY #&77
		BEQ osword77			;Jump and always obey
		CPY #&7D
		BNE serviceR4S
		JMP osword7D
\
\
\************************************************
\** OSWORD &7F Trapped when DTRAP active, otherwise ignored
\
.osword7F	JSR setSCR
		BIT &FD8F
		BMI osword77
.osword7F_R	JMP serviceR4S			;Return unclaiming the call, was RTS
\
\
\************************************************
\** OSWORD &77 Used as RAMFS sector Xfer Routine
\
.osword77	JSR saveAXY
		LDY #&00
		LDA (&B0),Y			;Get first byte of parameter block - Drive number
		BMI osw77_J1			;If >128, then use previous drive number
		JSR setDrvCF			;CLI, validate drive number AND#07, and store it at &CF
		
.osw77_J1	LDY #&06
		LDA (&B0),Y
		PHA
		CMP #&53
		BEQ osw77_RW			;Jump if OSWORD &7F command is &53
		CMP #&4B
		BEQ osw77_RW
		PLA
		RTS
\
\
\************************************************
\** OSWORD &77 - Commands &4B (Write) & &53 (Read)
\
.osw77_RW	LDY #&01
		LDA (&B0),Y
		STA &BE				;Save Buffer Address
		INY
		LDA (&B0),Y
		STA &BF
		INY
		JSR set10
		LDA (&B0),Y
		STA &FD74			;Save upper bytes for Tube
		INY
		LDA (&B0),Y
		STA &FD75
		LDY #&07
		LDA (&B0),Y
		STA zpm2			;Save track number
		INY
		LDA (&B0),Y
		STA zpm3			;Save sector number
		LDY #&00
		STY &C4				;Zero other locations
		STY &C5
		STY &C2
		
.osw77_RW2	LDA &C5				;Multiply track number by 10
		CLC
		ADC zpm2
		STA &C5
		LDA &C4
		ADC #&00
		STA &C4
		INY
		CPY #10
		BNE osw77_RW2
		LDA &C5
		CLC
		ADC zpm3			;Then add the sector number for 16 bit sector address
		STA &C5
		LDA &C4
		ADC #&00
		STA &C4
		LDY #&09
		LDA (&B0),Y
		AND #&0F
		STA &C3				;Store sector count
		INY
		LDA #&00
		STA (&B0),Y			;Set sucessful completion result
		PLA
		CMP #&4B
		BEQ osw77_RW3
		JMP readRAMblock
		
.osw77_RW3	JMP writeRAMblock
\
\
\************************************************
\** OSWORD &7D
\
.osword7D	JSR setDirDrv			;Set up Drive and Directories, checks for FDC Idle
		JSR loadCAT			;x8306
		CPY #&7E
		BEQ x9559
		LDY #&00
		JSR set0F
		LDA &FD04
		STA (&B0),Y
		RTS

.x9559		LDA #&00
		TAY
		STA (&B0),Y
		INY
		JSR set0F
		LDA &FD07
		STA (&B0),Y
		INY
		LDA &FD06
		AND #&03
		STA (&B0),Y
		INY
		LDA #&00
		STA (&B0),Y
		RTS
\
\
\************************************************
\** Start of OSFILE
\
.x9572		JSR x83D0
		PHA
		JSR staFF_10CF			;?&10CF=&FF
		STX &B0				;Save address of OSFILE parameter block
		JSR set10
		STX &FDDC
		STY &B1
		STY &FDDD
		LDX #&00
		LDY #&00
		JSR x80C8			;Copy Address of filename to &BCBD

.x958A		JSR x80B8
		CPY #&12
		BNE x958A
		PLA				;Recall OSFILE Command
		TAX
		INX				;Add 1 to it
		CPX #&08			;Is it in range 0-7?
		BCS x95A0			;Exit if not
		LDA x9980,X			;Get jump table
		PHA				;and put it on stack
		LDA x9978,X
		PHA

.x95A0		RTS				;Jump to table
\
\************************************************
\** Start of OSFSC Routine
\
.x95A1		CMP #&0B
		BCS x95A0
		STX &B5
		TAX
		LDA x996F,X			;Load jump table
		PHA
		LDA x9966,X
		PHA
		TXA
		LDX &B5

.x95B3		RTS				;Jump to table
\
\************************************************
\** Start of OSGBPB Routine
\
.x95B4		CMP #&09			;Check call is supported 0-8
		BCS x95B3			;Exit if not
		JSR saveAXY			;Save registers
		JSR stackClaim			;Change stacked A to &00
		JSR set10
		STX &FD7D			;Store LSB of control block
		STY &FD7E			;Store MSB of control block
		TAY
		TSX
		LDA #&00
		STA &0105,X
		LDA x999D,Y			;Setup Jump Table
		STA &FDD8
		LDA x99A6,Y
		STA &FDD9
		LDA x99AF,Y
		LSR A
		PHP
		LSR A
		PHP
		STA &FD7F
		JSR x973D
		LDY #&0C

.x95E6		LDA (&B4),Y
		JSR set10
		STA &FD60,Y
		DEY
		BPL x95E6
		LDA &FD63
		AND &FD64
		ORA &FDD7
		CLC
		ADC #&01
		BEQ x95FE
		LDA #&FF

.x95FE		JSR set10
		STA &FD81
		LDA &FD7F
		BCS x960D
		LDX #&61
		LDY #&FD			;#&10
		JSR &0406			;Tube Call

.x960D		PLP
		BCS x9614
		PLP

.x9611		JSR set10
		JMP (&FDD8)
\
\
\
.x9614		LDX #&03

.x9616		JSR set10
		LDA &FD69,X
		STA &B6,X
		DEX
		BPL x9616
		LDX #&B6
		LDY &FD60
		LDA #&00
		PLP
		BCS x962B
		JSR x92A9

.x962B		JSR x9037
		LDX #&03

.x9630		LDA &B6,X
		JSR set10
		STA &FD69,X
		DEX
		BPL x9630

.x9638		JSR x972F
		BMI x964A

.x963D		JSR set10
		LDY &FD60
		JSR x9611
		BCS x9652
		LDX #&09
		JSR x9723

.x964A		LDX #&05
		JSR x9723
		BNE x963D
		CLC

.x9652		PHP
		JSR x972F
		LDX #&05
		JSR x9723
		LDY #&0C
		JSR x973D

.x9660		JSR set10
		LDA &FD60,Y
		STA (&B4),Y
		DEY
		BPL x9660
		PLP
		RTS
\
\
\************************************************
\** OSGBPB = 8 - Get filenames
\
.x966A		JSR setDirDrv			;Set up Drive and Directories, checks for FDC Idle
		CMP #&05			;Check drive is in range 0-4
		BCC x966A_J
		JMP errBadDrv			;Go bad drive if it is not

.x966A_J	JSR loadCAT
		JSR set10
		LDA #LO(x967C)
		STA &FDD8
		LDA #HI(x967C)
		STA &FDD9
		BNE x9638
\
\
\
.x967C		LDY &FD69

.x967F		JSR set0F
		CPY &FD05
		BCS x96AC
		JSR set0E
		LDA &FD0F,Y
		JSR chkAlphaChar		;Check if it's a character
		EOR &CE
		BCS x9690
		AND #&DF

.x9690		AND #&7F
		BEQ x9699
		JSR mINY8
		BNE x967F

.x9699		LDA #&07
		JSR x9751
		STA &B0

.x96A0		JSR set0E
		LDA &FD08,Y
		JSR x9751
		INY
		DEC &B0
		BNE x96A0
		CLC

.x96AC		JSR set10
		STY &FD69
		JSR set0FS
		LDA &FD04
		JSR set10S
		STA &FD60
		RTS
\
\
\************************************************
\** OSGBPB = &05 - Get media title
\
.x96B6		JSR setDirDrv			;Set up Drive and Directories, checks for FDC Idle
		CMP #&05			;Check drive is in range 0-4
		BCC x96B6_J
		JMP errBadDrv			;Go bad drive if it is not

.x96B6_J	JSR loadCAT
		LDA #&0C
		JSR x9751
		LDY #&00

.x96C3		JSR set0E
		LDA &FD00,Y
		JSR x9751
		INY
		CPY #&08
		BNE x96C3

.x96CE		JSR set0F
		LDA &FCF8,Y
		JSR x9751
		INY
		CPY #&0C
		BNE x96CE
		JSR set0F
		LDA &FD06
		JSR mLSR4			;LSR A * 4
		JSR x9751
		LDA &CF
		JMP x9751
\
\
\************************************************
\** OSGBPB &06
\
.x96E7		JSR x9748
		JSR set10
		LDA &FDCB			;Default General Purpose Drive
		ORA #&30
		JSR x9751
		JSR x9748
		JSR set10
		LDA &FDCA			;Current Default Directory
		JMP x9751
\
\
\
.x96FB		JSR x9748
		JSR set10
		LDA &FDCD
		ORA #&30
		JSR x9751
		JSR x9748
		JSR set10
		LDA &FDCC
		JMP x9751
\
\
\
.x970F		PHA
		JSR set10
		LDA &FD61
		STA &B8
		LDA &FD62
		STA &B9
		LDX #&00
		PLA
		RTS
\
\
\
.x971E		JSR saveAXY
		LDX #&01

.x9723		LDY #&04
		JSR set10

.x9725		INC &FD60,X
		BNE x972E
		INX
		DEY
		BNE x9725

.x972E		RTS
\
\
\
.x972F		LDX #&03
		JSR set10

.x9731		LDA #&FF
		EOR &FD65,X
		STA &FD65,X
		DEX
		BPL x9731
		RTS
\
\
\
.x973D		JSR set10
		LDA &FD7D
		STA &B4
		LDA &FD7E
		STA &B5

.x9747		RTS
\
\
\
.x9748		LDA #&01
		BNE x9751
\
\
\************************************************
\** OSGBPB &03 - Get bytes from media using seq pointer
\
.x974C		JSR x90C6
		BCS x9747

.x9751		JSR set10
		BIT &FD81			;Tube Flag
		BPL x975C			;Skif if not set
		STA &FEE5			;Send to tube
		JMP x971E

.x975C		JSR x970F			;No Tube
		STA (&B8,X)			;MAY NEED A HACK?!?!?!?!?!?
		JMP x971E
\
\
\************************************************
\** OSGBPB &02 - Put bytes to media using seq pointer
\
.x9764		JSR x976C
		JSR x91AC
		CLC
		RTS

.x976C		JSR set10
		BIT &FD81
		BPL x9777
		LDA &FEE5
		JMP x971E

.x9777		JSR x970F
		LDA (&B8,X)			;AGAIN NEED A HACK?????!?!?!?!?!
		JMP x971E
\
\
\************************************************
\** OSFSC &08 - *ENABLE check
\
.osfsc_08	JSR set10
		BIT &FDC8
		BMI x9787
		DEC &FDC8

.x9787		RTS
\
\
\************************************************
\** OSFILE &05 - Read a files catalog info
\
.osfile_05	JSR x9841
		JSR readFileAttr		;Read file attributes
		LDA #&01
		RTS
\
\
\************************************************
\** OSFILE &06 - Delete file
\
.osfile_06	JSR x981E
		JSR readFileAttr		;Read file attributes
		JSR deleteCatFN			;Delete filename at Y from catalog
		BCC x97C0
\
\
\************************************************
\** OSFILE &01 - Write Catalog info
\
.osfile_01	JSR x981E
		JSR x97C6
		JSR x97E2
		BVC x97BD
\
\
\************************************************
\** OSFILE &02 - Write Load address
\
.osfile_02	JSR x981E
		JSR x97C6
		BVC x97C0
\
\
\************************************************
\** OSFILE &03 - Write Execution address
\
.osfile_03	JSR x981E
		JSR x97E2
		BVC x97C0
\
\
\************************************************
\** OSFILE &04 - Write Attributes
\
.osfile_04	JSR x9841
		JSR x9836

.x97BD		JSR x9805

.x97C0		JSR x887D
		LDA #&01
		RTS

.x97C6		JSR saveAXY
		JSR set0F
		LDY #&02
		LDA (&B0),Y
		STA &FD08,X
		INY
		LDA (&B0),Y
		STA &FD09,X
		INY
		LDA (&B0),Y
		ASL A
		ASL A
		EOR &FD0E,X
		AND #&0C
		BPL x97FD

.x97E2		JSR saveAXY
		JSR set0F
		LDY #&06
		LDA (&B0),Y
		STA &FD0A,X
		INY
		LDA (&B0),Y
		STA &FD0B,X
		INY
		LDA (&B0),Y
		ROR A
		ROR A
		ROR A
		EOR &FD0E,X
		AND #&C0

.x97FD		EOR &FD0E,X
		STA &FD0E,X
		CLV
		RTS
\
\************************************************
\
.x9805		JSR saveAXY
		LDY #&0E
		LDA (&B0),Y
		AND #&0A
		BEQ x9812
		LDA #&80

.x9812		JSR set0E
		EOR &FD0F,X
		AND #&80
		EOR &FD0F,X
		STA &FD0F,X
		RTS
\
\***********************************************
\
.x981E		JSR x984B
		PHP
		JSR chkDrv5
		PLP
		BCC x9846

.x9823		JSR set0E
		LDA &FD0F,Y
		BPL x984A

.x9828		JSR errFile			;Error "File locked"
		EQUB	&C3
		EQUB	"locked"
		BRK

.x9833		JSR x9823

.x9836		JSR saveAXY
		JSR x8F83
		BCC x985F
		JMP x8EE7

.x9841		JSR x984B
		BCS x985F

.x9846		PLA
		PLA
		LDA #&00

.x984A		RTS
\
\
\
.x984B		JSR procFName
		JSR getCatFirst			;Get first entry in catalog that matches, C=1=found,Y=offset
		BCC x985F
		TYA
		TAX

.x9855		JSR set10
		LDA &FDDC
		STA &B0
		LDA &FDDD
		STA &B1

.x985F		RTS
\
\
\************************************************
\** Setup value of PAGE and HIMEM
\
.setupPAHI	LDA #&83
		JSR osbyte
		JSR set10
		STY &FDD0
		LDA #&84
		JSR osbyte
		TYA
		SEC
		SBC &FDD0
		STA &FDD1
		RTS
\
\
\************************************************
\** OSBYTE Routines
\
.osbyte_0F	JSR saveAXY			;Save registers
		LDA #&0F			;*FX 15 (&0F) - Flush input buffer
		LDX #&01

.osbyteJ1	LDY #&00
		BEQ osbyteJ

.osbyte_C7W	LDA #&C7			;*FX 199 (&C7) - Write *SPOOL file handle (0)
		LDX #&00
		BEQ osbyteJ1

.osbyte_03X	TAX				;*FX 3 with A transferred to X

.osbyte_03	LDA #&03			;*FX 3 (&03) - Select output stream
		BNE osbyteJ

.osbyte_7E	JSR saveAXY			;Save registers
		LDA #&7E			;*FX 126 (&7E) - Acknowledge escape condition
		BNE osbyteJ

.osbyte_EC	LDA #&EC			;*FX 236 (&EC) - Read character destination status
		BNE osbyteXY

.osbyte_C7R	LDA #&C7			;*FX 199 (&C7) - Read *SPOOL file handle
		BNE osbyteXY

.osbyte_EA	LDA #&EA			;*FX 234 (&EA) - Read Tube presence flag
		BNE osbyteXY

.osbyte_A8	LDA #&A8			;*FX 168 (&A8) - Read address of ROM pointer table
		BNE osbyteXY

.osbyte_8F	LDA #&8F			;*FX 143 (&8F) - Issue paged ROM service request
		BNE osbyteJ

.osbyte_FF	LDA #&FF			;*FX 255 (&FF) - Start up options

.osbyteXY	LDX #&00

.osbyteY	LDY #&FF

.osbyteJ	JMP osbyte
\
\
\************************************************
\** Boot up Command Table
\
.x9933  	EQUS	"L.!BOOT"
		EQUB	&0D
		
.x993B		EQUS	"E."

.x993D		EQUS	"!BOOT"
		EQUB	&0D
\
\
\************************************************
\** Vectors
\
.x9943		EQUW	&FF1B			;&212 - FILEV - All file loads and saves passed thru here
		EQUW	&FF1E			;&214 - ARGSV - All calls of OSARGS
		EQUW	&FF21			;&216 - BGETV - Read one byte from a file
		EQUW	&FF24			;&218 - BPUTV - Put one buyte into a file
		EQUW	&FF27			;&21A - GBPBV - Get/Put block of bytes into/from a file
		EQUW	&FF2A			;&21C - FINDV - Open/Close a file
		EQUW	&FF2D			;&21E - FSCV - Various FS control
		
.x9951		EQUW	x9572			;FILEV - OSFILE
		BRK
		EQUW	OSargs			;ARGSV - OSARGS
		BRK
		EQUW	x90C6			;BGETV - OSBGET
		BRK
		EQUW	x91AC			;BPUTV - OSBPUT
		BRK
		EQUW	x95B4			;GBPBV - OSGBPB
		BRK
		EQUW	x8E78			;FINDV - OSFIND
		BRK
		EQUW	x95A1			;FSCV - OSFSC
		BRK
\
\
\************************************************
\** OSFSC Vectors
\
.x9966		EQUB	LO(osfsc_00-1)		;OSFSC &00 (&88D6) - *OPT command
		EQUB	LO(osfsc_01-1)		;OSFSC &01 (&9092) - Check EOF
		EQUB	LO(osfsc_02-1)		;OSFSC &02 (&878E) - */ command
		EQUB	LO(osfsc_03-1)		;OSFSC &03 (&862B) - Unrecognised OS command
		EQUB	LO(osfsc_02-1)		;OSFSC &04 (&878E) - *RUN command
		EQUB	LO(osfsc_05-1)		;OSFSC &05 (&83DD) - *CAT command
		EQUB	LO(osfsc_06-1)		;OSFSC &06 (&8DAB) - New FS about to take over
		EQUB	LO(osfsc_07-1)		;OSFSC &07 (&8DA6) - Request file handles
		EQUB	LO(osfsc_08-1)		;OSFSC &08 (&977F) - *ENABLE check
		EQUB	LO(osfsc_09-1)		;OSFSC &09 (&8DA6) - *EX
		EQUB	LO(osfsc_0A-1)		;OSFSC &0A (&977F) - *INFO

.x996F		EQUB	HI(osfsc_00-1)
		EQUB	HI(osfsc_01-1)
		EQUB	HI(osfsc_02-1)
		EQUB	HI(osfsc_03-1)
		EQUB	HI(osfsc_02-1)
		EQUB	HI(osfsc_05-1)
		EQUB	HI(osfsc_06-1)
		EQUB	HI(osfsc_07-1)
		EQUB	HI(osfsc_08-1)
		EQUB	HI(osfsc_09-1)
		EQUB	HI(osfsc_0A-1)
\
\
\************************************************
\** OSFILE Vectors
\
.x9978		EQUB	LO(osfile_FF-1)		;OSFILE &FF (&874E) - Load the named File
		EQUB	LO(osfile_00-1)		;OSFILE &00 (&8740) - Save block of memory
		EQUB	LO(osfile_01-1)		;OSFILE &01 (&979C) - Write catalog info
		EQUB	LO(osfile_02-1)		;OSFILE &02 (&97A7) - Write Load Address
		EQUB	LO(osfile_03-1)		;OSFILE &03 (&97AF) - Write Execution Address
		EQUB	LO(osfile_04-1)		;OSFILE &04 (&97B7) - Write Attributes
		EQUB	LO(osfile_05-1)		;OSFILE &05 (&9788) - Read files catalog info
		EQUB	LO(osfile_06-1)		;OSFILE &06 (&9791) - Delete File

.x9980		EQUB	HI(osfile_FF-1)
		EQUB	HI(osfile_00-1)
		EQUB	HI(osfile_01-1)
		EQUB	HI(osfile_02-1)
		EQUB	HI(osfile_03-1)
		EQUB	HI(osfile_04-1)
		EQUB	HI(osfile_05-1)
		EQUB	HI(osfile_06-1)
\
\
\*****************
\** OSGBPB Vectors
\
.x999D		EQUB	LO(cmdRTS)		;OSGBPB &00 - Ignore, RTS
		EQUB	LO(x9764)		;OSGBPB &01 - Put bytes to media using seq pointer
		EQUB	LO(x9764)		;OSGBPB &02 - Put bytes to media ignoring pointer
		EQUB	LO(x974C)		;OSGBPB &03 - Get bytes from media using seq pointer
		EQUB	LO(x974C)		;OSGBPB &04 - Get bytes from media ignoring pointer
		EQUB	LO(x96B6)		;OSGBPB &05 - Get media title and boot up option
		EQUB	LO(x96E7)		;OSGBPB &06 - Read currently selected directory and device
		EQUB	LO(x96FB)		;OSGBPB &07 - Read currently selected library
		EQUB	LO(x966A)		;OSGBPB &08 - Read file names from directory
		
.x99A6		EQUB	HI(cmdRTS)
		EQUB	HI(x9764)
		EQUB	HI(x9764)
		EQUB	HI(x974C)
		EQUB	HI(x974C)
		EQUB	HI(x96B6)
		EQUB	HI(x96E7)
		EQUB	HI(x96FB)
		EQUB	HI(x966A)

.x99AF		EQUB	&04
		EQUB	&02
		EQUB	&03
		EQUB	&06
		EQUB	&07
		EQUB	&04
		EQUB	&04
		EQUB	&04
		EQUB	&04
\
\
\************************************************
\** Start of *HELP routines
\
.help_NOramfs	LDA #&81
		JSR prtChrA
		JSR prtStr
		EQUB	" Not Detected"
		EQUB	&0D
		NOP
		JMP dt_skip
\
\
\************************************************
\** *HELP RFS command
\
.helpRFS	TYA
		LDX #&FF			;Offset in table where commands start-1
		LDY #&10			;Number of commands in table to print
\
\
\************************************************
\** *HELP Command
\
.x99BD		PHA
		STX zpm0
		STY zpm1
		JSR prtStr
		EQUB	&0D
		EQUS	"RetroClinic RamFS 1.00"
		EQUB	&0D
		NOP
		JSR setSCR
		LDY #&00
		
.help_L1	LDA &FD80,Y			;Load BOOT check area
		CMP cpyMsg,Y			;Is the (C) message stored there?
		BNE help_NOramfs		;if not, then there's no RAMFS present
		INY
		CPY #&0F
		BNE help_L1		
		LDA &FD8F
		BEQ dt_skip
		LDA #&83
		JSR prtChrA
		JSR prtStr
		EQUS	" DiskTrap Active"
		EQUB	&0D
		NOP
		
.dt_skip	LDX zpm0
		LDY zpm1
		STX &B8
		
.x99CD		LDA #&00
		STA &B9
		JSR prtChr20x2			;Print 2 Spaces
		JSR x9A15
		JSR prtChr0D
		DEY
		BNE x99CD
		PLA
		TAY

.x99DF		LDX #cmdTabUE-cmdTabD		;Was &A0 - length of command table
		JMP x8630
\
\
\************************************************
\** *HELP UTILS command
\
.helpUTILS	TYA
		LDX #cmdTabU-cmdTabD-1		;Offset in table where UTILS commands start-1
		LDY #&0A			;Number of commands in table to print
		BNE x99BD
\
\
\
.x99EB		JSR gsinitCLC			;JSR gsinit with CLC
		BEQ x9A56

.x99F0		JSR gsread
		BCC x99F0
		BCS x99DF
\
\
\************************************************
\** Get next argument from command line
\
.getNextArg	JSR gsinitCLC			;JSR gsinit with CLC
		BNE x9A56

.x99FC		JSR errARG
		EQUB	&DC
		EQUS	"Syntax: " 
		STX &B9
		JSR x9A15
		LDA #&00
		JSR x9A57
		JMP &0100

.x9A15		LDX &B8

.x9A17		INX
		LDA cmdTabD,X
		BMI x9A23
		JSR x9A57
		JMP x9A17

.x9A23		INX
		INX
		STX &B8
		LDA cmdTabD,X
		JSR x9A30
		JSR mLSR4			;LSR A * 4

.x9A30		JSR saveAXY
		AND #&0F
		BEQ x9A56
		TAY
		LDA #&20
		JSR x9A57
		LDX #&00

.x9A3F		LDA x9A67,X
		BEQ x9A47

.x9A44		INX
		BNE x9A3F

.x9A47		DEY
		BNE x9A44

.x9A4A		INX
		LDA x9A67,X
		BEQ x9A56
		JSR x9A57
		JMP x9A4A

.x9A56		RTS

.x9A57		JSR saveAXY
		LDX &B9
		BEQ x9A64
		INC &B9
		STA &0100,X
		RTS

.x9A64		JMP prtChrA
\
\
\************************************************
\** Help Expansion table
\
.x9A67		BRK
		EQUS	"<fsp>"
		BRK
		EQUS	"<afsp>"
		BRK
		EQUS	"(L)"
		BRK
		EQUS	"<src drv>"
		BRK
		EQUS	"<dest drv>"
		BRK
		EQUS	"<dest drv> <afsp>"
		BRK
		EQUS	"<old fsp>"
		BRK
		EQUS	"<new fsp>"
		BRK
		EQUS	"(<dir>)"
		BRK
		EQUS	"(<drv>)"
		BRK
		EQUS	"<title>"
		BRK
		
\
\
\************************************************
\** *COMPACT command
\
.cmdCompact	JSR gsinitCLC_D			;Setup Default Drive with a CLC call to gsinit
		JSR chkDrv5			;This command not allowed on the USB, so check for Drive 5
		JSR prtStr
		EQUS	"Compacting drive "
		NOP
		JSR set10
		STA &FDD2
		STA &FDD3
		JSR prtHexA4bit
		JSR prtChr0D
		LDY #&00

.x9AF1		JSR x8DCE
		JSR setupPAHI			;Setup value of PAGE and HIMEM
		JSR loadCAT
		JSR set0F
		LDY &FD05
		STY &CC
		LDA #&02
		STA &CA
		LDA #&00
		STA &CB

.x9B07		LDY &CC
		JSR mDEY8			;DEY x 8
		CPY #&F8
		BNE x9B4B
		JSR prtStr
		EQUS	"Disk compacted "
		NOP
		JSR set0F
		SEC
		LDA &FD07
		SBC &CA
		PHA
		LDA &FD06
		AND #&03
		SBC &CB
		JSR prtHexA4bit
		PLA
		JSR prtHexA8bit
		JSR prtStr
		EQUS	" free sectors"
		EQUB	&0D
		NOP
		RTS

.x9B4B		STY &CC
		JSR x82BB
		LDY &CC
		JSR set0F
		LDA &FD0E,Y
		AND #&30
		ORA &FD0D,Y
		ORA &FD0C,Y
		BEQ x9BC0
		LDA #&00
		STA &BE
		STA &C2
		LDA #&FF
		CLC
		ADC &FD0C,Y
		LDA #&00
		ADC &FD0D,Y
		STA &C6
		LDA &FD0E,Y
		PHP
		JSR mLSR4_AND3			;LSR A * 4, then AND &03
		PLP
		ADC #&00
		STA &C7
		LDA &FD0F,Y
		STA &C8
		LDA &FD0E,Y
		AND #&03
		STA &C9
		CMP &CB
		BNE x9BA2
		LDA &C8
		CMP &CA
		BNE x9BA2
		CLC
		ADC &C6
		STA &CA
		LDA &CB
		ADC &C7
		STA &CB
		JMP x9BC0

.x9BA2		LDA &CA
		STA &FD0F,Y
		LDA &FD0E,Y
		AND #&FC
		ORA &CB
		STA &FD0E,Y
		LDA #&00
		STA &A8
		STA &A9
		JSR x9E04
		JSR saveCAT

.x9BC0		LDY &CC
		JSR prtFNattr			;Print Filename and attributes
		JMP x9B07
\
\
\************************************************
\** Enable Check
\
.chkEnable	JSR set10
		BIT &FDC8
		BPL chkErts2
.chkAlways	JSR prtStr
		EQUS	"Go (Y/N) ? "
		NOP
		JSR osbyte_0F			;*FX15 - Flush input buffer
		JSR osrdch
		AND #&DF
		CMP #&59			;Does A="Y"
		BEQ chkErts
		JSR errARG
		EQUB	&BD
		EQUS	"Not enabled"
		BRK
.chkErts	JSR prtChr0D
.chkErts2	RTS
\
\
\
.getCopyD	JSR getNextArg			;Get next argument from command line
		JSR getDrv
		JSR set10
		STA &FDD2
		JSR getNextArg			;Get next argument from command line
		JSR getDrv
		JSR set10
		STA &FDD3
		CMP &FDD2			;Added so RAM cant copy drive onto itself
		BNE notBadDrv
		JMP errBadDrv
.notBadDrv	TYA
		PHA
		LDA #&00
		STA &A9
		JSR set10
		LDA &FDD3
		CMP &FDD2
		BNE prtCopyD
		LDA #&FF
		STA &A9
		STA &AA

.prtCopyD	JSR setupPAHI			;Setup value of PAGE and HIMEM
		JSR prtStr
		EQUS	"Copying from drive "
		NOP
		JSR set10
		LDA &FDD2
		JSR prtHexA4bit
		JSR prtStr
		EQUS	" to drive "
		NOP
		LDA &FDD3
		JSR prtHexA4bit
		JSR prtChr0D
		PLA
		TAY
		CLC

.x9C3B		RTS
\
\
\************************************************
\** Print 2 Carriage Returns
\
.prtChr0Dx2	JSR prtChr0D
\
\
\************************************************
\** Print Carriage Return
\
.prtChr0D	PHA
		LDA #&0D
		JSR prtChrA
		PLA
		RTS
\
\
\
.x9CA7		JSR osbyte_0F			;*FX15 - Flush input buffer
		JSR osrdch
		BCS x9CBD
		AND #&5F
		CMP #&59
		PHP
		BEQ x9CB8
		LDA #&4E

.x9CB8		JSR prtChrA
		PLP
		RTS

.x9CBD		JMP errEsc

.errDiskFull2	JMP errDiskFull
\
\
\************************************************
\** *BACKUP command
\
.cmdBackup	JSR chkEnable
		JSR getCopyD			;Get drives and print. Src=&10D2, Dest=&10D3
		LDA #&00
		STA &C9
		STA &CB
		STA &CA
		STA &C8
		STA &A8
						;JSR x9C3C
		JSR set10
		LDA &FDD2			;Load source drive
		JSR chkDrv5A			;Check for Drive 5 in A	
		JSR loadCAT			;Load source disk catalog
		JSR set0F
		LDA &FD07			;Load LSB of disk sectors
		STA &C6				;Store at &C6
		LDA &FD06			;Load MSB of disk sectors
		AND #&03			;Mask so only sector count is left
		STA &C7				;Store at &C7
		LDA &FD06			;Load MSB of disk sectors again
		AND #&F0			;Mask off boot option
		JSR set10
		STA &FDD8			;Store at &10D8
						;JSR x9C47
		LDA &FDD3			;Load destination drive
		STA &CF				;Store in &CF
		JSR chkDrv5A			;Check for Drive 5 in A
		JSR loadCAT			;Load destination catalog
		JSR set0F
		LDA &FD06			;Load destination disk size MSB
		AND #&03			;Mask off sector data
		CMP &C7				;Compare with source
		BCC errDiskFull2		;Error if not big enough
		BNE x9D11			;Jump if sector size radically different
		LDA &FD07			;Load sector MSB
		CMP &C6				;Compare with source disk
		BCC errDiskFull2		;Again, error if not big enough

.x9D11		JSR x9E04
		JSR set0F
		LDA &FD06
		PHA
		LDA &FD07
		PHA
		JSR loadCAT
		PLA
		JSR set0F
		STA &FD07
		JSR set10S
		PLA
		AND #&0F
		ORA &FDD8
		JSR set0FS
		STA &FD06
		JMP saveCAT
\
\
\************************************************
\** *COPY command
\
.cmdCopy	JSR sta23_10CF			;?&10CF=&23
		JSR getCopyD			;Get drives and print. Src=&10D2, Dest=&10D3
		JSR set10
		LDA &FDD2
		JSR chkDrv5A			;Check for Drive 5 in A
		LDA &FDD3
		JSR chkDrv5A			;Check for Drive 5 in A
		JSR getNextArg			;Get next argument from command line
		JSR procFNameR			;Process filename without resetting GSREAD
		;JSR x9C3C			;Source/dest selection NOT NEEDED
		JSR set10
		LDA &FDD2
		JSR setDrvCF			;CLI and check drive idle, validate drive number AND#03, and store it at &CF
		JSR getCatFirstE		;Check first filename in catalog, and error if not present

.x9D47		STY &AB				;Store offset of file
		JSR prtFNattr			;Print Filename and attributes
		LDX #&00

.x9D4E		LDA &C7,X
		JSR set10
		STA &FD58,X
		JSR set0ES
		LDA &FD08,Y
		STA &C7,X
		JSR set10S
		STA &FD50,X
		JSR set0FS
		LDA &FD08,Y
		STA &BD,X
		JSR set10S
		STA &FD47,X
		INX
		INY
		CPX #&08
		BNE x9D4E
		LDA &C3
		JSR mLSR4_AND3			;LSR A * 4, then AND &03
		STA &C5
		LDA &C1
		CLC
		ADC #&FF
		LDA &C2
		ADC #&00
		STA &C6
		LDA &C5
		ADC #&00
		STA &C7
		JSR set10S
		LDA &FD4E
		STA &C8
		LDA &FD4D
		AND #&03
		STA &C9
		LDA #&FF
		STA &A8
		JSR x9E04
						;JSR x9C3C
		JSR set10
		LDA &FDD2
		JSR setDrvCF			;CLI and check drive idle, validate drive number AND#03, and store it at &CF
		JSR loadCAT			;x8306
		LDX #&07

.x9DA2		JSR set10
		LDA &FD58,X
		STA &C7,X
		DEX
		BPL x9DA2
		LDY &AB
		STY &FDCE
		JSR getCatNext			;Get next entry in catalog that matches, C=1=found,Y=offset
		BCC x9DB4
		JMP x9D47
.x9DB4		RTS

.x9DB5		JSR x9DF3
						;JSR x9C47
		JSR set10
		LDA &FDD3
		STA &CF
		LDA &CE
		PHA
		JSR loadCAT			;x8306
		JSR getCatFirst			;Get first entry in catalog that matches, C=1=found,Y=offset
		BCC x9DCE
		JSR deleteCatFN			;Delete filename at Y from catalog

.x9DCE		PLA
		STA &CE
		JSR setLoadTU			;Set Load address pointers for Tube
		JSR setExecTU			;Set Execution address pointers for Tube
		LDA &C4
		JSR mLSR4_AND3			;LSR A * 4, then AND &03
		STA &C6
		JSR x8957
		LDA &C4
		AND #&03
		PHA
		LDA &C5
		PHA
		JSR x9DF3
		PLA
		STA &CA
		PLA
		STA &CB
		RTS

.x9DF3		LDX #&11

.x9DF5		JSR set10
		LDA &FD45,X
		LDY &BC,X
		STA &BC,X
		TYA
		STA &FD45,X
		DEX
		BPL x9DF5
		RTS
\
\
\
.x9E04		LDA #&00
		STA &BE				;Store 0 in LSB of address
		STA &C2				;Store 0 in LSB of length

.x9E0A		LDA &C6
		TAY
		JSR set10
		CMP &FDD1
		LDA &C7
		SBC #&00
		BCC x9E19
		LDY &FDD1

.x9E19		STY &C3
		LDA &C8
		STA &C5
		LDA &C9
		STA &C4
		JSR set10
		LDA &FDD0
		STA &BF
		LDA &FDD2
		STA &CF
		JSR x8B90
		JSR readRAMblock
		JSR set10
		LDA &FDD3
		STA &CF
		BIT &A8
		BPL x9E49
		JSR x9DB5
		LDA #&00
		STA &A8

.x9E49		LDA &CA
		STA &C5
		LDA &CB
		STA &C4
		JSR set10
		LDA &FDD0
		STA &BF
		JSR x8B90
		JSR writeRAMblock
		JSR x8B90
		LDA &C3
		CLC
		ADC &CA
		STA &CA
		BCC x9E6D
		INC &CB

.x9E6D		LDA &C3
		CLC
		ADC &C8
		STA &C8
		BCC x9E78
		INC &C9

.x9E78		SEC
		LDA &C6
		SBC &C3
		STA &C6
		BCS x9E83
		DEC &C7

.x9E83		ORA &C7
		BNE x9E0A
		RTS
\
\
\************************************************
\** *TYPE command
\
.cmdType	JSR x9FD1
		LDA #&00
		BEQ x9E94
\
\
\************************************************
\** *LIST command
\
.cmdList	JSR x9FD1
		LDA #&FF

.x9E94		JSR chkDrv5			;Check for Drive 5 with AND #&07
		STA &AB
		LDA #&40
		JSR osfind
		TAY
		LDA #&0D
		CPY #&00
		BNE x9EC0

.x9EA2		JMP x8235
\
\
\
.x9EA5		JSR osbget
		BCS x9EC8
		CMP #&0A
		BEQ x9EA5
		PLP
		BNE x9EB9
		PHA
		JSR x9F9C
		JSR prtChr20
		PLA

.x9EB9		JSR osasci
		BIT &FF
		BMI x9EE5

.x9EC0		AND &AB
		CMP #&0D
		PHP
		JMP x9EA5

.x9EC8		PLP
		JSR prtChr0D

.x9ECC		LDA #&00
		JMP osfind
\
\
\************************************************
\** *DUMP command
\
.cmdDump	JSR x9FD1
		JSR chkDrv5			;Check for Drive 5 in A
		LDA #&40
		JSR osfind
		TAY
		BEQ x9EA2
		LDX &F4
		LDA &0DF0,X
		STA &AD
		INC &AD

.x9EE5		BIT &FF
		BMI x9F49
		LDA &A9
		JSR prtHexA8bit
		LDA &A8
		JSR prtHexA8bit
		JSR prtChr20
		LDA #&07
		STA &AC
		LDX #&00

.x9EFC		JSR osbget
		BCS x9F0E
		STA (&AC,X)
		JSR prtHexA8bit
		JSR prtChr20
		DEC &AC
		BPL x9EFC
		CLC

.x9F0E		PHP
		BCC x9F1F

.x9F11		JSR prtStr
		EQUS	"** "
		LDA# &00
		STA (&AC,X)
		DEC &AC
		BPL x9F11

.x9F1F		LDA #&07
		STA &AC

.x9F23		LDA (&AC,X)
		CMP #&7F
		BCS x9F2D
		CMP #&20
		BCS x9F2F

.x9F2D		LDA #&2E

.x9F2F		JSR osasci
		DEC &AC
		BPL x9F23
		JSR prtChr0D
		LDA #&08
		CLC
		ADC &A8
		STA &A8
		BCC x9F44
		INC &A9

.x9F44		PLP
		BCC x9EE5
		JMP x9ECC			;Was BCS x9ECC
\
\
\
.x9F49		JSR osbyte_7E			;*FX126 - Acknowledge escape condition
		JSR x9ECC
		JMP errEsc
\
\
\************************************************
\** *BUILD command
\
.cmdBuild	JSR x9FD1
		JSR chkDrv5			;Check for Drive 5 in A
		LDA #&80
		JSR osfind
		STA &AB

.x9F5C		JSR x9F9C
		JSR prtChr20
		LDX &F4
		LDY &0DF0,X
		INY
		STY &AD
		LDX #&AC
		LDY #&FF
		STY &AE
		STY &B0
		INY
		STY &AC
		STY &AF
		TYA
		JSR osword
		PHP
		STY &AA
		LDY &AB
		LDX #&00
		BEQ x9F8B

.x9F84		LDA (&AC,X)
		JSR osbput
		INC &AC

.x9F8B		LDA &AC
		CMP &AA
		BNE x9F84
		PLP
		BCS x9F49
		LDA #&0D
		JSR osbput
		JMP x9F5C
\
\
\
.x9F9C		SED
		CLC
		LDA &A8
		ADC #&01
		STA &A8
		LDA &A9
		ADC #&00
		STA &A9
		CLD
		CLC
		JSR x9FB1
		LDA &A8

.x9FB1		PHA
		PHP
		JSR mLSR4			;LSR A * 4
		PLP
		JSR x9FBB
		PLA

.x9FBB		TAX
		BCS x9FC0
		BEQ prtChr20

.x9FC0		JSR prtHexA4bit
		SEC
		RTS
\
\*************************************************
\** Print 2 Spaces
\
.prtChr20x2	JSR prtChr20
\
\*************************************************
\** Print a Space
\
.prtChr20	PHA
		LDA #&20
		JSR prtChrA
		PLA
		CLC
		RTS
\
\
\*************************************************
\** Syntax Checker?
\
.x9FD1		TSX
		LDA #&00
		STA &0107,X
		DEY

.x9FD8		INY
		LDA (&F2),Y
		CMP #&20
		BEQ x9FD8
		CMP #&0D
		BNE x9FE6
		JMP x99FC

.x9FE6		LDA #&00
		STA &A8
		STA &A9
		PHA
		TYA
		CLC
		ADC &F2
		TAX
		LDA &F3
		ADC #&00
		TAY
		PLA
		RTS		
\
\
\************************************************
\** *RAMTEST  command
\
.RAMtest	JSR prtStr
		EQUS	"This will erase all RamDrives"
		EQUB	&0D
		EQUB	"Are you sure?"
		EQUB 	&0D
		NOP
		JSR chkAlways
		JSR stackClaim			;Change stacked A to &00
		JSR prtStr			;Print first message
		EQUS	"Testing RAM"
		EQUB &0D
		NOP
		JSR prtS_PAT
		JSR prtStr
		EQUS	"1111"			;First pattern, &FF
		NOP
		LDA #&FF
		JSR testRAM
		BCS test_Fail2			;If carry is set, it's a fail
		JSR prtS_PAT
		JSR prtStr
		EQUS	"1010"			;Second pattern &AA
		NOP
		LDA #&AA
		JSR testRAM
		BCS test_Fail2
		JSR prtS_PAT
		JSR prtStr
		EQUS	"0101"			;Third pattern &55
		NOP
		LDA #&55
		JSR testRAM
		BCS test_Fail2
		JSR prtS_PAT
		JSR prtStr
		EQUS	"0000"			;Last pattern &00
		NOP
		LDA #&00
		JSR testRAM
		BCS test_Fail2
		JSR prtStr			;It's passed, we can exit
		EQUS	"RAM passed all tests"
		EQUB	&0D
		NOP
.test_exit	JSR prtStr
		EQUS	"Please reset the system"
		EQUB	&0D
		NOP
		RTS
		
.test_Fail2	JSR prtStr
		EQUB	&0D
		EQUS	"Test fail at address &"
		NOP
		LDA zpm3			;print the TSB
		JSR prtHexA4bit
		LDA zpm2			;print the MSB
		JSR prtHexA8bit
		LDA zpm0			;and the LSB
		JSR prtHexA8bit
		JSR prtChr0D
		JMP test_exit
		
.testRAM	STA zpm0			;Store pattern for test
		JSR prtStr
		EQUB	" : Writing Page 0"
		NOP
		LDA #&00
		STA zpm2
		STA zpm3
.test_L1	LDA #&08			;Back the cursor off one space
		JSR prtChrA
		LDA zpm3
		STA pageH
		JSR prtHexA4bit
		BIT &FF
		BPL test_J1
		JMP errEsc
.test_J1	LDA zpm0
		LDX #&00
.test_L2	LDY zpm2
		STY pageL
.test_L3	STA &FD00,X			;Loop around &FFFFF bytes
		INX
		BNE test_L3
		INC zpm2
		BNE test_L2
		INC zpm3
		LDY zpm3
		CPY #&10
		BNE test_L1
		
		LDA #&08
		LDX #&0E
.test_L4	JSR prtChrA			;Back the cursor off 14 spaces
		DEX
		BNE test_L4
		JSR prtStr
		EQUB	"Checking Page 0"
		NOP
		LDA #&00
		STA zpm2
		STA zpm3
.test_L5	LDA #&08
		JSR prtChrA
		LDA zpm3
		STA pageH
		JSR prtHexA4bit
		BIT &FF
		BPL test_J2
		JMP errEsc		
.test_J2	LDX #&00
.test_L6	LDY zpm2
		STY pageL
.test_L7	LDA &FD00,X
		CMP zpm0			;Is it what it should be?
		BNE test_Fail			;if not, jump to fail
		INX
		BNE test_L7
		INC zpm2
		BNE test_L6
		INC zpm3
		LDY zpm3
		CPY #&10			;Loop for &FFFFF bytes
		BNE test_L5
		
.test_RET	LDA #&08
		LDX #&0F			;Back the cursor off 15 spaces
.test_L8	JSR prtChrA
		DEX
		BNE test_L8
		JSR prtStr
		EQUB	"Test OK        "
		EQUB &0D
		NOP
		CLC				;clear the carry to indicate test ok
		RTS				;return
		
.test_Fail	JSR prtChr0D
		STX zpm0			;Store the LSB of the address failure at &CF
		SEC				;Set the carry to show test failed
		RTS		
		
.prtS_PAT	JSR prtStr			;Routine to print "Pattern"
		EQUS	"Pattern "
		NOP
		RTS
\
\
\************************************************
\** USB error check - Carry set if more data to come, clear if exited with a prompt
\** This routine is used to check commands that return with a <CR> if okay
\
.uCHK		JSR uRDbL			;Read first byte
		JSR saveAXY
		CMP #&0D			;Is it a <CR>?
		BEQ uCHK_J2			;If so, set carry and exit
.uCHK_J3	PHA
		JSR setERR			;Set Error page in RAM
		LDA #&00
		TAY
		TAX
		STA &FD00
		DEY
		STY &FD01
		LDY #&03
		PLA
		STA &FD02
		CMP uprmpt,X
		BNE uCHK_L1
		INX
		
.uCHK_L1	JSR uRDbL
		STA &FD00,Y
		CMP #&0D
		BEQ uCHK_J1
		INY
		CMP uprmpt,X
		BNE uCHK_L1
		INX
		CPX #&04
		BEQ uCHK_J2a
		JMP uCHK_L1
		
.uCHK_J1	LDA #&00
		STA &FD00,Y
		JMP &FD00		
		
.uCHK_J2	SEC
		RTS

.uCHK_J2a	CLC
		RTS
\
\
\************************************************
\** Alternative Error check, for commands that do not return a <CR> before the prompt
\		
.uCHKa		JSR setERR			;Set Error page in RAM
		LDX #&00
		JSR uRDbL
		JSR saveAXY
		CMP #&44
		BNE uCHK_J3
		STA &FD02
		JSR uRDbL
		STA &FD03
		CMP #&3A
		BEQ uCHKa1
		LDY #&04
		JMP uCHK_L1
		
.uCHKa1		JSR uRDbL
		JSR uRDbL
		JMP uRDbL
\
\
\************************************************
\** USB read, checking for D:\>
\
.uREAD		LDY #&00
.uRD_L1		JSR uRDbL			;Read byte with flush on Escape
		CMP uprmpt,Y
		BNE uRD_J1
		CMP #&0D
		BEQ uRD_exit
		INY
		JMP uRD_L1
		
.uRD_J1		CPY #&00
		BEQ uRD_J2
		PHA
		LDA #&44			;Reinsert the "D" removed
		JSR prtChrA			;JSR &FFEE
		PLA
		
.uRD_J2		JSR prtChrA			;JSR &FFE3
		JMP uREAD
		
.uRD_exit	RTS	
\
\
\************************************************
\** Send command to USB device
\
.uCmd		JSR uSync			;was JSR uFlush
		LDY #&01
.U_L10		LDA (&F2),Y
		JSR uWRbL
		INY
		CMP #&0D
		BNE U_L10
		
		JSR uCHK
		BCS uREAD
		RTS
\
\
\************************************************
\** USB Monitor Sync
\
.uSync		NOP				;Filler....

.uS_1		JSR uRDb			;Read a byte
		BCS uS_2			;Branch out if no byte available
		BIT &FF				;Escape Check
		BPL uS_1
		JMP errEsc
.uS_2		BIT vdipS
		BVC uS_3			;Check but 6 of status = If ok to write data, then branch
		BIT &FF				;Else check for Escape
		BPL uS_1			;Loop if not pressed
		JMP errEsc
.uS_3		LDA #&45			;Load "E" sync caracter
		JSR uWRb			;send to VNC1L
		BCS uS_1			;if not written, loop
		LDA #&0D			;Load carriage return
		JSR uWRb			;send to VNC1L
		BCS uS_1			;if not written, loop
		
.uS_4		JSR uRDbL			;Read byte from VNC1L
		CMP #&45			;is it an "E"?
		BNE uS_4			;if not, loop
.uS_5		JSR uRDbL
		CMP #&0D			;is next char a carriage return?
		BNE uS_5			;if not, loop	
		
.uS_X		RTS				;ok, monitor sync is complete
\
\
\************************************************
\** Hard flush of the VNC1L
\		
.uFlush		LDX #&00
.uFl1		LDA vdip
		CMP #&0D
		BNE uFlush
		LDY #&80
.uFl2		INY
		BNE uFl2
		INX
		BNE uFl1
		RTS
\
\
\************************************************
\** Hard fill of buffer on escape
\
.uFill		JSR prtStr
		EQUB	&0D
		EQUS	"Filling Buffer"
		NOP
		LDA #&0D
.uFi1		STA vdip
		BIT vdipS
		BMI uFi1
		RTS
\
\
\************************************************
\** Write Byte to VNC1L
\** Loops until write done
\
.uWRbL		PHA
.uWRbL1		BIT vdipS
		BVC uWRbL2
		BIT &FF
		BPL uWRbL1
		JMP errEsc
		
.uWRbL2		PLA
		STA vdip
		RTS
\
\
.uWRbLs		PHP
		JSR uWRbL
		PLP
		RTS
\
\************************************************
\** Read byte from VNC1L
\** Loops until a byte is read
\
.uRDbL		BIT vdipS			;Get Status
		BPL uRDbL2			;Check bit 7, if data available, then exit
		BIT &FF
		BPL uRDbL
		JSR uFlush
		JMP errEsc
		
.uRDbL2		LDA vdip
		RTS
\
\
\************************************************
\** Write Byte to VNC1L
\** on exit, carry set if no byte written
\
.uWRb		PHA
		BIT vdipS			;Get status
		BVC uWRb2			;Check bit 6 - If ok to write data, then branch
		PLA
		SEC
		RTS

.uWRb2		PLA
		STA vdip
		CLC
		RTS		
\
\
\************************************************
\** Read Byte from VNC1L
\** on exit, carry set if no byte read
\
.uRDb		BIT vdipS			;Get status
		BMI uRDbX			;If bit 7 high, no data available so branch
		LDA vdip
		CLC
		RTS
		
.uRDbX		SEC
		RTS
\
\
\************************************************
\** Import Image to RAM/DISK
\
.uIMPcmd	JSR x9FD1			;Check Syntax
		JSR storeXY_F2
		JSR stackClaim			;Change stacked A to &00
		JSR getOptions			;Get and set Options
		JSR checkDFS
		LDA &FD90
		STA zpm5			;Store Quite/Verbose flag at zpm5
		
.U_J20a		JSR setSCR
		BIT zpm5
		BPL U_J20aQ
		JSR prtStr
		EQUS	"Mounting USB"
		EQUB	&0D
		NOP
		
.U_J20aQ	JSR uSync			;Synchronise Monitor
		JSR wrIPH			;Write "IPH<CR>" to monitor
		JSR wrDIR			;Write "DIR" to monitor
		LDA #&20
		JSR uWRbL			;and a space
		
.U_J21		LDY #&00

.U_L22		LDA (&F2),Y			;Write Filename to monitor
		JSR uWRbL
		INY
		CMP #&0D
		BNE U_L22
		
		JSR setERR			;Setup error check page, just incase
		LDY #&00
		STY &FD00
		DEY
		STY &FD01
		INY

.U_L23		JSR uRDbL			;Start of error check routine for the extract
		CMP #&0D			;This is messy and needs tidying up
		BEQ U_L23			;If first byte back is a CR, then ignore it
		STA &FD02,Y			;Store result at error buffer
		CMP (&F2),Y			;Check the character is part of the filename
		BEQ U_J23			;if so, then proceed
		CMP #&20			;Is it a space? End of filename, and beginning of data?
		BEQ U_J23a			;Jump if so
		INY				;Skip the error header and first bytes
		INY
		INY
		JMP uCHK_L1			;and jump to error handler
		
.U_J23		INY
		JMP U_L23

.U_J23a		LDX #&00
		JSR setSCR			;Set scratchpad workpage
		
.U_L24		JSR uRDbL			;Next 4 bytes from VNC1L are the filesize
		STA &FDF4,X			;Store them temporarily
		INX
		CPX #&04
		BNE U_L24
		
		LDA &FD92
		BPL U_L24dsd
		LDA &FDF6			;Get MSB of sector count
		CMP #&04			;If it's more than &3FF then the image is too long
		BCC U_J25
		JMP U_L24err
		
.U_L24dsd	LDA &FDF6
		CMP #&07
		BCC U_J25
		
.U_L24err	JSR errARG
		EQUB	&FF
		EQUS	"Image too long"
		BRK		
		
		
\***********************************************;Now we have the filesize, we can load it

.U_J25		JSR uSync			;Sync up the monitor	
		
		BIT zpm5
		BPL U_L30Q
		JSR prtStr	
		EQUB	&0D
		EQUS	"Importing to "
		NOP
		BIT &FD93
		BPL U_J25a
		JSR prtStr
		EQUS	"Disk "
		NOP
		JMP U_J25b
		
.U_J25a		JSR prtStr
		EQUS	"RAM "
		NOP

.U_J25b		JSR prtStr
		EQUS	"Drive"
		NOP
		BIT &FD92
		BMI U_J26
		LDA #&73
		JSR prtChrA
		
.U_J26		LDA #&20
		JSR prtChrA
		LDA &FD91
		ORA #&30
		JSR prtChrA
		BIT &FD92
		BMI U_L30R
		JSR prtStr	
		EQUS	" and "
		NOP
		LDA &FD92
		ORA #&30
		JSR prtChrA
		
.U_L30R		JSR prtChr0Dx2	
		
.U_L30Q		LDY #&00

.U_L30		LDA ustr1,Y			;Write "RD " to monitor
		BEQ U_J30
		JSR uWRbL
		INY
		BNE U_L30
		
.U_J30		LDY #&00		

.U_L31		LDA (&F2),Y			;Write the Filename to monitor
		JSR uWRbL
		CMP #&0D
		BEQ U_J32
		BIT zpm5
		BPL U_J31a
		JSR prtChrA			;and to the screen

.U_J31a		INY
		JMP U_L31
		
\***********************************************;Now data can be read

		
.U_J32		LDA &FD92			;Get second drive number
		AND #&80			;Mask off top bit
		STA zpm1			;and store as DSD flag, PL if DSD, MI if SSD
		LDA &FDF5			;Get byte count
		STA zpm2			;And transfer to zpm
		LDA &FDF6
		STA zpm3
		LDA #&00			;Zero all other counters in preparation
		TAX
		TAY
		STA zpm0			;Track Counter
		STA zpm7			;Sector Counter
		
		
.U_J33		BIT zpm5
		BPL U_J33a
		JSR prtStr
		EQUS	" 00"
		NOP

.U_J33a		BIT &FD93			;Check if destination is Disk or RAM
		BPL U_J34
		JMP impD			;Jump to Disk Import routine
		
.U_J34		LDA &FD92			;Get second drive, it's already been checked
		JSR mASL2			;Multiply by 4 for RAM page
		STA zpm6			;And in RAM copy
		LDA &FD91			;Get first drive
		JSR mASL2			;Multiply by 4 for RAM page
		STA zpm4			;And store in RAM copy			
		STA &FCFE			;And in page register
		LDA #&10			;Page offset
		STA &FCFF
		
.U_L40		LDX #&00
.U_L41		JSR uRDbL
		STA &FD00,X
		INX
		BNE U_L41
		SEC
		LDA zpm2
		SBC #&01
		STA zpm2
		BCS U_J42
		DEC zpm3
		
.U_J42		BIT zpm1			;Check DSD flag
		BMI U_S03			;If it's an SSD then just process side A only
		INY
		CPY #20
		BNE U_S01
		JSR procBA			;If Y=20 Then swap from side B to side A
		JMP U_J42a

.U_S01		CPY #10
		BNE U_S02
		JSR procAB			;If Y=10 Then swap from side A to side B
		JMP U_J42a
		
.U_S02		BCC U_S03
		JSR procB			;If Y>10 Then process side B
		JMP U_J42a
		
.U_S03		JSR procA			;Else process side A

.U_J42a		LDA zpm2
		BNE U_J44
		LDA zpm3
		BNE U_J44
		JMP U_exitEn
		
.U_J44		INC zpm7
		LDA zpm7
		CMP #10
		BNE U_L40
		BIT zpm5
		BPL U_L40
		LDA #&00
		STA zpm7
		LDA #&08
		JSR prtChrA
		JSR prtChrA
		INC zpm0
		LDA zpm0
		JSR prtHexA8bit
		JMP U_L40
		
.U_exitEn	JSR uSync
		BIT zpm5
		BPL U_exitEn2
		LDA #&20
		JSR prtChrA
		JSR setSCR
		LDA &FDF6
		JSR prtHexA8bit
		LDA &FDF5
		JSR prtHexA8bit
		LDA #&0D
		JSR prtChrA
		LDA #&07
		JSR prtChrA
.U_exitEn2	RTS	
\
\
\************************************************
\** Import to Disk Routine
\
.impD		JSR copyAE0			;Take a backup copy of AE0-AFF and zero it
		LDA #&84
		JSR osbyte			;Ask for value of HIMEM
		STX &F2
		TYA
		SEC
		SBC #&A				;Back it off &A00 bytes to allow for buffer
		STA &F3
		LDA #&03
		STA &AE5			;Set param+5 = &03
		LDA #&4B			;Set param+6 = &4B - Write Data Multi-Sector
		STA &AE6
		LDA &F3
		STA &AE2			;Set param+2 (buffer) to HIMEM - &A00
		LDA #&2A
		STA &AE9			;Set param+9 to &2A
		LDA &FD92
		STA zpm6
		LDA &FD91
		STA zpm4
		JSR copyZPM			;Copy ZPM variables to &AF0
		LDY #&FF
		STY &AE3			;Set top bytes for tube
		STY &AE4
		INY
		LDX #10				;Load sector counter with 10 by default
		LDA &AF6			;Check if double sided is active
		BMI impD1			;If not then jump
		LDX #20				;Otherwise use 20 for sector counter
		
.impD1		STX &AFF			;=10 for SSD, or 20 for DSD
\
\** Main copy routine starts here
\
		LDA &AF4			;Get First Drive
		STA &AE0			;Store it in Param Block
		
.impL1		LDA &AF9			;Get MSB of buffer
		STA &F3				;Resotre it to counter
		LDY #&00
		LDX #10				;X = 10 Sectors
		LDA &AF3			;Check if less than 255 sectors to copy
		BNE impL2			;Jump if not
		CPX &AF2			;Check if less than 10 Sectors left
		BCC impL2			;if not then jump
		LDX &AF2			;Otherwise, only loop for X sectors
		
.impL2		BIT vdipS
		BPL impL3
		BIT &FF
		BPL impL2
		JMP moni_ESC			;Provide Escape with flush
		
.impL3		LDA vdip
		STA (&F2),Y
		INY
		BNE impL2
		INC &F3
		DEX
		BNE impL2
		
		LDA #&7F
		LDX #&E0
		LDY #&0A
		JSR osword			;Write the buffer to the disk
		LDA &AEA
		BNE impERR			;Jump to disk error if found
		LDA &AF6			;Check second side
		BMI impL5			;Jump if invalid
		CMP &AE0			;Is it already there?
		BNE impL4			;If not, then put it there
		LDA &AF4
		STA &AE0			;Else restore it
		JMP impL5
		
.impL4		STA &AE0			;Put second side into param block
		JMP impL1			;And redo the track for side 2
		
.impL5		LDA &AF2			;Get the sector counter
		SEC
		SBC &AFF			;Substract the correct counter value, 10 for SSD, 20 for DSD
		STA &AF2			;Store back
		LDA &AF3
		SBC #&00
		STA &AF3			;And do the carry
		BCC impR1			;Exit if it underflows
		ORA &AF2
		BEQ impR1			;Exit if both bytes are 0
		
		INC &AE7			;Increment track counter in paramter Block
		BIT &AF5			;Check verbose option
		BPL impL1			;Jump if printing not required
		LDA #&08
		JSR &FFEE			;Not using prtChrA for speed
		JSR &FFEE			;prtChrA
		LDA &AE7
		PHA				;Save A
		LSR A
		LSR A
		LSR A
		LSR A
		AND #&0F
		CMP #&0A
		BCC impL6
		ADC #&06

.impL6		ADC #&30
		JSR &FFEE
		PLA
		AND #&0F
		CMP #&0A
		BCC impL7
		ADC #&06

.impL7		ADC #&30
		JSR &FFEE
		JMP impL1
		
.impR1		BIT &AF5			;Check verbose option
		BPL impR2			;Jump if printing not required
		JSR &FFE7
		
.impR2		JMP restAE0			;Restore AE0-AFF block from backup

.impERR		PHA
		JSR uFlush			;Flush the USB buffer
		JSR restAE0			;Restore AE0-AFF block from backup
		PLA
		JMP diskERR			;Jump to disk error handler
\
\
\************************************************
\** Export Image to USB
\
.uEXPcmd	JSR x9FD1			;Check Syntax
		JSR storeXY_F2
		JSR stackClaim			;Change stacked A to &00
		JSR getOptions			;Get and set options
		JSR checkDFS
		LDA &FD90			;Get Quiet/Verbose flag
		STA zpm5			;And store at zpm5
		LDA &FD93			;Get Disk/RAM option
		BPL U_J49			;Jump if RAM
		JSR loadDSECT			;Otherwise get the disk sectors
		JMP U_J49a
		
.U_J49		LDA &FD91			;Get first drive side
		STA &CF
		JSR loadCAT
		
.U_J49a		BIT zpm5			;Check for quiet flag
		BPL U_J50			;Branch if set
		JSR prtStr
		EQUS	"Mounting USB"
		EQUB	&0D
		NOP
		
.U_J50		JSR uSync			;Synchronise Monitor	
		JSR wrIPH			;Write IPH <CR> to monitor
		JSR wrOPW			;Write "OPW " to monitor
		
.U_J51		LDY #&00

.U_L52		LDA (&F2),Y			;Write the filename
		JSR uWRbL
		CMP #&0D
		BEQ U_J52
		INY
		JMP U_L52
		
.U_J52		JSR uCHKa			;Does this cover the error checks needed?
		JSR wrSEK			;Write "SEK 0000" to monitor		
		JSR wrWRF
		JSR uWRbL			;First byte is always Zero, so send it
		JSR setSCR
		LDA &FD92			;Get second drive number
		AND #&80			;Mask off top bit
		STA zpm1			;and store as DSD flag, PL if DSD, MI if SSD
		BPL U_J53b			;Jump if DSD		
		
.U_J53		JSR set0F			;Set Page 0F
		LDA &FD07			;Grab the LSB number of Sectors
		PHA				;And Store it momentarily
		LDA &FD06			;For SSD, next, MSB number of sectors
		AND #&03			;Mask off OPT bits
		JSR setSCR			;Set scratchram workspace
		STA &FDF6			;Store MSB
		JSR uWRbL			;And write it to VNC1L
		PLA				;Retreive LSB Number of sectors
		STA &FDF5			;Store LSB
		JSR uWRbL			;And write it to VNC1L
		JMP U_J53a
		
.U_J53b		LDA #&06			;For DSD, Sector count is always &640
		STA &FDF6
		JSR uWRbL
		LDA #&40			;LSB Number of sectors
		STA &FDF5
		JSR uWRbL
		
.U_J53a		LDA #&00
		JSR uWRbL			;And write a last zero
		LDA #&0D			;Finish command with a <CR>
		JSR uWRbL

\***********************************************;Now data can be written

		BIT zpm5
		BPL U_J54a
		JSR prtStr
		EQUB	&0D
		EQUS	"Exporting from "
		NOP
		BIT &FD93
		BPL U_J53d
		JSR prtStr
		EQUS	"Disk "
		NOP
		JMP U_J53c
				
.U_J53d		JSR prtStr
		EQUS	"RAM "
		NOP
		
.U_J53c		JSR prtStr
		EQUS	"Drive"
		NOP
		BIT &FD92
		BMI U_J54x
		LDA #&73
		JSR prtChrA
		
.U_J54x		LDA #&20
		JSR prtChrA
		LDA &FD91
		ORA #&30
		JSR prtChrA
		BIT &FD92
		BMI U_J54y
		JSR prtStr	
		EQUS	" and "
		NOP
		LDA &FD92
		ORA #&30
		JSR prtChrA
		
.U_J54y		JSR prtChr0Dx2	
	
.U_J54a		LDY #&00

.U_L54		LDA (&F2),Y
		CMP #&0D
		BEQ U_J54
		BIT zpm5
		BPL U_L54a
		JSR prtChrA
		
.U_L54a		INY
		JMP U_L54
		
.U_J54		LDA &FD92			;Get second drive number
		AND #&80			;Mask off top bit
		STA zpm1			;and store as DSD flag, PL if DSD, MI if SSD
		LDA &FDF5			;Get byte count
		STA zpm2			;And transfer to zpm
		LDA &FDF6
		STA zpm3
		LDA #&00			;Zero all other counters in preparation
		TAX
		TAY
		STA zpm0			;Track Counter
		STA zpm7			;Sector Counter
		BIT zpm5
		BPL U_J55a
		JSR prtStr
		EQUS	" 00"
		NOP
		
.U_J55a		BIT &FD93			;Check if destination is Disk or RAM
		BPL U_J55
		JMP expD			;Jump to Disk Export routine

.U_J55		JSR setSCR
		LDA &FDF5
		STA zpm2
		LDA &FDF6
		STA zpm3
		LDA #&00
		TAY
		STA zpm0
		LDA &FD92			;Get second drive
		JSR mASL2			;Multiply by 4 for RAM page
		STA zpm6
		LDA &FD91			;Get first drive
		JSR mASL2			;Multiply by 4 for RAM page
		STA zpm4
		STA &FCFE			;Store at MSB RAM address		
		LDA #&10
		STA &FCFF

.U_L60		LDX #&00
.U_L61		LDA &FD00,X
		JSR uWRbL
		INX
		BNE U_L61
		SEC
		LDA zpm2
		SBC #&01
		STA zpm2
		BCS U_J62a
		DEC zpm3

.U_J62a		BIT zpm1			;Check DSD flag
		BMI X_S03			;If it's an SSD then just process side A only
		INY
		CPY #20
		BNE X_S01
		JSR procBA			;If Y=20 Then swap from side B to side A
		JMP U_J62

.X_S01		CPY #10
		BNE X_S02
		JSR procAB			;If Y=10 Then swap from side A to side B
		JMP U_J62
		
.X_S02		BCC X_S03
		JSR procB			;If Y>10 Then process side B
		JMP U_J62
		
.X_S03		JSR procA			;Else process side A
	
.U_J62		LDA zpm2
		BNE U_J64
		LDA zpm3
		BNE U_J64
		JMP U_exit2
		
.U_J64		INC zpm7
		LDA zpm7
		CMP #10
		BNE U_L60
		BIT zpm5
		BPL U_L60
		LDA #&00
		STA zpm7
		LDA #&08
		JSR prtChrA
		JSR prtChrA
		INC zpm0
		LDA zpm0
		JSR prtHexA8bit
		JMP U_L60
		
.U_exit2	BIT vdipS			;Wait for VNC1l to become ready
		BVC U_J70
		BIT &FF
		BPL U_exit2
		JMP errEsc
		
.U_J70		JSR expCLF			;Write "CLF <FILENAME>" to monitor		
		JSR uSync
		BIT zpm5
		BPL U_exit2Z
		LDA #&20
		JSR prtChrA
		JSR setSCR
		LDA &FDF6
		JSR prtHexA8bit
		LDA &FDF5
		JSR prtHexA8bit
		LDA #&0D
		JSR prtChrA
		LDA #&07
		JSR prtChrA
		
.U_exit2Z	RTS
		
\
\
\************************************************
\** Export from Disk Routine
\
.expD		JSR copyAE0			;Take a backup copy of AE0-AFF and zero it
		LDA #&84
		JSR osbyte			;Ask for value of HIMEM
		STX &F2
		TYA
		SEC
		SBC #&A				;Back it off &A00 bytes to allow for buffer
		STA &F3
		LDA #&03
		STA &AE5			;Set param+5 = &03
		LDA #&53			;Set param+6 = &53 - Read Data Multi-Sector
		STA &AE6
		LDA &F3
		STA &AE2			;Set param+2 (buffer) to HIMEM - &A00
		LDA #&2A
		STA &AE9			;Set param+9 to &2A
		LDA &FD92
		STA zpm6
		LDA &FD91
		STA zpm4
		JSR copyZPM			;Copy ZPM variables to &AF0
		LDY #&FF
		STY &AE3			;Set top bytes for tube
		STY &AE4
		INY
		LDX #10				;Load sector counter with 10 by default
		LDA &AF6			;Check if double sided is active
		BMI expD1			;If not then jump
		LDX #20				;Otherwise use 20 for sector counter
		
.expD1		STX &AFF			;=10 for SSD, or 20 for DSD
\
\** Main copy routine starts here
\
		LDA &AF4			;Get First Drive
		STA &AE0			;Store it in Param Block
		
.expL1		LDA #&7F
		LDX #&E0
		LDY #&0A
		JSR osword			;Read the buffer from the disk
		LDA &AEA
		BEQ expL1a
		JMP expERR			;Jump to disk error if found

.expL1a		LDA &AF9			;Get MSB of buffer
		STA &F3				;Resotre it to counter
		LDY #&00
		LDX #10				;X = 10 Sectors
		LDA &AF3			;Check if less than 255 sectors to copy
		BNE expL2			;Jump if not
		CPX &AF2			;Check if less than 10 Sectors left
		BCC expL2			;if not then jump
		LDX &AF2			;Otherwise, only loop for X sectors
		
.expL2		LDA (&F2),Y

.expL2b		BIT vdipS
		BVC expL3
		BIT &FF
		BPL expL2b
		JMP expESC			;Provide Escape with fill
		
.expL3		STA vdip
		INY
		BNE expL2
		INC &F3
		DEX
		BNE expL2
		LDA &AF6			;Check second side
		BMI expL5			;Jump if invalid
		CMP &AE0			;Is it already there?
		BNE expL4			;If not, then put it there
		LDA &AF4
		STA &AE0			;Else restore it
		JMP expL5
		
.expL4		STA &AE0			;Put second side into param block
		JMP expL1			;And redo the track for side 2
		
.expL5		LDA &AF2			;Get the sector counter
		SEC
		SBC &AFF			;Substract the correct counter value, 10 for SSD, 20 for DSD
		STA &AF2			;Store back
		LDA &AF3
		SBC #&00
		STA &AF3			;And do the carry
		BCC expR1			;Exit if it underflows
		ORA &AF2
		BEQ expR1			;Exit if both bytes are 0
		
		INC &AE7			;Increment track counter in paramter Block
		BIT &AF5			;Check verbose option
		BPL expL1			;Jump if printing not required
		LDA #&08
		JSR &FFEE			;Not using prtChrA for speed
		JSR &FFEE			;prtChrA
		LDA &AE7
		PHA				;Save A
		LSR A
		LSR A
		LSR A
		LSR A
		AND #&0F
		CMP #&0A
		BCC expL6
		ADC #&06

.expL6		ADC #&30
		JSR &FFEE
		PLA
		AND #&0F
		CMP #&0A
		BCC expL7
		ADC #&06

.expL7		ADC #&30
		JSR &FFEE
		JMP expL1
		
.expR1		BIT &AF5			;Check verbose option
		BPL expR2			;Jump if printing not required
		JSR &FFE7
		
.expR2		JSR restAE0			;Restore AE0-AFF block from backup
		JSR expCLF			;Write "CLF <FILENAME>" to monitor
		JMP uSync
		
.expERR		PHA
		JSR uFill			;Fill and flush the USB buffer
		JSR uFlush
		JSR uSync			;Synchronise Buffer	
		JSR restAE0			;Restore AE0-AFF block from backup
		JSR expCLF			;Write "CLF <FILENAME>" to monitor
		PLA
		JMP diskERR			;Jump to disk error handler	
		
.expESC		JSR uFill			;Fill and flush the USB buffer
		JSR uFlush
		LDA #&7C
		JSR osbyte			;Acknowledge the Escape conditIon
		JSR uSync			;Synchronise Buffer
		JSR restAE0			;Restore AE0-AFF block from backup
		JSR expCLF			;Write "CLF <FILENAME>" to monitor
		JMP errEsc
\
\
\
.expCLF		JSR setSCR			;Set scratchram workpage
		JSR wrCLF			;Write "CLF " to monitor
		LDY #&00

.expR3		LDA (&F2),Y
		JSR uWRbL
		INY
		CMP #&0D
		BNE expR3
		RTS
\
\
\************************************************
\** USB Encode and Extract Processing Routines
\
.procA		INC &FCFF			;Process side A
		BNE procRTS			;Increment side A counter
		INC zpm4			;With carry
		LDA zpm4			;and return
		STA &FCFE

.procRTS	RTS
\
\
.procB		INC &FCFF			;Process side B
		BNE procRTS			;Increment side B counter
		INC zpm6			;With carry
		LDA zpm6			;and return
		STA &FCFE
		RTS
\
\
.procAB		INC &FCFF			;Process swap from side A to side B
		BNE procAB1			;Increment scetor counter
		INC zpm4			;with carry
		
.procAB1	LDA &FCFF			;Going from side A to B we need to back the sector count off by 10
		SEC
		SBC #10
		STA &FCFF			;But we can ignore the carry, as the other side count will still be in sync
		LDA zpm6			;Now store side B counter in MSB of page register
		STA &FCFE
		RTS
\
\
.procBA		INC &FCFF			;Process swap from side B to side A
		BNE procBA2			;Increment scetor counter
		INC zpm6			;with carry
		
.procBA2	LDA zpm4			;Going from side B to A there is no need to back off sector count
		STA &FCFE			;But we do now store side A counter MSB in paging resigster
		LDY #&00			;And clear the scetor counter ready for another cycle
		RTS
\
\
\************************************************
\** Copy ZPM to alternate workspace locations
\
.copyZPM	LDA zpm0
		STA &AF0
		LDA zpm1
		STA &AF1
		LDA zpm2
		STA &AF2
		LDA zpm3
		STA &AF3
		LDA zpm4
		STA &AF4
		LDA zpm5
		STA &AF5
		LDA zpm6
		STA &AF6
		LDA zpm7
		STA &AF7
		LDA &F2
		STA &AF8
		LDA &F3
		STA &AF9
		RTS
\
\
\************************************************
\** Copy &AE0 - &AFF to Scratchram Workspace
\
.copyAE0	JSR setSCR
		LDA #&00
		TAY
		TAX
		
.copyAE0L	LDA &AE0,Y			;Grab a copy of these 32 bytes
		STA &FD00,Y			;And store them for restore later
		TXA
		STA &AE0,Y			;Zero Parameter Block
		INY
		CPY #&20
		BNE copyAE0L
		LDA &F2
		STA &AEE
		LDA &F3
		STA &AEF
		RTS
\
\
\************************************************
\** Restore &AE0 - &AFF from Scratchram Workspace
\
.restAE0	LDA &AEE
		STA &F2
		LDA &AEF
		STA &F3
		JSR setSCR
		LDA #&00
		TAY
		
.restAE0L	LDA &FD00,Y			;Restore AE0 paramter area
		STA &AE0,Y
		INY
		CPY #&20
		BNE restAE0L
		RTS
\
\
\************************************************
\** Disk error routine, Displays results back from OSWORD &7F
\
.diskERR	CMP #&12
		BNE diskERR2
		JSR errDisk			;Error "Disk read only"
		EQUB	&C9
		EQUS	"read only"
		BRK

.diskERR2	CMP #&0A			;Was PHA before this command
		BEQ diskERR3
		AND #&0F
		CMP #&08
		BCC diskERR3
		JSR errDisk			;Error "Disk fault"
		EQUB	&C7
		EQUS	"fault"
		BRK

.diskERR3	JSR errARG			;Error "Drive fault"
		EQUB	&C5
		EQUS	"Drive fault "
		BRK
		
.checkDFS	LDA &FD93
		BPL checkDFS_X
		LDA #&00
		TAY
		JSR osargs
		CMP #&04
		BEQ checkDFS_X
		JSR errARG
		EQUB	&FF
		EQUS	"Disk System Not Selected"
		BRK
		
.checkDFS_X	RTS
\
\
\************************************************
\** Get number of sectors from Floppy Disk
\
.loadDSECT	JSR copyAE0
		LDA &FD91			;Get drive number
		STA &AE0			;Store in param block
		LDA #&FD
		STA &AE2			;Store &FD00 as 256 byte buffer
		LDA #&FF
		STA &AE3
		STA &AE4			;&FFFF top bytes for tube compat.
		LDA #&03
		STA &AE5
		LDA #&53
		STA &AE6
		LDA #&01
		STA &AE8			;Sector 1 only reaquired
		LDA #&21
		STA &AE9			;For just 1 sector
		JSR set0F
		LDA #&7F
		LDX #&E0
		LDY #&0A
		JSR osword
		JMP restAE0			;Restore AE0


\
\
\************************************************
\** USB Write Routines
\
.wrIPH		LDY #&00
		
.wrIPH1		LDA ustr3,Y			;Write "IPH<CR>" to monitor
		BEQ wrIPH2			;To set it to binary mode
		JSR uWRbL
		INY
		BNE wrIPH1
		
.wrIPH2		JMP uSync			;Sync on return
\
\
\
.wrIPA		LDY #&00
		
.wrIPA1		LDA ustr3a,Y			;Write "IPA<CR>" to monitor
		BEQ wrIPA2			;To set it to binary mode
		JSR uWRbL
		INY
		BNE wrIPA1
		
.wrIPA2		JMP uSync			;Sync on return
\
\
\
.wrDIR		LDY #&00

.wrDIR1		LDA ustr2,Y			;Write "DIR" to monitor
		BEQ wrDIR2
		JSR uWRbL
		INY
		BNE wrDIR1
		
.wrDIR2		RTS				;No sync on return
\
\
\
.wrDVL		LDY #&00

.wrDVL1		LDA ustr8,Y			;Write "DVL<CR>" to monitor
		BEQ wrDVL2
		JSR uWRbL
		INY
		BNE wrDVL1
		
.wrDVL2		RTS				;No sync on return
\
\
\
.wrDSN		LDY #&00

.wrDSN1		LDA ustr9,Y			;Write "DSN<CR>" to monitor
		BEQ wrDSN2
		JSR uWRbL
		INY
		BNE wrDSN1
		
.wrDSN2		RTS				;No sync on return
\
\
\
.wrOPW		LDY #&00

.wrOPW1		LDA ustr4,Y			;Write "OPW " to monitor
		BEQ wrOPW2
		JSR uWRbL
		INY
		BNE wrOPW1		

.wrOPW2		RTS				;No sync on return
\
\
\
.wrSEK		LDY #&00
		
.wrSEK_1	LDA ustr7,Y			;Write "SEK 0000" to monitor
		JSR uWRbL			;to set beginning of file
		INY
		CMP #&0D
		BNE wrSEK_1
		JMP uSync			;Sync on return
\
\
\
.wrWRF		LDY #&00
		
.wrWRF1		LDA ustr5,Y			;Write "WRF " to monitor
		BEQ wrWRF2
		JSR uWRbL
		INY
		BNE wrWRF1
		
.wrWRF2		RTS				;No sync on return
\
\
\
.wrCLF		LDY #&00

.wrCLF1		LDA ustr6,Y			;Write "CLF " to monitor
		BEQ wrCLF2
		JSR uWRbL
		INY
		BNE wrCLF1
		
.wrCLF2		RTS				;No sync on return		
\
\** Command Strings
\
.ustr1		EQUS	"RD "
		BRK
.ustr2		EQUS	"DIR"
		BRK
.ustr3		EQUS	"IPH"
		EQUB	&0D
		BRK
.ustr3a		EQUS	"IPA"
		EQUB	&0D
		BRK
.ustr4		EQUS	"OPW "
		BRK
.ustr5		EQUS	"WRF "
		BRK
.ustr6		EQUS	"CLF "
		BRK
.ustr7		EQUS	"SEK "
		BRK
		BRK
		BRK
		BRK
		EQUB	&0D
.ustr8		EQUS	"DVL"
		EQUB 	&0D
		BRK
.ustr9		EQUS	"DSN"
		EQUB	&0D
		BRK
.uprmpt		EQUS	"D:\>"
		EQUB	&0D
		BRK
\
\
\***************************************************
\** *MONITOR Command
\
.cmdMoni	JSR stackClaim			;Change stacked A to &00
		JSR prtStr
		EQUS	"USB Monitor"
		EQUB	&0D
		NOP
		JSR uSync
		JSR wrIPA
		JSR prtStr
		EQUS	"Ready"
		EQUB &0D
		EQUS	">"
		NOP
		JSR setSCR
.moni_OLs	LDY #&00
		STY &FDDB
.moni_OL1	BIT vdipS
		BMI moni_IL1
		BIT &FF
		BMI moni_ESC
		LDA vdip
		LDY &FDDB
		CMP uprmpt,Y
		BNE moni_OL2
		INY
		STY &FDDB
		CPY #&05
		BNE moni_OL3
		JMP moni_OLs
.moni_OL2	LDY #&00
		STY &FDDB
.moni_OL3	CMP #&80
		BCS moni_OL4a
		CMP #&0D
		BEQ moni_OL4
		CMP #&20
		BCS moni_OL4
.moni_OL4a	LDA #&2E
.moni_OL4	JSR prtChrA
		JMP moni_OL1
		
.moni_IL1	LDA #&81
		LDX #&00
		LDY #&00
		JSR osbyte
		BCS moni_CL1
		TXA
		JSR prtChrA
		JSR uWRbL
		JMP moni_OL1	
		
.moni_CL1	CPY #&1B
		BNE moni_OL1
.moni_ESC	JSR prtStr
		EQUB	&0D
		EQUS	"Flushing Buffer"
		EQUB	&0D
		NOP
		JSR uFlush
		JSR wrIPH
		JMP errEsc
\
\
\****************************************************
\** NVRAM Code
\
\
\** For Page Operations, setup as X = Source Page, Y= Destination Page

.eewrite	PHA				;Write 1 Byte at selected location
		TXA
		PHA
		TYA
		PHA
		JSR sstart
		LDA#160
		JSR writeb
		PLA
		JSR writeb
		PLA
		JSR writeb
		PLA
		JSR writeb
		JMP sstop

.eeread		TXA				;Read 1 Byte from selected location
		PHA
		TYA
		PHA
		JSR sstart
		LDA #160
		JSR writeb
		PLA
		JSR writeb
		PLA
		JSR writeb
		JSR sstart
		LDA #161
		JSR writeb
		JMP readb

.eewriteP	STX zpm1			;Write Page
		STY zpm3
		JSR sstart
		LDA #160
		JSR writeb
		LDA zpm3
		JSR writeb
		LDA #&00
		JSR writeb
		LDA #&00
		STA zpm4
		STA zpm0
		STA zpm2
		
.ew1		LDY zpm4
		LDA (zpm0),Y
		JSR writeb
		INC zpm4
		LDA zpm4
		CMP #128
		BNE ew1
		JSR sstop
		JSR ackerr
		JSR sstart
		LDA #160
		JSR writeb
		LDA zpm3
		JSR writeb
		LDA #128
		JSR writeb
		LDA #128
		STA zpm4
		
.ew2		LDY zpm4
		LDA (zpm0),Y
		JSR writeb
		INC zpm4
		LDA zpm4
		BNE ew2
		JSR sstop
		JSR ackerr
		RTS

.eereadP	STX zpm1			;Read Page
		STY zpm3
		LDX #&00
		STX zpm0
		STX zpm2
		LDY zpm1
		JSR eeread
		LDY #&00
		STY zpm4
		STA (zpm2),Y
		INC zpm4
		
.ee1		JSR readb
		LDY zpm4
		STA (zpm2),Y
		INC zpm4
		LDA zpm4
		BNE ee1
		JSR readnull
		JSR sstop
		RTS
\
\
\
.readb		LDA #&00			;Read a Byte
		STA zpm5
		STA &FCFC
		STA &FCFB
		LDX #&08
		
.rl1		LDA #&00
		STA &FCFC
		LDA #&01
		STA &FCFC
		LDA &FCFA
		ROR A
		ROL zpm5
		DEX
		BNE rl1
		JSR rdack
		LDA zpm5
		RTS

.readnull	LDA #&00
		STA &FCFC
		STA &FCFB
		LDX #&08
		
.rl2		LDA #&00
		STA &FCFC
		LDA #&01
		STA &FCFC
		DEX
		BNE rl2
		JMP rdnack
\
\
\
.writeb		STA zpm5			;Write a Byte
		LDA #&01
		STA &FCFB
		LDX #&08
		
.wl1		LDA #&00
		STA &FCFC
		LDA zpm5
		ROL A
		ROL A
		AND #&01
		STA &FCFA
		LDA #&01
		STA &FCFC
		ROL zpm5
		DEX
		BNE wl1
		
.ack		LDA #&00
		STA &FCFC
		STA &FCFB
		LDA #&01
		STA &FCFC
		LDA &FCFA
		AND #&01
		BNE ackerr
		RTS
\
\
\
.ackerr		JSR sstart
		LDA #160
		JMP writeb

.rdack		LDX #&00
		LDY #&01
		STX &FCFC
		STX &FCFA
		STY &FCFB
		STY &FCFC
		RTS
		
.rdnack		LDX #&00
		LDY #&01
		STX &FCFC
		STY &FCFA
		STY &FCFB
		STY &FCFC
		RTS
		
.sstop		LDX #&00
		LDY #&01
		STX &FCFC
		STY &FCFB
		STX &FCFA
		STY &FCFC
		STY &FCFA
		RTS
		
.sstart		LDX #&00
		LDY #&01
		STX &FCFC
		STY &FCFB
		STY &FCFA
		STY &FCFC
		STX &FCFA
		RTS
		
.init		LDA #&01
		STA &FCFC
		STA &FCFA
		STA &FCFB
		RTS
		
.initWP		LDA #&01
		STA &FCFC
		STA &FCFA
		STA &FCFB
		RTS
\
\
\************************************************
\** RamFS filing routines
\
.loadCAT	JSR saveAXY			;Load Catalog
		JSR set10
		LDA #&00
		STA &FDD6
		LDA &CF				;Current drive number
		STA &FD82
		CMP #&04			;Check if drive is 4 for NVRAM
		BEQ lNVram			;If so, It's NVRAM
		AND #&03
		JSR mASL2			;A contains drive number, Multiply by 4 to get RAM page
		STA zpm0
		LDX #&00
.lrc_1		LDA zpm0
		STA &FCFE
		LDA #&10			;Add 16 page offset for workspace
		STA &FCFF
		LDA &FD00,X
		JSR set0E
		STA &FD00,X
		INX
		BNE lrc_1
.lrc_2		LDA zpm0
		STA &FCFE
		LDA #&11			;Add 16 page offset for workspace
		STA &FCFF
		LDA &FD00,X
		JSR set0F
		STA &FD00,X
		INX
		BNE lrc_2
		RTS
		
.lNVram		JSR set0E			;Load Catalog from NVRAM
		LDX #&00			;Source page in NVRAM
		LDY #&FD			;Dest page
		JSR eereadP			;read it
		JSR set0F
		LDX #&01
		LDY #&FD
		JSR eereadP
		RTS
\
\
\
.saveCAT	JSR saveAXY			;Save Catalog
		CLC
		JSR set0F
		SED
		LDA &FD04
		ADC #&01
		CLD
		STA &FD04
		LDA &CF				;Current drive number
		AND #&04			;Check if drive is 4-7
		BNE sNVram			;If so, It's NVRAM
		LDA &CF
		JSR mASL2			;A contains drive number, Multiply by 4 to get RAM page
		STA zpm0
		STA &FCFE
		LDA #&10			;Add 16 page offset for workspace
		STA &FCFF
		LDX #&00
.src_1		JSR set0E
		LDA &FD00,X
		TAY
		LDA zpm0
		STA &FCFE
		LDA #&10
		STA &FCFF
		TYA
		STA &FD00,X
		INX
		BNE src_1
.src_2		JSR set0F
		LDA &FD00,X
		TAY
		LDA zpm0
		STA &FCFE
		LDA #&11
		STA &FCFF
		TYA
		STA &FD00,X
		INX
		BNE src_2
		RTS
		
.sNVram		JSR set0E			;Save Catalog to NVRAM
		LDX #&FD			;Source page in RAM
		LDY #&00			;Dest page in NVRAM
		JSR eewriteP			;write it
		JSR set0F
		LDX #&FD
		LDY #&01
		JSR eewriteP
		RTS
\
\
.x8B90		PHA
		LDA #&FF
		JSR set10
		STA &FD74
		STA &FD75
		PLA
		RTS

.x8B9B		JSR set10
		LDA &FD80
		PHA
		LDA &FDD6
		JMP x8BC1
\
\
\************************************************
\** Sets the Tube up for a data transfer
\** And stores a flag at zpm7
\
.setTubeXfer	PHA			
		JSR set10
		STA &FD80			
		LDA &BE				;Get the Transfer addresses
		STA &FD72			;And store then in the control block
		LDA &BF
		STA &FD73
		LDA &FD74			;Check the top 4 bytes
		AND &FD75
		ORA &FDD7			;Do math with the Tube flag
		EOR #&FF
		STA &FDD6			;Store the YES/NO to transfer result
		STA zpm7			;&FF = Transfer over Tube, &00 = No Transfer
		
.x8BC1		SEC
		BEQ x8BCE			;Jump if no transfer to perform
		LDX #&72			;Setup the pointer to control block
		LDY #&FD
		PLA				;Get a copy of the function code from A
		PHA
		JSR &0406			;Do the Call to Tube Host Code
		CLC

.x8BCE		PLA
		RTS






\
\************************************************
\** Core RAM transfer routines
\
\(&BE)=Destination ram
\(&C2)=Length
\(&C4)=Sector
\
.readRAMblock	JSR saveBEC5
		LDA #&01			;Command for Tube Read
		JSR setTubeXfer			;Do the Tube setup
		;JSR set10
		;LDA &FDD6			;Get the Tube presence flag
		;STA zpm7			;And store it
		LDA &C4
		AND #&03			;Remove high byte load/exec info from sector data
		STA &C4
		LDA &CF				;Get The current drive number
		AND #&04			;Mask off top bits
		CMP #&04			;Is it the NVRAM?
		BNE read_J1
		JMP rdNVblock			;Jump if so
		
.read_J1	LDA &CF
		JSR mASL2
		CLC
		ADC &C4
		STA &C4
		LDA &C5				;Add &10 to sectors
		CLC
		ADC #&10
		STA &C5
		STA &FCFF
		LDA &C4
		ADC #&00
		STA &C4
		STA &FCFE
		LDY #&00
		LDX #&00
		LDA &BF
		CMP #&FD
		BEQ read_gbpb			;If the read is back into itself, transfer 1 sector worth only
		
.read_L1	LDA &FD00,X
		BIT zpm7
		BMI readtube
		STA (&BE),Y
		JMP readtubeJ
.readtube	STA &FEE5		
		
.readtubeJ	LDA &C2
		SEC
		SBC #&01
		STA &C2
		LDA &C3
		SBC #&00
		BCC readDone
		STA &C3
		INX
		INY
		BNE read_L1
		INC &BF
		LDA &C5
		CLC
		ADC #&01
		STA &C5
		STA &FCFF
		LDA &C4
		ADC #&00
		STA &C4
		STA &FCFE
		LDA &C2
		BNE read_L1
		LDA &C3
		BNE read_L1

.readDone	JSR restoreBEC5
		RTS
		
.read_gbpb	LDA &C5
		STA &FCFF
		LDA &C4
		STA &FCFE
		LDA &FD00,Y
		PHA
		LDA zpm6
		JSR setDFS
		PLA
		STA &FD00,Y
		INY
		BNE read_gbpb
		JMP readDone
		
\(&BE)=Destination ram
\(&C2)=Length
\(&C4)=Sector	

.rdNVblock	LDA &BF
		CMP #&FD
		BNE rdNV01a
		LDA zpm6			;Set the destination page
		JSR setDFS			;If the write is to &BF
		
.rdNV01a	LDX #&00			;Addr low byte start from NVRAM	
		LDY &C5				;Addr high byte is Sector Number
		JSR eeread			;Start the read
		LDY #&00
		STY zpm4
		BIT zpm7
		BMI readNVtube
		STA (&BE),Y			;Store the first byte
		JMP readNVtubeJ
.readNVtube	STA &FEE5			;Or send it to the Tube
			
.readNVtubeJ	INC zpm4
		LDA &C2				;Need to subtract one byte for the one just read
		SEC
		SBC #&01
		STA &C2
		LDA &C3
		SBC #&00
		BCC rdNVdone
		STA &C3
		JMP rdNV02			;Then start by subtracting a second to get the byte count correct
		
.rdNV01		JSR readb
		BIT zpm7
		BMI readNVtube2
		LDY zpm4
		STA (&BE),Y			;Store the first byte
		JMP readNVtubeJ2
.readNVtube2	STA &FEE5			;Or send it to the Tube
			
.readNVtubeJ2	INC zpm4
		BNE rdNV02
		INC &BF

.rdNV02		LDA &C2
		SEC
		SBC #&01
		STA &C2
		LDA &C3
		SBC #&00
		BMI rdNVdone
		STA &C3
		JMP rdNV01
		
.rdNVdone	JSR readnull
		JSR sstop
		JSR restoreBEC5
		RTS
\
\
\
.writeRAMblock	JSR saveBEC5
		LDA #&00			;Command for Tube Write
		JSR setTubeXfer			;Do the Tube setup
		;JSR set10
		;LDA &FDD6			;Get the Tube presence flag
		;STA zpm7			;And store it
		LDA &C4
		AND #&03			;Remove high byte load/exec info from sector data
		STA &C4
		LDA &CF				;Get drive number
		AND #&04			;If it is 4 then its NVRAM
		CMP #&04
		BNE write_J1
		JMP wrNVblock			;and branch
		
.write_J1	LDA &CF				;Load drive number
		JSR mASL2			;multiply by 4 to get RAM page
		CLC
		ADC &C4				;add it to sector number
		STA &C4
		LDA &C5				;Add &10 to sectors
		CLC
		ADC #&10
		STA &C5
		STA &FCFF
		LDA &C4
		ADC #&00
		STA &C4
		STA &FCFE
		LDY #&00
		LDX #&00
		LDA &BF
		CMP #&FD
		BEQ write_gbpb			;If the read is back into itself, transfer 1 sector worth only
		
.write_L1	BIT zpm7
		BMI writetube
		LDA (&BE),Y
		JMP writetubeJ
.writetube	LDA &FEE5

.writetubeJ	STA &FD00,X
		LDA &C2
		SEC
		SBC #&01
		STA &C2
		LDA &C3
		SBC #&00
		BCC writeDone
		STA &C3
		INX
		INY
		BNE write_L1
		INC &BF
		LDA &C5
		CLC
		ADC #&01
		STA &C5
		STA &FCFF
		LDA &C4
		ADC #&00
		STA &C4
		STA &FCFE
		LDA &C2
		BNE write_L1
		LDA &C3
		BNE write_L1

.writeDone	JSR restoreBEC5
		RTS
		
.write_gbpb	LDA zpm6
		JSR setDFS
		LDA &FD00,Y
		PHA
		LDA &C5
		STA &FCFF
		LDA &C4
		STA &FCFE
		PLA
		STA &FD00,Y
		INY
		BNE write_gbpb
		JMP writeDone
		
\(&BE)=Destination ram
\(&C2)=Length
\(&C4)=Sector

.wrNVblock	LDA &BF
		CMP #&FD
		BNE wrNV01a
		LDA zpm6			;Set the destination page
		JSR setDFS			;If the write is to &BF

.wrNV01a	JSR sstart
		LDA #160
		JSR writeb
		LDA &C5
		JSR writeb
		LDA #&00
		JSR writeb
		LDA #&00
		STA zpm4
		STA zpm2
		
.wrNV01		BIT zpm7
		BMI wrNVtube2
		LDY zpm4
		LDA (&BE),Y			;Load the first byte from memory
		JMP wrNVtubeJ2
		
.wrNVtube2	LDA &FEE5			;Or load it from the Tube
			
.wrNVtubeJ2	JSR writeb
		INC zpm4
		LDA zpm4
		CMP #128
		BNE wrNV01
		JSR sstop
		JSR ackerr
		JSR sstart
		LDA #160
		JSR writeb
		LDA &C5
		JSR writeb
		LDA #128
		JSR writeb
		LDA #128
		STA zpm4
		
.wrNV02		BIT zpm7
		BMI wrNVtube3
		LDY zpm4
		LDA (&BE),Y			;Load the first byte from memory
		JMP wrNVtubeJ3
		
.wrNVtube3	LDA &FEE5			;Or load it from the Tube
			
.wrNVtubeJ3	JSR writeb
		INC zpm4
		LDA zpm4
		BNE wrNV02
		JSR sstop
		JSR ackerr

		INC &BF
		INC &C5
		DEC &C3
		BPL wrNVblock
		
		JSR restoreBEC5
		RTS
\
\
\************************************************
\** Get Options Routine
\ &90		00=Quiet/FF=Verbose flag for EXTRACT/ENCODE
\ &91		First Drive for EXT/ENC - &FF if not valid
\ &92		Second Drive for EXT/ENC - &FF if not valid
\ &93		00=Target RAM/FF=Target Disk
\ &94		Option counter

.getOptions	JSR set10
		LDA &FDCB			;Get current drive
		;JSR chkDrv4A			;Check it's in valid range
		JSR setSCR
		STA &FD91			;Store it as first drive
		LDY #&FF
		STY &FD90			;Store Verbose option
		STY &FD92			;Store Second drive as invalid
		INY
		STY &FD93			;Set default Target as RAM
		LDA #&05
		STA &FD94			;Set the maximum number of options to 4
		LDY #&00
		LDA (&F2),Y
		CMP #&2D			;Check if first charater is "-"
		BEQ getOpt2			;Jump if it is
		JMP getOptChk			;If no option set, validate drives and return
		
.getOpt2	LDX #&00

.getOpt2A	INY				;Next character
		LDA (&F2),Y
		CMP #&20			;Is it a space?
		BEQ getOptE			;if so, exit
		CMP #&51			;is it a "Q"
		BNE getOpt3
		LDA #&00
		STA &FD90
		JMP getOptL
		
.getOpt3	CMP #&44			;is it a "D"
		BNE getOpt4
		DEC &FD93			;if so then set Target to Disk
		JMP getOptL
		
.getOpt4	CMP #&30
		BCC badOpt			;Is option less than CHR$"0"?
		CMP #&34
		BCS badOpt			;Or greater than CHR$"3"?
		AND #&03			;must be drive number, so convert
		STA &FD91,X			;and store
		INX				;add one to drive counter
		CPX #&03
		BEQ badOpt
		
.getOptL	DEC &FD94
		BNE getOpt2A
		
.badOpt		JMP errBadOpt		
				
.getOptE	INY			
		LDA (&F2),Y			;Get next character
		CMP #&20			;If it's a space then its one too many
		BEQ badOpt			;So report it as a bad option
		TYA
		CLC
		ADC &F2				;Add the option characters to the filename address
		STA &F2
		LDA &F3
		ADC #&00
		STA &F3
		
.getOptChk	LDA &FD91			;Get first drive
		CMP #&04			;Check range 0-3
		BCC getOpt5
		JMP errBadDrv
		
.getOpt5	LDA &FD92			;Get second drive
		CMP #&FF
		BEQ getOpt7			;Ignore if &FF
		CMP #&04			;Check range 0-3
		BCC getOpt6
		JMP errBadDrv

.getOpt6	CMP &FD91			;Check if both drives equal
		BNE getOpt7
		JMP errBadOpt			;Error if they are
		
.getOpt7	RTS
\
\
\************************************************
\** Routine to Store and Recall File Transfer info
\
.saveBEC5	LDX #&07
		JSR setSCR			;Set scratchpad space
.S_L10		LDA &BE,X
		STA &FDF8,X
		DEX
		BPL S_L10
		RTS
		
.restoreBEC5	LDX #&07
		JSR setSCR			;Set scratchpad space
.R_L10		LDA &FDF8,X
		STA &BE,X
		DEX
		BPL R_L10
		RTS
\
\
\************************************************
\** Debug Printer
.debug		STA &70
		STX &71
		STY &72
		PLA
		STA &73
		PLA
		STA &74
		JSR prtHexA8bit
		PHA
		LDA &73
		JSR prtHexA8bit
		PHA
		JSR prtStr
		EQUS	"---A="
		NOP
		LDA &70
		JSR prtHexA8bit
		JSR prtStr
		EQUS	",X="
		NOP
		LDA &71
		JSR prtHexA8bit
		JSR prtStr
		EQUS	",Y="
		NOP
		LDA &72
		JSR prtHexA8bit
		TAY
		LDX &71
		LDA &70
		RTS
\
\
\*************************************************
\** Routines to set RAM workspace paging registers
\
.setSCR		PHA
		LDA #&01
.setLP		STA &FCFF
		LDA #&04
		STA &FCFE
		PLA
		RTS
		
.setLPS		STA &FCFF
		PLA
		RTS
\
\
\*************************************************
\** setDFS will set the equivalent page in RAM, in the workspace
\** on entry, A = Equivalent page in normal RAM

.setDFS		SEC
		SBC #&0C
		STA &FCFF
		LDA #&04
		STA &FCFE
		RTS
\
\
\*************************************************
\** Page set routines
\** S versions are when only LSB needs modifying
\		
.set0E		PHA
		LDA #&02
		BNE setLP
		
.set0ES		PHA
		LDA #&02
		BNE setLPS
		
.set0F		PHA
		LDA #&03
		BNE setLP
		
.set0FS		PHA
		LDA #&03
		BNE setLPS
		
.set10		PHA
		LDA #&04
		BNE setLP
		
.set10S		PHA
		LDA #&04
		BNE setLPS
		
.set11		PHA
		LDA #&05
		BNE setLP
		
.set11S		PHA
		LDA #&05
		BNE setLPS
		
.setERR		PHA
		LDA #&FF
		STA &FCFE
		STA &FCFF
		PLA
		RTS
		
		EQUB	&00
		EQUS	"END_OF_ROM"
		EQUB	&00
.ROMend		EQUB	&00			;TFFT

SAVE "!!RAMFS.bin", ROMstart, ROMend
