** Debugging only
HOME	EQU	$FC58
COUT	EQU	$FDED

** =============== Zero page ===============
PTR	EQU	$70	; quick temporary pointer storage


** ============ Start of program ===========
** MAIN LOOP
	ORG	$8000

MAIN	JSR	WAIT
* Capture keypress
	JSR	INPUT
	CMP	#$00	; check against: neutral $00 flag
	BEQ	MAIN	; jump if neutral flag
	CMP	#$D1	; check against: Q key (quit)
	BEQ	RTS	; exit if quit key is pressed
* Fetch all 12 tile datas (TEST PURPOSES ONLY)
	LDX	#$B
FETCHALLINNER	TXA
	PHA
	TAX
* fetch cell datum
	JSR	FETCHMAPDATA
* print data on screen
	PLA
	TAX
	LDA	LVLCHRS,X
	JSR	COUT
	LDA	LVLQNT,X
	JSR	COUT

	DEX
	BNE	FETCHALLINNER

	JMP	MAIN

	RTS


** =============== Map module ===============
** UPDATE TILE DATA TABLES
* Multiply X and Y registers by 2
FETCHMAPDATA	TXA
	ASL		; each pointer is 2 bytes
	TAX

* Build tile pointer
	LDA	LVLPTR,X
	STA	PTR
	LDA	LVLPTR+1,X
	STA	PTR+1

* Access tile datum
	LDY	#0
	TXA
	LSR		; each table element is 1 byte
	TAX

	LDA	(PTR),Y
	STA	LVLCHRS,X

	INY
	LDA	(PTR),Y
	STA	LVLQNT,X

	RTS

** ========== Input capture module ==========
** READ KEYPRESS
INPUT	LDA	$C000	; read keystroke
	BPL	NOKEY	; verify if A < $80
* Received positive keypress
	BIT	$C010	; clear keyboard strobe
	RTS		; return with key in A
* No positive keypress
NOKEY	LDA	#$00	; load neutral $00 flag
	RTS		; return with no key


** ================= Utils =================
** REQUEST_ANIMATION_FRAME SUBROUTINE
WAIT	LDA	#0	; 6Hz refresh rate
	JSR	$FCA8	; builtin wait subroutine
	RTS

** GLOBAL RTS CALLABLE FROM BRANCHES
RTS	RTS


** ======== CONSTANTS AND VARIABLES ========
** MAP MODULE DATA AND POINTERS
* Common tables
LVLPTR
	DA	LVL0
	DA	LVL1
	DA	LVL2
	DA	LVL3
	DA	LVL4
	DA	LVL5
	DA	LVL6
	DA	LVL7
	DA	LVL8
	DA	LVL9
	DA	LVLA
	DA	LVLB

LVLCHRS	DS	12
LVLQNT	DS	12

* Level data
LVL0	HEX	D0D0D002C108
LVL1	HEX	D0C1C102D008
LVL2	HEX	D0C2C202D008
LVL3	HEX	D0C3C302D008
LVL4	HEX	D0C4C402D008
LVL5	HEX	D0C5C502D008
LVL6	HEX	D0C6C602D008
LVL7	HEX	D0C5C702D008
LVL8	HEX	D0C4C802D008
LVL9	HEX	D0C3C902D008
LVLA	HEX	D0C2CA02D008
LVLB	HEX	D0FDCB02D008
