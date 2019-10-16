; RCOPY
; Original (1.00) code by RetroClinic
; Modified (1.01) by Alan Bleasby
	
oswrch = $ffee
osasci = $ffe3	
osbyte = $fff4
osword = $fff1
gsinit = $ffc2
gsread = $ffc5	
oscli  = $fff7
	
WRTCOMM = $4b
RDCOMM  = $53	

ROMSEL = &fe30

MEMBLK = $2300
SECHI = MEMBLK + $106
SECLO = SECHI + 1
	

org	&2d00


.start
	ldx	#$00		; Print copyright message
.rctlp	lda	rcopytext,x
	beq	procstr
	jsr	osasci
	inx
	bne	rctlp

.procstr
	jsr	gsinit		; Init CL string
	beq	bopterr		; Empty string, so error

	cmp	#'D'		; DFS?
	beq	mark_ff		; Yes so set flag byte to FF
	cmp	#'R'		; RAMFS?
	beq	mark_00		; Yes so set flag byte to 00

.bopterr
	jmp	badoption

.mark_ff
	lda	#$ff
	bne	mbcomm
.mark_00
	lda	#$00
.mbcomm	sta	$70

	iny			; Skip over R/D to numeric byte
	jsr	gsread		; Read CL byte
	sec			; Convert to binary
	sbc	#'0'
	bcc	bopterr		; Error if < 0
	cmp	#$04
	bcs	bopterr		; Error if > 3
	sta	$71		; Store as src drive

	jsr	gsread		; Next next FS letter
	cmp	#'D'		; DFS?
	beq	dtest		; Yes, so check previous FS not DFS too
	cmp	#'R'		; RAMFS?
	beq	rtest		; Yes, so check previous FS not RAMFS too
	bne	bopterr		; Otherwise an error

.dtest	lda	$70		; Previous FS
	cmp	#$ff		; DFS?
	beq	bopterr		; Yes, so error
	bne	finalnum

.rtest	lda	$70		; Previous FS is RAMFS?
	beq	bopterr		; Yes, so error

.finalnum
	jsr	gsread		; Get final numeral
	sec			; Convert to binary
	sbc	#'0'
	bcc	bopterr		; Error if < 0
	cmp	#$04
	bcs	bopterr		; Error if > 3
	sta	$72		; Store as dest drive number

	jsr	gsread		; Any extra bytes on CL?
	bcc	bopterr		; Yes, so error

	ldx	#$00		; Print "Copying from "
.cflp	lda	copyfromtext,x
	beq	cflpo
	jsr	osasci
	inx
	bne	cflp

.cflpo
	lda	$70		; Get first FS type
	beq	rprts		; Print RAM to Disc

	jsr	prtddrv		; Print "Disc Drive "
	jsr	prtsrcnum	; Print src drive number
	jsr	prtrdrv		; Print "RAM Drive "
	jsr	prtdestnum	; Print dest drive number
	jmp	sure		; Skip to end of drive info printing

.rprts
	jsr	prtrdrv		; Print "RAM Drive "
	jsr	prtsrcnum	; Print src drive number
	jsr	prtddrv		; Print "Disc Drive "
	jsr	prtdestnum	; Print dest drive number

.sure
	ldx	#$00		; Print "Are you sure (Y/N)? "
.aslp	lda	aresuretext,x
	beq	aslpo
	jsr	osasci
	inx
	bne	aslp

.aslpo

	lda	#$0f		; Clear input buffer
	ldx	#$00
	jsr	osbyte

.rdibuf	lda	#$91		; Get char from input buffer in Y
	ldx	#$00
	jsr	osbyte
	bcc	testsure	; A byte was in the buffer so test
	bit	$ff		; Empty buffer so test whether Esc pressed
	bpl	rdibuf		; No, so loop for another key
	rts			; Esc pressed

.testsure
	tya			; Get key and convert to UC
	and	#$df
	cmp	#'Y'		; Ready to go
	beq	gogogo		; Yes
	lda	#$0d		; No, so print space and return
	jmp	osasci

.gogogo
	ldx	#<disc		; RCOPY must run from an initialised DFS
	ldy	#>disc
	jsr	oscli

	lda	#$00		; Track 0
	sta	$73		; Store track number
	ldx	#$00		; Print "Copying track 00"
.ctklp	lda	copytracktext,x
	beq	trklp
	jsr	osasci
	inx
	bne	ctklp
	
.trklp	lda	#$08		; Print 2 backspaces for track display
	jsr	osasci
	jsr	osasci
	lda	$73		; Get current track number
	lsr	a		; Get MS nybble
	lsr	a
	lsr	a
	lsr	a
	jsr	prthex
	lda	$73
	and	#$0f		; Get LS nybble
	jsr	prthex

	bit	$ff		; Test for Esc
	bpl	tknoesc		; No Esc
	jsr	setram		; Esc, so switch back to RAMFS
	rts			; and return

