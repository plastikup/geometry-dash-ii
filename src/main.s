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
* Fetch tile data at index of keypress
	LDX	#0
	LDY	#0
	JSR	FETCHMAPDATA	; fetch cell datum
* Print keypress
	JSR	COUT
	JMP	MAIN

	RTS


** =============== Map module ===============
** UPDATE TILE DATA TABLES
* Multiply X and Y registers by 2
FETCHMAPDATA	TXA
	ASL		; each pointer is 2 bytes
	TAX
	TYA
	ASL		; each map datum is 2 bytes
	TAY

* Build tile pointer
	LDA	LVLPTR,X
	STA	PTR
	LDA	LVLPTR+1,X
	STA	PTR+1

* Access tile datum
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
LVL0	HEX	D0C0C002C108
LVL1	HEX	D001C102C008
LVL2	HEX	D001C202C008
LVL3	HEX	D001C302C008
LVL4	HEX	D001C402C008
LVL5	HEX	D001C502C008
LVL6	HEX	D001C602C008
LVL7	HEX	D001C702C008
LVL8	HEX	D001C802C008
LVL9	HEX	D001C902C008
LVLA	HEX	D001CA02C008
LVLB	HEX	D001CB02C008