.tknoesc
	lda	$70		; Src FS
	bpl	doRFS		; RFS so jump
	;  DFS read
	lda	$71		; Get src drive num
	ldx	$73		; Get track num
	jsr	RdDisc

	;  RAMFS write
	lda	$72		; Get dest drive num
	ldx	$73		; Get track num
	jsr	WrtRAM
	jmp	tkadj

.doRFS
	;  RAMFS read
	lda	$71		; Get src drive num
	ldx	$73		; Get track num
	jsr	RdRAM

	;  DFS write
	lda	$72		; Get dest drive num
	ldx	$73		; Get track num
	jsr	WrtDisc
	
.tkadj
	lda	$73		; Get track
	bne	nottk0

	lda	SECLO
	sta	$75		; LSB of number of total sectors
	lda	SECHI
	and	#$03
	sta	$74		; MSB of total sectors

	ldx	#$ff		; Counter for total tracks
.tcntlp	lda	$75		; LSB sectors
	sec			; Repeatedly subtract 10 (sec per trk)
	sbc	#$0a		; until the carry is clear
	sta	$75		; in order to calculate total tracks 
	lda	$74		; on disc. Then store in $76
	sbc	#$00
	sta	$74
	inx
	bcs	tcntlp
	stx	$76		; Total tracks

.nottk0	inc	$73		; Increment current track
	lda	$73		; Current track = total tracks?
	cmp	$76
	beq	alldone
	jmp	trklp

.alldone
	jsr	setram
	lda	#$0d		; Print CR and retrun
	jmp	osasci





;  Subroutines and data blocks


.RdDisc				; Read disc track. A=drvnum X=track
	ldy	#RDCOMM
	bne	setdc
.WrtDisc			; Write disc track. A=drvnum X=track
	ldy	#WRTCOMM

.setdc	sty	bcomm		; Read track
	sta	bdrv		; Set drv num
	stx	btrk		; Set track
	lda	#$7f		; DFS osword
.rdbc	ldx	#<block
	ldy	#>block
	jmp	osword


.RdRAM
	ldy	#RDCOMM		; Read RAMFS track. A=drvnum X=track
	bne	setrc
.WrtRAM
	ldy	#WRTCOMM	; Write RAMFS track. A=drvnum X=track

.setrc	sty	bcomm		; Read track
	sta	bdrv		; Set drv num
	stx	btrk		; Set track
	lda	#$77		; RAMFS osword
	jmp	rdbc


.setram
	ldx	#<ram
	ldy	#>ram
	jsr	oscli
	rts

.disc	equs	"DISC",$0d
.ram	equs	"RAM",$0d
	
.block
.bdrv	equb	$00		; drive number
	equb	<MEMBLK,>MEMBLK,$ff,$ff	; Memory address
	equb	$03		; Number of parameters
.bcomm	equb	WRTCOMM		; Command
.btrk	equb	$00		; Track number
.bsec	equb	$00		; Sector number
	equb	$2a		; Sector length (10 sectors i.e. full track)
.bstat	equb	$00		; Status byte



;  Print hex binary byte in A
.prthex
	clc
	adc	#$30
	cmp	#$3a
	bcc	hxprt
	adc	#$06
.hxprt	jsr	osasci
	rts




.prtsrcnum			; Print source drive number
	lda	$71
	bne	prtnum
.prtdestnum
	lda	$72		; Print destination drive number
.prtnum	clc			; Convert to ASCII
	adc	#$30
	jsr	osasci		; Print number plus
	lda	#' '		; trailing space and
	jmp	osasci		; return



; Print "RAM Drive "
.prtrdrv
	ldx	#$00
.prdlp	lda	ramdrivetext,x
	beq	prdlpo
	jsr	osasci
	inx
	bne	prdlp
.prdlpo	rts



; Print "Disc Drive "
.prtddrv
	ldx	#$00
.pddlp	lda	discdrivetext,x
	beq	pddlpo
	jsr	osasci
	inx
	bne	pddlp
.pddlpo	rts



.rcopytext	equs	"RCOPY 1.01",$0d,"(C) RetroClinic (15 Oct 2019)",$0d
		equs	"Additional code by Alan Bleasby",$0d,$0d,$00
.copyfromtext	equs	"Copying from ",$00
.ramdrivetext	equs	"RAM Drive ",$00
.discdrivetext	equs	"Disc Drive ",$00
.aresuretext	equs	$0d,"Are you sure (Y/N)? ",$00
.copytracktext	equs	$0d,"Copying track 00",$00

.badoption	equs	$00,$ff,"Bad option",$00


.end



SAVE "RCOPY", start, end, start
